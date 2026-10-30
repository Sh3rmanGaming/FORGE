# FORGE ForgeOS Component Design

**Version:** 0.1  
**Status:** Approved
**Milestone:** M2 – ForgeOS Foundation

---

# Purpose

This document defines the internal component design of ForgeOS.

It translates the high-level ForgeOS architecture into specific components with
clear responsibilities, dependencies, ownership boundaries, and interaction
rules.

The goal is to prevent device presentation, application metadata, lifecycle
state, navigation, notifications, and gameplay systems from becoming tightly
coupled as ForgeOS grows.

---

# Design Principles

ForgeOS follows these principles:

- one shared operating-system core
- multiple presentation hosts
- explicit component ownership
- controlled state transitions
- event-driven integration
- data-driven device and application registration
- persistent OS state through FORGE persistence
- no gameplay rules inside ForgeOS
- no UI rendering inside ForgeOS Core
- no device-specific branching inside shared components

---

# Component Overview

```text
FORGE Engine
    │
    ▼
ForgeOS Bootstrap
    │
    ├── ForgeOS Core
    │     ├── Device Registry
    │     ├── App Registry
    │     ├── Availability Service
    │     ├── Lifecycle Service
    │     ├── Navigation Service
    │     ├── Notification Service
    │     └── ForgeOS State
    │
    ├── Device Hosts
    │     ├── Phone Host
    │     └── Laptop Host
    │
    └── Registered Applications (conceptual roadmap set)
          ├── Settings App
          ├── Communications App
          ├── Projects App
          ├── Banking App
          └── Companies App
```

Domain managers remain outside ForgeOS:

```text
Project Manager
Banking Manager
Company Manager
Communications Manager
```

Applications bridge domain managers into ForgeOS.

The diagram is a responsibility map, not an implementation inventory. M3.001
specifies `forge.communications` as the first post-M2 domain application. Other
listed applications and any unimplemented services remain future work until
their own approved milestones.

---

# Component Dependency Direction

Dependencies must move inward toward shared services and outward toward
presentation only through public APIs.

```text
Domain Manager
      │
      ▼
ForgeOS Application
      │
      ▼
ForgeOS Core
      │
      ▼
Device Host
      │
      ▼
Rendered UI
```

The reverse dependency is not allowed.

A domain manager must not depend on:

- Phone Host
- Laptop Host
- ForgeOS navigation rendering
- device-specific controls
- application icons
- window or screen layout

---

# ForgeOS Bootstrap

## Responsibility

The ForgeOS Bootstrap coordinates ForgeOS startup and shutdown.

It is responsible for:

- initialising ForgeOS state
- registering the ForgeOS persistence namespace
- registering built-in devices
- registering built-in applications
- restoring persistent ForgeOS state
- connecting ForgeOS to the FORGE Event Bus
- coordinating ForgeOS shutdown

## Must Not Own

The bootstrap must not own:

- application lifecycle rules
- device definitions
- navigation logic
- notification logic
- gameplay state
- UI rendering

## Location

```text
forgeos/ForgeOS.lua
```

## Dependency Direction

```text
FORGE Engine
    ↓
ForgeOS Bootstrap
    ↓
ForgeOS Components
```

The Engine should know only how to start and stop ForgeOS.

---

# ForgeOS Core

## Responsibility

ForgeOS Core is the public coordination layer for ForgeOS.

It provides a stable API through which other systems can:

- register devices
- register applications
- query application availability
- open applications
- activate applications
- close applications
- perform navigation
- create notifications
- query ForgeOS state

## Must Not Own

ForgeOS Core must not directly own:

- registry storage
- device rendering
- application rendering
- domain gameplay logic
- XML persistence
- FS25 mission callbacks

The Core coordinates specialised ForgeOS components.

## Location

```text
forgeos/ForgeOSCore.lua
```

## Example Public Interaction

```lua
FORGE.ForgeOS:registerDevice(deviceDefinition)

FORGE.ForgeOS:registerApp(appDefinition)

FORGE.ForgeOS:openApp(
    "phone",
    "forge.projects"
)
```

These are conceptual interfaces only. Final names will be defined during the
ForgeOS API design phase.

## M2.003A Public Facade Clarification

### Architectural Intent

This clarification defines only the lifecycle and compatibility surface needed
for M2.003A. Future ForgeOS API design remains responsible for registration,
device, application, navigation, notification, and state-operation methods.

### Contract

The M2.003A public facade is:

```lua
FORGE.ForgeOS
```

It exposes these read-only queries:

```lua
FORGE.ForgeOS:getPhase()
FORGE.ForgeOS:getAppApiVersion()
FORGE.ForgeOS:supportsAppApiVersion(requiredVersion)
FORGE.ForgeOS:isAvailable()
FORGE.ForgeOS:isRegistrationOpen()
FORGE.ForgeOS:isRuntimeActive()
```

Queries return primitive or read-only values and never mutate state or publish
events. `isAvailable()` and `isRuntimeActive()` are true only during
`RUNTIME_ACTIVE`. `isRegistrationOpen()` is true only during
`REGISTRATION_OPEN`. Compatibility queries remain permitted in every phase.

Operations that request state changes return a `ForgeOSResult`. For M2.003A,
the lifecycle operations are:

```lua
FORGE.ForgeOS:start()
FORGE.ForgeOS:shutdown()
```

Bootstrap coordinates those operations, but Core owns the authoritative phase
and performs every phase change. Bootstrap requests lifecycle changes and
MUST NOT mutate lifecycle state directly. The transition operation is internal
and is not part of the public facade.

### Rationale

Primitive queries report facts, while result-bearing operations request state
changes. This distinction provides a consistent API rule without prematurely
defining later subsystem operations.

## M2.003B Registration Coordinator

### Responsibility

The Registration Coordinator owns:

- registration-participant coordination;
- validation and freeze orchestration;
- deterministic participant ordering;
- registration-gate results;
- registration lifecycle transition requests; and
- participant cleanup coordination.

It does not own registered definitions, registry storage, duplicate detection,
identifier validation, registry-specific invariants, or concrete lookup APIs.

### Registration Participant Contract

A Registration Participant is an internal ForgeOS component that owns one
complete registration set. It MUST implement:

```lua
participant:getRegistrationRole()
participant:validateRegistrationSet()
participant:freezeRegistrationSet()
participant:clearRegistrationSet()
participant:isRegistrationSetFrozen()
```

Return contracts:

| Operation | Return |
|---|---|
| `getRegistrationRole()` | One coordinator-recognised internal role |
| `validateRegistrationSet()` | One `ForgeOSResult` |
| `freezeRegistrationSet()` | One `ForgeOSResult` |
| `clearRegistrationSet()` | One `ForgeOSResult` |
| `isRegistrationSetFrozen()` | Boolean |

Validation MUST NOT freeze or mutate the registration set. Successful freeze
makes the set immutable. Cleanup MUST be safe and idempotent. The participant
contract is internal and does not define public addon or concrete registry
APIs.

### Required Roles and Ordering

Exactly one participant is required for each role. Coordination order is:

```text
Device Registry
    ↓
Device Host Registry
    ↓
App Registry
```

