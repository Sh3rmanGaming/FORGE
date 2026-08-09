# ADR-003 - Device Host Lifecycle and Visibility Ownership

**Status:** Accepted
**Date:** 2026-08-09

## Context

M2.010 introduces the first production Device Host, completes the three-role
ForgeOS registration set, and causes production ForgeOS to enter
`RUNTIME_ACTIVE` for the first time. Registration definitions, runtime Host
objects, visibility, rendering, and FS25 callbacks require distinct owners.

## Options Considered

1. Let Device Host Registry own registrations, runtime instances, and
   visibility. This conflates immutable registration data with runtime state.
2. Let each Host register as an independent FS25 listener and mutate its own
   state. This violates the single Engine lifecycle and State Store boundaries.
3. Separate registration, orchestration, visibility, presentation, and engine
   callbacks. This preserves existing ForgeOS ownership rules and is selected.

## Decision

`DeviceHostRegistry` owns immutable Host definitions, identifier uniqueness,
device-to-Host binding validation, registration validation/freeze/cleanup, and
private instance construction. It never owns a returned runtime instance.

ForgeOS bootstrap owns the single local PhoneHost instance. After deferred
registration completion reaches `RUNTIME_ACTIVE` and publishes `STARTED`,
ForgeOS constructs and initializes PhoneHost. `STARTED` proves runtime
activation, not later Host readiness. Failed Host creation or initialization
retains no partial reference and shuts ForgeOS down through its existing
lifecycle to `STOPPED`.

`DeviceStateService` exclusively owns runtime visibility. Public show/hide
operations request changes through ForgeOS. PhoneHost never mutates State Store
or service internals. Visibility starts `HIDDEN`, is idempotent, publishes only
completed changes, is not persisted, and does not use `activeDeviceId`.

Engine remains the only FS25 lifecycle/callback listener. It completes
registration exactly once on the first eligible update after all `loadMap`
processing and persistence restoration. It uses no timer or frame threshold.
Engine delegates bounded update, draw, action, keyboard, and pointer input to
the ForgeOS-owned Host only while runtime-active.

PhoneHost owns only transient presentation and input interpretation. M2.010
renders a minimal Phone frame, Home surface, declarative active app,
presentation and route identities, unread count, and retained-notification
tray. It does not render application controllers or execute route controllers.

Persisted resume data is obtained through the narrow internal Navigation
operation `getValidatedResumeDestination(deviceId)`. PhoneHost may orchestrate
the existing open, activate, and navigate operations, but gains no new
cross-service transaction or rollback guarantee.

This responsibility split also governs M2.011 Laptop Host unless a later
accepted architecture explicitly supersedes it.

## Consequences

- Production now owns all three registration participants and reaches
  `RUNTIME_ACTIVE` after deferred completion.
- Runtime Host readiness occurs after `STARTED` and must be logged and tested
  separately.
- Host definitions remain stable while runtime instances and visibility are
  recreated each lifecycle.
- Engine remains the single integration point with FS25 callbacks.
- Tests that installed a production placeholder Host must use the real
  registry; artificial participants remain only in isolated coordinator tests.

## Deferred Scope

Laptop Host, multiple or remote Host instances, multiplayer identity,
third-party Host namespaces, persisted active-device focus, general state
services, general UI infrastructure, application-controller rendering,
general multi-service transactions, notification actions, and
notification-driven navigation remain deferred.
