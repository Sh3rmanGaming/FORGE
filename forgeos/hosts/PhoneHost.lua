---=============================================================================
--- FORGE ForgeOS Phone Host
---
--- Presents the bounded Phone shell and the built-in Communications surface.
--- Owns transient geometry, clipping, hit regions, and scroll state only.
---=============================================================================

FORGE.PhoneHost = {}

local PhoneHost = FORGE.PhoneHost
local Result = FORGE.Definitions.ForgeOSResult
local Visibility = FORGE.Definitions.DeviceVisibility
local CommunicationsAppId = "forge.communications"
local InboxKind = "communications.inbox"
local DetailKind = "communications.messageDetail"
local InboxRowsVisible = 4
local DetailLinesVisible = 9
local InboxTextWidth = 31
local PreviewTextWidth = 34
local DetailTextWidth = 38
local PrimaryButton = 1
local WheelDown = 4
local WheelUp = 5

local function safeText(value, fallback)
    if type(value) == "string" and value ~= "" then
        return value
    end
    return fallback
end

local function ellipsis(value, limit)
    value = tostring(value or "")
    if string.len(value) <= limit then
        return value
    end
    if limit <= 3 then
        return string.sub("...", 1, limit)
    end
    return string.sub(value, 1, limit - 3) .. "..."
end

