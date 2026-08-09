# FORGE ForgeOS Architecture

**Version:** 0.1  
**Status:** Approved
**Milestone:** M2 – ForgeOS Foundation

---

# Purpose

ForgeOS is the shared operating environment for all interactive FORGE user
interfaces.

Its purpose is to provide a common application platform that can be hosted by
multiple devices while remaining completely independent of gameplay systems and
presentation layers.

ForgeOS is **not** the phone.

ForgeOS is the operating system.

The phone, laptop, and any future devices are presentation hosts that consume
the same ForgeOS services.

---

# Vision

ForgeOS allows every user-facing application within FORGE to behave
consistently regardless of which device is currently being used.

Rather than implementing separate phone and laptop systems, ForgeOS provides a
single operating environment that manages:

- applications
- navigation
- lifecycle
- notifications
- persistent OS state
- device capabilities

This architecture ensures every interface behaves consistently while allowing
each device to present information differently.

---

# Design Goals

ForgeOS has the following goals.

- Shared application platform.
- Device-independent architecture.
- Data-driven registration.
- Modular application lifecycle.
- Persistent operating system state.
- Event-driven communication.
- Multiplayer-aware design.
- Future extensibility.

ForgeOS must never contain gameplay-specific logic.

Gameplay systems expose applications to ForgeOS but remain authoritative over
their own rules and state.

---

# Architecture Overview

```text
                     FORGE Engine
                           │
                           ▼
                     ForgeOS Core
                           │
      ┌────────────────────┼────────────────────┐
      │                    │                    │
      ▼                    ▼                    ▼
 Device Registry     App Registry      Navigation State
      │                    │                    │
      ▼                    ▼                    ▼
 Device Profiles     Application State   Notifications
      │                    │
      └──────────────┬─────┘
                     ▼
        Device Host Implementations
          ┌──────────┴──────────┐
          ▼                     ▼
      Phone Host           Laptop Host
          │                     │
          └──────────┬──────────┘
                     ▼
             Registered Applications
```

ForgeOS coordinates application registration, availability, presentation
resolution, lifecycle, navigation, notifications, and operating-system state
through specialised registries and services.

Device host implementations own presentation.

Gameplay managers own gameplay.

ForgeOS MUST NOT own application business logic or domain behaviour.

---

# Architectural Layers

ForgeOS is divided into four logical layers.

## ForgeOS Core

The ForgeOS Core coordinates operations and exposes the public ForgeOS API for:

- device registration
- application registration
- lifecycle management
- navigation state
- notifications
- application availability
- operating system persistence

Registries and specialised services own their state, mutation rules, and
invariants. ForgeOS Bootstrap owns startup and shutdown coordination.

The ForgeOS Core MUST never render a user interface or directly own registry
and service state.

---

## Device Host Implementations

Device host implementations provide visual presentation and user interaction.

Initial device host implementations include:

- Phone
- Laptop

Future device types and their host implementations may include:

- Vehicle displays
- Control terminals
- Dedicated consoles
- Tablet interfaces

Device host implementations own:

- rendering
- controls
- animations
- layouts
- input translation

Device host implementations MUST never own application registration.

---

## Applications

Applications provide user-facing access to gameplay systems.

Examples include:

- Projects
- Banking
- Companies
- Communications
- Settings

Applications define:

- metadata
- presentation controllers
- routes
- UI state

Applications MUST never own gameplay rules.

---

## Domain Managers

Gameplay systems remain completely separate from ForgeOS.

Examples include:

- Project Manager
- Banking Manager
- Company Manager
- Communications Manager

Example relationship:

```text
Project Manager
       │
       ▼
 Projects App
       │
       ▼
    ForgeOS
       │
       ▼
 Phone / Laptop
```

---

# Device Model

ForgeOS separates logical device identity, registered definitions, presentation
code, runtime host objects, and player-scoped state.

## Canonical Device Terminology

The following terms are authoritative across ForgeOS documentation.

### Device type

A logical device identity such as `phone` or `laptop`. A device type is stable
and does not identify a runtime object.

### Device definition/profile

The registered capabilities and policy for a device type. A device
definition/profile is data and MUST NOT contain rendering objects or player
runtime state.

### Device host implementation

