# FORGE ForgeOS State Model

**Version:** 0.1  
**Status:** Approved
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

Device terminology follows the canonical definitions in
`ForgeOSArchitecture.md`.

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

ForgeOS subsystem state includes:

- device visibility
- active application per device
- app lifecycle state per device
- logical navigation state
- device resume state
- ForgeOS preferences
- notification records owned by ForgeOS
- app enabled-policy overrides

Each value MUST be mutated only by the registry or specialised service that
owns its state and invariants. Ownership that depends on the unresolved
`ForgeOSStateService` decision remains candidate rather than authoritative.

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

Runtime rendering objects and ephemeral presentation state MUST NOT be written
into ForgeOS persistence. Stable plain-data presentation preferences or resume
state MAY be persisted only when included in the ForgeOS state contract.

---

# State Store Namespace

ForgeOS persistent state MUST use the stable, authoritative namespace:

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

The target architecture is conceptually per player and per device.

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
state consumers. Current persistence is savegame-global and does not provide
true per-player multiplayer persistence.

---

# Device Scope

Resume and runtime state are represented separately for each device type as
player device state.

Example:

```text
player.local
├── phone
└── laptop
```

The phone and laptop may remember different apps and routes.

M2.011 implements this separation for the bounded PhoneHost and LaptopHost.
Visibility remains runtime-only and independent; `activeDeviceId` examples in
this document remain future model material and are not written by M2.011.

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

ForgeOS may track the currently selected device type for a player.

Example:

```text
activeDeviceId = phone
```

Whether this value is persistent remains an open decision.

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

Authoritative lifecycle states:

```text
CLOSED
OPEN
ACTIVE
BACKGROUND
```

Application state separates:

```text
App Registry
    registration

Validated policy or state input outside Lifecycle Service
    enabled or disabled

Availability Service
    availability calculated for a specific player and device type

Lifecycle Service
    CLOSED, OPEN, ACTIVE, BACKGROUND
```

Registration, enabled policy, and availability are not lifecycle states.
Enabled policy and calculated availability MUST constrain whether lifecycle
transitions may occur.

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

For M2.007, the Lifecycle Service resolves the player as `player.local`, treats
an absent app record as `CLOSED`, and stores only runtime lifecycle state. It
also owns the one-active-app mapping per device and bounded runtime enabled
overrides. None of these values is serialized or restored as active runtime
state.

All staged ForgeOS lifecycle-state and active-app changes commit atomically
only after required callbacks succeed. Callback failure leaves authoritative
ForgeOS state unchanged and publishes no lifecycle completion event. This
atomicity does not extend to arbitrary application-owned callback side effects.
Shutdown clears Lifecycle Service-owned runtime values without callbacks.

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
- be permitted by enabled policy

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

When a device is opened during `RUNTIME_ACTIVE`, ForgeOS should reconstruct
runtime state from validated resume data:

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

## M2.008 Navigation State Contract

Navigation Service owns runtime current route, parameters, and bounded history
per `player.local`, device, and app. History is ordered oldest to newest,
evicts its oldest entry deterministically when the private bound is exceeded,
and is never persisted.

After successful non-idempotent navigation, the service updates:

```text
players[player.local]
└── devices[deviceId]
    └── resume
        ├── appId
        ├── presentationId
        ├── routeId
        └── routeParameters
```

Failed and idempotent operations do not update resume state. Startup does not
automatically activate or navigate an app. Runtime history clears on shutdown;
the plain resume destination remains available to the existing persistence
pipeline.

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

Preferences affecting presentation only SHOULD be player-local. Preferences
affecting gameplay access, permissions, progression, company policy, or other
authoritative behaviour MUST remain server-authoritative or
domain-authoritative. Presentation preferences MUST NOT alter gameplay
authority. The exact persistence mechanism remains open.

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

# App Enabled Policy Input

ForgeOS MAY store validated app enabled-policy overrides. This input is owned
outside the Lifecycle Service and is not an application lifecycle state.

Conceptual structure:

```lua
appOverrides = {
    ["forge.projects"] = {
        enabled = true
    }
}
```

Enabled policy is not the same as availability.

Availability is calculated from:

- registration
- device support
- capabilities
- enabled policy
- policy providers

---

# Notifications

Notification state may be scoped per player.

Conceptual structure:

```lua
notifications = {
    ["notification.1"] = {
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

## M2.009 Notification State Contract

Notification Service uses the existing local-player structure:

```text
players[player.local]
    notifications
    notificationNextSequence
```

The M2.009 persisted compatibility shape is a map keyed by notification
identifier:

```lua
players["player.local"].notifications = {
    ["notification.1"] = {
        id = "notification.1",
        playerId = "player.local",
        source = "forge.projects",
        title = "New Project Available",
        body = "Western Ridge Expansion",
        severity = "info",
        persistence = "savegame",
        targetDevices = { phone = true },
        route = nil,
        metadata = nil,
        createdOrder = 1,
        read = false,
        dismissed = false
    }
}
players["player.local"].notificationNextSequence = 2
```

The map key MUST equal the record `id`. `createdOrder` is the positive integer
creation sequence used for deterministic oldest-to-newest ordering. `read` and
`dismissed` are explicit booleans. Persisted records MUST use `savegame`;
session and transient records are never valid in this subtree.

The next sequence is persisted independently of retained records. Every
successful transient, session, or savegame creation advances it; failed
creation does not. Therefore gaps in retained identifiers are valid and must
not be repaired away.

Transient notifications retain no state. Session records are owned in runtime
memory and clear on shutdown. Savegame records are controlled plain data in
`forge.os`; read and dismissed state persists with them. The service preserves
unrelated player, device, resume, and preference state whenever it commits or
repairs notification state.

Retained state is bounded. Oldest dismissed records are reclaimed first,
otherwise oldest read records. An unread undismissed record is never silently
evicted. The literal private capacity is not a persistence contract.

Restoration discards malformed, unsafe, and non-savegame records. If restored
records share an identifier or positive creation-order value, every member of
that conflict group is discarded. Survivors are ordered by creation order.
Repair respects a valid persisted next sequence and raises it above surviving
identifiers and orders where necessary. No notification event publishes during
repair, and failed repair exposes no partially repaired service state.

Older state with either notification field absent is valid. It is interpreted
as no retained notifications and next sequence `1`, then normalized without
disturbing unrelated `forge.os` state. Once M2.009 is accepted and frozen,
previously valid savegame notification records form an implementation
compatibility contract. A breaking representation change requires schema and
version review, migration or explicit compatibility handling, persistence
tests, runtime restoration evidence, and documentation review. General
long-term ForgeOS migration architecture remains deferred.

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

Device host implementation
    requests visibility changes
```

