---=============================================================================
--- FORGE ForgeOS App Registry
---
--- Owns authoritative application definitions for one ForgeOS lifecycle.
---
--- Responsibilities:
---     • Validate and atomically register controlled app definitions.
---     • Retain runtime-owned executable assets privately.
---     • Provide detached declarative snapshots and deterministic lookup.
---     • Participate in registration validation, freeze, and cleanup.
---
--- This component must never resolve presentations or execute app behaviour.
---=============================================================================

FORGE.AppRegistry = {}

local Registry = FORGE.AppRegistry
local Result = FORGE.Definitions.ForgeOSResult
local Event = FORGE.Definitions.ForgeOSEvent
local Capability = FORGE.Definitions.DeviceCapability

local definitions = {}
local runtimeAssets = {}
local registrationFrozen = false

local recognisedCapabilities = {}
for _, value in pairs(Capability) do
    recognisedCapabilities[value] = true
end

local recognisedCallbacks = {
    onRegister = true,
    onOpen = true,
    onActivate = true,
    onBackground = true,
    onClose = true
}

local lifecycleCallbacks = {
    onOpen = true,
    onActivate = true,
    onBackground = true,
    onClose = true
}

local function isFiniteNumber(value)
    return value == value
        and value ~= math.huge
        and value ~= -math.huge
end

local function isIdentifier(value)
    return type(value) == "string"
        and value ~= ""
        and string.find(value, "%s") == nil
end

local function copyPlainValue(value, visited)
    local valueType = type(value)

    if valueType == "nil"
        or valueType == "boolean"
        or valueType == "string" then
        return true, value
    end

    if valueType == "number" then
        return isFiniteNumber(value), value
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

local function copyOptionalPlainTable(value)
    if value == nil then
        return true, nil
    end

    if type(value) ~= "table" then
        return false, nil
    end

    return copyPlainValue(value, {})
end

local function copyRequirements(value)
    if value == nil then
        return true, nil
    end

    if type(value) ~= "table" then
        return false, nil
    end

    local copy = {}
    for capabilityId, required in pairs(value) do
        if recognisedCapabilities[capabilityId] ~= true
            or required ~= true then
            return false, nil
        end
        copy[capabilityId] = true
    end

    return true, copy
end

local function copyProviders(value)
    if value == nil then
        return true, nil
    end

    if type(value) ~= "table" then
        return false, nil
    end

    local copy = {}
    for index, provider in ipairs(value) do
        if type(provider) ~= "table"
            or type(provider.isAvailable)
                ~= "function" then
            return false, nil
        end
        copy[index] = provider
    end

    for key in pairs(value) do
        if type(key) ~= "number"
            or key < 1
            or key > #copy
            or key ~= math.floor(key) then
            return false, nil
        end
    end

    return true, copy
end

local function copyCallbacks(value)
    if value == nil then
        return true, nil
    end

    if type(value) ~= "table" then
        return false, nil
    end

    local copy = {}
    for callbackName, callback in pairs(value) do
        if recognisedCallbacks[callbackName]
                ~= true
            or type(callback) ~= "function" then
            return false, nil
        end
        copy[callbackName] = callback
    end

    return true, copy
end

local function copyActions(actions)
    if actions == nil then
        return true, nil, nil
    end

    if type(actions) ~= "table" then
        return false, nil, nil
    end

    local declarations = {}
    local assets = {}

    for actionId, action in pairs(actions) do
        if not isIdentifier(actionId) then
            return false, nil, nil
        end

        if action == true then
            declarations[actionId] = true
        elseif type(action) == "table" then
            if action.handler ~= nil
                and not isIdentifier(
                    action.handler
                ) then
                return false, nil, nil
            end
            if action.enabled ~= nil
                and type(action.enabled)
                    ~= "boolean" then
                return false, nil, nil
            end

            local requirementsValid,
                requirementsCopy =
                    copyRequirements(
                        action.requiredCapabilities
                    )
            local metadataValid, metadataCopy =
                copyOptionalPlainTable(
                    action.metadata
                )
            if not requirementsValid
                or not metadataValid then
                return false, nil, nil
            end

            local declaration = {}
            if action.enabled ~= nil then
                declaration.enabled = action.enabled
            end
            if requirementsCopy ~= nil then
                declaration.requiredCapabilities =
                    requirementsCopy
            end
            if metadataCopy ~= nil then
                declaration.metadata = metadataCopy
            end
            declarations[actionId] = declaration
            assets[actionId] = {
                handler = action.handler
            }
        else
            return false, nil, nil
        end
    end

    return true, declarations, assets
