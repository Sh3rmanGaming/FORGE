# FORGE ForgeOS Application Contract

**Version:** 0.1  
**Status:** Approved
**Milestone:** M2 – ForgeOS

---

## M2.010 Phone Host Presentation Boundary

The production Phone Host presents only detached declarative application data:
application identity/display name, resolved presentation identity, and current
route identity. It does not execute application or route controllers and gains
no direct access to registry, lifecycle, navigation, notification, State Store,
or persistence internals.

Phone visibility does not change application lifecycle. Hiding the Phone leaves
the current lifecycle and navigation state intact. When runtime state is absent,
the Host may request one validated persisted resume destination internally and
orchestrate the existing `openApp()`, `activateApp()`, and `navigate()` public
operations. Each operation retains its own frozen atomicity contract.

M2.011 applies the same boundary independently to Laptop. Phone and Laptop may
be visible simultaneously and retain separate active app, route, history, and
resume state. No global active-device or focus owner is introduced.

## M3.001 Communications Presentation Proposal

M3.001 proposes a bounded ForgeOS-owned presentation adapter for the built-in
`forge.communications` application. It returns detached versioned models and
accepts declared controlled actions; it does not expose or directly render
application controllers. The exact additive Host-facing methods, result
mapping, navigation mediation, and provider protocol remain under review in
[Communications Application Contract](../communications/CommunicationsAppContract.md).

Existing controller and action examples later in this document describe the
broader conceptual application model. They are not evidence that arbitrary
controller execution was implemented or frozen by M2.

---

# Purpose

This document defines the contract used by applications that register with
ForgeOS.

The application contract establishes how first-party and third-party addon mods
declare:

- application identity
- application metadata
- device support
- device-specific presentations
- capability-based presentation fallbacks
- routes
- exposed actions
- lifecycle callbacks
- controller bindings
- compatibility requirements

ForgeOS applications must register through the public ForgeOS API.

Applications must not modify ForgeOS registries, lifecycle state, navigation
state, or device state directly.

Device terminology follows the canonical definitions in
`ForgeOSArchitecture.md`.

---

# Core Principle

A ForgeOS application has one stable identity but may provide multiple
device-specific presentations.

Example:

```text
forge.projects
├── Shared application controller
├── Phone presentation
├── Laptop presentation
└── Capability-based fallback presentation
```

The phone and laptop presentations are not separate applications.

They share:

- application identity
- domain integration
- notification identity
- availability policy
- persisted application settings
- public API compatibility

They may differ in:

- layout
- routes
- available actions
- controls
- navigation style
- information density
- presentation controller

---

# Application Architecture

```text
Domain Manager
      │
      ▼
Shared App Controller
      │
      ▼
ForgeOS App Definition
      │
      ├── Phone Presentation
      ├── Laptop Presentation
      └── Capability Presentation
             │
             ▼
  Device Host Implementation
```

The domain manager owns gameplay rules.

The app controller translates user-facing requests into domain operations.

The presentation declares what the user may see and request through a
particular device.

ForgeOS Core coordinates registration, presentation selection, lifecycle,
navigation, and availability through the owning registries and services.

---

# Public Registration

Applications register through a public ForgeOS function.

Conceptual API:

```lua
FORGE.ForgeOS:registerApp(appDefinition)
```

The final function signature will be frozen during implementation.

Applications must not write directly into:

- App Registry private state
- Device Registry private state
- Lifecycle Service private state
- Navigation Service private state
- ForgeOS State Store tables

---

# Application Definition

A complete application definition may contain:

```lua
{
    id = "forge.projects",
    apiVersion = 1,

    displayName = "Projects",
    iconId = "forge.icon.projects",

    controller = FORGEProjects.Controller,

    supportedDevices = {
        phone = true,
        laptop = true
    },

    allowCapabilityFallback = false,

    requiredCapabilities = {
        notifications = true
    },

    defaultPresentation = "compact",

    presentations = {
        phone = {},
        laptop = {},
        compact = {}
    },

    availabilityProviders = {},

    metadata = {}
}
```

