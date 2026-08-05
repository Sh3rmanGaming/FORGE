---=============================================================================
--- FORGE Application Lifecycle State Definitions
---
--- Authoritative application lifecycle state identifiers used by ForgeOS.
---
--- Responsibilities:
---     • Define application runtime lifecycle states.
---     • Provide stable identifiers for lifecycle transitions.
---
--- This file must contain definitions only.
---=============================================================================

FORGE.Definitions.AppLifecycleState = {

    CLOSED = "closed",

    OPEN = "open",

    ACTIVE = "active",

    BACKGROUND = "background"
}