Registration order, addon load order, Lua table iteration order, and callback
insertion order MUST NOT determine coordination order.

The role identifiers are defined once inside the M2.003B coordinator
implementation boundary. They are not added to the public ForgeOS definitions
package.

### Startup Completion

The public facade exposes:

```lua
FORGE.ForgeOS:completeStartup()
```

The coordinator internally completes registration. All participants validate
before freeze begins. Missing, duplicate, or invalid role assignments prevent
startup from leaving `REGISTRATION_OPEN`.

Validation or freeze failure MUST NOT expose partially completed registration
as runtime-active. ForgeOS shuts down and invokes idempotent cleanup for every
installed participant. Registration is not automatically reopened.

### Registration Gate

The shared internal gate returns `SUCCESS` only during `REGISTRATION_OPEN` and
`REGISTRATION_CLOSED` in every other phase. Future concrete registries MUST
consult this gate before committing registration state.

The coordinator does not itself accept device, host, or application
definitions.

### Location

```text
forgeos/ForgeOSRegistrationCoordinator.lua
```

### Rationale

This boundary provides lifecycle coordination without absorbing the concrete
registry milestones.

---

# Device Registry

## Responsibility

The Device Registry owns authoritative registered device definitions and their
registration invariants. Device terminology follows the canonical definitions
in `ForgeOSArchitecture.md`.

It stores:

- device identifier
- display name
- capability declarations
- lifecycle policy
- supported presentation modes
- device-specific restrictions
- host binding identifier

## Example Device Definition

```lua
{
    id = "phone",
    displayName = "Phone",
    hostId = "forge.phoneHost",
    capabilities = {
        fullScreenApps = true,
        windowedApps = false,
        touchInput = true,
        pointerInput = false,
        keyboardInput = false,
        notifications = true,
        backgroundApps = true,
        multiApp = false
    }
}
```

`allowCapabilityFallback = false` means undeclared device types are unsupported.
An explicit `supportedDevices[deviceId] = false` remains an absolute block.

## Ownership

The Device Registry owns registered definitions.

The Device Registry does not own:

- active device
- current application
- host rendering
- application availability
- navigation history

## Required Operations

The public ForgeOS facade provides:

```lua
FORGE.ForgeOS:registerDevice(deviceDefinition)
FORGE.ForgeOS:isDeviceRegistered(deviceId)
FORGE.ForgeOS:getDeviceDefinition(deviceId)
FORGE.ForgeOS:getRegisteredDeviceIds()
```

`registerDevice()` is an operation returning one `ForgeOSResult`.
`isDeviceRegistered()` returns a Boolean. `getDeviceDefinition()` returns a
detached definition or `nil`. `getRegisteredDeviceIds()` returns a detached,
lexically sorted array. Queries do not mutate state or publish events.

The internal registry implements the Registration Participant contract. It
validates its complete set without mutation, freezes safely and idempotently,
rejects later registration, and clears its definitions and frozen state safely
and idempotently.

## M2.004 Registration Contract

The shared registration gate is checked before any registration mutation.
`nil` or non-table input returns `INVALID_ARGUMENT`. A supplied table that
fails schema or controlled-data validation returns `INVALID_DEFINITION`.
Duplicate detection follows successful schema validation and returns
`ALREADY_REGISTERED`. A valid atomic commit returns `SUCCESS`.
`INTERNAL_ERROR` is reserved for an unexpected internal failure.

Recognized definition fields are:

| Field | Requirement |
|---|---|
| `id` | Required non-empty string without whitespace |
| `displayName` | Required non-empty string |
| `capabilities` | Required table of recognized `DeviceCapability` keys and Boolean values |
| `hostId` | Optional non-empty string without whitespace |
| `policy` | Optional opaque plain-data table |
| `metadata` | Optional opaque plain-data table |

An empty capability table is valid. Unknown fields are omitted. Plain data may
contain finite numbers, strings, Booleans, and acyclic nested tables; it must
not contain functions, userdata, threads, callbacks, runtime objects, cycles,
or non-finite numbers.

The registry never retains caller-owned tables. Recognized fields and nested
plain data are copied into controlled storage, and definition queries return
new detached copies.

After a valid definition commits, the registry publishes
`ForgeOSEvent.DEVICE_REGISTERED` with:

```lua
{
    deviceId = registeredDeviceId
}
```

Rejected operations do not publish the event. Listener failure follows the
existing Event Bus and Logger failure path, does not roll back the committed
definition, and does not change `registerDevice()` from `SUCCESS`.

The registry enforces basic identifier validity and lifecycle-local
uniqueness only. It does not validate that `hostId` resolves, interpret
`policy` or `metadata`, or resolve third-party namespace and ownership rules.

One production Device Registry participant is installed after entry into
`REGISTRATION_OPEN` and before `REGISTRATION_OPENED` publication. M2.010 also
installs the production Device Host Registry and existing App Registry before
that event.

## Location

```text
forgeos/registries/DeviceRegistry.lua
```

---

# Device Host Registry

## Responsibility

The Device Host Registry registers device host implementations and associates
them with device definitions/profiles.

A device definition/profile describes capabilities and policy.

A device host implementation provides presentation code. A device host instance
is its runtime object and does not participate in registration. The registry
constructs instances through private factories; ForgeOS bootstrap owns every
instance returned by the registry.

Example:

```text
Device Definition
phone
    ↓
Host Binding
phoneHost
    ↓
PhoneHost runtime object
```

## Why This Is Separate

Keeping host binding separate prevents the Device Registry from becoming
responsible for UI implementation.

It also allows:

- replacing a host implementation
- development mock hosts
- future alternate interfaces
- headless tests

## Required Operations

Conceptually:

```text
register host implementation
retrieve host implementation
bind implementation to device definition/profile
unbind implementation
clear implementation registrations
```

ForgeOS has one registration lifecycle:

- during `REGISTRATION_OPEN`, the Device Registry accepts device
  definitions/profiles, the Device Host Registry accepts device host
  implementations, and the App Registry accepts application definitions;
- during `VALIDATING`, registration is closed and all three stable registration
  sets are validated;
- during `REGISTRATION_FROZEN`, all three registration sets are immutable,
  restored references MAY be validated and repaired, and final runtime
  preparation MAY occur;
- during `RUNTIME_ACTIVE`, normal public runtime operations are permitted and
  registration remains closed.

Public content registration MUST NOT occur during `INITIALISING`. Internal
service creation and persistence setup are not public registration.

## Location

```text
forgeos/registries/DeviceHostRegistry.lua
```

M2.010 installs this component as the production Device Host Registry. It owns
immutable Host definitions, binding validation, registration freeze and
cleanup, but never runtime instances or visibility.

---

# App Registry

## Responsibility

The App Registry owns authoritative application definitions.

It stores metadata and declared requirements.

## Example App Definition

```lua
{
    id = "forge.projects",
    displayName = "Projects",
    iconId = "forge.icon.projects",
    defaultRoute = "overview",
    supportedDevices = {
        phone = true,
        laptop = true
    },
    allowCapabilityFallback = false,
    requiredCapabilities = {
        notifications = true
    }
}
```

## Ownership

The App Registry owns:

- app identity
- display metadata
- device declarations
- `allowCapabilityFallback` policy
- capability requirements
- default route
- lifecycle callback references

