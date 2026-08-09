---=============================================================================
--- FORGE ForgeOS Device Host Registry
---
--- Owns immutable device-host implementation registrations for one lifecycle.
--- Runtime host instances returned by this registry are owned by ForgeOS.
---=============================================================================

FORGE.DeviceHostRegistry = {}

local Registry = FORGE.DeviceHostRegistry
local Result = FORGE.Definitions.ForgeOSResult

local registeredDefinitions = {}
local registrationFrozen = false

local function isIdentifier(value)
    return type(value) == "string"
        and value ~= ""
        and string.find(value, "%s") == nil
end

local function createControlledDefinition(definition)
    if type(definition) ~= "table"
        or not isIdentifier(definition.id)
        or not isIdentifier(definition.deviceId)
        or type(definition.createInstance) ~= "function" then
        return nil
    end

    return {
        id = definition.id,
        deviceId = definition.deviceId,
        createInstance = definition.createInstance
    }
end

function Registry:getRegistrationRole()
    return FORGE.ForgeOSRegistrationCoordinator
        .Role.DEVICE_HOST_REGISTRY
end

function Registry:registerHost(hostDefinition)
    local gateResult =
        FORGE.ForgeOSRegistrationCoordinator
            :getRegistrationGateResult()

    if gateResult ~= Result.SUCCESS
        or registrationFrozen then
        return Result.REGISTRATION_CLOSED
    end

    if type(hostDefinition) ~= "table" then
        return Result.INVALID_ARGUMENT
    end

    local callSucceeded, operationResult = pcall(function()
        local controlled =
            createControlledDefinition(hostDefinition)

        if controlled == nil then
            return Result.INVALID_DEFINITION
        end

        if registeredDefinitions[controlled.id] ~= nil then
            return Result.ALREADY_REGISTERED
        end

        registeredDefinitions[controlled.id] = controlled
        return Result.SUCCESS
    end)

    if not callSucceeded then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.FORGE_OS,
            "Unexpected device Host registration failure: %s",
            FORGE.Logger:safeToString(
                operationResult,
                "<unprintable error>"
            )
        )

        return Result.INTERNAL_ERROR
    end

    return operationResult
end

function Registry:isHostRegistered(hostId)
    return type(hostId) == "string"
        and registeredDefinitions[hostId] ~= nil
end

function Registry:getHostDeviceId(hostId)
    local definition = registeredDefinitions[hostId]
    return definition ~= nil and definition.deviceId or nil
end

function Registry:createHostInstance(hostId, context)
    if not isIdentifier(hostId) or type(context) ~= "table" then
        return Result.INVALID_ARGUMENT, nil
    end

    if not registrationFrozen then
        return Result.NOT_AVAILABLE, nil
    end

    local definition = registeredDefinitions[hostId]

    if definition == nil then
        return Result.NOT_REGISTERED, nil
    end

    local callSucceeded, hostInstance =
        pcall(definition.createInstance, context)

    if not callSucceeded or type(hostInstance) ~= "table" then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.FORGE_OS,
            "Device Host '%s' instance construction failed: %s",
            hostId,
            FORGE.Logger:safeToString(
                hostInstance,
                "<unprintable error>"
            )
        )

        return Result.INTERNAL_ERROR, nil
    end

    return Result.SUCCESS, hostInstance
end

function Registry:validateRegistrationSet()
    for hostId, definition in pairs(registeredDefinitions) do
        if createControlledDefinition(definition) == nil
            or definition.id ~= hostId then
            return Result.INVALID_DEFINITION
        end

        local device =
            FORGE.DeviceRegistry:getDeviceDefinition(
                definition.deviceId
            )

        if device == nil or device.hostId ~= hostId then
            return Result.INVALID_DEFINITION
        end
    end

    for _, deviceId in ipairs(
        FORGE.DeviceRegistry:getRegisteredDeviceIds()
    ) do
        local device =
            FORGE.DeviceRegistry:getDeviceDefinition(deviceId)

        if device.hostId ~= nil then
            local host = registeredDefinitions[device.hostId]

            if host == nil or host.deviceId ~= deviceId then
                return Result.INVALID_DEFINITION
            end
        end
    end

    return Result.SUCCESS
end

function Registry:freezeRegistrationSet()
    if registrationFrozen then
        return Result.SUCCESS
    end

    local validationResult = self:validateRegistrationSet()

    if validationResult ~= Result.SUCCESS then
        return validationResult
    end

    registrationFrozen = true
    return Result.SUCCESS
end

function Registry:clearRegistrationSet()
    registeredDefinitions = {}
    registrationFrozen = false
    return Result.SUCCESS
end

function Registry:isRegistrationSetFrozen()
    return registrationFrozen
end
