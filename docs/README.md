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

## Review Records

Engineering and architecture review evidence is stored under:

```text
reviews/
├── M2.002RuntimeVerification.md
├── M2ArchitectureReview.md
└── RepositoryBaselineAudit-001.md
```

Current records:

- [M2.002 Runtime Verification](reviews/M2.002RuntimeVerification.md)
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

M2 – ForgeOS
```

Completed implementation:

```text
M2.002 – Definitions
```

Next implementation stage:

```text
M2.003 – ForgeOS Core
```

---

## Long-Term Goal

FORGE documentation should allow an experienced developer to understand the
architecture, responsibilities, public contracts, and implementation
expectations before reading the source code.

Implementation should confirm the documentation rather than define it.
