---=============================================================================
--- FORGE ForgeOS Navigation Service
---
--- Owns logical route navigation for active local-player applications.
---
--- Responsibilities:
---     • Validate and commit presentation-scoped route navigation.
---     • Maintain bounded runtime history and deterministic back navigation.
---     • Update detached persistent resume destinations.
---     • Publish completed navigation events.
---
--- This service must never render UI or execute application assets.
---=============================================================================

FORGE.NavigationService = {}

local Service = FORGE.NavigationService
local Result = FORGE.Definitions.ForgeOSResult
local Phase = FORGE.Definitions.ForgeOSPhase
local Lifecycle = FORGE.Definitions.AppLifecycleState
local Event = FORGE.Definitions.ForgeOSEvent
local PlayerId = FORGE.Definitions.ForgeOSPlayerId.LOCAL
local Namespace = FORGE.Definitions.ForgeOSNamespace.OS
local MAX_HISTORY = 32

local records = {}

local function isIdentifier(value)
    return type(value) == "string"
        and value ~= ""
        and string.find(value, "%s") == nil
end

local function copyPlain(value, visited)
    local valueType = type(value)
    if valueType == "string" or valueType == "boolean" then
        return true, value
    end
    if valueType == "number" then
        return value == value
            and value ~= math.huge
            and value ~= -math.huge,
            value
    end
    if valueType ~= "table"
        or getmetatable(value) ~= nil
        or visited[value] then
        return false, nil
    end

    visited[value] = true
    local copy = {}
    for key, nested in pairs(value) do
        if type(key) ~= "string" then
            return false, nil
        end
        local valid, nestedCopy = copyPlain(nested, visited)
        if not valid then
            return false, nil
        end
        copy[key] = nestedCopy
    end
    return true, copy
end

local function copyParameters(value)
    if value == nil then
        return true, {}
    end
    if type(value) ~= "table" then
        return false, nil
    end
    return copyPlain(value, {})
end

local function equalPlain(left, right)
    if type(left) ~= type(right) then
        return false
    end
    if type(left) ~= "table" then
        return left == right
    end
    for key, value in pairs(left) do
        if not equalPlain(value, right[key]) then
            return false
        end
    end
    for key in pairs(right) do
        if left[key] == nil then
            return false
        end
    end
    return true
end

local function getRecord(deviceId, appId)
    local deviceRecords = records[deviceId]
    return deviceRecords ~= nil
        and deviceRecords[appId]
        or nil
end

local function setRecord(deviceId, appId, record)
    records[deviceId] = records[deviceId] or {}
    records[deviceId][appId] = record
end

local function validateGate(deviceId, appId)
    if FORGE.ForgeOSCore:getPhase()
        ~= Phase.RUNTIME_ACTIVE then
        return Result.NOT_AVAILABLE
    end
    if not FORGE.DeviceRegistry:isDeviceRegistered(deviceId)
        or not FORGE.AppRegistry:isAppRegistered(appId) then
        return Result.NOT_REGISTERED
    end
    if FORGE.AppLifecycleService:getAppLifecycleState(
        deviceId,
        appId
    ) ~= Lifecycle.ACTIVE then
        return Result.INVALID_TRANSITION
    end
    return Result.SUCCESS
end

local function resolve(deviceId, appId)
    local result, resolution = FORGE.PresentationResolver
        :resolvePresentation(appId, deviceId)
    if result ~= Result.SUCCESS then
        return result, nil
    end
    return Result.SUCCESS, resolution
end

local function updateResume(
    deviceId,
    appId,
    resolution,
    routeId,
    parameters
)
    local state, found = FORGE.StateStore:snapshot(Namespace)
    if not found or type(state.players) ~= "table" then
        return false
    end
    local player = state.players[PlayerId]
    if type(player) ~= "table" then
        return false
    end
    player.devices = player.devices or {}
    player.devices[deviceId] = player.devices[deviceId] or {}
    player.devices[deviceId].resume = {
        appId = appId,
        presentationId = resolution.presentationId,
        routeId = routeId,
        routeParameters = parameters
    }
    return FORGE.StateStore:replaceNamespace(Namespace, state)