`allowCapabilityFallback = false` is shown explicitly: undeclared device types
are unsupported unless the app deliberately opts into capability or default
presentation fallback.

The exact runtime representation may use a validated internal copy.

---

# Required Application Fields

Every application must define:

```text
id
apiVersion
displayName
supportedDevices
presentations
```

## `id`

Globally unique authoritative application identifier.

Example:

```text
forge.projects
```

Rules:

- must be a non-empty string
- must not contain whitespace
- must remain stable
- must not be derived from translated display text
- must not duplicate another registered application

Recommended format:

```text
<owner>.<application>
```

Examples:

```text
forge.projects
forge.bank
example.logistics
sheridan.contractBoard
```

---

## `apiVersion`

The ForgeOS application contract version expected by the app.

Initial value:

```lua
apiVersion = 1
```

ForgeOS must reject applications requiring an unsupported app API version.

The app API version is separate from:

- FORGE release version
- FORGE public addon API version
- persistence schema version

---

## `displayName`

Default human-readable application name.

Example:

```lua
displayName = "Projects"
```

The final implementation may later support localisation keys.

The display name is presentation metadata and is not an authoritative
identifier.

---

## `supportedDevices`

Declares explicit device support.

Example:

```lua
supportedDevices = {
    phone = true,
    laptop = true
}
```

A supported device declaration does not guarantee availability.

The app must also satisfy:

- device registration
- required capabilities
- enabled state
- external availability policies
- valid presentation resolution

Exact device declarations are authoritative when supplied.
`supportedDevices[deviceId] = true` permits the device type.
`supportedDevices[deviceId] = false` is an absolute block; capability matching
and default presentation fallback MUST NOT override it.

An app MAY support undeclared future device types through capability-based or
default presentations only when it explicitly sets:

```lua
allowCapabilityFallback = true
```

Without `allowCapabilityFallback = true`, an undeclared device type is
unsupported even when its capabilities match a presentation.

---

## `presentations`

Contains one or more application presentation definitions.

Example:

```lua
presentations = {
    phone = phonePresentation,
    laptop = laptopPresentation
}
```

An application is invalid if no usable presentation can be resolved for any
declared supported device.

---

# Optional Application Fields

An application may define:

```text
iconId
controller
requiredCapabilities
allowCapabilityFallback
defaultPresentation
availabilityProviders
metadata
callbacks
```

Unknown fields should not automatically become part of the public contract.

ForgeOS may ignore unknown fields when creating its validated internal copy.

`allowCapabilityFallback` is optional and defaults to `false`.

---

# Shared Application Controller

The shared controller exposes application operations independently of device
presentation.

Example:

```lua
FORGEProjects.Controller = {}

function FORGEProjects.Controller:getActiveProjects(context)
end

function FORGEProjects.Controller:getProject(context, projectId)
end

function FORGEProjects.Controller:acceptProject(context, projectId)
end

function FORGEProjects.Controller:updateSchedule(
    context,
    projectId,
    schedule
)
end
```

The controller:

- may communicate with domain managers
- may prepare presentation-ready data
- may validate app-level input
- must not bypass domain validation
- must not render UI
- must not directly mutate ForgeOS lifecycle or navigation state

---

# Presentation Definition

A presentation describes how an app is exposed through a device or compatible
device profile.

Example:

```lua
{
    id = "projects.phone",
    defaultRoute = "overview",

    requiredCapabilities = {
        fullScreenApps = true,
        touchInput = true
    },

    routes = {},
    actions = {},

    controller = FORGEProjects.PhonePresentation
}
```

A presentation may define:

```text
id
defaultRoute
requiredCapabilities
routes
actions
controller
metadata
priority
```

App-level `requiredCapabilities` are universal minimum requirements for every
use and presentation of the app. Presentation-level `requiredCapabilities` are
additional requirements for that presentation. Both sets MUST pass; a
presentation MUST NOT weaken or override app-level requirements.

---

# Presentation Selection

ForgeOS resolves presentations in this order:

```text
1. Evaluate any exact supportedDevices declaration
2. Reject an explicit false declaration
3. Resolve an exact device presentation where available
4. Resolve a compatible capability presentation when fallback is permitted
5. Resolve the declared default presentation when support and fallback rules permit it
6. Otherwise mark the application unavailable
```

