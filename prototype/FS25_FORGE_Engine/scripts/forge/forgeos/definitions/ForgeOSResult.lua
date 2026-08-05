---=============================================================================
--- FORGE ForgeOS Result Definitions
---
--- Authoritative operation result identifiers returned by ForgeOS.
---
--- Responsibilities:
---     • Define successful and failed ForgeOS operation results.
---     • Provide stable identifiers for public result contracts.
---
--- This file must contain definitions only.
---=============================================================================

FORGE.Definitions.ForgeOSResult = {

    SUCCESS = "success",

    INVALID_ARGUMENT = "invalidArgument",

    INVALID_DEFINITION = "invalidDefinition",

    ALREADY_REGISTERED = "alreadyRegistered",

    NOT_REGISTERED = "notRegistered",

    REGISTRATION_CLOSED = "registrationClosed",

    API_VERSION_UNSUPPORTED = "apiVersionUnsupported",

    NOT_AVAILABLE = "notAvailable",

    PRESENTATION_NOT_FOUND = "presentationNotFound",

    ROUTE_NOT_FOUND = "routeNotFound",

    ACTION_NOT_AVAILABLE = "actionNotAvailable",

    INVALID_TRANSITION = "invalidTransition",

    CAPABILITY_MISSING = "capabilityMissing",

    POLICY_REJECTED = "policyRejected",

    STATE_ERROR = "stateError",

    CALLBACK_FAILED = "callbackFailed",

    PERSISTENCE_ERROR = "persistenceError",

    INTERNAL_ERROR = "internalError"
}
