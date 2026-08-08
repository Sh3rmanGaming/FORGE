---=============================================================================
--- FORGE ForgeOS Application Lifecycle Service
---
--- Owns local-player application lifecycle state for registered devices.
---
--- Responsibilities:
---     • Validate and atomically commit application lifecycle transitions.
---     • Coordinate lifecycle callbacks and completed lifecycle events.
---     • Enforce one active application per device and enabled policy.
---     • Clear all runtime-only lifecycle state during shutdown.
---
--- This service must never persist runtime state or own app availability.
---=============================================================================

FORGE.AppLifecycleService = {}

local Service = FORGE.AppLifecycleService
local Result = FORGE.Definitions.ForgeOSResult
local State = FORGE.Definitions.AppLifecycleState
local Event = FORGE.Definitions.ForgeOSEvent
local Phase = FORGE.Definitions.ForgeOSPhase
local PlayerId = FORGE.Definitions.ForgeOSPlayerId.LOCAL
local Capability = FORGE.Definitions.DeviceCapability

local appStates = {}
local activeApps = {}
local enabledOverrides = {}
local operationActive = false

local callbackForState = {
    [State.OPEN] = "onOpen",
    [State.ACTIVE] = "onActivate",
    [State.BACKGROUND] = "onBackground",
    [State.CLOSED] = "onClose"
}

local eventForState = {
    [State.OPEN] = Event.APP_OPENED,
    [State.ACTIVE] = Event.APP_ACTIVATED,
    [State.BACKGROUND] = Event.APP_BACKGROUNDED,
    [State.CLOSED] = Event.APP_CLOSED
}

local function isIdentifier(value)
    return type(value) == "string"
        and value ~= ""
        and string.find(value, "%s") == nil
end

local function getState(deviceId, appId)
    local deviceStates = appStates[deviceId]
    return deviceStates ~= nil
        and deviceStates[appId]
        or State.CLOSED
end

local function setState(deviceId, appId, state)
    if state == State.CLOSED then
        if appStates[deviceId] ~= nil then
            appStates[deviceId][appId] = nil
            if next(appStates[deviceId]) == nil then
                appStates[deviceId] = nil
            end
        end
        return
    end

    appStates[deviceId] = appStates[deviceId] or {}
    appStates[deviceId][appId] = state
end

local function invokeCallback(change)
    local callback = FORGE.AppRegistry:getLifecycleCallback(
        change.appId,
        callbackForState[change.currentState]
    )
    if callback == nil then
        return true
    end

    local succeeded = pcall(callback, {
        playerId = PlayerId,
        deviceId = change.deviceId,
        appId = change.appId,
        previousState = change.previousState,
        requestedState = change.currentState
    })
    return succeeded
end

local function publishChange(change)
    FORGE.EventBus:publish(
        eventForState[change.currentState],
        {
            playerId = PlayerId,
            deviceId = change.deviceId,
            appId = change.appId,
            previousState = change.previousState,
            currentState = change.currentState
        }
    )
end

local function commitChanges(changes)
    for _, change in ipairs(changes) do
        setState(
            change.deviceId,
            change.appId,
            change.currentState
        )
        if change.currentState == State.ACTIVE then
            activeApps[change.deviceId] = change.appId
        elseif activeApps[change.deviceId]
            == change.appId then
            activeApps[change.deviceId] = nil
        end
    end
end

local function runChanges(changes)
    operationActive = true

    for _, change in ipairs(changes) do
        if not invokeCallback(change) then
            operationActive = false
            FORGE.Logger:error(
                FORGE.Definitions.LogSource.APP_LIFECYCLE,
                "Application lifecycle callback failed for '%s'",
                change.appId
            )
            return Result.CALLBACK_FAILED
        end
    end

    local committed = pcall(commitChanges, changes)
    if not committed then
        operationActive = false
        return Result.STATE_ERROR
    end

    operationActive = false
    for _, change in ipairs(changes) do
        publishChange(change)
    end
    return Result.SUCCESS
