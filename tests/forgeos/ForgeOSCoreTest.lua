---=============================================================================
--- FORGE ForgeOS Core Tests
---
--- Manual component harness for authoritative ForgeOS lifecycle behaviour.
---
--- Responsibilities:
---     • Verify initial and permitted lifecycle transitions.
---     • Verify rejected transitions do not mutate phase.
---     • Verify lifecycle, compatibility, and operation-gating queries.
---     • Verify the stopped lifecycle can restart safely.
---
--- This manual harness is invoked by the Engine development test runner.
---=============================================================================

FORGE.Tests = FORGE.Tests or {}

function FORGE.Tests.runForgeOSCoreTests()
    FORGE.Logger:info(
        FORGE.Definitions.LogSource.TEST,
        "ForgeOS Core test harness started"
    )

    local success, errorMessage = pcall(
        function()
            local Phase =
                FORGE.Definitions.ForgeOSPhase

            if FORGE.ForgeOS:getPhase()
                ~= Phase.UNAVAILABLE then
                error("ForgeOS initial phase must be unavailable")
            end

            if FORGE.ForgeOS:getAppApiVersion()
                ~= FORGE.Definitions
                    .ForgeOSVersion.APP_API then
                error("ForgeOS app API version query failed")
            end

            if not FORGE.ForgeOS
                :supportsAppApiVersion(1)
                or FORGE.ForgeOS
                    :supportsAppApiVersion(0)
                or FORGE.ForgeOS
                    :supportsAppApiVersion(1.5)
                or FORGE.ForgeOS
                    :supportsAppApiVersion("1") then
                error("ForgeOS compatibility query contract failed")
            end

            if FORGE.ForgeOS:isAvailable()
                or FORGE.ForgeOS:isRegistrationOpen()
                or FORGE.ForgeOS:isRuntimeActive() then
                error("Unavailable ForgeOS reported an active gate")
            end

            if not FORGE.ForgeOSCore:transitionPhase(
                Phase.INITIALISING
            ) then
                error("Initialising transition was rejected")
            end

            if FORGE.ForgeOSCore:transitionPhase(
                Phase.RUNTIME_ACTIVE
            ) then
                error("Invalid runtime-active transition was accepted")
            end

            if FORGE.ForgeOS:getPhase()
                ~= Phase.INITIALISING then
                error("Rejected transition changed the phase")
            end

            if not FORGE.ForgeOSCore:transitionPhase(
                Phase.REGISTRATION_OPEN
            ) then
                error("Registration-open transition was rejected")
            end

            if not FORGE.ForgeOS:isRegistrationOpen()
                or FORGE.ForgeOS:isAvailable()
                or FORGE.ForgeOS:isRuntimeActive() then
                error("Registration-open gates are incorrect")
            end

            if not FORGE.ForgeOSCore:transitionPhase(
                Phase.SHUTTING_DOWN
            ) or not FORGE.ForgeOSCore:transitionPhase(
                Phase.STOPPED
            ) then
                error("Core shutdown transitions failed")
            end

            if not FORGE.ForgeOSCore:transitionPhase(
                Phase.INITIALISING
            ) then
                error("Stopped ForgeOS could not restart")
            end

            if not FORGE.ForgeOSCore:transitionPhase(
                Phase.SHUTTING_DOWN
            ) or not FORGE.ForgeOSCore:transitionPhase(
                Phase.STOPPED
            ) then
                error("Restart cleanup transitions failed")
            end
        end
    )

    if not success then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.TEST,
            "ForgeOS Core test harness failed: %s",
            FORGE.Logger:safeToString(
                errorMessage,
                "<unprintable error>"
            )
        )

        return false, errorMessage
    end

    FORGE.Logger:info(
        FORGE.Definitions.LogSource.TEST,
        "ForgeOS Core test harness passed"
    )

    return true
end