end

local function publish(
    deviceId,
    appId,
    previousRoute,
    currentRoute,
    parameters,
    isBack
)
    local _, detached = copyParameters(parameters)
    FORGE.EventBus:publish(Event.NAVIGATION_CHANGED, {
        playerId = PlayerId,
        deviceId = deviceId,
        appId = appId,
        previousRoute = previousRoute,
        currentRoute = currentRoute,
        routeParameters = detached,
        isBackNavigation = isBack
    })
end

local function validateArguments(
    deviceId,
    appId,
    routeId,
    routeParameters
)
    if not isIdentifier(deviceId)
        or not isIdentifier(appId)
        or (routeId ~= nil and not isIdentifier(routeId)) then
        return Result.INVALID_ARGUMENT, nil
    end
    local valid, parameters = copyParameters(routeParameters)
    if not valid then
        return Result.INVALID_ARGUMENT, nil
    end
    return Result.SUCCESS, parameters
end

local function navigate(deviceId, appId, routeId, routeParameters)
    local argumentResult, parameters = validateArguments(
        deviceId,
        appId,
        routeId,
        routeParameters
    )
    if argumentResult ~= Result.SUCCESS then
        return argumentResult
    end
    local gateResult = validateGate(deviceId, appId)
    if gateResult ~= Result.SUCCESS then
        return gateResult
    end
    local resolutionResult, resolution = resolve(deviceId, appId)
    if resolutionResult ~= Result.SUCCESS then
        return resolutionResult
    end
    if resolution.presentation.routes[routeId] == nil then
        return Result.ROUTE_NOT_FOUND
    end

    local record = getRecord(deviceId, appId)
    if record ~= nil
        and record.currentRoute == routeId
        and equalPlain(record.currentParameters, parameters) then
        return Result.SUCCESS
    end

    local history = {}
    if record ~= nil then
        for _, entry in ipairs(record.history) do
            table.insert(history, entry)
        end
        table.insert(history, {
            routeId = record.currentRoute,
            routeParameters = record.currentParameters
        })
        if #history > MAX_HISTORY then
            table.remove(history, 1)
        end
    end

    if not updateResume(
        deviceId,
        appId,
        resolution,
        routeId,
        parameters
    ) then
        return Result.STATE_ERROR
    end

    local previousRoute = record ~= nil and record.currentRoute or nil
    setRecord(deviceId, appId, {
        currentRoute = routeId,
        currentParameters = parameters,
        history = history
    })
    publish(
        deviceId,
        appId,
        previousRoute,
        routeId,
        parameters,
        false
    )
    return Result.SUCCESS
end

local function goBack(deviceId, appId)
    local argumentResult = validateArguments(deviceId, appId, nil, nil)
    if argumentResult ~= Result.SUCCESS then
        return argumentResult
    end
    local gateResult = validateGate(deviceId, appId)
    if gateResult ~= Result.SUCCESS then
        return gateResult
    end
    local resolutionResult, resolution = resolve(deviceId, appId)
    if resolutionResult ~= Result.SUCCESS then
        return resolutionResult
    end

    local record = getRecord(deviceId, appId)
    if record == nil or #record.history == 0 then
        return Result.ROUTE_NOT_FOUND
    end

    local history = {}
    for _, entry in ipairs(record.history) do
        table.insert(history, entry)
    end
    local selected = nil
    while #history > 0 do
        local candidate = table.remove(history)
        if resolution.presentation.routes[candidate.routeId] ~= nil then
            selected = candidate
            break
        end
    end
    if selected == nil then
        record.history = history
        return Result.ROUTE_NOT_FOUND
    end

    if not updateResume(
        deviceId,
        appId,
        resolution,
        selected.routeId,
        selected.routeParameters
    ) then
        return Result.STATE_ERROR
    end

    local previousRoute = record.currentRoute
    record.currentRoute = selected.routeId
    record.currentParameters = selected.routeParameters
    record.history = history
    publish(
        deviceId,
        appId,
        previousRoute,
        selected.routeId,
        selected.routeParameters,
        true
    )
    return Result.SUCCESS