Example:

```text
phone
    ↓
presentations.phone
```

If no exact device presentation exists:

```text
device capabilities
    ↓
compatible presentation profile
```

If no compatible presentation exists:

```text
defaultPresentation
```

The default presentation MAY be selected only when the device type is
explicitly supported or when the device type is undeclared and
`allowCapabilityFallback = true`. It MUST NOT be selected for an explicitly
unsupported device type.

If no valid presentation can be resolved, the app is unavailable on that
device.

---

# Exact Device Presentations

An exact device presentation uses the device identifier as its registration key.

Example:

```lua
presentations = {
    phone = {
        defaultRoute = "overview"
    },

    laptop = {
        defaultRoute = "dashboard"
    }
}
```

Exact device presentations have priority over capability-based fallbacks.

---

# Capability-Based Presentations

An app may provide reusable presentation profiles selected through required
capabilities.

Example:

```lua
presentations = {
    compact = {
        requiredCapabilities = {
            fullScreenApps = true,
            touchInput = true
        }
    },

    desktop = {
        requiredCapabilities = {
            pointerInput = true,
            keyboardInput = true
        }
    }
}
```

This allows future devices to reuse existing presentations when the app sets
`allowCapabilityFallback = true`.

Examples:

- tablet may use `compact`
- office terminal may use `desktop`
- vehicle display may use a restricted compact profile

---

# Presentation Priority

Where multiple compatible capability presentations exist, ForgeOS should use an
explicit numeric priority.

Example:

```lua
priority = 100
```

Higher priority presentations are preferred.

Where priorities are equal, ForgeOS must use deterministic ordering.

Registration order should not silently determine selection.

---

# Routes

Routes represent logical destinations inside an application presentation.

Example:

```lua
routes = {
    overview = {
        controller = "showOverview"
    },

    projectDetails = {
        controller = "showProjectDetails"
    }
}
```

Route identifiers are local to the application.

A complete route identity is:

```text
appId + routeId
```

Example:

```text
forge.projects / projectDetails
```

---

# Route Rules

Route identifiers must:

- be non-empty strings
- contain no whitespace
- be unique within the presentation
- remain stable where persisted or externally referenced
- not contain translated display text

Each presentation must declare a valid default route.

---

# Device-Specific Routes

Different presentations may expose different routes.

Phone example:

```text
overview
projectDetails
messages
```

Laptop example:

```text
dashboard
projectDetails
schedule
budget
resources
analytics
```

A saved route from one device must not be assumed valid on another device.

Resume state is scoped per player and per device.

---

# Route Parameters

Route parameters must contain plain persistable data only.

Supported values:

- strings
- finite numbers
- booleans
- tables with string keys
- nested supported values

Unsupported values:

- functions
- userdata
- threads
- cyclic tables
- runtime objects
- UI references
- callback functions

Route parameters must be validated before being stored as resume state.

During M2.008, Navigation Service validates and detaches this plain-data shape
but does not execute route-specific availability providers or controllers.
Routes remain presentation-scoped declarations registered with their app.
Navigation of a route from another resolved presentation is rejected even when
the route identifier text matches.

---

# Actions

Actions represent user-requestable application operations.

Example:

```lua
actions = {
    viewProject = {
        handler = "viewProject"
    },

    acceptProject = {
        handler = "acceptProject"
    }
}
```

An action declaration may contain:

```text
handler
requiredCapabilities
enabled
metadata
```

---

# Device-Specific Action Exposure

Presentations decide which shared controller actions are exposed through a
device.

Phone example:

```lua
actions = {
    viewProject = true,
    acceptProject = true,
    sendMessage = true
}
```

Laptop example:

```lua
actions = {
    viewProject = true,
    acceptProject = true,
    sendMessage = true,
    editSchedule = true,
    manageBudget = true,
    assignResources = true,
    exportReport = true
}
```

The underlying shared controller may implement all operations.

The presentation decides which operations are accessible through that device.

---

# Action Authority

