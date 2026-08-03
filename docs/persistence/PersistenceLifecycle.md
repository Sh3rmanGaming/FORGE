# FORGE Persistence Lifecycle

**Version:** 1.0  
**Status:** Stable  
**Applies To:** M1.007 Persistence

---

# Purpose

The FORGE persistence system provides deterministic save and load behaviour for
all engine modules.

Its purpose is to ensure that runtime state survives savegame reloads while
keeping gameplay systems completely isolated from Farming Simulator's native
save implementation.

The persistence system is intentionally generic.

Individual modules never write XML directly.

Instead they register persistent namespaces with the Save Manager, which
coordinates all persistence operations.

---

# Design Goals

The persistence system was designed around the following principles.

- Multiplayer-first.
- Deterministic output.
- Generic implementation.
- Data-driven architecture.
- Module independence.
- Minimal engine coupling.
- Safe failure handling.

---

# Lifecycle Overview

Mission Startup

```
Engine
    │
    ▼
Register Engine State
    │
    ▼
Register Persistent Namespaces
    │
    ▼
Load forge.xml
    │
    ▼
XMLReader
    │
    ▼
SaveManager
    │
    ▼
StateStore
    │
    ▼
Gameplay Systems
```

---

Mission Save

```
Gameplay State
    │
    ▼
StateStore
    │
    ▼
SaveManager
    │
    ▼
XMLWriter
    │
    ▼
forge.xml
```

---

Mission Shutdown

```
Gameplay Ends
    │
    ▼
Clear Event Bus
    │
    ▼
Clear State Store
    │
    ▼
Clear Persistence Registrations
```

---

# Component Responsibilities

## Engine

Responsible for:

- registering engine state
- installing the save hook
- coordinating load
- coordinating save
- coordinating shutdown

The engine never serialises XML.

---

## State Store

Responsible for runtime data ownership.

The State Store:

- owns all runtime namespaces
- provides snapshots
- provides deep copies
- isolates modules

The State Store never performs persistence.

---

## Save Manager

Responsible for persistence coordination.

The Save Manager:

- registers persistent namespaces
- validates persistent state
- builds persistence documents
- restores runtime state

The Save Manager never performs XML serialisation.

---

## XML Writer

Responsible for deterministic XML output.

The XML Writer:

- serialises approved persistence documents
- writes version information
- writes namespaces
- writes values

The XML Writer has no knowledge of gameplay systems.

---

## XML Reader

Responsible for deterministic XML reconstruction.

The XML Reader:

- loads forge.xml
- validates document structure
- reconstructs runtime values
- returns persistence documents

The XML Reader never modifies runtime state.

---

# Data Ownership

Runtime data always flows through one direction.

```
Gameplay
    ↓
State Store
    ↓
Save Manager
    ↓
XML Writer
    ↓
forge.xml
```

Loading follows the reverse direction.

```
forge.xml
    ↓
XML Reader
    ↓
Save Manager
    ↓
State Store
    ↓
Gameplay
```

---

# Failure Behaviour

If persistence loading fails:

- engine startup continues
- the previously active runtime state is preserved
- no partially loaded namespaces remain applied
- an error is logged

For a new savegame with no `forge.xml`, registered default state is preserved and
the missing file is treated as a normal first-run condition.

If persistence saving fails:

- runtime state is restored
- no partial save is committed
- an error is logged

---

# Architectural Rules

The persistence system follows these rules.

1. Gameplay systems never access XML.
2. Gameplay systems never serialize data.
3. XML components never know gameplay systems.
4. State Store owns runtime data.
5. Save Manager owns persistence coordination.
6. XML components own persistence format.
7. Engine owns lifecycle coordination.

These rules form the architectural contract for all future FORGE modules.

---

# Milestone Status

Implemented during:

**M1.007 – Persistence**

Verified by:

- XML Writer tests
- XML Reader tests
- Save Manager tests
- Integration tests
- Production save/load verification
- Multiple save verification
- Reload verification

Persistence is considered production ready and forms the foundation for all
future FORGE modules.