Code that renders a device type and translates user input into ForgeOS
requests. It MUST NOT own registration, application lifecycle truth,
availability truth, navigation truth, or gameplay rules.

### Device host instance

A runtime host object created from a device host implementation. Host instances
contain presentation resources and other transient runtime data and MUST NOT be
persisted.

### Player device state

One player's visibility, application lifecycle, navigation, and resume state
for a device type. Player device state is distinct from the device
definition/profile and from every device host instance.

Other ForgeOS documents MUST use these terms with these meanings and MUST
reference this section rather than redefine them independently.

Initial device identifiers:

```text
phone
laptop
```

Each device definition/profile may expose capabilities such as:

- touch input
- mouse input
- keyboard input
- notifications
- background applications
- fullscreen applications
- windowed applications
- multitasking

General ForgeOS services MUST never hardcode phone or laptop presentation
behaviour. Approved bootstrap code may register built-in device profiles and
Host implementations; their presentation behavior remains inside each Host.

## M2.010 Production Host Ownership

The production Device Host Registry owns immutable Host definitions and
device-to-Host validation. ForgeOS bootstrap owns the one local runtime
PhoneHost instance. A runtime-only Device State Service owns visibility.
PhoneHost requests state changes through ForgeOS and never mutates State Store,
registries, persistence, or other service internals.

Production registration is completed once during the first eligible Engine
update after `loadMap()` and persistence restoration finish. Successful
completion enters `RUNTIME_ACTIVE` and publishes `STARTED`; PhoneHost is created
and initialized afterward. `STARTED` therefore proves ForgeOS runtime
activation, not later Host readiness.

---

# Application Model

Applications are registered with ForgeOS.

Each application has:

- unique identifier
- display name
- icon identifier
- supported devices
- required capabilities
- lifecycle callbacks
- default route

Example identifiers:

```text
forge.projects
forge.messages
forge.bank
forge.companies
forge.settings
```

Application identifiers become part of the public ForgeOS API and should remain
stable after release.

---

## Device Definition Profiles

A device definition/profile describes the capabilities and policy of a device
type.

Example:

```text
Phone

• Full-screen applications
• Single active application
• Notifications
• Touch navigation
```

```text
Laptop

• Windowed applications
• Multiple active applications
• Keyboard input
• Mouse input
• Task switching
```

The ForgeOS Core coordinates capability queries through the Device Registry
rather than making assumptions.

---

# Application Lifecycle

Applications transition through lifecycle states.

Authoritative lifecycle states:

```text
CLOSED
OPEN
ACTIVE
BACKGROUND
```

Application state is separated into four concerns:

- registration: registered or not registered, owned by the App Registry;
- enabled policy: enabled or disabled, supplied as validated policy or state
  input outside the Lifecycle Service;
- availability: calculated for a specific player and device type by the
  Availability Service;
- lifecycle: `CLOSED`, `OPEN`, `ACTIVE`, or `BACKGROUND`, owned by the
  Lifecycle Service.

Registration, enabled policy, and availability are not lifecycle states.
Enabled policy and calculated availability constrain whether lifecycle
transitions may occur.

Lifecycle state and valid transition invariants are owned exclusively by the
Lifecycle Service.

Applications may request transitions but do not perform them directly.

---

## M2.007 Lifecycle Service Clarification

M2.007 implements the local-player application lifecycle without adding
availability, navigation, rendering, resume restoration, or multiplayer
identity. The Lifecycle Service exclusively owns runtime-only lifecycle state,
the one-active-app mapping per device, and bounded enabled overrides.

The public facade provides `openApp(deviceId, appId)`,
`activateApp(deviceId, appId)`, `backgroundApp(deviceId, appId)`, and
`closeApp(deviceId, appId)`. Queries expose the current lifecycle state and
active app without creating records. M2.007 resolves player scope through
`ForgeOSPlayerId.LOCAL`.

Entering `OPEN` requires successful Presentation Resolver eligibility.
Registered apps default enabled; a runtime-only internal override constrains
open and activate but never background or close. Availability providers are
not executed.

Callbacks execute after complete validation and staging but before ForgeOS
state commit. If every callback succeeds, all staged lifecycle state and
active-app changes commit atomically, followed by completed events. If a
callback fails, no ForgeOS lifecycle state or lifecycle event is committed.
ForgeOS does not roll back arbitrary application-owned callback side effects.
No rollback callbacks, compensation, replay, or cross-service transaction is
part of M2.007.

