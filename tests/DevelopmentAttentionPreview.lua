---=============================================================================
--- FORGE Development Attention Preview
---
--- Development-only. Registers a few inert preview applications whose
--- launcher badges show each PF.005 attention state, so the shapes, sizes and
--- counts can be judged on screen. Registered only when the Logger is in
--- development mode; the operational build never calls it.
---
--- The preview applications own no domain state, take no actions, and persist
--- nothing.
---=============================================================================

FORGE.DevelopmentAttentionPreview = {}

local Preview = FORGE.DevelopmentAttentionPreview
local DeviceId = FORGE.Definitions.DeviceId

local ROUTE = "home"
local Entries = {
    { key = "unread7", name = "Preview Unread 7",
        attention = { state = "unread", count = 7 } },
    { key = "unread42", name = "Preview Unread 42",
        attention = { state = "unread", count = 42 } },
    { key = "unread150", name = "Preview Unread 150",
        attention = { state = "unread", count = 150 } },
    { key = "attention", name = "Preview Attention",
        attention = { state = "attention" } },
    { key = "warning3", name = "Preview Warning 3",
        attention = { state = "warning", count = 3 } },
    { key = "error", name = "Preview Error",
        attention = { state = "error" } }
}

local function createProvider(entry)
    local provider = { protocolVersion = 1 }

    function provider:getModel(context)
        return {
            modelVersion = 2,
            appId = context.appId,
            presentationId = context.presentationId,
            routeId = context.routeId,
            title = entry.name,
            actions = {},
            view = {
                component = "layout.stack",
                properties = {},
                children = {
                    {
                        component = "content.text",
                        properties = {
                            text = "Attention preview. This application is "
                                .. "for development verification only.",
                            textWrap = "word",
                            textOverflow = "ellipsis"
                        }
                    }
                }
            }
        }
    end

    function provider:getBadge(_)
        return entry.attention.count or 0
    end

    function provider:getAttention(_)
        local copy = {}
        for key, value in pairs(entry.attention) do
            copy[key] = value
        end
        return copy
    end

    function provider:performAction(_, _, _)
        return { completed = false, domainResult = "notAvailable" }
    end

    return provider
end

local function presentation(identifier, provider)
    return {
        id = identifier,
        controller = provider,
        defaultRoute = ROUTE,
        routes = { [ROUTE] = {} },
        actions = {}
    }
end

--- Registers every preview application. Returns the number registered.
function Preview:register()
    local registered = 0
    for _, entry in ipairs(Entries) do
        local provider = createProvider(entry)
        local result = FORGE.ForgeOS:registerApp({
            id = "forge.devpreview." .. entry.key,
            ownerId = "forge",
            apiVersion = FORGE.Definitions.ForgeOSVersion.APP_API,
            displayName = entry.name,
            supportedDevices = {
                [DeviceId.PHONE] = true,
                [DeviceId.LAPTOP] = true
            },
            presentations = {
                [DeviceId.PHONE] = presentation(
                    "forge.devpreview." .. entry.key .. ".phone", provider),
                [DeviceId.LAPTOP] = presentation(
                    "forge.devpreview." .. entry.key .. ".laptop", provider)
            }
        })
        if result == FORGE.Definitions.ForgeOSResult.SUCCESS then
            registered = registered + 1
        else
            FORGE.Logger:warning(
                FORGE.Definitions.LogSource.TEST,
                "Attention preview application '%s' was not registered: %s",
                entry.key,
                FORGE.Logger:safeToString(result, "<unknown>")
            )
        end
    end
    return registered
end
