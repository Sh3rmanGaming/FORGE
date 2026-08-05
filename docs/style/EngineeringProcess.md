# FORGE Engineering Process

**Status:** Review  
**Version:** 1.0

## Purpose

This document defines the authoritative engineering process and project roles
for FORGE. It ensures that architecture, implementation, testing, review, and
milestone acceptance remain deliberate and evidence-based.

## Scope

This process applies to architecture, documentation, source code, tests,
tooling, generated artifacts, repository maintenance, and milestone work.

## Authoritative Project Roles

### Project Director

The Project Director owns:

- product vision and priorities;
- gameplay direction;
- milestone scope and acceptance;
- release authorization;
- final decisions where product intent or project direction is involved; and
- appointment or delegation of project governance roles.

### Chief Architect

The Chief Architect owns:

- software architecture;
- architectural and public-contract decisions;
- engineering standards;
- architecture-review outcomes;
- technical quality expectations; and
- approval to implement architecture that has completed review;
- code and documentation quality;
- technical mentoring; and
- code review expectations.

### Implementation Engineer

The Implementation Engineer:

- validates each task before editing;
- implements only approved scope;
- follows authoritative documentation;
- challenges contradictions and unsafe assumptions;
- writes or updates proportionate tests and documentation;
- preserves alignment between documentation and implementation;
- preserves unrelated repository work; and
- provides evidence-based completion reports.

Codex acts as an Implementation Engineer when performing repository tasks. It
does not grant architecture, milestone, or release approval to itself.

### Contributor

The Contributor may propose focused designs, documentation, code, tests, and
recommendations. A Contributor follows the documented lifecycle and does not
grant approval to their own work.

### Reviewer

The Reviewer assesses work within delegated expertise, reports evidence and
defects, and recommends review outcomes. A Reviewer does not silently exercise
Project Director or Chief Architect authority.

## Engineering Principles

- **Player first.** Engineering exists to support reliable, enjoyable gameplay.
- **Design before construction.** Architecture and contracts precede
  significant implementation.
- **Documentation is part of the product.** It must remain accurate, reviewable,
  and aligned with implementation.
- **Explicit ownership and dependencies.** Every responsibility and dependency
  should be intentional and visible.
- **One source of truth.** Shared contracts and data have one authoritative
  definition.
- **Clarity over cleverness.** Work should be understandable to future
  contributors.
- **Proportionate assurance.** Review and testing depth follow change risk.
- **Honest uncertainty.** Open decisions, assumptions, and limitations are
  recorded rather than silently resolved.
- **Long-term maintainability.** Local convenience must not create avoidable
  coupling or future ambiguity.

## Engineering Lifecycle

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
        ↓
Milestone Acceptance where applicable
```

Steps MAY be combined for a small, low-risk task, but validation, authorization,
and evidence MUST remain explicit.

## Capability Batches and Architecture Clarification

Implementation SHOULD be organised into coherent, independently testable
capability batches rather than arbitrary file-sized batches.

Execution subdivisions of a parent milestone MAY be implemented and verified
independently. Parent milestone acceptance and contract freeze occur only after
every required batch is complete and the Project Director accepts the combined
evidence.

When implementation encounters a bounded ambiguity in otherwise Approved
architecture, Architecture Clarification Mode MAY:

1. identify the exact ambiguity and affected implementation;
2. draft a narrowly scoped clarification that preserves the Approved design;
3. obtain the required Project Director and Chief Architect approval; and
4. resume the validated engineering task without repeating unaffected audit
   work.

Clarification MAY make approved intent deterministic. It MUST NOT silently
invent observable behaviour, introduce an unapproved capability, or resolve an
unrelated open decision.

## Documentation-First Rule

Approved documentation is the implementation contract. Draft and Review
documents are design material and MUST NOT be represented as Approved,
Implemented, or Verified.

The documentation lifecycle remains:

```text
Draft
    ↓
Review
    ↓
Approved
    ↓
Implemented
    ↓