ForgeOS action exposure does not grant gameplay authority.

Example:

```text
Laptop presentation exposes manageBudget
        ↓
App controller submits budget request
        ↓
Project Manager validates request
        ↓
Authoritative state changes or request is rejected
```

The domain manager remains authoritative.

ForgeOS only controls whether an action is available through a presentation.

---

# Action Availability

ForgeOS should support an availability query such as:

```lua
FORGE.ForgeOS:isAppActionAvailable(
    playerId,
    deviceId,
    appId,
    actionId
)
```

The final API remains provisional.

Action availability may depend on:

- presentation exposure
- device capabilities
- app lifecycle state
- app enabled state
- external policy
- domain controller response

---

# Availability Providers

Applications may register controlled availability providers.

Example purposes:

- campaign unlock requirements
- company membership requirements
- player permission requirements
- gameplay progression requirements

Conceptual provider:

```lua
function provider:isAvailable(context)
    return true
end
```

or:

```lua
return false,
    FORGE.Definitions.AppAvailabilityReason.POLICY_REJECTED,
    "companyAccessRequired"
```

Availability providers must not directly mutate ForgeOS state.

---

# Application Lifecycle Callbacks

Applications may receive lifecycle callbacks.

Potential callbacks:

```text
onRegister
onOpen
onActivate
onBackground
onClose
```

Enabled-policy changes are not lifecycle transitions. Callback timing and
rollback outside the M2.007 boundary remain provisional.

For M2.007, Lifecycle Service invokes `onOpen`, `onActivate`, `onBackground`,
and `onClose` after validation and staging but before authoritative lifecycle
commit. `onRegister` is not a Lifecycle Service callback.

The App Registry retains callbacks as private runtime-owned assets and exposes
only the internal read-only accessor
`getLifecycleCallback(appId, callbackName)`. The accessor is usable after
registration freeze, permits only the four M2.007 lifecycle callback names,
and never exposes controllers, providers, action handlers, definitions, or
mutable executable-reference storage. Executable references remain excluded
from public snapshots, serialization, and persistence.

All required callbacks must succeed before ForgeOS commits lifecycle state and
publishes lifecycle events. A callback failure produces `CALLBACK_FAILED`, no
ForgeOS lifecycle-state mutation, and no lifecycle completion event. ForgeOS
does not attempt to reverse arbitrary application-owned side effects from a
callback that already executed.

---

# Callback Rules

Callbacks:

- receive a controlled application context
- execute after or around validated lifecycle transitions as documented
- must not mutate private ForgeOS state
- must not register new apps after registration closes
- must not assume a specific device host implementation
- must fail safely
- must not prevent ForgeOS cleanup

A callback failure should return a defined result and produce diagnostic output.

---

# Application Context

Applications should receive a controlled context object.

Potential context capabilities:

```text
query player identity
query active device
query app lifecycle state
navigate
go back
open modal
create notification
request app close
publish application event
access owned State Store namespace
access domain controller
```

The broader context above remains provisional. The M2.007 lifecycle callback
context is deliberately limited to a detached table containing `playerId`,
`deviceId`, `appId`, `previousState`, and `requestedState`.

The context must not expose:

- private registry tables
- private lifecycle tables
- raw ForgeOS persistence tables
- unrelated addon namespaces
- XML Reader
- XML Writer

---

# App-Owned State

Application domain state should normally belong to the application's own State
Store namespace.

Examples:

```text
forge.projects
forge.bank
example.logistics
```

Application state must not be stored inside `forge.os` unless it is genuinely
operating-system state.

`forge.os` may store references such as:

```text
last active app
last route
notification read state
device preferences
```

It must not store:

```text
project definitions
bank balances
company records
message contents owned by Communications
```

---

# Presentation State

Presentation state must be classified.

## Persisted resume state

May include:

- last route
- safe route parameters
- selected tab
- selected app-local section

## Session-only state

May include:

- temporary search terms
- expanded panel state
- current unsaved filters

## Transient state

Includes:

- hover state
- animation progress
- pointer position
- UI element references
- open callback references
- render targets