It does not own:

- current lifecycle state
- active routes
- navigation history
- availability decisions
- gameplay data

## Required Operations

The M2.005 public facade is:

```lua
FORGE.ForgeOS:registerApp(appDefinition)
FORGE.ForgeOS:isAppRegistered(appId)
FORGE.ForgeOS:getAppDefinition(appId)
FORGE.ForgeOS:getRegisteredAppIds()
```

`registerApp()` returns one `ForgeOSResult`. Queries return primitive or
detached public definition data. Identifier enumeration is lexical.

The registry is the App Registry Registration Participant. It validates and
freezes its own set, reports frozen state, and clears its definitions and
private runtime assets during lifecycle cleanup.

One production instance is installed after the Device Registry and before
`REGISTRATION_OPENED`. The Registration Coordinator owns orchestration only.

## M2.005 Storage Boundary

Recognized declarative fields are copied into controlled registry storage.
Unknown fields are ignored. Query results are detached from authoritative
state.

Executable references are runtime-owned implementation assets. Controllers,
callbacks, availability-provider functions, route controllers, and action
handlers may be retained in private runtime storage for later milestones, but
are excluded from serialization and public snapshots. M2.005 does not invoke
them.

The App Registry records and validates the basic shape of `ownerId` but does
not resolve ownership or introduce an Owner Registry. It validates
presentation, route, action, device, and capability declarations only as
definition structure; it does not select presentations or execute lifecycle,
navigation, availability, or host behaviour.

## M2.006 Presentation Resolver

The Presentation Resolver is a read-only service using detached App Registry
and Device Registry definitions plus the Core runtime gate.

`FORGE.ForgeOS:resolvePresentation(appId, deviceId)` returns one
`ForgeOSResult` followed by a detached resolution record. The service owns
exact-device matching, structural capability comparison, priority, lexical
tie-breaking, default fallback, match-type assignment, and deterministic
missing-capability diagnostics.

Capability candidates exclude the exact and default keys and must declare at
least one capability. Higher finite numeric priority wins, omitted priority is
zero, and equal priority uses lexical presentation-key order.

App missing requirements are evaluated lexically. Candidate failures are
evaluated lexically within deterministic candidate order; the first is retained
while later candidates remain eligible to resolve.

The service owns no registration, availability policy, executable invocation,
lifecycle, navigation, rendering, persistence, or runtime state.

## Location

```text
forgeos/registries/AppRegistry.lua
```

The resolver location is:

```text
forgeos/services/PresentationResolver.lua
```

---

# Availability Service

## Responsibility

The Availability Service owns availability calculation rules and determines
whether a registered application is currently available for a device type and
a specific player.

Availability is calculated from:

- app registration
- device registration
- supported-device declaration
- required capabilities
- app enabled or disabled state
- progression or unlock state
- optional external policy checks

## Availability Result

The service should return more than a boolean where useful.

Conceptually:

```lua
{
    available = false,
    reason = "missingCapability",
    detail = "windowedApps"
}
```

This helps:

- debugging
- UI messaging
- tests
- campaign authoring
- contributor understanding

## Availability Rules

An application is available only when:

1. the app is registered
2. the device is registered
3. the app supports the device type through an authoritative exact declaration
   or `allowCapabilityFallback = true`
4. the device satisfies both the app-level universal minimum capabilities and
   the additional requirements of the selected presentation
5. the app is enabled
6. no external policy rejects availability

## Must Not Own

The Availability Service must not own:

- UI presentation
- device definitions
- app definitions
- unlock progression
- campaign rules

It queries those sources through controlled interfaces.

Presentation-level capability requirements MUST NOT weaken or override
app-level requirements.

## Location

```text
forgeos/services/AppAvailabilityService.lua
```

---

# Lifecycle Service

## Responsibility

The Lifecycle Service owns application runtime state and valid state
transitions.

It tracks lifecycle state as player device state. M2 MAY resolve the player
through the isolated `player.local` identity while persistence remains
savegame-global.

Example:

```text
phone
└── forge.projects = ACTIVE

laptop
├── forge.projects = OPEN
└── forge.bank = ACTIVE
```

## Authoritative Lifecycle States

```text
CLOSED
OPEN
ACTIVE
BACKGROUND
```

Registration belongs to the App Registry. Enabled policy is a validated state
or policy input owned outside the Lifecycle Service. Availability is calculated
by the Availability Service for a specific player and device type. None of
registration, enabled policy, or availability is a lifecycle state.

## Transition Ownership

Only the Lifecycle Service may mutate lifecycle state.

Enabled policy and calculated availability MUST constrain whether lifecycle
transitions may occur.

Applications may request transitions.

Device hosts may request transitions.

Neither performs the transition directly.

## Example Transition Flow

```text
Phone Host
    │ requests open
    ▼
ForgeOS Core
    │ validates request
    ▼
Availability Service
    │ confirms availability
    ▼
Lifecycle Service
    │ performs transition
    ▼
Event Bus
    │ publishes app-opened event
    ▼
Phone Host updates presentation
```

## Transition Rules

The service must explicitly define valid transitions.

Conceptually:

```text
CLOSED     → OPEN
OPEN       → ACTIVE
ACTIVE     → BACKGROUND
BACKGROUND → ACTIVE
OPEN       → CLOSED
ACTIVE     → CLOSED
BACKGROUND → CLOSED
```

Device policies may impose additional restrictions.

Example:

- Phone allows one active app.
- Laptop may allow multiple open apps.
- A device without background support closes or suspends the previous app.

## Location

```text
forgeos/services/AppLifecycleService.lua
```

## M2.007 Deterministic Contract

The Lifecycle Service exposes runtime operations through `FORGE.ForgeOS` for
open, activate, background, and close, plus non-mutating lifecycle-state and
active-app queries. M2.007 uses `player.local` internally and owns no public
player-identity API.

Operation precedence is argument validation, `RUNTIME_ACTIVE`, registered
device, registered app, presentation eligibility when entering `OPEN`, enabled
policy, transition validation, displacement staging, callbacks, atomic state
commit, and completed events. An idempotent request returns `SUCCESS` without
callbacks or events. Activating a `CLOSED` app is invalid and does not
implicitly open it.

The App Registry supplies only the internal read-only operation
`getLifecycleCallback(appId, callbackName)`. It permits `onOpen`, `onActivate`,
`onBackground`, and `onClose`; returns a function or nil after registration
freeze; and exposes no other executable asset or private definition.
Executable references remain runtime-owned, non-serializable, and absent from
public snapshots.

Callbacks receive a detached context containing only local player, device,
app, previous state, and requested state. All callbacks complete before the
atomic ForgeOS lifecycle-state commit. A callback failure returns
`CALLBACK_FAILED`, commits no lifecycle state, and publishes no lifecycle
completion event. Earlier arbitrary callback side effects are app-owned and
are not transactionally reversed.

The service-local operation guard rejects re-entrant lifecycle operations with
`NOT_AVAILABLE`. Shutdown clears runtime lifecycle records, active-app
ownership, and enabled overrides without invoking app callbacks.

---

# Navigation Service

## Responsibility

