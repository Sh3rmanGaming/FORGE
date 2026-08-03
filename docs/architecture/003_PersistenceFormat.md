# 003 - Persistence Format

**Status:** Draft  
**Version:** 1.0

---

# Purpose

This document defines the persistence format used by the FORGE Engine.

It establishes the contract between the following engine services:

- SaveManager
- XMLWriter
- XMLReader

By defining the persistence format separately from its implementation, the engine can evolve its persistence system without changing gameplay systems or State Store behaviour.

---

# Scope

This document defines:

- The structure of `forge.xml`
- Persistent namespace representation
- Supported data types
- Table serialization rules
- Save versioning
- Loading expectations
- Validation requirements

This document does **not** define:

- Which namespaces should be persisted
- Gameplay data structures
- Multiplayer synchronization
- Save timing
- State Store implementation

---

# Related Documents

- 000 - Project Vision
- 001 - Engine Architecture
- 002 - Startup Lifecycle
- ADR-002 - Separate XML Reader and XML Writer

---

# Design Goals

The persistence system is designed to be:

- Human readable
- Deterministic
- Versioned
- Extensible
- Multiplayer-safe
- Independent of gameplay systems

Persistence should preserve runtime state while remaining understandable during debugging and development.

---

# Save File Location

FORGE stores its persistent state inside the active Farming Simulator savegame.

```
savegame*/
└── forge.xml
```

The save file is owned entirely by FORGE.

No other engine systems should write directly to this file.

---

# Root Structure

Every FORGE save file begins with a single root element.

```xml
<forge version="1">

</forge>
```

## Root Attributes

| Attribute | Type | Required | Description |
|-----------|------|----------|-------------|
| version | Integer | Yes | FORGE persistence format version |

The version refers to the persistence format rather than the engine version.

---

# Namespace Layout

Persistent State Store namespaces are stored beneath a namespace container.

```xml
<forge version="1">

    <namespaces>

        <namespace name="projects">

        </namespace>

        <namespace name="companies">

        </namespace>

    </namespaces>

</forge>
```

Each namespace represents one registered State Store namespace.

Namespace names must be unique.

---

# Value Representation

Each value is represented using a `<value>` element.

Primitive values store:

- key
- type
- value

Example:

```xml
<value
    key="companyName"
    type="string"
    value="Beer Contracting"/>
```

---

# Supported Types

FORGE Version 1 supports the following persistent types.

## String

```xml
<value
    key="name"
    type="string"
    value="FORGE"/>
```

---

## Number

```xml
<value
    key="balance"
    type="number"
    value="25000"/>
```

Numbers are stored using Lua numeric precision.

---

## Boolean

```xml
<value
    key="enabled"
    type="boolean"
    value="true"/>
```

---

## Table

Tables contain nested values.

Example:

```xml
<value
    key="settings"
    type="table">

    <value
        key="enabled"
        type="boolean"
        value="true"/>

    <value
        key="difficulty"
        type="string"
        value="normal"/>

</value>
```

Tables may contain additional nested tables.

---

# Table Rules

Tables must satisfy the following requirements.

## Allowed

- Nested tables
- Strings
- Numbers
- Booleans

## Not Allowed

- Functions
- Threads
- Userdata
- Nil values
- Cyclic references
- Non-string keys
- NaN
- Positive infinity
- Negative infinity

Namespaces containing unsupported values are considered invalid and cannot be saved.

---

# Deterministic Ordering

Namespaces are written alphabetically.

Table keys are written alphabetically.

Deterministic ordering provides:

- Stable save files
- Reliable comparisons
- Easier debugging
- Predictable testing

Ordering has no semantic meaning.

---

# Empty Namespaces

Registered persistent namespaces are written even when they contain no values.

Example:

```xml
<namespace name="projects"/>
```

Writing empty namespaces preserves registration intent and guarantees consistent save/load behaviour.

---

# Versioning

The persistence version is independent of the FORGE engine version.

Example:

```
FORGE Engine 0.5.0
Persistence Version 1
```

Future persistence changes must increase the persistence version.

Version migration is the responsibility of SaveManager.

---

# XML Writer Responsibilities

XMLWriter is responsible for:

- Creating forge.xml
- Writing version metadata
- Writing namespaces
- Writing values
- Writing nested tables
- Saving the XML document
- Releasing XML resources

XMLWriter must not access gameplay systems directly.

---

# XML Reader Responsibilities

XMLReader is responsible for:

- Opening forge.xml
- Reading version metadata
- Reading namespaces
- Reading values
- Reconstructing nested Lua tables
- Returning decoded data
- Releasing XML resources

XMLReader must not modify the State Store.

---

# Save Manager Responsibilities

SaveManager coordinates persistence.

Responsibilities include:

- Registering persistent namespaces
- Validating persistent namespaces
- Invoking XMLWriter
- Invoking XMLReader
- Applying loaded state
- Version compatibility
- Migration management

SaveManager owns persistence policy.

It does not own XML serialization.

---

# Loading Behaviour

The loading process follows this sequence.

```
Load XML

↓

Validate XML

↓

Validate Version

↓

Decode XML

↓

Return Lua Tables

↓

SaveManager validates data

↓

StateStore updated
```

If validation fails at any stage, no runtime state should be modified.

---

# Missing Save File

A missing `forge.xml` is considered valid.

This occurs when:

- Creating a new savegame
- FORGE has never stored persistent data

No errors should be generated.

---

# Invalid Save File

Malformed or unsupported save files must:

- Produce a descriptive error
- Abort loading
- Preserve existing runtime state

Partial loads are not permitted.

---

# Example Document

```xml
<?xml version="1.0" encoding="utf-8"?>

<forge version="1">

    <namespaces>

        <namespace name="companies">

            <value
                key="activeCompany"
                type="string"
                value="beerContracting"/>

            <value
                key="settings"
                type="table">

                <value
                    key="enabled"
                    type="boolean"
                    value="true"/>

                <value
                    key="startingBalance"
                    type="number"
                    value="25000"/>

            </value>

        </namespace>

        <namespace name="projects">

            <value
                key="selectedProject"
                type="string"
                value="farmExpansion"/>

        </namespace>

    </namespaces>

</forge>
```

---

# Future Considerations

Future persistence versions may introduce:

- Save compression
- Additional primitive types
- Object references
- Schema migration
- Partial namespace loading
- Integrity verification
- Save metadata
- Checksums
- Incremental persistence

These features should preserve backwards compatibility wherever practical.

---

# Summary

The FORGE persistence format provides a deterministic, versioned, human-readable representation of approved State Store namespaces.

This document defines the persistence contract implemented by XMLWriter and XMLReader and coordinated by SaveManager.

Future persistence changes should extend this specification through versioned revisions while maintaining compatibility with existing savegames whenever possible.