# FORGE ForgeOS Architecture

**Version:** 0.1  
**Status:** Review
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

ForgeOS MUST never hardcode phone or laptop behaviour.

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
applications. Notification authority boundaries remain an open decision.

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
    notification authority boundaries remain unresolved.
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
