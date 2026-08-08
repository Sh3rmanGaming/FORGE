# FORGE Roadmap

**Status:** Active  
**Last Updated:** 2026-08-05

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

All current ForgeOS documents are authored and have completed Architecture
Review. Four remain `Approved` as authoritative v0.1 implementation contracts.
ForgeOS Definitions has been implemented and verified.

Review evidence and accepted decisions are recorded in the
[M2 Architecture Review](../reviews/M2ArchitectureReview.md).

| Document | Authored | Architecture Review | Approved | Implemented | Verified |
|----------|----------|---------------------|----------|-------------|----------|
| ForgeOS Architecture | ✅ Complete | ✅ Complete | ✅ Complete | ⬜ Not Started | ⬜ Not Started |
| ForgeOS Component Design | ✅ Complete | ✅ Complete | ✅ Complete | ⬜ Not Started | ⬜ Not Started |
| ForgeOS Definitions | ✅ Complete | ✅ Complete | ✅ Complete | ✅ Complete | ✅ Complete |
| ForgeOS App Contract | ✅ Complete | ✅ Complete | ✅ Complete | ⬜ Not Started | ⬜ Not Started |
| ForgeOS State Model | ✅ Complete | ✅ Complete | ✅ Complete | ⬜ Not Started | ⬜ Not Started |

---

#### ✅ M2.002 – Definitions

| Authored | Architecture Review | Approved | Implemented | Verified |
|----------|---------------------|----------|-------------|----------|
| ✅ Complete | ✅ Complete | ✅ Complete | ✅ Complete | ✅ Complete |

M2.002 is complete. The Approved v0.1 definitions contract has been
implemented, synchronized into the prototype, loaded in the approved order,
and verified in Farming Simulator 25.

Evidence:

- [ForgeOS Definitions](../forgeos/ForgeOSDefinitions.md)
- [M2 Architecture Review](../reviews/M2ArchitectureReview.md)
- [M2.002 Runtime Verification](../reviews/M2.002RuntimeVerification.md)

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

#### ✅ M2.003 – ForgeOS Core

| Authored | Architecture Review | Approved | Implemented | Verified |
|----------|---------------------|----------|-------------|----------|
| ✅ Complete | ✅ Complete | ✅ Complete | ✅ Complete | ✅ Complete |

M2.003 is complete. It delivers the verified Core Lifecycle Foundation and
Registration Coordinator Foundation without implementing the concrete
registries assigned to later milestones.

##### ✅ M2.003A – Core Lifecycle Foundation

| Authored | Architecture Review | Approved | Implemented | Verified |
|----------|---------------------|----------|-------------|----------|
| ✅ Complete | ✅ Complete | ✅ Complete | ✅ Complete | ✅ Complete |

M2.003A implements and verifies the bounded Core lifecycle from `UNAVAILABLE`
through `REGISTRATION_OPEN`, plus clean shutdown to `STOPPED`.

Evidence:

- [ForgeOS Architecture](../forgeos/ForgeOSArchitecture.md)
- [ForgeOS Component Design](../forgeos/ForgeOSComponentDesign.md)
- [ForgeOS Definitions](../forgeos/ForgeOSDefinitions.md)
- [ForgeOS State Model](../forgeos/ForgeOSStateModel.md)
- [M2 Architecture Review](../reviews/M2ArchitectureReview.md)
- [M2.003A Runtime Verification](../reviews/M2.003ARuntimeVerification.md)

- Engine startup integration
- Engine shutdown integration
- authoritative lifecycle phase ownership
- M2.003A transition enforcement
- Core lifecycle and compatibility queries
- ForgeOS state initialization
- persistence registration
- registration-open and stopped events
- Core and Bootstrap component tests
- Core lifecycle integration tests

##### ✅ M2.003B – Registration Coordinator Foundation

| Authored | Architecture Review | Approved | Implemented | Verified |
|----------|---------------------|----------|-------------|----------|
| ✅ Complete | ✅ Complete | ✅ Complete | ✅ Complete | ✅ Complete |

M2.003B implements and verifies registration lifecycle coordination without
implementing concrete Device Registry, Device Host Registry, or App Registry
capabilities.

Evidence:

- [ForgeOS Architecture](../forgeos/ForgeOSArchitecture.md)
- [ForgeOS Component Design](../forgeos/ForgeOSComponentDesign.md)
- [ForgeOS Definitions](../forgeos/ForgeOSDefinitions.md)
- [ForgeOS App Contract](../forgeos/ForgeOSAppContract.md)
- [M2 Architecture Review](../reviews/M2ArchitectureReview.md)
- [M2.003B Runtime Verification](../reviews/M2.003BRuntimeVerification.md)