Runtime rendering objects and ephemeral presentation state MUST NOT be
persisted. Stable plain-data presentation preferences or resume state MAY be
persisted only when included in the ForgeOS state contract.

Persisted resume state MAY include the last valid app, presentation, route, safe
route parameters, and approved preferences. Runtime lifecycle state MUST be
reconstructed and validated during restore; ForgeOS MUST NOT restore active
runtime objects or replay stale lifecycle state.

---

# Device Visibility

Device visibility is separate from app lifecycle.

Example:

```text
Phone visible
Phone hidden
```

Hiding a device does not automatically close its active app.

When the device reopens, ForgeOS should restore:

```text
last valid app
last valid route
safe route parameters
```

---

# Resume Validation

When restoring a device, ForgeOS must validate:

1. the saved app is still registered
2. the app is still available
3. the device is still supported
4. a valid presentation can be resolved
5. the saved route still exists
6. route parameters are valid

Fallback order:

```text
saved app and route
→ saved app default route
→ device home
```

Removed or unavailable addon apps must not prevent the device from opening.

---

# Addon Registration Lifecycle

ForgeOS has one registration lifecycle. External addon mods may register
application definitions through the App Registry only during
`REGISTRATION_OPEN`. During the same phase, the Device Registry accepts device
definitions/profiles and the Device Host Registry accepts device host
implementations. Runtime device host instances do not participate in
registration.

Authoritative phases:

```text
UNAVAILABLE
INITIALISING
REGISTRATION_OPEN
VALIDATING
REGISTRATION_FROZEN
RUNTIME_ACTIVE
SHUTTING_DOWN
STOPPED
```

Public content registration MUST NOT occur during `INITIALISING`; internal
service creation and persistence setup are not public registration. Entering
`VALIDATING` closes registration and validation MUST operate on all three stable
registration sets. `REGISTRATION_FROZEN` means validation succeeded, all three
sets are immutable, restored references MAY be validated and repaired, and
normal runtime operations remain unavailable. `RUNTIME_ACTIVE` is the first
normal runtime phase and registration remains closed.

Permitted and forbidden operations for every phase are defined in
`ForgeOSDefinitions.md`. Late registrations MUST be rejected cleanly.

## M2.003B Coordination Boundary

M2.003B implements only the coordinator that orchestrates the Device Registry,
Device Host Registry, and App Registry participant roles.

Concrete application registration, definition storage, duplicate detection,
identifier validation, lookup, and App Registry invariants remain deferred to
the dedicated App Registry milestone.

The public operation `FORGE.ForgeOS:completeStartup()` completes validation,
freeze, and transition to `RUNTIME_ACTIVE` only after all three internal
Registration Participants are installed. The coordinator does not accept
application definitions.

Future App Registry registration operations MUST consult the shared
registration gate and return `REGISTRATION_CLOSED` without mutation when
registration is not open.

## M2.005 App Registry Boundary

M2.005 implements the concrete App Registry as the authoritative owner of
registered application definitions. ForgeOS exposes:

```lua
FORGE.ForgeOS:registerApp(appDefinition)
FORGE.ForgeOS:isAppRegistered(appId)
FORGE.ForgeOS:getAppDefinition(appId)
FORGE.ForgeOS:getRegisteredAppIds()
```

Registration is atomic, phase-gated, API-compatible, lifecycle-local, and
duplicate-safe. Public queries return detached definition data and lexical
identifier lists. Successful commit publishes `APP_REGISTERED` with only the
registered `appId`.

Executable references are runtime-owned implementation assets. Controllers,
callbacks, providers, route controllers, and action handlers are excluded from
serialization and public snapshots and are not invoked by M2.005.

The App Registry validates structural consistency only. It records `ownerId`
without resolving ownership and does not select a presentation, calculate
availability, execute lifecycle callbacks, navigate, or bind a device host.

The production participant installs after the Device Registry and before
`REGISTRATION_OPENED`. Production remains at `REGISTRATION_OPEN` until the
concrete Device Host Registry exists.

## M2.006 Presentation Resolution Boundary

