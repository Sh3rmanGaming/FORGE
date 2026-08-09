# FORGE ForgeOS Definitions

**Version:** 0.1  
**Status:** Verified
**Milestone:** M2.002 – ForgeOS Definitions

---

---

# Purpose

This document defines the authoritative identifiers, enumerations, constants,
result codes, event names, and shared state identifiers used by ForgeOS.

These definitions establish the vocabulary used by all ForgeOS components.

The purpose of this document is to ensure that:

- every ForgeOS component uses consistent identifiers
- application and device states have one authoritative meaning
- events use stable names
- failures can be reported consistently
- device capabilities remain data-driven
- public identifiers can be frozen before external applications depend on them

Implementation files must use these definitions rather than repeating raw
strings throughout the codebase.

---

---

# Definition Ownership

ForgeOS definitions belong to the ForgeOS subsystem.

Source location:

```text
forgeos/definitions/
```

Initial definition files:

```text
forgeos/definitions/
├── ForgeOSDefinitions.lua
├── ForgeOSVersion.lua
├── ForgeOSNamespace.lua
├── ForgeOSPhase.lua
├── ForgeOSPlayerId.lua
├── DeviceId.lua
├── DeviceCapability.lua
├── DeviceVisibility.lua
├── AppLifecycleState.lua
├── AppAvailabilityReason.lua
├── PresentationMatchType.lua
├── NotificationPersistence.lua
├── NotificationSeverity.lua
├── NavigationLayer.lua
├── ForgeOSEvent.lua
└── ForgeOSResult.lua
```

The exact file split may change during implementation.

The authoritative identifiers defined in this document should not change
silently after the ForgeOS API is frozen.

---

# ForgeOS Namespace

ForgeOS persistent state MUST use the authoritative State Store namespace:

```text
forge.os
```

Authoritative definition:

```lua
FORGE.Definitions.ForgeOSNamespace = {
    OS = "forge.os"
}
```

The `forge.os` identifier is stable and persistence-facing. The namespace
contains ForgeOS-owned persistent state only.

It must not contain:

- device definitions
- application definitions
- runtime host objects
- rendering objects
- callbacks
- domain gameplay state

Definitions are rebuilt through registration during startup.

---

---

# ForgeOS Versions

ForgeOS uses separate version identifiers for separate compatibility
boundaries.

Implemented definitions:

```lua
FORGE.Definitions.ForgeOSVersion = {
    APP_API = 1,
    STATE = 1
}
```

## `APP_API`

The application contract version used to validate built-in and external
ForgeOS applications.

An app definition declares the app API version it requires:

```lua
apiVersion = 1
```

ForgeOS must reject an application requiring an unsupported app API version.

## `STATE`

The internal version of the persistent data stored inside the `forge.os`
namespace.

This version allows ForgeOS state migrations without requiring every internal
state change to alter the global FORGE XML schema.

These versions are independent from:

```text
FORGE release version
FORGE public addon API version
FORGE persistence schema version
```

A change to one version must not silently imply a change to the others.

---

# ForgeOS Phases

ForgeOS uses an explicit operating and registration lifecycle.

Implemented definitions:

```lua
FORGE.Definitions.ForgeOSPhase = {
    UNAVAILABLE = "unavailable",
    INITIALISING = "initialising",
    REGISTRATION_OPEN = "registrationOpen",
    VALIDATING = "validating",
    REGISTRATION_FROZEN = "registrationFrozen",
    RUNTIME_ACTIVE = "runtimeActive",
    SHUTTING_DOWN = "shuttingDown",
    STOPPED = "stopped"
}
```

## Phase Meaning

### `unavailable`

ForgeOS has not started and cannot accept registrations or runtime requests.

### `initialising`

ForgeOS is creating its state, services, persistence integration, and
registration environment. This internal setup is not public registration.

### `registrationOpen`

The Device Registry may register device definitions/profiles, the Device Host
Registry may register device host implementations, and the App Registry may
register application definitions.

### `validating`

Registration is closed. ForgeOS validates the stable registration sets of all
three registries before runtime begins.

### `registrationFrozen`

Validation has succeeded and all three registration sets are immutable.
Restored references may be validated, repaired, or discarded, and final runtime
preparation may occur. Normal runtime operations remain unavailable.

### `runtimeActive`

ForgeOS is available for normal device, application, navigation, and
notification operations.

### `shuttingDown`

ForgeOS is releasing runtime state and host resources.

### `stopped`

ForgeOS shutdown is complete.

External addons must not rely on mod load order alone. They must verify that
ForgeOS exists, supports the required API version, and currently permits
registration.

## Permitted and Forbidden Operations by Phase

### `unavailable`

No registration, validation, runtime, persistence-restore, or shutdown
operation is permitted. Existence and compatibility probes MAY report that
ForgeOS is unavailable.

### `initialising`

Bootstrap MAY create services, initialise state, register persistence
integration, restore raw `forge.os` data through existing Engine persistence
infrastructure, and prepare the registration environment. References depending
on registered apps, devices, presentations, or routes MUST NOT yet be treated
as validated. Public content registration and all runtime operations are
forbidden.

### `registrationOpen`

Device definition/profile, device host implementation, and application
definition registration are permitted through their respective registries.
Runtime device host instances do not participate in registration. Registration
validation local to one submitted definition MAY occur. Runtime device,
application, navigation, and notification operations are forbidden.

### `validating`

Entering `VALIDATING` closes registration. ForgeOS MUST validate all three
stable registration sets. New registration, registration mutation, and runtime
operations are forbidden.

### `registrationFrozen`

Validation has succeeded and all three registration sets are immutable.
Registration and normal runtime operations are forbidden. Restored references
MAY be validated, repaired, or discarded against the frozen sets. Bootstrap MAY
complete runtime preparation.

### `runtimeActive`

Normal device, application, availability, lifecycle, navigation, notification,
and state operations are permitted through the public API. Registration and
registration mutation are forbidden.

### `shuttingDown`

Bootstrap MAY coordinate cleanup, final state handling, and release of device
host instances. New registration and normal runtime requests are forbidden.
Required cleanup operations MUST remain permitted.

### `stopped`

Shutdown is complete. Registration, validation, runtime, persistence-restore,
and cleanup operations are forbidden. Read-only diagnostics MAY report the
stopped phase.

## M2.003A Lifecycle Contract Clarification

### Architectural Intent

This clarification defines only the observable lifecycle behaviour required by
the M2.003A Core Lifecycle Foundation. It introduces no phase or capability and
does not alter the complete v0.1 lifecycle.

### Query Contract

The public Core facade provides:

