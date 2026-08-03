# FORGE Roadmap

**Status:** Active  
**Last Updated:** 2026-08-03

---

## Overall Progress

| Milestone | Status |
|-----------|--------|
| M0 – Foundation | ✅ Complete |
| M1 – Engine | 🟡 In Progress |
| M2 – Phone OS | ⬜ Planned |
| M3 – Communications | ⬜ Planned |
| M4 – Projects | ⬜ Planned |
| M5 – Banking | ⬜ Planned |
| M6 – Companies | ⬜ Planned |
| M7 – Campaign SDK | ⬜ Planned |
| M8 – Public Release | ⬜ Planned |

---

## Current Milestone — M1: Engine

# FORGE Development Roadmap

## Completed

- ✅ M1.001 – Definitions
- ✅ M1.002 – Logger Definitions
- ✅ M1.003 – Logging Service
- ✅ M1.004 – Synchronisation Tool
- ✅ M1.004.01 – Recursive Synchronisation
- ✅ M1.005 – Event Bus
- ✅ M1.006 – State Store

---

## In Progress

### 🟡 M1.007 – Persistence

#### ✅ M1.007.01 – XML Writer
- Deterministic XML generation
- Nested table serialization
- Supported type serialization
- Invalid document validation
- XML writer test suite

#### ✅ M1.007.02 – XML Reader
- XML document deserialization
- Recursive value reconstruction
- Type decoding
- Structure validation
- XML reader test suite

#### ✅ M1.007.03 – Save Manager Integration
- Namespace registration
- Persistence validation
- StateStore snapshot integration
- XML Writer integration
- XML Reader integration
- StateStore restore integration
- Save Manager test suite
- Integration test framework

#### ✅ M1.007.04 – End-to-End Persistence Verification

- ✅ M1.007.04.01 – Save Manager Round-Trip Verification
- ✅ M1.007.04.02 – FS25 Save Lifecycle Integration
- ✅ M1.007.04.03 – Production Engine Persistence Namespace

- ✅ M1.007.04.04 – Save Count Mutation
  - Increment save counter on every successful save.
  - Verify persistence across multiple saves.

- ✅ M1.007.04.05 – First Run State Mutation
  - Automatically transition `firstRun` from true to false.
  - Verify state survives reload.

- ✅ M1.007.04.06 – Real Savegame Reload Verification
  - Save game.
  - Exit to menu.
  - Reload save.
  - Verify complete runtime restoration.

- ✅ M1.007.04.07 – Repeated Save Verification
  - Verify repeated saves.
  - Verify no duplicate callbacks.
  - Verify no duplicate writes.

#### ⏳ M1.007.05 – Persistence Polish

- Remove temporary engine diagnostics.
- Finalise XML schema documentation.
- Finalise persistence lifecycle documentation.
- Finalise Save Manager documentation.
- Final code review.
- Freeze persistence API.

---

## Planned

### ⏳ M1.008 – Campaign Manager
- Campaign lifecycle
- Save slot abstraction
- World metadata
- Campaign registry

### ⏳ M1.009 – Phone OS Foundation
- Operating system bootstrap
- Application lifecycle
- Window management
- UI framework integration

### ⏳ M1.010 – Engine Bootstrap
- Module discovery
- Module registration
- Dependency ordering
- Engine startup pipeline
- Engine shutdown pipeline

---

# Milestone Exit Criteria

## M1.007 – Persistence

Persistence is considered complete when:

- ✅ State Store namespaces can be registered.
- ✅ XML documents are written deterministically.
- ✅ XML documents are read deterministically.
- ✅ Strings, numbers, booleans and nested tables survive round-trip serialization.
- ✅ Empty namespaces are supported.
- ✅ Unsupported, cyclic and non-finite values are rejected.
- ✅ Missing persistence files are handled safely.
- ⏳ Save version compatibility is enforced.
- ✅ SaveManager integrates XML Reader and XML Writer.
- ✅ Engine hooks into the FS25 save lifecycle.
- ⏳ `saveCount` persists and increments exactly once per save.
- ⏳ `firstRun` automatically transitions after the first successful save.
- ⏳ Runtime state is restored after exiting and reloading a savegame.
- ⏳ Multiple saves during one session remain deterministic.
- ⏳ Persistence documentation is complete.

---

# Milestone Vision

**M1 delivers the complete FORGE engine foundation.**

By the completion of Milestone 1, FORGE will provide:

- Logging
- Event dispatching
- Shared runtime state
- Deterministic persistence
- Automatic save/load integration with Farming Simulator
- Engine lifecycle management
- A stable platform upon which all future gameplay systems can be built

From this point onward, future milestones focus on building gameplay features **using** the engine rather than expanding the engine itself.

---

## Future Milestones

Future milestones will be expanded as they become active.

Only the current milestone contains detailed implementation tasks to keep this roadmap concise and easy to maintain.