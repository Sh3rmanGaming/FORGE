---=============================================================================
--- FORGE ForgeOS Device Registry
---
--- Owns authoritative device definitions for one ForgeOS lifecycle.
---
--- Responsibilities:
---     • Validate and register controlled device definitions.
---     • Provide detached deterministic device-definition queries.
---     • Participate in registration validation, freeze, and cleanup.
---     • Publish completed device registrations.
---
--- This component must never own device hosts, player state, gameplay, or UI.
---=============================================================================

FORGE.DeviceRegistry = {}

local Registry =
    FORGE.DeviceRegistry

local Result =
    FORGE.Definitions.ForgeOSResult

local Event =
    FORGE.Definitions.ForgeOSEvent

local Capability =
    FORGE.Definitions.DeviceCapability

local registeredDefinitions = {}
local registrationFrozen = false

local recognisedCapabilities = {}

for _, capabilityId in pairs(Capability) do
    recognisedCapabilities[capabilityId] = true
end

local function isFiniteNumber(value)
    return value == value
        and value ~= math.huge
        and value ~= -math.huge
end

local function copyPlainValue(value, visited)
    local valueType = type(value)

    if valueType == "nil"
        or valueType == "boolean"
        or valueType == "string" then
        return true, value
    end

    if valueType == "number" then
        if not isFiniteNumber(value) then
            return false, nil
        end

        return true, value
    end

    if valueType ~= "table"
        or visited[value]
        or getmetatable(value) ~= nil then
        return false, nil
    end

    visited[value] = true

    local copy = {}

    for key, nestedValue in pairs(value) do
        local keyValid, keyCopy =
            copyPlainValue(key, visited)

        local valueValid, valueCopy =
            copyPlainValue(nestedValue, visited)

        if not keyValid or not valueValid then
            visited[value] = nil

            return false, nil
        end

        copy[keyCopy] = valueCopy
    end

    visited[value] = nil

    return true, copy
end

local function isNonEmptyString(value)
    return type(value) == "string"
        and value ~= ""
end

local function isIdentifier(value)
    return isNonEmptyString(value)
        and string.find(value, "%s") == nil
end

local function copyCapabilities(capabilities)
    if type(capabilities) ~= "table" then
        return false, nil
    end

    local copy = {}

    for capabilityId, enabled in pairs(
        capabilities
    ) do
        if recognisedCapabilities[capabilityId]
                ~= true
            or type(enabled) ~= "boolean" then
            return false, nil
        end

        copy[capabilityId] = enabled
    end

    return true, copy
end

local function copyOptionalTable(value)
    if value == nil then
        return true, nil
    end

    if type(value) ~= "table" then
        return false, nil
    end

    return copyPlainValue(value, {})
end

local function createControlledDefinition(
    definition
)
    if not isIdentifier(definition.id)
        or not isNonEmptyString(
            definition.displayName
        ) then
        return nil
    end

    local capabilitiesValid,
        capabilitiesCopy =
            copyCapabilities(
                definition.capabilities
            )

    if not capabilitiesValid then
        return nil
    end

    if definition.hostId ~= nil
        and not isIdentifier(
            definition.hostId
        ) then
        return nil
    end

    local policyValid, policyCopy =
        copyOptionalTable(definition.policy)

    if not policyValid then
        return nil
    end

    local metadataValid, metadataCopy =
        copyOptionalTable(definition.metadata)

    if not metadataValid then
        return nil
    end

    local controlled = {
        id = definition.id,
        displayName = definition.displayName,
        capabilities = capabilitiesCopy
    }

    if definition.hostId ~= nil then
        controlled.hostId = definition.hostId
    end

    if policyCopy ~= nil then
        controlled.policy = policyCopy
    end

    if metadataCopy ~= nil then
        controlled.metadata = metadataCopy
    end

    return controlled
end

local function copyDefinition(definition)
    local valid, copy =
        copyPlainValue(definition, {})

    if not valid then
        return nil
    end

    return copy
end

--- Returns the coordinator-owned Device Registry role.
-- @return string role
function Registry:getRegistrationRole()
    return FORGE.ForgeOSRegistrationCoordinator
        .Role.DEVICE_REGISTRY
end

--- Registers one controlled device definition.
-- @param deviceDefinition any
-- @return string result
function Registry:registerDevice(deviceDefinition)
    local gateResult =
        FORGE.ForgeOSRegistrationCoordinator
            :getRegistrationGateResult()

    if gateResult ~= Result.SUCCESS
        or registrationFrozen then
        return Result.REGISTRATION_CLOSED
    end

    if type(deviceDefinition) ~= "table" then
        return Result.INVALID_ARGUMENT
    end

    local callSucceeded, operationResult =
        pcall(
            function()
                local controlled =
                    createControlledDefinition(
                        deviceDefinition
                    )

                if controlled == nil then
                    return Result.INVALID_DEFINITION
                end

                if registeredDefinitions[
                    controlled.id
                ] ~= nil then
                    return Result.ALREADY_REGISTERED
                end

                registeredDefinitions[
                    controlled.id
                ] = controlled

                FORGE.EventBus:publish(
                    Event.DEVICE_REGISTERED,
                    {
                        deviceId = controlled.id
                    }
                )

                return Result.SUCCESS
            end
        )

    if not callSucceeded then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.DEVICE_REGISTRY,
            "Unexpected device registration failure: %s",
            FORGE.Logger:safeToString(
                operationResult,
                "<unprintable error>"
            )
        )

        return Result.INTERNAL_ERROR
    end

    return operationResult
end

--- Returns whether a device identifier is registered.
-- @param deviceId any
-- @return boolean registered
function Registry:isDeviceRegistered(deviceId)
    return type(deviceId) == "string"
        and registeredDefinitions[deviceId]
            ~= nil
end

--- Returns a detached registered device definition.
-- @param deviceId any
-- @return table|nil definition
function Registry:getDeviceDefinition(deviceId)
    if type(deviceId) ~= "string" then
        return nil
    end

    local definition =
        registeredDefinitions[deviceId]

    if definition == nil then
        return nil
    end

    return copyDefinition(definition)
end

--- Returns detached registered identifiers in lexical order.
-- @return table identifiers
function Registry:getRegisteredDeviceIds()
    local identifiers = {}

    for deviceId in pairs(
        registeredDefinitions
    ) do
        table.insert(identifiers, deviceId)
    end

    table.sort(identifiers)

    return identifiers
end

--- Validates the complete controlled registration set.
-- @return string result
function Registry:validateRegistrationSet()
    for deviceId, definition in pairs(
        registeredDefinitions
    ) do
        local controlled =
            createControlledDefinition(
                definition
            )

        if controlled == nil
            or controlled.id ~= deviceId then
            return Result.INVALID_DEFINITION
        end
    end

    return Result.SUCCESS
end

--- Validates and freezes device registrations.
-- @return string result
function Registry:freezeRegistrationSet()
    if registrationFrozen then
        return Result.SUCCESS
    end

    local validationResult =
        self:validateRegistrationSet()

    if validationResult ~= Result.SUCCESS then
        return validationResult
    end

    registrationFrozen = true

    return Result.SUCCESS
end

--- Clears all definitions and resets the frozen state.
-- @return string result
function Registry:clearRegistrationSet()
    registeredDefinitions = {}
    registrationFrozen = false

    return Result.SUCCESS
end

--- Returns whether device registration is frozen.
-- @return boolean frozen
function Registry:isRegistrationSetFrozen()
    return registrationFrozen
end
