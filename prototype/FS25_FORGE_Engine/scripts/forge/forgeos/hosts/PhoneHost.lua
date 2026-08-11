---=============================================================================
--- FORGE ForgeOS Phone Host
---
--- Presents the bounded M2.010 Phone shell. It owns transient presentation and
--- input state only and receives no mutable ForgeOS internals.
---=============================================================================

FORGE.PhoneHost = {}

local PhoneHost = FORGE.PhoneHost
local Result = FORGE.Definitions.ForgeOSResult
local DeviceId = FORGE.Definitions.DeviceId
local Visibility = FORGE.Definitions.DeviceVisibility

local function safeText(value, fallback)
    if type(value) == "string" and value ~= "" then
        return value
    end
    return fallback
end

function PhoneHost.create(context)
    if type(context) ~= "table" then
        return nil
    end

    local instance = {
        context = context,
        initialized = false,
        frameOverlay = nil,
        appCardOverlay = nil,
        bounds = { x = 0.70, y = 0.12, width = 0.27, height = 0.76 }
    }

    function instance:initialize()
        if self.initialized then
            return Result.SUCCESS
        end

        if type(createImageOverlay) == "function"
            and type(FORGE.ModDirectory) == "string" then
            local overlayCreated, overlay = pcall(
                createImageOverlay,
                FORGE.ModDirectory
                    .. "scripts/forge/forgeos/assets/phone_frame.dds"
            )
            if overlayCreated then
                self.frameOverlay = overlay
            end
            local cardCreated, cardOverlay = pcall(
                createImageOverlay,
                FORGE.ModDirectory
                    .. "scripts/forge/forgeos/assets/app_card.dds"
            )
            if cardCreated then
                self.appCardOverlay = cardOverlay
            end
        end

        self.initialized = true
        FORGE.Logger:info(
            FORGE.Definitions.LogSource.PHONE_HOST,
            "Phone Host initialized"
        )
        return Result.SUCCESS
    end

    function instance:isOperational()
        return self.initialized
    end

    function instance:containsPoint(posX, posY)
        local bounds = self.bounds
        return type(posX) == "number" and type(posY) == "number"
            and posX >= bounds.x
            and posX <= bounds.x + bounds.width
            and posY >= bounds.y
            and posY <= bounds.y + bounds.height
    end

    function instance:update(dt)
        if not self.initialized or type(dt) ~= "number" then
            return
        end
    end

    local function drawLabel(text, x, y, size)
        if type(renderText) == "function" then
            renderText(x, y, size, tostring(text))
        end
    end

    local function setColor(red, green, blue, alpha)
        if type(setTextColor) == "function" then
            setTextColor(red, green, blue, alpha or 1)
        end
    end

    local function drawPanel(x, y, width, height, red, green, blue, alpha)
        if type(drawFilledRect) == "function" then
            drawFilledRect(x, y, width, height, red, green, blue, alpha)
        end
    end

    function instance:draw()
        if not self.initialized
            or self.context.getVisibility()
                ~= Visibility.VISIBLE then
            return
        end

        local bounds = self.bounds
        if self.frameOverlay ~= nil and type(renderOverlay) == "function" then
            if type(setOverlayColor) == "function" then
                setOverlayColor(self.frameOverlay, 1, 1, 1, 1)
            end
            renderOverlay(self.frameOverlay,
                bounds.x - 0.014, bounds.y - 0.014,
                bounds.width + 0.028, bounds.height + 0.028)
        else
            drawPanel(bounds.x, bounds.y, bounds.width, bounds.height,
                0.01, 0.014, 0.019, 0.97)
            drawPanel(bounds.x + 0.004, bounds.y + 0.012,
                bounds.width - 0.008, bounds.height - 0.024,
                0.045, 0.055, 0.068, 0.98)
        end

        -- Keep frame hardware visually separate from the OS content.
        drawPanel(bounds.x + 0.012,
            bounds.y + bounds.height - 0.072,
            bounds.width - 0.024, 0.004, 0.95, 0.48, 0.12, 1)

        local x = bounds.x + 0.022
        local y = bounds.y + bounds.height - 0.112
        setColor(0.96, 0.97, 0.99, 1)
        drawLabel("FORGE", x, y, 0.026)
        setColor(1, 0.56, 0.18, 1)
        drawLabel("OS", x + 0.088, y, 0.026)
        setColor(0.60, 0.64, 0.70, 1)
        drawLabel("OPERATIONS HUB", x, y - 0.03, 0.011)

        local appId = self.context.getActiveAppId()
        local presentationId = nil
        local routeId = nil
        local appLabel = "Home"

        if appId ~= nil then
            local app = self.context.getAppDefinition(appId)
            appLabel = safeText(
                app ~= nil and app.displayName or nil,
                appId
            )
            local _, resolution =
                self.context.resolvePresentation(appId)
            presentationId = resolution ~= nil
                and resolution.presentationId
                or nil
            routeId = self.context.getCurrentRoute(appId)
        end

        local surfaceY = bounds.y + bounds.height - 0.235
        drawPanel(x, surfaceY, bounds.width - 0.044, 0.09,
            0.09, 0.105, 0.125, 0.98)
        drawPanel(x, surfaceY + 0.086, bounds.width - 0.044, 0.004,
            0.95, 0.48, 0.12, 1)
        setColor(0.63, 0.67, 0.72, 1)
        drawLabel("ACTIVE SURFACE", x + 0.012, surfaceY + 0.061, 0.011)
        setColor(0.96, 0.97, 0.99, 1)
        drawLabel(appLabel, x + 0.012, surfaceY + 0.035, 0.017)
        setColor(0.60, 0.64, 0.70, 1)
        drawLabel(safeText(presentationId, "home") .. "  /  "
            .. safeText(routeId, "none"), x + 0.012, surfaceY + 0.014, 0.010)

        local launcherY = surfaceY - 0.03
        setColor(0.63, 0.67, 0.72, 1)
        drawLabel("APPLICATIONS", x, launcherY, 0.011)
        local cardY = launcherY - 0.072
        local cardWidth = (bounds.width - 0.054) / 2
        local shownApps = 0
        local registeredApps = type(self.context.getRegisteredAppIds)
                == "function"
            and self.context.getRegisteredAppIds()
            or {}
        for _, registeredAppId in ipairs(registeredApps) do
            local app = self.context.getAppDefinition(registeredAppId)
            if app ~= nil
                and type(app.supportedDevices) == "table"
                and app.supportedDevices.phone == true
                and shownApps < 4 then
                local column = shownApps % 2
                local row = math.floor(shownApps / 2)
                local cardX = x + column * (cardWidth + 0.01)
                local currentY = cardY - row * 0.078
                if self.appCardOverlay ~= nil
                    and type(renderOverlay) == "function" then
                    if type(setOverlayColor) == "function" then
                        setOverlayColor(self.appCardOverlay, 1, 1, 1, 1)
                    end
                    renderOverlay(self.appCardOverlay,
                        cardX, currentY, cardWidth, 0.064)
                else
                    drawPanel(cardX, currentY, cardWidth, 0.064,
                        0.105, 0.12, 0.145, 0.98)
                    drawPanel(cardX, currentY + 0.06, cardWidth, 0.004,
                        0.95, 0.48, 0.12, 1)
                end
                setColor(0.95, 0.96, 0.98, 1)
                drawLabel(safeText(app.displayName, registeredAppId),
                    cardX + 0.009, currentY + 0.035, 0.012)
                setColor(0.58, 0.62, 0.68, 1)
                drawLabel("OPEN", cardX + 0.009, currentY + 0.014, 0.009)
                shownApps = shownApps + 1
            end
        end
        if shownApps == 0 then
            setColor(0.52, 0.56, 0.62, 1)
            drawLabel("No applications registered", x, cardY + 0.02, 0.011)
        end

        local notifications = self.context.getNotifications()
        local unread = 0
        for _, notification in ipairs(notifications) do
            if not notification.read and not notification.dismissed then
                unread = unread + 1
            end
        end

        local notificationY = bounds.y + 0.205
        setColor(0.63, 0.67, 0.72, 1)
        drawLabel("NOTIFICATIONS", x, notificationY, 0.011)
        if unread > 0 then
            drawPanel(x + bounds.width - 0.087, notificationY - 0.004,
                0.03, 0.024, 0.95, 0.48, 0.12, 1)
            setColor(0.08, 0.05, 0.02, 1)
            drawLabel(tostring(unread), x + bounds.width - 0.077,
                notificationY + 0.002, 0.011)
        end

        local shown = 0
        for _, notification in ipairs(notifications) do
            if not notification.dismissed and shown < 4 then
                shown = shown + 1
                notificationY = notificationY - 0.036
                local marker = notification.read and "" or "* "
                setColor(notification.read and 0.62 or 0.96,
                    notification.read and 0.66 or 0.97,
                    notification.read and 0.72 or 0.99, 1)
                drawLabel(
                    marker .. safeText(notification.title, notification.id)
                        .. " [" .. safeText(notification.severity, "") .. "]",
                    x,
                    notificationY,
                    0.011
                )
            end
        end
        setColor(0.52, 0.56, 0.62, 1)
        drawLabel("F7 CLOSE  |  F6 POINTER", x, bounds.y + 0.035, 0.010)
        setColor(1, 1, 1, 1)
    end

    function instance:resume()
        if self.context.getActiveAppId() ~= nil then
            return Result.SUCCESS
        end

        local resumeResult, destination =
            self.context.getValidatedResumeDestination()

        if resumeResult ~= Result.SUCCESS then
            return resumeResult
        end

        if destination == nil then
            return Result.SUCCESS
        end

        local result = self.context.openApp(destination.appId)
        if result == Result.SUCCESS then
            result = self.context.activateApp(destination.appId)
        end
        if result == Result.SUCCESS then
            result = self.context.navigate(
                destination.appId,
                destination.routeId,
                destination.routeParameters
            )
        end

        if result ~= Result.SUCCESS then
            self.context.closeApp(destination.appId)
            FORGE.Logger:warning(
                FORGE.Definitions.LogSource.PHONE_HOST,
                "Phone resume failed; displaying Home surface"
            )
        end

        return Result.SUCCESS
    end

    function instance:onInput(action, value, ...)
        if not self.initialized or self.context.isUiBlocked() then
            return false
        end

        local toggleRequested =
            action == "FORGE_TOGGLE_PHONE" and value ~= 0

        if toggleRequested then
            if self.context.getVisibility() == Visibility.VISIBLE then
                self.context.hide()
            else
                self.context.show()
            end
            return true
        end

        if self.context.getVisibility() ~= Visibility.VISIBLE then
            return false
        end

        local payload = select(1, ...)
        if action == "PHONE_MARK_READ"
            and type(payload) == "string" then
            self.context.markNotificationRead(payload)
            return true
        end
        if action == "PHONE_DISMISS"
            and type(payload) == "string" then
            self.context.dismissNotification(payload)
            return true
        end

        return false
    end

    function instance:onPointer(posX, posY, isDown, isUp, button)
        if not self.initialized
            or self.context.isUiBlocked()
            or self.context.getVisibility() ~= Visibility.VISIBLE then
            return false
        end

        if not self:containsPoint(posX, posY) then
            return false
        end

        if isDown then
            local notifications = self.context.getNotifications()
            if button == 1 then
                for _, notification in ipairs(notifications) do
                    if not notification.read and not notification.dismissed then
                        self.context.markNotificationRead(notification.id)
                        break
                    end
                end
            elseif button == 2 or button == 3 then
                for _, notification in ipairs(notifications) do
                    if not notification.dismissed then
                        self.context.dismissNotification(notification.id)
                        break
                    end
                end
            end
        end

        return true
    end

    function instance:shutdown()
        if self.frameOverlay ~= nil and type(delete) == "function" then
            pcall(delete, self.frameOverlay)
        end
        if self.appCardOverlay ~= nil and type(delete) == "function" then
            pcall(delete, self.appCardOverlay)
        end
        self.frameOverlay = nil
        self.appCardOverlay = nil
        self.initialized = false
        FORGE.Logger:info(
            FORGE.Definitions.LogSource.PHONE_HOST,
            "Phone Host shut down"
        )
        return Result.SUCCESS
    end

    return instance
end
