-- FORGE OS - first interactive phone shell.
-- Lightweight overlay UI intentionally avoids GIANTS menu replacement so it can
-- remain visible as a picture-in-picture window during normal gameplay.

ForgePhoneOS = {
    VERSION = "0.4.1.0",
    SAVE_SECTION = "phone",
    isOpen = false,
    isDragging = false,
    selectedApp = nil,
    x = 0.685,
    y = 0.135,
    width = 0.285,
    height = 0.705,
    dragOffsetX = 0,
    dragOffsetY = 0,
    backgroundOverlay = nil,
    panelOverlay = nil,
    accentOverlay = nil,
    phoneFrameOverlay = nil,
    appCardOverlay = nil,
    contentPanelOverlay = nil,
    actionHintShown = false
}

ForgePhoneOS.apps = {
    { id = "mail",      label = "MAIL",      subtitle = "Email inbox" },
    { id = "messages",  label = "MESSAGES",  subtitle = "Calls and texts" },
    { id = "projects",  label = "PROJECTS",  subtitle = "Current work" },
    { id = "banking",   label = "BANKING",   subtitle = "Accounts" },
    { id = "tutorials", label = "TUTORIALS", subtitle = "Learn FORGE" },
    { id = "settings",  label = "SETTINGS",  subtitle = "Preferences" }
}

local function inside(px, py, x, y, w, h)
    return px >= x and px <= x + w and py >= y and py <= y + h
end

local function clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value))
end

local function safeSetOverlayColor(overlay, r, g, b, a)
    if overlay ~= nil and setOverlayColor ~= nil then
        setOverlayColor(overlay, r, g, b, a)
    end
end

local function drawBox(overlay, x, y, w, h, r, g, b, a)
    if overlay == nil then
        return
    end
    safeSetOverlayColor(overlay, r, g, b, a)
    renderOverlay(overlay, x, y, w, h)
end

-- Approximate rounded panels using overlapping rectangles. This keeps the UI
-- texture-light and works with the existing one-pixel DDS overlay.
local function drawRoundedBox(overlay, x, y, w, h, radius, r, g, b, a)
    radius = math.min(radius or 0.012, w * 0.25, h * 0.25)
    drawBox(overlay, x + radius, y, w - radius * 2, h, r, g, b, a)
    drawBox(overlay, x, y + radius, w, h - radius * 2, r, g, b, a)
    drawBox(overlay, x + radius * 0.30, y + radius * 0.30, w - radius * 0.60, h - radius * 0.60, r, g, b, a)
end

local function drawPhoneFrame(overlay, x, y, w, h)
    local bezel = 0.010
    drawRoundedBox(overlay, x - bezel, y - bezel, w + bezel * 2, h + bezel * 2, 0.025, 0.010, 0.013, 0.017, 0.995)
    drawRoundedBox(overlay, x - 0.004, y - 0.004, w + 0.008, h + 0.008, 0.021, 0.16, 0.17, 0.18, 1)
    drawRoundedBox(overlay, x, y, w, h, 0.018, 0.025, 0.032, 0.040, 0.985)

    -- Speaker slit and home indicator make the overlay read as a physical phone.
    drawRoundedBox(overlay, x + w * 0.40, y + h - 0.019, w * 0.20, 0.004, 0.002, 0.30, 0.32, 0.34, 1)
    drawRoundedBox(overlay, x + w * 0.37, y + 0.010, w * 0.26, 0.005, 0.002, 0.32, 0.34, 0.36, 1)
end

local function drawTextLine(text, x, y, size, r, g, b, a, bold)
    setTextColor(r, g, b, a)
    setTextBold(bold == true)
    setTextAlignment(RenderText.ALIGN_LEFT)
    renderText(x, y, size, tostring(text))
    setTextBold(false)
end

