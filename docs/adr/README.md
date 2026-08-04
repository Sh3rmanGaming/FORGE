# Architecture Decision Records (ADRs)

This directory contains the Architecture Decision Records (ADRs) for the FORGE project.

ADRs document significant architectural decisions that affect the design, implementation, and long-term maintenance of the engine. Each ADR captures not only the decision that was made, but also the context, alternatives that were considered, and the consequences of that decision.

## Purpose

The goals of the ADR system are to:

- Record why important decisions were made.
- Prevent the same discussions from being repeated.
- Provide historical context for future contributors.
- Improve consistency across the project.
- Make architectural trade-offs explicit.

## ADR Lifecycle

Each ADR progresses through one of the following states:

| Status | Description |
|---------|-------------|
| Proposed | Under discussion and not yet accepted. |
| Accepted | Approved and part of the current architecture. |
| Superseded | Replaced by a newer ADR. |
| Deprecated | No longer recommended but retained for historical reference. |

ADRs are never deleted. If a decision changes, a new ADR should supersede the previous one.

## Naming Convention

ADRs use sequential numbering.

Example:

```text
ADR-001-Definitions.md
ADR-002-Logging.md
ADR-003-EventBus.md
```

Numbers are never reused, even if an ADR is later superseded.

## ADR Template

Each ADR should contain the following sections:

1. Context
2. Options Considered
3. Decision
4. Consequences
5. Future Review (optional)

Additional sections may be added where appropriate if they improve clarity.

## Current ADRs

| ADR | Title | Status |
|-----|-------|--------|
| [ADR-001](ADR-001-Definitions.md) | Use Dedicated Definition Tables | Accepted |
| [ADR-002](docs/ADR/ADR-002-Separate-Persistence-Reader-and-Writer.md) | Separate Persistence Reading and Writing | Accepted |

As new ADRs are created, update this table to provide a quick index of the project's architectural history.

ADR-002 remains in its current legacy nested location. Its location is indexed
here for discoverability; no file move is implied.
