---=============================================================================
--- FORGE ForgeOS Navigation Integration Tests
---
--- Manual integration harness for the M2.008 Navigation Service boundary.
---
--- Responsibilities:
---     • Verify public lifecycle-to-navigation integration.
---     • Verify route, back, resume, event, cleanup, and restart behavior.
---     • Verify production remains registration-open without a Host registry.
---
--- This manual harness is invoked only by the Engine development test runner.
---=============================================================================

FORGE.Tests = FORGE.Tests or {}

function FORGE.Tests.runForgeOSNavigationIntegrationTests()
    FORGE.Logger:info(
        FORGE.Definitions.LogSource.TEST,
        "ForgeOS Navigation integration test started"
    )
    local Result = FORGE.Definitions.ForgeOSResult
    local Phase = FORGE.Definitions.ForgeOSPhase
    local Role = FORGE.ForgeOSRegistrationCoordinator.Role
    local eventCount = 0

    local function host()
        local value = { frozen = false }
        function value:getRegistrationRole() return Role.DEVICE_HOST_REGISTRY end
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
            or FORGE.ForgeOS:navigate("phone", "forge.nav", "home")
                ~= Result.NOT_AVAILABLE then
            error("Production Navigation gate failed")
        end
        if FORGE.ForgeOS:registerDevice({
            id = "phone", displayName = "Phone", capabilities = {}
        }) ~= Result.SUCCESS
            or FORGE.ForgeOS:registerApp({
                id = "forge.nav",
                apiVersion = FORGE.Definitions.ForgeOSVersion.APP_API,
                displayName = "Navigation",
                supportedDevices = { phone = true },
                presentations = {
                    phone = {
                        id = "nav.phone",
                        defaultRoute = "home",
                        routes = { home = {}, detail = {} }
                    }
                }
            }) ~= Result.SUCCESS
            or FORGE.ForgeOSRegistrationCoordinator
                :installParticipant(host()) ~= Result.SUCCESS
            or FORGE.ForgeOS:completeStartup() ~= Result.SUCCESS
            or FORGE.ForgeOS:openApp("phone", "forge.nav")
                ~= Result.SUCCESS
            or FORGE.ForgeOS:activateApp("phone", "forge.nav")
                ~= Result.SUCCESS then
            error("Navigation integration setup failed")
        end

        local observer = {}
        function observer:onEvent() eventCount = eventCount + 1 end
        FORGE.EventBus:subscribe(
            FORGE.Definitions.ForgeOSEvent.NAVIGATION_CHANGED,
            observer,
            observer.onEvent
        )
        if FORGE.ForgeOS:navigate("phone", "forge.nav", "home")
                ~= Result.SUCCESS
            or FORGE.ForgeOS:navigate(
                "phone", "forge.nav", "detail", { itemId = "item.one" }
            ) ~= Result.SUCCESS
            or FORGE.ForgeOS:goBack("phone", "forge.nav")
                ~= Result.SUCCESS
            or FORGE.ForgeOS:getCurrentRoute("phone", "forge.nav")
                ~= "home"
            or eventCount ~= 3 then
            error("Public Navigation integration failed")
        end

        local state, found = FORGE.StateStore:snapshot(
            FORGE.Definitions.ForgeOSNamespace.OS
        )
        if not found
            or state.players[FORGE.Definitions.ForgeOSPlayerId.LOCAL]
                .devices.phone.resume.routeId ~= "home" then
            error("Navigation resume integration failed")
        end

        if FORGE.ForgeOS:shutdown() ~= Result.SUCCESS
            or FORGE.ForgeOS:start() ~= Result.SUCCESS
            or FORGE.ForgeOS:getPhase() ~= Phase.REGISTRATION_OPEN
            or FORGE.ForgeOS:getCurrentRoute("phone", "forge.nav") ~= nil
            or FORGE.ForgeOS:shutdown() ~= Result.SUCCESS then
            error("Navigation integration restart failed")
        end
        cleanup()
    end)

    if not success then
        pcall(cleanup)
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.TEST,
            "ForgeOS Navigation integration test failed: %s",
            FORGE.Logger:safeToString(errorMessage, "<unprintable error>")
        )
        return false, errorMessage
    end
    FORGE.Logger:info(
        FORGE.Definitions.LogSource.TEST,
        "ForgeOS Navigation integration test passed"
    )
    return true
end
