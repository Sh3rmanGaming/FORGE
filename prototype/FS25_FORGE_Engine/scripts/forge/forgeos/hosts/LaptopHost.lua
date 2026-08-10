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

    function instance:draw()
        if not self.initialized
            or self.context.getVisibility() ~= Visibility.VISIBLE then
            return
        end

        local bounds = self.bounds
        if type(drawFilledRect) == "function" then
            drawFilledRect(bounds.x, bounds.y, bounds.width, bounds.height,
                0.025, 0.035, 0.055, 0.96)
            drawFilledRect(bounds.x + 0.01, bounds.y + 0.02,
                bounds.width - 0.02, bounds.height - 0.04,
                0.10, 0.12, 0.16, 0.98)
        end

        if type(setTextColor) == "function" then
            setTextColor(1, 1, 1, 1)
        end

        local x = bounds.x + 0.025
        local y = bounds.y + bounds.height - 0.055
        drawLabel("FORGE Laptop", x, y, 0.026)
        y = y - 0.05
        drawLabel("Home / Desktop", x, y, 0.019)

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

        y = y - 0.05
        drawLabel("Application: " .. appLabel, x, y, 0.017)
        y = y - 0.032
        drawLabel("Presentation: " .. safeText(presentationId, "home"), x, y, 0.014)
        y = y - 0.028
        drawLabel("Route: " .. safeText(routeId, "none"), x, y, 0.014)

        local launcherX = bounds.x + bounds.width * 0.56
        local launcherY = bounds.y + bounds.height - 0.105
        drawLabel("Applications", launcherX, launcherY, 0.017)
        local shownApps = 0
        for _, registeredAppId in ipairs(self.context.getRegisteredAppIds()) do
            local app = self.context.getAppDefinition(registeredAppId)
            if app ~= nil
                and type(app.supportedDevices) == "table"
                and app.supportedDevices.laptop == true
                and shownApps < 6 then
                shownApps = shownApps + 1
                launcherY = launcherY - 0.035
                drawLabel(safeText(app.displayName, registeredAppId), launcherX, launcherY, 0.014)
            end
        end

        local notifications = self.context.getNotifications()
        local unread = 0
        for _, notification in ipairs(notifications) do
            if not notification.read and not notification.dismissed then
                unread = unread + 1
            end
        end
        y = y - 0.055
        drawLabel("Notifications (" .. unread .. ")", x, y, 0.017)
        local shown = 0
        for _, notification in ipairs(notifications) do
            if not notification.dismissed and shown < 5 then
                shown = shown + 1
                y = y - 0.034
                drawLabel((notification.read and "" or "* ")
                    .. safeText(notification.title, notification.id), x, y, 0.014)
            end
        end
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
