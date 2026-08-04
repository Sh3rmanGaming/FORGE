---=============================================================================
--- FORGE ForgeOS Phase Definitions
---
--- Defines the authoritative operating phases used by ForgeOS.
---
--- Responsibilities:
---     • Define ForgeOS startup phases.
---     • Define the addon registration lifecycle.
---     • Define ForgeOS runtime and shutdown phases.
---
--- This file must never contain runtime behaviour.
---=============================================================================

FORGE.Definitions.ForgeOSPhase = {

    UNAVAILABLE = "unavailable",

    INITIALISING = "initialising",

    REGISTRATION_OPEN = "registrationOpen",

    VALIDATING = "validating",

    REGISTRATION_FROZEN = "registrationFrozen",

    RUNTIME_ACTIVE = "runtimeActive",

    SHUTTING_DOWN = "shuttingDown",

    STOPPED = "stopped"
}