# ADR-001 - Shared Definitions

**Status:** Accepted

**Date:** 2026-08-01

**Confidence:** 100%

---

# Context

FORGE requires many shared values that will be referenced throughout the engine.

Examples include:

- Log Sources
- Event Names
- Project Statuses
- Company Roles
- Phone Applications
- Notification Types
- Save Versions
- Permission Levels

Using literal strings or numbers throughout the codebase introduces unnecessary risk.

Examples include:

- Typographical errors
- Inconsistent naming
- Difficult refactoring
- Poor auto-completion
- Harder debugging

---

# Options Considered

## Option A

Use literal strings and numbers throughout the code.

### Advantages

- Fast to write

### Disadvantages

- Error prone
- Difficult to maintain
- Difficult to search
- No single source of truth

---

## Option B

Create a single global Constants.lua file.

### Advantages

- Central location

### Disadvantages

- Becomes a dumping ground
- Violates the Single Responsibility Principle
- Difficult to navigate
- Creates unnecessary coupling

---

## Option C (Chosen)

Create dedicated definition files for each logical group.

Examples:

engine/definitions/

- LogSource.lua
- Event.lua
- ProjectStatus.lua
- PhoneApp.lua
- CompanyRole.lua

Each file owns one responsibility only.

---

# Decision

FORGE will never use magic values where a reusable definition exists.

Every shared value shall have one authoritative definition.

Definition files shall be grouped by purpose rather than collected into a monolithic constants file.

---

# Consequences

## Positive

- Better IntelliSense
- Easier refactoring
- Easier debugging
- Improved readability
- Consistent naming
- Reduced human error

## Negative

- More files
- Slightly longer initial development

The long-term maintenance benefits outweigh the additional structure.

---

# Future Review

This decision should only be reconsidered if Lua gains native enum support or another language feature that makes dedicated definition tables obsolete.

At the time of writing, dedicated definition tables provide the cleanest and most maintainable solution.