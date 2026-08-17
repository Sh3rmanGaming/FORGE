---=============================================================================
--- FORGE Laptop Host Tests
---=============================================================================

FORGE.Tests = FORGE.Tests or {}

function FORGE.Tests.runLaptopHostTests()
    local Result = FORGE.Definitions.ForgeOSResult
    local Visibility = FORGE.Definitions.DeviceVisibility
    local visibility = Visibility.HIDDEN
    local reads, dismissals = 0, 0
    local rectangles, labels = 0, 0
    local overlays, overlayDeletes = 0, 0
    local context = {
        getVisibility = function() return visibility end,
        show = function() visibility = Visibility.VISIBLE; return Result.SUCCESS end,
        hide = function() visibility = Visibility.HIDDEN; return Result.SUCCESS end,
        getActiveAppId = function() return nil end,
        getRegisteredAppIds = function() return { "forge.test" } end,
        getAppDefinition = function() return { id = "forge.test", displayName = "Test", supportedDevices = { laptop = true } } end,
        resolvePresentation = function() return Result.SUCCESS, { presentationId = "test.laptop" } end,
        getCurrentRoute = function() return nil end,
        getValidatedResumeDestination = function() return Result.SUCCESS, nil end,
        openApp = function() return Result.SUCCESS end,
        activateApp = function() return Result.SUCCESS end,
        navigate = function() return Result.SUCCESS end,
        closeApp = function() return Result.SUCCESS end,
        getNotifications = function() return {{ id = "notification.1", title = "Test", read = false, dismissed = false }} end,
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
    createImageOverlay = function() return 200 end
    renderOverlay = function() overlays = overlays + 1 end
    setOverlayColor = function() end
    delete = function() overlayDeletes = overlayDeletes + 1 end

    local success, errorMessage = pcall(function()
        local host = FORGE.LaptopHost.create(context)
        if host == nil or host:initialize() ~= Result.SUCCESS
            or not host:isOperational()
            or host:onInput("FORGE_TOGGLE_LAPTOP", 1) ~= true
            or visibility ~= Visibility.VISIBLE
            or (host:draw() == false)
            or rectangles < 5
            or labels < 8
            or overlays < 1
            or not host:containsPoint(0.20, 0.20)
            or host:containsPoint(0.99, 0.99)
            or host:onPointer(0.20, 0.20, true, false, 1) ~= true
            or reads ~= 1
            or host:onPointer(0.20, 0.20, true, false, 3) ~= true
            or dismissals ~= 1
            or host:onPointer(0.99, 0.99, true, false, 1) ~= false
            or host:shutdown() ~= Result.SUCCESS
            or overlayDeletes ~= 1
            or host:isOperational() then
            error("Laptop Host bounded shell contract failed")
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
