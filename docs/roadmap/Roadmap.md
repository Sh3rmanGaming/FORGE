# FORGE Roadmap

**Status:** Active  
**Last Updated:** 2026-08-03

---

## Overall Progress

| Milestone | Status |
|-----------|--------|
| M0 – Foundation | ✅ Complete |
| M1 – Engine | ✅ Complete |
| M2 – ForgeOS | 🟡 In Progress |
| M3 – Communications | ⬜ Planned |
| M4 – Projects | ⬜ Planned |
| M5 – Banking | ⬜ Planned |
| M6 – Companies | ⬜ Planned |
| M7 – Campaign SDK | ⬜ Planned |
| M8 – Public Release | ⬜ Planned |

---

## Current Milestone — M2: ForgeOS

# FORGE Development Roadmap

## Completed
---

## In Progress

### 🟡 M2 – ForgeOS

#### ⏳ M2.001 – Documentation

All current ForgeOS documents are authored and have status `Review` while
undergoing Architecture Review. They are not yet Approved, Implemented, or
Verified.

Review evidence and accepted decisions are recorded in the
[M2 Architecture Review](../reviews/M2ArchitectureReview.md).

| Document | Authored | Architecture Review | Approved | Implemented | Verified |
|----------|----------|---------------------|----------|-------------|----------|
| ForgeOS Architecture | ✅ Complete | 🟡 In Progress | ⬜ Not Started | ⬜ Not Started | ⬜ Not Started |
| ForgeOS Component Design | ✅ Complete | 🟡 In Progress | ⬜ Not Started | ⬜ Not Started | ⬜ Not Started |
| ForgeOS Definitions | ✅ Complete | 🟡 In Progress | ⬜ Not Started | ⬜ Not Started | ⬜ Not Started |
| ForgeOS App Contract | ✅ Complete | 🟡 In Progress | ⬜ Not Started | ⬜ Not Started | ⬜ Not Started |
| ForgeOS State Model | ✅ Complete | 🟡 In Progress | ⬜ Not Started | ⬜ Not Started | ⬜ Not Started |

---

#### ⏳ M2.002 – Definitions

- ForgeOS namespace definitions
- ForgeOS version definitions
- ForgeOS phase definitions
- Player identity definitions
- Device identifiers
- Device capabilities
- Device visibility definitions
- Application lifecycle definitions
- Application availability definitions
- Presentation match definitions
- Notification persistence definitions
- Notification severity definitions
- Navigation layer definitions
- ForgeOS event definitions
- ForgeOS result definitions
- ForgeOS log sources
- Definition validation
- Definition test suite

---

#### ⏳ M2.003 – ForgeOS Core

- Engine startup integration
- Engine shutdown integration
- Registration lifecycle
- Registration validation
- Registration freeze
- Core service coordination
- Public ForgeOS API
- ForgeOS state initialization
- Core test suite

---

#### ⏳ M2.004 – Device Registry

- Device registration
- Duplicate validation
- Device capability registration
- Device lookup
- Device availability queries
- Device validation
- Device registry test suite

---

#### ⏳ M2.005 – App Registry

- Application registration
- Owner registration
- API compatibility validation
- Duplicate validation
- Presentation validation
- Callback validation
- Registry lookup
- Registry test suite

---

#### ⏳ M2.006 – Presentation Resolver

- Exact device matching
- Capability matching
- Priority resolution
- Deterministic tie breaking
- Default presentation fallback
- Presentation validation
- Presentation resolution test suite

---

#### ⏳ M2.007 – Lifecycle Service

- Open application
- Close application
- Activate application
- Background application
- Enabled-policy integration
- Lifecycle validation
- Transition validation
- Lifecycle event publishing
- Lifecycle test suite

---

#### ⏳ M2.008 – Navigation Service

- Route registration
- Route validation
- Route navigation
- Resume state
- Route parameter validation
- Navigation history
- Navigation events
- Navigation test suite

---

#### ⏳ M2.009 – Notification Service