When activation displaces another active app, a device with
`BACKGROUND_APPS` backgrounds it; otherwise ForgeOS closes it. The displaced
callback and event precede the requested app callback and event. Lifecycle
operations are service-locally non-reentrant.

Production remains at `REGISTRATION_OPEN` until the Device Host Registry is
implemented. Controlled M2.007 verification uses an explicit test participant.

---

# Application Availability

Registration and availability are separate concepts.

A registered application may become unavailable because:

- unsupported device
- missing capability
- gameplay progression
- company restrictions
- campaign rules
- administrator restrictions

Applications remain registered even when unavailable.

---

# Presentation Support

One application has one stable application identifier and MAY provide exact
device, capability-based, and default presentations.

When `supportedDevices` supplies an exact declaration for a device type, that
declaration is authoritative. An explicit `true` permits the device type, and
an explicit `false` is an absolute block. Capability matching and default
presentation fallback MUST NOT override an explicit `false`.

Capability-based or default presentation fallback MAY apply to an undeclared
future device type only when the application sets
`allowCapabilityFallback = true`. The optional field defaults to `false`;
without explicit opt-in, undeclared device types are unsupported.

Presentation resolution MUST:

1. evaluate any exact `supportedDevices` declaration;
2. reject an explicit `false`;
3. resolve an exact device presentation where available;
4. resolve a compatible capability presentation when fallback is permitted;
5. resolve the declared default presentation when support and fallback rules
   permit it; or
6. mark the application unavailable.

App-level `requiredCapabilities` are universal minimum requirements.
Presentation-level `requiredCapabilities` are additional requirements for the
selected presentation. Both MUST pass, and presentation requirements MUST NOT
weaken or override app-level requirements.

---

# ForgeOS Operating Phases

ForgeOS has one registration lifecycle. During `REGISTRATION_OPEN`, the Device
Registry MAY register device definitions/profiles, the Device Host Registry MAY
register device host implementations, and the App Registry MAY register
application definitions. Runtime device host instances do not participate in
registration.

Public content registration MUST remain forbidden during `INITIALISING`.
Internal service creation and persistence setup during that phase are not
public registration.

Entering `VALIDATING` closes registration, and validation MUST operate on the
stable registration sets of all three registries. `REGISTRATION_FROZEN` means
validation succeeded and all three registration sets are immutable. Restored
references MAY be validated and repaired, and final runtime preparation MAY
occur, but normal runtime operations remain unavailable. `RUNTIME_ACTIVE` is
the first phase in which normal public runtime operations are permitted;
registration remains closed.

The complete permitted and forbidden operation contract for every phase is
defined in `ForgeOSDefinitions.md`.

## M2.003A Core Lifecycle Clarification

### Architectural Intent

This clarification makes the Approved v0.1 contracts sufficiently
deterministic for the M2.003A Core Lifecycle Foundation. It introduces no new
ForgeOS capability and does not resolve decisions outside that implementation
stage.

### Contract

`FORGE.ForgeOS` is the stable public ForgeOS facade. The facade may exist while
ForgeOS is unavailable and does not expose mutable lifecycle state or direct
State Store data.

ForgeOS Core owns the authoritative phase, validates lifecycle transition
requests, performs permitted phase changes, and supplies phase-gating queries.
ForgeOS Bootstrap coordinates startup and shutdown and requests lifecycle
changes from Core. Bootstrap MUST NOT mutate lifecycle state directly.

M2.003A ends at `REGISTRATION_OPEN`. Validation, registration freeze, runtime
activation, and the `STARTED` event remain deferred. Normal runtime operations
therefore remain unavailable throughout this stage.

### Rationale

The clarification establishes deterministic ownership and observable
behaviour without defining registry or runtime APIs ahead of their approved
implementation stages.

## M2.003B Registration Coordination Clarification

### Architectural Intent

M2.003B separates registration lifecycle coordination from concrete registry
implementation. It introduces no registry storage, lookup, identifier
validation, duplicate detection, or registry-specific invariant.

### Contract

The ForgeOS Registration Coordinator orchestrates the three required
Registration Participant roles:

```text
Device Registry
Device Host Registry
App Registry
```

