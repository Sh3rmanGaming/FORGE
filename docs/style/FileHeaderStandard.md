# FORGE File Header Standard

## Purpose

This document defines the standard header format used throughout the FORGE project.

Every source file should communicate its purpose before the reader reaches the implementation.

Good headers reduce onboarding time, improve maintainability and clearly define a file's responsibilities.

---

# General Principles

Every header should answer four questions:

1. What is this file?
2. Why does it exist?
3. What is it responsible for?
4. What is it not responsible for?

Headers should describe intent, not implementation.

Implementation details belong within the code.

---

# Lua Files

```lua
---=============================================================================
--- FORGE Logging Service
---
--- Provides structured diagnostic logging for the FORGE Engine.
---
--- Responsibilities:
---     • Validate log levels.
---     • Validate log sources.
---     • Format log messages.
---     • Write diagnostics.
---
--- This service must never contain gameplay logic.
---=============================================================================
```

---

# Python Files

```python
"""
=============================================================================
FORGE Synchronisation Tool

Purpose:
    Synchronises the authoritative FORGE engine source into the prototype
    reference implementation.

Responsibilities:
    • Validate repository structure.
    • Synchronise engine files.
    • Synchronise test files.
    • Report synchronisation results.

Design Principles:
    • Repository is the source of truth.
    • Synchronisation is repeatable.
    • Synchronisation is idempotent.
    • Fail early with clear diagnostics.

This tool is part of the FORGE developer toolchain.
=============================================================================
"""
```

---

# Markdown Documents

Every document should begin with:

- Title
- Purpose
- Scope (when appropriate)
- Status (Draft, Review, Approved, Implemented or Verified where applicable)

Example:

```markdown
# Startup Lifecycle

## Purpose

Describe the runtime startup sequence of the FORGE Engine.

## Status

Approved
```

---

# XML Files

XML should include comments describing the section's purpose where appropriate.

Example:

```xml
<!--
    FORGE Lua Load Order

    Files are listed in dependency order.
    Earlier files must not depend on later files.
-->
```

---

# Responsibilities

Headers describe:

- Purpose
- Responsibilities
- Constraints

Headers should not duplicate implementation details.

---

# Principles

A good header should:

- Explain intent.
- Define responsibility.
- Be concise.
- Be maintained alongside the file.

If a file's purpose changes, its header must be updated as part of the same change.