- Registration Coordinator ownership
- explicit Registration Participant internal contract
- three required participant roles
- deterministic participant ordering
- validation and freeze orchestration
- registration gating and late-participant rejection
- failure cleanup, shutdown, and restart
- registration-frozen and started event publication
- component and registration-lifecycle integration tests

Coordinator capability is verified using explicit test participants through
`REGISTRATION_FROZEN` and `RUNTIME_ACTIVE`. Production integration is verified
while correctly remaining at `REGISTRATION_OPEN` until the concrete
participants exist. Production runtime activation is deferred to those later
registry milestones.

---

#### ✅ M2.004 – Device Registry

| Authored | Architecture Review | Approved | Implemented | Verified |
|----------|---------------------|----------|-------------|----------|
| ✅ Complete | ✅ Complete | ✅ Complete | ✅ Complete | ✅ Complete |

M2.004 is complete. It implements and verifies the concrete Device Registry
without implementing the deferred Device Host Registry or App Registry.

Evidence:

- [ForgeOS Architecture](../forgeos/ForgeOSArchitecture.md)
- [ForgeOS Component Design](../forgeos/ForgeOSComponentDesign.md)
- [ForgeOS Definitions](../forgeos/ForgeOSDefinitions.md)
- [M2 Architecture Review](../reviews/M2ArchitectureReview.md)
- [M2.004 Runtime Verification](../reviews/M2.004RuntimeVerification.md)

- authoritative device-definition registration
- deterministic argument, schema, duplicate, and gate results
- device capability validation
- lifecycle-local duplicate rejection
- detached controlled storage and lookup
- deterministic identifier enumeration
- `DEVICE_REGISTERED` publication and listener-failure isolation
- Registration Participant validation, freeze, cleanup, and restart
- production participant installation before registration-open observers
- component and lifecycle integration tests
- synchronized prototype and FS25 runtime verification

Production ForgeOS correctly remains at `REGISTRATION_OPEN` until the concrete
Device Host Registry and App Registry participants are implemented. Production
runtime activation remains deferred.

---

#### ✅ M2.005 – App Registry

| Authored | Architecture Review | Approved | Implemented | Verified |
|----------|---------------------|----------|-------------|----------|
| ✅ Complete | ✅ Complete | ✅ Complete | ✅ Complete | ✅ Complete |

M2.005 is complete. It implements and verifies the bounded App Registry
capability without implementing presentation resolution, application
lifecycle, availability, navigation, owner authority, or the deferred Device
Host Registry.

Evidence:

- [ForgeOS Architecture](../forgeos/ForgeOSArchitecture.md)
- [ForgeOS Component Design](../forgeos/ForgeOSComponentDesign.md)
- [ForgeOS Definitions](../forgeos/ForgeOSDefinitions.md)
- [ForgeOS App Contract](../forgeos/ForgeOSAppContract.md)
- [M2 Architecture Review](../reviews/M2ArchitectureReview.md)
- [M2.005 Runtime Verification](../reviews/M2.005RuntimeVerification.md)

- authoritative application-definition registration
- owner identifier recording and basic validation
- App API compatibility validation
- deterministic argument, schema, API, duplicate, and gate results
- nested presentation, route, action, callback, and provider shape validation
- controlled declarative storage and private executable references
- detached snapshots and lexical identifier enumeration
- `APP_REGISTERED` publication and listener-failure isolation
- Registration Participant validation, freeze, cleanup, and restart
- production Device Registry then App Registry installation
- reconciled component and lifecycle integration tests
- synchronized prototype and FS25 runtime verification

Production ForgeOS correctly remains at `REGISTRATION_OPEN` until the concrete
Device Host Registry participant exists. Production runtime activation and
`STARTED` remain deferred.

---

#### ✅ M2.006 – Presentation Resolver

| Authored | Architecture Review | Approved | Implemented | Verified |
|----------|---------------------|----------|-------------|----------|
| ✅ Complete | ✅ Complete | ✅ Complete | ✅ Complete | ✅ Complete |

M2.006 is complete. It implements and verifies deterministic read-only
presentation resolution without implementing availability execution,
application lifecycle, navigation, rendering, persistence, or the deferred
Device Host Registry.

Evidence:

- [ForgeOS Architecture](../forgeos/ForgeOSArchitecture.md)
- [ForgeOS Component Design](../forgeos/ForgeOSComponentDesign.md)
- [ForgeOS Definitions](../forgeos/ForgeOSDefinitions.md)
- [ForgeOS App Contract](../forgeos/ForgeOSAppContract.md)
- [M2 Architecture Review](../reviews/M2ArchitectureReview.md)
- [M2.006 Runtime Verification](../reviews/M2.006RuntimeVerification.md)

- runtime-active public resolver facade
- exact-device matching
- capability-compatible fallback
- declared default fallback
- universal and presentation capability validation
- finite numeric priority and omitted-priority handling
- deterministic lexical tie-breaking
- deterministic missing-capability diagnostics
- exact, capability, and default match types
- detached read-only results
- component and integration regression coverage
- synchronized prototype and FS25 runtime verification

Controlled tests verify resolution at `RUNTIME_ACTIVE` using an explicit
Device Host test participant. Production correctly remains at
`REGISTRATION_OPEN` until the concrete Device Host Registry exists.

---

#### ✅ M2.007 – Lifecycle Service

| Authored | Architecture Review | Approved | Implemented | Verified |
|----------|---------------------|----------|-------------|----------|
| ✅ Complete | ✅ Complete | ✅ Complete | ✅ Complete | ✅ Complete |

M2.007 is complete. It implements and verifies the bounded local-player
Lifecycle Service without implementing Availability, Navigation, rendering,
resume restoration, multiplayer identity, or a production Device Host
Registry.

Evidence:

- [ForgeOS Architecture](../forgeos/ForgeOSArchitecture.md)
- [ForgeOS Component Design](../forgeos/ForgeOSComponentDesign.md)
- [ForgeOS Definitions](../forgeos/ForgeOSDefinitions.md)
- [ForgeOS App Contract](../forgeos/ForgeOSAppContract.md)
- [ForgeOS State Model](../forgeos/ForgeOSStateModel.md)
- [M2 Architecture Review](../reviews/M2ArchitectureReview.md)
- [M2.007 Runtime Verification](../reviews/M2.007RuntimeVerification.md)

- public open, activate, background, and close operations
- lifecycle-state and active-app queries
- runtime-only local-player/device/app lifecycle state
- one-active-app invariant and deterministic displacement
- bounded enabled-policy integration
- Presentation Resolver eligibility for opening
- private lifecycle-callback access after registry freeze
- callback timing, controlled failure, and non-reentrancy
- atomic ForgeOS lifecycle-state and active-app commit
- completed lifecycle events and listener-failure isolation
- cleanup, shutdown, restart, and non-persistence
- complete retained regression and FS25 runtime verification

Controlled tests verify lifecycle behavior at `RUNTIME_ACTIVE` using one
explicit Device Host test participant. Production correctly remains at
`REGISTRATION_OPEN` until the concrete Device Host Registry exists.

---

#### ✅ M2.008 – Navigation Service

| Authored | Architecture Review | Approved | Implemented | Verified |
|----------|---------------------|----------|-------------|----------|
| ✅ Complete | ✅ Complete | ✅ Complete | ✅ Complete | ✅ Complete |

M2.008 is complete. It implements and verifies bounded logical navigation for
the active local-player application without introducing a Route Registry,
runtime route registration, route-controller execution, automatic lifecycle
transitions, or a production Device Host Registry.

Evidence:

- [ForgeOS Architecture](../forgeos/ForgeOSArchitecture.md)
- [ForgeOS Component Design](../forgeos/ForgeOSComponentDesign.md)
- [ForgeOS Definitions](../forgeos/ForgeOSDefinitions.md)
- [ForgeOS App Contract](../forgeos/ForgeOSAppContract.md)
- [ForgeOS State Model](../forgeos/ForgeOSStateModel.md)
- [M2 Architecture Review](../reviews/M2ArchitectureReview.md)
- [M2.008 Runtime Verification](../reviews/M2.008RuntimeVerification.md)

- public navigate and back operations
- current-route and detached-history queries
- runtime-active and active-app gating
- presentation-scoped route validation
- safe detached route parameters
- deterministic idempotence
- bounded runtime history and deterministic oldest-first eviction
- deterministic invalid-history repair and back navigation
- post-commit navigation events and listener-failure isolation
- navigation resume-state updates without persisted runtime history
- runtime cleanup, shutdown, and restart
- traceable packaging, deployment, regression, and FS25 runtime verification

Controlled tests verify navigation at `RUNTIME_ACTIVE` using one explicit
Device Host test participant. Production correctly remains at
`REGISTRATION_OPEN` until the concrete Device Host Registry exists.

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
