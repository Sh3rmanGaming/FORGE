---=============================================================================
--- FORGE ForgeOS Notification Cue View
---
--- Shared PF.006 Host-side queue, timing, drawing and tap handling for
--- transient notification cues: Phone banners and Laptop toasts (ADR-007).
---
--- Owns session-only display state: which cues are visible or waiting and how
--- long each has been shown. Never reads, marks, or dismisses notifications;
--- expiry only removes the cue from view. Drawing uses the calling Host's own
--- painter, so colours stay in that Host's theme.
---
--- Painter contract: { aspect, tint(token), rect(token, x, y, w, h),
--- text(text, x, y, size, r, g, b) }.
---=============================================================================

FORGE.NotificationCueView = {}

local CueView = FORGE.NotificationCueView
local Token = FORGE.Definitions.PresentationToken
local Severity = FORGE.Definitions.NotificationSeverity

local SeverityToken = {
    [Severity.INFO] = Token.SEMANTIC_INFORMATION,
    [Severity.SUCCESS] = Token.SEMANTIC_SUCCESS,
    [Severity.WARNING] = Token.SEMANTIC_WARNING,
    [Severity.ERROR] = Token.SEMANTIC_ERROR,
    [Severity.CRITICAL] = Token.SEMANTIC_ERROR
}

local BorderThickness = 0.0016
local StripeWidth = 0.0045

local View = {}
View.__index = View

local function estimateWidth(text, size, aspect)
    if type(getTextWidth) == "function" then
        local ok, width = pcall(getTextWidth, size, text)
        if ok and type(width) == "number" then
            return width
        end
    end
    return string.len(text) * size * 0.55 / aspect
end

--- Cuts a line to one line that fits, ending in "..." when shortened.
local function fit(text, size, maxWidth, aspect)
    text = tostring(text or "")
    if estimateWidth(text, size, aspect) <= maxWidth then
        return text
    end
    local length = string.len(text)
    while length > 1 do
        length = length - 1
        local candidate = string.sub(text, 1, length) .. "..."
        if estimateWidth(candidate, size, aspect) <= maxWidth then
            return candidate
        end
    end
    return "..."
end

local function contains(region, x, y)
    return x >= region.x and x <= region.x + region.width
        and y >= region.y and y <= region.y + region.height
end

--- Creates a cue view.
-- @param config table maxVisible, maxWaiting, durationMs, showWaiting, and
--   the card geometry: anchorX, anchorY (bottom-left of the newest card),
--   width, height, gap, padding, sizes { app, title, body }.
function CueView.create(config)
    local view = setmetatable({
        config = config,
        visible = {},
        waiting = {},
        regions = {},
        pressedId = nil
    }, View)
    return view
end

local function indexOf(list, notificationId)
    for index, cue in ipairs(list) do
        if cue.notificationId == notificationId then
            return index
        end
    end
    return nil
end

