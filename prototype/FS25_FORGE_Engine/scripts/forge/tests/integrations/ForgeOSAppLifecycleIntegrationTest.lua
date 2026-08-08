---=============================================================================
--- FORGE ForgeOS Application Lifecycle Integration Tests
---
--- Manual integration harness for the M2.007 Lifecycle Service boundary.
---
--- Responsibilities:
---     • Verify the public lifecycle facade at runtime active.
---     • Verify production registries and resolver integration.
---     • Verify shutdown, restart, and the deferred production-host gate.
---
--- This manual harness is invoked only by the Engine development test runner.
---=============================================================================

FORGE.Tests = FORGE.Tests or {}

function FORGE.Tests.runForgeOSAppLifecycleIntegrationTests()
    FORGE.Logger:info(
        FORGE.Definitions.LogSource.TEST,
        "ForgeOS App Lifecycle integration test started"
    )

    local Result = FORGE.Definitions.ForgeOSResult
    local Phase = FORGE.Definitions.ForgeOSPhase
    local Role = FORGE.ForgeOSRegistrationCoordinator.Role
    local callbackCount = 0
    local eventCount = 0
    local failCallback = false
    local reentrantResult = nil

    local function host()
        local value = { frozen = false }
        function value:getRegistrationRole()
            return Role.DEVICE_HOST_REGISTRY
        end
        function value:validateRegistrationSet() return Result.SUCCESS end
        function value:freezeRegistrationSet()
            self.frozen = true
            return Result.SUCCESS
        end
        function value:clearRegistrationSet()
            self.frozen = false
            return Result.SUCCESS
        end
        function value:isRegistrationSetFrozen() return self.frozen end
        return value
    end

    local function cleanup()
        FORGE.ForgeOS:shutdown()
        FORGE.EventBus:clearAll()
        FORGE.StateStore:clearAll()
        FORGE.SaveManager:clearAllRegistrations()
    end

    local success, errorMessage = pcall(function()
        cleanup()
        if FORGE.ForgeOS:start() ~= Result.SUCCESS
            or FORGE.ForgeOS:getPhase() ~= Phase.REGISTRATION_OPEN
            or FORGE.ForgeOS:openApp("phone", "forge.lifecycle")
                ~= Result.NOT_AVAILABLE then
            error("Production lifecycle gate failed")
        end
        if FORGE.ForgeOS:registerDevice({
            id = "phone", displayName = "Phone", capabilities = {}
        }) ~= Result.SUCCESS
            or FORGE.ForgeOS:registerApp({
                id = "forge.lifecycle",
                apiVersion = FORGE.Definitions.ForgeOSVersion.APP_API,
                displayName = "Lifecycle",
                supportedDevices = { phone = true },
                presentations = {
                    phone = {
                        id = "lifecycle.phone",
                        defaultRoute = "home",
                        routes = { home = {} }
                    }
                }
            }) ~= Result.SUCCESS
            or FORGE.ForgeOS:registerApp({
                id = "forge.lifecycleSecond",
                apiVersion = FORGE.Definitions.ForgeOSVersion.APP_API,
                displayName = "Lifecycle Second",
                supportedDevices = { phone = true },
                presentations = {
                    phone = {
                        id = "lifecycleSecond.phone",
                        defaultRoute = "home",
                        routes = { home = {} }
                    }
                },
                callbacks = {
                    onActivate = function()
                        callbackCount = callbackCount + 1
                        reentrantResult = FORGE.ForgeOS:closeApp(
                            "phone", "forge.lifecycleSecond"
                        )
                        if failCallback then
                            error("intentional integration callback failure")
                        end
                    end
                }
            }) ~= Result.SUCCESS
            or FORGE.ForgeOSRegistrationCoordinator
                :installParticipant(host()) ~= Result.SUCCESS
            or FORGE.ForgeOS:completeStartup() ~= Result.SUCCESS then
            error("Lifecycle integration setup failed")
        end

        local observer = {}
        function observer:onEvent()
            eventCount = eventCount + 1
        end
        for _, eventId in ipairs({
            FORGE.Definitions.ForgeOSEvent.APP_OPENED,
            FORGE.Definitions.ForgeOSEvent.APP_ACTIVATED,
            FORGE.Definitions.ForgeOSEvent.APP_BACKGROUNDED,
            FORGE.Definitions.ForgeOSEvent.APP_CLOSED
        }) do
            FORGE.EventBus:subscribe(
                eventId,
                observer,
                observer.onEvent
            )
        end

        if FORGE.ForgeOS:openApp("phone", "forge.lifecycle")
                ~= Result.SUCCESS
            or FORGE.ForgeOS:activateApp("phone", "forge.lifecycle")
                ~= Result.SUCCESS
            or FORGE.ForgeOS:openApp(
                "phone", "forge.lifecycleSecond"
            ) ~= Result.SUCCESS
            or FORGE.AppLifecycleService:setAppEnabled(
                "forge.lifecycleSecond", false
            ) ~= Result.SUCCESS
            or FORGE.ForgeOS:activateApp(
                "phone", "forge.lifecycleSecond"
            ) ~= Result.POLICY_REJECTED
            or FORGE.AppLifecycleService:setAppEnabled(
                "forge.lifecycleSecond", true
            ) ~= Result.SUCCESS then
            error("Public lifecycle policy integration failed")
        end

        failCallback = true
        local eventsBeforeFailure = eventCount
        if FORGE.ForgeOS:activateApp(
                "phone", "forge.lifecycleSecond"
            ) ~= Result.CALLBACK_FAILED
            or FORGE.ForgeOS:getActiveAppId("phone")
                ~= "forge.lifecycle"
            or eventCount ~= eventsBeforeFailure
            or reentrantResult ~= Result.NOT_AVAILABLE then
            error("Lifecycle callback integration failed")
        end

        failCallback = false
        if FORGE.ForgeOS:activateApp(
                "phone", "forge.lifecycleSecond"
            ) ~= Result.SUCCESS
            or callbackCount ~= 2
            or FORGE.ForgeOS:getActiveAppId("phone")
                ~= "forge.lifecycleSecond"
            or FORGE.ForgeOS:getAppLifecycleState(
                "phone", "forge.lifecycle"
            ) ~= FORGE.Definitions.AppLifecycleState.CLOSED
            or FORGE.ForgeOS:backgroundApp(
                "phone", "forge.lifecycleSecond"
            ) ~= Result.SUCCESS
            or FORGE.ForgeOS:closeApp(
                "phone", "forge.lifecycleSecond"
            ) ~= Result.SUCCESS
            or FORGE.ForgeOS:openApp("phone", "forge.lifecycle")
                ~= Result.SUCCESS
            or FORGE.ForgeOS:backgroundApp("phone", "forge.lifecycle")
                ~= Result.SUCCESS
            or FORGE.ForgeOS:closeApp("phone", "forge.lifecycle")
                ~= Result.SUCCESS then
            error("Public lifecycle facade failed")
        end
        if FORGE.ForgeOS:shutdown() ~= Result.SUCCESS
            or FORGE.ForgeOS:start() ~= Result.SUCCESS
            or FORGE.ForgeOS:getPhase() ~= Phase.REGISTRATION_OPEN
            or FORGE.ForgeOS:shutdown() ~= Result.SUCCESS then
            error("Lifecycle restart failed")
        end
        cleanup()
    end)

    if not success then
        pcall(cleanup)
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.TEST,
            "ForgeOS App Lifecycle integration test failed: %s",
            FORGE.Logger:safeToString(errorMessage, "<unprintable error>")
        )
        return false, errorMessage
    end

    FORGE.Logger:info(
        FORGE.Definitions.LogSource.TEST,
        "ForgeOS App Lifecycle integration test passed"
    )
    return true
end