end

local function runOperation(operation, ...)
    local call = { pcall(operation, ...) }
    if not call[1] then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.NAVIGATION,
            "Unexpected Navigation Service failure: %s",
            FORGE.Logger:safeToString(call[2], "<unprintable error>")
        )
        return Result.INTERNAL_ERROR
    end
    return call[2]
end

function Service:navigate(deviceId, appId, routeId, routeParameters)
    return runOperation(
        navigate,
        deviceId,
        appId,
        routeId,
        routeParameters
    )
end

function Service:goBack(deviceId, appId)
    return runOperation(goBack, deviceId, appId)
end

function Service:getCurrentRoute(deviceId, appId)
    local record = getRecord(deviceId, appId)
    if record == nil then
        return nil, nil
    end
    local _, parameters = copyParameters(record.currentParameters)
    return record.currentRoute, parameters
end

function Service:getNavigationHistory(deviceId, appId)
    local record = getRecord(deviceId, appId)
    local history = {}
    if record == nil then
        return history
    end
    for _, entry in ipairs(record.history) do
        local _, parameters = copyParameters(entry.routeParameters)
        table.insert(history, {
            routeId = entry.routeId,
            routeParameters = parameters
        })
    end
    return history
end

--- Returns one detached, registry-validated persisted resume destination.
-- Invalid saved destinations are discarded through the existing namespace
-- replacement path and never exposed to a runtime Host.
-- @param deviceId any
-- @return string result
-- @return table|nil resume
function Service:getValidatedResumeDestination(deviceId)
    if not isIdentifier(deviceId) then
        return Result.INVALID_ARGUMENT, nil
    end

    if FORGE.ForgeOSCore:getPhase() ~= Phase.RUNTIME_ACTIVE then
        return Result.NOT_AVAILABLE, nil
    end

    if not FORGE.DeviceRegistry:isDeviceRegistered(deviceId) then
        return Result.NOT_REGISTERED, nil
    end

    local callSucceeded, operationResult, resume = pcall(function()
        local state, found = FORGE.StateStore:snapshot(Namespace)

        if not found or type(state.players) ~= "table" then
            return Result.STATE_ERROR, nil
        end

        local player = state.players[PlayerId]
        local device = type(player) == "table"
            and type(player.devices) == "table"
            and player.devices[deviceId]
            or nil
        local stored = type(device) == "table"
            and device.resume
            or nil

        if stored == nil then
            return Result.SUCCESS, nil
        end

        local validParameters, parameters =
            copyParameters(stored.routeParameters)
        local resolutionResult, resolution =
            FORGE.PresentationResolver:resolvePresentation(
                stored.appId,
                deviceId
            )
        local valid = isIdentifier(stored.appId)
            and isIdentifier(stored.presentationId)
            and isIdentifier(stored.routeId)
            and validParameters
            and resolutionResult == Result.SUCCESS
            and resolution.presentationId == stored.presentationId
            and resolution.presentation.routes[stored.routeId] ~= nil

        if valid then
            return Result.SUCCESS, {
                appId = stored.appId,
                presentationId = stored.presentationId,
                routeId = stored.routeId,
                routeParameters = parameters
            }
        end

        device.resume = nil

        if not FORGE.StateStore:replaceNamespace(Namespace, state) then
            return Result.STATE_ERROR, nil
        end

        FORGE.Logger:warning(
            FORGE.Definitions.LogSource.NAVIGATION,
            "Discarded invalid Phone navigation resume destination"
        )

        return Result.SUCCESS, nil
    end)

    if not callSucceeded then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.NAVIGATION,
            "Unexpected navigation resume validation failure: %s",
            FORGE.Logger:safeToString(
                operationResult,
                "<unprintable error>"
            )
        )

        return Result.INTERNAL_ERROR, nil
    end

    return operationResult, resume
end

function Service:clearRuntimeState()
    records = {}
    return Result.SUCCESS
end