`FORGE.ForgeOS:resolvePresentation(appId, deviceId)` is a read-only
`RUNTIME_ACTIVE` query returning `result, resolution`. It reads detached
registry definitions, publishes no event, and accesses or executes no private
application asset.

Resolution applies exact support, universal app capabilities, the exact
presentation, eligible capability presentations, then the declared default.
Explicit device `false` is absolute and undeclared fallback requires
`allowCapabilityFallback = true`.

Capability candidates exclude the exact and default keys and declare at least
one presentation capability. Candidates use descending finite numeric
priority, omitted priority zero, and lexical presentation key for ties.

Universal missing capabilities are selected lexically and returned
immediately. Candidate failures are selected lexically within deterministic
candidate order; the first is retained while later candidates remain eligible
to resolve.

M2.006 performs no availability-provider, callback, route, action, lifecycle,
navigation, host, rendering, ownership, or persistence behaviour.

---

# Addon Compatibility

An external addon must verify:

```text
FORGE exists
ForgeOS exists
required public API version is supported
required app API version is supported
registration is open
dependencies are available
```

Conceptual check:

```lua
if FORGE == nil
    or FORGE.ForgeOS == nil
    or FORGE.ForgeOS.APP_API_VERSION ~= 1 then
    return
end
```

A formal compatibility API should replace direct equality checks before public
release.

---

# Duplicate Registration

ForgeOS must reject duplicate application identifiers.

It must not:

- silently replace the existing app
- merge definitions automatically
- accept registration based on load order

Duplicate registration should return:

```text
false
ALREADY_REGISTERED
```

and log the conflicting identifier.

---

# Registration Ownership

An addon should have an authoritative addon identity.

Applications registered by that addon should record their owner.

Example:

```lua
ownerId = "forge.projects"
```

or:

```lua
ownerId = "example.logistics"
```

Ownership may later be used to enforce:

- namespace access
- asset ownership
- lifecycle cleanup
- dependency tracking
- addon diagnostics

---

# Registration Validation

ForgeOS must validate the complete app definition before committing it to the
App Registry.

Validation includes:

- required fields
- valid app ID
- supported API version
- unique app ID
- valid device declarations
- valid presentations
- valid routes
- valid default routes
- valid actions
- valid capability identifiers
- valid callback types
- valid owner identity

Registration must be atomic.

An invalid app must not leave a partial registry entry.

---

# Registration Result

`registerApp()` is an operation and returns one `ForgeOSResult`:

```lua
local result =
    FORGE.ForgeOS:registerApp(appDefinition)
```

Success:

```lua
FORGE.Definitions.ForgeOSResult.SUCCESS
```

Example failure:

```lua
FORGE.Definitions.ForgeOSResult.INVALID_DEFINITION
```

Registration diagnostics are reported through the existing Logger path rather
than additional public return values.

---

# App Unregistration

Application unregistration is deferred for the initial M2 implementation.

Removing a live app introduces complexity involving:

- active lifecycle state
- navigation state
- persisted resume state
- notifications
- device hosts
- addon dependencies

Initial rule:

> Applications remain registered for the duration of the mission runtime.

Controlled unregistration may be introduced later.

---

# Built-In and External Apps

ForgeOS must use the same registration contract for:

- built-in FORGE apps
- first-party addon apps
- third-party addon apps

Built-in applications must not bypass validation.

This ensures the public contract is proven by FORGE itself.

---

# Example Complete App Definition

