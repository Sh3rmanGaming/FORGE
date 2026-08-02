---=============================================================================
--- FORGE Event Bus
---
--- Allows FORGE systems to communicate without directly depending on each other.
---
--- Responsibilities:
---     • Register event listeners
---     • Publish events
---     • Remove listeners
---     • Clear listeners during shutdown
---
--- This class should never contain gameplay logic.
---=============================================================================

FORGE.EventBus = {}

FORGE.EventBus = {
    listeners = {}
}