---=============================================================================
--- FORGE Application Presentation Service
---
--- Delivers bounded, detached application models and actions to runtime Hosts.
---
--- Responsibilities:
---     • Gate presentation access through ForgeOS runtime ownership.
---     • Invoke private approved providers under containment and re-entrancy.
---     • Validate the closed M3 Communications model and action protocols.
---     • Mediate declarative navigation through the ForgeOS facade.
---
--- This service must never render UI, own domain state, or expose providers.
---=============================================================================

FORGE.ApplicationPresentationService = {}

local Service = FORGE.ApplicationPresentationService
local Result = FORGE.Definitions.ForgeOSResult
local Phase = FORGE.Definitions.ForgeOSPhase
local Lifecycle = FORGE.Definitions.AppLifecycleState
local Visibility = FORGE.Definitions.DeviceVisibility
local PlayerId = FORGE.Definitions.ForgeOSPlayerId.LOCAL

local operationActive = {}

local function isIdentifier(value)
    return type(value) == "string"
        and value ~= ""
        and string.find(value, "%s") == nil
end

local function isNonNegativeInteger(value)
    return type(value) == "number"
        and value >= 0
        and value == math.floor(value)
end

local function hasOnly(value, allowed)
    if type(value) ~= "table"
        or getmetatable(value) ~= nil then
        return false
    end
    for key in pairs(value) do
        if type(key) ~= "string" or not allowed[key] then
            return false
        end
    end
    return true
end

local function copyPlain(value, visited, allowNumericKeys)
    local valueType = type(value)
    if valueType == "nil"
        or valueType == "boolean"
        or valueType == "string" then
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
        if type(key) ~= "string"
            and not (allowNumericKeys
                and type(key) == "number"
                and key >= 1
                and key == math.floor(key)) then
            return false, nil
        end
        local valid, nestedCopy = copyPlain(
            nested,
            visited,
            allowNumericKeys
        )
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
    return copyPlain(value, {}, false)
end

local function validateRecord(record, detail)
    local allowed = {
        messageId = true,
        subject = true,
        sender = true,
        channel = true,
        priority = true,
        unread = true,
        archived = true
    }
    if detail then
        allowed.body = true
    else
        allowed.preview = true
    end
    if not hasOnly(record, allowed)
        or not isIdentifier(record.messageId)
        or type(record.subject) ~= "string"
        or type(record.sender) ~= "string"
        or not isIdentifier(record.channel)
        or not isIdentifier(record.priority)
        or type(record.unread) ~= "boolean"
        or type(record.archived) ~= "boolean" then
        return false
    end
    if detail then
        return type(record.body) == "string"
    end
    return type(record.preview) == "string"
end

local function validateContent(content, routeId)
    if routeId == "inbox" then
        if not hasOnly(content, {
            kind = true,
            emptyText = true,
            rows = true
        })
            or content.kind ~= "communications.inbox"
            or type(content.emptyText) ~= "string"
            or type(content.rows) ~= "table"
            or getmetatable(content.rows) ~= nil then
            return false
        end
        local count = 0
        for index, row in ipairs(content.rows) do
            count = count + 1
            if index ~= count or not validateRecord(row, false) then
                return false
            end
        end
        for key in pairs(content.rows) do
            if type(key) ~= "number"
                or key < 1
                or key > count
                or key ~= math.floor(key) then
                return false
            end
        end
        return true
    end

    if routeId == "messageDetail" then
        if not hasOnly(content, { kind = true, message = true })
            or content.kind ~= "communications.messageDetail" then
            return false
        end
        return content.message == nil
            or validateRecord(content.message, true)
    end

    return false
end

local function validateActions(actions, presentation)
    if type(actions) ~= "table"
        or getmetatable(actions) ~= nil then
        return false
    end
    local count = 0
    for index, action in ipairs(actions) do
        count = count + 1
        if index ~= count
            or not hasOnly(action, {
                id = true,
                label = true,
                parameters = true
            })
            or not isIdentifier(action.id)
            or type(action.label) ~= "string"
            or presentation.actions == nil
            or presentation.actions[action.id] == nil then
            return false
        end
        local valid = copyParameters(action.parameters)
        if not valid then
            return false
        end
    end
    for key in pairs(actions) do
        if type(key) ~= "number"
            or key < 1
            or key > count
            or key ~= math.floor(key) then
            return false
        end
    end
    return true
end

