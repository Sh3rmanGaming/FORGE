---=============================================================================
--- FORGE Notification Persistence Definitions
---
--- Authoritative notification persistence policy identifiers used by ForgeOS.
---
--- Responsibilities:
---     • Define notification persistence policies.
---     • Distinguish transient, session, and savegame lifetimes.
---
--- This file must contain definitions only.
---=============================================================================

FORGE.Definitions.NotificationPersistence = {

    TRANSIENT = "transient",

    SESSION = "session",

    SAVEGAME = "savegame"
}