```lua
FORGE.ForgeOS:getPhase()
FORGE.ForgeOS:getAppApiVersion()
FORGE.ForgeOS:supportsAppApiVersion(requiredVersion)
FORGE.ForgeOS:isAvailable()
FORGE.ForgeOS:isRegistrationOpen()
FORGE.ForgeOS:isRuntimeActive()
```

`getPhase()` returns one authoritative `ForgeOSPhase` value.
`getAppApiVersion()` returns `ForgeOSVersion.APP_API`.
`supportsAppApiVersion(requiredVersion)` returns true only for a positive
integer equal to the supported application API version. Invalid input returns
false.

`isAvailable()` and `isRuntimeActive()` return true only during
`RUNTIME_ACTIVE`. `isRegistrationOpen()` returns true only during
`REGISTRATION_OPEN`. Queries are permitted in every phase and never mutate
state or publish events.

### Operation Result Contract

Queries return primitive or read-only values. Operations requesting state
changes return a `ForgeOSResult`.

For M2.003A, `start()` and `shutdown()` use:

| Condition | Result |
|---|---|
| Completed operation or idempotent no-op | `SUCCESS` |
| Operation forbidden by the current phase | `INVALID_TRANSITION` |
| Base-state initialisation failure | `STATE_ERROR` |
| Persistence-registration failure | `PERSISTENCE_ERROR` |
| Unexpected internal failure | `INTERNAL_ERROR` |

Future registration operations rejected outside `REGISTRATION_OPEN` return
`REGISTRATION_CLOSED`. Future runtime operations rejected outside
`RUNTIME_ACTIVE` return `NOT_AVAILABLE`.

### M2.003A Transition Matrix

| Current phase | Next phase |
|---|---|
| `UNAVAILABLE` | `INITIALISING` |
| `INITIALISING` | `REGISTRATION_OPEN` |
| `INITIALISING` | `SHUTTING_DOWN` |
| `REGISTRATION_OPEN` | `SHUTTING_DOWN` |
| `SHUTTING_DOWN` | `STOPPED` |
| `STOPPED` | `INITIALISING` |

Every other transition is rejected without changing phase.

The direct transition from `REGISTRATION_OPEN` to `SHUTTING_DOWN` is permitted
because validation, registration freeze, and runtime activation are
intentionally deferred during M2.003A. A future complete startup MUST proceed
through those phases and MUST NOT use this bounded milestone path to bypass
them.

### Idempotence Contract

Starting from `UNAVAILABLE` or `STOPPED` performs startup. Starting from
`REGISTRATION_OPEN` returns `SUCCESS` without repeating work. Starting during
`INITIALISING`, `SHUTTING_DOWN`, or a later lifecycle phase returns
`INVALID_TRANSITION` during M2.003A.

Shutdown from `INITIALISING` or `REGISTRATION_OPEN` performs cleanup and
stopping. Shutdown from `UNAVAILABLE`, `SHUTTING_DOWN`, or `STOPPED` returns
`SUCCESS` without repeating work.

Idempotent calls do not repeat state creation, persistence registration,
cleanup, phase transitions, or event publication.

### Lifecycle Ownership

ForgeOS Core owns and performs authoritative phase changes. ForgeOS Bootstrap
coordinates startup and shutdown and requests changes from Core. Bootstrap
MUST NOT mutate phase state directly. No other component may maintain an
independent authoritative phase.

### Lifecycle Events

`REGISTRATION_OPENED` is published exactly once after a successful startup has
entered `REGISTRATION_OPEN`:

```lua
{
    phase = FORGE.Definitions.ForgeOSPhase.REGISTRATION_OPEN,
    appApiVersion = FORGE.Definitions.ForgeOSVersion.APP_API
}
```

`STOPPED` is published exactly once after cleanup completes and the
authoritative phase becomes `STOPPED`:

```lua
{
    phase = FORGE.Definitions.ForgeOSPhase.STOPPED
}
```

Listeners observe completed transitions. Listener failure does not reverse
either completed transition. Idempotent calls do not republish events.
`STARTED` is not published during M2.003A and remains associated with successful
entry into `RUNTIME_ACTIVE`.

### Runtime Gating

Lifecycle and compatibility queries are always permitted. Registration is
phase-permitted only during `REGISTRATION_OPEN`, although registry APIs are not
introduced by M2.003A. Normal runtime operations remain forbidden because
M2.003A does not reach `RUNTIME_ACTIVE`.

Rejected operations do not mutate state or publish completion events. Tests
may exercise internal phase gating without introducing placeholder public
subsystem operations.

## M2.003B Registration Lifecycle Clarification

### Architectural Intent

M2.003B defines registration coordination and the transition into
`RUNTIME_ACTIVE`. It does not define or implement concrete registry behaviour
or runtime-active subsystem operations.

### Startup Completion Result

`FORGE.ForgeOS:completeStartup()` returns one `ForgeOSResult`:

| Condition | Result |
|---|---|
| Startup completion succeeds | `SUCCESS` |
| Already `RUNTIME_ACTIVE` | `SUCCESS` |
| Current phase cannot complete startup | `INVALID_TRANSITION` |
| A required participant is absent or invalid | `NOT_AVAILABLE` |
| Participant validation or freeze fails | Participant failure result |
| Unexpected coordination failure | `INTERNAL_ERROR` |

An idempotent call during `RUNTIME_ACTIVE` does not repeat validation, freeze,
phase transitions, or event publication.

### Transition Matrix Extension

M2.003B adds:

| Current phase | Next phase | Condition |
|---|---|---|
| `REGISTRATION_OPEN` | `VALIDATING` | Registration completion begins |
| `VALIDATING` | `REGISTRATION_FROZEN` | All participants validate |
| `VALIDATING` | `SHUTTING_DOWN` | Validation fails |
| `REGISTRATION_FROZEN` | `RUNTIME_ACTIVE` | All participants freeze |
| `REGISTRATION_FROZEN` | `SHUTTING_DOWN` | Freeze or finalisation fails |
| `RUNTIME_ACTIVE` | `SHUTTING_DOWN` | Normal shutdown |

Existing M2.003A transitions remain valid. Core authoritatively performs every
phase change.

### Validation and Freeze Failure

Validation stops at the first failing participant. No participant is frozen,
registration is not reopened, and ForgeOS shuts down to `STOPPED`.

Freeze stops at the first failing participant. Runtime activation and
`STARTED` publication do not occur. Every installed participant receives
idempotent cleanup, including already frozen participants, and ForgeOS shuts
down to `STOPPED`.

Partially completed coordination MUST NOT be reported as successful or exposed
as runtime-active.

### Registration Gate

The internal shared registration gate returns:

