---=============================================================================
--- FORGE Production Startup Integration Tests
---=============================================================================

FORGE.Tests = FORGE.Tests or {}

function FORGE.Tests.runForgeOSProductionStartupIntegrationTests()
    local Result = FORGE.Definitions.ForgeOSResult
    local Event = FORGE.Definitions.ForgeOSEvent
    local visibilityAtStarted = "unexpected"
    local observer = {}
    function observer:onStarted()
        visibilityAtStarted = FORGE.ForgeOS:getDeviceVisibility("phone")
    end

    local success, errorMessage = pcall(function()
        FORGE.ForgeOS:shutdown()
        FORGE.EventBus:clearAll()
        FORGE.StateStore:clearAll()
        FORGE.SaveManager:clearAllRegistrations()
        FORGE.EventBus:subscribe(Event.STARTED, observer, observer.onStarted)
        if FORGE.ForgeOS:start() ~= Result.SUCCESS
            or visibilityAtStarted ~= "unexpected"
            or FORGE.ForgeOS:completeStartup() ~= Result.SUCCESS
            or visibilityAtStarted ~= nil
            or FORGE.ForgeOS:getDeviceVisibility("phone")
                ~= FORGE.Definitions.DeviceVisibility.HIDDEN then
            error("STARTED and Host readiness ordering failed")
        end
        FORGE.ForgeOS:shutdown()
    end)
    FORGE.ForgeOS:shutdown()
    if not success then return false, errorMessage end
    return true
end
