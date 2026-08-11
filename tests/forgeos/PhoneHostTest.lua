---=============================================================================
--- FORGE Phone Host Tests
---=============================================================================

FORGE.Tests = FORGE.Tests or {}

function FORGE.Tests.runPhoneHostTests()
    local Result = FORGE.Definitions.ForgeOSResult
    local Visibility = FORGE.Definitions.DeviceVisibility
    local visibility = Visibility.HIDDEN
    local shows = 0
    local hides = 0
    local reads = 0
    local dismissals = 0
    local rectangles = 0
    local labels = 0
    local overlays = 0
    local overlayDeletes = 0
    local resumeCalls = {}
    local resumeDestination = nil
    local context = {
        getVisibility = function() return visibility end,
        show = function() visibility = Visibility.VISIBLE; shows = shows + 1; return Result.SUCCESS end,
        hide = function() visibility = Visibility.HIDDEN; hides = hides + 1; return Result.SUCCESS end,
        getActiveAppId = function() return nil end,
        getRegisteredAppIds = function() return { "forge.test" } end,
        getAppDefinition = function()
            return {
                id = "forge.test",
                displayName = "Test App",
                supportedDevices = { phone = true }
            }
        end,
        resolvePresentation = function() return Result.NOT_AVAILABLE, nil end,
        getCurrentRoute = function() return nil end,
        getValidatedResumeDestination = function() return Result.SUCCESS, resumeDestination end,
        openApp = function(appId) table.insert(resumeCalls, "open:" .. appId); return Result.SUCCESS end,
        activateApp = function(appId) table.insert(resumeCalls, "activate:" .. appId); return Result.SUCCESS end,
        navigate = function(appId, routeId) table.insert(resumeCalls, "navigate:" .. appId .. ":" .. routeId); return Result.SUCCESS end,
        closeApp = function() return Result.SUCCESS end,
        getNotifications = function()
            return {{ id = "notification.1", title = "Test", severity = "info", read = false, dismissed = false }}
        end,
        markNotificationRead = function() reads = reads + 1; return Result.SUCCESS end,
        dismissNotification = function() dismissals = dismissals + 1; return Result.SUCCESS end,
        isUiBlocked = function() return false end
    }

    local originalDrawFilledRect = drawFilledRect
    local originalRenderText = renderText
    local originalSetTextColor = setTextColor
    local originalCreateImageOverlay = createImageOverlay
    local originalRenderOverlay = renderOverlay
    local originalSetOverlayColor = setOverlayColor
    local originalDelete = delete
    drawFilledRect = function() rectangles = rectangles + 1 end
    renderText = function() labels = labels + 1 end
    setTextColor = function() end
    createImageOverlay = function() return 100 end
    renderOverlay = function() overlays = overlays + 1 end
    setOverlayColor = function() end
    delete = function() overlayDeletes = overlayDeletes + 1 end

    local success, errorMessage = pcall(function()
        local host = FORGE.PhoneHost.create(context)
        if host == nil or host:initialize() ~= Result.SUCCESS
            or not host:isOperational()
            or host:onInput("FORGE_TOGGLE_PHONE", 1) ~= true
            or shows ~= 1
            or (host:draw() == false)
            or rectangles < 3
            or labels < 10
            or overlays < 2
            or host:onPointer(0.71, 0.13, true, false, 1) ~= true
            or reads ~= 1
            or host:onPointer(0.71, 0.13, true, false, 3) ~= true
            or dismissals ~= 1
            or host:onPointer(0.1, 0.1, true, false, 1) ~= false
            or host:onInput("FORGE_TOGGLE_PHONE", 1) ~= true
            or hides ~= 1
            or host:onPointer(0.71, 0.13, true, false, 1) ~= false
            or host:onInput("KEY_EVENT", 1, { sym = 118 }) ~= false
            or shows ~= 1
            or host:onInput("KEY_EVENT", 0, { sym = 118 }) ~= false
            or host:shutdown() ~= Result.SUCCESS
            or overlayDeletes ~= 2
            or host:isOperational() then
            error("Phone Host presentation/input lifecycle failed")
        end

        resumeDestination = {
            appId = "forge.resume",
            routeId = "home",
            routeParameters = {}
        }
        if host:initialize() ~= Result.SUCCESS
            or host:resume() ~= Result.SUCCESS
            or resumeCalls[1] ~= "open:forge.resume"
            or resumeCalls[2] ~= "activate:forge.resume"
            or resumeCalls[3] ~= "navigate:forge.resume:home"
            or host:shutdown() ~= Result.SUCCESS then
            error("Phone Host resume orchestration failed")
        end
    end)

    drawFilledRect = originalDrawFilledRect
    renderText = originalRenderText
    setTextColor = originalSetTextColor
    createImageOverlay = originalCreateImageOverlay
    renderOverlay = originalRenderOverlay
    setOverlayColor = originalSetOverlayColor
    delete = originalDelete

    if not success then return false, errorMessage end
    return true
end
