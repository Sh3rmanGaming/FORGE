---=============================================================================
--- FORGE ForgeOS Registration Coordinator
---
--- Coordinates the internal ForgeOS registration lifecycle participants.
---
--- Responsibilities:
---     • Define authoritative internal registration-participant roles.
---     • Install exactly one participant for each required role.
---     • Orchestrate deterministic validation and registration freeze.
---     • Provide the shared registration phase gate.
---     • Coordinate participant cleanup.
---
--- This component must never own registry data or registry-specific invariants.
---=============================================================================

FORGE.ForgeOSRegistrationCoordinator = {}

local Coordinator =
    FORGE.ForgeOSRegistrationCoordinator

Coordinator.Role = {
    DEVICE_REGISTRY = "deviceRegistry",
    DEVICE_HOST_REGISTRY = "deviceHostRegistry",
    APP_REGISTRY = "appRegistry"
}

local Phase =
    FORGE.Definitions.ForgeOSPhase

local Result =
    FORGE.Definitions.ForgeOSResult

local Event =
    FORGE.Definitions.ForgeOSEvent

local roleOrder = {
    Coordinator.Role.DEVICE_REGISTRY,
    Coordinator.Role.DEVICE_HOST_REGISTRY,
    Coordinator.Role.APP_REGISTRY
}

local recognisedRoles = {
    [Coordinator.Role.DEVICE_REGISTRY] = true,
    [Coordinator.Role.DEVICE_HOST_REGISTRY] = true,
    [Coordinator.Role.APP_REGISTRY] = true
}

local participants = {}

local requiredOperations = {
    "getRegistrationRole",
    "validateRegistrationSet",
    "freezeRegistrationSet",
    "clearRegistrationSet",
    "isRegistrationSetFrozen"
}

local function callParticipant(
    participant,
    operationName
)
    local callSucceeded, operationResult =
        pcall(
            participant[operationName],
            participant
        )

    if not callSucceeded then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.FORGE_OS,
            "Registration participant operation '%s' failed: %s",
            operationName,
            FORGE.Logger:safeToString(
                operationResult,
                "<unprintable error>"
            )
        )

        return Result.INTERNAL_ERROR
    end

    return operationResult
end

local function getParticipantRole(participant)
    if type(participant) ~= "table" then
        return nil
    end

    for _, operationName in ipairs(
        requiredOperations
    ) do
        if type(participant[operationName])
            ~= "function" then
            return nil
        end
    end

    local callSucceeded, role =
        pcall(
            participant.getRegistrationRole,
            participant
        )

    if not callSucceeded
        or recognisedRoles[role] ~= true then
        return nil
    end

    return role
end

local function hasCompleteParticipantSet()
    for _, role in ipairs(roleOrder) do
        if participants[role] == nil then
            return false
        end
    end

    return true
end

--- Returns the shared registration phase-gate result.
-- @return string result
function Coordinator:getRegistrationGateResult()
    if FORGE.ForgeOSCore:getPhase()
        == Phase.REGISTRATION_OPEN then
        return Result.SUCCESS
    end

    return Result.REGISTRATION_CLOSED
end

--- Installs one internal registration participant for the current lifecycle.
-- @param participant any
-- @return string result
function Coordinator:installParticipant(participant)
    local gateResult =
        self:getRegistrationGateResult()

    if gateResult ~= Result.SUCCESS then
        return gateResult
    end

    local role =
        getParticipantRole(participant)

    if role == nil then
        return Result.INVALID_ARGUMENT
    end

    if participants[role] ~= nil then
        return Result.ALREADY_REGISTERED
    end

    participants[role] = participant

    return Result.SUCCESS
end

--- Returns whether every required participant role is installed.
-- @return boolean complete
function Coordinator:hasCompleteParticipantSet()
    return hasCompleteParticipantSet()
end

--- Validates and freezes all installed registration participants.
---
--- This internal operation leaves ForgeOS at REGISTRATION_FROZEN on success.
-- @return string result
function Coordinator:completeRegistration()
    if self:getRegistrationGateResult()
        ~= Result.SUCCESS then
        return Result.INVALID_TRANSITION
    end

    if not hasCompleteParticipantSet() then
        return Result.NOT_AVAILABLE
    end

    if not FORGE.ForgeOSCore:transitionPhase(
        Phase.VALIDATING
    ) then
        return Result.INTERNAL_ERROR
    end

    for _, role in ipairs(roleOrder) do
        local validationResult =
            callParticipant(
                participants[role],
                "validateRegistrationSet"
            )

        if validationResult ~= Result.SUCCESS then
            return validationResult
        end
    end

    if not FORGE.ForgeOSCore:transitionPhase(
        Phase.REGISTRATION_FROZEN
    ) then
        return Result.INTERNAL_ERROR
    end

    for _, role in ipairs(roleOrder) do
        local participant =
            participants[role]

        local freezeResult =
            callParticipant(
                participant,
                "freezeRegistrationSet"
            )

        if freezeResult ~= Result.SUCCESS then
            return freezeResult
        end

        local callSucceeded, frozen =
            pcall(
                participant
                    .isRegistrationSetFrozen,
                participant
            )

        if not callSucceeded or frozen ~= true then
            return Result.INTERNAL_ERROR
        end
    end

    FORGE.EventBus:publish(
        Event.REGISTRATION_FROZEN,
        {
            phase =
                Phase.REGISTRATION_FROZEN
        }
    )

    FORGE.Logger:info(
        FORGE.Definitions.LogSource.FORGE_OS,
        "ForgeOS registration frozen"
    )

    return Result.SUCCESS
end

--- Clears every installed participant and its assignment.
-- @return string result
function Coordinator:clearRegistrationParticipants()
    local cleanupResult =
        Result.SUCCESS

    for _, role in ipairs(roleOrder) do
        local participant =
            participants[role]

        if participant ~= nil then
            local participantResult =
                callParticipant(
                    participant,
                    "clearRegistrationSet"
                )

            if cleanupResult == Result.SUCCESS
                and participantResult
                    ~= Result.SUCCESS then
                cleanupResult =
                    participantResult
            end
        end
    end

    participants = {}

    return cleanupResult
end
