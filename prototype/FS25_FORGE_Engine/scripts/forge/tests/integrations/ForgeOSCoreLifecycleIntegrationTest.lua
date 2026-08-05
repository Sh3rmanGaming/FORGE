---=============================================================================
--- FORGE ForgeOS Core Lifecycle Integration Tests
---
--- Manual integration harness for the M2.003A lifecycle foundation.
---
--- Responsibilities:
---     • Verify Core and Bootstrap lifecycle coordination.
---     • Verify state and persistence readiness at registration-open.
---     • Verify registration and runtime phase gates.
---     • Verify clean shutdown and restart.
---
--- This manual harness is invoked by the Engine development test runner.
---=============================================================================

FORGE.Tests = FORGE.Tests or {}

function FORGE.Tests.runForgeOSCoreLifecycleIntegrationTests()
    FORGE.Logger:info(
        FORGE.Definitions.LogSource.TEST,
        "ForgeOS lifecycle integration test started"
    )

    local success, errorMessage = pcall(
        function()
            local Phase =
                FORGE.Definitions.ForgeOSPhase

            local Result =
                FORGE.Definitions.ForgeOSResult

            local Namespace =
                FORGE.Definitions.ForgeOSNamespace.OS

            FORGE.EventBus:clearAll()
            FORGE.StateStore:clearAll()
            FORGE.SaveManager:clearAllRegistrations()

            if FORGE.ForgeOS:start()
                ~= Result.SUCCESS then
                error("Integrated ForgeOS startup failed")
            end

            if FORGE.ForgeOS:getPhase()
                    ~= Phase.REGISTRATION_OPEN
                or not FORGE.ForgeOS
                    :isRegistrationOpen()
                or FORGE.ForgeOS:isAvailable()
                or FORGE.ForgeOS
                    :isRuntimeActive() then
                error("Integrated lifecycle gates are incorrect")
            end

            if not FORGE.StateStore:exists(Namespace)
                or not FORGE.SaveManager
                    :isNamespaceRegistered(Namespace) then
                error("Integrated persistence setup is incomplete")
            end

            if FORGE.ForgeOSCore
                :isRuntimeOperationPermitted() then
                error("Runtime operation was permitted before activation")
            end

            if FORGE.ForgeOS:shutdown()
                    ~= Result.SUCCESS
                or FORGE.ForgeOS:getPhase()
                    ~= Phase.STOPPED then
                error("Integrated ForgeOS shutdown failed")
            end

            if FORGE.ForgeOS:start()
                    ~= Result.SUCCESS
                or FORGE.ForgeOS:getPhase()
                    ~= Phase.REGISTRATION_OPEN
                or FORGE.ForgeOS:shutdown()
                    ~= Result.SUCCESS then
                error("Integrated ForgeOS restart failed")
            end

            FORGE.EventBus:clearAll()
            FORGE.StateStore:clearAll()
            FORGE.SaveManager:clearAllRegistrations()
        end
    )

    if not success then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.TEST,
            "ForgeOS lifecycle integration test failed: %s",
            FORGE.Logger:safeToString(
                errorMessage,
                "<unprintable error>"
            )
        )

        return false, errorMessage
    end

    FORGE.Logger:info(
        FORGE.Definitions.LogSource.TEST,
        "ForgeOS lifecycle integration test passed"
    )

    return true
end