The Navigation Service owns logical navigation state.

It tracks:

- current route
- route parameters
- navigation history
- back stack
- modal state
- selected device
- selected application context

## Navigation State Scope

Navigation should normally be stored per device and per application.

Example:

```text
phone
└── forge.projects
      ├── currentRoute = "projectDetails"
      └── history
            ├── "overview"
            └── "activeProjects"
```

The laptop may maintain separate route state for the same app.

## Navigation Does Not Render

The service describes logical state.

It does not decide:

- animation
- screen layout
- window position
- button placement
- visual transitions

## Example Navigation Request

```lua
FORGE.ForgeOS:navigate(
    "phone",
    "forge.projects",
    "projectDetails",
    {
        projectId = "project.westernRidge"
    }
)
```

This is conceptual only.

## M2.008 Deterministic Contract

Navigation Service consumes frozen detached route declarations through the App
Registry snapshot and Presentation Resolver. It does not own route
registration or access private executable assets.

The public facade exposes `navigate`, `goBack`, `getCurrentRoute`, and
`getNavigationHistory`. State-changing operations require the application to
be active and validate identifiers, runtime phase, registration, lifecycle,
presentation, route, and detached plain parameters in the approved order.

Runtime history is bounded, oldest-to-newest, and non-persistent. Normal
navigation pushes the previous destination. Back navigation searches newest
first, discards invalid historical entries deterministically, and never pushes
the destination being left. An idempotent request returns success without
state, resume, history, or event changes.

The service updates only the navigation portion of persistent resume state
under `forge.os/players/player.local/devices[deviceId]/resume`. Runtime history,
controllers, providers, actions, modals, and lifecycle state are excluded.

## Location

```text
forgeos/services/NavigationService.lua
```

---

# Notification Service

## Responsibility

The Notification Service owns ForgeOS notification records and delivery state.

It tracks:

- notification identifier
- source
- title
- body
- severity
- created time
- read state
- dismissed state
- target player
- target devices
- optional application route

## Example Notification

```lua
{
    id = "notification.1",
    source = "forge.projects",
    title = "New Project Available",
    body = "Western Ridge Expansion is available for review.",
    severity = "info",
    targetDevices = {
        phone = true,
        laptop = true
    },
    route = {
        appId = "forge.projects",
        routeId = "projectDetails",
        parameters = {
            projectId = "project.westernRidge"
        }
    }
}
```

## Authority Boundary

Notifications must distinguish between:

- authoritative saved notifications
- player-local visual notifications
- transient system messages

The notification record may be authoritative while its animation remains local.

## M2.009 Deterministic Contract

Notification Service records delivery state; the originating domain retains
authority over the represented gameplay fact. The service accepts detached
definitions containing source, title, body, severity, persistence policy,
registered device targets, and optional declarative route and metadata.

Every successful transient, session, or savegame creation allocates one
monotonic generated identifier and commits the next sequence before publishing
`NOTIFICATION_CREATED`. Transient records are event-only, session records are
runtime-only, and savegame records are retained under `forge.os`. Read and
dismiss operations are idempotent and publish their completed event only after
commit.

Runtime retained storage is bounded. The service reclaims the oldest dismissed
record, otherwise the oldest read record, and refuses creation rather than
silently evicting an unread undismissed record. The capacity is private.

Lazy restoration builds a complete staged repaired set before State Store
replacement. All records in duplicate identifier or creation-order conflict
groups are discarded. Repair retains no arbitrary winner, preserves unrelated
state, and emits no notification event.

The component does not render, invoke hosts, execute routes, mutate lifecycle
or navigation, or own the gameplay condition described by a record.

### Public operations and queries

State-changing operations return `ForgeOSResult`. Creation additionally
returns the generated identifier on success. Read and dismiss validate the
identifier, require `RUNTIME_ACTIVE`, require a retained record, treat an
already-completed change as idempotent success, commit, and only then publish
the completed event.

Creation applies this precedence:

1. outer argument shape;
2. scalar schema, severity, and persistence;
3. target structure;
4. route and metadata controlled-data validation;
5. `RUNTIME_ACTIVE`;
6. registered target devices;
7. retained-capacity availability;
8. identifier allocation and staged mutation;
9. State Store replacement and authoritative commit; and
10. `NOTIFICATION_CREATED` publication.

`getNotification(notificationId)` returns a detached record or `nil`.
`getNotifications(deviceId, includeDismissed)` returns a detached,
oldest-to-newest array and excludes dismissed records unless explicitly
requested. Invalid input, runtime unavailability, absence, and internal repair
failure deliberately collapse to `nil` or `{}`. Unexpected internal or repair
failure emits one controlled diagnostic.

### Notification definition

Required fields are `source`, `title`, `body`, `severity`, `persistence`, and
`targetDevices`. Optional fields are declarative `route` and controlled
plain-data `metadata`. Source, device, app, and route identifiers use the
existing non-empty, no-whitespace identifier rule. Title and body are strings;
body may be empty. Every target value is exactly `true`, at least one target is
required, and every target device must be registered before commit.

Route existence is not validated during creation. Route parameters and
metadata reject functions, userdata, threads, non-finite numbers, cycles,
shared-reference graphs, metatables, non-string keys, and executable or
runtime objects. Unknown top-level definition fields are ignored and are not
retained; they do not extend the approved schema.

## Location

```text
forgeos/services/NotificationService.lua
```

---

# ForgeOS State

## Responsibility

ForgeOS State contains runtime operating-system state that does not belong to a
single registry or service.

Possible state includes:

- active device
- player preferences
- app enabled-state overrides
- persistent notification records
- last active application per device
- device-specific settings

## State Store Namespace

Authoritative State Store namespace:

```text
forge.os
```

## Persistence Boundary

The stable persistence-facing namespace is `forge.os`. Only persistent state
defined by the ForgeOS state contract belongs in that namespace.

Registry definitions should normally be rebuilt during startup rather than
saved, because they originate from engine and module registration.

Persisted resume state MAY include:

```text
last active device
last valid app
last valid presentation
last valid route
safe route parameters
read notification state
approved user preferences
accessibility preferences
device preferences
```

MUST NOT be persisted:

```text
registered app definitions
registered device definitions
host runtime references
render targets
temporary animations
input state
open modal callbacks
```

Runtime rendering objects and ephemeral presentation state MUST NOT be
persisted. Stable plain-data presentation preferences or resume state MAY be
persisted only when included in the ForgeOS state contract.

Presentation-only preferences SHOULD be player-local. Preferences affecting
gameplay access, permissions, progression, company policy, or other
authoritative behaviour MUST remain server-authoritative or
domain-authoritative and MUST NOT be altered by presentation preferences. The
exact persistence mechanism remains open.

## Proposed Location

ForgeOS may access state through the existing State Store rather than creating a
separate state container.

A thin state-coordination component may still be useful:

```text
forgeos/services/ForgeOSStateService.lua
```

Its necessity should be decided during implementation design.

---

# Device State Service

## Responsibility

`DeviceStateService` owns only runtime device visibility for M2.010. It starts
the local Phone at `HIDDEN`, validates show/hide requests, commits idempotent
visibility transitions, publishes completed visibility events, and clears its
state at shutdown. It does not persist visibility or write `activeDeviceId`.

