# FORGE Roadmap

**Status:** Active  
**Last Updated:** 2026-08-11

---

## Overall Progress

| Milestone | Status |
|-----------|--------|
| M0 – Foundation | ✅ Complete |
| M1 – Engine | ✅ Complete |
| M2 – ForgeOS | ✅ Complete |
| M3 – Communications | 🟡 In Progress |
| M4 – Projects | ⬜ Planned |
| M5 – Banking | ⬜ Planned |
| M6 – Companies | ⬜ Planned |
| M7 – Campaign SDK | ⬜ Planned |
| M8 – Public Release | ⬜ Planned |

---

## Current Milestone — M3: Communications

# FORGE Development Roadmap

## Completed

### ✅ M2 – ForgeOS

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

#### ✅ M2.009 – Notification Service

| Authored | Architecture Review | Approved | Implemented | Verified |
|----------|---------------------|----------|-------------|----------|
| ✅ Complete | ✅ Complete | ✅ Complete | ✅ Complete | ✅ Complete |

M2.009 is implemented, synchronized, runtime verified, accepted, and frozen
within its bounded Notification Foundation scope. Two FS25 cycles using one
unchanged package verify hard-restart savegame restoration, session absence,
read/dismiss state, and monotonic sequence continuity.

Evidence:

- [ForgeOS Architecture](../forgeos/ForgeOSArchitecture.md)
- [ForgeOS Component Design](../forgeos/ForgeOSComponentDesign.md)
- [ForgeOS Definitions](../forgeos/ForgeOSDefinitions.md)
- [ForgeOS State Model](../forgeos/ForgeOSStateModel.md)
- [M2 Architecture Review](../reviews/M2ArchitectureReview.md)
- [M2.009 Runtime Verification](../reviews/M2.009RuntimeVerification.md)

- Notification creation
- Notification dismissal
- Notification read state
- Notification persistence
- Notification targeting
- Notification events
- Notification test suite

---

#### ✅ M2.010 – Phone Host

| Authored | Architecture Review | Approved | Implemented | Verified |
|----------|---------------------|----------|-------------|----------|
| ✅ Complete | ✅ Complete | ✅ Complete | ✅ Complete | ✅ Complete |

M2.010 is implemented, synchronized, runtime verified, accepted, and frozen
within its bounded Phone Host and local cross-mod integration scope. Production
ForgeOS now reaches `RUNTIME_ACTIVE` with its first concrete Device Host after
deferred first-update registration completion. A real dependent companion mod
registered during `REGISTRATION_OPEN`, and the same reviewed package pair
proved Phone resume and retained notification state across a hard restart.

Evidence and governing records:

- [ADR-003 - Device Host Lifecycle and Visibility](../adr/ADR-003-Device-Host-Lifecycle-and-Visibility.md)
- [ADR-004 - FS25 Cross-Mod ForgeOS Export Bridge](../adr/ADR-004-FS25-Cross-Mod-ForgeOS-Export-Bridge.md)
- [M2 Architecture Review](../reviews/M2ArchitectureReview.md)
- [M2.010 Runtime Verification](../reviews/M2.010RuntimeVerification.md)
- [ForgeOS Addon Integration](../developer/ForgeOSAddonIntegration.md)

Accepted capability includes the production Device Host Registry topology,
built-in Phone and `phoneHost`, one ForgeOS-owned local PhoneHost, Device State
visibility, F7 `FORGE_TOGGLE_PHONE` input, minimal Phone presentation,
notification read/dismiss integration, same-runtime state preservation,
hard-restart navigation resume, clean shutdown, and the complete retained
regression suite.

Dedicated-server bridge and Phone behaviour, multiplayer Host ownership,
multiple runtime Hosts, Laptop Host, third-party Host registration, general app
rendering, and general cursor/focus ownership remain unverified and unfrozen.

Overall M2 remains In Progress.

---

#### ✅ M2.011 – Laptop Host

| Authored | Architecture Review | Approved | Implemented | Verified |
|----------|---------------------|----------|-------------|----------|
| ✅ Complete | ✅ Complete | ✅ Complete | ✅ Complete | ✅ Complete |

M2.011 is implemented, synchronized, runtime verified, accepted, and frozen
within its bounded Laptop Host and two-Host orchestration scope. The unchanged
FORGE/verifier package pair passed two FS25 cycles across a hard restart.

Evidence and governing records:

- [ADR-003 - Device Host Lifecycle and Visibility](../adr/ADR-003-Device-Host-Lifecycle-and-Visibility.md)
- [M2 Architecture Review](../reviews/M2ArchitectureReview.md)
- [M2.011 Runtime Verification](../reviews/M2.011RuntimeVerification.md)

Accepted capability includes one ForgeOS-owned PhoneHost and LaptopHost,
deterministic Phone-then-Laptop processing, reverse shutdown, atomic Host
startup, independent simultaneous visibility, the bounded Laptop shell and
launcher, notification interaction, independent resume, F8 as the
development/fallback Laptop adapter, and the verified F6 pointer-mode boundary.
The future physical in-world Laptop interaction remains deferred.

