---=============================================================================
--- FORGE ForgeOS Laptop Host
---
--- Presents the bounded Laptop shell and Communications application surface.
--- Owns transient geometry, clipping, hit regions, and scroll state only.
---=============================================================================

FORGE.LaptopHost = {}

local LaptopHost = FORGE.LaptopHost
local Result = FORGE.Definitions.ForgeOSResult
local Visibility = FORGE.Definitions.DeviceVisibility
local CommunicationsAppId = "forge.communications"
local InboxKind = "communications.inbox"
local DetailKind = "communications.messageDetail"
local InboxRowsVisible = 6
local DetailLinesVisible = 13
local InboxTextWidth = 64
local PreviewTextWidth = 72
local DetailTextWidth = 88
local PrimaryButton = 1
local WheelDown = 4
local WheelUp = 5

local function safeText(value, fallback)
    return type(value) == "string" and value ~= "" and value or fallback
end

local function ellipsis(value, limit)
    value = tostring(value or "")
    if string.len(value) <= limit then return value end
    return string.sub(value, 1, limit - 3) .. "..."
end

local function visualLines(value, width)
    value = tostring(value or "")
    local lines, current = {}, ""
    for index = 1, string.len(value) do
        local character = string.sub(value, index, index)
        if character == "\n" then
            lines[#lines + 1], current = current, ""
        else
            current = current .. character
            if string.len(current) == width then
                lines[#lines + 1], current = current, ""
            end
        end
    end
    if current ~= "" or #lines == 0 then lines[#lines + 1] = current end
    return lines
end

local function previewLines(value)
    local lines = visualLines(value, PreviewTextWidth)
    if #lines <= 2 then return lines end
    return { lines[1], ellipsis(lines[2] .. "x", PreviewTextWidth) }
end

local function contains(region, x, y)
    return region ~= nil
        and x >= region.x and x <= region.x + region.width
        and y >= region.y and y <= region.y + region.height
end

function LaptopHost.create(context)
    if type(context) ~= "table" then return nil end

    local instance = {
        context = context,
        initialized = false,
        bounds = { x = 0.015, y = 0.025, width = 0.97, height = 0.95 },
        wallpaperOverlay = nil,
        hitRegions = {},
        pressedControl = nil,
        inboxScrollOffset = 0,
        detailScrollOffset = 0,
        activeAppId = nil,
        routeId = nil,
        model = nil,
        modelRouteId = nil,
        refreshElapsed = 0,
        statusText = nil
    }

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

    local function region(self, identifier, x, y, width, height, action)
        self.hitRegions[#self.hitRegions + 1] = {
            id = identifier, x = x, y = y, width = width, height = height,
            action = action
        }
    end

    local function findRegion(self, x, y)
        for _, candidate in ipairs(self.hitRegions) do
            if contains(candidate, x, y) then return candidate end
        end
        return nil
    end

    local function resetPresentation(self)
        self.inboxScrollOffset = 0
        self.detailScrollOffset = 0
        self.pressedControl = nil
        self.hitRegions = {}
        self.model = nil
        self.modelRouteId = nil
        self.refreshElapsed = 0
        self.statusText = nil
    end

    local function report(self, operation, value)
        self.statusText = "Unavailable"
        FORGE.Logger:warning(FORGE.Definitions.LogSource.LAPTOP_HOST,
            "Laptop Communications %s failed: %s", operation,
            FORGE.Logger:safeToString(value, "<unknown>"))
    end

    local function refreshModel(self, force)
        if self.activeAppId ~= CommunicationsAppId then return false end
        if not force and self.model ~= nil
            and self.modelRouteId == self.routeId then return true end
        local call = { pcall(self.context.getApplicationPresentationModel,
            CommunicationsAppId) }
        if not call[1] or call[2] == nil then
            if self.modelRouteId ~= self.routeId then
                self.model, self.modelRouteId = nil, nil
            end
            report(self, "model acquisition", call[1] and "no model" or call[2])
            return false
        end
        self.model, self.modelRouteId = call[2], self.routeId
        self.statusText = nil
        return true
    end

    local function synchronizeRoute(self)
        local appId = self.context.getActiveAppId()
        local routeId = appId ~= nil and self.context.getCurrentRoute(appId) or nil
        if self.activeAppId ~= appId then
            resetPresentation(self)
            self.activeAppId, self.routeId = appId, routeId
            if appId == CommunicationsAppId then refreshModel(self, true) end
        elseif self.routeId ~= routeId then
            if self.routeId == "inbox" then self.inboxScrollOffset = 0 end
            if self.routeId == "messageDetail" then self.detailScrollOffset = 0 end
            self.pressedControl = nil
            self.model, self.modelRouteId = nil, nil
            self.routeId = routeId
            if appId == CommunicationsAppId then refreshModel(self, true) end
        end
    end

    local function actionById(model, actionId, messageId)
        for _, action in ipairs(model.actions or {}) do
            if action.id == actionId and (messageId == nil
                or action.parameters.messageId == messageId) then
                return action
            end
        end
        return nil
    end

    local function performAction(self, action)
        if action == nil then return end
        local call = { pcall(self.context.performApplicationAction,
            CommunicationsAppId, action.id, action.parameters or {}) }
        if not call[1] or call[2] ~= Result.SUCCESS then
            report(self, "action delivery", call[2])
            return
        end
        local outcome = call[3]
        self.statusText = outcome ~= nil and not outcome.completed
            and safeText(outcome.domainResult, "Unavailable") or nil
        synchronizeRoute(self)
        refreshModel(self, true)
    end

    local function openCommunications(self)
        local sequence = {
            { "open", self.context.openApp, CommunicationsAppId },
            { "activate", self.context.activateApp, CommunicationsAppId },
            { "navigate", self.context.navigate, CommunicationsAppId,
                "inbox", {} }
        }
        for _, step in ipairs(sequence) do
            local call = { pcall(step[2], select(3, unpack(step))) }
            if not call[1] or call[2] ~= Result.SUCCESS then
                report(self, "launcher " .. step[1], call[2])
                return false
            end
        end
        synchronizeRoute(self)
        return true
    end

    local function returnToLaptopHome(self)
        local appId = self.activeAppId
        if appId == nil then return false end
        local call = { pcall(self.context.closeApp, appId) }
        if not call[1] or call[2] ~= Result.SUCCESS then
            self.statusText = "Unavailable"
            FORGE.Logger:warning(FORGE.Definitions.LogSource.LAPTOP_HOST,
                "Laptop Home close failed for %s: %s",
                FORGE.Logger:safeToString(appId, "<unknown>"),
                FORGE.Logger:safeToString(call[2], "<unknown>"))
            return false
        end
        synchronizeRoute(self)
        return true
    end

    local function registerLaptopHome(self)
        if self.activeAppId ~= nil then
            region(self, "laptopHome", self.bounds.x + 0.225,
                self.bounds.y + 0.018, 0.09, 0.038,
                { laptopHome = true })
        end
    end

    function instance:initialize()
        if self.initialized then return Result.SUCCESS end
        if type(createImageOverlay) == "function"
            and type(FORGE.ModDirectory) == "string" then
            local created, overlay = pcall(createImageOverlay,
                FORGE.ModDirectory
                    .. "scripts/forge/forgeos/assets/laptop_wallpaper.png")
            self.wallpaperOverlay = created and overlay or nil
        end
        resetPresentation(self)
        self.activeAppId, self.routeId = nil, nil
        self.initialized = true
        FORGE.Logger:info(FORGE.Definitions.LogSource.LAPTOP_HOST,
            "Laptop Host initialized")
        return Result.SUCCESS
    end

    function instance:isOperational() return self.initialized end

    function instance:containsPoint(posX, posY)
        return type(posX) == "number" and type(posY) == "number"
            and contains(self.bounds, posX, posY)
    end

    function instance:update(dt)
        if not self.initialized or type(dt) ~= "number" then return end
        synchronizeRoute(self)
        if self.activeAppId == CommunicationsAppId then
            self.refreshElapsed = self.refreshElapsed + math.max(dt, 0)
            if self.refreshElapsed >= 500 then
                self.refreshElapsed = 0
                refreshModel(self, true)
            end
        end
    end

    local function drawShell(self)
        local b = self.bounds
        if self.wallpaperOverlay ~= nil and type(renderOverlay) == "function" then
            if type(setOverlayColor) == "function" then
                setOverlayColor(self.wallpaperOverlay, 1, 1, 1, 1)
            end
            renderOverlay(self.wallpaperOverlay, b.x, b.y, b.width, b.height)
        else
            drawPanel(b.x, b.y, b.width, b.height,
                0.012, 0.018, 0.028, 0.99)
        end
        drawPanel(b.x, b.y, b.width, b.height, 0.01, 0.025, 0.04, 0.35)
        drawPanel(b.x + 0.009, b.y + b.height - 0.014,
            b.width - 0.018, 0.005, 0.95, 0.48, 0.12, 1)
        local x, y = b.x + 0.025, b.y + b.height - 0.055
        setColor(0.96, 0.97, 0.99, 1); drawLabel("FORGE", x, y, 0.026)
        setColor(1, 0.56, 0.18, 1); drawLabel("OS", x + 0.09, y, 0.026)
        setColor(0.60, 0.64, 0.70, 1)
        drawLabel("LAPTOP  /  OPERATIONS DESKTOP", x, y - 0.032, 0.011)
        drawPanel(b.x + 0.009, b.y + 0.018, b.width - 0.018,
            0.038, 0.035, 0.043, 0.055, 0.99)
        setColor(0.58, 0.62, 0.68, 1)
        drawLabel("F8 CLOSE", x, b.y + 0.031, 0.010)
        if self.activeAppId ~= nil then
            drawLabel("HOME", b.x + 0.247, b.y + 0.031, 0.010)
        end
        drawLabel("F6 POINTER MODE", b.x + b.width - 0.155,
            b.y + 0.031, 0.010)
    end

    local function drawButton(self, id, label, x, y, width, action)
        drawPanel(x, y, width, 0.038, 0.13, 0.15, 0.18, 1)
        setColor(0.94, 0.95, 0.97, 1)
        drawLabel(label, x + 0.01, y + 0.012, 0.010)
        region(self, id, x, y, width, 0.038, action)
    end

    local function drawInbox(self, model)
        local rows = model.content.rows or {}
        local maximum = math.max(0, #rows - InboxRowsVisible)
        self.inboxScrollOffset = math.min(self.inboxScrollOffset, maximum)
        local x, width = self.bounds.x + 0.025, self.bounds.width - 0.05
        if #rows == 0 then
            setColor(0.72, 0.75, 0.80, 1)
            drawLabel(safeText(model.content.emptyText, "No messages"),
                x + 0.015, self.bounds.y + 0.49, 0.014)
            return
        end
        local first = #rows - self.inboxScrollOffset
        for visible = 1, InboxRowsVisible do
            local row = rows[first - visible + 1]
            if row ~= nil then
                local y = self.bounds.y + 0.70 - (visible - 1) * 0.092
                drawPanel(x, y, width, 0.084, 0.045, 0.065, 0.085, 0.90)
                if row.unread then
                    drawPanel(x, y, 0.005, 0.084, 0.95, 0.48, 0.12, 1)
                end
                setColor(0.67, 0.71, 0.76, 1)
                drawLabel(ellipsis(row.sender, InboxTextWidth),
                    x + 0.012, y + 0.058, 0.010)
                setColor(0.96, 0.97, 0.99, 1)
                drawLabel(ellipsis(row.subject, InboxTextWidth),
                    x + 0.012, y + 0.034, 0.012)
                local preview = previewLines(row.preview)
                setColor(0.56, 0.60, 0.66, 1)
                drawLabel(preview[1] or "", x + 0.36, y + 0.052, 0.010)
                drawLabel(preview[2] or "", x + 0.36, y + 0.025, 0.010)
                local action = actionById(model,
                    "communications.openMessage", row.messageId)
                if action ~= nil then
                    region(self, "row:" .. row.messageId,
                        x, y, width, 0.084, action)
                end
            end
        end
    end

    local function drawDetail(self, model)
        local message = model.content.message
        local x = self.bounds.x + 0.025
        local back = actionById(model, "communications.back")
        local inbox = actionById(model, "communications.openInbox")
        if message == nil then
            setColor(0.94, 0.95, 0.97, 1)
            drawLabel("Message unavailable", x + 0.015,
                self.bounds.y + 0.49, 0.014)
        else
            setColor(0.66, 0.70, 0.76, 1)
            drawLabel(ellipsis(message.sender, InboxTextWidth),
                x, self.bounds.y + 0.74, 0.011)
            setColor(0.96, 0.97, 0.99, 1)
            drawLabel(ellipsis(message.subject, InboxTextWidth),
                x, self.bounds.y + 0.70, 0.015)
            local lines = visualLines(message.body, DetailTextWidth)
            local maximum = math.max(0, #lines - DetailLinesVisible)
            self.detailScrollOffset = math.min(self.detailScrollOffset, maximum)
            setColor(0.72, 0.75, 0.80, 1)
            for line = 1, DetailLinesVisible do
                local value = lines[self.detailScrollOffset + line]
                if value ~= nil then
                    drawLabel(value, x,
                        self.bounds.y + 0.675 - line * 0.034, 0.011)
                end
            end
        end
        if back ~= nil then
            drawButton(self, "back", "Back", x, self.bounds.y + 0.075,
                0.075, back)
        end
        if inbox ~= nil then
            drawButton(self, "inbox", "Inbox", x + 0.085,
                self.bounds.y + 0.075, 0.075, inbox)
        end
        if message ~= nil then
            local markRead = actionById(model, "communications.markRead",
                message.messageId)
            local archive = actionById(model, "communications.archive",
                message.messageId)
            if markRead ~= nil then
                drawButton(self, "markRead", "Read", x + 0.28,
                    self.bounds.y + 0.075, 0.085, markRead)
            end
            if archive ~= nil then
                drawButton(self, "archive", "Archive", x + 0.375,
                    self.bounds.y + 0.075, 0.09, archive)
            end
        end
    end

    local function drawCommunications(self)
        self.hitRegions = {}
        registerLaptopHome(self)
        local x = self.bounds.x + 0.025
        drawPanel(self.bounds.x + 0.02, self.bounds.y + 0.065,
            self.bounds.width - 0.04, self.bounds.height - 0.15,
            0.018, 0.03, 0.045, 0.88)
        setColor(0.96, 0.97, 0.99, 1)
        drawLabel("Communications", x, self.bounds.y + 0.81, 0.021)
        local badge = self.model ~= nil and self.model.badgeCount or 0
        if badge > 0 then
            setColor(1, 0.56, 0.18, 1)
            drawLabel(tostring(badge), self.bounds.x + 0.89,
                self.bounds.y + 0.812, 0.012)
        end
        if self.model == nil then
            setColor(0.75, 0.55, 0.40, 1)
            drawLabel("Unavailable", x, self.bounds.y + 0.49, 0.014)
        elseif self.model.content.kind == InboxKind then
            drawInbox(self, self.model)
        elseif self.model.content.kind == DetailKind then
            drawDetail(self, self.model)
        end
        if self.statusText ~= nil then
            setColor(0.90, 0.58, 0.42, 1)
            drawLabel(ellipsis(self.statusText, 45), x,
                self.bounds.y + 0.062, 0.009)
        end
    end

    local function drawHome(self)
        self.hitRegions = {}
        registerLaptopHome(self)
        local b, x = self.bounds, self.bounds.x + 0.04
        local launcherX, launcherY = x, b.y + b.height - 0.15
        setColor(0.62, 0.66, 0.72, 1)
        drawLabel("APPLICATIONS", launcherX, launcherY, 0.011)
        local shown = 0
        for _, appId in ipairs(self.context.getRegisteredAppIds()) do
            local app = self.context.getAppDefinition(appId)
            if app ~= nil and type(app.supportedDevices) == "table"
                and app.supportedDevices.laptop == true and shown < 6 then
                local column, row = shown % 2, math.floor(shown / 2)
                local width = 0.14
                local cardX = launcherX + column * (width + 0.02)
                local cardY = launcherY - 0.105 - row * 0.12
                drawPanel(cardX, cardY, width, 0.095,
                    0.035, 0.055, 0.075, 0.82)
                drawPanel(cardX, cardY + 0.09, width, 0.005,
                    column == 0 and 0.22 or 0.95,
                    column == 0 and 0.62 or 0.48,
                    column == 0 and 0.95 or 0.12, 1)
                setColor(0.96, 0.97, 0.99, 1)
                drawLabel(safeText(app.displayName, appId),
                    cardX + 0.012, cardY + 0.052, 0.013)
                if appId == CommunicationsAppId then
                    local badge = self.context.getApplicationBadge(appId)
                    if badge > 0 then
                        setColor(1, 0.56, 0.18, 1)
                        drawLabel(tostring(badge), cardX + width - 0.025,
                            cardY + 0.052, 0.010)
                    end
                    region(self, "launcher:" .. appId, cardX, cardY,
                        width, 0.095, { launcher = true })
                end
                shown = shown + 1
            end
        end

        local notifications = self.context.getNotifications()
        local notificationY = b.y + 0.43
        local notificationX = b.x + b.width - 0.30
        setColor(0.62, 0.66, 0.72, 1)
        drawLabel("NOTIFICATIONS", notificationX, notificationY, 0.011)
        local count = 0
        for _, notification in ipairs(notifications) do
            if not notification.dismissed and count < 5 then
                count, notificationY = count + 1, notificationY - 0.034
                setColor(notification.read and 0.62 or 0.96,
                    notification.read and 0.66 or 0.97,
                    notification.read and 0.72 or 0.99, 1)
                drawLabel((notification.read and "" or "* ")
                    .. safeText(notification.title, notification.id),
                    notificationX, notificationY, 0.011)
            end
        end
    end

    function instance:draw()
        if not self.initialized
            or self.context.getVisibility() ~= Visibility.VISIBLE then return end
        synchronizeRoute(self)
        drawShell(self)
        if self.activeAppId == CommunicationsAppId then
            refreshModel(self, false)
            drawCommunications(self)
        else
            drawHome(self)
        end
        setColor(1, 1, 1, 1)
    end

    function instance:resume()
        if self.context.getActiveAppId() ~= nil then return Result.SUCCESS end
        local resumeResult, destination =
            self.context.getValidatedResumeDestination()
        if resumeResult ~= Result.SUCCESS or destination == nil then
            return resumeResult
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
            FORGE.Logger:warning(FORGE.Definitions.LogSource.LAPTOP_HOST,
                "Laptop resume failed; displaying Home surface")
        end
        return Result.SUCCESS
    end

    function instance:onInput(action, value, payload)
        if not self.initialized or self.context.isUiBlocked() then return false end
        if action == "FORGE_TOGGLE_LAPTOP" and value ~= 0 then
            if self.context.getVisibility() == Visibility.VISIBLE then
                self.context.hide()
            else
                self.context.show()
            end
            return true
        end
        if self.context.getVisibility() ~= Visibility.VISIBLE then return false end
        if self.activeAppId == CommunicationsAppId then return false end
        if action == "LAPTOP_MARK_READ" and type(payload) == "string" then
            self.context.markNotificationRead(payload); return true
        end
        if action == "LAPTOP_DISMISS" and type(payload) == "string" then
            self.context.dismissNotification(payload); return true
        end
        return action == "KEY_EVENT" and value ~= 0
    end

    function instance:onPointer(posX, posY, isDown, isUp, button)
        if not self.initialized or self.context.isUiBlocked()
            or self.context.getVisibility() ~= Visibility.VISIBLE then
            self.pressedControl = nil; return false
        end
        local inside = self:containsPoint(posX, posY)
        if self.activeAppId == CommunicationsAppId then
            if not inside then
                if isUp then self.pressedControl = nil end
                return false
            end
            if (button == WheelDown or button == WheelUp) and isDown then
                local direction = button == WheelDown and 1 or -1
                if self.routeId == "inbox" and self.model ~= nil then
                    local maximum = math.max(0,
                        #(self.model.content.rows or {}) - InboxRowsVisible)
                    self.inboxScrollOffset = math.max(0, math.min(maximum,
                        self.inboxScrollOffset + direction))
                elseif self.routeId == "messageDetail" and self.model ~= nil
                    and self.model.content.message ~= nil then
                    local maximum = math.max(0, #visualLines(
                        self.model.content.message.body, DetailTextWidth)
                        - DetailLinesVisible)
                    self.detailScrollOffset = math.max(0, math.min(maximum,
                        self.detailScrollOffset + direction))
                end
                return true
            end
            if button ~= PrimaryButton then return false end
            local target = findRegion(self, posX, posY)
            if isDown then
                self.pressedControl = target ~= nil and target.id or nil
                return target ~= nil
            end
            if isUp then
                local pressed = self.pressedControl
                self.pressedControl = nil
                if target ~= nil and target.id == pressed then
                    if target.action.laptopHome then
                        return returnToLaptopHome(self)
                    end
                    performAction(self, target.action)
                    return true
                end
                return pressed ~= nil
            end
            return target ~= nil
        end

        local target = inside and findRegion(self, posX, posY) or nil
        if button == PrimaryButton and isDown and target ~= nil then
            self.pressedControl = target.id; return true
        end
        if button == PrimaryButton and isUp then
            local pressed = self.pressedControl
            self.pressedControl = nil
            if target ~= nil and target.id == pressed then
                if target.action.laptopHome then
                    return returnToLaptopHome(self)
                end
                if target.action.launcher then return openCommunications(self) end
            end
            return pressed ~= nil
        end
        if inside and isDown then
            local notifications = self.context.getNotifications()
            if button == PrimaryButton then
                for _, notification in ipairs(notifications) do
                    if not notification.read and not notification.dismissed then
                        self.context.markNotificationRead(notification.id); break
                    end
                end
            elseif button == 2 or button == 3 then
                for _, notification in ipairs(notifications) do
                    if not notification.dismissed then
                        self.context.dismissNotification(notification.id); break
                    end
                end
            end
        end
        return inside
    end

    function instance:shutdown()
        if self.wallpaperOverlay ~= nil and type(delete) == "function" then
            pcall(delete, self.wallpaperOverlay)
        end
        self.wallpaperOverlay = nil
        resetPresentation(self)
        self.activeAppId, self.routeId = nil, nil
        self.initialized = false
        FORGE.Logger:info(FORGE.Definitions.LogSource.LAPTOP_HOST,
            "Laptop Host shut down")
        return Result.SUCCESS
    end

    return instance
end