## Location

```text
forgeos/services/DeviceStateService.lua
```

---

# Phone Host

## Responsibility

The Phone Host presents ForgeOS through a phone-style interface.

It owns:

- phone visual layout
- screen visibility
- phone input handling
- full-screen application presentation
- home-screen presentation
- phone transitions and animations
- phone-specific controls

## Must Not Own

The Phone Host must not own:

- app registration
- app lifecycle truth
- app availability truth
- notification records
- gameplay state
- domain rules

## Interaction Model

```text
Phone input
    ↓
Phone Host
    ↓
ForgeOS request
    ↓
ForgeOS state transition
    ↓
ForgeOS event
    ↓
Phone Host rerenders
```

## Location

```text
forgeos/hosts/PhoneHost.lua
```

M2.010 implements one local PhoneHost instance owned by ForgeOS. It renders a
minimal Phone shell and declarative app/presentation/route identity plus a
retained-notification tray. Application-controller rendering remains deferred.
Engine owns FS25 callbacks and delegates bounded work to this instance only
while ForgeOS is runtime-active.

---

# Laptop Host

## Responsibility

The Laptop Host presents ForgeOS through a desktop or laptop-style interface.

It may eventually own:

- desktop layout
- taskbar
- window presentation
- pointer input
- keyboard input
- application switching
- window sizing and positioning

## Initial Scope

The first implementation should remain simple.

The laptop foundation does not need a complete window manager during the first
ForgeOS milestone.

A minimal host may provide:

- app launcher
- one active app surface
- pointer input
- keyboard-aware routing
- device registration proof

True multi-window behaviour may be a later enhancement.

## Location

```text
forgeos/hosts/LaptopHost.lua
```

M2.011 implements one local LaptopHost alongside PhoneHost. ForgeOS owns both
instances in a private device-keyed collection. The Laptop shell provides a
Home/Desktop surface, bounded detached launcher, one active presentation
region, route identity, retained notifications, pointer controls, keyboard
containment, and validated Navigation resume. Windowing, multi-app rendering,
controller execution, text entry, drag-and-drop, and application-owned custom
UI remain deferred.

F8 is the current remappable development/fallback visibility adapter. The Host
does not depend on F8 or any activation source; a future physical Laptop object
is expected to request the same public Laptop visibility operation.

M3.007 expands the Laptop presentation bounds to a screen-safe full-screen
surface while retaining one active application. The Home surface uses an
original FORGE woodland operations background, fixed launcher shortcuts, and
bounded status chrome; an active application replaces Home content rather than
opening a movable window. ForgeOS draws Laptop before Phone and treats a
visible Phone rectangle as pointer-occluding. All non-presentation Host order,
independent visibility, lifecycle, and navigation behavior remains unchanged.

---

# ForgeOS Application Contract

## Responsibility

Every application must implement a predictable contract.

The implemented App API contract is defined in ForgeOS App Contract. The
following structure is illustrative presentation material:

```lua
{
    id = "forge.projects",
    displayName = "Projects",
    iconId = "forge.icon.projects",
    supportedDevices = {
        phone = true,
        laptop = true
    },
    defaultRoute = "overview",

    onRegister = function(appContext)
    end,

    onOpen = function(appContext)
    end,

    onActivate = function(appContext)
    end,

    onBackground = function(appContext)
    end,

    onClose = function(appContext)
    end
}
```

## Application Context

Callbacks should receive a controlled context rather than unrestricted ForgeOS
internals.

Possible context operations:

```text
navigate
go back
create notification
query active device
query app state
request close
publish app event
```

The context should not expose private registry tables or service internals.

---

# Domain Application Integration

Applications act as adapters between ForgeOS and domain managers.

Example:

```text
Project Manager
      │
      │ authoritative project data
      ▼
Projects App Controller
      │
      │ presentation-ready view data
      ▼
ForgeOS Application
      │
      ▼
Phone Host / Laptop Host
```

The Projects App may:

- query active projects
- request project details
- submit user actions
- navigate between project views
- create project-related notifications

It must not directly own:

- project completion rules
- reward calculations
- project persistence
- company eligibility
- deadline simulation

---

# Event Bus Integration

ForgeOS uses the existing FORGE Event Bus for significant state changes.

Potential event groups:

```text
forge.os.device.*
forge.os.app.*
forge.os.navigation.*
forge.os.notification.*
```

Events should communicate completed state changes, not replace direct API return
values.

Example:

```text
request open app
    ↓
API validates and executes
    ↓
API returns result
    ↓
event announces successful change
```

Events should not be used to hide required synchronous validation.

ForgeOS MUST NOT report a multi-service operation as successful while exposing
partially committed lifecycle, navigation, resume, notification, or visibility
state. The exact staging, rollback, callback timing, and re-entrancy behaviour
remain open.

---

# Persistence Integration

ForgeOS must use:

```text
State Store
Save Manager
```

It must not call:

```text
XML Reader
XML Writer
```

directly.

## Startup Flow

```text
ForgeOS Bootstrap
    ↓
register forge.os namespace
    ↓
apply default state
    ↓
register namespace with Save Manager
    ↓
Engine loads persistence
    ↓
ForgeOS validates restored state
```

The precise order must account for the existing Engine lifecycle.

## Save Flow

ForgeOS writes runtime values into `forge.os`.

The existing Engine save hook and Save Manager persist them automatically.

ForgeOS does not install another save hook.

---

# Multiplayer State Classification

Every ForgeOS state value must be classified.

## Authoritative Shared State

Examples:

- saved notifications caused by gameplay
- unlocked applications
- campaign restrictions
- company-access restrictions
- shared project alerts

Owned by the server.

## Player-Local Persistent State

Examples:

- preferred device
- notification read state
- app layout preferences
- accessibility options

This may require per-player persistence design.

The current persistence system stores savegame-global state, so player-local
persistence must not be assumed until explicitly designed.

## Player-Local Transient State

Examples:

- currently visible phone
- current hover target
- animation progress
- pointer position
- temporary modal
- open window position during the current session

Owned locally and not saved unless later required.

---

# Initial Component Set

The recommended initial ForgeOS implementation consists of:

```text
ForgeOS.lua
ForgeOSCore.lua

definitions/
├── DeviceCapability.lua
├── AppLifecycleState.lua
├── ForgeOSEvent.lua
└── ForgeOSResult.lua

registries/
├── DeviceRegistry.lua
└── AppRegistry.lua

services/
├── AppAvailabilityService.lua
├── AppLifecycleService.lua
├── NavigationService.lua
└── NotificationService.lua

hosts/
├── PhoneHost.lua
└── LaptopHost.lua

tests/
├── DeviceRegistryTest.lua
├── AppRegistryTest.lua
├── AppAvailabilityServiceTest.lua
├── AppLifecycleServiceTest.lua
├── NavigationServiceTest.lua
├── NotificationServiceTest.lua
└── ForgeOSIntegrationTest.lua
```

Not every file must be created immediately.

This structure represents the intended ownership boundaries.

---

# Recommended Implementation Order