end

local function copyRoutes(routes, defaultRoute)
    if type(routes) ~= "table"
        or not isIdentifier(defaultRoute) then
        return false, nil, nil
    end

    local declarations = {}
    local assets = {}
    local count = 0

    for routeId, route in pairs(routes) do
        if not isIdentifier(routeId)
            or type(route) ~= "table" then
            return false, nil, nil
        end
        count = count + 1

        if route.controller ~= nil
            and not isIdentifier(
                route.controller
            ) then
            return false, nil, nil
        end

        local requirementsValid,
            requirementsCopy =
                copyRequirements(
                    route.requiredCapabilities
                )
        local providersValid, providersCopy =
            copyProviders(
                route.availabilityProviders
            )
        local metadataValid, metadataCopy =
            copyOptionalPlainTable(
                route.metadata
            )

        if not requirementsValid
            or not providersValid
            or not metadataValid then
            return false, nil, nil
        end

        local declaration = {}
        if requirementsCopy ~= nil then
            declaration.requiredCapabilities =
                requirementsCopy
        end
        if metadataCopy ~= nil then
            declaration.metadata = metadataCopy
        end
        declarations[routeId] = declaration
        assets[routeId] = {
            controller = route.controller,
            availabilityProviders =
                providersCopy
        }
    end

    if count == 0
        or declarations[defaultRoute] == nil then
        return false, nil, nil
    end

    return true, declarations, assets
end

local function copyPresentations(presentations)
    if type(presentations) ~= "table" then
        return false, nil, nil
    end

    local declarations = {}
    local assets = {}
    local ids = {}
    local count = 0

    for presentationKey, presentation in pairs(
        presentations
    ) do
        if not isIdentifier(presentationKey)
            or type(presentation) ~= "table"
            or not isIdentifier(presentation.id)
            or ids[presentation.id] then
            return false, nil, nil
        end
        ids[presentation.id] = true
        count = count + 1

        if presentation.controller ~= nil
            and type(presentation.controller)
                ~= "table" then
            return false, nil, nil
        end
        if presentation.priority ~= nil
            and (
                type(presentation.priority)
                    ~= "number"
                or not isFiniteNumber(
                    presentation.priority
                )
            ) then
            return false, nil, nil
        end

        local requirementsValid,
            requirementsCopy =
                copyRequirements(
                    presentation
                        .requiredCapabilities
                )
        local routesValid, routesCopy,
            routeAssets =
                copyRoutes(
                    presentation.routes,
                    presentation.defaultRoute
                )
        local actionsValid, actionsCopy,
            actionAssets =
                copyActions(
                    presentation.actions
                )
        local metadataValid, metadataCopy =
            copyOptionalPlainTable(
                presentation.metadata
            )

        if not requirementsValid
            or not routesValid
            or not actionsValid
            or not metadataValid then
            return false, nil, nil
        end

        local declaration = {
            id = presentation.id,
            defaultRoute =
                presentation.defaultRoute,
            routes = routesCopy
        }
        if requirementsCopy ~= nil then
            declaration.requiredCapabilities =
                requirementsCopy
        end
        if actionsCopy ~= nil then
            declaration.actions = actionsCopy
        end
        if metadataCopy ~= nil then
            declaration.metadata = metadataCopy
        end
        if presentation.priority ~= nil then
            declaration.priority =
                presentation.priority
        end

        declarations[presentationKey] =
            declaration
        assets[presentationKey] = {
            controller = presentation.controller,
            routes = routeAssets,
            actions = actionAssets
        }
    end

    return count > 0, declarations, assets