end

local function validateRequest(deviceId, appId)
    if not isIdentifier(deviceId)
        or not isIdentifier(appId) then
        return Result.INVALID_ARGUMENT
    end
    if FORGE.ForgeOSCore:getPhase()
        ~= Phase.RUNTIME_ACTIVE then
        return Result.NOT_AVAILABLE
    end
    if not FORGE.DeviceRegistry:isDeviceRegistered(deviceId)
        or not FORGE.AppRegistry:isAppRegistered(appId) then
        return Result.NOT_REGISTERED
    end
    if operationActive then
        return Result.NOT_AVAILABLE
    end
    return Result.SUCCESS
end

local function change(deviceId, appId, targetState)
    local validation = validateRequest(deviceId, appId)
    if validation ~= Result.SUCCESS then
        return validation
    end

    local previousState = getState(deviceId, appId)
    if targetState == State.OPEN then
        if previousState ~= State.CLOSED then
            return Result.SUCCESS
        end
        local resolutionResult = FORGE.PresentationResolver
            :resolvePresentation(appId, deviceId)
        if resolutionResult ~= Result.SUCCESS then
            return resolutionResult
        end
        if enabledOverrides[appId] == false then
            return Result.POLICY_REJECTED
        end
    elseif targetState == State.ACTIVE then
        if activeApps[deviceId] == appId then
            return Result.SUCCESS
        end
        if previousState ~= State.OPEN
            and previousState ~= State.BACKGROUND then
            return Result.INVALID_TRANSITION
        end
        if enabledOverrides[appId] == false then
            return Result.POLICY_REJECTED
        end
    elseif targetState == State.BACKGROUND then
        if previousState == State.BACKGROUND then
            return Result.SUCCESS
        end
        if previousState ~= State.OPEN
            and previousState ~= State.ACTIVE then
            return Result.INVALID_TRANSITION
        end
    elseif targetState == State.CLOSED then
        if previousState == State.CLOSED then
            return Result.SUCCESS
        end
    end

    local changes = {}
    if targetState == State.ACTIVE then
        local activeAppId = activeApps[deviceId]
        if activeAppId ~= nil and activeAppId ~= appId then
            local device = FORGE.DeviceRegistry
                :getDeviceDefinition(deviceId)
            local displacedState = State.CLOSED
            if device.capabilities[Capability.BACKGROUND_APPS]
                == true then
                displacedState = State.BACKGROUND
            end
            table.insert(changes, {
                deviceId = deviceId,
                appId = activeAppId,
                previousState = State.ACTIVE,
                currentState = displacedState
            })
        end
    end

    table.insert(changes, {
        deviceId = deviceId,
        appId = appId,
        previousState = previousState,
        currentState = targetState
    })
    return runChanges(changes)
end

function Service:openApp(deviceId, appId)
    return change(deviceId, appId, State.OPEN)
end

function Service:activateApp(deviceId, appId)
    return change(deviceId, appId, State.ACTIVE)
end

function Service:backgroundApp(deviceId, appId)
    return change(deviceId, appId, State.BACKGROUND)
end

function Service:closeApp(deviceId, appId)
    return change(deviceId, appId, State.CLOSED)
end

function Service:getAppLifecycleState(deviceId, appId)
    return getState(deviceId, appId)
end

function Service:getActiveAppId(deviceId)
    return activeApps[deviceId]
end

function Service:setAppEnabled(appId, enabled)
    if not isIdentifier(appId)
        or type(enabled) ~= "boolean" then
        return Result.INVALID_ARGUMENT
    end
    if not FORGE.AppRegistry:isAppRegistered(appId) then
        return Result.NOT_REGISTERED
    end
    enabledOverrides[appId] = enabled
    return Result.SUCCESS
end

function Service:clearRuntimeState()
    appStates = {}
    activeApps = {}
    enabledOverrides = {}
    operationActive = false
    return Result.SUCCESS
end
