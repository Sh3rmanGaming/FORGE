---=============================================================================
--- FORGE ForgeOS Export Bridge Tests
---=============================================================================

FORGE.Tests = FORGE.Tests or {}

local function createMessageCenter()
    local center = {
        subscriptions = {},
        unsubscribeTargets = {}
    }

    function center:subscribe(topic, callback, target)
        self.subscriptions[topic] = self.subscriptions[topic] or {}
        table.insert(self.subscriptions[topic], {
            callback = callback,
            target = target
        })
    end

    function center:publish(topic, request)
        local listeners = self.subscriptions[topic] or {}
        for _, listener in ipairs(listeners) do
            listener.callback(listener.target, request)
        end
    end

    function center:unsubscribeAll(target)
        table.insert(self.unsubscribeTargets, target)
        for topic, listeners in pairs(self.subscriptions) do
            local retained = {}
            for _, listener in ipairs(listeners) do
                if listener.target ~= target then
                    table.insert(retained, listener)
                end
            end
            self.subscriptions[topic] = retained
        end
    end

    return center
end

function FORGE.Tests.runForgeOSExportBridgeTests()
    local Bridge = FORGE.ForgeOSExportBridge
    local success, errorMessage = pcall(function()
        Bridge:shutdown()
        local center = createMessageCenter()
        local topic = Bridge:getRequestTopic()

        if Bridge:getBridgeVersion() ~= 1
            or topic ~= "forge.crossMod.forgeOS.request.v1"
            or not Bridge:start(center)
            or not Bridge:isActive() then
            error("Bridge start or version contract failed")
        end

        local request = {
            requestedBridgeVersion = 1,
            responderCount = 0
        }
        center:publish(topic, request)
        if request.responderCount ~= 1
            or request.bridgeVersion ~= 1
            or request.forgeOS ~= FORGE.ForgeOS
            or request.FORGE ~= nil then
            error("Valid facade-only response failed")
        end

        local priorResponse = {
            requestedBridgeVersion = 1,
            responderCount = 2
        }
        center:publish(topic, priorResponse)
        if priorResponse.responderCount ~= 3
            or priorResponse.forgeOS ~= FORGE.ForgeOS then
            error("Prior responder count handling failed")
        end

        local rejected = {
            {},
            { requestedBridgeVersion = 2, responderCount = 0 },
            { requestedBridgeVersion = 1, responderCount = -1 },
            { requestedBridgeVersion = 1, responderCount = 0.5 },
            { requestedBridgeVersion = "1", responderCount = 0 },
            { requestedBridgeVersion = 1, responderCount = "0" }
        }
        for _, malformed in ipairs(rejected) do
            center:publish(topic, malformed)
            if type(malformed) == "table"
                and malformed.forgeOS ~= nil then
                error("Malformed request received a facade")
            end
        end
        center:publish(topic, nil)

        local protectedRequest = setmetatable({}, {
            __index = function()
                error("consumer metatable must not execute")
            end
        })
        center:publish(topic, protectedRequest)

        local duplicate = {
            requestedBridgeVersion = 1,
            responderCount = 0
        }
        center:publish(topic, duplicate)
        duplicate.responderCount = duplicate.responderCount + 1
        if duplicate.responderCount ~= 2 then
            error("Duplicate provider simulation failed")
        end

        if not Bridge:shutdown()
            or Bridge:isActive()
            or center.unsubscribeTargets[1] ~= Bridge then
            error("Bridge shutdown cleanup failed")
        end

        local afterShutdown = {
            requestedBridgeVersion = 1,
            responderCount = 0
        }
        center:publish(topic, afterShutdown)
        if afterShutdown.responderCount ~= 0
            or afterShutdown.forgeOS ~= nil then
            error("Bridge responded after shutdown")
        end

        local failingCenter = createMessageCenter()
        function failingCenter:subscribe()
            error("controlled listener failure")
        end
        if Bridge:start(failingCenter) or Bridge:isActive() then
            error("Listener failure was not contained")
        end
        Bridge:shutdown()
    end)

    FORGE.ForgeOSExportBridge:shutdown()
    if not success then
        return false, errorMessage
    end
    return true
end
