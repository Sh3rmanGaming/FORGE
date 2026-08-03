# FORGE Save Manager

**Version:** 1.0  
**Status:** Stable  
**Module:** SaveManager

---

# Purpose

The Save Manager coordinates all persistence operations within the FORGE Engine.

It acts as the bridge between runtime state and persistent storage while
remaining completely independent of gameplay systems.

The Save Manager owns persistence coordination but does not own runtime state
or XML serialization.

---

# Responsibilities

The Save Manager is responsible for:

- registering persistent namespaces
- validating persistent state
- constructing persistence documents
- loading persistence documents
- restoring runtime state
- validating persistence versions

The Save Manager never performs XML serialization itself.

---

# Architectural Position

```
Gameplay Systems
        │
        ▼
   State Store
        │
        ▼
  Save Manager
     ▲     ▼
XMLReader XMLWriter
        │
        ▼
    forge.xml
```

The Save Manager is the only component that communicates with both the runtime
State Store and the XML persistence layer.

---

# Public API

## registerNamespace(namespace)

Registers an existing State Store namespace for persistence.

Requirements:

- namespace must exist
- namespace must be registered only once

Returns:

- true on success
- false on failure

---

## isNamespaceRegistered(namespace)

Returns whether a namespace is currently registered for persistence.

Returns:

- true
- false

---

## validateNamespace(namespace)

Verifies that every value inside the namespace can be safely persisted.

Validation includes:

- supported value types
- finite numeric values
- recursive tables
- cyclic table detection

Returns:

- true
- false

---

## save(saveDirectory)

Creates a persistence document from every registered namespace.

Workflow:

```
Registered Namespaces
        │
        ▼
Snapshot State Store
        │
        ▼
Validate and Detach Values
        │
        ▼
Build Persistence Document
        │
        ▼
XML Writer
        │
        ▼
forge.xml
```

Returns:

- true if the save completed successfully
- false if any stage failed

If saving fails, no runtime state is modified.

---

## load(saveDirectory)

Loads persistent state from the savegame.

Workflow:

```
forge.xml
      │
      ▼
 XML Reader
      │
      ▼
Validate Version
      │
      ▼
Prepare Namespaces
      │
      ▼
Replace Runtime State
```

Returns:

- true if loading completed successfully
- false otherwise

If loading fails, the existing runtime state remains active.

---

# Namespace Registration

Only namespaces explicitly registered with the Save Manager are persisted.

Example:

```lua
FORGE.StateStore:register("forge.engine")

FORGE.SaveManager:registerNamespace(
    "forge.engine"
)
```

This explicit registration prevents accidental persistence of temporary runtime
data.

---

# Validation Rules

The Save Manager accepts:

- strings
- numbers
- booleans
- nested tables

The Save Manager rejects:

- functions
- userdata
- threads
- cyclic tables
- NaN
- positive infinity
- negative infinity

Tables are persisted as plain data. Metatables and their behaviour are not
serialized or restored.

---

# Error Handling

Save failures

- validation failure
- XML creation failure
- XML write failure
- XML save failure

Load failures

- persistence file access failure
- unsupported schema version
- malformed XML
- invalid decoded runtime data
- namespace application failure

A missing persistence document is not considered an error. In that case, the
current State Store values are preserved so newly created savegames can continue
using their registered defaults.

Errors are logged through the Logger service.

Runtime state is never partially modified.

---

# Design Principles

The Save Manager follows several architectural rules.

## Own coordination

The Save Manager coordinates persistence.

It does not own runtime data.

---

## Never own gameplay

Gameplay systems remain completely unaware of persistence.

Modules store and retrieve runtime data through the State Store.

A module that requires persistence must also register its existing State Store
namespace with the Save Manager during initialisation. It does not call the XML
Reader or XML Writer directly.

---

## Generic implementation

The Save Manager contains no gameplay-specific logic.

It has no knowledge of:

- campaigns
- contracts
- economy
- projects
- missions

---

## Deterministic behaviour

Repeated saves of identical runtime state produce identical persistence
documents.

---

## Safe failure

Failures never leave runtime state partially updated.

Either an entire persistence operation succeeds or no changes are applied.

---

# Integration

The Save Manager depends upon:

- State Store
- XML Writer
- XML Reader
- Logger

It does not depend upon any gameplay module.

---

# Future Extensions

The current implementation supports Persistence Version 1.

Future versions may introduce:

- schema migration
- selective namespace upgrades
- backward compatibility
- incremental persistence

These features should be implemented without changing the Save Manager public
API.

---

# Stability

The Save Manager was completed during:

**M1.007 – Persistence**

Its public API is considered stable.

Future changes should preserve backward compatibility wherever practical.