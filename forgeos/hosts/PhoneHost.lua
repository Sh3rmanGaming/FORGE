---=============================================================================
--- FORGE ForgeOS Phone Host
---
--- Presents the bounded PF.004 Phone companion shell and application surface.
--- Owns transient geometry, clipping, hit regions, and scroll state only.
---=============================================================================

FORGE.PhoneHost = {}

local PhoneHost = FORGE.PhoneHost
local Result = FORGE.Definitions.ForgeOSResult
local Visibility = FORGE.Definitions.DeviceVisibility
local Token = FORGE.Definitions.PresentationToken
-- Grandfathered model-v1 compatibility only. PF.008 owns removal.
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

local Theme = {
    [Token.SURFACE_BACKGROUND] = { 0.012, 0.018, 0.028, 0.99 },
    [Token.SURFACE_PRIMARY] = { 0.035, 0.043, 0.055, 0.98 },
    [Token.SURFACE_SECONDARY] = { 0.050, 0.060, 0.073, 0.94 },
    [Token.SURFACE_ELEVATED] = { 0.070, 0.080, 0.094, 0.96 },
    [Token.SURFACE_SELECTED] = { 0.115, 0.095, 0.060, 0.96 },
    [Token.SURFACE_DISABLED] = { 0.038, 0.043, 0.050, 0.82 },
    [Token.TEXT_PRIMARY] = { 0.94, 0.95, 0.97, 1 },
    [Token.TEXT_SECONDARY] = { 0.70, 0.73, 0.77, 1 },
    [Token.TEXT_MUTED] = { 0.50, 0.54, 0.59, 1 },
    [Token.TEXT_DISABLED] = { 0.38, 0.41, 0.45, 1 },
    [Token.ACCENT_PRIMARY] = { 0.95, 0.48, 0.12, 1 },
    [Token.BORDER_SUBTLE] = { 0.20, 0.23, 0.27, 0.72 },
    [Token.BORDER_ACTIVE] = { 0.95, 0.48, 0.12, 1 },
    [Token.BORDER_FOCUS] = { 0.92, 0.72, 0.42, 1 }
}

local function color(token)
    return Theme[token] or Theme[Token.TEXT_PRIMARY]
