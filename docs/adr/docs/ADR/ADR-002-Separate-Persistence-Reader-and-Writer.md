# ADR-002 - Separate Persistence Reading and Writing

**Status:** Accepted  
**Date:** 2026-08-02

---

## Context

FORGE requires persistent runtime state to be written into and loaded from the active Farming Simulator savegame.

The Save Manager is responsible for deciding:

- Which State Store namespaces are persistent.
- Whether persistent state is valid.
- When save and load operations occur.
- Whether loaded data should be applied to runtime state.
- Which save format version is supported.

Actual XML encoding and decoding introduce a separate set of responsibilities.

These include:

- Creating and opening XML resources.
- Writing primitive values.
- Writing nested tables.
- Reading and validating XML nodes.
- Decoding stored value types.
- Handling malformed XML.
- Managing XML resource cleanup.
- Preserving deterministic output.

Implementing all of these behaviours directly inside the Save Manager would give one service multiple unrelated responsibilities and tightly couple persistence policy to the XML storage format.

---

## Options Considered

### Option A – Implement XML Reading and Writing Inside Save Manager

The Save Manager directly performs all XML encoding and decoding.

#### Advantages

- Fewer files.
- Faster initial implementation.
- All persistence code is located in one service.

#### Disadvantages

- Mixes persistence policy with storage implementation.
- Causes the Save Manager to grow rapidly.
- Makes testing more difficult.
- Creates strong coupling to XML.
- Makes future format changes harder.
- Violates the Single Responsibility Principle.

---

### Option B – Use One Shared XML Serializer

Create one serializer module responsible for both reading and writing XML.

#### Advantages

- Separates XML handling from Save Manager.
- Reduces Save Manager complexity.
- Keeps persistence format logic in one place.

#### Disadvantages

- Reading and writing remain combined despite having different failure modes.
- The module may become large and difficult to navigate.
- Loading requires defensive parsing while saving requires deterministic output.
- Changes to one direction may unintentionally affect the other.

---

### Option C – Use Separate XML Reader and XML Writer Modules

Create dedicated modules for XML reading and XML writing.

```text
engine/
└── services/
    ├── SaveManager.lua
    └── persistence/
        ├── XMLReader.lua
        └── XMLWriter.lua
```

#### Advantages

- Each module has one clear responsibility.
- Save Manager remains focused on orchestration and policy.
- XML encoding and decoding can be tested independently.
- Reading and writing may evolve separately.
- Malformed-file handling remains isolated within the reader.
- Deterministic output remains isolated within the writer.
- Future storage formats can be introduced with less disruption.

#### Disadvantages

- More files.
- Slightly more initial implementation work.
- Requires clear interfaces between the modules.

---

## Decision

FORGE will separate persistence coordination, XML writing, and XML reading.

The responsibilities are divided as follows.

### Save Manager

The Save Manager shall:

- Register State Store namespaces for persistence.
- Validate persistent runtime state.
- Resolve the FORGE save-file path.
- Coordinate save and load operations.
- Enforce supported save-format versions.
- Decide when decoded data is applied to the State Store.
- Delegate XML encoding and decoding.

The Save Manager must not directly implement XML serialization or deserialization.

---

### XML Writer

The XML Writer shall:

- Create the FORGE XML document.
- Write save-format metadata.
- Serialize registered namespaces.
- Serialize supported primitive values.
- Serialize supported nested tables.
- Produce deterministic output.
- Save and release XML resources safely.

The XML Writer must not modify State Store data or decide which namespaces are persistent.

---

### XML Reader

The XML Reader shall:

- Open an existing FORGE XML document.
- Read save-format metadata.
- Validate XML structure and stored types.
- Decode primitive values and nested tables.
- Reject malformed or unsupported data.
- Return decoded data without directly modifying the State Store.
- Release XML resources safely.

The XML Reader must not decide whether decoded data should be applied to runtime state.

---

## Data Flow

Saving follows this sequence:

```text
State Store
    │
    ▼
Save Manager
    │
    ▼
XML Writer
    │
    ▼
forge.xml
```

Loading follows this sequence:

```text
forge.xml
    │
    ▼
XML Reader
    │
    ▼
Save Manager
    │
    ▼
State Store
```

Decoded data must be returned to the Save Manager before any live State Store namespace is modified.

This allows the Save Manager to reject incomplete or invalid load results without corrupting existing runtime state.

---

## Consequences

### Positive

- Save Manager remains small and focused.
- XML implementation details are isolated.
- Reader and writer can be tested independently.
- Persistence failure handling becomes clearer.
- Future save-format migrations are easier to introduce.
- Future storage formats can be added without rewriting persistence policy.
- Contributors can immediately identify where persistence code belongs.

### Negative

- Additional files and interfaces are required.
- Initial implementation takes longer.
- Reader and writer contracts must remain aligned with the same save format.

The long-term maintainability benefits outweigh the additional initial structure.

---

## Implementation Constraints

- XML modules shall be located beneath `engine/services/persistence/`.
- XML Reader and XML Writer shall not own gameplay state.
- XML Reader shall not directly modify the State Store.
- XML Writer shall not determine which namespaces are persistent.
- Save Manager shall remain the only persistence coordinator.
- Reader and Writer must share the same authoritative save-format version.
- Significant changes to this responsibility boundary require a new ADR.

---

## Future Review

This decision should be reviewed if:

- FORGE replaces XML with another primary persistence format.
- The GIANTS Engine introduces a higher-level persistence API that makes the separation unnecessary.
- Reader and Writer responsibilities become demonstrably simpler when implemented together.

Until then, separate XML Reader and XML Writer modules remain the approved architecture.