A device host implementation MAY request a visibility change through the public
ForgeOS API. It MUST NOT mutate authoritative visibility state directly. Device
hosts and apps MUST NOT edit State Store tables directly. M2.010 assigns
runtime visibility to `DeviceStateService`; `showDevice()`, `hideDevice()`, and
`getDeviceVisibility()` form its bounded public façade.

---

# Atomic State Changes

ForgeOS MUST NOT report a multi-service operation as successful while exposing
partially committed lifecycle, navigation, resume, notification, or visibility
state.

The exact staging, rollback, callback timing, and re-entrancy behaviour remain
open architectural decisions.

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

If the operation fails before completion, ForgeOS MUST preserve or restore a
valid externally visible state and MUST NOT report success for a partial
commit.

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

ForgeOS startup MUST respect the operating phases:

1. During `INITIALISING`, register `forge.os`, apply default state, establish
   persistence integration, and allow raw State Store data to be restored
   through existing Engine persistence infrastructure. References to apps,
   devices, presentations, and routes are not yet validated.
2. During `REGISTRATION_OPEN`, rebuild device definitions/profiles, device host
   implementation registrations, app definitions, and related registration
   data.
3. During `VALIDATING`, close registration and validate all three stable
   registration sets.
4. During `REGISTRATION_FROZEN`, validate, repair, or discard restored
   references against the immutable registration sets and reconstruct safe
   runtime lifecycle state.
5. During `RUNTIME_ACTIVE`, expose only validated, reconstructed runtime state.

ForgeOS MUST NOT blindly restore active runtime objects or replay stale
lifecycle state.

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

## M2.003A Mandatory Bootstrap State

### Contract

When `forge.os` contains no restored or previously initialised state, Bootstrap
MUST establish:

```lua
{
    version = FORGE.Definitions.ForgeOSVersion.STATE,

    players = {
        [FORGE.Definitions.ForgeOSPlayerId.LOCAL] = {
            activeDeviceId = nil,
            devices = {},
            notifications = {},
            preferences = {}
        }
    }
}
```

Bootstrap MUST use `ForgeOSNamespace.OS`, MUST NOT overwrite restored state
with defaults, and MUST NOT create device, application, presentation, route,
notification, or host runtime objects.

Restored references remain unvalidated during M2.003A and MUST NOT be exposed
through runtime operations.

### Partial-Startup Contract

Startup succeeds only after ForgeOS enters `INITIALISING`, establishes the
namespace and mandatory state where absent, registers persistence, enters
`REGISTRATION_OPEN`, and publishes `REGISTRATION_OPENED`.

If a required step before `REGISTRATION_OPEN` fails:

- startup returns the applicable failure result;
- `REGISTRATION_OPENED` is not published;
- Bootstrap requests `SHUTTING_DOWN`, performs safe cleanup, and requests
  `STOPPED`;
- partial state is not exposed as operational;
- unrelated Engine state, registrations, and listeners remain untouched;
- global clearing operations MUST NOT be used to simulate ForgeOS-only
  rollback; and
- ForgeOS allocations that cannot be safely removed through existing owning
  services remain reusable by a later startup attempt.

### Rationale

The mandatory shape makes the approved base state deterministic. The rollback
boundary preserves unrelated Engine state where existing services do not
provide single-namespace removal.

---

# Restored State Validation

Raw state restored during `INITIALISING` MUST be treated as unvalidated.
During `REGISTRATION_FROZEN`, ForgeOS MUST validate:

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

# Candidate State Service Boundaries

Candidate ownership, pending the `ForgeOSStateService` open decision:

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

Device host instance
    transient presentation state
```

Logical device visibility is owned authoritatively by the bounded
`DeviceStateService` during M2.010.

A device host implementation MAY request visibility changes through the public
ForgeOS API but MUST NOT mutate authoritative visibility state directly. The
approved visibility API is exposed through ForgeOS.

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
2. M2 MAY use the isolated `player.local` identity resolver.
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
14. Multi-service operations MUST NOT report success while exposing partially
    committed lifecycle, navigation, resume, notification, or visibility state.
15. ForgeOS uses the existing State Store and Save Manager.
16. Current persistence is savegame-global and does not provide true
    per-player multiplayer persistence.

---

# Open Decisions

The canonical cross-component open decisions are recorded in
`ForgeOSComponentDesign.md`. The following state-model-specific details also
remain unresolved:

- stable multiplayer player identity and persistence policy
- active-device persistence
- exact persistence mechanism for presentation preferences
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

---

# Related Documentation

- [M2 Architecture Review](../reviews/M2ArchitectureReview.md) records accepted
  state-model decisions, deferred assumptions, and remaining state gaps.
- [Engineering Process](../style/EngineeringProcess.md) defines review,
  approval, implementation, and verification governance.
