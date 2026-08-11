---=============================================================================
--- FORGE ForgeOS Laptop Host
---
--- Presents the bounded M2.011 Laptop shell. It owns transient presentation
--- and input state only and remains independent of its activation source.
---=============================================================================

FORGE.LaptopHost = {}

local LaptopHost = FORGE.LaptopHost
local Result = FORGE.Definitions.ForgeOSResult
local Visibility = FORGE.Definitions.DeviceVisibility

local function safeText(value, fallback)
    if type(value) == "string" and value ~= "" then
        return value
    end
    return fallback
end

function LaptopHost.create(context)
    if type(context) ~= "table" then
        return nil
    end

    local instance = {
        context = context,
        initialized = false,
        bounds = { x = 0.08, y = 0.12, width = 0.54, height = 0.72 }
    }

    function instance:initialize()
        if self.initialized then
            return Result.SUCCESS
        end
        self.initialized = true
        FORGE.Logger:info(
            FORGE.Definitions.LogSource.LAPTOP_HOST,
            "Laptop Host initialized"
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
            or self.context.getVisibility() ~= Visibility.VISIBLE then
            return
        end

        local bounds = self.bounds
        drawPanel(bounds.x, bounds.y, bounds.width, bounds.height,
            0.012, 0.018, 0.028, 0.97)
        drawPanel(bounds.x + 0.009, bounds.y + 0.018,
            bounds.width - 0.018, bounds.height - 0.036,
            0.052, 0.064, 0.082, 0.98)
        drawPanel(bounds.x + 0.009,
            bounds.y + bounds.height - 0.014,
            bounds.width - 0.018, 0.005, 0.95, 0.48, 0.12, 1)

        local x = bounds.x + 0.025
        local y = bounds.y + bounds.height - 0.055
        setColor(0.96, 0.97, 0.99, 1)
        drawLabel("FORGE", x, y, 0.026)
        setColor(1, 0.56, 0.18, 1)
        drawLabel("OS", x + 0.09, y, 0.026)
        setColor(0.60, 0.64, 0.70, 1)
        drawLabel("LAPTOP  /  OPERATIONS DESKTOP", x, y - 0.032, 0.011)

        local appId = self.context.getActiveAppId()
        local appLabel = "Home"
        local presentationId = nil
        local routeId = nil
        if appId ~= nil then
            local app = self.context.getAppDefinition(appId)
            appLabel = safeText(app ~= nil and app.displayName or nil, appId)
            local _, resolution = self.context.resolvePresentation(appId)
            presentationId = resolution ~= nil
                and resolution.presentationId or nil
            routeId = self.context.getCurrentRoute(appId)
        end

        local workspaceY = bounds.y + bounds.height - 0.235
        local workspaceWidth = bounds.width * 0.52
        drawPanel(x, workspaceY, workspaceWidth, 0.12,
            0.09, 0.105, 0.13, 0.98)
        drawPanel(x, workspaceY + 0.115, workspaceWidth, 0.005,
            0.95, 0.48, 0.12, 1)
        setColor(0.62, 0.66, 0.72, 1)
        drawLabel("ACTIVE WORKSPACE", x + 0.014,
            workspaceY + 0.087, 0.011)
        setColor(0.96, 0.97, 0.99, 1)
        drawLabel(appLabel, x + 0.014, workspaceY + 0.055, 0.018)
        setColor(0.58, 0.62, 0.68, 1)
        drawLabel("Presentation  " .. safeText(presentationId, "home"),
            x + 0.014, workspaceY + 0.029, 0.010)
        drawLabel("Route  " .. safeText(routeId, "none"),
            x + 0.014, workspaceY + 0.011, 0.010)

        local launcherX = bounds.x + bounds.width * 0.56
        local launcherY = bounds.y + bounds.height - 0.108
        setColor(0.62, 0.66, 0.72, 1)
        drawLabel("APPLICATIONS", launcherX, launcherY, 0.011)
        local shownApps = 0
        for _, registeredAppId in ipairs(self.context.getRegisteredAppIds()) do
            local app = self.context.getAppDefinition(registeredAppId)
            if app ~= nil
                and type(app.supportedDevices) == "table"
                and app.supportedDevices.laptop == true
                and shownApps < 6 then
                local column = shownApps % 2
                local row = math.floor(shownApps / 2)
                local cardWidth = bounds.width * 0.185
                local cardX = launcherX + column * (cardWidth + 0.012)
                local cardY = launcherY - 0.082 - row * 0.09
                drawPanel(cardX, cardY, cardWidth, 0.072,
                    0.10, 0.118, 0.145, 0.98)
                drawPanel(cardX, cardY + 0.067, cardWidth, 0.005,
                    column == 0 and 0.22 or 0.95,
                    column == 0 and 0.62 or 0.48,
                    column == 0 and 0.95 or 0.12, 1)
                setColor(0.96, 0.97, 0.99, 1)
                drawLabel(safeText(app.displayName, registeredAppId),
                    cardX + 0.01, cardY + 0.038, 0.012)
                setColor(0.58, 0.62, 0.68, 1)
                drawLabel("SHORTCUT", cardX + 0.01, cardY + 0.015, 0.009)
                shownApps = shownApps + 1
            end
        end

        local notifications = self.context.getNotifications()
        local unread = 0
        for _, notification in ipairs(notifications) do
            if not notification.read and not notification.dismissed then
                unread = unread + 1
            end
        end
        local notificationY = bounds.y + 0.285
        setColor(0.62, 0.66, 0.72, 1)
        drawLabel("NOTIFICATIONS", x, notificationY, 0.011)
        if unread > 0 then
            drawPanel(x + 0.14, notificationY - 0.004,
                0.032, 0.024, 0.95, 0.48, 0.12, 1)
            setColor(0.08, 0.05, 0.02, 1)
            drawLabel(tostring(unread), x + 0.151,
                notificationY + 0.002, 0.011)
        end
        local shown = 0
        for _, notification in ipairs(notifications) do
            if not notification.dismissed and shown < 5 then
                shown = shown + 1
                notificationY = notificationY - 0.034
                setColor(notification.read and 0.62 or 0.96,
                    notification.read and 0.66 or 0.97,
                    notification.read and 0.72 or 0.99, 1)
                drawLabel((notification.read and "" or "* ")
                    .. safeText(notification.title, notification.id),
                    x, notificationY, 0.011)
            end
        end
        drawPanel(bounds.x + 0.009, bounds.y + 0.018,
            bounds.width - 0.018, 0.038, 0.035, 0.043, 0.055, 0.99)
        setColor(0.58, 0.62, 0.68, 1)
        drawLabel("F8 CLOSE", x, bounds.y + 0.031, 0.010)
        drawLabel("F6 POINTER MODE", bounds.x + bounds.width - 0.155,
            bounds.y + 0.031, 0.010)
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
            result = self.context.navigate(destination.appId,
                destination.routeId, destination.routeParameters)
        end
        if result ~= Result.SUCCESS then
            self.context.closeApp(destination.appId)
            FORGE.Logger:warning(
                FORGE.Definitions.LogSource.LAPTOP_HOST,
                "Laptop resume failed; displaying Home surface"
            )
        end
        return Result.SUCCESS
    end

    function instance:onInput(action, value, payload)
        if not self.initialized or self.context.isUiBlocked() then
            return false
        end
        if action == "FORGE_TOGGLE_LAPTOP" and value ~= 0 then
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
        if action == "LAPTOP_MARK_READ" and type(payload) == "string" then
            self.context.markNotificationRead(payload)
            return true
        end
        if action == "LAPTOP_DISMISS" and type(payload) == "string" then
            self.context.dismissNotification(payload)
            return true
        end
        return action == "KEY_EVENT" and value ~= 0
    end

    function instance:onPointer(posX, posY, isDown, isUp, button)
        if not self.initialized or self.context.isUiBlocked()
            or self.context.getVisibility() ~= Visibility.VISIBLE
            or not self:containsPoint(posX, posY) then
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
        self.initialized = false
        FORGE.Logger:info(
            FORGE.Definitions.LogSource.LAPTOP_HOST,
            "Laptop Host shut down"
        )
        return Result.SUCCESS
    end

    return instance
end
