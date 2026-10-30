---=============================================================================
--- FORGE Presentation Contract Field Definitions
---
--- Controlled field names used by presentation envelopes and references.
---
--- This file must contain definitions only.
---=============================================================================

FORGE.Definitions.PresentationEnvelopeField = {
    MODEL_VERSION = "modelVersion",
    APP_ID = "appId",
    PRESENTATION_ID = "presentationId",
    ROUTE_ID = "routeId",
    TITLE = "title",
    ATTENTION = "attention",
    VIEW = "view",
    ACTIONS = "actions"
}

FORGE.Definitions.PresentationActionField = {
    TARGET = "target",
    ACTION_ID = "actionId",
    PARAMETERS = "parameters"
}

FORGE.Definitions.AttentionField = {
    STATE = "state",
    COUNT = "count",
    ACCESSIBLE_LABEL = "accessibleLabel"
}

FORGE.Definitions.RouteSchemaField = {
    PARAMETERS = "parameters",
    ALLOW_ADDITIONAL_PARAMETERS = "allowAdditionalParameters",
    TYPE = "type",
    REQUIRED = "required"
}