function ForgePhoneOS:loadResources()
    if self.backgroundOverlay ~= nil then
        return
    end

    local texture = ForgeEngine.MOD_DIRECTORY .. "textures/forge_pixel.dds"
    self.backgroundOverlay = createImageOverlay(texture)
    self.panelOverlay = createImageOverlay(texture)
    self.accentOverlay = createImageOverlay(texture)
    self.phoneFrameOverlay = createImageOverlay(ForgeEngine.MOD_DIRECTORY .. "textures/phone_frame.dds")
    self.appCardOverlay = createImageOverlay(ForgeEngine.MOD_DIRECTORY .. "textures/app_card.dds")
    self.contentPanelOverlay = createImageOverlay(ForgeEngine.MOD_DIRECTORY .. "textures/content_panel.dds")

    ForgeLogger.info("FORGE OS resources loaded")
end

function ForgePhoneOS:deleteResources()
    for _, field in ipairs({"backgroundOverlay", "panelOverlay", "accentOverlay", "phoneFrameOverlay", "appCardOverlay", "contentPanelOverlay"}) do
        local overlay = self[field]
        if overlay ~= nil and delete ~= nil then
            delete(overlay)
        end
        self[field] = nil
    end
end

function ForgePhoneOS:onMissionLoad()
    self:loadResources()
    ForgeSaveManager.registerSection(
        self.SAVE_SECTION,
        self,
        ForgePhoneOS.loadFromXML,
        ForgePhoneOS.saveToXML
    )
    ForgeModuleRegistry.register("forge.os.phone", self, self.VERSION)
    ForgeEventBus.publish("forge.phone.ready", self)
    ForgeLogger.info("FORGE OS phone shell ready; press F7 to toggle")
end

function ForgePhoneOS:onMissionDelete()
    self:setOpen(false)
    ForgeSaveManager.unregisterOwner(self)
    self:deleteResources()
    self.selectedApp = nil
    self.isDragging = false
end

function ForgePhoneOS:loadFromXML(xmlFile, key)
    self.x = xmlFile:getFloat(key .. "#x", self.x)
    self.y = xmlFile:getFloat(key .. "#y", self.y)
    self.x = clamp(self.x, 0.005, 0.995 - self.width)
    self.y = clamp(self.y, 0.005, 0.995 - self.height)
    ForgeLogger.debug("Loaded phone position x=%.3f y=%.3f", self.x, self.y)
end

function ForgePhoneOS:saveToXML(xmlFile, key)
    xmlFile:setFloat(key .. "#x", self.x)
    xmlFile:setFloat(key .. "#y", self.y)
end

function ForgePhoneOS:setOpen(open)
    open = open == true
    if self.isOpen == open then
        return
    end

    self.isOpen = open
    self.isDragging = false

    if g_inputBinding ~= nil and g_inputBinding.setShowMouseCursor ~= nil then
        g_inputBinding:setShowMouseCursor(open)
    end

    if not open then
        self.selectedApp = nil
    end

    ForgeEventBus.publish(open and "forge.phone.opened" or "forge.phone.closed", self)
    ForgeLogger.debug("Phone %s", open and "opened" or "closed")
end

function ForgePhoneOS:toggle()
    self:setOpen(not self.isOpen)
end

function ForgePhoneOS:keyEvent(unicode, sym, modifier, isDown)
    if not isDown then
        return false
    end

    local f7 = Input ~= nil and Input.KEY_f7 or nil
    local esc = Input ~= nil and Input.KEY_esc or nil

    if sym == f7 or sym == 118 then
        self:toggle()
        return true
    end

    if self.isOpen and (sym == esc or sym == 27) then
        if self.selectedApp ~= nil then
            self.selectedApp = nil
        else
            self:setOpen(false)
        end
        return true
    end

    return false
end

function ForgePhoneOS:getAppRect(index)
    local padding = 0.018
    local gapX = 0.012
    local gapY = 0.018
    local gridTop = self.y + self.height - 0.165
    local appW = (self.width - padding * 2 - gapX) / 2
    local appH = 0.128
    local column = (index - 1) % 2
    local row = math.floor((index - 1) / 2)
    local appX = self.x + padding + column * (appW + gapX)
    local appY = gridTop - (row + 1) * appH - row * gapY
    return appX, appY, appW, appH
end

