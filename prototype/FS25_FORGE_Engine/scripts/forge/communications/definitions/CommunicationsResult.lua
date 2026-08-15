---=============================================================================
--- FORGE Communications Result Definitions
---
--- Authoritative operation and integration-detail results for Communications.
---
--- Responsibilities:
---     • Define Communications domain operation results.
---     • Define bounded optional-notification failure detail.
---     • Remain distinct from ForgeOS infrastructure results.
---
--- This file must contain definitions only.
---=============================================================================

FORGE.Definitions.CommunicationsResult = {

    SUCCESS = "success",

    INVALID_ARGUMENT = "invalidArgument",

    INVALID_DEFINITION = "invalidDefinition",

    NOT_AVAILABLE = "notAvailable",

    NOT_FOUND = "notFound",

    CAPACITY_EXHAUSTED = "capacityExhausted",

    STATE_ERROR = "stateError",

    NOTIFICATION_CREATION_FAILED =
        "notificationCreationFailed",

    NOTIFICATION_LINKAGE_FAILED =
        "notificationLinkageFailed",

    INTERNAL_ERROR = "internalError"
}
