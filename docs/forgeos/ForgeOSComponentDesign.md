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
    └── Registered Applications
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
