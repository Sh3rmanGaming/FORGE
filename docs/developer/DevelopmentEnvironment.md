# FORGE Development Environment

**Status:** Accepted  
**Version:** 1.0

---

## Purpose

This document describes the recommended development environment for contributing to the FORGE project.

Following these recommendations helps ensure a consistent development experience across contributors and reduces environment-specific issues.

---

## Operating System

FORGE is primarily developed on Windows.

Development on Linux and macOS is expected to be possible, although it has not yet been formally validated.

---

## Required Software

### Farming Simulator 25

Required for runtime testing.

---

### GIANTS Editor

Required for certain asset and XML workflows.

---

### Visual Studio Code

Recommended editor for all FORGE development.

---

### Git

Required for source control.

---

### Python 3

Required for the FORGE developer toolchain.

Currently used by:

- FORGE Synchronisation Tool (`tools/sync.py`)

Future developer tools will also rely on Python.

---

## Recommended Visual Studio Code Extensions

### Lua

Lua language support.

---

### Even Better TOML

Configuration editing.

---

### XML

Improved XML editing and validation.

---

### Markdown All in One

Documentation authoring.

---

### GitLens

Enhanced Git history and blame information.

---

### EditorConfig (optional)

Helps maintain consistent formatting across contributors.

---

## Repository Workflow

The engine/ directory is the single authoritative source for the FORGE engine

```text
engine/
```

Changes should always be made there.

After modifying the engine, synchronise the prototype:

```powershell
python tools/sync.py
```

The generated prototype should never be edited directly.

---

## Git Workflow

Current long-term branch strategy:

```text
main
│
├── development
├── experimental
└── feature/*
```

Feature branches may be introduced as the project grows.

---

## Coding Standards

Before submitting changes:

- Follow the FORGE coding standards.
- Update documentation where required.
- Create an ADR for significant architectural decisions.
- Ensure the synchronisation tool completes successfully.
- Verify that tests continue to pass.

---

## Related Documents

- Engineering Charter
- Coding Standards
- Documentation Lifecycle