```lua
local appDefinition = {
    id = "forge.projects",
    ownerId = "forge.projects",
    apiVersion = 1,

    displayName = "Projects",
    iconId = "forge.icon.projects",

    controller = FORGEProjects.Controller,

    supportedDevices = {
        phone = true,
        laptop = true
    },

    allowCapabilityFallback = false,

    requiredCapabilities = {
        notifications = true
    },

    defaultPresentation = "compact",

    presentations = {
        phone = {
            id = "projects.phone",
            defaultRoute = "overview",

            requiredCapabilities = {
                fullScreenApps = true,
                touchInput = true
            },

            routes = {
                overview = {},
                projectDetails = {},
                messages = {}
            },

            actions = {
                viewProject = true,
                acceptProject = true,
                sendMessage = true
            },

            controller =
                FORGEProjects.PhonePresentation
        },

        laptop = {
            id = "projects.laptop",
            defaultRoute = "dashboard",

            requiredCapabilities = {
                pointerInput = true,
                keyboardInput = true
            },

            routes = {
                dashboard = {},
                projectDetails = {},
                schedule = {},
                budget = {},
                resources = {},
                analytics = {}
            },

            actions = {
                viewProject = true,
                acceptProject = true,
                sendMessage = true,
                editSchedule = true,
                manageBudget = true,
                assignResources = true,
                exportReport = true
            },

            controller =
                FORGEProjects.LaptopPresentation
        },

        compact = {
            id = "projects.compact",
            priority = 10,
            defaultRoute = "overview",

            requiredCapabilities = {
                fullScreenApps = true
            },

            routes = {
                overview = {},
                projectDetails = {}
            },

            actions = {
                viewProject = true
            }
        }
    },

    availabilityProviders = {},

    metadata = {}
}
```

Here `allowCapabilityFallback = false` intentionally restricts support to
explicitly permitted device types; capability and default presentations cannot
make an undeclared device type available.

---

# Public Contract Rules

1. One application has one stable app ID.
2. An app may provide multiple presentations.
3. Exact device presentations take priority.
4. Capability presentations provide reusable fallbacks only under the
   `allowCapabilityFallback` contract.
5. Presentations declare routes and exposed actions.
6. Shared controllers own app-level operations.
7. Domain managers remain authoritative over gameplay.
8. ForgeOS Core coordinates lifecycle, navigation, and presentation resolution
   through their owning services.
9. App definitions are validated and copied atomically.
10. External apps use the same contract as built-in apps.
11. Registration is allowed only during the formal registration window.
12. Device visibility does not automatically close the app.
13. Resume state is conceptually scoped per player and per device. M2 MAY use
    the isolated `player.local` resolver, while current persistence remains
    savegame-global and does not provide true per-player multiplayer
    persistence.
14. Invalid saved app state must fall back safely.
15. Apps must not access private ForgeOS implementation state.
16. Enabled policy and calculated availability constrain lifecycle transitions
    but are not lifecycle states.
17. ForgeOS MUST NOT report a multi-service operation as successful while
    exposing partially committed lifecycle, navigation, resume, notification,
    or visibility state.
18. Engine/platform Host orchestration methods are not addon-facing application
    APIs. External applications acquire the façade through the cross-mod bridge
    and use only the documented registration, query, lifecycle, navigation,
    notification, and visibility operations.
19. `notification.source` identifies the origin of a notification; it does not
    establish application ownership, inbox routing, or an unread app-badge
    contract.
20. The M2 freeze permits future backward-compatible additive API evolution
    following compatibility, documentation, and test review.

---

# Open Decisions

The canonical cross-component open decisions are recorded in
`ForgeOSComponentDesign.md`. The following app-contract-specific details also
remain unresolved:

- exact application context API
- localisation metadata format
- asset registration format
- presentation priority limits
- action result format
- formal addon dependency declarations
- controlled app unregistration

These decisions must not invalidate the core app contract.

---

# Success Criteria

This contract is ready for implementation when:

1. Apps can register from separate addon mods.
2. App IDs are globally unique.
3. One app can support multiple device presentations.
4. Laptop presentations can expose richer functions than phone presentations.
5. `allowCapabilityFallback` supports future device types without overriding
   explicit device blocks.
6. Routes and actions are validated.
7. Domain rules remain outside ForgeOS.
8. Registration is atomic.
9. Resume state can safely reference app and route identifiers.
10. The contract can be versioned independently of persistence.

---

# Related Documentation

- [M2 Architecture Review](../reviews/M2ArchitectureReview.md) records accepted
  application-contract decisions and unresolved contract questions.
- [Engineering Process](../style/EngineeringProcess.md) defines review,
  approval, implementation, and verification governance.
- [Git Workflow](../style/GitWorkflow.md) governs promotion, tagging, and
  release handling for public API and compatibility changes.