end

local function copySupportedDevices(value)
    if type(value) ~= "table" then
        return false, nil, false
    end

    local copy = {}
    local supported = false
    for deviceId, declared in pairs(value) do
        if not isIdentifier(deviceId)
            or type(declared) ~= "boolean" then
            return false, nil, false
        end
        copy[deviceId] = declared
        supported = supported or declared
    end

    return true, copy, supported
end

local function createControlledDefinition(app)
    if not isIdentifier(app.id)
        or type(app.apiVersion) ~= "number"
        or app.apiVersion < 1
        or app.apiVersion
            ~= math.floor(app.apiVersion)
        or type(app.displayName) ~= "string"
        or app.displayName == ""
        or (
            app.ownerId ~= nil
            and not isIdentifier(app.ownerId)
        )
        or (
            app.iconId ~= nil
            and not isIdentifier(app.iconId)
        )
        or (
            app.controller ~= nil
            and type(app.controller) ~= "table"
        )
        or (
            app.allowCapabilityFallback
                ~= nil
            and type(
                app.allowCapabilityFallback
            ) ~= "boolean"
        ) then
        return nil, nil, Result.INVALID_DEFINITION
    end

    local devicesValid, devicesCopy,
        hasSupportedDevice =
            copySupportedDevices(
                app.supportedDevices
            )
    local requirementsValid, requirementsCopy =
        copyRequirements(
            app.requiredCapabilities
        )
    local presentationsValid,
        presentationsCopy,
        presentationAssets =
            copyPresentations(
                app.presentations
            )
    local providersValid, providersCopy =
        copyProviders(
            app.availabilityProviders
        )
    local callbacksValid, callbacksCopy =
        copyCallbacks(app.callbacks)
    local metadataValid, metadataCopy =
        copyOptionalPlainTable(app.metadata)

    if not devicesValid
        or not requirementsValid
        or not presentationsValid
        or not providersValid
        or not callbacksValid
        or not metadataValid then
        return nil, nil, Result.INVALID_DEFINITION
    end

    local allowFallback =
        app.allowCapabilityFallback == true

    if not hasSupportedDevice
        and not allowFallback then
        return nil, nil, Result.INVALID_DEFINITION
    end

    if app.defaultPresentation ~= nil
        and (
            not isIdentifier(
                app.defaultPresentation
            )
            or presentationsCopy[
                app.defaultPresentation
            ] == nil
        ) then
        return nil, nil, Result.INVALID_DEFINITION
    end

    for deviceId, supported in pairs(
        devicesCopy
    ) do
        if supported
            and presentationsCopy[deviceId]
                == nil
            and not allowFallback then
            return nil, nil,
                Result.INVALID_DEFINITION
        end
    end

    if app.apiVersion
        ~= FORGE.Definitions
            .ForgeOSVersion.APP_API then
        return nil, nil,
            Result.API_VERSION_UNSUPPORTED
    end

    local controlled = {
        id = app.id,
        apiVersion = app.apiVersion,
        displayName = app.displayName,
        supportedDevices = devicesCopy,
        presentations = presentationsCopy,
        allowCapabilityFallback = allowFallback
    }
    if app.ownerId ~= nil then
        controlled.ownerId = app.ownerId
    end
    if app.iconId ~= nil then
        controlled.iconId = app.iconId
    end
    if requirementsCopy ~= nil then
        controlled.requiredCapabilities =
            requirementsCopy
    end
    if app.defaultPresentation ~= nil then
        controlled.defaultPresentation =
            app.defaultPresentation
    end
    if metadataCopy ~= nil then
        controlled.metadata = metadataCopy
    end

    local assets = {
        controller = app.controller,
        availabilityProviders = providersCopy,
        callbacks = callbacksCopy,
        presentations = presentationAssets
    }

    return controlled, assets, Result.SUCCESS