```text
M2.001 ForgeOS Architecture
    ↓
M2.002 ForgeOS Definitions
    ↓
M2.003 ForgeOS Core
    ↓
M2.004 Device Registry
    ↓
M2.005 App Registry
    ↓
M2.006 Presentation Resolver
    ↓
M2.007 App Lifecycle
    ↓
M2.008 Navigation
    ↓
M2.009 Notifications
    ↓
M2.010 Phone Host Foundation
    ↓
M2.011 Laptop Host Foundation
    ↓
M2.012 Integration Testing
    ↓
M2.013 Documentation and API Freeze
```

M2.012 adds one consolidated integration boundary over the retained component
and integration suites. It proves production startup, external registration,
presentation resolution, lifecycle, navigation, persistence, notifications,
the two-Host runtime, and shutdown without replacing the detailed owning
component tests.

For a notification targeted to both production devices, PhoneHost and
LaptopHost project the same authoritative record. Read and dismissal mutations
therefore become observable through both device queries. Device targeting
controls presentation eligibility only.

`updateRuntimeHost()`, `drawRuntimeHost()`, `dispatchHostInput()`, and
`dispatchHostPointer()` are Engine/platform adapter operations. They are not
addon-facing application APIs merely because the current implementation places
them on the ForgeOS façade table.

M2.013 is a stabilization, bounded visual-polish, documentation, and contract-
freeze boundary. It does not execute application controllers or introduce the
future desktop/window subsystem. Window/session ownership, z-order, focus,
geometry, application rendering, modal ownership, and text input remain future
post-M2 architecture.

---

# Open Decisions

The following contract decisions remain unresolved. Implementations and other
documents MUST NOT silently choose answers before architecture review records
the decision.

## Lifecycle callback timing and rollback

The point at which callbacks run relative to authoritative lifecycle mutation,
and whether callback failure rolls back a transition, remain unresolved.

## Event ordering and re-entrancy

Cross-service event order and whether event handlers may issue re-entrant
ForgeOS operations remain unresolved.

## Availability provider composition

The composition, precedence, conflict handling, and diagnostic rules for
multiple availability providers remain unresolved.

## Navigation and lifecycle atomicity

Operations that change lifecycle and navigation state MUST satisfy the minimum
cross-service atomicity invariant. Their staging, rollback, callback timing,
and re-entrancy behaviour remain unresolved.

## Notification authority boundaries

M2.009 assigns gameplay facts to their originating domains and player-facing
delivery records to Notification Service. Multiplayer authority and host
delivery acknowledgement remain unresolved.

## ForgeOSStateService

Whether a dedicated `ForgeOSStateService` is required, and which state
invariants it would own, remains unresolved.

## Multiplayer player identity

The stable multiplayer identity source and multiplayer persistence policy
remain unresolved. M2 MAY use the isolated `player.local` resolver, but current
persistence remains savegame-global.

## Active device persistence

Whether active device selection is persisted remains unresolved.

## Future multi-app and windowing implications

M2 assumes one active application per device type. The contract implications
of multiple active applications, windows, and device host instances remain
unresolved.

## M2.011 Bounded Multi-Host and Cursor Contract

M2.011 resolves only the two-Host production case: Phone then Laptop processing,
reverse shutdown, atomic startup, independent simultaneous visibility, and
bounds-based pointer dispatch. Engine owns the documented FS25 cursor adapter;
higher-priority GIANTS GUI state wins. General focus, window management,
cross-mod cursor ownership, and arbitrary Host collections remain unresolved.

---

# Initial Recommendations

For the first implementation:

1. Track lifecycle state as player device state.
2. Support one active application per device type.
3. Allow multiple registered device types.
4. Keep phone and laptop player device state separate.
5. Use external availability providers for progression restrictions.
6. Start with logical navigation and one route stack per app in each player
   device state.
7. Keep notification records separate from visual notification animations.
8. Rebuild app and device definitions on startup.
9. Persist only stable user or OS state.
10. Keep the API structurally capable of future per-player state.

---

# Success Criteria

This component design is successful when:

- each ForgeOS responsibility has one clear owner
- no component must reach into another component’s private storage
- phone and laptop hosts share the same OS logic
- apps can be tested without rendering a device host
- registries can be tested without FS25 gameplay systems
- lifecycle transitions are deterministic
- navigation state is independent of presentation
- notifications are independent of their visual display
- ForgeOS persists through existing FORGE infrastructure
- future domain apps can register without changing ForgeOS internals

---

# Next Design Step

The next design artifact is:

```text
docs/forgeos/ForgeOSDefinitions.md
```

That document will define the authoritative identifiers and enums required before
implementation, including:

- device identifiers
- device capabilities
- app lifecycle states
- availability failure reasons
- notification persistence policies
- event identifiers
- result codes
- ForgeOS State Store namespace
- ForgeOS log source identifiers

---

## ForgeOS Export Bridge (Provisional M2.010 Adapter)

`FORGE.ForgeOSExportBridge` owns the `g_messageCenter` subscription lifecycle
for the provisional version-1 cross-mod acquisition protocol. It subscribes
after `ForgeOS:start()` opens registration and before FORGE's `loadMap` returns.
It accepts only a strictly valid caller-owned request container, increments its
`responderCount`, and writes only `bridgeVersion` and the exact
`FORGE.ForgeOS` facade reference. It stores no consumer reference after the
handler returns.

Shutdown first disables responses, then removes all subscriptions owned by the
bridge target, releases its carrier reference, and clears lifecycle state
before normal ForgeOS shutdown. Malformed requests are ignored and unexpected
handler failures are contained and diagnosed without mutating ForgeOS state.
The protocol remains provisional pending the runtime proof required by
[ADR-004](../adr/ADR-004-FS25-Cross-Mod-ForgeOS-Export-Bridge.md).

# Related Documentation

- [M2 Architecture Review](../reviews/M2ArchitectureReview.md) records accepted
  component decisions and the open decisions that implementations must not
  resolve silently.
- [Engineering Process](../style/EngineeringProcess.md) defines the review and
  implementation workflow governing this design.

## PF.001 Presentation Definitions Component

PF.001 extends the existing ForgeOS definitions package with declarative-model,
component, property, layout-value, semantic-token, action-reference, attention,
route-schema, notification-cue, activation-stage/result, limit, and diagnostic
identifiers. These files contain definitions only and load after the ForgeOS
definitions namespace but before services, registries, Hosts, applications, and
tests.

PF.001 does not create a renderer, validator, notification presentation
coordinator, route-schema executor, attention provider, or activation service.
Those responsibilities remain separately gated in PF.002, PF.005, and PF.006.
No component may interpret these definitions before its own implementation
batch is approved.

The bounded PF.001 clarification also defines canonical declarative node
fields, text-flow values, Host action identifiers, semantic component states,
child policies, and an exact `PresentationComponentContract` table. The table
is definition data only. No component validator, layout engine, renderer, hit
region builder, or dispatcher is introduced before PF.002 approval.

## PF.002 Declarative Validation and Shared Renderer Component Design

**Status:** Approved
**Implementation:** Implemented, Verified, Accepted and Frozen

PF.002 consumes the frozen PF.001 definitions and
[Declarative Presentation Protocol](ForgeOSDeclarativePresentationProtocol.md)
without adding or reinterpreting vocabulary. The component chain is:

