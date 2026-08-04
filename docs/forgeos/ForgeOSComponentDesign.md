# FORGE ForgeOS Component Design

**Version:** 0.1  
**Status:** Draft  
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

## Proposed Location

```text
engine/forgeos/ForgeOS.lua
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

## Proposed Location

```text
engine/forgeos/ForgeOSCore.lua
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

---

# Device Registry

## Responsibility

The Device Registry owns authoritative registered-device definitions.

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

## Ownership

The Device Registry owns registered definitions.

The Device Registry does not own:

- active device
- current application
- host rendering
- application availability
- navigation history

## Required Operations

Conceptually, the registry must support:

```text
register device
check whether device exists
retrieve device definition
retrieve all devices
clear registrations
```

## Proposed Location

```text
engine/forgeos/registries/DeviceRegistry.lua
```

---

# Device Host Registry

## Responsibility

The Device Host Registry associates logical device definitions with runtime
presentation hosts.

A device definition describes capabilities.

A device host implements presentation.

Example:

```text
Device Definition
phone
    ↓
Host Binding
forge.phoneHost
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
register host
retrieve host
bind host to device
unbind host
clear hosts
```

## Proposed Location

```text
engine/forgeos/registries/DeviceHostRegistry.lua
```

This component may be deferred until the first host implementation if it proves
unnecessary during the headless foundation.

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

Conceptually:

```text
register app
check whether app exists
retrieve app definition
retrieve all apps
clear registrations
```

## Proposed Location

```text
engine/forgeos/registries/AppRegistry.lua
```

---

# Availability Service

## Responsibility

The Availability Service determines whether a registered application is
currently available on a specific device.

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
3. the app supports the device
4. the device satisfies required capabilities
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

## Proposed Location

```text
engine/forgeos/services/AppAvailabilityService.lua
```

---

# Lifecycle Service

## Responsibility

The Lifecycle Service owns application runtime state and valid state
transitions.

It tracks lifecycle state per device.

Example:

```text
phone
└── forge.projects = ACTIVE

laptop
├── forge.projects = OPEN
└── forge.bank = ACTIVE
```

## Initial Lifecycle States

```text
REGISTERED
AVAILABLE
OPEN
ACTIVE
BACKGROUND
CLOSED
DISABLED
```

These names remain provisional until the ForgeOS Definitions milestone.

## Transition Ownership

Only the Lifecycle Service may mutate lifecycle state.

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
REGISTERED → AVAILABLE
AVAILABLE  → OPEN
OPEN       → ACTIVE
ACTIVE     → BACKGROUND
BACKGROUND → ACTIVE
OPEN       → CLOSED
ACTIVE     → CLOSED
BACKGROUND → CLOSED
AVAILABLE  → DISABLED
DISABLED   → AVAILABLE
```

Device policies may impose additional restrictions.

Example:

- Phone allows one active app.
- Laptop may allow multiple open apps.
- A device without background support closes or suspends the previous app.

## Proposed Location

```text
engine/forgeos/services/AppLifecycleService.lua
```

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

## Proposed Location

```text
engine/forgeos/services/NavigationService.lua
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
    id = "notification.000001",
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

## Proposed Location

```text
engine/forgeos/services/NotificationService.lua
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

Proposed namespace:

```text
forge.os
```

## Persistence Boundary

Only persistent state belongs in the ForgeOS namespace.

Registry definitions should normally be rebuilt during startup rather than
saved, because they originate from engine and module registration.

Likely persistent:

```text
last active device
last active app
read notification state
user preferences
accessibility preferences
device preferences
```

Likely transient:

```text
registered app definitions
registered device definitions
host runtime references
render targets
temporary animations
input state
open modal callbacks
```

## Proposed Location

ForgeOS may access state through the existing State Store rather than creating a
separate state container.

A thin state-coordination component may still be useful:

```text
engine/forgeos/services/ForgeOSStateService.lua
```

Its necessity should be decided during implementation design.

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

## Proposed Location

```text
engine/forgeos/hosts/PhoneHost.lua
```

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

## Proposed Location

```text
engine/forgeos/hosts/LaptopHost.lua
```

---

# ForgeOS Application Contract

## Responsibility

Every application must implement a predictable contract.

The final contract remains to be defined, but may include:

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
M2.003 Device Registry
    ↓
M2.004 App Registry
    ↓
M2.005 App Availability
    ↓
M2.006 App Lifecycle
    ↓
M2.007 Navigation
    ↓
M2.008 Notifications
    ↓
M2.009 ForgeOS Persistence
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

# Open Design Decisions

The following questions must be resolved before or during implementation.

## Device Selection

Should ForgeOS maintain one globally active device, or should each local player
have an independent active device?

The likely answer is player-local, but the multiplayer and persistence model
must be designed first.

## Lifecycle Granularity

Should lifecycle state be tracked:

- per app globally
- per app per device
- per app per player per device

The long-term architecture likely requires per player and per device.

The first implementation may use a simpler model if the limitation is clearly
documented and does not hardcode an incompatible API.

## Laptop Windowing

Should multi-window support be part of M2, or should the Laptop Host initially
support one active app?

The recommended initial design is one active app, with future lifecycle APIs
remaining capable of supporting multiple open apps.

## App Unlocks

Should progression-based unlocks be:

- stored directly in ForgeOS
- provided by domain managers
- provided by campaign policy
- combined through availability providers

The recommended design is external availability providers so ForgeOS does not
own gameplay progression.

## Notification Persistence

Which notifications should survive reload?

The likely design requires an explicit persistence policy per notification:

```text
TRANSIENT
SESSION
SAVEGAME
```

These names remain provisional.

## Application Callbacks

Should callbacks live directly in app definitions, or should definitions refer
to separate application controller objects?

Separate controller objects are likely cleaner for complex apps.

## Route Parameters

What values may be stored in route parameters?

For safety and persistence compatibility, route parameters should probably be
limited to plain data:

- strings
- finite numbers
- booleans
- plain tables with string keys

## Registration Timing

When may external modules register devices and apps?

Possible phases:

```text
definitions loaded
ForgeOS initialising
registration open
registration frozen
mission active
```

A formal registration lifecycle may prevent late or inconsistent registration.

---

# Initial Recommendations

For the first implementation:

1. Track lifecycle state per device.
2. Support one active application per device.
3. Allow multiple registered devices.
4. Keep phone and laptop state separate.
5. Use external availability providers for progression restrictions.
6. Start with logical navigation and one route stack per app per device.
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