All three roles MUST be installed exactly once for a ForgeOS lifecycle before
startup may leave `REGISTRATION_OPEN`. Concrete participants retain ownership
of their registration data, mutation rules, validation rules, freeze
invariants, and cleanup.

The coordinator requests lifecycle changes from Core and MUST NOT mutate phase
state directly. Registration completion is internal to the coordinator. The
public facade exposes the overall startup operation:

```lua
FORGE.ForgeOS:completeStartup()
```

Successful completion proceeds through `VALIDATING`,
`REGISTRATION_FROZEN`, and `RUNTIME_ACTIVE`. This phase transition does not
implement device, host, application, navigation, notification, or other
runtime-active subsystem behaviour.

### Rationale

The coordinator establishes one deterministic lifecycle mechanism while
leaving concrete registry capabilities in their dedicated milestones.

## M2.004 Device Registry Clarification

### Architectural Intent

This clarification makes the Approved ForgeOS v0.1 Device Registry contract
sufficiently deterministic for M2.004. It introduces no Device Host Registry,
App Registry, host-binding, policy, metadata, or third-party namespace
capability.

### Contract

The Device Registry owns authoritative device definitions, lifecycle-local
identifier uniqueness, controlled storage and retrieval, registry-specific
validation and freeze invariants, cleanup, and successful device-registration
event publication.

ForgeOS Core exposes the public facade and delegates registry operations. The
Registration Coordinator coordinates the registry as its required Device
Registry participant but does not own device definitions or their invariants.
The Device Host Registry retains responsibility for concrete hosts and host
lookup.

The public M2.004 facade is:

```lua
FORGE.ForgeOS:registerDevice(deviceDefinition)
FORGE.ForgeOS:isDeviceRegistered(deviceId)
FORGE.ForgeOS:getDeviceDefinition(deviceId)
FORGE.ForgeOS:getRegisteredDeviceIds()
```

`registerDevice()` returns one `ForgeOSResult`. Queries return primitive or
detached read-only values, do not mutate state, and do not publish events.
Definitions are copied into controlled storage, query results are detached,
and identifier enumeration is lexically ordered.

One production Device Registry participant is installed after Core enters
`REGISTRATION_OPEN` and before `REGISTRATION_OPENED` observers are invited to
register. Installation failure follows the existing partial-startup rollback
contract. Cleanup clears definitions and frozen state, and restart reinstalls
the participant for the new lifecycle.

M2.004 does not automatically register built-in device profiles. Production
ForgeOS remains at `REGISTRATION_OPEN` until concrete Device Host Registry and
App Registry participants exist. Explicit test participants may represent
those deferred roles in development verification only.

### Rationale

This establishes an authoritative concrete registry without absorbing later
registry ownership or silently resolving preserved identifier and host-binding
decisions.

## M2.005 App Registry Clarification

### Architectural Intent

This clarification makes the Approved ForgeOS v0.1 App Registry contract
sufficiently deterministic for M2.005. It introduces no Presentation Resolver,
application Lifecycle Service, Navigation Service, Availability Service, Owner
Registry, or Device Host Registry capability.

### Contract

The App Registry owns authoritative application definitions,
lifecycle-local identifier uniqueness, controlled storage and retrieval,
registry-specific validation and freeze invariants, cleanup, and successful
application-registration event publication.

ForgeOS exposes the public facade and delegates registry operations. The
Registration Coordinator coordinates the registry as its required App Registry
participant but does not own application definitions or their invariants.

The public M2.005 facade is:

```lua
FORGE.ForgeOS:registerApp(appDefinition)
FORGE.ForgeOS:isAppRegistered(appId)
FORGE.ForgeOS:getAppDefinition(appId)
FORGE.ForgeOS:getRegisteredAppIds()
```

`registerApp()` returns one `ForgeOSResult`. Queries return primitive or
detached public definition data, do not mutate state, and do not publish
events. Registered identifiers are lexically ordered.

Executable references, including controllers, callbacks, provider functions,
route controllers, and action handlers, are runtime-owned implementation
assets. The registry may retain them privately for later milestones, but they
are intentionally excluded from serialization and public definition
snapshots. M2.005 does not invoke them.