--- Adds a cue. Duplicate notification ids are ignored.
function View:push(cue)
    if type(cue) ~= "table" or type(cue.notificationId) ~= "string" then
        return false
    end
    if indexOf(self.visible, cue.notificationId)
        or indexOf(self.waiting, cue.notificationId) then
        return false
    end
    local config = self.config
    local entry = {
        notificationId = cue.notificationId,
        source = cue.sourceName or cue.source,
        title = cue.title,
        body = cue.body,
        severity = cue.severity,
        actionable = cue.actionable,
        age = 0
    }
    if #self.visible < config.maxVisible then
        self.visible[#self.visible + 1] = entry
    elseif config.maxWaiting > 0 then
        if #self.waiting >= config.maxWaiting then
            table.remove(self.waiting, 1)
        end
        self.waiting[#self.waiting + 1] = entry
    else
        table.remove(self.visible, 1)
        self.visible[#self.visible + 1] = entry
    end
    return true
end

--- Advances display time and promotes waiting cues. dt is in milliseconds.
function View:update(dt)
    if type(dt) ~= "number" or dt < 0 then
        return
    end
    local kept = {}
    for _, cue in ipairs(self.visible) do
        cue.age = cue.age + dt
        if cue.age < self.config.durationMs then
            kept[#kept + 1] = cue
        end
    end
    self.visible = kept
    while #self.visible < self.config.maxVisible and #self.waiting > 0 do
        self.visible[#self.visible + 1] = table.remove(self.waiting, 1)
    end
    if #self.visible == 0 then
        self.regions = {}
        self.pressedId = nil
    end
end

--- Moves the card stack. Called by a Host when its surroundings change.
function View:setAnchor(anchorX, anchorY)
    self.config.anchorX = anchorX
    self.config.anchorY = anchorY
end

function View:hasCues()
    return #self.visible > 0
end

function View:getWaitingCount()
    return #self.waiting
end

function View:getVisibleCount()
    return #self.visible
end

--- Removes one cue from view without touching any notification record.
function View:remove(notificationId)
    local index = indexOf(self.visible, notificationId)
    if index ~= nil then
        table.remove(self.visible, index)
    else
        index = indexOf(self.waiting, notificationId)
        if index ~= nil then
            table.remove(self.waiting, index)
        end
    end
    if self.pressedId == notificationId then
        self.pressedId = nil
    end
    while #self.visible < self.config.maxVisible and #self.waiting > 0 do
        self.visible[#self.visible + 1] = table.remove(self.waiting, 1)
    end
end

function View:clear()
    self.visible, self.waiting, self.regions = {}, {}, {}
    self.pressedId = nil
end

--- Draws the visible cues, newest nearest the anchor, and records hit regions.
function View:draw(painter)
    self.regions = {}
    local config = self.config
    local aspect = painter.aspect
    local count = #self.visible
    for slot = 0, count - 1 do
        local cue = self.visible[count - slot]
        local x = config.anchorX
        local y = config.anchorY + slot * (config.height + config.gap)
        local width, height = config.width, config.height
        local token = SeverityToken[cue.severity] or Token.SEMANTIC_INFORMATION
        local tint = painter.tint(token)

        painter.rect(token, x, y, width, height)
        painter.rect(Token.SURFACE_ELEVATED,
            x + BorderThickness / aspect, y + BorderThickness,
            width - 2 * BorderThickness / aspect, height - 2 * BorderThickness)
        painter.rect(token, x, y + height * 0.10, StripeWidth,
            height * 0.80)

        local textX = x + config.padding
        local textWidth = width - config.padding * 2
        local pillWidth = 0
        if config.showWaiting and slot == 0 and #self.waiting > 0 then
            local label = "+" .. tostring(#self.waiting)
            pillWidth = 0.030
            local pillHeight = height * 0.30
            local pillX = x + width - pillWidth - 0.008
            local pillY = y + height - pillHeight - height * 0.10
            painter.rect(Token.ACCENT_PRIMARY, pillX, pillY, pillWidth,
                pillHeight)
            painter.text(label,
                pillX + (pillWidth - estimateWidth(label,
                    config.sizes.body, aspect)) / 2,
                pillY + pillHeight * 0.18, config.sizes.body, 0.07, 0.07, 0.09)
            textWidth = textWidth - pillWidth - 0.006
        end

        local muted = painter.tint(Token.TEXT_SECONDARY)
        local primary = painter.tint(Token.TEXT_PRIMARY)
        painter.text(fit(string.upper(tostring(cue.source or "")),
                config.sizes.app, textWidth, aspect),
            textX, y + height - config.sizes.app - height * 0.14,
            config.sizes.app, muted[1], muted[2], muted[3])
        painter.text(fit(cue.title, config.sizes.title, textWidth, aspect),
            textX, y + height * 0.38, config.sizes.title,
            primary[1], primary[2], primary[3])
        painter.text(fit(cue.body, config.sizes.body, textWidth, aspect),
            textX, y + height * 0.12, config.sizes.body,
            muted[1], muted[2], muted[3])

        self.regions[#self.regions + 1] = {
            x = x, y = y, width = width, height = height,
            notificationId = cue.notificationId, actionable = cue.actionable,
            tint = tint
        }
    end
end

--- Returns the region (and its notification id) under a point, or nil.
function View:hit(posX, posY)
    for index = #self.regions, 1, -1 do
        if contains(self.regions[index], posX, posY) then
            return self.regions[index]
        end
    end
    return nil
end

--- Handles a pointer event. Returns handled, activatedNotificationId.
-- A cue activates only on primary release over the cue that was pressed.
function View:pointer(posX, posY, isDown, isUp, button, primaryButton)
    if #self.regions == 0 then
        return false, nil
    end
    local target = self:hit(posX, posY)
    if isDown and button == primaryButton then
        self.pressedId = target ~= nil and target.notificationId or nil
        return target ~= nil, nil
    end
    if isUp and button == primaryButton then
        local pressed = self.pressedId
        self.pressedId = nil
        if target ~= nil and target.notificationId == pressed then
            return true, target.actionable and target.notificationId or nil
        end
        return pressed ~= nil, nil
    end
    return false, nil
end
