---=============================================================================
--- FORGE Presentation Component Contract Definitions
---
--- Exact PF.001 property, child, interaction, and semantic-state contracts for
--- each approved declarative component. Tables contain definitions only.
---=============================================================================

FORGE.Definitions.PresentationComponentContract = {
    ["layout.stack"] = {
        allowedProperties = {
            "direction", "alignment", "distribution", "spacing", "padding",
            "gap", "widthMode", "heightMode", "minimumWidth", "maximumWidth",
            "minimumHeight", "maximumHeight", "grow", "surface", "border",
            "clipping", "overflow"
        },
        requiredProperties = {},
        childPolicy = "required",
        minimumChildren = 1,
        maximumChildren = 64,
        interactive = false,
        allowedSemanticStates = {}
    },
    ["layout.row"] = {
        allowedProperties = {
            "alignment", "distribution", "spacing", "padding", "gap",
            "widthMode", "heightMode", "minimumWidth", "maximumWidth",
            "minimumHeight", "maximumHeight", "grow", "surface", "border",
            "clipping", "overflow"
        },
        requiredProperties = {},
        childPolicy = "required",
        minimumChildren = 1,
        maximumChildren = 64,
        interactive = false,
        allowedSemanticStates = {}
    },
    ["layout.split"] = {
        allowedProperties = {
            "direction", "alignment", "padding", "gap", "widthMode",
            "heightMode", "minimumWidth", "maximumWidth", "minimumHeight",
            "maximumHeight", "grow", "surface", "border", "clipping",
            "overflow"
        },
        requiredProperties = {},
        childPolicy = "required",
        minimumChildren = 2,
        maximumChildren = 2,
        interactive = false,
        allowedSemanticStates = {}
    },
    ["layout.scroll"] = {
        allowedProperties = {
            "direction", "padding", "widthMode", "heightMode",
            "minimumWidth", "maximumWidth", "minimumHeight", "maximumHeight",
            "grow", "surface", "border", "clipping", "overflow"
        },
        requiredProperties = {},
        childPolicy = "required",
        minimumChildren = 1,
        maximumChildren = 1,
        interactive = false,
        allowedSemanticStates = {}
    },
    ["content.text"] = {
        allowedProperties = {
            "text", "accessibleLabel", "widthMode", "heightMode",
            "minimumWidth", "maximumWidth", "minimumHeight", "maximumHeight",
            "grow", "textRole", "textAlignment", "clipping", "overflow",
            "textWrap", "maximumLines", "textOverflow", "semanticState"
        },
        requiredProperties = { "text" },
        childPolicy = "forbidden",
        minimumChildren = 0,
        maximumChildren = 0,
        interactive = false,
        allowedSemanticStates = {
            "none", "unread", "attention", "success", "warning", "error",
            "information"
        }
    },
    ["content.icon"] = {
        allowedProperties = {
            "iconId", "accessibleLabel", "widthMode", "heightMode",
            "minimumWidth", "maximumWidth", "minimumHeight", "maximumHeight",
            "grow", "clipping", "semanticState"
        },
        requiredProperties = { "iconId" },
        childPolicy = "forbidden",
        minimumChildren = 0,
        maximumChildren = 0,
        interactive = false,
        allowedSemanticStates = {
            "none", "unread", "attention", "success", "warning", "error",
            "information"
        }
    },
    ["content.divider"] = {
        allowedProperties = {
            "widthMode", "heightMode", "minimumWidth", "maximumWidth",
            "minimumHeight", "maximumHeight", "grow", "border"
        },
        requiredProperties = {},
        childPolicy = "forbidden",
        minimumChildren = 0,
        maximumChildren = 0,
        interactive = false,
        allowedSemanticStates = {}
    },
    ["content.emptyState"] = {
        allowedProperties = {
            "text", "iconId", "accessibleLabel", "padding", "gap",
            "widthMode", "heightMode", "minimumWidth", "maximumWidth",
            "minimumHeight", "maximumHeight", "grow", "surface", "border",
            "textRole", "textAlignment", "semanticState"
        },
        requiredProperties = {},
        contentSources = { "text", "iconId", "accessibleLabel", "children" },
        minimumContentSources = 1,
        childPolicy = "allowed",
        minimumChildren = 0,
        maximumChildren = 4,
        interactive = false,
        allowedSemanticStates = {
            "none", "attention", "success", "warning", "error",
            "information"
        }
    },
    ["control.button"] = {
        allowedProperties = {
            "text", "iconId", "accessibleLabel", "actionReference", "padding",
            "gap", "widthMode", "heightMode", "minimumWidth", "maximumWidth",
            "minimumHeight", "maximumHeight", "grow", "surface", "border",
            "textRole", "textAlignment", "selected", "disabled",
            "semanticState"
        },
        requiredProperties = { "actionReference" },
        contentSources = { "text", "iconId", "accessibleLabel", "children" },
        minimumContentSources = 1,
        childPolicy = "allowed",
        minimumChildren = 0,
        maximumChildren = 4,
        interactive = true,
        allowedSemanticStates = {
            "none", "unread", "attention", "success", "warning", "error",
            "information"
        }
    },
    ["control.iconButton"] = {
        allowedProperties = {
            "iconId", "accessibleLabel", "actionReference", "padding",
            "widthMode", "heightMode", "minimumWidth", "maximumWidth",
            "minimumHeight", "maximumHeight", "grow", "surface", "border",
            "selected", "disabled", "semanticState"
        },
        requiredProperties = {
            "iconId", "accessibleLabel", "actionReference"
        },
        childPolicy = "forbidden",
        minimumChildren = 0,
        maximumChildren = 0,
        interactive = true,
        allowedSemanticStates = {
            "none", "unread", "attention", "success", "warning", "error",
            "information"
        }
    },
    ["control.navigationItem"] = {
        allowedProperties = {
            "text", "iconId", "accessibleLabel", "actionReference", "count",
            "padding", "gap", "widthMode", "heightMode", "minimumWidth",
            "maximumWidth", "minimumHeight", "maximumHeight", "grow",
            "surface", "border", "textRole", "textAlignment", "selected",
            "disabled", "semanticState"
        },
        requiredProperties = { "actionReference" },
        contentSources = { "text", "iconId", "accessibleLabel", "children" },
        minimumContentSources = 1,
        childPolicy = "allowed",
        minimumChildren = 0,
        maximumChildren = 4,
        interactive = true,
        allowedSemanticStates = {
            "none", "unread", "attention", "warning", "error"
        }
    },
    ["control.listRow"] = {
        allowedProperties = {
            "accessibleLabel", "actionReference", "padding", "gap",
            "widthMode", "heightMode", "minimumWidth", "maximumWidth",
            "minimumHeight", "maximumHeight", "grow", "surface", "border",
            "selected", "disabled", "semanticState"
        },
        requiredProperties = { "actionReference" },
        childPolicy = "required",
        minimumChildren = 1,
        maximumChildren = 64,
        interactive = true,
        allowedSemanticStates = {
            "none", "unread", "attention", "warning", "error"
        }
    },
    ["indicator.badge"] = {
        allowedProperties = {
            "count", "accessibleLabel", "widthMode", "heightMode",
            "minimumWidth", "maximumWidth", "minimumHeight", "maximumHeight",
            "grow", "semanticState"
        },
        requiredProperties = { "semanticState" },
        childPolicy = "forbidden",
        minimumChildren = 0,
        maximumChildren = 0,
        interactive = false,
        allowedSemanticStates = {
            "none", "unread", "attention", "success", "warning", "error",
            "information"
        }
    },
    ["indicator.status"] = {
        allowedProperties = {
            "text", "iconId", "accessibleLabel", "widthMode", "heightMode",
            "minimumWidth", "maximumWidth", "minimumHeight", "maximumHeight",
            "grow", "textRole", "textAlignment", "semanticState"
        },
        requiredProperties = { "semanticState" },
        contentSources = { "text", "iconId", "accessibleLabel" },
        minimumContentSources = 1,
        childPolicy = "forbidden",
        minimumChildren = 0,
        maximumChildren = 0,
        interactive = false,
        allowedSemanticStates = {
            "none", "unread", "attention", "success", "warning", "error",
            "information"
        }
    }
}
