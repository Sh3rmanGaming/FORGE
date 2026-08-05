---=============================================================================
--- FORGE ForgeOS Bootstrap Tests
---
--- Manual component harness for ForgeOS startup and shutdown coordination.
---
--- Responsibilities:
---     • Verify mandatory state and persistence registration.
---     • Verify lifecycle event timing and payloads.
---     • Verify startup and shutdown idempotence.
---     • Verify cleanup and restart safety.
---
--- This manual harness is invoked by the Engine development test runner.
---=============================================================================

FORGE.Tests = FORGE.Tests or {}

function FORGE.Tests.runForgeOSBootstrapTests()
    FORGE.Logger:info(
        FORGE.Definitions.LogSource.TEST,
        "ForgeOS Bootstrap test harness started"
    )

    local success, errorMessage = pcall(
        function()
            local Phase =
                FORGE.Definitions.ForgeOSPhase

            local Result =
                FORGE.Definitions.ForgeOSResult

            local Event =
                FORGE.Definitions.ForgeOSEvent

            local Namespace =
                FORGE.Definitions.ForgeOSNamespace.OS

            FORGE.EventBus:clearAll()
            FORGE.StateStore:clearAll()
            FORGE.SaveManager:clearAllRegistrations()

            local observed = {
                registrationOpened = 0,
                stopped = 0
            }

            function observed:onRegistrationOpened(payload)
                if payload.phase
                    ~= Phase.REGISTRATION_OPEN
                    or payload.appApiVersion
                        ~= FORGE.Definitions
                            .ForgeOSVersion.APP_API then
                    error("Registration-opened payload is invalid")
                end

                self.registrationOpened =
                    self.registrationOpened + 1
            end

            function observed:onStopped(payload)
                if payload.phase ~= Phase.STOPPED then
                    error("Stopped payload is invalid")
                end

                self.stopped =
                    self.stopped + 1
            end

            FORGE.EventBus:subscribe(
                Event.REGISTRATION_OPENED,
                observed,
                observed.onRegistrationOpened
            )

            FORGE.EventBus:subscribe(
                Event.STOPPED,
                observed,
                observed.onStopped
            )

            if FORGE.ForgeOS:start()
                ~= Result.SUCCESS then
                error("ForgeOS startup failed")
            end

            if FORGE.ForgeOS:getPhase()
                ~= Phase.REGISTRATION_OPEN
                or observed.registrationOpened ~= 1 then
                error("ForgeOS did not enter registration-open")
            end

            local state, found =
                FORGE.StateStore:snapshot(Namespace)

            local localPlayer =
                found
                and state.players
                and state.players[
                    FORGE.Definitions
                        .ForgeOSPlayerId.LOCAL
                ]

            if state.version
                    ~= FORGE.Definitions
                        .ForgeOSVersion.STATE
                or type(localPlayer) ~= "table"
                or localPlayer.activeDeviceId ~= nil
                or type(localPlayer.devices) ~= "table"
                or type(localPlayer.notifications) ~= "table"
                or type(localPlayer.preferences) ~= "table" then
                error("Mandatory ForgeOS state is invalid")
            end

            if not FORGE.SaveManager
                :isNamespaceRegistered(Namespace) then
                error("ForgeOS persistence was not registered")
            end

            if FORGE.ForgeOS:start()
                    ~= Result.SUCCESS
                or observed.registrationOpened ~= 1 then
                error("ForgeOS startup is not idempotent")
            end

            if FORGE.ForgeOS:shutdown()
                    ~= Result.SUCCESS
                or FORGE.ForgeOS:getPhase()
                    ~= Phase.STOPPED
                or observed.stopped ~= 1 then
                error("ForgeOS shutdown failed")
            end

            if FORGE.ForgeOS:shutdown()
                    ~= Result.SUCCESS
                or observed.stopped ~= 1 then
                error("ForgeOS shutdown is not idempotent")
            end

            if FORGE.ForgeOS:start()
                    ~= Result.SUCCESS
                or FORGE.ForgeOS:shutdown()
                    ~= Result.SUCCESS
                or observed.registrationOpened ~= 2
                or observed.stopped ~= 2 then
                error("ForgeOS restart lifecycle failed")
            end

            FORGE.EventBus:clearAll()
            FORGE.StateStore:clearAll()
            FORGE.SaveManager:clearAllRegistrations()
        end
    )

    if not success then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.TEST,
            "ForgeOS Bootstrap test harness failed: %s",
            FORGE.Logger:safeToString(
                errorMessage,
                "<unprintable error>"
            )
        )

        return false, errorMessage
    end

    FORGE.Logger:info(
        FORGE.Definitions.LogSource.TEST,
        "ForgeOS Bootstrap test harness passed"
    )

    return true
end
