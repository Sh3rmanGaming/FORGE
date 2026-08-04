# FORGE ForgeOS State Model

**Version:** 0.1  
**Status:** Draft  
**Milestone:** M2 – ForgeOS

---

# Purpose

This document defines the runtime and persistent state model used by ForgeOS.

It establishes:

- state ownership
- player scope
- device scope
- application lifecycle state
- device visibility state
- navigation state
- resume state
- notification state
- persistence boundaries
- multiplayer authority boundaries
- restoration and fallback behaviour

ForgeOS state must remain independent of UI rendering objects and domain
gameplay state.

---

# Core State Principle

ForgeOS state is conceptually scoped:

```text
per player
    per device
        per application
```

The long-term model is:

```text
player
└── device
    ├── visibility
    ├── active app
    ├── resume state
    ├── navigation state
    ├── device preferences
    └── app lifecycle state
```

M2 may initially use one local-player scope, but the data structure and public
APIs must remain compatible with future per-player state.

---

# State Ownership

ForgeOS owns:

- device visibility
- active application per device
- app lifecycle state per device
- logical navigation state
- device resume state
- ForgeOS preferences
- notification records owned by ForgeOS
- app enabled-state overrides

ForgeOS does not own:

- project state
- bank accounts
- company records
- communication domain records
- gameplay progression rules
- domain validation
- rendering state

---

# State Layers

ForgeOS state is divided into four categories.

```text
Registration State
Runtime OS State
Persistent Resume State
Transient Presentation State
```

Each category has a separate ownership and persistence policy.

---

# Registration State

Registration state contains definitions rebuilt during startup.

Examples:

- registered devices
- registered applications
- registered presentations
- availability providers
- host bindings
- app controllers
- callbacks

Registration state is not persisted.

Reasons:

- definitions originate from installed mods
- callbacks and runtime references cannot be serialized
- installed addons may change between sessions
- registration must be validated each startup

---

# Runtime OS State

Runtime OS state describes the currently active ForgeOS session.

Examples:

- active device
- device visibility
- active app per device
- app lifecycle state
- current navigation route
- modal state
- session notifications

Some runtime state may also contribute to persistent resume state.

---

# Persistent Resume State

Resume state stores enough information to reopen a device where the player left
it.

Persisted values may include:

- last valid app ID
- last valid presentation ID
- last valid route ID
- safe route parameters
- selected app section
- device preferences
- notification read state
- saved notification records

Resume state does not require the device to remain logically open between
sessions.

---

# Transient Presentation State

Transient presentation state belongs to the host or presentation controller.

Examples:

- animation progress
- pointer position
- hover state
- pressed button state
- temporary UI object references
- render targets
- callback closures
- modal animation state
- unsaved text input buffers

Transient state must never be written into ForgeOS persistence.

---

# State Store Namespace

ForgeOS persistent state uses:

```text
forge.os
```

ForgeOS must register this namespace with:

```text
FORGE.StateStore
FORGE.SaveManager
```

ForgeOS must not access XML Reader or XML Writer directly.

---

# Proposed Persistent Structure

Conceptual structure:

```lua
{
    version = 1,

    players = {
        ["player.local"] = {
            activeDeviceId = "phone",

            devices = {
                phone = {
                    lastAppId = "forge.projects",
                    lastPresentationId =
                        "projects.phone",
                    lastRouteId =
                        "projectDetails",

                    routeParameters = {
                        projectId =
                            "project.westernRidge"
                    },

                    preferences = {}
                },

                laptop = {
                    lastAppId = "forge.bank",
                    lastPresentationId =
                        "bank.laptop",
                    lastRouteId = "accounts",
                    routeParameters = {},
                    preferences = {}
                }
            },

            notifications = {}
        }
    }
}
```

The exact field names may be refined during implementation.

---

# ForgeOS State Version

ForgeOS should maintain an internal state version separate from the XML schema
version.

Example:

```lua
version = 1
```

This allows ForgeOS state migrations without necessarily changing the global
persistence document schema.

The following versions are separate:

```text
FORGE persistence schema version
ForgeOS state version
ForgeOS app API version
FORGE public addon API version
```

---

# Player Scope

The target architecture is per-player.

Conceptually:

```text
players[playerId]
```

M2 may initially use one resolved local-player identity.

The player identity must be obtained through one controlled resolver.

Conceptual API:

```lua
FORGE.ForgeOS:getCurrentPlayerId()
```

Implementation code must not scatter a literal such as:

```text
localPlayer
```

throughout the subsystem.

---

# Initial Player Identity

Until stable multiplayer identity integration exists, M2 may use an internal
single-player identifier such as:

```text
player.local
```

That identifier must be isolated behind the player identity resolver.

Future multiplayer support should replace the resolver rather than redesign all
state consumers.

---

# Device Scope

Resume and runtime state are stored separately for each device.

Example:

```text
player.local
├── phone
└── laptop
```

The phone and laptop may remember different apps and routes.

Example:

```text
Phone
    forge.projects / projectDetails

Laptop
    forge.bank / accounts
```

Opening one device must not overwrite the resume state of another device.

---

# Device Visibility State

Device visibility describes whether the host interface is currently displayed.

Proposed values:

```text
VISIBLE
HIDDEN
```

Visibility is runtime state.

It is separate from app lifecycle.

---

# Visibility Rule

Hiding a device does not automatically close its active application.

Example:

```text
Phone visible
    forge.projects active

Phone hidden
    forge.projects remains resume target

Phone visible again
    forge.projects restored
```

A device policy may later choose to background or suspend an app, but hiding the
host must not erase its resume state.

---

# Active Device

ForgeOS may track the currently selected device for a player.

Example:

```text
activeDeviceId = phone
```

This may be persistent where useful.

However, active device identity must not imply device visibility.

Possible combinations:

```text
active device = phone
phone visibility = hidden
```

This allows the last selected device to be remembered without forcing its UI to
remain visible.

---

# Application Lifecycle State

Application lifecycle is tracked per player and per device.

Recommended lifecycle states:

```text
CLOSED
OPEN
ACTIVE
BACKGROUND
DISABLED
```

Registration and availability are not lifecycle states.

They remain owned by:

```text
App Registry
Availability Service
```

---

# Lifecycle State Shape

Conceptual runtime state:

```lua
appStates = {
    ["forge.projects"] = "active",
    ["forge.bank"] = "closed"
}
```

This table belongs under a specific player and device scope.

Example:

```text
players[playerId]
└── devices[deviceId]
    └── appStates[appId]
```

---

# Initial Lifecycle Policy

M2 supports:

- multiple registered apps
- one active app per device
- zero or more open/background apps where supported
- independent lifecycle state per device

Initial device policy:

```text
Phone
    one active app
    background support allowed
    multi-app presentation disabled

Laptop
    one active app
    background support allowed
    multi-window presentation deferred
```

---

# Active Application

Each device may have one active application.

Conceptual field:

```lua
activeAppId = "forge.projects"
```

The active app must:

- be registered
- be available
- support the device
- have a resolved presentation
- not be disabled

If any condition becomes invalid, ForgeOS must select a safe fallback.

---

# Resume State

Resume state is the persisted destination restored when a device reopens.

Conceptual fields:

```text
lastAppId
lastPresentationId
lastRouteId
routeParameters
```

Resume state is per player and per device.

---

# Resume Update Timing

Resume state should update after successful state changes.

Examples:

```text
app successfully activated
    update lastAppId

route successfully changed
    update lastRouteId

route parameters successfully validated
    update routeParameters
```

Failed lifecycle or navigation requests must not overwrite valid resume state.

---

# Resume Restoration

When a device is opened, ForgeOS should:

1. resolve player identity
2. retrieve device state
3. inspect saved app ID
4. verify app registration
5. verify current availability
6. resolve a compatible presentation
7. verify saved route
8. validate route parameters
9. restore valid state
10. publish completed state changes

---

# Resume Fallback Order

```text
saved app + saved route
        ↓
saved app + presentation default route
        ↓
device home
```

If the saved app is unavailable or removed:

```text
device home
```

ForgeOS must not fail device startup because an addon is missing.

---

# Presentation Resume State

The saved presentation ID is advisory.

ForgeOS should re-run presentation resolution during restore.

Reasons:

- device capabilities may change
- app presentation definitions may change
- addons may be updated
- exact presentation may no longer exist

If the saved presentation remains valid, it may be reused.

Otherwise ForgeOS selects the best current presentation.

---

# Navigation State

Navigation is scoped per player, device, and app.

Conceptual runtime shape:

```lua
navigation = {
    currentRouteId = "projectDetails",

    routeParameters = {
        projectId = "project.westernRidge"
    },

    history = {},
    modal = nil
}
```

---

# Persisted Navigation

M2 persists:

- current route
- safe route parameters
- selected app-local section where required

M2 does not persist:

- full back stack
- modal stack
- transient route history
- callback-based navigation state
- temporary forms
- incomplete user input

---

# Route Validation

A persisted route must be validated against the currently resolved
presentation.

A route is valid only when:

- app exists
- presentation exists
- route exists in presentation
- route parameters pass plain-data validation
- any route availability rule passes

Invalid routes fall back to the presentation default route.

---

# Route Parameter Persistence

Persisted route parameters may contain:

- strings
- finite numbers
- booleans
- nested tables with string keys

They must not contain:

- functions
- userdata
- threads
- cyclic references
- host objects
- controller objects
- UI elements
- domain object references

Domain objects should be referenced by stable identifiers.

Example:

```lua
{
    projectId = "project.westernRidge"
}
```

Not:

```lua
{
    project = projectRuntimeObject
}
```

---

# Device Preferences

Preferences may be stored per player and per device.

Examples:

```text
notification volume
interface scale
preferred home layout
accessibility settings
device theme
sort preferences
```

Preferences must remain plain persistable data.

Presentation-specific preferences should use a controlled subtable.

Example:

```lua
preferences = {
    theme = "dark",

    apps = {
        ["forge.projects"] = {
            sortMode = "deadline"
        }
    }
}
```

---

# App Enabled State

ForgeOS may store app enabled-state overrides.

Conceptual structure:

```lua
appOverrides = {
    ["forge.projects"] = {
        enabled = true
    }
}
```

Enabled state is not the same as availability.

Availability is calculated from:

- registration
- device support
- capabilities
- enabled state
- policy providers

---

# Notifications

Notification state may be scoped per player.

Conceptual structure:

```lua
notifications = {
    ["notification.000001"] = {
        source = "forge.projects",
        title = "New Project Available",
        body = "Western Ridge Expansion",
        severity = "info",
        persistence = "savegame",
        read = false,
        dismissed = false,
        targetDevices = {
            phone = true,
            laptop = true
        }
    }
}
```

---

# Notification Persistence

Notification persistence policy determines storage.

```text
TRANSIENT
    not stored

SESSION
    runtime only

SAVEGAME
    stored in forge.os
```

Only plain notification data may be persisted.

Visual animation state remains host-local and transient.

---

# Notification Read State

Read and dismissed state may be player-specific.

Example:

```text
Player A
    notification unread

Player B
    notification read
```

The initial single-player implementation may use one local player scope while
preserving this structure.

---

# Authoritative State

ForgeOS state must be classified as either authoritative or player-local.

## Authoritative shared state

Examples:

- app unlocks caused by gameplay
- campaign restrictions
- company access restrictions
- gameplay-created notifications
- shared project alerts

Controlled by the authoritative server or domain manager.

## Player-local persistent state

Examples:

- last app
- last route
- notification read state
- device preferences
- accessibility preferences

Future per-player persistence is required.

## Player-local transient state

Examples:

- visible device
- pointer position
- animation progress
- hover state
- temporary modal state

Owned locally.

---

# Current Persistence Limitation

The current FORGE persistence system stores savegame-global state.

True per-player persistent ForgeOS state requires a stable player identity and a
defined multiplayer persistence policy.

M2 should:

- use a per-player-shaped data structure
- use one temporary local-player identity
- isolate player resolution
- avoid claiming full multiplayer persistence
- preserve future compatibility

---

# State Mutation Ownership

Only the component owning a state value may mutate it.

Examples:

```text
Lifecycle Service
    mutates app lifecycle state

Navigation Service
    mutates navigation state

Notification Service
    mutates notification records

ForgeOS Core
    coordinates cross-service operations

Device Host
    requests visibility changes
```

Device hosts and apps must not edit State Store tables directly.

---

# Atomic State Changes

Multi-step state changes should be atomic where possible.

Example app activation:

```text
validate app
validate device
resolve presentation
validate lifecycle transition
background current app
activate requested app
update resume state
publish event
```

If the operation fails before completion, ForgeOS should preserve the previous
valid state.

---

# State Events

Completed state changes should publish events.

Examples:

```text
device visibility changed
active app changed
app lifecycle changed
navigation changed
notification created
notification read
notification dismissed
```

