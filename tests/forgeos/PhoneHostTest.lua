---=============================================================================
--- FORGE PF.004 Phone Host Tests
---=============================================================================

FORGE.Tests = FORGE.Tests or {}

function FORGE.Tests.runPhoneHostTests()
    local Result = FORGE.Definitions.ForgeOSResult
    local Visibility = FORGE.Definitions.DeviceVisibility
    local visibility = Visibility.VISIBLE
    local activeAppId, routeId = nil, nil
    local apps, unavailable = {}, {}
    local calls, notificationMutations = {}, 0
    local metrics = { width = 1920, height = 1080, uiScale = 1 }
    local rectangles, labels, overlayDeletes = 0, {}, 0
    local badgeRenders, attentionQueries, attentionFails = 0, 0, false
    local attentionByApp = {}

    local function definition(appId)
        return { id = appId, displayName = "App " .. appId,
            iconId = appId == "app.missingIcon" and "missing.icon" or nil,
            supportedDevices = { phone = true } }
    end

    local context = {
        getVisibility = function() return visibility end,
        show = function() visibility = Visibility.VISIBLE; return Result.SUCCESS end,
        hide = function() visibility = Visibility.HIDDEN; return Result.SUCCESS end,
        getActiveAppId = function() return activeAppId end,
        getRegisteredAppIds = function() return apps end,
        getAppDefinition = function(appId) return definition(appId) end,
        resolvePresentation = function(appId)
            if unavailable[appId] then return Result.NOT_AVAILABLE, nil end
            return Result.SUCCESS, { presentationId = appId .. ".phone",
                presentation = { modelVersion = 2, defaultRoute = "home" } }
        end,
        getCurrentRoute = function() return routeId end,
        getValidatedResumeDestination = function()
            return Result.NOT_AVAILABLE, nil
        end,
        openApp = function(appId)
            calls[#calls + 1] = "open:" .. appId
            return Result.SUCCESS
        end,
        activateApp = function(appId)
            calls[#calls + 1] = "activate:" .. appId
            activeAppId = appId
            return Result.SUCCESS
        end,
        navigate = function(appId, nextRoute)
            calls[#calls + 1] = "navigate:" .. appId .. ":" .. nextRoute
            routeId = nextRoute
            return Result.SUCCESS
        end,
        closeApp = function(appId)
            calls[#calls + 1] = "close:" .. appId
            activeAppId, routeId = nil, nil
            return Result.SUCCESS
        end,
        getApplicationPresentationModel = function() return nil end,
        performApplicationAction = function() return Result.NOT_AVAILABLE end,
        getApplicationBadge = function() return 0 end,
        getApplicationAttention = function(appId)
            attentionQueries = attentionQueries + 1
            if attentionFails then error("attention provider failure") end
            return attentionByApp[appId] or { state = "none", count = 0 }
        end,
        getViewportMetrics = function() return metrics end,
        getNotifications = function() error("PF.004 queried notifications") end,
        markNotificationRead = function()
            notificationMutations = notificationMutations + 1
        end,
        dismissNotification = function()
            notificationMutations = notificationMutations + 1
        end,
        performPresentationAction = function() return Result.NOT_AVAILABLE end,
        performHostAction = function() return Result.NOT_AVAILABLE end,
        isUiBlocked = function() return false end
    }

    local originals = { drawFilledRect, renderText, setTextColor,
        createImageOverlay, renderOverlay, setOverlayColor, delete }
    drawFilledRect = function() rectangles = rectangles + 1 end
    renderText = function(_, _, _, value) labels[#labels + 1] = tostring(value) end
    setTextColor = function() end
    createImageOverlay = function(path)
        return string.find(path, "badge_", 1, true) and 300 or 100
    end
    renderOverlay = function(overlay)
        if overlay == 300 then badgeRenders = badgeRenders + 1 end
    end
    setOverlayColor = function() end
    delete = function() overlayDeletes = overlayDeletes + 1 end

    local success, errorMessage = pcall(function()
        local host = FORGE.PhoneHost.create(context)
        if host == nil or host:initialize() ~= Result.SUCCESS
            or host.geometryProfile ~= "standard"
            or host.shortcutPageSize ~= 6
            or host.applicationViewport == nil
            or host.bannerSafeRegion == nil then
            error("Phone trusted standard geometry failed")
        end

        apps = {}
        host:draw()
        if #host.projectedShortcuts ~= 0 or #host.hitRegions ~= 0 then
            error("Phone empty Home failed")
        end

        apps = { "app.one" }
        host:draw()
        if #host.projectedShortcuts ~= 1
            or host.hitRegions[1].action.appId ~= "app.one" then
            error("Phone one-app registry projection failed")
        end

        apps = { "app.one", "app.two", "app.three", "app.missingIcon" }
        unavailable["app.two"] = true
        host:draw()
        if #host.projectedShortcuts ~= 3
            or host.projectedShortcuts[3].iconId ~= "missing.icon" then
            error("Phone availability/icon fallback projection failed")
        end
        unavailable["app.two"] = nil

        apps = {}
        for index = 1, 13 do apps[index] = "app." .. tostring(index) end
        host:draw()
        if #host.projectedShortcuts ~= 13 or host.shortcutPageCount ~= 3
            or #host.hitRegions ~= 8 then
            error("Phone large-population paging failed")
        end
        local nextRegion = host.hitRegions[#host.hitRegions]
        host:onPointer(nextRegion.x + 0.001, nextRegion.y + 0.001,
            true, false, 1)
        host:onPointer(nextRegion.x + 0.001, nextRegion.y + 0.001,
            false, true, 1)
        host:draw()
        if host.shortcutPage ~= 2 or #host.hitRegions ~= 8 then
            error("Phone page transition failed")
        end
        host.shortcutPage = 3
        host:draw()
        if #host.hitRegions ~= 3 then
            error("Phone incomplete final page failed")
        end

        apps = { "app.generic" }
        host.shortcutPage = 1
        host:draw()

        -- PF.005: Phone shortcuts show attention, sampled on update only.
        attentionByApp["app.generic"] = { state = "unread", count = 150 }
        local queriesBefore = attentionQueries
        host:draw()
        if attentionQueries ~= queriesBefore then
            error("Phone queried attention while drawing")
        end
        host:update(600)
        if attentionQueries ~= queriesBefore + 1 then
            error("Phone did not sample attention once per application")
        end
        host:update(100)
        if attentionQueries ~= queriesBefore + 1 then
            error("Phone sampled attention before the refresh interval")
        end
        local rendersBefore = badgeRenders
        labels = {}; host:draw()
        local cappedSeen = false
        for _, label in ipairs(labels) do
            if label == "99+" then cappedSeen = true end
        end
        if not cappedSeen or badgeRenders <= rendersBefore then
            error("Phone did not draw a 99+ unread badge")
        end
        if attentionByApp["app.generic"].count ~= 150 then
            error("Phone display compression altered the attention value")
        end
        attentionByApp["app.generic"] = { state = "error" }
        host:update(600)
        rendersBefore = badgeRenders
        labels = {}; host:draw()
        if badgeRenders <= rendersBefore then
            error("Phone error badge was not drawn")
        end
        attentionFails = true
        host:update(600)
        rendersBefore = badgeRenders
        host:draw()
        if badgeRenders ~= rendersBefore then
            error("Phone drew a badge after attention failed")
        end
        attentionFails = false
        attentionByApp["app.generic"] = nil
        host:update(600)

        local launcher = host.hitRegions[1]
        host:onPointer(launcher.x + 0.001, launcher.y + 0.001,
            false, false, 1)
        if host.hoveredControl ~= "launcher:app.generic" then
            error("Phone hover seam failed")
        end
        host:onPointer(launcher.x + 0.001, launcher.y + 0.001,
            true, false, 1)
        host:onPointer(0.5, 0.5, false, true, 1)
        if activeAppId ~= nil then error("Phone release-outside launched app") end
        host:onPointer(launcher.x + 0.001, launcher.y + 0.001,
            true, false, 1)
        host:onPointer(launcher.x + 0.001, launcher.y + 0.001,
            false, true, 1)
        if calls[1] ~= "open:app.generic"
            or calls[2] ~= "activate:app.generic"
            or calls[3] ~= "navigate:app.generic:home"
            or activeAppId ~= "app.generic" then
            error("Phone generic launch lifecycle failed")
        end

        host:draw()
        local home
        for _, candidate in ipairs(host.hitRegions) do
            if candidate.action.phoneHome then home = candidate end
            if not candidate.action.phoneHome
                and (candidate.x < host.applicationViewport.x
                    or candidate.y < host.applicationViewport.y
                    or candidate.x + candidate.width
                        > host.applicationViewport.x
                            + host.applicationViewport.width
                    or candidate.y + candidate.height
                        > host.applicationViewport.y
                            + host.applicationViewport.height) then
                error("Application hit region escaped Phone viewport")
            end
        end
        if home == nil then error("Phone OS Home missing") end
        host:onPointer(home.x + 0.001, home.y + 0.001, true, false, 1)
        host:onPointer(home.x + 0.001, home.y + 0.001, false, true, 1)
        if activeAppId ~= nil or calls[#calls] ~= "close:app.generic" then
            error("Phone OS Home lifecycle failed")
        end

        host:onPointer(0.71, 0.13, true, false, 1)
        host:onPointer(0.71, 0.13, false, true, 1)
        if notificationMutations ~= 0 then
            error("Generic Phone shell mutated notification state")
        end
        if host:onPointer(0.2, 0.2, true, false, 1) then
            error("Phone claimed outside pointer")
        end

        -- The frame plus five badge images are deleted on shutdown.
        if host:shutdown() ~= Result.SUCCESS or overlayDeletes ~= 6 then
            error("Phone shutdown failed")
        end

        metrics = { width = 1280, height = 1024, uiScale = 1.25 }
        host = FORGE.PhoneHost.create(context)
        if host:initialize() ~= Result.SUCCESS
            or host.geometryProfile ~= "compact"
            or host.shortcutPageSize ~= 4
            or host:shutdown() ~= Result.SUCCESS then
            error("Phone trusted compact geometry failed")
        end
        if rectangles == 0 or #labels == 0 then
            error("Phone shell did not render")
        end
    end)

    drawFilledRect, renderText, setTextColor = originals[1], originals[2], originals[3]
    createImageOverlay, renderOverlay = originals[4], originals[5]
    setOverlayColor, delete = originals[6], originals[7]
    if not success then return false, errorMessage end
    return true
end
