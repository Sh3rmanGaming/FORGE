---=============================================================================
--- FORGE Development Test Bootstrap
---
--- Enables the internal manual test runner for development verification builds.
---
--- Responsibilities:
---     • Enable the existing Logger development mode before Engine loads.
---     • Confirm development-mode activation through the Logger.
---     • Emit one concise activation or failure diagnostic.
---
--- This file defines no public API and performs no test or runtime operation.
---=============================================================================

FORGE.Logger:setDevelopmentMode(true)

if FORGE.Logger:isDevelopmentMode() then
    FORGE.Logger:info(
        "Test",
        "FORGE M2.004 development verification mode enabled"
    )
else
    FORGE.Logger:error(
        "Test",
        "FORGE M2.004 development verification mode could not be enabled"
    )
end
