---=============================================================================
--- FORGE ForgeOS Device Registry Integration Tests
---
--- Manual integration harness for the M2.004 production registry boundary.
---
--- Responsibilities:
---     • Verify production registry installation before registration observers.
---     • Verify public registration and coordinator participation.
---     • Verify production waits for deferred participant implementations.
---     • Verify explicit test participants enable freeze, runtime, and restart.
---
--- This manual harness is invoked only by the Engine development test runner.
---=============================================================================

FORGE.Tests = FORGE.Tests or {}

function FORGE.Tests.runForgeOSDeviceRegistryIntegrationTests()
    FORGE.Logger:info(
        FORGE.Definitions.LogSource.TEST,
        "ForgeOS Device Registry integration test started"
    )

    local success, errorMessage = pcall(
        function()
            local Coordinator =
                FORGE.ForgeOSRegistrationCoordinator

            local Result =
                FORGE.Definitions.ForgeOSResult

            local Phase =
                FORGE.Definitions.ForgeOSPhase

            local Event =
                FORGE.Definitions.ForgeOSEvent

            local observer = {
                opened = 0,
                registryInstalledAtOpen = false
            }

            function observer:onRegistrationOpened()
                self.opened = self.opened + 1

                self.registryInstalledAtOpen =
                    Coordinator:installParticipant(
                        FORGE.DeviceRegistry
                    ) == Result.ALREADY_REGISTERED
                    and Coordinator:installParticipant(
                        FORGE.DeviceHostRegistry
                    ) == Result.ALREADY_REGISTERED
            end

            FORGE.ForgeOS:shutdown()
            FORGE.EventBus:clearAll()
            FORGE.StateStore:clearAll()
            FORGE.SaveManager:clearAllRegistrations()

            FORGE.EventBus:subscribe(
                Event.REGISTRATION_OPENED,
                observer,
                observer.onRegistrationOpened
            )

            if FORGE.ForgeOS:start()
                    ~= Result.SUCCESS
                or observer.opened ~= 1
                or not observer
                    .registryInstalledAtOpen then
                error("Production registry was not installed before registration opened")
            end

            if FORGE.ForgeOS:registerDevice({
                id = "integration.device",
                displayName = "Integration Device",
                capabilities = {}
            }) ~= Result.SUCCESS then
                error("Public Device Registry facade did not register")
            end

            if FORGE.ForgeOS:completeStartup()
                    ~= Result.SUCCESS
                or FORGE.ForgeOS:getPhase()
                    ~= Phase.RUNTIME_ACTIVE
                or not FORGE.DeviceRegistry
                    :isRegistrationSetFrozen() then
                error("Device Registry did not participate in startup completion")
            end

            if FORGE.ForgeOS:shutdown()
                    ~= Result.SUCCESS
                or #FORGE.ForgeOS
                    :getRegisteredDeviceIds() ~= 0 then
                error("Integrated Device Registry shutdown failed")
            end

            observer.opened = 0
            observer.registryInstalledAtOpen =
                false

            if FORGE.ForgeOS:start()
                    ~= Result.SUCCESS
                or observer.opened ~= 1
                or not observer
                    .registryInstalledAtOpen
                or FORGE.ForgeOS:shutdown()
                    ~= Result.SUCCESS then
                error("Integrated Device Registry restart failed")
            end

            FORGE.EventBus:clearAll()
            FORGE.StateStore:clearAll()
            FORGE.SaveManager:clearAllRegistrations()
        end
    )

    if not success then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.TEST,
            "ForgeOS Device Registry integration test failed: %s",
            FORGE.Logger:safeToString(
                errorMessage,
                "<unprintable error>"
            )
        )

        return false, errorMessage
    end

    FORGE.Logger:info(
        FORGE.Definitions.LogSource.TEST,
        "ForgeOS Device Registry integration test passed"
    )

    return true
end