- Notification creation
- Notification dismissal
- Notification read state
- Notification persistence
- Notification targeting
- Notification events
- Notification test suite

---

#### ⏳ M2.010 – Phone Host

- Phone device registration
- Phone presentation host
- Phone lifecycle integration
- Phone navigation integration
- Phone notification integration
- Phone resume support
- Phone host test suite

---

#### ⏳ M2.011 – Laptop Host

- Laptop device registration
- Laptop presentation host
- Laptop lifecycle integration
- Laptop navigation integration
- Laptop notification integration
- Laptop resume support
- Laptop host test suite

---

#### ⏳ M2.012 – End-to-End Integration

- ForgeOS startup verification
- Device registration verification
- App registration verification
- Presentation resolution verification
- Lifecycle verification
- Navigation verification
- Resume state verification
- Persistence verification
- Notification verification
- Multiplayer compatibility verification

---

#### ⏳ M2.013 – ForgeOS Polish

- Remove temporary diagnostics
- Documentation review
- Public API review
- Definition review
- Code review
- Performance review
- Final architecture review
- Freeze ForgeOS API

---

## Planned

### ⏳ M1.008 – Campaign Manager
- Campaign lifecycle
- Save slot abstraction
- World metadata
- Campaign registry

### ⏳ M1.009 – Phone OS Foundation
- Operating system bootstrap
- Application lifecycle
- Window management
- UI framework integration

### ⏳ M1.010 – Engine Bootstrap
- Module discovery
- Module registration
- Dependency ordering
- Engine startup pipeline
- Engine shutdown pipeline

---

# Milestone Exit Criteria

M2 – ForgeOS is considered complete when all of the following are true:

## Architecture

- All ForgeOS design documentation has been reviewed and finalised.
- No unresolved architectural decisions remain.
- Public contracts are frozen.

## Definitions

- All authoritative ForgeOS definitions have been implemented.
- Definition validation passes.
- Definition test suite passes.

## Core

- ForgeOS initialises correctly with the FORGE Engine.
- Registration lifecycle functions correctly.
- Registration freeze is enforced.
- Shutdown performs complete cleanup.

## Device System

- Devices register correctly.
- Device capability resolution functions correctly.
- Device validation passes.

## Application System

- Applications register through the public ForgeOS API.
- Duplicate registrations are rejected.
- API compatibility is validated.
- Presentation definitions are validated.

## Presentation System

- Exact device presentation resolution functions.
- Capability fallback resolution functions.
- Default presentation fallback functions.
- Deterministic resolution is verified.

## Lifecycle

- Application lifecycle transitions behave correctly.
- Invalid transitions are rejected.
- Lifecycle events publish correctly.

## Navigation

- Route registration functions.
- Route validation functions.
- Resume state restores correctly.
- Navigation events publish correctly.

## Notifications

- Notifications can be created.
- Notifications can be dismissed.
- Read state persists correctly.
- Persistence policies function correctly.

## Device Hosts

- Phone host fully integrates with ForgeOS.
- Laptop host fully integrates with ForgeOS.
- Device-specific resume state functions correctly.

## Integration

- Complete ForgeOS startup verified.
- Complete ForgeOS shutdown verified.
- Persistence verified across save/load.
- Resume state verified after reload.
- Event flow verified.
- Multiplayer compatibility validated where applicable.

## Quality

- Temporary diagnostics removed.
- Documentation updated.
- Code review completed.
- ForgeOS API frozen.
- All automated and manual tests pass.

---

# Milestone Vision

**M1 delivers the complete FORGE engine foundation.**

By the completion of Milestone 1, FORGE will provide:

- Logging
- Event dispatching
- Shared runtime state
- Deterministic persistence
- Automatic save/load integration with Farming Simulator
- Engine lifecycle management
- A stable platform upon which all future gameplay systems can be built

From this point onward, future milestones focus on building gameplay features **using** the engine rather than expanding the engine itself.

---

## Future Milestones

Future milestones will be expanded as they become active.

Only the current milestone contains detailed implementation tasks to keep this roadmap concise and easy to maintain.
