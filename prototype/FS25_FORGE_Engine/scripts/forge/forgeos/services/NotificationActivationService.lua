---=============================================================================
--- FORGE ForgeOS Notification Activation Service
---
--- Opens a notification's logical destination through the existing Lifecycle
--- and Navigation services (ADR-008).
---
--- Responsibilities:
---     • Preflight the notification, device, app, presentation, route and
---       route parameters without side effects.
---     • Open, activate and navigate in that order, stopping at the first
---       failure and reporting the last completed stage.
---     • Mark the notification read only after navigation succeeds.
---
--- No rollback is promised or attempted. This service never mutates linked
--- domain state, owns no notification data, and exposes no public ForgeOS API;
--- Hosts reach it through their private Host context.
---=============================================================================

FORGE.NotificationActivationService = {}

local Service = FORGE.NotificationActivationService
local Result = FORGE.Definitions.ForgeOSResult
local Phase = FORGE.Definitions.ForgeOSPhase
local Stage = FORGE.Definitions.NotificationActivationStage
local Outcome = FORGE.Definitions.NotificationActivationResult

local function isIdentifier(value)
    return type(value) == "string"
        and value ~= ""
        and string.find(value, "%s") == nil
end

local function report(result, stage, detail, appId, routeId)
    return {
        result = result,
        stage = stage,
        detail = detail,
        appId = appId,
        routeId = routeId
    }
end

--- Validates everything that can be checked without changing state.
-- @return table|nil failure
-- @return table|nil record
local function preflight(deviceId, notificationId)
    if FORGE.ForgeOSCore:getPhase() ~= Phase.RUNTIME_ACTIVE then
        return report(Outcome.VALIDATION_FAILED, Stage.NONE,
            Result.NOT_AVAILABLE), nil
    end
    if not isIdentifier(deviceId) or not isIdentifier(notificationId) then
        return report(Outcome.VALIDATION_FAILED, Stage.NONE,
            Result.INVALID_ARGUMENT), nil
    end
    if not FORGE.DeviceRegistry:isDeviceRegistered(deviceId) then
        return report(Outcome.VALIDATION_FAILED, Stage.NONE,
            Result.NOT_REGISTERED), nil
    end
    local record = FORGE.NotificationService:getNotification(notificationId)
    if record == nil then
        return report(Outcome.VALIDATION_FAILED, Stage.NONE,
            Result.NOT_REGISTERED), nil
    end
    if record.targetDevices[deviceId] ~= true then
        return report(Outcome.VALIDATION_FAILED, Stage.NONE,
            Result.INVALID_ARGUMENT), nil
    end
    local route = record.route
    if route == nil then
        return report(Outcome.VALIDATION_FAILED, Stage.NONE,
            Result.ROUTE_NOT_FOUND), nil
    end
    if not FORGE.AppRegistry:isAppRegistered(route.appId) then
        return report(Outcome.VALIDATION_FAILED, Stage.NONE,
            Result.NOT_REGISTERED, route.appId, route.routeId), nil
    end
    local resolution, presentation = FORGE.PresentationResolver
        :resolvePresentation(route.appId, deviceId)
    if resolution ~= Result.SUCCESS then
        return report(Outcome.VALIDATION_FAILED, Stage.NONE, resolution,
            route.appId, route.routeId), nil
    end
    local declaration = presentation.presentation.routes[route.routeId]
    if declaration == nil then
        return report(Outcome.VALIDATION_FAILED, Stage.NONE,
            Result.ROUTE_NOT_FOUND, route.appId, route.routeId), nil
    end
    if not FORGE.RouteParameterSchema:validate(
        declaration.parameters, route.parameters) then
        return report(Outcome.VALIDATION_FAILED, Stage.NONE,
            Result.INVALID_ARGUMENT, route.appId, route.routeId), nil
    end
    return nil, record, presentation.presentation.defaultRoute
end

local function activate(deviceId, notificationId)
    local failure, record, defaultRoute = preflight(deviceId, notificationId)
    if failure ~= nil then
        return failure
    end
    local appId = record.route.appId
    local routeId = record.route.routeId

    local result = FORGE.AppLifecycleService:openApp(deviceId, appId)
    if result ~= Result.SUCCESS then
        return report(Outcome.OPEN_FAILED, Stage.PREFLIGHT, result,
            appId, routeId)
    end
    result = FORGE.AppLifecycleService:activateApp(deviceId, appId)
    if result ~= Result.SUCCESS then
        return report(Outcome.ACTIVATION_FAILED, Stage.OPEN, result,
            appId, routeId)
    end
    -- A first-time open seeds the app's default route, so Back from the
    -- destination has somewhere to return to.
    if routeId ~= defaultRoute
        and FORGE.NavigationService:getCurrentRoute(deviceId, appId) == nil then
        result = FORGE.NavigationService:navigate(
            deviceId, appId, defaultRoute, {})
        if result ~= Result.SUCCESS then
            return report(Outcome.NAVIGATION_FAILED, Stage.ACTIVATE, result,
                appId, routeId)
        end
    end
    result = FORGE.NavigationService:navigate(
        deviceId, appId, routeId, record.route.parameters)
    if result ~= Result.SUCCESS then
        return report(Outcome.NAVIGATION_FAILED, Stage.ACTIVATE, result,
            appId, routeId)
    end
    result = FORGE.NotificationService:markNotificationRead(notificationId)
    if result ~= Result.SUCCESS then
        return report(Outcome.READ_UPDATE_FAILED, Stage.NAVIGATE, result,
            appId, routeId)
    end
    return report(Outcome.SUCCESS, Stage.COMPLETE, Result.SUCCESS,
        appId, routeId)
end

--- Activates a notification's destination on one device.
-- @param deviceId any
-- @param notificationId any
-- @return table outcome { result, stage, detail, appId, routeId }
function Service:activate(deviceId, notificationId)
    local call = { pcall(activate, deviceId, notificationId) }
    if not call[1] then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.NOTIFICATION,
            "Unexpected notification activation failure: %s",
            FORGE.Logger:safeToString(call[2], "<unprintable error>")
        )
        return report(Outcome.VALIDATION_FAILED, Stage.NONE,
            Result.INTERNAL_ERROR)
    end
    return call[2]
end
