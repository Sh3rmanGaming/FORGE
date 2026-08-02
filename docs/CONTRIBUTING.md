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

- Project Vision
- Engineering Charter
- Engine Architecture
- Coding Standards
- Documentation Lifecycle
- Development Environment
- Architecture Decision Records (ADRs)

Understanding these documents will make contributing significantly easier.

---

## Development Workflow

1. Create or update documentation where appropriate.
2. Discuss significant architectural changes before implementation.
3. Implement the approved design.
4. Run the FORGE Synchronisation Tool.
5. Test your changes.
6. Update documentation if behaviour has changed.
7. Submit your changes for review.

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