# FORGE
### Farming Operations & Regional Growth Engine

> **A living gameplay framework for Farming Simulator 25.**

FORGE transforms Farming Simulator from a collection of isolated mechanics into a living world where businesses, projects, finance, communication and progression work together to create deeper and more immersive gameplay.

Whether you simply want a richer Farming Simulator experience, want to build your own campaigns, or contribute to the engine itself, FORGE has been designed with you in mind.

---

# Why FORGE?

Traditional Farming Simulator gameplay focuses primarily on farming machinery and production.

FORGE expands the game into a living simulation by introducing systems that interact with one another to create meaningful long-term progression.

Examples include:

- Living companies
- Dynamic projects
- Banking and finance
- Career progression
- Communication systems
- Modular campaign framework
- Phone operating system
- Extensible APIs for modders

Every system has been designed to work together while remaining modular and configurable.

---

# Project Philosophy

FORGE is built around one simple idea:

> **Every technical decision should ultimately improve the player's experience.**

The project also values:

- Maintainability
- Documentation
- Long-term sustainability
- Open source collaboration

The goal is to ensure that even if the original creators move on, the community can continue to build upon FORGE for years to come.

---

# Current Status

**Development Stage**

Active development

The ForgeOS foundation is complete. Development is currently focused on the
M3 Communications system that uses that foundation.

---

# Current milestone

**M3 — Communications**

M3.001 through M3.004 are implemented, runtime verified, accepted, and frozen
within their bounded scopes. FORGE now has authoritative received-message
storage and persistence, a built-in Communications application, detached
inbox/detail presentation models, unread badges, declared application actions,
and ForgeOS-mediated navigation.

M3.005 — Notification Integration, M3.006 — Phone Communications UI, and
M3.007 — Laptop Communications UI are implemented, runtime verified,
accepted, and frozen within their bounded scopes. M3.008 — End-to-End
Verification and Polish passed its unchanged-package two-cycle gate. M3.008
and overall M3 are accepted and frozen within their bounded scopes.

# Repository Structure

```text
engine/         Authoritative FORGE engine source
tests/          Engine test harnesses
tools/          Developer tooling
docs/           Architecture and engineering documentation
prototype/      Synchronised FS25 reference implementation
campaigns/      Campaign content
sdk/            Creator SDK
themes/         Phone OS themes
assets/         Shared project assets
```

The `engine/` directory is the single source of truth.

Changes are synchronised into the prototype using the FORGE Synchronisation Tool.

---

# Who is FORGE for?

## Players

Install FORGE to experience a richer, more connected Farming Simulator world.

No programming knowledge required.

---

## Modders

Create your own:

- Campaigns
- Companies
- Phone applications
- Projects
- Themes
- Gameplay extensions

without modifying the core engine.

---

## Contributors

Help improve the engine itself.

The project welcomes contributors who share our passion for maintainable, well-documented software.

---

# Documentation

The project documentation is organised under `docs/`.

Recommended reading order:

1. Project Vision
2. Engineering Charter
3. Engineering Guide
4. Engine Architecture
5. Startup Lifecycle
6. Roadmap
7. Contributing

---

# Core Principles

- Player-first design
- Design before construction
- Documentation is part of the product
- Prefer explicit dependencies
- Leave it better than you found it
- Build for the long term

---

# License

FORGE is distributed under the terms recorded in [LICENSE](LICENSE).

---

# Thank You

Whether you're here to play, create, or contribute—

**Welcome to FORGE.**
