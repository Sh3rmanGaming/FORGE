# FORGE Coding Standards

## Purpose

This document defines the coding standards used throughout the FORGE project.

The objective is not to enforce personal preferences, but to establish a consistent style that keeps the codebase readable, maintainable, and approachable for all contributors.

Where no specific rule exists, contributors should follow the principles defined in the Engineering Charter.

---

## Core Principles

- Write code for humans first.
- Prefer clarity over cleverness.
- Every file should have a single responsibility.
- Prefer explicit dependencies.
- Leave the codebase better than you found it.

---

## Naming

- Tables use `PascalCase`.
- Functions use `camelCase`.
- Local variables use `camelCase`.
- Constants and definitions use descriptive names rather than abbreviations.
- Avoid unexplained abbreviations.

---

## File Structure

A source file should generally contain:

1. Header comment.
2. Table declaration.
3. Constants.
4. Public functions.
5. Private helper functions.
6. Registration (if required).

---

## Comments

Comments should explain **why**, not repeat **what** the code already says.

Use comments to document:

- Design decisions.
- Non-obvious behaviour.
- Engine limitations.
- Assumptions.

Avoid comments that simply describe the next line of code.

---

## Error Handling

- Fail early where practical.
- Log meaningful errors.
- Avoid silently ignoring failures.
- Prefer clear error messages over generic ones.

---

## Definitions

Do not use magic values where an authoritative definition exists.

Shared values belong in dedicated definition tables.

---

## Documentation

Public systems should be documented.

All source files should include the standard FORGE file header.

Major architectural decisions should be recorded as ADRs.

---

## Formatting

The FORGE project follows consistent formatting to maximise readability.

- Use 4 spaces for indentation.
- Wrap long lines where practical to improve readability.
- Group related code with a single blank line.
- Avoid excessive vertical whitespace.
- Keep functions reasonably small and focused.
  
---

## Functions

Functions should:

- Perform one clearly defined task.
- Validate inputs where practical.
- Return early when invalid conditions are detected.
- Avoid unnecessary nesting.
- Remain small enough to understand without scrolling extensively.