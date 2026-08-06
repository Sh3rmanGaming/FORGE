---=============================================================================
--- FORGE ForgeOS Registration Coordinator Tests
---
--- Manual component harness for M2.003B registration coordination.
---
--- Responsibilities:
---     • Verify participant installation and role completeness.
---     • Verify deterministic validation and freeze ordering.
---     • Verify late-participant rejection.
---     • Verify validation, freeze, shutdown, and restart cleanup.
---
--- This manual harness is invoked by the Engine development test runner.
---=============================================================================

FORGE.Tests = FORGE.Tests or {}

function FORGE.Tests.runForgeOSRegistrationCoordinatorTests()
    FORGE.Logger:info(
        FORGE.Definitions.LogSource.TEST,
        "ForgeOS Registration Coordinator test harness started"
    )

    local DeviceRegistry =
        FORGE.DeviceRegistry

    local originalValidate =
        DeviceRegistry.validateRegistrationSet

    local originalFreeze =
        DeviceRegistry.freezeRegistrationSet

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

            local trace = {}
            local insideDeviceFreeze = false

            function DeviceRegistry:validateRegistrationSet()
                if not insideDeviceFreeze then
                    table.insert(
                        trace,
                        "validate:"
                            .. Coordinator.Role
                                .DEVICE_REGISTRY
                    )
                end

                return originalValidate(self)
            end

            function DeviceRegistry:freezeRegistrationSet()
                table.insert(
                    trace,
                    "freeze:"
                        .. Coordinator.Role
                            .DEVICE_REGISTRY
                )

                insideDeviceFreeze = true

                local callSucceeded, result =
                    pcall(originalFreeze, self)

                insideDeviceFreeze = false

                if not callSucceeded then
                    error(result)
                end

                return result
            end

            local function createParticipant(
                role,
                validationResult,
                freezeResult
            )
                local participant = {
                    role = role,
                    validationResult =
                        validationResult
                        or Result.SUCCESS,
                    freezeResult =
                        freezeResult
                        or Result.SUCCESS,
                    frozen = false
                }

                function participant:getRegistrationRole()
                    return self.role
                end

                function participant:validateRegistrationSet()
                    table.insert(
                        trace,
                        "validate:" .. self.role
                    )

                    return self.validationResult
                end

                function participant:freezeRegistrationSet()
                    table.insert(
                        trace,
                        "freeze:" .. self.role
                    )

                    if self.freezeResult
                        == Result.SUCCESS then
                        self.frozen = true
                    end

                    return self.freezeResult
                end

                function participant:clearRegistrationSet()
                    table.insert(
                        trace,
                        "clear:" .. self.role
                    )

                    self.frozen = false

                    return Result.SUCCESS
                end

                function participant:isRegistrationSetFrozen()
                    return self.frozen
                end

                return participant
            end

            local function startLifecycle()
                FORGE.EventBus:clearAll()
                FORGE.StateStore:clearAll()
                FORGE.SaveManager:clearAllRegistrations()
                Coordinator
                    :clearRegistrationParticipants()

                if FORGE.ForgeOS:start()
                    ~= Result.SUCCESS then
                    error("Unable to start test lifecycle")
                end
            end

            startLifecycle()

            if Coordinator:installParticipant({})
                ~= Result.INVALID_ARGUMENT then
                error("Invalid participant was accepted")
            end

            local host =
                createParticipant(
                    Role.DEVICE_HOST_REGISTRY
                )

            local app =
                createParticipant(
                    Role.APP_REGISTRY
                )

            if Coordinator:installParticipant(app)
                    ~= Result.SUCCESS
                or Coordinator:installParticipant(host)
                    ~= Result.SUCCESS
                or not Coordinator
                    :hasCompleteParticipantSet() then
                error("Complete participant set was not installed")
            end

            if Coordinator:installParticipant(
                createParticipant(
                    Role.DEVICE_REGISTRY
                )
            ) ~= Result.ALREADY_REGISTERED then
                error("Duplicate participant role was accepted")
            end

            if Coordinator:completeRegistration()
                    ~= Result.SUCCESS
                or FORGE.ForgeOS:getPhase()
                    ~= Phase.REGISTRATION_FROZEN then
                error("Registration coordination did not freeze")
            end

            local expectedTrace = {
                "validate:" .. Role.DEVICE_REGISTRY,
                "validate:" .. Role.DEVICE_HOST_REGISTRY,
                "validate:" .. Role.APP_REGISTRY,
                "freeze:" .. Role.DEVICE_REGISTRY,
                "freeze:" .. Role.DEVICE_HOST_REGISTRY,
                "freeze:" .. Role.APP_REGISTRY
            }

            if #trace ~= #expectedTrace then
                error("Participant order trace contained unexpected callbacks")
            end

            for index, expected in ipairs(
                expectedTrace
            ) do
                if trace[index] ~= expected then
                    error("Participant order was not deterministic")
                end
            end

            if Coordinator:installParticipant(
                createParticipant(
                    Role.DEVICE_REGISTRY
                )
            ) ~= Result.REGISTRATION_CLOSED then
                error("Late participant installation was accepted")
            end

            if FORGE.ForgeOS:shutdown()
                ~= Result.SUCCESS then
                error("Frozen lifecycle did not shut down")
            end

            trace = {}
            startLifecycle()

            Coordinator:installParticipant(
                createParticipant(
                    Role.DEVICE_HOST_REGISTRY,
                    Result.INVALID_DEFINITION
                )
            )

            Coordinator:installParticipant(
                createParticipant(
                    Role.APP_REGISTRY
                )
            )

            if Coordinator:completeRegistration()
                    ~= Result.INVALID_DEFINITION
                or FORGE.ForgeOS:getPhase()
                    ~= Phase.VALIDATING then
                error("Validation failure was not preserved")
            end

            if #trace ~= 2 then
                error("Validation continued after participant failure")
            end

            if FORGE.ForgeOS:shutdown()
                ~= Result.SUCCESS then
                error("Validation failure cleanup failed")
            end

            trace = {}
            startLifecycle()

            Coordinator:installParticipant(
                createParticipant(
                    Role.DEVICE_HOST_REGISTRY,
                    Result.SUCCESS,
                    Result.INTERNAL_ERROR
                )
            )

            Coordinator:installParticipant(
                createParticipant(
                    Role.APP_REGISTRY
                )
            )

            if Coordinator:completeRegistration()
                    ~= Result.INTERNAL_ERROR
                or FORGE.ForgeOS:getPhase()
                    ~= Phase.REGISTRATION_FROZEN then
                error("Freeze failure was not preserved")
            end

            if FORGE.ForgeOS:shutdown()
                ~= Result.SUCCESS then
                error("Freeze failure cleanup failed")
            end

            FORGE.EventBus:clearAll()
            FORGE.StateStore:clearAll()
            FORGE.SaveManager:clearAllRegistrations()

        end
    )

    DeviceRegistry.validateRegistrationSet =
        originalValidate

    DeviceRegistry.freezeRegistrationSet =
        originalFreeze

    local cleanupSucceeded, cleanupError =
        pcall(
            function()
                local Result =
                    FORGE.Definitions
                        .ForgeOSResult

                if FORGE.ForgeOS:shutdown()
                    ~= Result.SUCCESS then
                    error("ForgeOS test cleanup failed")
                end

                if FORGE
                    .ForgeOSRegistrationCoordinator
                    :clearRegistrationParticipants()
                    ~= Result.SUCCESS then
                    error("Registration participant cleanup failed")
                end

                FORGE.EventBus:clearAll()
                FORGE.StateStore:clearAll()
                FORGE.SaveManager
                    :clearAllRegistrations()
            end
        )

    if not cleanupSucceeded then
        if success then
            success = false
            errorMessage = cleanupError
        else
            FORGE.Logger:error(
                FORGE.Definitions.LogSource.TEST,
                "ForgeOS Registration Coordinator test cleanup also failed: %s",
                FORGE.Logger:safeToString(
                    cleanupError,
                    "<unprintable error>"
                )
            )
        end
    end

    if not success then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.TEST,
            "ForgeOS Registration Coordinator test harness failed: %s",
            FORGE.Logger:safeToString(
                errorMessage,
                "<unprintable error>"
            )
        )

        return false, errorMessage
    end

    FORGE.Logger:info(
        FORGE.Definitions.LogSource.TEST,
        "ForgeOS Registration Coordinator test harness passed"
    )

    return true
end