```text
SUCCESS               during REGISTRATION_OPEN
REGISTRATION_CLOSED   during every other phase
```

Future concrete registries use this decision before committing registration
state. A rejected late registration does not mutate state or publish a
registry-specific event.

### Registration Frozen Event

After all participants freeze and Core enters `REGISTRATION_FROZEN`, publish
`ForgeOSEvent.REGISTRATION_FROZEN` exactly once:

```lua
{
    phase =
        FORGE.Definitions.ForgeOSPhase.REGISTRATION_FROZEN
}
```

### Started Event

After Core enters `RUNTIME_ACTIVE`, publish `ForgeOSEvent.STARTED` exactly
once:

```lua
{
    phase =
        FORGE.Definitions.ForgeOSPhase.RUNTIME_ACTIVE,
    appApiVersion =
        FORGE.Definitions.ForgeOSVersion.APP_API
}
```

Listeners observe completed transitions. Listener failure does not reverse a
completed transition.

### Restart and Cleanup

Registration state is rebuilt for every ForgeOS lifecycle and is not
persisted. Shutdown or failed completion invokes participant cleanup. A
restarted lifecycle begins with mutable, unfrozen participant sets and may
install each required role once.

---

# ForgeOS Player Identifiers

ForgeOS state is conceptually scoped per player and per device.

The initial M2 implementation may use one temporary local-player identifier:

```lua
FORGE.Definitions.ForgeOSPlayerId = {
    LOCAL = "player.local"
}
```

The literal `player.local` must be isolated behind the ForgeOS player identity
resolver.

Implementation files must not repeat this literal throughout the subsystem.

The long-term public API must remain compatible with stable multiplayer player
identities without requiring the per-device state model to be redesigned.

M2 MAY use the isolated `player.local` resolver. Current persistence is
savegame-global and does not provide true per-player multiplayer persistence.

---

# ForgeOS Log Sources

ForgeOS components must use authoritative Logger sources.

Initial proposed sources:

```lua
FORGE.Definitions.LogSource.FORGE_OS =
    "ForgeOS"

FORGE.Definitions.LogSource.FORGE_OS_STATE =
    "ForgeOSState"

FORGE.Definitions.LogSource.DEVICE_REGISTRY =
    "DeviceRegistry"

FORGE.Definitions.LogSource.APP_REGISTRY =
    "AppRegistry"

FORGE.Definitions.LogSource.APP_PRESENTATION =
    "AppPresentation"

FORGE.Definitions.LogSource.APP_AVAILABILITY =
    "AppAvailability"

FORGE.Definitions.LogSource.APP_LIFECYCLE =
    "AppLifecycle"

FORGE.Definitions.LogSource.NAVIGATION =
    "Navigation"

FORGE.Definitions.LogSource.NOTIFICATION =
    "Notification"

FORGE.Definitions.LogSource.PHONE_HOST =
    "PhoneHost"

FORGE.Definitions.LogSource.LAPTOP_HOST =
    "LaptopHost"
```

These identifiers describe the source of diagnostic output.

They must not contain logging behaviour.

---

# Device Identifiers

Device identifiers uniquely identify logical ForgeOS device types.

Device terminology follows the canonical definitions in
`ForgeOSArchitecture.md`.

Initial built-in devices:

```lua
FORGE.Definitions.DeviceId = {
    PHONE = "phone",
    LAPTOP = "laptop"
}
```

## Rules

Device identifiers must:

- be strings
- contain non-whitespace characters
- be unique
- remain stable after public release
- use lowercase machine-readable values
- describe a logical device rather than a runtime instance

Valid examples:

```text
phone
laptop
tablet
vehicleTerminal
```

Invalid examples:

```text
Phone
My Laptop
device 1
```

The phone and laptop identifiers are public ForgeOS identifiers.

---

---

# Device Capabilities

Capabilities describe features supported by a logical device.

Implemented definitions:

```lua
FORGE.Definitions.DeviceCapability = {
    FULL_SCREEN_APPS = "fullScreenApps",
    WINDOWED_APPS = "windowedApps",
    TOUCH_INPUT = "touchInput",
    POINTER_INPUT = "pointerInput",
    KEYBOARD_INPUT = "keyboardInput",
    NOTIFICATIONS = "notifications",
    BACKGROUND_APPS = "backgroundApps",
    MULTI_APP = "multiApp",
    MODALS = "modals",
    NAVIGATION_HISTORY = "navigationHistory"
}
```

## Capability Meaning

### `fullScreenApps`

The device can display an application using the complete application surface.

Initial use:

- phone
- laptop

---

### `windowedApps`

The device can display applications within movable or managed windows.

Initial use:

- future laptop windowing

The initial Laptop Host may not implement this capability.

---

### `touchInput`

The device supports touch-style input interaction.

Initial use:

- phone-style controls

This capability describes interaction behaviour and does not require a physical
touchscreen.

---

### `pointerInput`

The device supports pointer movement and selection.

Initial use:

- mouse-driven laptop interface

---

### `keyboardInput`

The device supports keyboard input routed to applications.

Initial use:

- laptop
- text-entry applications

---

### `notifications`

The device can display ForgeOS notifications.

Initial use:

- phone
- laptop

---

### `backgroundApps`

The device supports applications remaining open without being the foreground
application.

Initial use:

- phone may support suspended background apps
- laptop may support open inactive apps

The exact lifecycle behaviour remains controlled by device policy.

---

### `multiApp`

The device supports more than one open application simultaneously.

Initial implementation recommendation:

- phone: false
- laptop: false

The capability may become true for the laptop after window management exists.

---

### `modals`

The device can display a modal navigation layer above an application route.

---

### `navigationHistory`

The device supports logical back-stack navigation.

Initial use:

- phone
- laptop

---

---

# Initial Device Capability Profiles

The following profiles are design defaults, not runtime registrations.

## Phone

```lua
{
    fullScreenApps = true,
    windowedApps = false,
    touchInput = true,
    pointerInput = false,
    keyboardInput = false,
    notifications = true,
    backgroundApps = true,
    multiApp = false,
    modals = true,
    navigationHistory = true
}
```

## Laptop

```lua
{
    fullScreenApps = true,
    windowedApps = false,
    touchInput = false,
    pointerInput = true,
    keyboardInput = true,
    notifications = true,
    backgroundApps = true,
    multiApp = false,
    modals = true,
    navigationHistory = true
}
```

Laptop windowing and multiple simultaneous applications are deferred.

---

---

# Device Visibility

Device visibility describes whether a device host instance is currently
presented to a player.

Implemented definitions:

```lua
FORGE.Definitions.DeviceVisibility = {
    HIDDEN = "hidden",
    VISIBLE = "visible"
}
```

