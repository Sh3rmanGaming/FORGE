# FORGE Documentation

## Purpose

This directory contains FORGE architecture, standards, subsystem contracts,
milestone plans, technical decisions, and implementation guidance.

Approved FORGE documentation is the authoritative source of truth.

Implementation MUST follow approved documentation and MUST NOT silently define
or override architectural contracts.

Whenever implementation changes an architectural decision or public contract,
the relevant documentation must be updated as part of the same change.

## Status

Review

---

## Documentation Structure

```text
docs/
├── README.md
├── CONTRIBUTING.md
├── Engineering.md
├── EngineeringCharter.md
├── style/
├── architecture/
├── persistence/
├── forgeos/
├── roadmap/
├── adr/
├── developer/
└── reviews/
```

This structure separates project standards from subsystem documentation while
keeping all design material in one authoritative location.

---

## Standards

Project-wide standards that apply to every subsystem.

```text
style/
├── CodingStandards.md
├── DocumentationLifecycle.md
├── EngineeringProcess.md
├── FileHeaderStandard.md
└── GitWorkflow.md
```

These documents define:

- coding conventions
- documentation conventions
- authoritative project roles and engineering workflow
- Git branch, promotion, and repository safety policy
- file header requirements
- project-wide engineering standards

Every Contributor, Reviewer, and Implementation Engineer should read the
applicable documents before contributing or reviewing work.

---

## Architecture

Project-wide architectural documentation.

```text
architecture/
├── 000_ProjectVision.md
├── 001_EngineArchitecture.md
├── 002_StartupLifecycle.md
└── 003_PersistenceFormat.md
```

These documents describe systems that span multiple FORGE subsystems.

Subsystem-specific architecture should remain inside the subsystem directory.

---

## Persistence

Authoritative documentation for the persistence subsystem.

```text
persistence/
├── PersistenceLifecycle.md
├── XMLSchema.md
└── SaveManager.md
```

These documents define:

- persistence lifecycle
- XML persistence format
- Save Manager behaviour
- persistence ownership

---

## ForgeOS

ForgeOS Definitions is Verified as the authoritative v0.1 definitions
implementation contract. The other four ForgeOS documents remain Approved as
authoritative v0.1 implementation contracts, with their implementation and
verification outstanding.

```text
forgeos/
├── ForgeOSArchitecture.md
├── ForgeOSDefinitions.md
├── ForgeOSAppContract.md
├── ForgeOSStateModel.md
└── ForgeOSComponentDesign.md
```

These documents define:

- subsystem architecture
- public contracts
- runtime state
- authoritative definitions
- implementation boundaries

Before implementing a ForgeOS component, review the relevant ForgeOS
documentation.

---

## Roadmap

Milestone planning and project progression.

```text
roadmap/
└── Roadmap.md
```

Each milestone should contain:

- Purpose
- Deliverables
- Roadmap
- Milestone Exit Criteria
- Implementation Notes (optional)
- Changelog

---

## Architecture Decision Records

Architecture Decision Records (ADRs) explain why important technical decisions
were made.

```text
adr/
├── README.md
├── ADR-001-Definitions.md
└── docs/ADR/
    └── ADR-002-Separate-Persistence-Reader-and-Writer.md
```

ADR-002 remains in a legacy nested location and is indexed accurately until a
separate task authorizes moving it.

An ADR should explain:

- the problem
- the decision
- the reasoning
- the consequences

ADRs should remain concise.

Subsystem documentation should contain the complete design.

---

## Developer Procedures

- [Development Environment](developer/DevelopmentEnvironment.md)
- [FS25 Runtime Verification Deployment](developer/FS25RuntimeVerificationDeployment.md)
- [ForgeOS Addon Integration](developer/ForgeOSAddonIntegration.md)

The runtime-verification deployment procedure is the authoritative packaging,
archive-validation, deployment-hash, evidence-preservation, and operational-
restoration gate for future FS25 verification builds.

---

## Review Records

Engineering and architecture review evidence is stored under:

```text
reviews/
├── M2.002RuntimeVerification.md
├── M2.003ARuntimeVerification.md
├── M2.003BRuntimeVerification.md
├── M2.004RuntimeVerification.md
├── M2.005RuntimeVerification.md
├── M2.006RuntimeVerification.md
├── M2.007RuntimeVerification.md
├── M2.008RuntimeVerification.md
├── M2ArchitectureReview.md
└── RepositoryBaselineAudit-001.md
```

Current records:

