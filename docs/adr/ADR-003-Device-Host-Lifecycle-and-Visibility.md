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

ForgeOS bootstrap owns a private bounded production Host collection. M2.011
contains exactly one PhoneHost and one LaptopHost, keyed by device identifier.
Construction, initialization, update, draw, and eligible keyboard dispatch use
fixed Phone-then-Laptop order; shutdown uses Laptop-then-Phone order. After
deferred registration completion reaches `RUNTIME_ACTIVE` and publishes
`STARTED`, ForgeOS constructs and initializes the complete Host set. `STARTED`
proves runtime activation, not later Host readiness.

Host startup is atomic. Any construction or initialization failure retains no
partial Host collection, shuts down staged Hosts in reverse order, clears
Device State runtime entries, restores gameplay cursor mode, and shuts ForgeOS
down through its existing lifecycle to `STOPPED`. M2.011 permits no degraded
Phone-only production mode.

`DeviceStateService` exclusively owns runtime visibility. Public show/hide
operations request changes through ForgeOS. PhoneHost never mutates State Store
or service internals. Visibility starts `HIDDEN`, is idempotent, publishes only
completed changes, is not persisted, and does not use `activeDeviceId`.

Engine remains the only FS25 lifecycle/callback listener. It completes
registration exactly once on the first eligible update after all `loadMap`
processing and persistence restoration. It uses no timer or frame threshold.
Engine delegates bounded update, draw, action, keyboard, and pointer input to
the ForgeOS-owned Host only while runtime-active.

PhoneHost and LaptopHost own only transient presentation and input
interpretation. M2.010
renders a minimal Phone frame, Home surface, declarative active app,
presentation and route identities, unread count, and retained-notification
tray. It does not render application controllers or execute route controllers.

Persisted resume data is obtained through the narrow internal Navigation
operation `getValidatedResumeDestination(deviceId)`. PhoneHost may orchestrate
the existing open, activate, and navigate operations, but gains no new
cross-service transaction or rollback guarantee.

M2.011 applies the same boundary to a bounded Laptop shell with one active app
surface, launcher, navigation identity, and retained notification tray. Phone
and Laptop visibility and device state remain independent and may both be
visible. No `activeDeviceId` or visibility persistence is introduced.

Engine remains the cursor adapter owner. The documented FS25
`g_inputBinding:setShowMouseCursor()` facility carries the bounded
`GAMEPLAY`/`FORGE_POINTER` transition, and `g_gui:getIsGuiVisible()` gives
higher-priority GIANTS UI precedence. Hosts never manipulate cursor, camera, or
input contexts. `FORGE_TOGGLE_LAPTOP` with F8 is a remappable M2.011
development/fallback adapter, not the permanent Laptop interaction model.

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

Remote or arbitrary Host instances, multiplayer identity, third-party Host
namespaces, persisted active-device focus, general state
services, general UI infrastructure, application-controller rendering,
general multi-service transactions, notification actions, and
notification-driven navigation remain deferred.

The intended future Laptop entry point is a physical in-world object using a
separate world/device adapter to request `showDevice(laptop)`. Object placement,
ownership, persistence, targeting, proximity, animation, and multiplayer world
authority are not part of M2.011.