Visibility is separate from application lifecycle.

Hiding a device does not automatically close its active application or erase
its resume state.

Example:

```text
Phone visible
    forge.projects active

Phone hidden
    forge.projects remains the phone resume target

Phone visible again
    ForgeOS restores the last valid app and route
```

M2.010 visibility operations are:

```lua
FORGE.ForgeOS:showDevice(deviceId) -> ForgeOSResult
FORGE.ForgeOS:hideDevice(deviceId) -> ForgeOSResult
FORGE.ForgeOS:getDeviceVisibility(deviceId) -> DeviceVisibility | nil
```

Mutation precedence is invalid identifier, runtime-active gate, registered
device, usable runtime Host binding, authoritative state commit, then event.
Visibility starts `HIDDEN`, is runtime-only, and idempotent calls publish no
event. A completed change publishes `DEVICE_VISIBILITY_CHANGED` with local
player, device, previous visibility, and current visibility identifiers.

Device visibility is initially player-local runtime state.

Whether visibility itself should ever be persisted remains an implementation
decision. The last valid app and route are persisted independently.

---

# Application Lifecycle States

ForgeOS application lifecycle states describe runtime application state for a
specific player and device.

Registration, enabled policy, and availability are not lifecycle states.

They remain owned by:

```text
App Registry
    registration

Availability Service
    calculated availability

Lifecycle Service
    runtime lifecycle
```

Authoritative lifecycle definitions:

```lua
FORGE.Definitions.AppLifecycleState = {
    CLOSED = "closed",
    OPEN = "open",
    ACTIVE = "active",
    BACKGROUND = "background"
}
```

Lifecycle state is conceptually tracked per player and per device type as part
of player device state. M2 MAY resolve the player through the isolated
`player.local` resolver.

---

# Lifecycle State Meaning

## `closed`

The application has no active presentation state on the device.

It remains registered and may still be available.

## `open`

The application has an active runtime presence on the device but is not
necessarily the foreground application.

## `active`

The application is the foreground application receiving primary user
interaction on the device.

Initial ForgeOS policy supports one active application per device.

## `background`

The application remains open but is not the foreground application.

The device must support background applications.

Enabled or disabled policy is a validated state or policy input owned outside
the Lifecycle Service. It constrains availability and lifecycle transitions but
is not itself a lifecycle state. Registration and calculated availability are
also not lifecycle states.

---

# Lifecycle Transition Model

Initial valid transitions:

```text
CLOSED     → OPEN

OPEN       → ACTIVE
OPEN       → BACKGROUND
OPEN       → CLOSED

ACTIVE     → BACKGROUND
ACTIVE     → CLOSED

BACKGROUND → ACTIVE
BACKGROUND → CLOSED
```

Enabled policy and calculated availability MUST permit a transition before it
may occur. In particular, availability must be confirmed before transitioning
from `CLOSED` to `OPEN`.

The Lifecycle Service must reject unsupported transitions.

Device policy may impose additional restrictions.

Examples:

- a phone may background or close its current active app before activating
  another app
- a device without background support must close the previous app
- disabled policy prevents opening or activating an application
- hiding a device does not automatically perform a lifecycle transition

---

## M2.007 Lifecycle Operation Contract

Public operations are `openApp(deviceId, appId)`,
`activateApp(deviceId, appId)`, `backgroundApp(deviceId, appId)`, and
`closeApp(deviceId, appId)`. They return one `ForgeOSResult`. Queries return
the current lifecycle state or active app identifier and never mutate state.

Validation precedence is invalid argument, runtime availability, registered
device, registered app, presentation eligibility for `CLOSED -> OPEN`, enabled
policy, transition validity, callbacks, state commit, and event publication.
The applicable results are `INVALID_ARGUMENT`, `NOT_AVAILABLE`,
`NOT_REGISTERED`, resolver-controlled eligibility failures,
`POLICY_REJECTED`, `INVALID_TRANSITION`, `CALLBACK_FAILED`, `STATE_ERROR`,
`INTERNAL_ERROR`, and `SUCCESS`.

Idempotent success without callbacks or events applies to opening any already
open lifecycle state, activating the already active app, backgrounding an
already background app, and closing an already closed app. Activation does not
implicitly open a closed app.

One active app is permitted per device. Activating another app backgrounds the
previous app when `BACKGROUND_APPS` is true and otherwise closes it. Both
ForgeOS-owned changes commit atomically after all required callbacks succeed.
The displaced transition is processed and published first.

Lifecycle callback completion is not a transaction over arbitrary
application-owned side effects. Callback failure prevents ForgeOS lifecycle
state and event commit but does not compensate callback code that already ran.

Lifecycle event payloads use `ForgeOSPlayerId.LOCAL`, `deviceId`, `appId`,
`previousState`, and `currentState`. Runtime lifecycle state and enabled
overrides clear on shutdown and are never serialized.

---

# Application Availability Reasons

Availability checks should return both a result and an authoritative reason.

Implemented definitions:

```lua
FORGE.Definitions.AppAvailabilityReason = {
    AVAILABLE = "available",
    APP_NOT_REGISTERED = "appNotRegistered",
    DEVICE_NOT_REGISTERED = "deviceNotRegistered",
    DEVICE_NOT_SUPPORTED = "deviceNotSupported",
    MISSING_CAPABILITY = "missingCapability",
    PRESENTATION_NOT_FOUND = "presentationNotFound",
    ROUTE_NOT_FOUND = "routeNotFound",
    ACTION_NOT_AVAILABLE = "actionNotAvailable",
    API_VERSION_UNSUPPORTED = "apiVersionUnsupported",
    APP_DISABLED = "appDisabled",
    POLICY_REJECTED = "policyRejected",
    INVALID_DEFINITION = "invalidDefinition",
    UNKNOWN = "unknown"
}
```

## Reason Meaning

### `available`

The app passed every availability and presentation-resolution check.

### `appNotRegistered`

The requested application does not exist in the App Registry.

### `deviceNotRegistered`

The requested device does not exist in the Device Registry.

### `deviceNotSupported`

The app does not declare support for the requested device.

### `missingCapability`

The device does not provide one or more capabilities required by the app or
selected presentation.

The result should identify the missing capability where possible.

### `presentationNotFound`

The app supports the device in principle, but ForgeOS could not resolve an
exact, capability-compatible, or default presentation.

### `routeNotFound`

The requested or restored route does not exist in the resolved presentation.

A resume operation should fall back to the presentation default route where
possible.

### `actionNotAvailable`

The resolved presentation does not expose the requested app action, or an
action-specific requirement was not satisfied.

### `apiVersionUnsupported`