end

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
        bounds = { x = 0.70, y = 0.12, width = 0.27, height = 0.76 },
        applicationViewport = nil,
        shortcutViewport = nil,
        bannerSafeRegion = nil,
        hitRegions = {},
        pressedControl = nil,
        hoveredControl = nil,
        focusedControl = nil,
        disabledControl = nil,
        shortcutPage = 1,
        shortcutPageCount = 1,
        shortcutPageSize = 6,
        projectedShortcuts = {},
        inboxScrollOffset = 0,
        detailScrollOffset = 0,
        activeAppId = nil,
        routeId = nil,
        model = nil,
        modelRouteId = nil,
        refreshElapsed = 0,
        statusText = nil,
        declarative = nil
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

    local function drawTokenPanel(token, x, y, width, height, alpha)
        local value = color(token)
        drawPanel(x, y, width, height, value[1], value[2], value[3],
            alpha or value[4])
    end

    local function setTokenColor(token)
        local value = color(token)
        setColor(value[1], value[2], value[3], value[4])
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
        for index = #self.hitRegions, 1, -1 do
            local candidate = self.hitRegions[index]
            if contains(candidate, x, y) then
                return candidate
            end
        end
        return nil
    end

    local function rebuildGeometry(self)
        local width, height, scale = 1920, 1080, 1
        if type(self.context.getViewportMetrics) == "function" then
            local metrics = self.context.getViewportMetrics()
            if type(metrics) == "table" then
                width = type(metrics.width) == "number" and metrics.width or width
                height = type(metrics.height) == "number" and metrics.height or height
                scale = type(metrics.uiScale) == "number" and metrics.uiScale or scale
            end
        end
        local aspect = height > 0 and width / height or 16 / 9
        local compact = aspect < 1.48 or scale > 1.15
        self.density = compact and 0.76 or 0.82
        self.geometryProfile = compact and "compact" or "standard"
        self.shortcutPageSize = compact and 4 or 6
        local b = self.bounds
        self.bannerSafeRegion = {
            x = b.x + 0.020, y = b.y + b.height - 0.155,
            width = b.width - 0.040, height = 0.055
        }
        self.applicationViewport = {
            x = b.x + 0.020, y = b.y + 0.065,
            width = b.width - 0.040, height = b.height - 0.220
        }
        self.shortcutViewport = {
            x = b.x + 0.024, y = b.y + 0.110,
            width = b.width - 0.048, height = b.height - 0.310
        }
    end

    local function resetPresentation(self)
        self.inboxScrollOffset = 0
        self.detailScrollOffset = 0
        self.pressedControl = nil
        self.hoveredControl = nil
        self.hitRegions = {}
        self.model = nil
        self.modelRouteId = nil
        self.statusText = nil
        self.refreshElapsed = 0
        if self.declarative ~= nil then self.declarative:reset() end
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

    local function openShortcut(self, appId)
        local resolved = { pcall(self.context.resolvePresentation, appId) }
        if not resolved[1] or resolved[2] ~= Result.SUCCESS
            or type(resolved[3]) ~= "table"
            or type(resolved[3].presentation) ~= "table"
            or type(resolved[3].presentation.defaultRoute) ~= "string" then
            self.disabledControl = "launcher:" .. tostring(appId)
            report(self, "launcher resolution", resolved[2])
            return false
        end
        local defaultRoute = resolved[3].presentation.defaultRoute
        local sequence = {
            { "open", self.context.openApp, appId },
            { "activate", self.context.activateApp, appId },
            { "navigate", self.context.navigate, appId, defaultRoute, {} }
        }
        for _, step in ipairs(sequence) do
            local call = { pcall(step[2], select(3, unpack(step))) }
            if not call[1] or call[2] ~= Result.SUCCESS then
                report(self, "launcher " .. step[1],
                    call[1] and call[2] or call[2])
                if step[1] ~= "open" then pcall(self.context.closeApp, appId) end
                self.disabledControl = "launcher:" .. tostring(appId)
                return false
            end
        end
        synchronizeRoute(self)
        self.disabledControl = nil
        return true
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
            self.frameOverlay = frameCreated and frame or nil
        end
        resetPresentation(self)
        rebuildGeometry(self)
        self.declarative = FORGE.PresentationHostAdapter.create(
            self.context, self.applicationViewport, self.density,
            FORGE.Definitions.LogSource.PHONE_HOST)
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
        elseif self.activeAppId ~= nil then
            self.refreshElapsed = self.refreshElapsed + math.max(dt, 0)
            if self.refreshElapsed >= 500 then
                self.refreshElapsed = 0
                self.declarative:refresh(self.activeAppId)
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
            drawTokenPanel(Token.SURFACE_BACKGROUND,
                bounds.x, bounds.y, bounds.width, bounds.height)
            drawTokenPanel(Token.SURFACE_PRIMARY,
                bounds.x + 0.004, bounds.y + 0.012,
                bounds.width - 0.008, bounds.height - 0.024)
        end
        drawTokenPanel(Token.BORDER_ACTIVE,
            bounds.x + 0.012, bounds.y + bounds.height - 0.072,
            bounds.width - 0.024, 0.004)
        local x = bounds.x + 0.022
        local y = bounds.y + bounds.height - 0.112
        setTokenColor(Token.TEXT_PRIMARY)
        drawLabel("FORGE", x, y, 0.026)
        setTokenColor(Token.ACCENT_PRIMARY)
        drawLabel("OS", x + 0.088, y, 0.026)
        setTokenColor(Token.TEXT_MUTED)
        drawLabel("COMPANION", x, y - 0.03, 0.010)
        drawLabel("F7 CLOSE", x, bounds.y + 0.027, 0.009)
        if self.activeAppId ~= nil then
            drawLabel("HOME", bounds.x + 0.105, bounds.y + 0.027, 0.009)
        end
        drawLabel("F6 POINTER", bounds.x + bounds.width - 0.085,
            bounds.y + 0.027, 0.009)
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
    end

    local function drawHome(self)
        self.hitRegions = {}
        local viewport = self.shortcutViewport
        setTokenColor(Token.TEXT_MUTED)
        drawLabel("APPLICATIONS", viewport.x,
            viewport.y + viewport.height, 0.009)
        local projected = {}
        for _, appId in ipairs(self.context.getRegisteredAppIds()) do
            local app = self.context.getAppDefinition(appId)
            local resolved = { pcall(self.context.resolvePresentation, appId) }
            if app ~= nil and app.supportedDevices ~= nil
                and app.supportedDevices.phone == true
                and resolved[1] and resolved[2] == Result.SUCCESS
                and type(resolved[3]) == "table" then
                projected[#projected + 1] = { appId = appId,
                    displayName = safeText(app.displayName, appId),
                    iconId = app.iconId, iconResolved = false }
            end
        end
        self.projectedShortcuts = projected
        self.shortcutPageCount = math.max(1,
            math.ceil(#projected / self.shortcutPageSize))
        self.shortcutPage = math.max(1,
            math.min(self.shortcutPage, self.shortcutPageCount))
        if #projected == 0 then
            setTokenColor(Token.TEXT_SECONDARY)
            drawLabel("No Phone applications available", viewport.x,
                viewport.y + viewport.height - 0.06, 0.010)
            return
        end
        local columns = 2
        local rows = math.ceil(self.shortcutPageSize / columns)
        local gap = 0.010
        local cellWidth = (viewport.width - gap) / columns
        local cellHeight = math.min(0.095,
            (viewport.height - 0.045) / rows)
        local first = (self.shortcutPage - 1) * self.shortcutPageSize + 1
        local last = math.min(#projected, first + self.shortcutPageSize - 1)
        for index = first, last do
            local shortcut = projected[index]
            local visible = index - first
            local column, row = visible % columns, math.floor(visible / columns)
            local x = viewport.x + column * (cellWidth + gap)
            local y = viewport.y + viewport.height - 0.035
                - (row + 1) * cellHeight
            local id = "launcher:" .. shortcut.appId
            local pressed = self.pressedControl == id
            local hovered = self.hoveredControl == id
            local focused = self.focusedControl == id
            local disabled = self.disabledControl == id
            if pressed or hovered or focused or disabled then
                drawTokenPanel(disabled and Token.SURFACE_DISABLED
                    or pressed and Token.SURFACE_SELECTED
                    or Token.SURFACE_ELEVATED,
                    x, y, cellWidth, cellHeight - 0.008)
                drawTokenPanel((hovered or focused) and Token.BORDER_FOCUS
                    or Token.BORDER_ACTIVE,
                    x, y, 0.0025, cellHeight - 0.008)
            end
            -- Controlled generic fallback; no domain artwork inference.
            drawTokenPanel(Token.BORDER_SUBTLE,
                x + 0.008, y + cellHeight - 0.044, 0.026, 0.026)
            drawTokenPanel(Token.ACCENT_PRIMARY,
                x + 0.014, y + cellHeight - 0.038, 0.014, 0.014)
            setTokenColor(disabled and Token.TEXT_DISABLED
                or Token.TEXT_PRIMARY)
            drawLabel(ellipsis(shortcut.displayName, 14), x + 0.008,
                y + 0.012, 0.009)
            region(self, id, x, y, cellWidth, cellHeight - 0.008,
                { launcher = true, appId = shortcut.appId })
        end
        if self.shortcutPageCount > 1 then
            setTokenColor(Token.TEXT_SECONDARY)
            drawLabel(tostring(self.shortcutPage) .. " / "
                .. tostring(self.shortcutPageCount), viewport.x,
                viewport.y + 0.010, 0.008)
            region(self, "pagePrevious", viewport.x + 0.065,
                viewport.y, 0.035, 0.030, { page = -1 })
            region(self, "pageNext", viewport.x + 0.110,
                viewport.y, 0.035, 0.030, { page = 1 })
            drawLabel("<", viewport.x + 0.078, viewport.y + 0.009, 0.009)
            drawLabel(">", viewport.x + 0.123, viewport.y + 0.009, 0.009)
        end
        if self.statusText ~= nil then
            setTokenColor(Token.TEXT_SECONDARY)
            drawLabel(ellipsis(self.statusText, 28), viewport.x,
                viewport.y - 0.025, 0.008)
        end
    end

    function instance:draw()
        if not self.initialized
            or self.context.getVisibility() ~= Visibility.VISIBLE then
            return
        end
        synchronizeRoute(self)
        drawShell(self)
        if self.activeAppId == CommunicationsAppId then
            self.hitRegions = {}
            refreshModel(self, false)
            drawCommunications(self)
        elseif self.activeAppId ~= nil then
            self.hitRegions = {}
            drawTokenPanel(Token.SURFACE_PRIMARY,
                self.applicationViewport.x, self.applicationViewport.y,
                self.applicationViewport.width,
                self.applicationViewport.height)
            self.declarative:refresh(self.activeAppId)
            if not self.declarative:draw() then
                setTokenColor(Token.TEXT_SECONDARY)
                drawLabel("Application unavailable",
                    self.applicationViewport.x + 0.012,
                    self.applicationViewport.y
                        + self.applicationViewport.height * 0.5, 0.011)
            end
            registerPhoneHome(self)
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
        return false
    end

    function instance:onPointer(posX, posY, isDown, isUp, button)
        if not self.initialized or self.context.isUiBlocked()
            or self.context.getVisibility() ~= Visibility.VISIBLE then
            self.pressedControl = nil
            return false
        end
        local inside = self:containsPoint(posX, posY)
        if self.activeAppId ~= nil and self.activeAppId ~= CommunicationsAppId
            and inside and self.declarative.session.plan ~= nil then
            if self.declarative:pointer(posX, posY, isDown, isUp, button) then
                return true
            end
        end
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
        if not isDown and not isUp then
            self.hoveredControl = target ~= nil and target.id or nil
            return target ~= nil
        end
        if self.activeAppId == nil and inside and isDown
            and (button == WheelDown or button == WheelUp)
            and contains(self.shortcutViewport, posX, posY) then
            local direction = button == WheelDown and 1 or -1
            self.shortcutPage = math.max(1, math.min(self.shortcutPageCount,
                self.shortcutPage + direction))
            self.pressedControl = nil
            return true
        end
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
                    self.focusedControl = target.id
                    return openShortcut(self, target.action.appId)
                end
                if target.action.page then
                    self.focusedControl = target.id
                    self.shortcutPage = math.max(1,
                        math.min(self.shortcutPageCount,
                            self.shortcutPage + target.action.page))
                    return true
                end
            end
            return pressed ~= nil
        end
        return inside
    end

    function instance:shutdown()
        if self.frameOverlay ~= nil and type(delete) == "function" then
            pcall(delete, self.frameOverlay)
        end
        self.frameOverlay = nil
        resetPresentation(self)
        self.declarative = nil
        self.activeAppId = nil
        self.routeId = nil
        self.initialized = false
        FORGE.Logger:info(FORGE.Definitions.LogSource.PHONE_HOST,
            "Phone Host shut down")
        return Result.SUCCESS
    end

    return instance
end