```text
Application
    -> detached declarative presentation
    -> Application Presentation Service
    -> validation / mediation
    -> Shared Renderer
    -> Host adapter and profile
    -> device geometry, input, and render backend
```

Gameplay/domain services own truth. Applications own task-specific
composition. Application Presentation Service owns acquisition, detachment,
validation, and application-action mediation. Shared renderer components own
presentation semantics only. Hosts own device environment and independent
runtime sessions.

### Component allocation

| Component | Responsibility | Must not own |
|---|---|---|
| `ApplicationPresentationService` | Resolve context/provider, guard invocation, select v1/v2 validation, mediate application actions | drawing, Host geometry, domain truth |
| `DeclarativeViewValidator` | Produce a canonical detached v2 copy after complete envelope/tree/contract/limit validation | repair, partial acceptance, token metrics |
| `PresentationPropertyValidator` | Validate frozen property types, enum/category membership, defaults, component state and action references | new defaults or vocabulary |
| `HostPresentationProfile` | Immutable per-pass viewport, density, token metrics, typography metrics, colors, icon resolver, hit minimums, scroll step | application data or mutable session state |
| `PresentationLayoutEngine` | Deterministic bottom-up measurement and top-down arrangement | draw calls, provider calls, gameplay semantics |
| `PresentationTextLayout` | Bounded measurement, wrapping, maximum-lines, clipping and UTF-8-safe ellipsis records | source-string mutation or arbitrary fonts |
| `PresentationTokenResolver` | Category-safe resolution of frozen semantic tokens/states through the Host profile | application overrides or raw styling |
| `PresentationRenderPlanBuilder` | Convert arranged nodes to finite primitives, clips, paint ordinals, scroll extents and action metadata | callbacks or persistent state |
| `PresentationRendererBackend` | Execute trusted bounded measure/draw/clip operations supplied by the Host | model traversal or application branching |
| `HostViewSession` | Per-Host generation, last-safe model, scroll, hover, press and diagnostic suppression | persistence or another Host's state |
| `HostHitRegionController` | Own clipped regions, reverse-paint hit testing, press/release cancellation and input claiming | application action execution |
| `PresentationActionMediator` | Revalidate and route application or frozen Host actions to their existing owners | generic commands or domain inference |
| `PhonePresentationAdapter` | Supply Phone viewport/profile/backend/input and its independent session | Laptop state or application-specific rendering |
| `LaptopPresentationAdapter` | Supply Laptop viewport/profile/backend/input and its independent session | Phone state or application-specific rendering |

These are architectural responsibilities, not authorization for exact Lua
module names or source creation. Implementation structure must be reviewed
against this allocation after architecture approval.

### Acquisition and validation interface

Conceptually, a Host requests a refreshed model using only its device and
current resolved context. `ApplicationPresentationService` validates lifecycle
and resolution, enters a guard keyed by device and app, calls the private
provider under protected execution, releases the guard on every exit, and
routes model v1 to the retained path or model v2 to
`DeclarativeViewValidator`.

The validator walks provider data once while constructing a new canonical
copy. It rejects unknown fields, sparse arrays, invalid key/value types,
metatables, aliases, cycles, invalid component cardinality/content sources,
nested interactive nodes, invalid action references, category-invalid tokens,
and every frozen defensive-limit breach. It returns only an entirely valid
copy; no rejected subtree reaches layout. Provider references are never stored.

Application action activation returns through the service, which rechecks the
current device/app/presentation/route, declared action, controlled parameters,
generation, and guard before invoking the existing provider action path. Host
actions are limited to `osHome` and `deviceClose` and execute only through
their existing lifecycle/visibility owners.

### Layout component contract

`PresentationLayoutEngine` receives a validated tree, immutable Host profile,
finite viewport constraint, and current Host scroll offsets. Measurement is
bottom-up; arrangement is top-down. All calculations remain finite and
non-negative. Declaration order is the only sibling ordering input.

- Stack uses its frozen direction, with gap between children and distribution
  on the main axis.
- Row is the horizontal Stack specialization fixed by the frozen contract.
- Split always has two children and partitions one bounded axis. Flexible
  children use their frozen grow values, or equal shares when neither supplies
  grow. Applications may nest Split to compose multiple generic regions.
- Scroll always has one child, one declared axis, one finite viewport, and a
  clamped runtime offset. Its child receives an unbounded axis constraint only
  for measurement; PF.001 node/depth/child/text/action/parameter limits still
  bound all work and allocation.
- spacing is additive outer separation in parent flow; padding is inner inset;
  gap occurs once between adjacent children; alignment is cross-axis and
  distribution is main-axis.
- content/auto/fill/weighted sizing, grow, minimum and maximum constraints use
  only frozen values. Weighted remainder is redistributed after clamping.
  Overflow is handled by the declared clip/overflow rule, never negative size
  or model mutation.

Split carries no navigation, list, reading, mailbox, Project, Banking,
Companies, Fleet, vehicle, employee, account, invoice, or other domain
semantics. Those structures arise solely from application composition.

### Leaf and control component contract

| Frozen component | Generic renderer behavior |
|---|---|
| Text | Measure approved text role, wrap/limit/clip/ellipsis without changing source |
| Icon | Resolve one controlled icon ID through the trusted profile |
| Divider | Produce a non-interactive border-role rule |
| Empty State | Arrange icon, text, then declared children in a centered vertical internal flow |
| Button | Arrange icon, text, then declared children in a horizontal internal flow and expose one clipped action region |
| Icon Button | Arrange required icon/label and expose one clipped action region |
| Navigation Item | Arrange icon, text, declared children, then trailing count in a horizontal internal flow and expose one clipped action region |
| List Row | Arrange declared children in a horizontal internal flow and expose one clipped action region |
| Badge | Render exact optional count and approved semantic state |
| Status | Arrange icon then text in a horizontal internal flow and apply semantic state |

`accessibleLabel` contributes accessibility meaning and satisfies the frozen
content rule where allowed, but it does not implicitly create visible text.
Missing optional sources consume no space. Component `padding` encloses the
internal flow and `gap` separates only adjacent present items. Declared child
nodes retain their own full layout semantics, so an application can place a
Stack or other frozen composition inside a generic control without teaching
the control any domain structure. Icon Button renders its icon; its required
label remains accessibility data. Badge with no count renders only its bounded
semantic indicator. Divider orientation follows its arranged bounds rather
than an application or domain identifier.

The component identifier alone chooses these semantics. Application, route,
action, text, and domain identifiers cannot choose renderer code paths. Final
palette, typography, icon artwork, Phone/Laptop visual composition,
notification appearance, and Communications layout remain later Design Lead or
separately gated work.

### Render plan, clipping, and input

Arrangement produces an ephemeral plan. Background/border precedes children;
children paint in declaration order; later siblings are above earlier siblings.
There is no supplied z-index. Every primitive and hit region uses the
intersection of applicable ancestor clips. Empty clips produce neither pixels
nor action regions.

Each interactive node contributes one Host-owned region with its clipped
rectangle, structural identity, generation, paint ordinal, detached action,
and enabled state. Press records the topmost enabled region under the primary
pointer. Release activates exactly once only when current hit, identity,
generation, enabled state, and action signature still match. Route/app change,
Host hide, plan replacement, leaving the region, or secondary input cancels.