function ForgePhoneOS:mouseEvent(posX, posY, isDown, isUp, button)
    if not self.isOpen then
        return false
    end

    -- FS25 mouse-move events do not consistently retain the pressed button ID.
    -- Once a drag has started, process movement and release before filtering by button.
    if self.isDragging then
        if isUp then
            self.isDragging = false
            ForgeLogger.debug("Phone drag finished x=%.3f y=%.3f", self.x, self.y)
            return true
        end

        self.x = clamp(posX - self.dragOffsetX, 0.005, 0.995 - self.width)
        self.y = clamp(posY - self.dragOffsetY, 0.005, 0.995 - self.height)
        return true
    end

    local leftButton = Input ~= nil and Input.MOUSE_BUTTON_LEFT or 1
    if button ~= leftButton then
        return inside(posX, posY, self.x, self.y, self.width, self.height)
    end

    local headerY = self.y + self.height - 0.075

    if isDown then
        -- Close button
        if inside(posX, posY, self.x + self.width - 0.045, headerY + 0.012, 0.032, 0.038) then
            self:setOpen(false)
            return true
        end

        -- Back button inside an app.
        if self.selectedApp ~= nil and inside(posX, posY, self.x + 0.016, headerY + 0.012, 0.050, 0.038) then
            self.selectedApp = nil
            return true
        end

        -- Header drag area.
        if inside(posX, posY, self.x, headerY, self.width, 0.075) then
            self.isDragging = true
            self.dragOffsetX = posX - self.x
            self.dragOffsetY = posY - self.y
            return true
        end

        if self.selectedApp == nil then
            for index, app in ipairs(self.apps) do
                local ax, ay, aw, ah = self:getAppRect(index)
                if inside(posX, posY, ax, ay, aw, ah) then
                    self.selectedApp = app
                    ForgeEventBus.publish("forge.phone.appOpened", app.id)
                    ForgeLogger.debug("Opened phone app '%s'", app.id)
                    return true
                end
            end
        end
    end

    return inside(posX, posY, self.x, self.y, self.width, self.height)
end

function ForgePhoneOS:drawHome()
    drawTextLine("FORGE OS", self.x + 0.020, self.y + self.height - 0.055, 0.024, 1, 1, 1, 1, true)
    drawTextLine("Farming Operations & Regional Growth Engine", self.x + 0.020, self.y + self.height - 0.088, 0.011, 0.72, 0.77, 0.82, 1, false)

    for index, app in ipairs(self.apps) do
        local ax, ay, aw, ah = self:getAppRect(index)
        safeSetOverlayColor(self.appCardOverlay, 1, 1, 1, 1)
        renderOverlay(self.appCardOverlay, ax, ay, aw, ah)
        drawTextLine(app.label, ax + 0.012, ay + ah - 0.047, 0.016, 1, 1, 1, 1, true)
        drawTextLine(app.subtitle, ax + 0.012, ay + 0.027, 0.011, 0.68, 0.73, 0.78, 1, false)
    end

    drawTextLine("F7 CLOSE  |  DRAG TOP BAR", self.x + 0.020, self.y + 0.022, 0.010, 0.56, 0.61, 0.66, 1, false)
end

