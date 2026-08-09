---=============================================================================
--- FORGE ForgeOS Cross-Mod Export Bridge
---
--- Adapts the local FS25 MessageCenter to the existing public ForgeOS facade.
--- The version-1 protocol remains provisional pending real runtime proof.
---=============================================================================

FORGE.ForgeOSExportBridge = {}

local Bridge = FORGE.ForgeOSExportBridge

local BRIDGE_VERSION = 1
local REQUEST_TOPIC = "forge.crossMod.forgeOS.request.v1"

local acceptingRequests = false
local messageCenter = nil
local diagnosticIssued = false

local function diagnoseOnce(message)
    if diagnosticIssued then
        return
    end

    diagnosticIssued = true
    FORGE.Logger:error(
        FORGE.Definitions.LogSource.ENGINE,
        "ForgeOS export bridge: %s",
        message
    )
end

local function isNonNegativeInteger(value)
    return type(value) == "number"
        and value >= 0
        and value == math.floor(value)
end

local function handleRequest(request)
    if not acceptingRequests or type(request) ~= "table" then
        return
    end

    local requestedVersion = rawget(request, "requestedBridgeVersion")
    local responderCount = rawget(request, "responderCount")

    if requestedVersion ~= BRIDGE_VERSION
        or not isNonNegativeInteger(requestedVersion)
        or not isNonNegativeInteger(responderCount) then
        return
    end

    rawset(request, "responderCount", responderCount + 1)
    rawset(request, "bridgeVersion", BRIDGE_VERSION)
    rawset(request, "forgeOS", FORGE.ForgeOS)
end

function Bridge:onRequest(request)
    local succeeded, errorMessage = pcall(handleRequest, request)
    if not succeeded then
        diagnoseOnce(
            "request handler failed: "
                .. tostring(errorMessage)
        )
    end
end

function Bridge:start(carrier)
    if acceptingRequests then
        return carrier == messageCenter
    end

    if type(carrier) ~= "table"
        or type(carrier.subscribe) ~= "function"
        or type(carrier.unsubscribeAll) ~= "function" then
        diagnoseOnce("active MessageCenter carrier is unavailable")
        return false
    end

    local subscribed, errorMessage = pcall(
        carrier.subscribe,
        carrier,
        REQUEST_TOPIC,
        Bridge.onRequest,
        Bridge
    )
    if not subscribed then
        diagnoseOnce(
            "subscription failed: "
                .. tostring(errorMessage)
        )
        return false
    end

    messageCenter = carrier
    acceptingRequests = true
    diagnosticIssued = false

    FORGE.Logger:info(
        FORGE.Definitions.LogSource.ENGINE,
        "ForgeOS export bridge subscribed (bridgeVersion=%d topic=%s)",
        BRIDGE_VERSION,
        REQUEST_TOPIC
    )

    return true
end

function Bridge:shutdown()
    acceptingRequests = false

    local carrier = messageCenter
    messageCenter = nil

    if carrier ~= nil then
        local unsubscribed, errorMessage = pcall(
            carrier.unsubscribeAll,
            carrier,
            Bridge
        )
        if not unsubscribed then
            diagnoseOnce(
                "subscription cleanup failed: "
                    .. tostring(errorMessage)
            )
            return false
        end
    end

    diagnosticIssued = false
    return true
end

function Bridge:isActive()
    return acceptingRequests
end

function Bridge:getBridgeVersion()
    return BRIDGE_VERSION
end

function Bridge:getRequestTopic()
    return REQUEST_TOPIC
end