One production App Registry participant is installed after the Device Registry
and before `REGISTRATION_OPENED` observers are invited to register.
Installation failure follows the existing partial-startup rollback contract.
Cleanup clears definitions, private runtime assets, and frozen state.

Before M2.010, production ForgeOS remained at `REGISTRATION_OPEN` because no
concrete Device Host Registry participant existed. M2.010 supplies the real
participant; production now completes registration on the first eligible
post-load Engine update without a placeholder participant.

### Rationale

This establishes the approved application-definition authority without
absorbing presentation selection, application execution, navigation,
availability, ownership enforcement, or host behaviour.

## M2.006 Presentation Resolver Clarification

### Architectural Intent

This clarification makes the Approved v0.1 presentation-resolution contract
deterministic for M2.006. It introduces no Device Host Registry production
behaviour, availability execution, lifecycle, navigation, rendering,
persistence, or new definition constant.

### Public Contract

`FORGE.ForgeOS:resolvePresentation(appId, deviceId)` returns
`result, resolution`. Success provides the app ID, device ID, selected
presentation key and ID, `PresentationMatchType`, and a detached presentation.
Controlled failures may provide an `AppAvailabilityReason` and one
deterministic `missingCapability`.

The resolver is read-only, is permitted only in `RUNTIME_ACTIVE`, and performs
no registry lookup after a rejected runtime gate. It mutates no state,
publishes no event, executes no callback or provider, and accesses no private
App Registry executable-reference storage.

Resolution applies the exact device declaration, validates universal app
requirements, attempts the exact presentation, attempts eligible capability
presentations, then attempts the default. Explicit `false` is absolute;
undeclared fallback requires `allowCapabilityFallback = true`.

A capability candidate is neither the exact device key nor the default key and
declares at least one presentation capability. Candidates use descending
finite numeric priority, omitted priority zero, and lexical presentation key
for ties.

Missing app requirements are selected lexically and returned immediately.
Candidate requirements are evaluated lexically; the first failure in
deterministic candidate order is retained while later candidates remain
eligible to succeed. Capability failure is reported only when it is the final
failure class.

Production remains at `REGISTRATION_OPEN` while Device Host Registry is
deferred. Runtime-active behaviour uses an explicit test participant only.

---

# Navigation

The Navigation Service owns logical navigation state and its invariants.

Navigation includes:

- home
- application
- route
- modal
- history
- back stack

The ForgeOS Core coordinates navigation requests through the Navigation
Service.

Device host implementations decide how navigation is presented visually.

## M2.008 Navigation Service Clarification

M2.008 owns logical runtime navigation for the active `player.local`
application. App Registry remains authoritative for presentation-scoped route
declarations; no Route Registry, late route registration, or new registration
participant is introduced.

Public `navigate(deviceId, appId, routeId, routeParameters)` and
`goBack(deviceId, appId)` operations require `RUNTIME_ACTIVE`, registered app
and device, an `ACTIVE` app lifecycle state, a successfully resolved
presentation, and a route declared by that presentation. Navigation never
performs an implicit lifecycle transition.

Navigation Service owns the current route, detached parameters, and bounded
runtime history per local player, device, and app. History is ordered oldest
to newest, evicts the oldest entry deterministically when its private capacity
is exceeded, and is never persisted. The private capacity is not a public
definition or compatibility contract.

Successful non-idempotent navigation atomically commits logical navigation and
plain-data resume destination before publishing `NAVIGATION_CHANGED`.
Idempotent navigation mutates no history or resume state and publishes no
event. Route controllers, availability providers, actions, modals, rendering,
and automatic resume remain deferred.

---

# Notifications

The Notification Service owns shared notification state and its invariants.
ForgeOS Core coordinates notification requests through that service.

Notifications may originate from:

- gameplay managers
- applications
- engine events

Examples:

```text
New Project Available

Loan Payment Due

Employee Message

Company Reputation Increased
```

Notification state belongs to the Notification Service rather than individual
applications. M2.009 resolves the delivery-record/gameplay-fact boundary;
multiplayer authority and host delivery acknowledgement remain open.

## M2.009 Notification Foundation Clarification

M2.009 makes the player-facing delivery-record boundary deterministic for the
isolated `player.local` scope. Originating domains remain authoritative for
gameplay facts; Notification Service exclusively owns generated notification
identifiers, detached delivery records, read and dismissed state, ordering,
persistence-policy handling, and completed notification events.

