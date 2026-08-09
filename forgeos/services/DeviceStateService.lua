---=============================================================================
--- FORGE ForgeOS Device State Service
---
--- Owns bounded runtime-only device visibility for the local M2 player.
---=============================================================================

FORGE.DeviceStateService = {}

local Service = FORGE.DeviceStateService
local Result = FORGE.Definitions.ForgeOSResult
local Phase = FORGE.Definitions.ForgeOSPhase
local Visibility = FORGE.Definitions.DeviceVisibility
local Event = FORGE.Definitions.ForgeOSEvent
local PlayerId = FORGE.Definitions.ForgeOSPlayerId

local visibilityByDevice = {}
local hostAvailabilityResolver = nil

local function isIdentifier(value)
    return type(value) == "string"
        and value ~= ""
        and string.find(value, "%s") == nil
end

function Service:setHostAvailabilityResolver(resolver)
    if resolver ~= nil and type(resolver) ~= "function" then
        return Result.INVALID_ARGUMENT
    end

    hostAvailabilityResolver = resolver
    return Result.SUCCESS
end

function Service:initialiseDevice(deviceId)
    if not isIdentifier(deviceId) then
        return Result.INVALID_ARGUMENT
    end

    visibilityByDevice[deviceId] = Visibility.HIDDEN
    return Result.SUCCESS
end

local function changeVisibility(deviceId, requestedVisibility)
    if not isIdentifier(deviceId) then
        return Result.INVALID_ARGUMENT
    end

    if FORGE.ForgeOSCore:getPhase() ~= Phase.RUNTIME_ACTIVE then
        return Result.NOT_AVAILABLE
    end

    if not FORGE.DeviceRegistry:isDeviceRegistered(deviceId) then
        return Result.NOT_REGISTERED
    end

    if hostAvailabilityResolver == nil then
        return Result.NOT_AVAILABLE
    end

    local resolverSucceeded, hostAvailable =
        pcall(hostAvailabilityResolver, deviceId)

    if not resolverSucceeded then
        return Result.INTERNAL_ERROR
    end

    if hostAvailable ~= true then
        return Result.NOT_AVAILABLE
    end

    local previousVisibility = visibilityByDevice[deviceId]

    if previousVisibility == nil then
        return Result.STATE_ERROR
    end

    if previousVisibility == requestedVisibility then
        return Result.SUCCESS
    end

    visibilityByDevice[deviceId] = requestedVisibility

    FORGE.EventBus:publish(
        Event.DEVICE_VISIBILITY_CHANGED,
        {
            playerId = PlayerId.LOCAL,
            deviceId = deviceId,
            previousVisibility = previousVisibility,
            currentVisibility = requestedVisibility
        }
    )

    return Result.SUCCESS
end

function Service:showDevice(deviceId)
    local callSucceeded, result = pcall(
        changeVisibility,
        deviceId,
        Visibility.VISIBLE
    )

    return callSucceeded and result or Result.INTERNAL_ERROR
end

function Service:hideDevice(deviceId)
    local callSucceeded, result = pcall(
        changeVisibility,
        deviceId,
        Visibility.HIDDEN
    )

    return callSucceeded and result or Result.INTERNAL_ERROR
end

function Service:getDeviceVisibility(deviceId)
    if not isIdentifier(deviceId)
        or FORGE.ForgeOSCore:getPhase() ~= Phase.RUNTIME_ACTIVE
        or not FORGE.DeviceRegistry:isDeviceRegistered(deviceId)
        or hostAvailabilityResolver == nil then
        return nil
    end

    local resolverSucceeded, hostAvailable =
        pcall(hostAvailabilityResolver, deviceId)

    if not resolverSucceeded or hostAvailable ~= true then
        return nil
    end

    return visibilityByDevice[deviceId]
end

function Service:clearRuntimeState()
    visibilityByDevice = {}
    hostAvailabilityResolver = nil
    return Result.SUCCESS
end