The application requires a ForgeOS app API version that the current runtime does
not support.

### `appDisabled`

The application is currently disabled.

### `policyRejected`

An external availability provider rejected access.

Possible sources include:

- campaign progression
- company access
- player permissions
- gameplay restrictions

### `invalidDefinition`

The device, app, presentation, route, or action definition is malformed.

This normally indicates a registration or implementation problem.

### `unknown`

The service could not provide a more specific reason.

This should be rare and should normally produce diagnostic output.

---

# Presentation Match Types

ForgeOS applications have one stable identity but may provide multiple
device-specific presentations.

ForgeOS records how a presentation was resolved using:

```lua
FORGE.Definitions.PresentationMatchType = {
    EXACT_DEVICE = "exactDevice",
    CAPABILITY = "capability",
    DEFAULT = "default"
}
```

## `exactDevice`

The presentation was registered directly for the requested device ID.

Example:

```text
device = phone
presentation key = phone
```

## `capability`

The presentation was selected because its required capabilities are satisfied
by the device.

This supports future devices without requiring every app to hardcode every
device ID. Capability matching for a device type not listed in
`supportedDevices` is permitted only when the app sets
`allowCapabilityFallback = true`.

## `default`

The app's declared default presentation was used after no exact or
capability-based presentation was selected and only when support and fallback
rules permit it.

When `supportedDevices` supplies an exact declaration for a device type, that
declaration is authoritative. An explicit `false` is an absolute block. An app
that does not set `allowCapabilityFallback = true` MUST be unavailable on
undeclared device types even when their capabilities otherwise match.

Presentation resolution order is:

```text
1. evaluate an exact supportedDevices declaration
2. reject an explicit false declaration
3. resolve an exact device presentation where available
4. resolve a compatible capability presentation when fallback is permitted
5. resolve the declared default presentation when support and fallback rules permit it
6. otherwise mark the app unavailable
```

Where multiple capability presentations match, explicit priority and
deterministic ordering must be used. Registration order must not silently
determine the result.

---

# Notification Persistence Policies

Notifications require an explicit persistence policy.

Implemented definitions:

```lua
FORGE.Definitions.NotificationPersistence = {
    TRANSIENT = "transient",
    SESSION = "session",
    SAVEGAME = "savegame"
}
```

## `transient`

The notification exists only long enough to be presented.

It is not retained in ForgeOS notification history.

Examples:

- temporary status message
- input confirmation
- development notification

---

## `session`

The notification remains available during the current mission session.

It is removed when the mission unloads.

Examples:

- session reminders
- temporary operational alerts
- UI notices that should not survive reload

---

## `savegame`

The notification is stored in ForgeOS persistent state.

It survives:

- saves
- mission unload
- savegame reload

Examples:

- received project offers
- unread messages
- important company notices
- persistent account alerts

Only plain persistable notification data may use this policy.

---

---

# Notification Severity

ForgeOS notifications should use consistent severity identifiers.

Implemented definitions:

```lua
FORGE.Definitions.NotificationSeverity = {
    INFO = "info",
    SUCCESS = "success",
    WARNING = "warning",
    ERROR = "error",
    CRITICAL = "critical"
}
```

Severity influences presentation but must not define notification behaviour.

A host may use:

- icons
- sound
- animation
- emphasis
- notification duration

The notification record remains presentation-independent.

---

---

# Navigation Layer Types

ForgeOS logical navigation uses defined layer types.

Implemented definitions:

```lua
FORGE.Definitions.NavigationLayer = {
    HOME = "home",
    APP = "app",
    ROUTE = "route",
    MODAL = "modal"
}
```

## `home`

The device's operating-system home or launcher surface.

---

## `app`

The application presentation context.

---

## `route`

A logical page or destination within an application.

---

## `modal`

A temporary navigation layer displayed above the current route.

---

---

# ForgeOS Events

ForgeOS events must use stable authoritative identifiers.

Implemented definitions:

```lua
FORGE.Definitions.ForgeOSEvent = {

    REGISTRATION_OPENED =
        "forge.os.registration.opened",

    REGISTRATION_FROZEN =
        "forge.os.registration.frozen",

    DEVICE_REGISTERED =
        "forge.os.device.registered",

    DEVICE_ACTIVATED =
        "forge.os.device.activated",

    DEVICE_DEACTIVATED =
        "forge.os.device.deactivated",

    DEVICE_VISIBILITY_CHANGED =
        "forge.os.device.visibilityChanged",

    APP_REGISTERED =
        "forge.os.app.registered",

    APP_PRESENTATION_RESOLVED =
        "forge.os.app.presentationResolved",

    APP_AVAILABILITY_CHANGED =
        "forge.os.app.availabilityChanged",

    APP_OPENED =
        "forge.os.app.opened",

    APP_ACTIVATED =
        "forge.os.app.activated",

    APP_BACKGROUNDED =
        "forge.os.app.backgrounded",

    APP_CLOSED =
        "forge.os.app.closed",

    NAVIGATION_CHANGED =
        "forge.os.navigation.changed",

    NOTIFICATION_CREATED =
        "forge.os.notification.created",

    NOTIFICATION_READ =
        "forge.os.notification.read",

    NOTIFICATION_DISMISSED =
        "forge.os.notification.dismissed",

    STARTED =
        "forge.os.started",

    STOPPED =
        "forge.os.stopped"
}
```

Device activation and deactivation must not be treated as synonyms for device
visibility.

Enabled-policy and availability changes are not lifecycle events. Their event
contracts remain to be defined with the owning policy and availability
services.

Events announce completed state changes.

They must not replace direct API results or synchronous validation.

---

# Event Payload Expectations

Event payload structures will be formalised with each component.

Initial expectations are listed below.

## Registration opened

```lua
{
    phase = "registrationOpen"
}
```

## Device registered

```lua
{
    deviceId = "phone"
}
```

## Device visibility changed

```lua
{
    playerId = "player.local",
    deviceId = "phone",
    previousVisibility = "hidden",
    currentVisibility = "visible"
}
```

## App registered

```lua
{
    appId = "forge.projects",
    ownerId = "forge.projects",
    apiVersion = 1
}
```

## App presentation resolved

```lua
{
    playerId = "player.local",
    deviceId = "phone",
    appId = "forge.projects",
    presentationId = "projects.phone",
    matchType = "exactDevice"
}
```

## App lifecycle event

```lua
{
    playerId = "player.local",
    deviceId = "phone",
    appId = "forge.projects",
    previousState = "open",
    currentState = "active"
}
```

## Navigation changed