local function validateModel(model, context, presentation)
    if not hasOnly(model, {
        modelVersion = true,
        appId = true,
        presentationId = true,
        routeId = true,
        title = true,
        badgeCount = true,
        content = true,
        actions = true
    })
        or model.modelVersion ~= 1
        or model.appId ~= context.appId
        or model.presentationId ~= context.presentationId
        or model.routeId ~= context.routeId
        or type(model.title) ~= "string"
        or not isNonNegativeInteger(model.badgeCount)
        or not validateContent(model.content, context.routeId)
        or not validateActions(model.actions, presentation) then
        return nil
    end
    local valid, copy = copyPlain(model, {}, true)
    return valid and copy or nil
end

local function validateNavigation(navigation, resolution)
    if navigation == nil then
        return true, nil
    end
    if not hasOnly(navigation, {
        operation = true,
        routeId = true,
        parameters = true
    }) then
        return false, nil
    end
    if navigation.operation == "navigate" then
        if not isIdentifier(navigation.routeId)
            or resolution.presentation.routes[navigation.routeId] == nil then
            return false, nil
        end
    elseif navigation.operation == "back"
        or navigation.operation == "home" then
        if navigation.routeId ~= nil then
            return false, nil
        end
    else
        return false, nil
    end
    local valid, parameters = copyParameters(navigation.parameters)
    if not valid then
        return false, nil
    end
    local copy = { operation = navigation.operation }
    if navigation.routeId ~= nil then
        copy.routeId = navigation.routeId
    end
    if navigation.parameters ~= nil then
        copy.parameters = parameters
    end
    return true, copy
end

local function validateOutcome(outcome, resolution)
    if not hasOnly(outcome, {
        completed = true,
        domainResult = true,
        navigation = true
    })
        or type(outcome.completed) ~= "boolean"
        or not isIdentifier(outcome.domainResult) then
        return nil
    end
    local valid, navigation = validateNavigation(
        outcome.navigation,
        resolution
    )
    if not valid then
        return nil
    end
    local copy = {
        completed = outcome.completed,
        domainResult = outcome.domainResult
    }
    if navigation ~= nil then
        copy.navigation = navigation
    end
    return copy
end

local function gate(deviceId, appId, requireActive)
    if not isIdentifier(deviceId)
        or not isIdentifier(appId) then
        return Result.INVALID_ARGUMENT, nil, nil
    end
    if appId ~= FORGE.Definitions.CommunicationsAppId.COMMUNICATIONS then
        return Result.NOT_AVAILABLE, nil, nil
    end
    if FORGE.ForgeOSCore:getPhase() ~= Phase.RUNTIME_ACTIVE then
        return Result.NOT_AVAILABLE, nil, nil
    end
    if not FORGE.DeviceRegistry:isDeviceRegistered(deviceId)
        or not FORGE.AppRegistry:isAppRegistered(appId) then
        return Result.NOT_REGISTERED, nil, nil
    end
    if (requireActive
            and FORGE.AppLifecycleService:getAppLifecycleState(deviceId, appId)
                ~= Lifecycle.ACTIVE)
        or FORGE.DeviceStateService:getDeviceVisibility(deviceId)
            ~= Visibility.VISIBLE
        or not FORGE.ForgeOS:isRuntimeHostOperational(deviceId) then
        return Result.NOT_AVAILABLE, nil, nil
    end
    local resolutionResult, resolution = FORGE.PresentationResolver
        :resolvePresentation(appId, deviceId)
    if resolutionResult ~= Result.SUCCESS then
        return resolutionResult, nil, nil
    end
    local provider = FORGE.AppRegistry:getPresentationProvider(
        appId,
        resolution.presentationKey
    )
    if type(provider) ~= "table"
        or provider.protocolVersion ~= 1
        or type(provider.getModel) ~= "function"
        or type(provider.performAction) ~= "function"
        or type(provider.getBadge) ~= "function" then
        return Result.NOT_AVAILABLE, nil, nil
    end
    return Result.SUCCESS, resolution, provider
end

local function buildContext(deviceId, appId, resolution)
    local routeId, routeParameters = FORGE.NavigationService
        :getCurrentRoute(deviceId, appId)
    if routeId == nil then
        routeId = resolution.presentation.defaultRoute
        routeParameters = {}
    end
    if resolution.presentation.routes[routeId] == nil then
        return nil
    end
    local valid, parameters = copyParameters(routeParameters)
    if not valid then
        return nil
    end
    if appId == FORGE.Definitions.CommunicationsAppId.COMMUNICATIONS then
        if routeId == "inbox" and next(parameters) ~= nil then
            return nil
        end
        if routeId == "messageDetail"
            and (not hasOnly(parameters, { messageId = true })
                or not isIdentifier(parameters.messageId)) then
            return nil
        end
    end
    return {
        playerId = PlayerId,
        deviceId = deviceId,
        appId = appId,
        presentationId = resolution.presentationId,
        routeId = routeId,
        routeParameters = parameters
    }
