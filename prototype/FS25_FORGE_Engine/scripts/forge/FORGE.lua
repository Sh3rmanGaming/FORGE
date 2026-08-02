---=============================================================================
--- FORGE Root Namespace
---
--- Farming Operations & Regional Growth Engine
---
--- Establishes the root namespace and shared metadata for the FORGE framework.
---
--- Responsibilities:
---     • Create the global FORGE namespace.
---     • Provide shared framework identity and version metadata.
---     • Provide the root namespace beneath which FORGE systems are organised.
---
--- This file must not contain gameplay logic or initialise mission state.
---=============================================================================

FORGE = FORGE or {}

FORGE.Version = "0.5.0-dev"
FORGE.Name = "Farming Operations & Regional Growth Engine"