Verified
```

Roadmap progress, authorship progress, architecture-review progress, and
document status are separate measures.

Implementation MUST NOT:

- silently define architecture absent from approved documentation;
- override an approved contract;
- treat an open decision as resolved; or
- claim that implementation proves approval or verification.

## Review Outcomes

A review produces one of these outcomes:

- **Accepted:** the reviewed change may proceed within stated scope.
- **Accepted with conditions:** work may proceed only when listed conditions
  are satisfied.
- **Revision required:** identified defects must be corrected and reviewed
  again.
- **Deferred:** no decision is made; the matter remains open.
- **Rejected:** the proposal must not be implemented.

Acceptance of an individual decision during review does not automatically
change a document's lifecycle status.

## Codex Task States

- **VALIDATING:** inspecting scope, repository state, architecture, and risk.
- **STOP:** blocked by contradiction, missing authority, missing information,
  unsafe action, or scope violation.
- **READY FOR APPROVAL:** validation passed and a concrete plan awaits approval.
- **IMPLEMENTING:** approved changes are in progress.
- **VERIFYING:** required checks and diff review are in progress.
- **COMPLETE:** approved work is finished and reported.

## STOP Authority

The Implementation Engineer MUST stop before editing when a task would:

- conflict with accepted or approved architecture;
- introduce or knowingly preserve a relevant repository contradiction;
- depend on material missing information;
- silently resolve an open architectural decision;
- require an unsafe or unauthorized Git operation; or
- exceed approved task or milestone scope.

A STOP report MUST provide:

1. reason;
2. evidence;
3. consequences;
4. suggested correction; and
5. decision required from the Project Director, Chief Architect, or through an
   explicit scope change.

STOP is a safety and correctness mechanism, not a substitute for investigating
available evidence.

## READY FOR APPROVAL

When no blocker exists, the Implementation Engineer MUST report:

- files to create and modify;
- repository findings supported by evidence;
- risks;
- assumptions;
- a file-by-file implementation plan; and
- advisory recommendations where useful.

No file edits begin until explicit approval is received.

## Audit Levels

| Level | Scope | Typical use |
|-------|-------|-------------|
| 0 | Targeted check | One fact, path, identifier, or small textual correction. |
| 1 | File audit | Complete review of one file and its direct contract. |
| 2 | Component audit | A component, its tests, dependencies, and documentation. |
| 3 | Subsystem audit | Cross-component architecture, contracts, integration, and milestone alignment. |
| 4 | Repository or milestone audit | Repository-wide authority, workflow, history, integration, release, and acceptance evidence. |

The lowest audit level that adequately addresses the risk SHOULD be used.
Findings MUST distinguish confirmed defects from observations and
recommendations.

## Codex Usage Efficiency

- Provide one focused objective and explicit constraints.
- Identify authoritative documents and expected deliverables.
- Separate read-only review from implementation authorization.
- Prefer one coordinated task for tightly coupled files.
- Avoid mixing unrelated cleanup with architecture or implementation work.
- Reuse existing evidence rather than repeating repository-wide audits without
  cause.
- Request the audit level appropriate to the decision being made.

Efficiency MUST NOT override correctness, safety, or required review.

## Testing Principles

- Testing depth MUST be proportionate to behavioural and architectural risk.
- Documentation-only work requires structural, reference, terminology, and diff
  validation.
- Source changes require relevant automated or manual tests where available.
- Integration changes require validation across affected boundaries.
- Generated or synchronized output must be checked against authoritative
  source.
- A passing test does not prove architecture approval.
- Tests that cannot be run MUST be reported explicitly with the remaining risk.

## Architecture Change Logs

An Architecture Change Log records contract-level changes accepted during a
review. Each entry contains:

1. title;
2. previous contract;
3. accepted contract;
4. reason;
5. documents affected; and
6. classification as clarification, inconsistency correction, new
   architectural rule, or open decision resolved.

Formatting-only, editorial, and repository-housekeeping changes are excluded.
Accepted decisions MUST NOT be described as formal document approval unless the
Chief Architect has also advanced the document status.

## Milestone Acceptance

A milestone may be accepted only by the Project Director after applicable
evidence has been reviewed. Evidence SHOULD include:

- required deliverables;
- architecture and documentation status;
- implementation alignment;
- test and audit results;
- unresolved issues and accepted deferrals;
- repository and release readiness; and
- Chief Architect assessment of technical acceptance criteria.

Completion of individual tasks does not by itself complete a milestone.

## Maintenance Rule

This document MUST be updated whenever project roles or the engineering process
change. Related guides SHOULD reference this document rather than duplicate its
contracts.

Role references in older documents are interpreted through the canonical roles
defined here until those documents are revised in an explicitly approved task.

## Related Documents

- [Repository Guide](../../AGENTS.md)
- [Engineering Charter](../EngineeringCharter.md)
- [Git Workflow](GitWorkflow.md)
- [Documentation Lifecycle](DocumentationLifecycle.md)
- [Coding Standards](CodingStandards.md)
- [File Header Standard](FileHeaderStandard.md)