Events announce completed changes.

Events must not replace synchronous validation or API return values.

---

# State Initialisation

ForgeOS startup should:

1. register `forge.os`
2. apply default state
3. register namespace for persistence
4. rebuild app and device definitions
5. allow FORGE persistence loading
6. validate restored ForgeOS state
7. repair or discard invalid references
8. enter runtime state

The exact integration point with the Engine lifecycle must be defined before
implementation.

---

# Default State

A new ForgeOS state may begin as:

```lua
{
    version = 1,

    players = {
        ["player.local"] = {
            activeDeviceId = nil,
            devices = {},
            notifications = {},
            preferences = {}
        }
    }
}
```

Device state may be created lazily when a registered device is first used.

---

# Restored State Validation

After persistence loading, ForgeOS must validate:

- state version
- player tables
- device IDs
- app IDs
- presentation IDs
- route IDs
- route parameters
- notification records
- preference value types

Unknown or invalid data must not crash ForgeOS.

---

# Removed Addon Handling

A save may reference an app from an addon that is no longer installed.

Example:

```text
lastAppId = example.logistics
```

If `example.logistics` is not registered:

- preserve unrelated ForgeOS state
- discard or ignore the invalid resume reference
- fall back to device home
- log a development diagnostic where appropriate
- do not treat the full save as corrupted

---

# Updated Addon Handling

An app update may remove a route.

Example:

```text
saved route = legacyDashboard
```

If the route no longer exists:

```text
use app default route
```

If no valid default route exists:

```text
use device home
```

---

# State Cleanup

On mission shutdown:

- runtime registry state is cleared
- transient ForgeOS state is cleared
- device hosts release resources
- lifecycle records are cleared
- navigation runtime state is cleared
- persistent State Store state is cleared by the Engine after saving

ForgeOS must not install an independent XML save process.

---

# Proposed State Service Boundaries

Recommended ownership:

```text
ForgeOSStateService
    player/device state access
    default state
    state version
    resume records
    preferences

AppLifecycleService
    app lifecycle values

NavigationService
    routes and route parameters

NotificationService
    notifications

DeviceHost
    visibility and transient presentation state
```

Device visibility may be coordinated through ForgeOS Core while remaining
player-local runtime state.

---

# State Access API

Apps and hosts should use controlled APIs.

Conceptual examples:

```lua
FORGE.ForgeOS:getDeviceState(
    playerId,
    deviceId
)

FORGE.ForgeOS:getActiveApp(
    playerId,
    deviceId
)

FORGE.ForgeOS:getResumeState(
    playerId,
    deviceId
)
```

Public callers must receive detached or read-only data where appropriate.

Private State Store tables must not be exposed directly.

---

# State Model Rules

1. ForgeOS state is conceptually per player and per device.
2. M2 may use one isolated local-player identity.
3. Device visibility is separate from app lifecycle.
4. Hiding a device does not erase resume state.
5. Each device remembers its own last app and route.
6. Registration definitions are rebuilt, not persisted.
7. Domain gameplay state does not belong in `forge.os`.
8. Route parameters use stable plain-data identifiers.
9. Full navigation history is not persisted during M2.
10. Invalid saved app references fall back safely.
11. Missing addons must not corrupt ForgeOS startup.
12. State mutation occurs only through owning services.
13. Completed changes publish events.
14. Cross-service mutations should be atomic.
15. ForgeOS uses the existing State Store and Save Manager.

---

# Open Implementation Decisions

The following remain to be resolved during implementation:

- stable multiplayer player identity source
- player-local versus server-owned preference storage
- exact device visibility API
- whether active device is persisted
- app state repair logging level
- ForgeOS state migration process
- route-level availability policies
- maximum retained savegame notifications
- notification expiry
- preference schema registration
- per-app session state interface

These decisions should not require changing the core state shape.

---

# Success Criteria

The state model is ready for implementation when:

1. Phone and laptop can retain separate resume states.
2. A device reopens to its last valid app and route.
3. Missing apps fall back to device home.
4. Removed routes fall back to app defaults.
5. Player scope is isolated behind an identity resolver.
6. Registration state is not persisted.
7. Domain state remains outside `forge.os`.
8. Route parameters are safe to persist.
9. ForgeOS state can be validated after loading.
10. The model remains compatible with future per-player persistence.