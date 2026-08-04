# Contributing to FORGE

Thank you for your interest in contributing to FORGE.

Whether you are fixing a bug, improving documentation, designing a new gameplay system, or proposing an architectural improvement, your contribution is appreciated.

This document explains how the project is developed and what is expected when contributing.

---

## Project Philosophy

FORGE is built around a few core principles:

- Readability over cleverness.
- Architecture before implementation.
- XML first, Lua second.
- Documentation is part of the product.
- Long-term maintainability is more important than short-term speed.

If you are unsure why a particular standard exists, consult the project documentation before introducing an exception.

---

## Before You Start

Please familiarise yourself with the following documents:

- [Engineering Process](style/EngineeringProcess.md)
- [Git Workflow](style/GitWorkflow.md)
- [Project Vision](architecture/000_ProjectVision.md)
- [Engineering Charter](EngineeringCharter.md)
- [Engine Architecture](architecture/001_EngineArchitecture.md)
- [Coding Standards](style/CodingStandards.md)
- [Documentation Lifecycle](style/DocumentationLifecycle.md)
- [Development Environment](developer/DevelopmentEnvironment.md)
- [Architecture Decision Records](adr/README.md)

Understanding these documents will make contributing significantly easier.

---

## Development Workflow

1. Validate repository state, scope, and applicable documentation.
2. Return `STOP` for a blocker or `READY FOR APPROVAL` with a concrete plan.
3. Wait for explicit approval.
4. Create or update documentation where appropriate.
5. Implement the approved design.
6. Run applicable synchronization only when its effects are understood.
7. Test and review changes in proportion to risk.
8. Report changes, evidence, unresolved issues, and repository status.

---

## Coding Standards

All contributions should follow the project's coding standards.

In particular:

- Keep functions focused.
- Avoid unnecessary coupling.
- Use authoritative definition tables.
- Include standard FORGE file headers.
- Write code that is easy to understand.

---

## Documentation

Documentation should evolve alongside the code.

When behaviour changes:

- Update the relevant documentation.
- Update ADRs where architectural decisions change.
- Keep examples accurate.

---

## Pull Requests

When submitting a pull request:

- Clearly describe the purpose of the change.
- Explain any architectural decisions.
- Reference relevant issues or ADRs where appropriate.
- Keep changes focused on a single objective.

Smaller pull requests are generally easier to review than large ones.

---

## Reporting Issues

When reporting a bug, include:

- Steps to reproduce the issue.
- Expected behaviour.
- Actual behaviour.
- Relevant log output where available.
- Farming Simulator version.
- FORGE version or commit, if known.

---

## Code of Conduct

Please be respectful when discussing ideas.

Critique designs rather than people.

Disagreement is expected during engineering discussions, but decisions should ultimately follow the documented architecture and review process.

---

## Questions

If you are unsure about a design decision, ask before implementing it.

Good questions early in development are significantly cheaper than large refactors later.
