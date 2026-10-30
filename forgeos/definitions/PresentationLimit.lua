---=============================================================================
--- FORGE Presentation Protocol Limit Definitions
---
--- Defensive bounds for future declarative view and controlled-data validators.
---
--- This file must contain definitions only.
---=============================================================================

FORGE.Definitions.PresentationLimit = {

    MAX_VIEW_DEPTH = 12,

    MAX_VIEW_NODES = 512,

    MAX_CHILDREN_PER_NODE = 64,

    MAX_TEXT_LENGTH = 8192,

    MAXIMUM_TEXT_LINES = 32,

    MAX_ACTIONS = 128,

    MAX_PARAMETER_DEPTH = 8,

    MAX_PARAMETER_ENTRIES = 128,

    MAX_ROUTE_PARAMETERS = 32
}