end

function Registry:getRegistrationRole()
    return FORGE.ForgeOSRegistrationCoordinator
        .Role.APP_REGISTRY
end

function Registry:registerApp(appDefinition)
    if FORGE.ForgeOSRegistrationCoordinator
        :getRegistrationGateResult()
        ~= Result.SUCCESS
        or registrationFrozen then
        return Result.REGISTRATION_CLOSED
    end

    if type(appDefinition) ~= "table" then
        return Result.INVALID_ARGUMENT
    end

    local succeeded, operationResult =
        pcall(function()
            local controlled, assets, result =
                createControlledDefinition(
                    appDefinition
                )
            if result ~= Result.SUCCESS then
                return result
            end
            if definitions[controlled.id] ~= nil then
                return Result.ALREADY_REGISTERED
            end

            definitions[controlled.id] = controlled
            runtimeAssets[controlled.id] = assets

            FORGE.EventBus:publish(
                Event.APP_REGISTERED,
                { appId = controlled.id }
            )
            return Result.SUCCESS
        end)

    if not succeeded then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.APP_REGISTRY,
            "Unexpected app registration failure: %s",
            FORGE.Logger:safeToString(
                operationResult,
                "<unprintable error>"
            )
        )
        return Result.INTERNAL_ERROR
    end

    return operationResult
end

function Registry:isAppRegistered(appId)
    return type(appId) == "string"
        and definitions[appId] ~= nil
end

function Registry:getAppDefinition(appId)
    local definition = definitions[appId]
    if type(appId) ~= "string"
        or definition == nil then
        return nil
    end
    local valid, copy =
        copyPlainValue(definition, {})
    return valid and copy or nil
end

--- Returns one private lifecycle callback for internal ForgeOS use.
-- @param appId any
-- @param callbackName any
-- @return function|nil callback
function Registry:getLifecycleCallback(
    appId,
    callbackName
)
    if type(appId) ~= "string"
        or lifecycleCallbacks[callbackName]
            ~= true then
        return nil
    end

    local assets = runtimeAssets[appId]
    if assets == nil
        or assets.callbacks == nil then
        return nil
    end

    return assets.callbacks[callbackName]
end

--- Returns one private presentation provider for internal ForgeOS use.
-- The executable reference is never included in detached app snapshots.
-- @param appId any
-- @param presentationKey any
-- @return table|nil provider
function Registry:getPresentationProvider(
    appId,
    presentationKey
)
    if type(appId) ~= "string"
        or type(presentationKey) ~= "string" then
        return nil
    end

    local assets = runtimeAssets[appId]
    local presentation = assets ~= nil
        and assets.presentations[presentationKey]
        or nil

    return presentation ~= nil
        and presentation.controller
        or nil
end

function Registry:getRegisteredAppIds()
    local ids = {}
    for appId in pairs(definitions) do
        table.insert(ids, appId)
    end
    table.sort(ids)
    return ids
end

function Registry:validateRegistrationSet()
    for appId, definition in pairs(
        definitions
    ) do
        if definition.id ~= appId
            or runtimeAssets[appId] == nil then
            return Result.INVALID_DEFINITION
        end
    end
    return Result.SUCCESS
end

function Registry:freezeRegistrationSet()
    if registrationFrozen then
        return Result.SUCCESS
    end
    local result =
        self:validateRegistrationSet()
    if result == Result.SUCCESS then
        registrationFrozen = true
    end
    return result
end

function Registry:clearRegistrationSet()
    definitions = {}
    runtimeAssets = {}
    registrationFrozen = false
    return Result.SUCCESS
end

function Registry:isRegistrationSetFrozen()
    return registrationFrozen
end
