---=============================================================================
--- FORGE Declarative Presentation Host Adapter
---
--- Binds the shared PF.002 renderer to one Host-owned device session.
---=============================================================================

FORGE.PresentationHostAdapter = {}

local Adapter = FORGE.PresentationHostAdapter
local Result = FORGE.Definitions.ForgeOSResult

local function stable(value)
    if type(value) ~= "table" then return tostring(value) end
    local keys = {}
    for key in pairs(value) do keys[#keys + 1] = key end
    table.sort(keys)
    local parts = {}
    for _, key in ipairs(keys) do parts[#parts + 1] = key .. "=" .. stable(value[key]) end
    return "{" .. table.concat(parts, ",") .. "}"
end

local function makeProfile(viewport, density)
    local spacing = {
        ["spacing.xs"] = 0.004 * density, ["spacing.sm"] = 0.007 * density,
        ["spacing.md"] = 0.011 * density, ["spacing.lg"] = 0.016 * density,
        ["spacing.xl"] = 0.024 * density, ["spacing.xxl"] = 0.034 * density
    }
    local sizes = {
        ["size.xs"] = 0.02 * density, ["size.sm"] = 0.035 * density,
        ["size.md"] = 0.06 * density, ["size.lg"] = 0.10 * density,
        ["size.xl"] = 0.16 * density, ["size.xxl"] = 0.24 * density,
        ["size.viewport"] = math.max(viewport.width, viewport.height)
    }
    local typography = {}
    local roles = { ["typography.display"] = 1.5, ["typography.heading1"] = 1.35,
        ["typography.heading2"] = 1.22, ["typography.heading3"] = 1.12,
        ["typography.body"] = 1, ["typography.bodyStrong"] = 1,
        ["typography.label"] = 0.92, ["typography.caption"] = 0.82,
        ["typography.numeric"] = 1 }
    for role, scale in pairs(roles) do
        typography[role] = { size = 0.012 * density * scale,
            lineHeight = 0.018 * density * scale }
    end
    local surfaces, borders, semantic = {}, {}, {}
    for _, token in ipairs({ "surface.background", "surface.primary",
        "surface.secondary", "surface.elevated", "surface.selected",
        "surface.disabled" }) do surfaces[token] = true end
    for _, token in ipairs({ "border.subtle", "border.standard",
        "border.active", "border.focus" }) do borders[token] = true end
    for _, state in ipairs({ "unread", "attention", "success", "warning",
        "error", "information" }) do semantic[state] = true end
    return { viewport = viewport, density = density, spacing = spacing,
        sizes = sizes, typography = typography, surfaces = surfaces,
        borders = borders, semantic = semantic, ellipsis = "...",
        scrollStep = 0.04 * density, iconSize = 0.03 * density,
        icons = { ["forge.placeholder"] = "forge.placeholder" } }
end

local function makeBackend()
    local function clipped(bounds, clip)
        local x = math.max(bounds.x, clip.x)
        local y = math.max(bounds.y, clip.y)
        local right = math.min(bounds.x + bounds.width, clip.x + clip.width)
        local top = math.min(bounds.y + bounds.height, clip.y + clip.height)
        return x, y, math.max(0, right - x), math.max(0, top - y)
    end
    local colors = {
        none = { 0.94, 0.95, 0.97 }, unread = { 0.95, 0.62, 0.20 },
        attention = { 0.95, 0.62, 0.20 }, success = { 0.35, 0.82, 0.50 },
        warning = { 0.98, 0.70, 0.22 }, error = { 0.95, 0.32, 0.30 },
        information = { 0.35, 0.68, 0.96 }
    }
    return {
        measureText = function(text, font)
            if type(getTextWidth) == "function" then
                local ok, width = pcall(getTextWidth, font.size, text)
                if ok and type(width) == "number" then return width end
            end
            return #tostring(text) * font.size * 0.52
        end,
        drawBox = function(primitive)
            local b = primitive.bounds
            local x, y, width, height = clipped(b, primitive.clip)
            if type(drawFilledRect) == "function" and width > 0 and height > 0 then
                drawFilledRect(x, y, width, height, 0.07, 0.09, 0.12, 0.92)
            end
        end,
        drawText = function(primitive)
            local clip = primitive.clip
            if type(renderText) == "function" and primitive.x >= clip.x
                and primitive.x <= clip.x + clip.width and primitive.y >= clip.y
                and primitive.y <= clip.y + clip.height then
                local color = colors[primitive.state] or colors.none
                if type(setTextColor) == "function" then
                    setTextColor(color[1], color[2], color[3], 1)
                end
                renderText(primitive.x, primitive.y, primitive.font.size, primitive.text)
            end
        end,
        drawIcon = function(primitive)
            local b = primitive.bounds
            if type(drawFilledRect) == "function" then
                local size = math.min(b.width, b.height) * 0.5
                local icon = { x = b.x + (b.width - size) / 2,
                    y = b.y + (b.height - size) / 2,
                    width = size, height = size }
                local x, y, width, height = clipped(icon, primitive.clip)
                if width > 0 and height > 0 then
                    drawFilledRect(x, y, width, height, 0.72, 0.76, 0.82, 1)
                end
            end
        end
    }
end

function Adapter.create(context, viewport, density, logSource)
    local value = {
        context = context,
        profile = makeProfile(viewport, density),
        backend = makeBackend(),
        session = FORGE.PresentationRenderer.createSession(),
        model = nil,
        appId = nil,
        routeId = nil,
        contextKey = nil,
        logSource = logSource
    }

    function value:reset()
        FORGE.PresentationRenderer.resetSession(self.session)
        self.model, self.appId, self.routeId, self.contextKey = nil, nil, nil, nil
    end

    function value:refresh(appId)
        if appId == nil then self:reset(); return false end
        local routeId, parameters = self.context.getCurrentRoute(appId)
        local key = appId .. "\0" .. tostring(routeId) .. "\0" .. stable(parameters or {})
        local call = { pcall(self.context.getApplicationPresentationModel, appId) }
        if not call[1] or type(call[2]) ~= "table" or call[2].modelVersion ~= 2 then
            if self.contextKey ~= key then self:reset(); self.contextKey = key end
            return false
        end
        local plan, failure = FORGE.PresentationRenderer.buildPlan(
            call[2], self.profile, self.backend, self.session, key)
        if plan == nil then
            FORGE.Logger:warning(self.logSource,
                "Declarative render-plan failure: %s",
                FORGE.Logger:safeToString(failure, "<unknown>"))
            return self.session.plan ~= nil
        end
        self.model, self.appId, self.routeId, self.contextKey = call[2], appId, routeId, key
        return true
    end

    function value:draw()
        if self.session.plan == nil then return false end
        local ok, failure = FORGE.PresentationRenderer.draw(self.session.plan, self.backend)
        if not ok then
            FORGE.Logger:warning(self.logSource, "Declarative backend failure: %s",
                FORGE.Logger:safeToString(failure, "<unknown>"))
        end
        return ok
    end

    function value:activate(reference)
        if reference.target == "application" then
            local result = self.context.performApplicationAction(
                self.appId, reference.actionId, reference.parameters)
            if result == Result.SUCCESS then self:refresh(self.appId) end
            return result == Result.SUCCESS
        end
        if reference.actionId == "osHome" then
            return self.context.closeApp(self.appId) == Result.SUCCESS
        end
        if reference.actionId == "deviceClose" then
            return self.context.hide() == Result.SUCCESS
        end
        return false
    end

    function value:pointer(x, y, isDown, isUp, button)
        if (button == 4 or button == 5) and isDown then
            return FORGE.PresentationRenderer.scroll(self.session, x, y,
                button == 4 and 1 or -1, self.profile.scrollStep)
        end
        return FORGE.PresentationRenderer.pointer(self.session, x, y,
            isDown, isUp, button, function(reference) self:activate(reference) end)
    end

    return value
end