```lua
{
    playerId = "player.local",
    deviceId = "phone",
    appId = "forge.projects",
    previousRoute = "overview",
    currentRoute = "projectDetails",
    routeParameters = {
        projectId = "project.westernRidge"
    },
    isBackNavigation = false
}
```

For M2.008, navigation operations use existing `ForgeOSResult` and
`NAVIGATION_CHANGED` identifiers. They introduce no new definition constant.
The event is published only after committed logical navigation and resume
state. Parameters are detached plain data. Runtime history is bounded but its
private capacity is not a public definition or persistence contract.

## Notification created

```lua
{
    playerId = "player.local",
    notificationId = "notification.1",
    source = "forge.projects",
    persistence = "savegame",
    notification = detachedNotification
}
```

For M2.009, every successful creation allocates an identifier in the form
`notification.<unpadded decimal sequence>`. Successful transient creation
advances the persisted sequence even though it retains no record. Failed
creation consumes no identifier, and gaps caused by transient records are
valid.

`NOTIFICATION_READ` payload:

```lua
{
    playerId = "player.local",
    notificationId = "notification.1",
    read = true
}
```

`NOTIFICATION_DISMISSED` payload:

```lua
{
    playerId = "player.local",
    notificationId = "notification.1",
    dismissed = true
}
```

Notification events announce only completed non-idempotent changes. Payloads
are detached. Listener failure does not roll back committed state or alter the
operation result.

Events announce completed changes.

They must not replace direct API results or synchronous validation.

---

# ForgeOS Result Codes

ForgeOS operations should return a boolean where appropriate and may also
return an authoritative result code.

Implemented definitions:

```lua
FORGE.Definitions.ForgeOSResult = {
    SUCCESS = "success",
    INVALID_ARGUMENT = "invalidArgument",
    INVALID_DEFINITION = "invalidDefinition",
    ALREADY_REGISTERED = "alreadyRegistered",
    NOT_REGISTERED = "notRegistered",
    REGISTRATION_CLOSED = "registrationClosed",
    API_VERSION_UNSUPPORTED = "apiVersionUnsupported",
    NOT_AVAILABLE = "notAvailable",
    PRESENTATION_NOT_FOUND = "presentationNotFound",
    ROUTE_NOT_FOUND = "routeNotFound",
    ACTION_NOT_AVAILABLE = "actionNotAvailable",
    INVALID_TRANSITION = "invalidTransition",
    CAPABILITY_MISSING = "capabilityMissing",
    POLICY_REJECTED = "policyRejected",
    STATE_ERROR = "stateError",
    CALLBACK_FAILED = "callbackFailed",
    PERSISTENCE_ERROR = "persistenceError",
    INTERNAL_ERROR = "internalError"
}
```

## Result Contract

Conceptually, ForgeOS operations may return:

```lua
return true,
    FORGE.Definitions.ForgeOSResult.SUCCESS
```

or:

```lua
return false,
    FORGE.Definitions.ForgeOSResult.NOT_AVAILABLE
```

Some operations may include a third detail value.

Example:

```lua
return false,
    FORGE.Definitions.ForgeOSResult.CAPABILITY_MISSING,
    FORGE.Definitions.DeviceCapability.KEYBOARD_INPUT
```

The exact public return contracts will be defined before implementation freeze.

---

# Application Identifier Rules

ForgeOS application identifiers must be globally unique.

Recommended format:

```text
<owner>.<application>
```

Built-in FORGE apps use:

```text
forge.<application>
```

Examples:

```text
forge.settings
forge.communications
forge.projects
forge.bank
forge.companies
```

Third-party examples:

```text
example.logistics
author.weather
campaign.contractBoard
```

Identifiers must:

- be non-empty strings
- contain no whitespace
- remain stable
- be treated as case-sensitive authoritative identifiers
- not be derived from translated display names

Display names may change without changing application identifiers.

---

---

# Route Identifier Rules

Route identifiers are application-local.

Examples:

```text
overview
activeProjects
projectDetails
settings
notificationPreferences
```

A route is uniquely identified by:

```text
appId + routeId
```

Example:

```text
forge.projects / projectDetails
```

Route identifiers must:

- be strings
- contain non-whitespace characters
- remain stable where persisted or externally referenced
- not contain translated display text

---

---

# Notification Identifier Rules

Notification identifiers must be unique within the relevant ForgeOS state
scope.

Implemented M2.009 format:

```text
notification.<unpadded decimal sequence>
```

Example:

```text
notification.1
```

The Notification Service should own identifier generation.

Applications and domain managers should not generate notification identifiers
independently unless the API explicitly supports external stable identifiers.

---

---

# Definition Validation Rules

All definition tables are input data and must be validated during registration.

ForgeOS should copy valid definitions into controlled internal representations
rather than retaining mutable caller-owned tables.

## Device definition requirements

Required:

```text
id
displayName
capabilities
```

Optional:

```text
hostId
policy
metadata
```

### M2.004 Device Registry validation

The M2.004 public operation:

```lua
FORGE.ForgeOS:registerDevice(deviceDefinition)
```

uses this deterministic result order:

1. the shared registration gate is checked first and returns
   `REGISTRATION_CLOSED` when registration is unavailable;
2. `nil` or non-table input returns `INVALID_ARGUMENT`;
3. a supplied table failing the schema or controlled-data rules returns
   `INVALID_DEFINITION`;
4. an already registered validated identifier returns `ALREADY_REGISTERED`;
5. a valid atomic commit returns `SUCCESS`; and
6. `INTERNAL_ERROR` is reserved for an unexpected internal failure.

`id` is a non-empty string without whitespace. `displayName` is a non-empty
string. `capabilities` is a table whose keys are approved
`DeviceCapability` values and whose values are Boolean; the table may be
empty. Optional `hostId` is a non-empty string without whitespace.

Optional `policy` and `metadata` are opaque plain-data tables. Controlled data
may contain finite numbers, strings, Booleans, and acyclic nested tables. It
must not contain functions, userdata, threads, callbacks, runtime objects,
cycles, or non-finite numbers. Unknown fields are ignored and not stored.

Registration copies recognized fields into controlled storage. Queries return
detached data and cannot expose a mutable reference to authoritative registry
state. Registered identifier enumeration is lexical.

Successful commit publishes:

```lua
FORGE.Definitions.ForgeOSEvent.DEVICE_REGISTERED
```

with:

```lua
{
    deviceId = registeredDeviceId
}
```

Rejected registration does not publish the event. Listener failure is reported
through the existing Event Bus and Logger path, does not remove the committed
definition, and does not change the operation result from `SUCCESS`.

These rules do not define third-party namespace ownership, resolve `hostId`,
interpret `policy` or `metadata`, or automatically create built-in device
profiles.

## App definition requirements

