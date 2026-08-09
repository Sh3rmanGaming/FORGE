---=============================================================================
--- FORGE ForgeOS Registration Lifecycle Integration Tests
---
--- Verifies the real production registration participant set. Artificial
--- failure participants remain isolated in ForgeOSRegistrationCoordinatorTest.
---=============================================================================

FORGE.Tests = FORGE.Tests or {}

function FORGE.Tests.runForgeOSRegistrationLifecycleIntegrationTests()
    FORGE.Logger:info(
        FORGE.Definitions.LogSource.TEST,
        "ForgeOS Registration Lifecycle integration test started"
    )

    local Result = FORGE.Definitions.ForgeOSResult
    local Phase = FORGE.Definitions.ForgeOSPhase
    local Event = FORGE.Definitions.ForgeOSEvent
    local opened = 0
    local frozen = 0
    local started = 0

    local observer = {}
    function observer:onOpened() opened = opened + 1 end
    function observer:onFrozen() frozen = frozen + 1 end
    function observer:onStarted() started = started + 1 end

    local function cleanup()
        FORGE.ForgeOS:shutdown()
        FORGE.EventBus:clearAll()
        FORGE.StateStore:clearAll()
        FORGE.SaveManager:clearAllRegistrations()
    end

    local success, errorMessage = pcall(function()
        cleanup()
        FORGE.EventBus:subscribe(Event.REGISTRATION_OPENED, observer, observer.onOpened)
        FORGE.EventBus:subscribe(Event.REGISTRATION_FROZEN, observer, observer.onFrozen)
        FORGE.EventBus:subscribe(Event.STARTED, observer, observer.onStarted)

        if FORGE.ForgeOS:start() ~= Result.SUCCESS
            or FORGE.ForgeOS:getPhase() ~= Phase.REGISTRATION_OPEN
            or opened ~= 1
            or not FORGE.ForgeOSRegistrationCoordinator
                :hasCompleteParticipantSet()
            or FORGE.ForgeOSRegistrationCoordinator:installParticipant(
                FORGE.DeviceHostRegistry
            ) ~= Result.ALREADY_REGISTERED then
            error("Production registration set did not open deterministically")
        end

        if FORGE.ForgeOS:completeStartup() ~= Result.SUCCESS
            or FORGE.ForgeOS:getPhase() ~= Phase.RUNTIME_ACTIVE
            or frozen ~= 1
            or started ~= 1
            or not FORGE.DeviceRegistry:isRegistrationSetFrozen()
            or not FORGE.DeviceHostRegistry:isRegistrationSetFrozen()
            or not FORGE.AppRegistry:isRegistrationSetFrozen() then
            error("Production registration set did not freeze and activate")
        end

        if FORGE.ForgeOS:completeStartup() ~= Result.SUCCESS
            or frozen ~= 1 or started ~= 1 then
            error("Production completion was not idempotent")
        end

        if FORGE.ForgeOS:registerDevice({})
            ~= Result.REGISTRATION_CLOSED then
            error("Late production registration was accepted")
        end

        if FORGE.ForgeOS:shutdown() ~= Result.SUCCESS
            or FORGE.ForgeOS:getPhase() ~= Phase.STOPPED
            or FORGE.DeviceHostRegistry:isRegistrationSetFrozen() then
            error("Production registration cleanup failed")
        end
        cleanup()
    end)

    pcall(cleanup)
    if not success then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.TEST,
            "ForgeOS Registration Lifecycle integration test failed: %s",
            FORGE.Logger:safeToString(errorMessage, "<unprintable error>")
        )
        return false, errorMessage
    end

    FORGE.Logger:info(
        FORGE.Definitions.LogSource.TEST,
        "ForgeOS Registration Lifecycle integration test passed"
    )
    return true
end