The public facade provides `createNotification(definition)`,
`markNotificationRead(notificationId)`, and
`dismissNotification(notificationId)`. Read-only queries expose one detached
record or an oldest-to-newest detached list optionally filtered by registered
target device and dismissed state. Operations require `RUNTIME_ACTIVE`.

The M2.009 public facade is frozen for implementation as:

```text
createNotification(definition) -> ForgeOSResult, notificationId | nil
markNotificationRead(notificationId) -> ForgeOSResult
dismissNotification(notificationId) -> ForgeOSResult
getNotification(notificationId) -> detachedNotification | nil
getNotifications(deviceId, includeDismissed) -> detachedNotifications
```

No public player identifier is accepted. M2.009 resolves every operation to
`ForgeOSPlayerId.LOCAL`. The read-only queries intentionally use primitive
results: `nil` or an empty array means no readable query result and does not
classify absence, invalid input, runtime unavailability, or internal failure.
Unexpected query and restoration failures produce one controlled internal
diagnostic without exposing partial notification state.

Every successful creation receives a monotonic unpadded
`notification.<decimal sequence>` identifier. This includes transient
notifications, which advance the persisted sequence but retain no record.
Session records remain runtime-only. Savegame records and the next sequence
use the existing `forge.os` namespace. Failed creation consumes no identifier.

Targets declare possible future host presentation only. They do not establish
delivery, visibility, app availability, or gameplay authority. Optional routes
are executable-free declarative destinations and are not resolved or navigated
during notification creation.

Retained storage is bounded. Deterministic reclamation removes the oldest
dismissed record first, otherwise the oldest read record. Unread and
undismissed records are never silently evicted. The initial private capacity is
not a public definition or compatibility contract.

Restoration rejects malformed or unsafe records. Every member of a duplicate
identifier or duplicate creation-order conflict group is discarded; no winner
depends on Lua iteration. Repair preserves unrelated ForgeOS state, honours a
valid persisted next sequence, advances it where required, and publishes no
notification event.

M2.009 introduces no rendering, notification action, navigation, host
behaviour, gameplay authority, stable multiplayer identity, per-player
persistence, time-based expiry, or general ForgeOS State Service.

---

# Persistence

ForgeOS persistent state MUST use the existing FORGE persistence framework.

Authoritative State Store namespace:

```text
forge.os
```

The `forge.os` namespace is a stable persistence-facing identifier.

Persisted resume state MAY include:

- last valid application
- last valid presentation
- last valid route
- safe route parameters
- approved preferences

Runtime rendering objects and ephemeral presentation state MUST NOT be
persisted. Stable plain-data presentation preferences or resume state MAY be
persisted only when included in the ForgeOS state contract.

Raw `forge.os` data MAY be restored through the existing Engine persistence
infrastructure during `INITIALISING`, but references depending on registered
apps, devices, presentations, or routes MUST NOT yet be treated as validated.
During `REGISTRATION_FROZEN`, those references MAY be validated, repaired, or
discarded against the frozen registration set. During `RUNTIME_ACTIVE`, only
validated and reconstructed runtime state MAY be exposed. ForgeOS MUST NOT
blindly restore runtime rendering objects or replay stale lifecycle state.

Current persistence remains savegame-global. M2 MAY use the isolated
`player.local` identity resolver; true per-player multiplayer persistence is
not yet implemented.

Presentation-only preferences SHOULD be player-local. Preferences that affect
gameplay access, permissions, progression, company policy, or other
authoritative behaviour MUST remain server-authoritative or
domain-authoritative. Presentation preferences MUST NOT alter gameplay
authority. The exact persistence mechanism remains open.

ForgeOS MUST NOT access XML directly.

---

# Events

ForgeOS publishes lifecycle events through the Event Bus.

Examples:

```text
forge.os.device.registered
forge.os.device.changed

forge.os.app.registered
forge.os.app.opened
forge.os.app.closed
forge.os.app.activated
forge.os.app.backgrounded

forge.os.navigation.changed

forge.os.notification.created
forge.os.notification.dismissed
```

All event names will be defined authoritatively.

---

# Multiplayer

ForgeOS distinguishes between:

- authoritative shared state
- player-local interface state

