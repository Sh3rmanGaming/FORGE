---=============================================================================
--- FORGE ForgeOS Cross-Mod Bridge Integration Tests
---=============================================================================

FORGE.Tests = FORGE.Tests or {}

function FORGE.Tests.runForgeOSCrossModBridgeIntegrationTests()
    local Result = FORGE.Definitions.ForgeOSResult
    local Phase = FORGE.Definitions.ForgeOSPhase
    local Bridge = FORGE.ForgeOSExportBridge
    local topic = Bridge:getRequestTopic()
    local listener = nil
    local listenerTarget = nil
    local center = {}

    function center:subscribe(subscribedTopic, callback, target)
        if subscribedTopic ~= topic then
            error("Unexpected bridge topic")
        end
        listener = callback
        listenerTarget = target
    end

    function center:publish(publishedTopic, request)
        if publishedTopic == topic and listener ~= nil then
            listener(listenerTarget, request)
        end
    end

    function center:unsubscribeAll(target)
        if target == listenerTarget then
            listener = nil
            listenerTarget = nil
        end
    end

    local success, errorMessage = pcall(function()
        Bridge:shutdown()
        FORGE.ForgeOS:shutdown()
        FORGE.EventBus:clearAll()
        FORGE.StateStore:clearAll()
        FORGE.SaveManager:clearAllRegistrations()

        if FORGE.ForgeOS:start() ~= Result.SUCCESS
            or FORGE.ForgeOS:getPhase() ~= Phase.REGISTRATION_OPEN then
            error("ForgeOS did not enter the registration window")
        end

        local phaseBefore = FORGE.ForgeOS:getPhase()
        if not Bridge:start(center) then
            error("Bridge did not subscribe")
        end

        local response = {
            requestedBridgeVersion = 1,
            responderCount = 0
        }
        center:publish(topic, response)
        local facade = response.forgeOS
        response = nil

        if type(facade) ~= "table"
            or facade ~= FORGE.ForgeOS
            or facade:getAppApiVersion() ~= 1
            or facade:supportsAppApiVersion(1) ~= true
            or facade:getPhase() ~= phaseBefore then
            error("Synchronous facade acquisition contract failed")
        end

        if not Bridge:shutdown() or listener ~= nil then
            error("Integration cleanup failed")
        end
        if FORGE.ForgeOS:getPhase() ~= phaseBefore then
            error("Bridge mutated ForgeOS lifecycle state")
        end
    end)

    Bridge:shutdown()
    FORGE.ForgeOS:shutdown()
    if not success then
        return false, errorMessage
    end
    return true
end
