# FORGE Repository Guide

## Project Purpose

FORGE is an open-source gameplay framework for Farming Simulator 25. It provides
a modular engine and shared platforms upon which maintainable gameplay systems
can be built.

## Authoritative Guidance

Engineering work MUST follow:

1. `docs/style/EngineeringProcess.md` for project roles and engineering process
2. `docs/EngineeringCharter.md` for engineering philosophy
3. accepted Architecture Decision Records
4. approved architecture and contract documents
5. `docs/style/GitWorkflow.md`
6. applicable coding, documentation, and file-header standards

`docs/style/EngineeringProcess.md` is the authoritative source for project
roles and engineering workflow.

## Documentation First

Significant design and public-contract changes MUST be documented and reviewed
before implementation. Draft and Review documents are not approved
implementation contracts.

Before changing a subsystem, review its architecture, definitions, contracts,
state model, roadmap scope, and relevant ADRs. Implementation MUST NOT silently
resolve open architectural decisions.

## Repository Source of Truth

Authoritative source belongs in the repository source directories. Prototype,
generated, synchronized, packaged, and test-output copies MUST NOT silently
replace authoritative source. Follow the documented synchronization and
generated-file policies before changing derived files.

## Roles and Approval

The Project Director owns product and milestone authority. The Chief Architect
owns architecture and engineering-contract authority. The Implementation
Engineer performs approved work and reports evidence. Full responsibilities are
defined in `docs/style/EngineeringProcess.md`.

## STOP Authority

Before editing a multi-file task, validate scope, architecture, repository
state, and safety. Return `STOP` without modifying files when work would:

- conflict with accepted or approved architecture;
- preserve or introduce a repository contradiction;
- require missing information;
- silently resolve an open architectural decision;
- perform an unsafe Git operation; or
- exceed milestone or approved task scope.

A STOP report MUST include the reason, evidence, consequences, suggested
correction, and the decision or scope change required.

## READY FOR APPROVAL

When validation finds no blocker, report `READY FOR APPROVAL` with:

- files to create or modify;
- evidence-based repository findings;
- risks;
- assumptions; and
- a file-by-file implementation plan.

Wait for explicit approval before editing.

## Engineering Principles

- Put player outcomes first.
- Design and document before construction.
- Prefer explicit responsibilities and dependencies.
- Preserve a single authoritative source.
- Keep changes focused, reviewable, and reversible.
- Test in proportion to risk.
- Record uncertainty rather than concealing it.
- Optimise for long-term maintainability and future contributors.

## Repository Safety

- Preserve unrelated and pre-existing work.
- Inspect a dirty working tree before editing.
- Do not stage, commit, push, tag, delete, rename, or move files without
  explicit authorization.
- Do not run synchronization tools until their source, destination, and
  generated-file effects are understood.
- Never treat generated output as authoritative unless documentation explicitly
  says otherwise.

## Completion Reporting

Report:

- files created and modified;
- checks and tests performed;
- unresolved issues;
- repository observations;
- advisory recommendations;
- Git status and diff summary; and
- confidence in the result.

Clearly distinguish facts, assumptions, and recommendations. Confirm that no
architectural decision was silently changed.
