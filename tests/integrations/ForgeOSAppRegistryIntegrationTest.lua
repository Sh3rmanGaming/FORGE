---=============================================================================
--- FORGE ForgeOS App Registry Integration Tests
---
--- Manual integration harness for the M2.005 production registry boundary.
---
--- Responsibilities:
---     • Verify Device and App participants install before registration opens.
---     • Verify production waits for the deferred Device Host Registry.
---     • Verify explicit Host participation enables startup completion.
---     • Verify registry freeze, cleanup, shutdown, and restart.
---
--- This manual harness is invoked only by the Engine development test runner.
---=============================================================================

FORGE.Tests = FORGE.Tests or {}

function FORGE.Tests.runForgeOSAppRegistryIntegrationTests()
    FORGE.Logger:info(
        FORGE.Definitions.LogSource.TEST,
        "ForgeOS App Registry integration test started"
    )

    local success, errorMessage = pcall(function()
        local Coordinator =
            FORGE.ForgeOSRegistrationCoordinator
        local Role = Coordinator.Role
        local Result =
            FORGE.Definitions.ForgeOSResult
        local Phase =
            FORGE.Definitions.ForgeOSPhase
        local Event =
            FORGE.Definitions.ForgeOSEvent

        local function createHost()
            local host = { frozen = false }
            function host:getRegistrationRole()
                return Role.DEVICE_HOST_REGISTRY
            end
            function host:validateRegistrationSet()
                return Result.SUCCESS
            end
            function host:freezeRegistrationSet()
                self.frozen = true
                return Result.SUCCESS
            end
            function host:clearRegistrationSet()
                self.frozen = false
                return Result.SUCCESS
            end
            function host:isRegistrationSetFrozen()
                return self.frozen
            end
            return host
        end

        local observer = {
            opened = 0,
            registriesInstalled = false
        }
        function observer:onOpened()
            self.opened = self.opened + 1
            self.registriesInstalled =
                Coordinator:installParticipant(
                    FORGE.DeviceRegistry
                ) == Result.ALREADY_REGISTERED
                and Coordinator:installParticipant(
                    FORGE.AppRegistry
                ) == Result.ALREADY_REGISTERED
        end

        FORGE.ForgeOS:shutdown()
        FORGE.EventBus:clearAll()
        FORGE.StateStore:clearAll()
        FORGE.SaveManager:clearAllRegistrations()
        FORGE.EventBus:subscribe(
            Event.REGISTRATION_OPENED,
            observer,
            observer.onOpened
        )

        if FORGE.ForgeOS:start()
                ~= Result.SUCCESS
            or observer.opened ~= 1
            or not observer.registriesInstalled
            or FORGE.ForgeOS:completeStartup()
                ~= Result.NOT_AVAILABLE
            or FORGE.ForgeOS:getPhase()
                ~= Phase.REGISTRATION_OPEN then
            error("Production registry installation boundary failed")
        end

        if Coordinator:installParticipant(
            createHost()
        ) ~= Result.SUCCESS
            or FORGE.ForgeOS:completeStartup()
                ~= Result.SUCCESS
            or FORGE.ForgeOS:getPhase()
                ~= Phase.RUNTIME_ACTIVE
            or not FORGE.DeviceRegistry
                :isRegistrationSetFrozen()
            or not FORGE.AppRegistry
                :isRegistrationSetFrozen() then
            error("App Registry startup completion failed")
        end

        if FORGE.ForgeOS:shutdown()
                ~= Result.SUCCESS
            or #FORGE.ForgeOS
                :getRegisteredAppIds() ~= 0 then
            error("App Registry integration cleanup failed")
        end

        observer.opened = 0
        observer.registriesInstalled = false
        if FORGE.ForgeOS:start()
                ~= Result.SUCCESS
            or observer.opened ~= 1
            or not observer.registriesInstalled
            or FORGE.ForgeOS:shutdown()
                ~= Result.SUCCESS then
            error("App Registry integration restart failed")
        end

        FORGE.EventBus:clearAll()
        FORGE.StateStore:clearAll()
        FORGE.SaveManager:clearAllRegistrations()
    end)

    if not success then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.TEST,
            "ForgeOS App Registry integration test failed: %s",
            FORGE.Logger:safeToString(
                errorMessage,
                "<unprintable error>"
            )
        )
        return false, errorMessage
    end

    FORGE.Logger:info(
        FORGE.Definitions.LogSource.TEST,
        "ForgeOS App Registry integration test passed"
    )
    return true
end
