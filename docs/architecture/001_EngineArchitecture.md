# FORGE Engine Architecture

**Status:** Accepted  
**Version:** 1.0

---

## Purpose

This document defines the high-level architecture of the FORGE Engine.

Its purpose is to provide contributors with a consistent understanding of how the engine is organised, where new code belongs, and the responsibilities of each subsystem.

This document intentionally describes structure rather than implementation.

Implementation details are documented separately.

---

## Architecture Goals

The FORGE Engine is designed to be:

- Modular
- Multiplayer first
- Data driven
- Easy to navigate
- Easy to test
- Easy to extend
- Clear to new contributors
- Resistant to tightly coupled systems

Every architectural decision should support these goals.

---

## Engine Structure

```text
engine/
├── FORGE.lua
├── Engine.lua
├── definitions/
├── services/
├── managers/
└── utilities/
```

---

## Root Files

### FORGE.lua

Defines the global FORGE namespace.

Responsibilities:

- Global namespace creation
- Shared engine metadata
- Global references

This file should contain no gameplay logic.

---

### Engine.lua

Coordinates engine startup and shutdown.

Responsibilities:

- Engine initialisation
- Service initialisation
- Manager initialisation
- Startup sequencing
- Shutdown sequencing

This file should not contain business logic.

---

## Directory Responsibilities

### definitions/

Contains authoritative shared definitions.

Examples include:

- Log levels
- Log sources
- Event names
- Permission identifiers

Definition files provide a single source of truth and should never contain executable logic.

---

### services/

Contains reusable engine services.

Examples include:

- Logger
- Event Bus

Services provide functionality to the rest of the engine but should not own gameplay state.

---

### managers/

Contains long-lived systems responsible for coordinating gameplay domains.

Examples may include:

- Campaign Manager
- Save Manager
- Company Manager
- Economy Manager

Managers own state and coordinate multiple services.

---

### utilities/

Contains stateless helper functions shared across multiple systems.

Utilities should:

- Have no persistent state.
- Avoid dependencies where practical.
- Never contain gameplay ownership.

---

## Architectural Principles

FORGE follows several architectural principles.

### Single Responsibility

Every file should have one clearly defined purpose.

---

### Composition over Coupling

Systems should communicate through shared services and events rather than directly depending on one another.

---

### Data First

Gameplay should be driven by XML wherever practical.

Lua exists to execute systems rather than store gameplay data.

---

### Server Authority

The server owns the simulation.

Clients request actions rather than directly modifying state.

---

## Related Documents

- Project Vision
- Startup Lifecycle
- ADR-001 – Use Dedicated Definition Tables