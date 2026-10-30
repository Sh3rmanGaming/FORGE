---=============================================================================
--- FORGE ForgeOS Attention Badge
---
--- Shared PF.005 projection of a controlled application attention model onto
--- Host-drawn badge images. Owns shape selection, count formatting, geometry,
--- image lifetime, and a flat-rectangle fallback. Never derives, counts, or
--- stores attention truth: it only presents the model a Host passes in.
---=============================================================================

FORGE.AttentionBadge = {}

local AttentionBadge = FORGE.AttentionBadge
local AttentionState = FORGE.Definitions.AttentionState
local Token = FORGE.Definitions.PresentationToken

local AssetDirectory = "scripts/forge/forgeos/assets/"
local Assets = {
    unreadCircle = "badge_unread_circle.png",
    unreadPill = "badge_unread_pill.png",
    attention = "badge_attention.png",
    warning = "badge_warning.png",
    error = "badge_error.png"
}
-- Pixel width / pixel height of each image.
local ShapeAspect = {
    unreadCircle = 1,
    unreadPill = 2,
    attention = 1,
    warning = 1,
    error = 1
}
local StateToken = {
    [AttentionState.UNREAD] = Token.SEMANTIC_UNREAD,
    [AttentionState.ATTENTION] = Token.SEMANTIC_ATTENTION,
    [AttentionState.WARNING] = Token.SEMANTIC_WARNING,
    [AttentionState.ERROR] = Token.SEMANTIC_ERROR
}
-- Used only when an image cannot be created.
local FallbackGlyph = {
    attention = "!",
    warning = "!",
    error = "X"
}
local MaxExactDisplay = 99
local CountGap = 0.003
local GlyphColor = { 0.07, 0.07, 0.09 }

--- Formats a count for display. The authoritative value is never altered;
--- values above 99 are shown as `99+`. Returns nil when there is nothing to
--- show.
function AttentionBadge.formatCount(count)
    if type(count) ~= "number" or count < 1 or count ~= math.floor(count) then
        return nil
    end
    if count > MaxExactDisplay then
        return tostring(MaxExactDisplay) .. "+"
    end
    return tostring(count)
end

local function countShape(text)
    return string.len(text) > 1 and "unreadPill" or "unreadCircle"
end

--- Describes what to draw for an attention model, or nil for no badge.
--- Hosts pass the detached model they already received; malformed input
--- produces no badge.
function AttentionBadge.describe(attention)
    if type(attention) ~= "table" then
        return nil
    end
    local state = attention.state
    local token = StateToken[state]
    if token == nil then
        return nil
    end
    local text = AttentionBadge.formatCount(attention.count)
    if state == AttentionState.UNREAD then
        return {
            state = state,
            shape = text ~= nil and countShape(text) or "unreadCircle",
            token = token,
            text = text
        }
    end
    return {
        state = state,
        shape = state,
        token = token,
        countText = text
    }
end

--- Creates the badge images. Returns a (possibly empty) table; any image that
--- cannot be created is simply absent and drawn with the fallback.
function AttentionBadge.loadOverlays()
    local overlays = {}
    if type(createImageOverlay) ~= "function"
        or type(FORGE.ModDirectory) ~= "string" then
        return overlays
    end
    for key, file in pairs(Assets) do
        local created, overlay = pcall(
            createImageOverlay,
            FORGE.ModDirectory .. AssetDirectory .. file
        )
        if created and overlay ~= nil and overlay ~= 0 then
            overlays[key] = overlay
        end
    end
    return overlays
end

function AttentionBadge.deleteOverlays(overlays)
    if type(overlays) ~= "table" or type(delete) ~= "function" then
        return
    end
    for _, overlay in pairs(overlays) do
        pcall(delete, overlay)
    end
end

--- Reads the current attention for every registered application through the
--- Host context. The result is a session-local snapshot owned by the caller;
--- it is never persisted. Failed or malformed answers are simply absent.
function AttentionBadge.collect(context)
    local snapshot = {}
    if type(context) ~= "table"
        or type(context.getRegisteredAppIds) ~= "function"
        or type(context.getApplicationAttention) ~= "function" then
        return snapshot
    end
    local listed = { pcall(context.getRegisteredAppIds) }
    if not listed[1] or type(listed[2]) ~= "table" then
        return snapshot
    end
    for _, appId in ipairs(listed[2]) do
        local call = { pcall(context.getApplicationAttention, appId) }
        if call[1] and type(call[2]) == "table" then
            snapshot[appId] = call[2]
        end
    end
    return snapshot
end

local function shapeWidth(shape, height, aspect)
    return height / aspect * ShapeAspect[shape]
end

--- Total drawn width, in normalised screen units, for a described badge.
function AttentionBadge.measure(spec, height, aspect)
    if spec == nil then
        return 0
    end
    local width = shapeWidth(spec.shape, height, aspect)
    if spec.countText ~= nil then
        width = width + CountGap
            + shapeWidth(countShape(spec.countText), height, aspect)
    end
    return width
end

local function textWidth(text, size, aspect)
    if type(getTextWidth) == "function" then
        local ok, width = pcall(getTextWidth, size, text)
        if ok and type(width) == "number" then
            return width
        end
    end
    return string.len(text) * size * 0.55 / aspect
end

local function drawText(painter, text, x, y, width, height)
    local size = height * (string.len(text) >= 3 and 0.40
        or string.len(text) == 2 and 0.46 or 0.58)
    local offset = (width - textWidth(text, size, painter.aspect)) / 2
    painter.text(text, x + offset, y + (height - size * 0.72) / 2, size,
        GlyphColor[1], GlyphColor[2], GlyphColor[3])
end

local function drawShape(overlays, shape, token, text, x, y, height, painter)
    local width = shapeWidth(shape, height, painter.aspect)
    local overlay = overlays ~= nil and overlays[shape] or nil
    if overlay ~= nil and type(renderOverlay) == "function" then
        local tint = painter.tint(token)
        if type(setOverlayColor) == "function" then
            setOverlayColor(overlay, tint[1], tint[2], tint[3], tint[4] or 1)
        end
        renderOverlay(overlay, x, y, width, height)
    else
        painter.rect(token, x, y, width, height)
        text = text or FallbackGlyph[shape]
    end
    if text ~= nil then
        drawText(painter, text, x, y, width, height)
    end
end

--- Draws a described badge with its bottom-left corner at (x, y). The painter
--- supplies `aspect` (screen width / height), `tint(token)`, `rect(token, x,
--- y, w, h)`, and `text(text, x, y, size, r, g, b)` in the calling Host's own
--- palette.
function AttentionBadge.draw(overlays, spec, x, y, height, painter)
    if spec == nil then
        return
    end
    if spec.countText ~= nil then
        local pill = countShape(spec.countText)
        drawShape(overlays, pill, spec.token, spec.countText, x, y, height,
            painter)
        x = x + shapeWidth(pill, height, painter.aspect) + CountGap
    end
    drawShape(overlays, spec.shape, spec.token, spec.text, x, y, height,
        painter)
end