Gameplay data belongs to the authoritative simulation.

Visual interface state remains local unless explicitly synchronised.

ForgeOS state is conceptually scoped per player and per device. M2 MAY use the
isolated `player.local` identity resolver. Current persistence remains
savegame-global and does not provide true per-player multiplayer persistence.
The documentation and public contracts MUST NOT imply that multiplayer player
identity or persistence is already solved.

---

# Future Expansion

ForgeOS is designed to support additional systems without architectural changes.

Potential future applications include:

- Fleet Management
- Inventory
- Marketplace
- Contracts
- Calendar
- Email
- GPS
- Weather
- HR
- Accounting

Future devices may include:

- Vehicle terminals
- Tablet interfaces
- Wall displays
- Dedicated control panels

---

# Architectural Rules

1. ForgeOS Core MUST coordinate operations and expose the public API.
2. Registries and specialised services MUST own their state, mutation rules,
   and invariants.
3. ForgeOS Bootstrap MUST own startup and shutdown coordination.
4. ForgeOS Core MUST NOT render UI.
5. Device host implementations MUST NOT own application registration.
6. Applications MUST NOT own gameplay rules.
7. Gameplay managers MUST NOT depend on presentation.
8. Device capabilities MUST be data-driven.
9. Navigation state and invariants MUST belong to the Navigation Service.
10. Notification state and invariants MUST belong to the Notification Service;
    multiplayer authority and host delivery acknowledgement remain unresolved.
11. Persistence MUST use State Store and Save Manager.
12. Public application identifiers MUST remain stable.
13. Campaign authors SHOULD interact through the Campaign SDK rather than
    private ForgeOS internals.
14. ForgeOS MUST NOT report a multi-service operation as successful while
    exposing partially committed lifecycle, navigation, resume, notification,
    or visibility state. Staging, rollback, callback timing, and re-entrancy
    remain open architectural decisions.

---

# Initial Scope

The ForgeOS Foundation milestone establishes:

- ForgeOS architecture
- ForgeOS definitions
- Device Registry
- App Registry
- App Lifecycle
- Navigation
- Notifications
- Persistence
- Phone host foundation
- Laptop host foundation
- Testing
- Documentation

The following are intentionally excluded:

- Projects gameplay
- Banking gameplay
- Company gameplay
- Communications gameplay
- Campaign SDK
- Final UI artwork

These systems will build upon the ForgeOS foundation during later milestones.

---

# Success Criteria

ForgeOS Foundation is complete when the engine can:

1. Register multiple devices.
2. Register multiple applications.
3. Determine application availability.
4. Open applications.
5. Close applications.
6. Activate applications.
7. Maintain navigation state.
8. Persist operating system state.
9. Restore operating system state after reload.
10. Support multiple device host implementations without duplicating operating system logic.

---

# Summary

ForgeOS provides a reusable operating environment for every interactive system
within FORGE.

It separates gameplay from presentation, enabling multiple devices to expose
the same applications while maintaining a single authoritative operating
system.

ForgeOS forms the foundation upon which all future user-facing systems,
including Projects, Banking, Companies, Communications, and the Campaign SDK,
will be built.

---

## Provisional FS25 Cross-Mod Acquisition Adapter

M2.010 introduces `FORGE.ForgeOSExportBridge` as a narrow FS25 adapter carried
by the local process's `g_messageCenter`. A dependent mod publishes one
version-1 request on `forge.crossMod.forgeOS.request.v1`; a single active FORGE
provider may return only the existing `FORGE.ForgeOS` facade through the
caller-owned response table. Dependency ordering does not place FORGE globals
inside another mod's custom Lua environment.

The bridge is local-process only. It provides no RPC, network authority, state
access, registration storage, or access to the surrounding FORGE namespace.
Its exact message-center protocol remains provisional until real cross-mod
runtime verification succeeds. [ADR-004](../adr/ADR-004-FS25-Cross-Mod-ForgeOS-Export-Bridge.md)
records the approved implementation boundary and evidence requirement.

# Related Documentation

- [M2 Architecture Review](../reviews/M2ArchitectureReview.md) records accepted
  decisions, deferred assumptions, and remaining architecture gaps.
- [Engineering Process](../style/EngineeringProcess.md) defines review,
  approval, implementation, and verification governance.
