---=============================================================================
--- FORGE Application Availability Reason Definitions
---
--- Authoritative application availability reason identifiers used by ForgeOS.
---
--- Responsibilities:
---     • Define successful and rejected availability outcomes.
---     • Provide stable diagnostic reason identifiers.
---
--- This file must contain definitions only.
---=============================================================================

FORGE.Definitions.AppAvailabilityReason = {

    AVAILABLE = "available",

    APP_NOT_REGISTERED = "appNotRegistered",

    DEVICE_NOT_REGISTERED = "deviceNotRegistered",

    DEVICE_NOT_SUPPORTED = "deviceNotSupported",

    MISSING_CAPABILITY = "missingCapability",

    PRESENTATION_NOT_FOUND = "presentationNotFound",

    ROUTE_NOT_FOUND = "routeNotFound",

    ACTION_NOT_AVAILABLE = "actionNotAvailable",

    API_VERSION_UNSUPPORTED = "apiVersionUnsupported",

    APP_DISABLED = "appDisabled",

    POLICY_REJECTED = "policyRejected",

    INVALID_DEFINITION = "invalidDefinition",

    UNKNOWN = "unknown"
}
