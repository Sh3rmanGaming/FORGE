# ADR-001 - Use Dedicated Definition Tables

**Status:** Accepted  
**Date:** 2026-08-01

---

## Context

FORGE requires many shared values that are referenced throughout the engine.

Examples include:

- Log sources
- Event names
- Project statuses
- Company roles
- Phone applications
- Notification types
- Save versions
- Permission levels

Using literal strings or numeric values throughout the codebase introduces unnecessary risk, including:

- Typographical errors
- Inconsistent naming
- Difficult refactoring
- Poor editor autocompletion
- Harder debugging

To maintain consistency and improve long-term maintainability, these shared values require a single authoritative source.

---

## Options Considered

### Option A — Use Literal Values

Use literal strings and numeric values directly throughout the codebase.

#### Advantages

- Fast to write initially
- No additional files

#### Disadvantages

- Error-prone
- Difficult to maintain
- Difficult to search
- No single source of truth
- Inconsistent naming becomes likely

---

### Option B — Use One Global Constants File

Create a single global `Constants.lua` file containing every shared value.

#### Advantages

- One central location
- Easy to discover

#### Disadvantages

- Becomes a dumping ground
- Violates the Single Responsibility Principle
- Difficult to navigate as the project grows
- Creates unnecessary coupling between unrelated systems

---

### Option C — Use Dedicated Definition Tables (Chosen)

Create dedicated definition files for each logical group.

Example:

```text
engine/
└── definitions/
    ├── Event.lua
    ├── LogLevel.lua
    ├── LogSource.lua
    ├── NotificationType.lua
    ├── PhoneApp.lua
    └── ProjectStatus.lua
```

Each definition file owns a single logical responsibility and acts as the authoritative source for that category.

---

## Decision

FORGE shall not use magic values where an authoritative definition exists.

Every shared value shall have one authoritative definition.

Definition tables shall be grouped by purpose rather than collected into a monolithic constants file.

---

## Consequences

### Positive

- Better editor autocompletion
- Easier refactoring
- Easier debugging
- Improved readability
- Consistent naming across the engine
- Reduced human error
- Clear ownership of shared values

### Negative

- Increased number of files
- Slightly longer initial development
- Engine startup must load definition tables before dependent systems

The long-term maintenance and scalability benefits outweigh the additional structure.

---

## Future Review

This decision should be reconsidered if Lua, the Farming Simulator scripting environment, or the FORGE architecture introduces a more maintainable mechanism for defining shared authoritative values.

At the time of writing, dedicated definition tables provide the clearest, most maintainable, and most scalable solution.