function ForgePhoneOS:drawApp()
    local app = self.selectedApp
    drawTextLine("< BACK", self.x + 0.018, self.y + self.height - 0.052, 0.014, 0.92, 0.55, 0.20, 1, true)
    drawTextLine(app.label, self.x + 0.092, self.y + self.height - 0.052, 0.021, 1, 1, 1, 1, true)

    local contentX = self.x + 0.020
    local contentY = self.y + 0.080
    local contentW = self.width - 0.040
    local contentH = self.height - 0.185
    safeSetOverlayColor(self.contentPanelOverlay, 1, 1, 1, 1)
    renderOverlay(self.contentPanelOverlay, contentX, contentY, contentW, contentH)

    if app.id == "projects" then
        local project = ForgeCampaignManager ~= nil and ForgeCampaignManager:getActiveProject() or nil
        if project == nil then
            drawTextLine("NO ACTIVE PROJECT", contentX + 0.018, contentY + contentH - 0.055, 0.018, 1, 1, 1, 1, true)
            drawTextLine("No enabled campaign project was found.", contentX + 0.018, contentY + contentH - 0.095, 0.012, 0.72, 0.77, 0.82, 1, false)
        else
            local stage = ForgeCampaignManager:getCurrentStage(project)
            local percent, completed, total = ForgeCampaignManager:getProjectProgress(project)
            drawTextLine(project.title, contentX + 0.018, contentY + contentH - 0.055, 0.018, 1, 1, 1, 1, true)
            drawTextLine(project.client ~= "" and project.client or "Independent Project", contentX + 0.018, contentY + contentH - 0.090, 0.011, 0.92, 0.55, 0.20, 1, true)
            drawTextLine("STATUS  " .. tostring(project.status), contentX + 0.018, contentY + contentH - 0.125, 0.011, 0.70, 0.76, 0.82, 1, true)
            drawTextLine(string.format("PROGRESS  %d%%  (%d/%d)", percent, completed, total), contentX + 0.018, contentY + contentH - 0.158, 0.011, 0.70, 0.76, 0.82, 1, false)

            if stage ~= nil then
                drawTextLine("STAGE " .. tostring(project.currentStage) .. "/" .. tostring(#project.stages), contentX + 0.018, contentY + contentH - 0.205, 0.011, 0.92, 0.55, 0.20, 1, true)
                drawTextLine(stage.title, contentX + 0.018, contentY + contentH - 0.242, 0.015, 1, 1, 1, 1, true)
                local objectiveY = contentY + contentH - 0.288
                for index, objective in ipairs(stage.objectives) do
                    if index > 5 then break end
                    local marker = objective.completed and "[X] " or "[ ] "
                    drawTextLine(marker .. objective.text, contentX + 0.018, objectiveY, 0.011, objective.completed and 0.55 or 0.84, objective.completed and 0.75 or 0.87, objective.completed and 0.58 or 0.90, 1, false)
                    objectiveY = objectiveY - 0.034
                end
            end
        end
    elseif app.id == "settings" then
        drawTextLine("PHONE SETTINGS", contentX + 0.018, contentY + contentH - 0.055, 0.018, 1, 1, 1, 1, true)
        drawTextLine("Window position saves with this career.", contentX + 0.018, contentY + contentH - 0.095, 0.012, 0.72, 0.77, 0.82, 1, false)
        drawTextLine("Toggle key: F7", contentX + 0.018, contentY + contentH - 0.135, 0.012, 0.80, 0.83, 0.86, 1, false)
    else
        drawTextLine(app.label .. " APP", contentX + 0.018, contentY + contentH - 0.055, 0.018, 1, 1, 1, 1, true)
        drawTextLine("App shell installed successfully.", contentX + 0.018, contentY + contentH - 0.095, 0.012, 0.72, 0.77, 0.82, 1, false)
        drawTextLine("Functional content arrives in a later sprint.", contentX + 0.018, contentY + contentH - 0.135, 0.012, 0.80, 0.83, 0.86, 1, false)
    end
end

function ForgePhoneOS:draw()
    if not self.isOpen then
        if g_currentMission ~= nil and not g_currentMission.isSynchronizingWithPlayers then
            drawTextLine("F7  FORGE PHONE", 0.845, 0.955, 0.012, 0.88, 0.58, 0.25, 0.92, true)
        end
        return
    end

    safeSetOverlayColor(self.phoneFrameOverlay, 1, 1, 1, 1)
    renderOverlay(self.phoneFrameOverlay, self.x - 0.018, self.y - 0.014, self.width + 0.036, self.height + 0.028)
    drawRoundedBox(self.accentOverlay, self.x + 0.020, self.y + self.height - 0.015, self.width - 0.040, 0.005, 0.002, 0.94, 0.58, 0.24, 1)

    -- close marker
    drawTextLine("X", self.x + self.width - 0.035, self.y + self.height - 0.052, 0.017, 0.92, 0.55, 0.20, 1, true)

    if self.selectedApp == nil then
        self:drawHome()
    else
        self:drawApp()
    end
end