### Independent Host sessions and companion overlay

PhoneHost and LaptopHost may be visible simultaneously. They share validator,
layout, text, token, and render-plan semantics but never a runtime view session.
Each Host separately owns:

- context key and generation;
- last-safe validated view;
- scroll offsets;
- hover and pressed identity;
- viewport/profile and clip geometry;
- render plan and hit regions; and
- failure-diagnostic suppression.

Showing the right-side Phone overlay does not close, navigate, refresh, or
reset Laptop. Hiding Phone restores normal input eligibility to the preserved
Laptop/gameplay state. Overlapping input follows existing Phone-over-Laptop
occlusion; it does not merge sessions. Exact Phone geometry remains deferred.

Future tutorial or gameplay systems may present instructions through an
approved application/service path and determine progress from approved events
or domain facts. Phone never directly controls Laptop application state, and
PF.002 defines no tutorial/mission component or service.

### Invalid models and controlled failures

Only a fully validated model and successfully built plan replace a Host's safe
view. Provider failure, re-entry, validation failure, missing profile mapping,
or layout/render-plan failure retains the safe view only for that exact Host
context. Otherwise the Host renders its bounded unavailable state. No invalid
subtree, inferred navigation, domain mutation, or cross-Host fallback occurs.
Diagnostics use existing presentation/Host sources, omit sensitive body data,
and throttle repeated equivalent failures per Host context.

### Verification seams

Unit tests cover detachment, exact frozen contracts and limits, sizing,
component layout, text, clipping, semantic precedence, paint/hit ordering,
scrolling, input cancellation, mediation, re-entrancy, last-safe behavior, and
v1 branching. Integration tests use a neutral synthetic provider on both
Hosts, including simultaneous visibility and proof that one Host cannot alter
the other's session. FS25 verification requires visible Phone/Laptop v2 views,
long bounded reading content, pointer/action evidence, controlled failures,
v1 coexistence, restart-cleared runtime state, retained regressions, and
separately fingerprinted verification/operational packages.

## PF.002 — ACCEPTED AND FROZEN

PF.002 is implemented, verified, accepted, and frozen. Its accepted operational
fingerprint is
`8472BF9B8A3ED573DA57BA7BB99E71B98E69AE7147D31961A98D37C1A654D10F`.

## PF.003 Laptop Shell Component Design

PF.003 composes a Host-owned Laptop shell around, but never inside, the frozen
PF.002 application renderer:

```text
LaptopHost
├── Laptop shell profile (trusted viewport and semantic regions)
├── Desktop compositor
│   ├── wallpaper/fallback and readability treatment
│   ├── identity/status/control regions
│   └── registry-derived shortcut projection and shell hit regions
└── active application viewport
    └── independent Laptop PF.002 Host adapter/session
```

### Laptop shell profile

The profile derives safe margins, identity/status band, shortcut region,
application viewport, control/hint band, future-toast safe region, and visible
Phone overlap from Host-observed viewport, aspect ratio, and UI scale. Exact
numbers are profile decisions validated in FS25, not application input or pixels
copied from concept art. An unreadably small geometry produces a controlled
unavailable shell result.

### Desktop compositor

The compositor receives existing App Registry definitions and Presentation
Resolver availability outcomes. It projects `displayName`, optional `iconId`,
and stable identity into deterministic compact shortcut cells. It contains no
app catalog or application/domain branch. Missing icon assets use the common
generic fallback plus textual identity; the fallback infers no domain meaning
and is not the disabled cue.

Shortcut placement is bounded to a deliberate cluster. One/few apps remain at
the cluster origin without enlargement. Larger populations add profile-defined
cells and a deterministic bounded overflow page/scroll treatment. Only visible
cells and fixed shell controls are measured, drawn, and hit-tested; no public
registry maximum is introduced. Page/offset, hover, press, arrangement, and hit
regions are runtime-only.

Wallpaper is one fixed shell-owned milestone asset with semantic fallback and
approved semantic readability treatment. The compositor owns no preference,
selection, or persistence mechanism.

### Active application viewport

When lifecycle reports one active app, Desktop shortcuts are replaced by the
application workspace. Restrained Host identity/status/Home/Close/hint regions
remain outside the delegated rectangle. PF.002 clips the validated app plan and
its Host-owned hit regions to that rectangle. Shell regions and application
regions cannot overwrite or reuse each other.

OS Home/Desktop closes the active app through existing App Lifecycle ownership.
Device Close changes Laptop visibility. Back remains Navigation/application
action. The design adds no minimise, window, task switch, background surface, or
multiple-active-app state.

### Input, sessions, and later seams

Shell controls use primary press and release on the same current logical region.
Application input remains PF.002-owned inside the app viewport. Visible Phone
geometry draws above Laptop and claims overlapping input; Laptop retains input
outside overlap. Phone and Laptop sessions remain independent in both mutation
directions.

PF.003 reserves a shortcut badge anchor but creates no PF.005 attention truth.
It reserves lower-right geometry but creates no PF.006 toast behavior. PF.007
owns Communications Laptop composition.

The active-app Communications model-v1 renderer is the sole grandfathered
exception. It receives only the trusted Laptop application viewport and owns no
Desktop or global shell region. It gains no feature, schema, layout system, or
new consumer. PF.007 must migrate Communications Laptop to model-v2 and delete
this branch; it cannot remain at PF.007 acceptance without a new architecture
review.

The authoritative complete PF.003 design and traceability are in
[FORGE OS Laptop Shell Architecture](ForgeOSLaptopShellArchitecture.md).

## PF.004 Phone Shell Component Design

PF.004 composes a Host-owned compact companion shell around one trusted Phone
application viewport. `PhoneHost` owns frame/safe bounds, identity/status,
registry-derived Home launcher, page controls, OS Home, Close/hints, shell hit
regions, and an empty top-edge PF.006-safe region. The active app owns none of
those regions.

`PhoneShortcutProjection` consumes existing Phone eligibility, presentation
resolution, app identity, `displayName`, and optional `iconId`. It creates a
deterministic runtime-only projection with generic icon fallback. The bounded
shortcut cluster uses fixed profile capacity and pages rather than a four-app
cap, unlimited grid, or shrinking targets. Its attention anchor is only PF.005.

`PhoneGeometryProfile` derives safe shell, banner seam, launcher/application,
navigation, and clipping rectangles from Host metrics and UI scale. PF.002
receives only the application rectangle and Phone density profile. Shell and
application draw/hit plans are clipped independently.

Generic model-v2 apps use PF.002 without app-ID branching. The existing
Communications v1 Phone renderer is the sole isolated transition and receives
only the same trusted viewport. It owns no Home, status, OS Home, Close,
notification, or global navigation region; PF.008 must migrate and remove it.

Shell press/release requires the same current logical region. Phone continues to
claim overlapping Laptop input first. Phone and Laptop profile, scroll, hover,
pressed, last-safe, clipping, hit-region, and generation state remain mutually
independent. See
[FORGE OS Phone Shell Architecture](ForgeOSPhoneShellArchitecture.md).
