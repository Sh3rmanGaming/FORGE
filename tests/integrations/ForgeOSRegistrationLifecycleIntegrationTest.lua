---=============================================================================
--- FORGE ForgeOS Registration Lifecycle Integration Tests
---
--- Manual integration harness for M2.003B startup completion.
---
--- Responsibilities:
---     • Verify explicit participants complete the ForgeOS startup lifecycle.
---     • Verify registration-frozen and started event publication.
---     • Verify runtime idempotence and late-participant rejection.
---     • Verify shutdown cleanup and restart.
---
--- This manual harness is invoked by the Engine development test runner.
---=============================================================================

FORGE.Tests = FORGE.Tests or {}

function FORGE.Tests.runForgeOSRegistrationLifecycleIntegrationTests()
    FORGE.Logger:info(
        FORGE.Definitions.LogSource.TEST,
        "ForgeOS Registration Lifecycle integration test started"
    )

    local DeviceRegistry =
        FORGE.DeviceRegistry

    local originalClear =
        DeviceRegistry.clearRegistrationSet

    local success, errorMessage = pcall(
        function()
            local Coordinator =
                FORGE.ForgeOSRegistrationCoordinator

            local Role =
                Coordinator.Role

            local Result =
                FORGE.Definitions.ForgeOSResult

            local Phase =
                FORGE.Definitions.ForgeOSPhase

            local Event =
                FORGE.Definitions.ForgeOSEvent

            local cleanupCount = 0

            function DeviceRegistry:clearRegistrationSet()
                cleanupCount = cleanupCount + 1

                return originalClear(self)
            end

            local function createParticipant(role)
                local participant = {
                    role = role,
                    frozen = false
                }

                function participant:getRegistrationRole()
                    return self.role
                end

                function participant:validateRegistrationSet()
                    return Result.SUCCESS
                end

                function participant:freezeRegistrationSet()
                    self.frozen = true

                    return Result.SUCCESS
                end

                function participant:clearRegistrationSet()
                    self.frozen = false
                    cleanupCount = cleanupCount + 1

                    return Result.SUCCESS
                end

                function participant:isRegistrationSetFrozen()
                    return self.frozen
                end

                return participant
            end

            local function installParticipants()
                local installed =
                    Coordinator:installParticipant(
                        createParticipant(
                            Role.APP_REGISTRY
                        )
                    ) == Result.SUCCESS
                    and Coordinator:installParticipant(
                        createParticipant(
                            Role.DEVICE_HOST_REGISTRY
                        )
                    ) == Result.SUCCESS

                if not installed then
                    error("Unable to install integration participants")
                end
            end

            FORGE.EventBus:clearAll()
            FORGE.StateStore:clearAll()
            FORGE.SaveManager:clearAllRegistrations()
            Coordinator
                :clearRegistrationParticipants()

            local observed = {
                frozen = 0,
                started = 0,
                stopped = 0
            }

            function observed:onFrozen(payload)
                if payload.phase
                    ~= Phase.REGISTRATION_FROZEN then
                    error("Registration-frozen payload is invalid")
                end

                self.frozen = self.frozen + 1
            end

            function observed:onStarted(payload)
                if payload.phase ~= Phase.RUNTIME_ACTIVE
                    or payload.appApiVersion
                        ~= FORGE.Definitions
                            .ForgeOSVersion.APP_API then
                    error("Started payload is invalid")
                end

                self.started = self.started + 1
            end

            function observed:onStopped(payload)
                if payload.phase ~= Phase.STOPPED then
                    error("Stopped payload is invalid")
                end

                self.stopped = self.stopped + 1
            end

            FORGE.EventBus:subscribe(
                Event.REGISTRATION_FROZEN,
                observed,
                observed.onFrozen
            )

            FORGE.EventBus:subscribe(
                Event.STARTED,
                observed,
                observed.onStarted
            )

            FORGE.EventBus:subscribe(
                Event.STOPPED,
                observed,
                observed.onStopped
            )

            if FORGE.ForgeOS:start()
                ~= Result.SUCCESS then
                error("Integrated registration lifecycle did not start")
            end

            if FORGE.ForgeOS:completeStartup()
                ~= Result.NOT_AVAILABLE then
                error("Startup completed without required participants")
            end

            installParticipants()

            if FORGE.ForgeOS:completeStartup()
                    ~= Result.SUCCESS
                or FORGE.ForgeOS:getPhase()
                    ~= Phase.RUNTIME_ACTIVE
                or not FORGE.ForgeOS:isAvailable()
                or not FORGE.ForgeOS:isRuntimeActive()
                or observed.frozen ~= 1
                or observed.started ~= 1 then
                error("Integrated startup completion failed")
            end

            if FORGE.ForgeOS:completeStartup()
                    ~= Result.SUCCESS
                or observed.frozen ~= 1
                or observed.started ~= 1 then
                error("Startup completion is not idempotent")
            end

            if Coordinator:installParticipant(
                createParticipant(
                    Role.DEVICE_REGISTRY
                )
            ) ~= Result.REGISTRATION_CLOSED then
                error("Late participant was not rejected")
            end

            if FORGE.ForgeOS:shutdown()
                    ~= Result.SUCCESS
                or observed.stopped ~= 1
                or cleanupCount ~= 3 then
                error("Integrated registration shutdown failed")
            end

            if FORGE.ForgeOS:start()
                ~= Result.SUCCESS then
                error("Integrated registration restart failed")
            end

            installParticipants()

            if FORGE.ForgeOS:completeStartup()
                    ~= Result.SUCCESS
                or FORGE.ForgeOS:shutdown()
                    ~= Result.SUCCESS
                or observed.frozen ~= 2
                or observed.started ~= 2
                or observed.stopped ~= 2
                or cleanupCount ~= 6 then
                error("Restarted registration lifecycle failed")
            end

            FORGE.EventBus:clearAll()
            FORGE.StateStore:clearAll()
            FORGE.SaveManager:clearAllRegistrations()

        end
    )

    DeviceRegistry.clearRegistrationSet =
        originalClear

    if not success then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.TEST,
            "ForgeOS Registration Lifecycle integration test failed: %s",
            FORGE.Logger:safeToString(
                errorMessage,
                "<unprintable error>"
            )
        )

        return false, errorMessage
    end

    FORGE.Logger:info(
        FORGE.Definitions.LogSource.TEST,
        "ForgeOS Registration Lifecycle integration test passed"
    )

    return true
end