end

local function operationKey(deviceId, appId)
    return deviceId .. "\0" .. appId
end

local function beginOperation(deviceId, appId)
    local key = operationKey(deviceId, appId)
    if operationActive[key] then
        return nil
    end
    operationActive[key] = true
    return key
end

local function finishOperation(key)
    operationActive[key] = nil
end

local function reportFailure(kind, failure)
    FORGE.Logger:error(
        FORGE.Definitions.LogSource.FORGE_OS,
        "Application presentation %s failed: %s",
        kind,
        FORGE.Logger:safeToString(failure, "<unprintable error>")
    )
end

local function applyNavigation(deviceId, appId, navigation, resolution)
    if navigation == nil then
        return Result.SUCCESS
    end
    if navigation.operation == "navigate" then
        return FORGE.ForgeOS:navigate(
            deviceId,
            appId,
            navigation.routeId,
            navigation.parameters
        )
    end
    if navigation.operation == "back" then
        return FORGE.ForgeOS:goBack(deviceId, appId)
    end
    return FORGE.ForgeOS:navigate(
        deviceId,
        appId,
        resolution.presentation.defaultRoute,
        navigation.parameters
    )
end

function Service:getModel(deviceId, appId)
    local gateResult, resolution, provider = gate(deviceId, appId, true)
    if gateResult ~= Result.SUCCESS then
        return nil
    end
    local context = buildContext(deviceId, appId, resolution)
    local key = context ~= nil and beginOperation(deviceId, appId) or nil
    if key == nil then
        return nil
    end
    local call = { pcall(provider.getModel, provider, context) }
    finishOperation(key)
    if not call[1] then
        reportFailure("model query", call[2])
        return nil
    end
    local model = validateModel(
        call[2],
        context,
        resolution.presentation
    )
    if model == nil then
        reportFailure("model validation", "invalid provider model")
    end
    return model
end

function Service:getBadge(deviceId, appId)
    local gateResult, resolution, provider = gate(deviceId, appId, false)
    if gateResult ~= Result.SUCCESS then
        return 0
    end
    local context = buildContext(deviceId, appId, resolution)
    local key = context ~= nil and beginOperation(deviceId, appId) or nil
    if key == nil then
        return 0
    end
    local call = { pcall(provider.getBadge, provider, context) }
    finishOperation(key)
    if not call[1] then
        reportFailure("badge query", call[2])
        return 0
    end
    if not isNonNegativeInteger(call[2]) then
        reportFailure("badge validation", "invalid provider badge")
        return 0
    end
    return call[2]
end

function Service:performAction(deviceId, appId, actionId, parameters)
    if not isIdentifier(actionId) then
        return Result.INVALID_ARGUMENT, nil
    end
    local parametersValid, detachedParameters = copyParameters(parameters)
    if not parametersValid then
        return Result.INVALID_ARGUMENT, nil
    end
    local gateResult, resolution, provider = gate(deviceId, appId, true)
    if gateResult ~= Result.SUCCESS then
        return gateResult, nil
    end
    if resolution.presentation.actions == nil
        or resolution.presentation.actions[actionId] == nil then
        return Result.INVALID_ARGUMENT, nil
    end
    local context = buildContext(deviceId, appId, resolution)
    local key = context ~= nil and beginOperation(deviceId, appId) or nil
    if key == nil then
        return Result.NOT_AVAILABLE, nil
    end
    local call = {
        pcall(
            provider.performAction,
            provider,
            context,
            actionId,
            detachedParameters
        )
    }
    finishOperation(key)
    if not call[1] then
        reportFailure("action", call[2])
        return Result.CALLBACK_FAILED, nil
    end
    local outcome = validateOutcome(call[2], resolution)
    if outcome == nil then
        reportFailure("action outcome validation", "invalid provider outcome")
        return Result.CALLBACK_FAILED, nil
    end
    local navigationResult = applyNavigation(
        deviceId,
        appId,
        outcome.navigation,
        resolution
    )
    if navigationResult ~= Result.SUCCESS then
        return navigationResult, outcome
    end
    return Result.SUCCESS, outcome
end

function Service:clearRuntimeState()
    operationActive = {}
    return Result.SUCCESS
end
