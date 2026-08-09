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
        bounds = { x = 0.70, y = 0.12, width = 0.27, height = 0.76 }
    }

    function instance:initialize()
        if self.initialized then
            return Result.SUCCESS
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
            or self.context.getVisibility()
                ~= Visibility.VISIBLE then
            return
        end

        local bounds = self.bounds
        if type(drawFilledRect) == "function" then
            drawFilledRect(
                bounds.x,
                bounds.y,
                bounds.width,
                bounds.height,
                0.035,
                0.045,
                0.06,
                0.94
            )
            drawFilledRect(
                bounds.x + 0.008,
                bounds.y + 0.012,
                bounds.width - 0.016,
                bounds.height - 0.024,
                0.09,
                0.11,
                0.14,
                0.98
            )
        end

        local x = bounds.x + 0.02
        local y = bounds.y + bounds.height - 0.055
        if type(setTextColor) == "function" then
            setTextColor(1, 1, 1, 1)
        end
        drawLabel("FORGE Phone", x, y, 0.025)

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

        y = y - 0.06
        drawLabel("Surface: " .. appLabel, x, y, 0.018)
        y = y - 0.035
        drawLabel(
            "Presentation: " .. safeText(presentationId, "home"),
            x,
            y,
            0.015
        )
        y = y - 0.03
        drawLabel(
            "Route: " .. safeText(routeId, "none"),
            x,
            y,
            0.015
        )

        local notifications = self.context.getNotifications()
        local unread = 0
        for _, notification in ipairs(notifications) do
            if not notification.read and not notification.dismissed then
                unread = unread + 1
            end
        end

        if type(setTextColor) == "function" then
            setTextColor(1, 1, 1, 1)
        end

        y = y - 0.055
        drawLabel("Notifications (" .. unread .. ")", x, y, 0.018)

        local shown = 0
        for _, notification in ipairs(notifications) do
            if not notification.dismissed and shown < 4 then
                shown = shown + 1
                y = y - 0.04
                local marker = notification.read and "" or "* "
                drawLabel(
                    marker .. safeText(notification.title, notification.id)
                        .. " [" .. safeText(notification.severity, "") .. "]",
                    x,
                    y,
                    0.014
                )
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

        if action == "KEY_EVENT" and value ~= 0 then
            local keyEvent = select(1, ...)
            local f7 = Input ~= nil and Input.KEY_f7 or nil
            toggleRequested = type(keyEvent) == "table"
                and (keyEvent.sym == f7 or keyEvent.sym == 118)
        end

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

        local bounds = self.bounds
        local inside = posX >= bounds.x
            and posX <= bounds.x + bounds.width
            and posY >= bounds.y
            and posY <= bounds.y + bounds.height

        if not inside then
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
            FORGE.Definitions.LogSource.PHONE_HOST,
            "Phone Host shut down"
        )
        return Result.SUCCESS
    end

    return instance
end