- Laptop device registration
- Laptop presentation host
- Laptop lifecycle integration
- Laptop navigation integration
- Laptop notification integration
- Laptop resume support
- Laptop host test suite

Dedicated-server Host/UI behaviour remains unverified and unfrozen. Window
management, multi-app rendering, physical world-object interaction, general
focus ownership, controller execution, and other deferred capabilities are not
included in this freeze.

Overall M2 remains In Progress.

---

#### ✅ M2.012 – End-to-End Integration

| Authored | Architecture Review | Approved | Implemented | Verified |
|----------|---------------------|----------|-------------|----------|
| ✅ Complete | ✅ Complete | ✅ Complete | ✅ Complete | ✅ Complete |

M2.012 is implemented and runtime verified through one unchanged-package,
two-cycle FS25 gate across a hard restart. See
[M2.012 Runtime Verification](../reviews/M2.012RuntimeVerification.md).

- ForgeOS startup verification
- Device registration verification
- App registration verification
- Presentation resolution verification
- Lifecycle verification
- Navigation verification
- Resume state verification
- Persistence verification
- Notification verification
- Bounded multiplayer compatibility review
- Explicit multiplayer and dedicated-server non-verification record
- Shared cross-device notification-state verification

---

#### ✅ M2.013 – ForgeOS Polish

| Authored | Architecture Review | Approved | Implemented | Verified |
|----------|---------------------|----------|-------------|----------|
| ✅ Complete | ✅ Complete | ✅ Complete | ✅ Complete | ✅ Complete |

M2.013 is accepted and complete. The implemented ForgeOS Foundation is frozen
within the layered boundary recorded by the
[M2.013 Final Architecture Review](../reviews/M2.013FinalArchitectureReview.md)
and supported by the
[M2.013 Runtime Verification](../reviews/M2.013RuntimeVerification.md).

- Remove temporary diagnostics
- Documentation review
- Public API review
- Definition review
- Code review
- Performance review
- Final architecture review
- Freeze the implemented ForgeOS Foundation contract
- Classify addon-facing, Engine/platform-adapter, internal, and deferred APIs
- Preserve compatible future additive API evolution

Overall M2 – ForgeOS is complete. The freeze covers the accepted Foundation,
not every future ForgeOS capability. Multiplayer and dedicated-server Host/UI
behaviour, controller/application rendering, interactive Phone application
menus, source-to-app badge ownership, Laptop desktop/window management, general
focus/text-input ownership, and physical Laptop interaction remain explicitly
deferred, unverified, and non-frozen where applicable.

---

## In Progress

### 🟡 M3 – Communications

#### ✅ M3.001 – Communications Architecture

| Authored | Architecture Review | Approved | Implemented | Verified |
|----------|---------------------|----------|-------------|----------|
| ✅ Complete | ✅ Complete | ✅ Complete | ➖ N/A | ➖ N/A |

M3.001 specifies the received-message domain, persistence boundary,
notification relationship, and bounded ForgeOS application-presentation
adapter. Architecture approval now authorizes M3.002 definitions only. See the
[M3 Architecture Review](../reviews/M3ArchitectureReview.md).

#### ✅ M3.002 – Communications Definitions

| Authored | Architecture Review | Approved | Implemented | Verified |
|----------|---------------------|----------|-------------|----------|
| ✅ Complete | ✅ Complete | ✅ Complete | ✅ Complete | ✅ Complete |

- Stable identifiers, enumerations, results, events, and validation
- Pure controlled-data validation and detachment helper
- Component harness integrated into the development test runner
- Runtime verified, accepted, and frozen within the bounded definitions scope

#### ⏳ M3.003 – Communications Manager

- Authoritative bounded inbox, read/archive state, persistence, and repair
- Next implementation boundary; not started

#### ⏳ M3.004 – Communications Application Contract

- Built-in application registration and bounded presentation integration

#### ⏳ M3.005 – Notification Integration

- Linked alerts, asymmetric read propagation, and navigation linkage

#### ⏳ M3.006 – Phone Communications UI

- Full-screen inbox and message-detail Phone surfaces

#### ⏳ M3.007 – Laptop Communications UI

- One bounded Laptop application surface without desktop/window expansion

#### ⏳ M3.008 – End-to-End Verification and Polish

- Retained regression, two-cycle persistence, runtime evidence, and acceptance

---

## Planned

### ⏳ M1.008 – Campaign Manager
- Campaign lifecycle
- Save slot abstraction
- World metadata
- Campaign registry

### ⏳ M1.009 – Phone OS Foundation

Historical scope classification:

- Operating system bootstrap — superseded by M2 ForgeOS Core and Bootstrap.
- Application lifecycle — superseded by M2.007 App Lifecycle.
- Bounded UI framework integration — superseded by the M2.010 Phone Host and
  M2.011 Laptop Host foundations.
- Window management — retained as future post-M2 desktop/UI architecture work.
- Rich application UI and physical Laptop interaction — retained as future
  work and not implemented by M2.

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
- No unresolved architectural decisions block the accepted M2 scope.
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
- The bounded multiplayer compatibility review is complete; stable multiplayer
  identity, comprehensive multiplayer runtime behaviour, and dedicated-server
  Host/UI behaviour remain explicitly unverified and non-frozen.

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
