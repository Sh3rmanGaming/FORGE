---=============================================================================
--- FORGE PF.003 Laptop Host Tests
---=============================================================================

FORGE.Tests = FORGE.Tests or {}

function FORGE.Tests.runLaptopHostTests()
    local Result = FORGE.Definitions.ForgeOSResult
    local Visibility = FORGE.Definitions.DeviceVisibility
    local visibility, activeAppId, routeId = Visibility.HIDDEN, nil, nil
    local population, unavailable = {}, {}
    local sequence, labels = {}, {}
    local overlays, overlayDeletes, notificationQueries = 0, 0, 0
    local attentionQueries, attentionFails, badgeRenders = 0, false, 0
    local attentionByApp = { ["forge.one"] = { state = "unread", count = 3 } }

    local function definition(appId)
        return { id = appId, displayName = "Application " .. appId,
            iconId = appId == "forge.two" and "forge.icon.two" or nil,
            supportedDevices = { laptop = true } }
    end

    local context = {
        getVisibility = function() return visibility end,
        show = function() visibility = Visibility.VISIBLE; return Result.SUCCESS end,
        hide = function() visibility = Visibility.HIDDEN; return Result.SUCCESS end,
        getActiveAppId = function() return activeAppId end,
        getRegisteredAppIds = function() return population end,
        getAppDefinition = definition,
        resolvePresentation = function(appId)
            if unavailable[appId] then return Result.NOT_AVAILABLE, nil end
            return Result.SUCCESS, { presentationId = appId .. ".laptop",
                presentation = { defaultRoute = "home" } }
        end,
        getCurrentRoute = function() return routeId end,
        getValidatedResumeDestination = function() return Result.SUCCESS, nil end,
        openApp = function(appId)
            sequence[#sequence + 1] = "open:" .. appId; return Result.SUCCESS
        end,
        activateApp = function(appId)
            sequence[#sequence + 1] = "activate:" .. appId
            activeAppId = appId; return Result.SUCCESS
        end,
        navigate = function(appId, destination)
            sequence[#sequence + 1] = "navigate:" .. appId .. ":" .. destination
            routeId = destination; return Result.SUCCESS
        end,
        closeApp = function(appId)
            sequence[#sequence + 1] = "close:" .. appId
            activeAppId, routeId = nil, nil; return Result.SUCCESS
        end,
        getApplicationBadge = function(appId)
            return appId == "forge.one" and 3 or 0
        end,
        getApplicationAttention = function(appId)
            attentionQueries = attentionQueries + 1
            if attentionFails then error("attention provider failure") end
            return attentionByApp[appId] or { state = "none", count = 0 }
        end,
        getApplicationPresentationModel = function() return nil end,
        performApplicationAction = function() return Result.NOT_AVAILABLE end,
        getNotifications = function()
            notificationQueries = notificationQueries + 1; return {}
        end,
        isUiBlocked = function() return false end,
        getViewportMetrics = function()
            return { width = 1920, height = 1080, uiScale = 1 }
        end
    }

    local originalDrawFilledRect, originalRenderText = drawFilledRect, renderText
    local originalSetTextColor = setTextColor
    local originalCreateImageOverlay, originalRenderOverlay =
        createImageOverlay, renderOverlay
    local originalSetOverlayColor, originalDelete = setOverlayColor, delete
    drawFilledRect = function() end
    renderText = function(_, _, _, text) labels[#labels + 1] = text end
    setTextColor = function() end
    createImageOverlay = function(path)
        return string.find(path, "badge_", 1, true) and 300 or 200
    end
    renderOverlay = function(overlay)
        overlays = overlays + 1
        if overlay == 300 then badgeRenders = badgeRenders + 1 end
    end
    setOverlayColor = function() end
    delete = function() overlayDeletes = overlayDeletes + 1 end

    local success, errorMessage = pcall(function()
        local host = FORGE.LaptopHost.create(context)
        if host == nil or host:initialize() ~= Result.SUCCESS
            or not host:isOperational()
            or host:onInput("FORGE_TOGGLE_LAPTOP", 1) ~= true
            or visibility ~= Visibility.VISIBLE then
            error("Laptop Host lifecycle failed")
        end

        host:draw()
        local emptySeen = false
        for _, label in ipairs(labels) do
            if label == "No Laptop applications available" then emptySeen = true end
        end
        if not emptySeen or notificationQueries ~= 0 then
            error("Laptop empty state or permanent-feed removal failed")
        end

        population = { "forge.one", "forge.two", "forge.unavailable" }
        unavailable["forge.unavailable"] = true
        labels = {}; host:draw()
        if #host.projectedShortcuts ~= 2 or host.shortcutPageCount ~= 1
            or #host.hitRegions ~= 2 then
            error("Laptop registry projection failed")
        end

        -- PF.005: attention is sampled on update and never while drawing.
        local queriesBefore = attentionQueries
        labels = {}; host:draw()
        if attentionQueries ~= queriesBefore then
            error("Laptop queried attention while drawing")
        end
        host:update(600)
        if attentionQueries ~= queriesBefore + 3 then
            error("Laptop did not sample attention once per application")
        end
        host:update(100)
        if attentionQueries ~= queriesBefore + 3 then
            error("Laptop sampled attention before the refresh interval")
        end
        local overlaysBefore = badgeRenders
        labels = {}; host:draw()
        local countSeen = false
        for _, label in ipairs(labels) do
            if label == "3" then countSeen = true end
        end
        if not countSeen or badgeRenders <= overlaysBefore then
            error("Laptop unread badge did not draw the count over its image")
        end
        attentionByApp["forge.one"] = { state = "warning" }
        host:update(600)
        overlaysBefore = badgeRenders
        labels = {}; host:draw()
        for _, label in ipairs(labels) do
            if label == "3" then error("Laptop kept a stale attention count") end
        end
        if badgeRenders <= overlaysBefore then
            error("Laptop warning badge was not drawn")
        end
        attentionFails = true
        host:update(600)
        overlaysBefore = badgeRenders
        labels = {}; host:draw()
        if badgeRenders ~= overlaysBefore then
            error("Laptop drew a badge after attention failed")
        end
        attentionFails = false
        attentionByApp["forge.one"] = { state = "unread", count = 3 }

        local one = host.hitRegions[1]
        host:onPointer(one.x + 0.01, one.y + 0.01, false, false, 1)
        if host.hoveredControl ~= one.id then error("Laptop hover failed") end
        if not host:onPointer(one.x + 0.01, one.y + 0.01, true, false, 1)
            or #sequence ~= 0
            or not host:onPointer(one.x + 0.01, one.y + 0.01, false, true, 1)
            or sequence[1] ~= "open:forge.one"
            or sequence[2] ~= "activate:forge.one"
            or sequence[3] ~= "navigate:forge.one:home" then
            error("Laptop generic launcher lifecycle failed")
        end

        host:draw()
        if host.applicationViewport.width <= host.shortcutViewport.width
            or host.applicationViewport.height <= 0.70 then
            error("Laptop application viewport is not dominant")
        end
        local home
        for _, hit in ipairs(host.hitRegions) do
            if hit.id == "laptopHome" then home = hit end
        end
        if home == nil
            or not host:onPointer(home.x + 0.01, home.y + 0.01, true, false, 1)
            or not host:onPointer(home.x + 0.01, home.y + 0.01, false, true, 1)
            or activeAppId ~= nil or sequence[#sequence] ~= "close:forge.one" then
            error("Laptop OS Home/Desktop failed")
        end

        population, unavailable = {}, {}
        for index = 1, 19 do
            population[index] = string.format("forge.app%02d", index)
        end
        host:draw()
        if #host.projectedShortcuts ~= 19 or host.shortcutPageCount ~= 3
            or host.shortcutPageSize ~= 8 or #host.hitRegions ~= 10 then
            error("Laptop shortcut overflow contract failed")
        end
        local nextPage = host.hitRegions[#host.hitRegions]
        host:onPointer(nextPage.x + 0.005, nextPage.y + 0.005, true, false, 1)
        host:onPointer(nextPage.x + 0.005, nextPage.y + 0.005, false, true, 1)
        if host.shortcutPage ~= 2 then error("Laptop page control failed") end
        host:draw()
        host:onPointer(host.shortcutViewport.x + 0.01,
            host.shortcutViewport.y + 0.10, true, false, 4)
        if host.shortcutPage ~= 3 then error("Laptop wheel overflow failed") end

        context.getViewportMetrics = function()
            return { width = 1280, height = 1024, uiScale = 1.25 }
        end
        local compact = FORGE.LaptopHost.create(context)
        compact:initialize(); compact:draw()
        if compact.shortcutPageSize ~= 6
            or #compact.projectedShortcuts ~= 19
            or compact.shortcutPageCount ~= 4 then
            error("Laptop compact geometry profile failed")
        end
        compact:shutdown()

        -- PF.006: toasts stack to three, a tap activates through the private
        -- context, a closed Laptop shows none, and expiry only hides them.
        local cueQueue, activated = {}, {}
        context.takeNotificationCues = function()
            local taken = cueQueue
            cueQueue = {}
            return taken
        end
        context.activateNotification = function(notificationId)
            activated[#activated + 1] = notificationId
            return { result = "success", stage = "complete" }
        end
        local function toast(number)
            return { notificationId = "notification." .. number,
                source = "forge.test", title = "Toast " .. number,
                body = "Body", severity = "info", actionable = true }
        end
        visibility = Visibility.VISIBLE
        cueQueue = { toast(1), toast(2), toast(3), toast(4) }
        host:update(16)
        labels = {}
        host:draw()
        local shown = 0
        for _, label in ipairs(labels) do
            if string.sub(label, 1, 5) == "Toast" then shown = shown + 1 end
        end
        if shown ~= 3 or not host:hasTransientCue() then
            error("Laptop toast stack should show exactly three")
        end
        local toastRegion = host.cues.regions[1]
        host:onPointer(toastRegion.x + 0.01, toastRegion.y + 0.01,
            true, false, 1)
        host:onPointer(toastRegion.x + 0.01, toastRegion.y + 0.01,
            false, true, 1)
        if activated[1] ~= toastRegion.notificationId then
            error("Laptop toast tap did not activate its destination")
        end
        host:update(10000)
        if host:hasTransientCue() or notificationQueries ~= 0 then
            error("Laptop toast expiry or notification query misbehaved")
        end
        visibility = Visibility.HIDDEN
        cueQueue = { toast(5) }
        host:update(16)
        labels = {}
        host:draw()
        for _, label in ipairs(labels) do
            if label == "Toast 5" then error("closed Laptop drew a toast") end
        end
        if host:hasTransientCue() or #cueQueue ~= 0 then
            error("closed Laptop kept or failed to drain a cue")
        end
        visibility = Visibility.VISIBLE

        if overlays < 1 or notificationQueries ~= 0
            or not host:containsPoint(0.20, 0.20)
            or host:containsPoint(0.99, 0.99)
            or host:shutdown() ~= Result.SUCCESS
            -- Each Host deletes its wallpaper plus five badge images; two
            -- Hosts shut down in this test.
            or overlayDeletes ~= 12 or host:isOperational() then
            error("Laptop shell/fallback/shutdown contract failed")
        end
    end)

    drawFilledRect, renderText = originalDrawFilledRect, originalRenderText
    setTextColor = originalSetTextColor
    createImageOverlay, renderOverlay = originalCreateImageOverlay,
        originalRenderOverlay
    setOverlayColor, delete = originalSetOverlayColor, originalDelete
    if not success then return false, errorMessage end
    return true
end