- [M2.002 Runtime Verification](reviews/M2.002RuntimeVerification.md)
- [M2.003A Runtime Verification](reviews/M2.003ARuntimeVerification.md)
- [M2.003B Runtime Verification](reviews/M2.003BRuntimeVerification.md)
- [M2.004 Runtime Verification](reviews/M2.004RuntimeVerification.md)
- [M2.005 Runtime Verification](reviews/M2.005RuntimeVerification.md)
- [M2.006 Runtime Verification](reviews/M2.006RuntimeVerification.md)
- [M2.007 Runtime Verification](reviews/M2.007RuntimeVerification.md)
- [M2.008 Runtime Verification](reviews/M2.008RuntimeVerification.md)
- [M2.009 Runtime Verification](reviews/M2.009RuntimeVerification.md)
- [M2.010 Runtime Verification](reviews/M2.010RuntimeVerification.md)
- [M2.011 Runtime Verification](reviews/M2.011RuntimeVerification.md)
- [M2.012 Runtime Verification](reviews/M2.012RuntimeVerification.md)
- [M2.013 Final Architecture Review](reviews/M2.013FinalArchitectureReview.md)
- [M2.013 Runtime Verification](reviews/M2.013RuntimeVerification.md)
- [M3 Architecture Review](reviews/M3ArchitectureReview.md)
- [M3.002 Runtime Verification](reviews/M3.002RuntimeVerification.md)
- [M3.003 Runtime Verification](reviews/M3.003RuntimeVerification.md)
- [M3.004 Runtime Verification](reviews/M3.004RuntimeVerification.md)
- [M3.005 Runtime Verification](reviews/M3.005RuntimeVerification.md)
- [M3.006 Runtime Verification](reviews/M3.006RuntimeVerification.md)
- [M3.007 Runtime Verification](reviews/M3.007RuntimeVerification.md)
- [M3.008 Runtime Verification](reviews/M3.008RuntimeVerification.md)
- [Communications Architecture](communications/CommunicationsArchitecture.md)
- [Communications Component Design](communications/CommunicationsComponentDesign.md)
- [Communications Definitions](communications/CommunicationsDefinitions.md)
- [Communications State Model](communications/CommunicationsStateModel.md)
- [Communications Application Contract](communications/CommunicationsAppContract.md)
- [ADR-003 - Device Host Lifecycle and Visibility](adr/ADR-003-Device-Host-Lifecycle-and-Visibility.md)
- [ADR-004 - FS25 Cross-Mod ForgeOS Export Bridge](adr/ADR-004-FS25-Cross-Mod-ForgeOS-Export-Bridge.md)
- [Verified M2.010 companion reference](../verification/FS25_FORGE_M2010_Verifier/README.md)
- [Verified M2.011 companion reference](../verification/FS25_FORGE_M2011_Verifier/README.md)
- [M2 Architecture Review](reviews/M2ArchitectureReview.md)
- [Repository Baseline Audit 001](reviews/RepositoryBaselineAudit-001.md)

Review records capture evidence and outcomes. They do not change a document's
lifecycle status unless the appropriate authority records that status change.

---

## Documentation Authority

Approved FORGE documentation is authoritative. Draft and Review documents
remain design material under review and MUST NOT be treated as approved
implementation contracts.

Document authority depends on status:

- **Draft:** incomplete or unresolved and not an implementation contract.
- **Review:** authored and ready for architecture review, but not yet accepted
  as an implementation contract.
- **Approved:** accepted as the implementation contract.
- **Implemented:** reflected in code.
- **Verified:** the implementation has been tested against the document.

Roadmap authorship progress MUST remain distinct from these document statuses.
An authored document MAY be Draft or Review and MUST NOT be described as
Approved, Implemented, or Verified until it reaches those states.

When documentation and implementation disagree:

1. Stop implementation.
2. Determine whether the documentation or implementation is incorrect.
3. Update the incorrect source.
4. Review the change.
5. Commit both documentation and implementation together where appropriate.

Documentation should never be silently ignored because implementation appears
easier.

---

## Documentation Review

Documentation should be reviewed before implementation begins.

The authoritative workflow and role definitions are in
[EngineeringProcess.md](style/EngineeringProcess.md). Git operations and
promotion policy are defined in [GitWorkflow.md](style/GitWorkflow.md).
File-header requirements are defined in
[FileHeaderStandard.md](style/FileHeaderStandard.md).

The implementation workflow for every subsystem is:

```text
Problem or Objective
        ↓
Repository and Scope Validation
        ↓
Architecture and Contract Review
        ↓
READY FOR APPROVAL or STOP
        ↓
Explicit Approval
        ↓
Documentation and Implementation
        ↓
Testing and Audit
        ↓
Code and Full File Review
        ↓
Completion Report
```

Branch promotion, commits, pushes, API freezes, and tags occur only when their
requirements in the Git Workflow and applicable milestone plan are satisfied.

---

## Selecting Documentation for Implementation

Only review documentation relevant to the subsystem being implemented.

Example:

### ForgeOS App Registry

Review:

- ForgeOS Architecture
- ForgeOS Definitions
- ForgeOS App Contract

### ForgeOS Navigation

Review:

- ForgeOS Architecture
- ForgeOS State Model

### Persistence

Review:

- Persistence Lifecycle
- XML Schema
- Save Manager

This keeps implementation focused while avoiding unnecessary review of
unrelated systems.

---

## Updating Documentation

Documentation should be updated whenever:

- architecture changes
- public APIs change
- responsibilities change
- persistence changes
- behaviour changes
- implementation reveals a better design

Documentation updates are considered part of implementation rather than
optional maintenance.

---

## Current Project Status

```text
Current Milestone

M3 – Communications
```

Completed implementation:

```text
M2.002 – Definitions
M2.003 – ForgeOS Core
    M2.003A – Core Lifecycle Foundation
    M2.003B – Registration Coordinator Foundation
M2.004 – Device Registry
M2.005 – App Registry
M2.006 – Presentation Resolver
M2.007 – Lifecycle Service
M2.008 – Navigation Service
M2.009 – Notification Service
M2.010 – Phone Host
M2.011 – Laptop Host
M2.012 – End-to-End Integration
M2.013 – ForgeOS Polish
M3.001 – Communications Architecture
M3.002 – Communications Definitions
M3.003 – Communications Manager
M3.004 – Communications Application Contract
M3.005 – Notification Integration
M3.006 – Phone Communications UI
```

Current verification stage:

```text
M3.008 – End-to-End Verification and Polish
```

M2.010 – Phone Host is implemented, synchronized, runtime verified, accepted,
and frozen within its bounded scope. Production ForgeOS reaches
`RUNTIME_ACTIVE` with its first concrete Phone Host, and the external companion
bridge is runtime proven. M2.011 – Laptop Host is implemented, synchronized,
runtime verified, accepted, and frozen within its bounded two-Host scope. F8
remains its development/fallback adapter while physical in-world Laptop
interaction remains future work. Dedicated-server Host/UI behaviour remains
unverified. M2.012 – End-to-End Integration is runtime verified through an
unchanged-package two-cycle gate. M2.013 – ForgeOS Polish is runtime verified,
accepted, and complete. The bounded implemented ForgeOS Foundation contract is
frozen, and overall M2 is Complete. Multiplayer and dedicated-server Host/UI
runtime behaviour and the other recorded post-M2 capabilities remain
unverified or deferred and are not included in that freeze.

M3.001 Architecture is approved. Its contracts define one received-message
`forge.communications` application, a separate Communications-owned SAVEGAME
inbox, asymmetric notification linkage, and a bounded detached application-
presentation adapter. M3.002 definitions are implemented, synchronized,
runtime verified, accepted, and frozen within their bounded scope. Notification
execution, presentation execution, UI, and external producer APIs remain
unimplemented.
M3.003 – Communications Manager provides the authoritative inbox, read/archive
lifecycle, persistence registration,
deterministic restoration, detached queries, retention, and Engine lifecycle
coordination. Implementation and runtime verification are complete; the
milestone was accepted and frozen within that bounded scope on 2026-08-16.
M3.004 – Communications Application Contract provides built-in app
registration, private provider retention, detached inbox/detail models, unread
badges, declared actions, and ForgeOS-mediated navigation. It is implemented,
runtime verified, accepted, and frozen within that bounded scope. Host UI and
notification linkage remain deferred from the frozen M3.004 scope. M3.005 –
Notification Integration is implemented, runtime verified, accepted, and
frozen within its bounded scope. M3.006 Phone Communications UI and M3.007
Laptop Communications UI are implemented, runtime verified, accepted, and
frozen within their bounded scopes. M3.008 End-to-End Verification and Polish
is implemented and runtime verified through an unchanged-package two-cycle
gate. M3.008 and overall M3 are accepted and frozen within their bounded
scopes.

---

## Long-Term Goal

FORGE documentation should allow an experienced developer to understand the
architecture, responsibilities, public contracts, and implementation
expectations before reading the source code.

Implementation should confirm the documentation rather than define it.