Required:

```text
id
apiVersion
displayName
supportedDevices
presentations
```

Optional:

```text
ownerId
iconId
controller
requiredCapabilities
allowCapabilityFallback
defaultPresentation
availabilityProviders
metadata
callbacks
```

`allowCapabilityFallback` is optional and defaults to `false`.

An exact `supportedDevices[deviceId] = true` permits the device type. An exact
`false` is an absolute block and MUST NOT be overridden by capability or default
fallback. An undeclared device type MAY use capability or default presentation
fallback only when `allowCapabilityFallback = true`.

App-level `requiredCapabilities` are universal minimum requirements.
Presentation-level `requiredCapabilities` are additional requirements for the
selected presentation; they MUST NOT weaken or override app-level requirements.

### M2.005 App Registry validation

The M2.005 public operation:

```lua
FORGE.ForgeOS:registerApp(appDefinition)
```

uses this deterministic result order:

1. the shared registration gate is checked first and returns
   `REGISTRATION_CLOSED` when registration is unavailable;
2. `nil` or non-table input returns `INVALID_ARGUMENT`;
3. a supplied table failing schema or controlled-data rules returns
   `INVALID_DEFINITION`;
4. an unsupported `apiVersion` returns `API_VERSION_UNSUPPORTED`;
5. an already registered validated identifier returns `ALREADY_REGISTERED`;
6. a valid atomic commit returns `SUCCESS`; and
7. `INTERNAL_ERROR` is reserved for an unexpected internal failure.

Identifiers and optional `ownerId` are non-empty strings without whitespace.
Required display names are non-empty strings. Device declarations are Boolean.
Capability requirements use approved `DeviceCapability` identifiers and may
only require a capability with `true`.

Presentations, routes, actions, defaults, and capability declarations must be
internally consistent. Optional declarative metadata is controlled plain data:
finite numbers, strings, Booleans, and acyclic nested tables only. Unknown
fields are ignored.

Executable references are runtime-owned implementation assets. Controllers,
callbacks, availability-provider functions, route controllers, and action
handlers are validated by type and may be retained privately, but are excluded
from serialization and public definition snapshots. M2.005 does not invoke
them.

Registration copies recognized data into controlled storage. Queries return
detached public data and cannot expose authoritative registry state.
Registered identifier enumeration is lexical.

Successful commit publishes:

```lua
FORGE.Definitions.ForgeOSEvent.APP_REGISTERED
```

with:

```lua
{
    appId = registeredAppId
}
```

Rejected registration does not publish the event. Listener failure is reported
through the existing Event Bus and Logger path, does not remove the committed
definition, and does not change the operation result from `SUCCESS`.

These rules do not resolve owner identity, select presentations, invoke
executable references, or implement lifecycle, navigation, availability, host,
or persistence behaviour for applications.

### M2.006 Presentation Resolver results

`FORGE.ForgeOS:resolvePresentation(appId, deviceId)` returns
`result, resolution`.

Result precedence is:

1. invalid identifiers return `INVALID_ARGUMENT`;
2. a phase other than `RUNTIME_ACTIVE` returns `NOT_AVAILABLE` without registry
   lookup;
3. a missing app or device returns `NOT_REGISTERED` with its corresponding
   `AppAvailabilityReason`;
4. unsupported device rules return `NOT_AVAILABLE` with
   `DEVICE_NOT_SUPPORTED`;
5. final capability incompatibility returns `CAPABILITY_MISSING` with
   `MISSING_CAPABILITY`;
6. no usable presentation returns `PRESENTATION_NOT_FOUND`; and
7. unexpected failure returns `INTERNAL_ERROR` with `UNKNOWN`.

Success returns a detached record containing `appId`, `deviceId`,
`presentationKey`, `presentationId`, `matchType`, and `presentation`.

App requirements are evaluated first in lexical order. Presentation candidates
are deterministic and their missing requirements are lexical. The first
candidate capability failure is retained while later candidates remain
eligible to succeed.

Every finite numeric priority is valid. Omitted priority is zero. Higher
priority wins and lexical presentation key breaks ties. Capability candidates
exclude the exact and default keys and require at least one presentation
capability. Default evaluation is a distinct final stage.

`defaultRoute` is not an app-level field.

Each presentation owns its own default route.

## Presentation definition requirements

Required:

```text
id
defaultRoute
routes
```

Optional:

```text
requiredCapabilities
actions
controller
metadata
priority
```

ForgeOS must verify that:

- presentation IDs are valid and deterministic
- every route ID is valid
- every action ID is valid
- `defaultRoute` exists in the presentation's route table
- capability identifiers are recognised
- callback and controller values satisfy the app contract
- capability-based presentation ties are resolved deterministically

## Route definition requirements

A route must have a valid application-local identifier.

Optional route data may include:

```text
controller
requiredCapabilities
availabilityProviders
metadata
```

Persisted route parameters are runtime state and must use plain persistable
values.

## Action definition requirements

An action must have a valid application-local identifier.

An action may define:

```text
handler
requiredCapabilities
enabled
metadata
```

An exposed action does not bypass domain-manager validation.

## Unknown fields

Unknown fields must not silently become part of the public contract.

The initial recommendation is to ignore unknown fields only when ForgeOS creates
a controlled validated copy containing recognised fields.

Registration must be atomic.

An invalid device, app, or presentation must not leave a partial registry
entry.

---

# Authoritative Shared Definitions

The following definitions are expected to become public and stable:

```text
ForgeOSVersion
ForgeOSNamespace
ForgeOSPhase
ForgeOSPlayerId
DeviceId
DeviceCapability
DeviceVisibility
AppLifecycleState
AppAvailabilityReason
PresentationMatchType
NotificationPersistence
NotificationSeverity
NavigationLayer
ForgeOSEvent
ForgeOSResult
ForgeOS Log Sources
```

Changes to these definitions after API freeze require:

1. documentation updates
2. test updates
3. compatibility review
4. migration planning where persisted identifiers are affected
5. addon compatibility review where public contracts are affected

---

# Initial Definition File Plan

Recommended implementation:

```text
forgeos/definitions/
├── ForgeOSDefinitions.lua
├── ForgeOSVersion.lua
├── ForgeOSNamespace.lua
├── ForgeOSPhase.lua
├── ForgeOSPlayerId.lua
├── DeviceId.lua
├── DeviceCapability.lua
├── DeviceVisibility.lua
├── AppLifecycleState.lua
├── AppAvailabilityReason.lua
├── PresentationMatchType.lua
├── NotificationPersistence.lua
├── NotificationSeverity.lua
├── NavigationLayer.lua
├── ForgeOSEvent.lua
└── ForgeOSResult.lua
```

