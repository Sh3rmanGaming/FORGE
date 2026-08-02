# FORGE Engineering Guide

**Status:** Approved  
**Version:** 1.0

---

## Purpose

This document provides an overview of the engineering practices used throughout the FORGE project.

It serves as the entry point for contributors who want to understand how FORGE is designed, developed, documented and maintained.

Rather than duplicating information contained elsewhere, this guide links together the project's engineering standards and explains how they fit together.

---

## Engineering Philosophy

FORGE is engineered around a small number of core principles.

- Architecture before implementation.
- Documentation is part of the product.
- Readability over cleverness.
- XML first, Lua second.
- Long-term maintainability over short-term convenience.
- Design systems, not isolated features.

These principles guide every engineering decision made within the project.

---

## Engineering Decisions

Engineering decisions should be made using the following order of precedence:

1. Engineering Charter
2. Accepted ADRs
3. Architecture documentation
4. Coding Standards
5. Project conventions

If documentation appears to conflict, contributors should seek clarification before implementing a change.

---

## Engineering Workflow

Typical development follows this sequence:

```text
Identify Problem
        │
        ▼
Research
        │
        ▼
Architecture & Design
        │
        ▼
Documentation
        │
        ▼
Implementation
        │
        ▼
Review
        │
        ▼
Testing
        │
        ▼
Verification
```

The exact workflow may vary depending on the size of the change, but architectural work should always precede implementation.

---

## Engineering Documentation

The following documents define the engineering standards for FORGE.

| Document | Purpose |
|----------|---------|
| Engineering Charter | Defines engineering values and decision-making principles. |
| Coding Standards | Defines code structure and style expectations. |
| Documentation Lifecycle | Defines how documentation progresses from draft to verified. |
| File Header Standard | Defines standard headers for source files. |
| Development Environment | Defines the recommended development setup. |
| ADRs | Record significant architectural decisions. |

---

## Quality Expectations

Every contribution should strive to:

- Improve readability.
- Reduce unnecessary complexity.
- Preserve modularity.
- Minimise coupling.
- Keep documentation current.
- Leave the codebase better than it was found.

---

## Release Readiness

Before a milestone is considered complete, the following should be reviewed where applicable:

- Documentation updated.
- Architecture reviewed.
- Synchronisation completed successfully.
- Tests passing.
- Roadmap updated.
- CHANGELOG updated.
- Milestone approved.

---

## Related Documents

- Engineering Charter
- Coding Standards
- Documentation Lifecycle
- Development Environment
- Architecture Decision Records