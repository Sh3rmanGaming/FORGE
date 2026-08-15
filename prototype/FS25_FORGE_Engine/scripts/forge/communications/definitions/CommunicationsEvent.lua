---=============================================================================
--- FORGE Communications Event Definitions
---
--- Authoritative completed event identifiers emitted by Communications.
---
--- Responsibilities:
---     • Define stable message lifecycle event identifiers.
---     • Distinguish domain events from ForgeOS notification events.
---
--- This file must contain definitions only.
---=============================================================================

FORGE.Definitions.CommunicationsEvent = {

    MESSAGE_CREATED =
        "communication.messageCreated",

    MESSAGE_READ =
        "communication.messageRead",

    MESSAGE_ARCHIVED =
        "communication.messageArchived"
}
