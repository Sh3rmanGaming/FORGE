# FORGE ForgeOS Architecture

**Version:** 0.1  
**Status:** Draft  
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
               Device Hosts
          ┌──────────┴──────────┐
          ▼                     ▼
      Phone Host           Laptop Host
          │                     │
          └──────────┬──────────┘
                     ▼
             Registered Applications
```

ForgeOS owns application behaviour.

Device hosts own presentation.

Gameplay managers own gameplay.

---

# Architectural Layers

ForgeOS is divided into four logical layers.

## ForgeOS Core

The ForgeOS Core owns:

- device registration
- application registration
- lifecycle management
- navigation state
- notifications
- application availability
- operating system persistence

The ForgeOS Core must never render a user interface.

---

## Device Hosts

Device hosts provide visual presentation and user interaction.

Initial device hosts include:

- Phone
- Laptop

Future hosts may include:

- Vehicle displays
- Control terminals
- Dedicated consoles
- Tablet interfaces

Device hosts own:

- rendering
- controls
- animations
- layouts
- input translation

Device hosts never own application registration.

---

## Applications

Applications provide user-facing access to gameplay systems.

Examples include:

- Projects
- Banking
- Companies
- Communications
- Settings

Applications own:

- metadata
- presentation controllers
- routes
- UI state

Applications never own gameplay rules.

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

Every ForgeOS host is represented by a registered device.

Initial device identifiers:

```text
phone
laptop
```

Each device may expose capabilities such as:

- touch input
- mouse input
- keyboard input
- notifications
- background applications
- fullscreen applications
- windowed applications
- multitasking

ForgeOS must never hardcode phone or laptop behaviour.

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

# Device Profiles

A device profile describes what a host supports.

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

The ForgeOS Core queries device capabilities rather than making assumptions.

---

# Application Lifecycle

Applications transition through lifecycle states.

Initial lifecycle states:

```text
REGISTERED
AVAILABLE
OPEN
ACTIVE
BACKGROUND
CLOSED
DISABLED
```

State transitions are controlled exclusively by ForgeOS.

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

# Navigation

ForgeOS owns logical navigation.

Navigation includes:

- home
- application
- route
- modal
- history
- back stack

The ForgeOS Core defines navigation.

Device hosts decide how navigation is presented visually.

---

# Notifications

ForgeOS provides a shared notification system.

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

The notification system belongs to ForgeOS rather than individual applications.

---

# Persistence

ForgeOS persistent state uses the existing FORGE persistence framework.

Proposed namespace:

```text
forge.os
```

Persistent data may include:

- active device
- last active application
- user settings
- notification preferences
- accessibility options

Transient rendering state should not be persisted unless explicitly required.

ForgeOS must never access XML directly.

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

This boundary must remain clearly documented.

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

1. ForgeOS Core never renders UI.
2. Device hosts never own application registration.
3. Applications never own gameplay rules.
4. Gameplay managers never depend on presentation.
5. Device capabilities are data-driven.
6. Navigation belongs to ForgeOS.
7. Notifications belong to ForgeOS.
8. Persistence uses State Store and Save Manager.
9. Public application identifiers remain stable.
10. Campaign authors will interact through the Campaign SDK rather than private ForgeOS internals.

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
10. Support multiple device hosts without duplicating operating system logic.

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