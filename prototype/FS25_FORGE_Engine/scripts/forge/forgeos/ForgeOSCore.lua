---=============================================================================
--- FORGE ForgeOS Core
---
--- Owns the authoritative ForgeOS operating phase and lifecycle gates.
---
--- Responsibilities:
---     • Store the authoritative ForgeOS phase.
---     • Enforce approved lifecycle transitions.
---     • Answer lifecycle and operation-gating queries.
---
--- This component must never coordinate startup, persistence, or UI rendering.
---=============================================================================

FORGE.ForgeOSCore = {}

local Phase =
    FORGE.Definitions.ForgeOSPhase

local currentPhase =
    Phase.UNAVAILABLE

local permittedTransitions = {
    [Phase.UNAVAILABLE] = {
        [Phase.INITIALISING] = true
    },
    [Phase.INITIALISING] = {
        [Phase.REGISTRATION_OPEN] = true,
        [Phase.SHUTTING_DOWN] = true
    },
    [Phase.REGISTRATION_OPEN] = {
        [Phase.VALIDATING] = true,
        [Phase.SHUTTING_DOWN] = true
    },
    [Phase.VALIDATING] = {
        [Phase.REGISTRATION_FROZEN] = true,
        [Phase.SHUTTING_DOWN] = true
    },
    [Phase.REGISTRATION_FROZEN] = {
        [Phase.RUNTIME_ACTIVE] = true,
        [Phase.SHUTTING_DOWN] = true
    },
    [Phase.RUNTIME_ACTIVE] = {
        [Phase.SHUTTING_DOWN] = true
    },
    [Phase.SHUTTING_DOWN] = {
        [Phase.STOPPED] = true
    },
    [Phase.STOPPED] = {
        [Phase.INITIALISING] = true
    }
}

--- Returns the authoritative ForgeOS operating phase.
-- @return string phase
function FORGE.ForgeOSCore:getPhase()
    return currentPhase
end

--- Returns whether a phase transition is permitted.
-- @param nextPhase any
-- @return boolean permitted
function FORGE.ForgeOSCore:canTransitionTo(nextPhase)
    local phaseTransitions =
        permittedTransitions[currentPhase]

    return phaseTransitions ~= nil
        and phaseTransitions[nextPhase] == true
end

--- Performs one permitted authoritative phase transition.
---
--- This is an internal lifecycle operation used only by ForgeOS Bootstrap.
-- @param nextPhase any
-- @return boolean transitioned
function FORGE.ForgeOSCore:transitionPhase(nextPhase)
    if not self:canTransitionTo(nextPhase) then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.FORGE_OS,
            "Rejected ForgeOS phase transition from '%s' to '%s'",
            currentPhase,
            FORGE.Logger:safeToString(
                nextPhase,
                "<unprintable>"
            )
        )

        return false
    end

    currentPhase = nextPhase

    return true
end

--- Returns whether content registration is currently permitted.
-- @return boolean permitted
function FORGE.ForgeOSCore:isRegistrationOperationPermitted()
    return currentPhase
        == Phase.REGISTRATION_OPEN
end

--- Returns whether normal runtime operations are currently permitted.
-- @return boolean permitted
function FORGE.ForgeOSCore:isRuntimeOperationPermitted()
    return currentPhase
        == Phase.RUNTIME_ACTIVE
end