local function visualLines(value, width)
    value = tostring(value or "")
    local lines = {}
    local current = ""
    for index = 1, string.len(value) do
        local character = string.sub(value, index, index)
        if character == "\n" then
            lines[#lines + 1] = current
            current = ""
        else
            current = current .. character
            if string.len(current) == width then
                lines[#lines + 1] = current
                current = ""
            end
        end
    end
    if current ~= "" or #lines == 0 then
        lines[#lines + 1] = current
    end
    return lines
end

local function previewLines(value)
    local lines = visualLines(value, PreviewTextWidth)
    if #lines <= 2 then
        return lines
    end
    return { lines[1], ellipsis(lines[2] .. "x", PreviewTextWidth) }
end

local function contains(region, x, y)
    return region ~= nil
        and x >= region.x and x <= region.x + region.width
        and y >= region.y and y <= region.y + region.height
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
        bounds = { x = 0.70, y = 0.12, width = 0.27, height = 0.76 },
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
            id = identifier,
            x = x,
            y = y,
            width = width,
            height = height,
            action = action
        }
    end

    local function findRegion(self, x, y)
        for _, candidate in ipairs(self.hitRegions) do
            if contains(candidate, x, y) then
                return candidate
            end
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
        self.statusText = nil
        self.refreshElapsed = 0
    end

    local function report(self, operation, value)
        self.statusText = "Unavailable"
        FORGE.Logger:warning(
            FORGE.Definitions.LogSource.PHONE_HOST,
            "Phone Communications %s failed: %s",
            operation,
            FORGE.Logger:safeToString(value, "<unknown>"))
    end

    local function refreshModel(self, force)
        if self.activeAppId ~= CommunicationsAppId then
            return false
        end
        if not force and self.model ~= nil
            and self.modelRouteId == self.routeId then
            return true
        end
        local call = {
            pcall(
                self.context.getApplicationPresentationModel,
                CommunicationsAppId)
        }
        if not call[1] or call[2] == nil then
            if self.modelRouteId ~= self.routeId then
                self.model = nil
                self.modelRouteId = nil
            end
            report(self, "model acquisition", call[1] and "no model" or call[2])
            return false
        end
        self.model = call[2]
        self.modelRouteId = self.routeId
        self.statusText = nil
        return true
    end

    local function synchronizeRoute(self)
        local activeAppId = self.context.getActiveAppId()
        local routeId = activeAppId ~= nil
            and self.context.getCurrentRoute(activeAppId) or nil
        if self.activeAppId ~= activeAppId then
            resetPresentation(self)
            self.activeAppId = activeAppId
            self.routeId = routeId
            if activeAppId == CommunicationsAppId then
                refreshModel(self, true)
            end
            return
        end
        if self.routeId ~= routeId then
            if self.routeId == "inbox" then
                self.inboxScrollOffset = 0
            elseif self.routeId == "messageDetail" then
                self.detailScrollOffset = 0
            end
            self.pressedControl = nil
            self.model = nil
            self.modelRouteId = nil
            self.routeId = routeId
            if activeAppId == CommunicationsAppId then
                refreshModel(self, true)
            end
        end
    end

    local function performAction(self, action)
        if action == nil then
            return
        end
        local call = {
            pcall(
                self.context.performApplicationAction,
                CommunicationsAppId,
                action.id,
                action.parameters or {})
        }
        if not call[1] or call[2] ~= Result.SUCCESS then
            report(self, "action delivery", call[1] and call[2] or call[2])
            return
        end
        local outcome = call[3]
        self.statusText = outcome ~= nil and not outcome.completed
            and safeText(outcome.domainResult, "Unavailable") or nil
        synchronizeRoute(self)
        refreshModel(self, true)
    end

    local function actionById(model, actionId, messageId)
        for _, action in ipairs(model.actions or {}) do
            if action.id == actionId
                and (messageId == nil
                    or action.parameters.messageId == messageId) then
                return action
            end
        end
        return nil
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
                report(self, "launcher " .. step[1],
                    call[1] and call[2] or call[2])
                return
            end
        end
        synchronizeRoute(self)
    end

    local function returnToPhoneHome(self)
        local appId = self.activeAppId
        if appId == nil then
            return false
        end
        local call = { pcall(self.context.closeApp, appId) }
        if not call[1] or call[2] ~= Result.SUCCESS then
            self.statusText = "Unavailable"
            FORGE.Logger:warning(FORGE.Definitions.LogSource.PHONE_HOST,
                "Phone Home close failed for %s: %s",
                FORGE.Logger:safeToString(appId, "<unknown>"),
                FORGE.Logger:safeToString(
                    call[1] and call[2] or call[2], "<unknown>"))
            return false
        end
        synchronizeRoute(self)
        return true
    end

    local function registerPhoneHome(self)
        if self.activeAppId ~= nil then
            region(self, "phoneHome", self.bounds.x + 0.09,
                self.bounds.y + 0.012, 0.09, 0.035,
                { phoneHome = true })
        end
    end

    function instance:initialize()
        if self.initialized then
            return Result.SUCCESS
        end
        if type(createImageOverlay) == "function"
            and type(FORGE.ModDirectory) == "string" then
            local frameCreated, frame = pcall(createImageOverlay,
                FORGE.ModDirectory .. "scripts/forge/forgeos/assets/phone_frame.dds")
            local cardCreated, card = pcall(createImageOverlay,
                FORGE.ModDirectory .. "scripts/forge/forgeos/assets/app_card.dds")
            self.frameOverlay = frameCreated and frame or nil
            self.appCardOverlay = cardCreated and card or nil
        end
        resetPresentation(self)
        self.activeAppId = nil
        self.routeId = nil
        self.initialized = true
        FORGE.Logger:info(FORGE.Definitions.LogSource.PHONE_HOST,
            "Phone Host initialized")
        return Result.SUCCESS
    end

    function instance:isOperational()
        return self.initialized
    end

    function instance:containsPoint(posX, posY)
        return type(posX) == "number" and type(posY) == "number"
            and contains(self.bounds, posX, posY)
    end

    function instance:update(dt)
        if not self.initialized or type(dt) ~= "number" then
            return
        end
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
        local bounds = self.bounds
        if self.frameOverlay ~= nil and type(renderOverlay) == "function" then
            if type(setOverlayColor) == "function" then
                setOverlayColor(self.frameOverlay, 1, 1, 1, 1)
            end
            renderOverlay(self.frameOverlay, bounds.x - 0.014,
                bounds.y - 0.014, bounds.width + 0.028, bounds.height + 0.028)
        else
            drawPanel(bounds.x, bounds.y, bounds.width, bounds.height,
                0.01, 0.014, 0.019, 0.97)
            drawPanel(bounds.x + 0.004, bounds.y + 0.012,
                bounds.width - 0.008, bounds.height - 0.024,
                0.045, 0.055, 0.068, 0.98)
        end
        drawPanel(bounds.x + 0.012, bounds.y + bounds.height - 0.072,
            bounds.width - 0.024, 0.004, 0.95, 0.48, 0.12, 1)
        local x = bounds.x + 0.022
        local y = bounds.y + bounds.height - 0.112
        setColor(0.96, 0.97, 0.99, 1)
        drawLabel("FORGE", x, y, 0.026)
        setColor(1, 0.56, 0.18, 1)
        drawLabel("OS", x + 0.088, y, 0.026)
        setColor(0.60, 0.64, 0.70, 1)
        drawLabel("OPERATIONS HUB", x, y - 0.03, 0.011)
    end

    local function drawInbox(self, model)
        local content = model.content
        local rows = content.rows or {}
        local maxOffset = math.max(0, #rows - InboxRowsVisible)
        self.inboxScrollOffset = math.min(self.inboxScrollOffset, maxOffset)
        local first = #rows - self.inboxScrollOffset
        local x = self.bounds.x + 0.022
        local width = self.bounds.width - 0.044
        if #rows == 0 then
            setColor(0.72, 0.75, 0.80, 1)
            drawLabel(safeText(content.emptyText, "No messages"),
                x + 0.012, self.bounds.y + 0.46, 0.014)
            return
        end
        for visible = 1, InboxRowsVisible do
            local index = first - visible + 1
            local row = rows[index]
            if row ~= nil then
                local y = self.bounds.y + 0.44 - (visible - 1) * 0.102
                drawPanel(x, y, width, 0.101, 0.085, 0.10, 0.12, 0.98)
                if row.unread then
                    drawPanel(x, y, 0.005, 0.101, 0.95, 0.48, 0.12, 1)
                end
                setColor(0.67, 0.71, 0.76, 1)
                drawLabel(ellipsis(row.sender, InboxTextWidth),
                    x + 0.011, y + 0.074, 0.010)
                setColor(0.96, 0.97, 0.99, 1)
                drawLabel(ellipsis(row.subject, InboxTextWidth),
                    x + 0.011, y + 0.050, 0.012)
                local preview = previewLines(row.preview)
                setColor(0.56, 0.60, 0.66, 1)
                drawLabel(preview[1] or "", x + 0.011, y + 0.028, 0.009)
                drawLabel(preview[2] or "", x + 0.011, y + 0.011, 0.009)
                local action = actionById(model,
                    "communications.openMessage", row.messageId)
                if action ~= nil then
                    region(self, "row:" .. row.messageId,
                        x, y, width, 0.101, action)
                end
            end
        end
    end

    local function drawButton(self, identifier, label, x, y, width, action)
        drawPanel(x, y, width, 0.039, 0.13, 0.15, 0.18, 1)
        setColor(0.94, 0.95, 0.97, 1)
        drawLabel(label, x + 0.008, y + 0.013, 0.010)
        region(self, identifier, x, y, width, 0.039, action)
    end

    local function drawDetail(self, model)
        local message = model.content.message
        local x = self.bounds.x + 0.022
        local width = self.bounds.width - 0.044
        local back = actionById(model, "communications.back")
        local inbox = actionById(model, "communications.openInbox")
        if message == nil then
            setColor(0.94, 0.95, 0.97, 1)
            drawLabel("Message unavailable", x + 0.012,
                self.bounds.y + 0.46, 0.014)
        else
            setColor(0.66, 0.70, 0.76, 1)
            drawLabel(ellipsis(message.sender, InboxTextWidth),
                x, self.bounds.y + 0.525, 0.011)
            setColor(0.96, 0.97, 0.99, 1)
            drawLabel(ellipsis(message.subject, InboxTextWidth),
                x, self.bounds.y + 0.49, 0.015)
            local lines = visualLines(message.body, DetailTextWidth)
            local maximum = math.max(0, #lines - DetailLinesVisible)
            self.detailScrollOffset = math.min(self.detailScrollOffset, maximum)
            setColor(0.72, 0.75, 0.80, 1)
            for line = 1, DetailLinesVisible do
                local value = lines[self.detailScrollOffset + line]
                if value ~= nil then
                    drawLabel(value, x, self.bounds.y + 0.445 - line * 0.027, 0.010)
                end
            end
        end
        if back ~= nil then
            drawButton(self, "back", "Back", x, self.bounds.y + 0.145,
                0.066, back)
        end
        if inbox ~= nil then
            drawButton(self, "inbox", "Inbox", x + 0.072,
                self.bounds.y + 0.145, 0.066, inbox)
        end
        if message ~= nil then
            local markRead = actionById(model, "communications.markRead",
                message.messageId)
            local archive = actionById(model, "communications.archive",
                message.messageId)
            if markRead ~= nil then
                drawButton(self, "markRead", "Read", x,
                    self.bounds.y + 0.195, 0.094, markRead)
            end
            if archive ~= nil then
                drawButton(self, "archive", "Archive", x + 0.104,
                    self.bounds.y + 0.195, 0.094, archive)
            end
        end
    end

    local function drawCommunications(self)
        self.hitRegions = {}
        local x = self.bounds.x + 0.022
        registerPhoneHome(self)
        setColor(0.96, 0.97, 0.99, 1)
        drawLabel("Communications", x, self.bounds.y + 0.575, 0.019)
        local badge = self.model ~= nil and self.model.badgeCount or 0
        if badge > 0 then
            setColor(1, 0.56, 0.18, 1)
            drawLabel(tostring(badge), self.bounds.x + 0.232,
                self.bounds.y + 0.577, 0.012)
        end
        if self.model == nil then
            setColor(0.75, 0.55, 0.40, 1)
            drawLabel("Unavailable", x, self.bounds.y + 0.48, 0.014)
        elseif self.model.content.kind == InboxKind then
            drawInbox(self, self.model)
        elseif self.model.content.kind == DetailKind then
            drawDetail(self, self.model)
        end
        if self.statusText ~= nil then
            setColor(0.90, 0.58, 0.42, 1)
            drawLabel(ellipsis(self.statusText, 28),
                x, self.bounds.y + 0.105, 0.009)
        end
        setColor(0.52, 0.56, 0.62, 1)
        drawLabel("F7 CLOSE  |  F6 POINTER", x,
            self.bounds.y + 0.035, 0.010)
    end

    local function drawHome(self)
        self.hitRegions = {}
        registerPhoneHome(self)
        local bounds = self.bounds
        local x = bounds.x + 0.022
        local surfaceY = bounds.y + bounds.height - 0.235
        drawPanel(x, surfaceY, bounds.width - 0.044, 0.09,
            0.09, 0.105, 0.125, 0.98)
        drawPanel(x, surfaceY + 0.086, bounds.width - 0.044, 0.004,
            0.95, 0.48, 0.12, 1)
        setColor(0.63, 0.67, 0.72, 1)
        drawLabel("ACTIVE SURFACE", x + 0.012, surfaceY + 0.061, 0.011)
        local appLabel = "Home"
        local presentationLabel = "home  /  none"
        if self.activeAppId ~= nil then
            local app = self.context.getAppDefinition(self.activeAppId)
            appLabel = safeText(app ~= nil and app.displayName or nil,
                self.activeAppId)
            local _, resolution =
                self.context.resolvePresentation(self.activeAppId)
            presentationLabel = safeText(
                resolution ~= nil and resolution.presentationId or nil,
                "home") .. "  /  " .. safeText(self.routeId, "none")
        end
        setColor(0.96, 0.97, 0.99, 1)
        drawLabel(appLabel, x + 0.012, surfaceY + 0.035, 0.017)
        setColor(0.60, 0.64, 0.70, 1)
        drawLabel(presentationLabel, x + 0.012, surfaceY + 0.014, 0.010)
        local launcherY = surfaceY - 0.03
        setColor(0.63, 0.67, 0.72, 1)
        drawLabel("APPLICATIONS", x, launcherY, 0.011)
        local cardY = launcherY - 0.072
        local cardWidth = (bounds.width - 0.054) / 2
        local shownApps = 0
        for _, appId in ipairs(self.context.getRegisteredAppIds()) do
            local app = self.context.getAppDefinition(appId)
            if app ~= nil and app.supportedDevices.phone == true
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
                    renderOverlay(self.appCardOverlay, cardX, currentY,
                        cardWidth, 0.064)
                else
                    drawPanel(cardX, currentY, cardWidth, 0.064,
                        0.105, 0.12, 0.145, 0.98)
                end
                setColor(0.95, 0.96, 0.98, 1)
                drawLabel(safeText(app.displayName, appId),
                    cardX + 0.009, currentY + 0.035, 0.012)
                if appId == CommunicationsAppId then
                    local badge = self.context.getApplicationBadge(appId)
                    if badge > 0 then
                        setColor(1, 0.56, 0.18, 1)
                        drawLabel(tostring(badge), cardX + cardWidth - 0.026,
                            currentY + 0.035, 0.010)
                    end
                    region(self, "launcher:" .. appId, cardX, currentY,
                        cardWidth, 0.064, { launcher = true })
                end
                shownApps = shownApps + 1
            end
        end
        local notifications = self.context.getNotifications()
        local notificationY = bounds.y + 0.205
        setColor(0.63, 0.67, 0.72, 1)
        drawLabel("NOTIFICATIONS", x, notificationY, 0.011)
        local shown = 0
        for _, notification in ipairs(notifications) do
            if not notification.dismissed and shown < 4 then
                shown = shown + 1
                notificationY = notificationY - 0.036
                setColor(notification.read and 0.62 or 0.96,
                    notification.read and 0.66 or 0.97,
                    notification.read and 0.72 or 0.99, 1)
                drawLabel((notification.read and "" or "* ")
                    .. safeText(notification.title, notification.id),
                    x, notificationY, 0.011)
            end
        end
        setColor(0.52, 0.56, 0.62, 1)
        drawLabel("F7 CLOSE  |  F6 POINTER", x,
            bounds.y + 0.035, 0.010)
    end

    function instance:draw()
        if not self.initialized
            or self.context.getVisibility() ~= Visibility.VISIBLE then
            return
        end
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
        if self.context.getActiveAppId() ~= nil then
            return Result.SUCCESS
        end
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
            FORGE.Logger:warning(FORGE.Definitions.LogSource.PHONE_HOST,
                "Phone resume failed; displaying Home surface")
        end
        return Result.SUCCESS
    end

    function instance:onInput(action, value, ...)
        if not self.initialized or self.context.isUiBlocked() then
            return false
        end
        if action == "FORGE_TOGGLE_PHONE" and value ~= 0 then
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
        if action == "PHONE_MARK_READ" and type(payload) == "string" then
            self.context.markNotificationRead(payload)
            return true
        end
        if action == "PHONE_DISMISS" and type(payload) == "string" then
            self.context.dismissNotification(payload)
            return true
        end
        return false
    end

    function instance:onPointer(posX, posY, isDown, isUp, button)
        if not self.initialized or self.context.isUiBlocked()
            or self.context.getVisibility() ~= Visibility.VISIBLE then
            self.pressedControl = nil
            return false
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
                    local lines = visualLines(
                        self.model.content.message.body, DetailTextWidth)
                    local maximum = math.max(0, #lines - DetailLinesVisible)
                    self.detailScrollOffset = math.max(0, math.min(maximum,
                        self.detailScrollOffset + direction))
                end
                return true
            end
            if button ~= PrimaryButton then
                return false
            end
            local target = findRegion(self, posX, posY)
            if isDown then
                self.pressedControl = target ~= nil and target.id or nil
                return target ~= nil
            end
            if isUp then
                local pressed = self.pressedControl
                self.pressedControl = nil
                if target ~= nil and target.id == pressed then
                    if target.action.phoneHome then
                        return returnToPhoneHome(self)
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
            self.pressedControl = target.id
            return true
        end
        if button == PrimaryButton and isUp then
            local pressed = self.pressedControl
            self.pressedControl = nil
            if target ~= nil and target.id == pressed then
                if target.action.phoneHome then
                    return returnToPhoneHome(self)
                end
                if target.action.launcher then
                    openCommunications(self)
                    return true
                end
            end
            return pressed ~= nil
        end
        if inside and isDown then
            local notifications = self.context.getNotifications()
            if button == PrimaryButton then
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
        return inside
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
        resetPresentation(self)
        self.activeAppId = nil
        self.routeId = nil
        self.initialized = false
        FORGE.Logger:info(FORGE.Definitions.LogSource.PHONE_HOST,
            "Phone Host shut down")
        return Result.SUCCESS
    end

    return instance
end