`ForgeOSDefinitions.lua` establishes any shared ForgeOS definition namespace or
load-time validation required by the subsystem.

Individual definition files assign authoritative tables such as:

```lua
FORGE.Definitions.ForgeOSVersion = {}
FORGE.Definitions.ForgeOSNamespace = {}
FORGE.Definitions.ForgeOSPhase = {}
FORGE.Definitions.ForgeOSPlayerId = {}
FORGE.Definitions.DeviceId = {}
FORGE.Definitions.DeviceCapability = {}
FORGE.Definitions.DeviceVisibility = {}
FORGE.Definitions.AppLifecycleState = {}
FORGE.Definitions.AppAvailabilityReason = {}
FORGE.Definitions.PresentationMatchType = {}
FORGE.Definitions.NotificationPersistence = {}
FORGE.Definitions.NotificationSeverity = {}
FORGE.Definitions.NavigationLayer = {}
FORGE.Definitions.ForgeOSEvent = {}
FORGE.Definitions.ForgeOSResult = {}
```

A flatter definition structure remains consistent with existing definitions
such as:

```text
LogLevel
LogSource
```

The final file structure should favour contributor clarity over unnecessary
nesting.

---

# Initial Implementation Order

The recommended definition implementation order is:

```text
1. Extend LogSource.lua
2. Create ForgeOSDefinitions.lua
3. Create ForgeOSVersion.lua
4. Create ForgeOSNamespace.lua
5. Create ForgeOSPhase.lua
6. Create ForgeOSPlayerId.lua
7. Create DeviceId.lua
8. Create DeviceCapability.lua
9. Create DeviceVisibility.lua
10. Create AppLifecycleState.lua
11. Create AppAvailabilityReason.lua
12. Create PresentationMatchType.lua
13. Create NotificationPersistence.lua
14. Create NotificationSeverity.lua
15. Create NavigationLayer.lua
16. Create ForgeOSEvent.lua
17. Create ForgeOSResult.lua
18. Add definitions to modDesc.xml
19. Add definition tests
20. Run one batch verification
```

The synchronisation manifest must include the ForgeOS definition directory
before runtime testing begins.

---

# Open Definition Decisions

The following items remain intentionally open.

## Device identifier extensibility

Built-in IDs are defined authoritatively, and third-party device types MAY
register custom identifiers during `REGISTRATION_OPEN`.

The `DeviceId` definition table therefore lists built-in identifiers without
implying that only those identifiers are valid.

Ownership rules, compatibility rules, identifier namespace rules, and collision
prevention for third-party identifiers remain unresolved.

## Stable player identity

M2 MAY use the isolated temporary identity:

```text
player.local
```

The source of a stable multiplayer player identifier remains open.

This must be solved through the identity resolver rather than by changing every
state consumer.

## Presentation priority range

Capability-based presentation definitions use a numeric priority.

M2.006 accepts every finite numeric priority. Omitted priority is zero. Higher
values are preferred and lexical presentation key resolves equal values.
Registration and Lua table iteration order do not affect selection.

## Active-device persistence

The state model permits remembering the last selected device.

Whether `activeDeviceId` is persisted in the first implementation remains open.

This does not affect the conceptual per-player and per-device state shape.
Current persistence remains savegame-global.

---

# Frozen Pre-Implementation Decisions

The following design decisions are now authoritative for the initial ForgeOS
implementation:

```text
Registration
    one lifecycle for Device Registry, Device Host Registry, and App Registry
    runtime device host instances are not registrations

Availability
    calculated by Availability Service

Enabled policy
    validated input owned outside Lifecycle Service

Lifecycle
    CLOSED
    OPEN
    ACTIVE
    BACKGROUND

App identity
    one stable app ID

Presentations
    exact device
    explicit false is an absolute block
    capability or default fallback only when allowCapabilityFallback is true
    app and presentation capability requirements both apply

State scope
    conceptually per player and per device

Initial player scope
    isolated player.local resolver

Device visibility
    separate from app lifecycle

Resume persistence
    last valid app
    last valid presentation reference
    last valid route
    safe route parameters

Navigation persistence
    no full back stack or modal stack during M2

Addon registration
    public content registration permitted only during REGISTRATION_OPEN

Persistence
    forge.os is the stable State Store namespace
    runtime objects and ephemeral presentation state are never persisted
    restored runtime lifecycle is reconstructed and validated

Compatibility
    ForgeOS app API version is separate from persistence version
```

These decisions should not be reopened during individual registry or service
implementation unless testing reveals a concrete architectural conflict.

---

# Success Criteria

M2.002 – ForgeOS Definitions is complete when:

1. Every initial ForgeOS identifier has one authoritative definition.
2. ForgeOS app API and state versions are defined separately.
3. The `forge.os` namespace is defined.
4. ForgeOS registration and runtime phases are defined.
5. The temporary player identity is isolated authoritatively.
6. Built-in device IDs are defined.
7. Device capabilities and visibility states are defined.
8. Lifecycle states contain only runtime lifecycle conditions.
9. Availability reasons include presentation, route, action, and API failures.
10. Presentation match types are defined.
11. Notification policies and severities are defined.
12. Navigation layers are defined.
13. Event identifiers are defined.
14. Result codes are defined.
15. ForgeOS log sources are added.
16. App and presentation validation requirements match the App Contract.
17. Definitions are loaded in the correct order.
18. Definitions have a manual test harness.
19. No ForgeOS implementation file requires repeated raw identifiers.
20. The documentation, App Contract, and State Model use the same vocabulary.

---

## Provisional Cross-Mod Bridge Values

The M2.010 FS25 adapter uses bridge protocol version `1` and the provisional
message topic `forge.crossMod.forgeOS.request.v1`. These are adapter protocol
values, not ForgeOS definition constants, engine versions, App API versions,
or persistence versions. A consumer must independently require bridge version
1 and `forgeOS:supportsAppApiVersion(1) == true`.

The request container begins with `requestedBridgeVersion = 1` and
`responderCount = 0`. A recognized provider may modify only
`responderCount`, `bridgeVersion`, and `forgeOS`. Consumers accept exactly one
responder and reject zero or multiple responders. The exact protocol is not
frozen until its real cross-mod behaviour is verified.

# Related Documentation

- [M2 Architecture Review](../reviews/M2ArchitectureReview.md) records accepted
  definition decisions, deferrals, and remaining gaps.
- [Engineering Process](../style/EngineeringProcess.md) defines review,
  approval, implementation, and verification governance.
- [Git Workflow](../style/GitWorkflow.md) governs promotion, tagging, and
  release handling for stable definitions and compatibility changes.
