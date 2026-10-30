---=============================================================================
--- FORGE PF.005 Attention Badge Tests
---
--- Verifies count formatting, state-to-shape selection, geometry, drawing with
--- and without images, and the session-local attention snapshot.
---=============================================================================

FORGE.Tests = FORGE.Tests or {}

function FORGE.Tests.runAttentionBadgeTests()
    local Badge = FORGE.AttentionBadge
    local Token = FORGE.Definitions.PresentationToken

    local function check(condition, message)
        if not condition then
            error(message)
        end
    end

    local rects, texts, overlayCalls, overlayColors
    local function newPainter()
        rects, texts, overlayCalls, overlayColors = {}, {}, {}, {}
        return {
            aspect = 2,
            tint = function(_) return { 0.5, 0.25, 0.125, 1 } end,
            rect = function(token, x, y, width, height)
                rects[#rects + 1] = { token = token, x = x, y = y,
                    width = width, height = height }
            end,
            text = function(text, x, y, size)
                texts[#texts + 1] = { text = text, x = x, y = y, size = size }
            end
        }
    end

    local oldRenderOverlay, oldSetOverlayColor = renderOverlay, setOverlayColor
    local succeeded, failure = pcall(function()
        -- Count formatting: exact up to 99, then 99+; never invented.
        check(Badge.formatCount(nil) == nil, "nil count produced text")
        check(Badge.formatCount(0) == nil, "zero count produced text")
        check(Badge.formatCount(-3) == nil, "negative count produced text")
        check(Badge.formatCount(12.5) == nil, "fractional count produced text")
        check(Badge.formatCount("7") == nil, "string count produced text")
        check(Badge.formatCount(1) == "1", "count 1 formatted wrongly")
        check(Badge.formatCount(99) == "99", "count 99 must be exact")
        check(Badge.formatCount(100) == "99+", "count 100 must be 99+")
        check(Badge.formatCount(100000) == "99+", "large count must be 99+")

        -- State to shape.
        check(Badge.describe(nil) == nil, "nil attention produced a badge")
        check(Badge.describe("unread") == nil, "string attention accepted")
        check(Badge.describe({ state = "none", count = 0 }) == nil,
            "none state produced a badge")
        check(Badge.describe({ state = "bogus", count = 3 }) == nil,
            "unknown state produced a badge")
        local seven = Badge.describe({ state = "unread", count = 7 })
        check(seven.shape == "unreadCircle" and seven.text == "7"
            and seven.token == Token.SEMANTIC_UNREAD, "unread 7 wrong")
        local fortyTwo = Badge.describe({ state = "unread", count = 42 })
        check(fortyTwo.shape == "unreadPill" and fortyTwo.text == "42",
            "unread 42 should use the pill")
        local source = { state = "unread", count = 150 }
        local capped = Badge.describe(source)
        check(capped.shape == "unreadPill" and capped.text == "99+",
            "unread 150 should display 99+")
        check(source.count == 150, "display compression altered the value")
        local bare = Badge.describe({ state = "unread" })
        check(bare.shape == "unreadCircle" and bare.text == nil,
            "unread without a count should be a plain circle")
        local attention = Badge.describe({ state = "attention" })
        check(attention.shape == "attention" and attention.countText == nil
            and attention.token == Token.SEMANTIC_ATTENTION,
            "attention without a count wrong")
        local warning = Badge.describe({ state = "warning", count = 3,
            accessibleLabel = "Three warnings" })
        check(warning.shape == "warning" and warning.countText == "3"
            and warning.token == Token.SEMANTIC_WARNING,
            "warning with a count wrong")
        local failureBadge = Badge.describe({ state = "error" })
        check(failureBadge.shape == "error" and failureBadge.countText == nil
            and failureBadge.token == Token.SEMANTIC_ERROR,
            "error without a count wrong")

        -- Geometry: square shapes keep pixel squareness through the aspect.
        check(math.abs(Badge.measure(seven, 0.03, 2) - 0.015) < 1e-9,
            "circle width ignored the aspect ratio")
        check(math.abs(Badge.measure(fortyTwo, 0.03, 2) - 0.03) < 1e-9,
            "pill should be twice as wide as a circle")
        check(Badge.measure(warning, 0.03, 2) > Badge.measure(attention, 0.03, 2),
            "a count should widen a non-unread badge")
        check(Badge.measure(nil, 0.03, 2) == 0, "no badge should measure zero")

        -- Fallback drawing (no images).
        local painter = newPainter()
        Badge.draw({}, seven, 0.1, 0.2, 0.03, painter)
        check(#rects == 1 and rects[1].token == Token.SEMANTIC_UNREAD,
            "unread fallback should draw one tinted rectangle")
        check(#texts == 1 and texts[1].text == "7",
            "unread fallback should draw the count")
        painter = newPainter()
        Badge.draw({}, failureBadge, 0.1, 0.2, 0.03, painter)
        check(#rects == 1 and #texts == 1 and texts[1].text == "X",
            "error fallback should show a glyph")
        painter = newPainter()
        Badge.draw({}, warning, 0.1, 0.2, 0.03, painter)
        check(#rects == 2 and #texts == 2 and texts[1].text == "3"
            and texts[2].text == "!",
            "warning with a count should draw the count then the shape")
        check(rects[2].x > rects[1].x, "count should sit left of the shape")
        -- A mirrored shape right edge puts the shape left of the count.
        painter = newPainter()
        Badge.draw({}, warning, 0.1, 0.2, 0.03, painter, 0.05)
        check(#rects == 2 and rects[1].x == 0.1
            and math.abs(rects[2].x + rects[2].width - 0.05) < 1e-9
            and rects[2].x < rects[1].x,
            "mirrored shape should end at shapeRight, left of the count")
        painter = newPainter()
        Badge.draw({}, failureBadge, 0.1, 0.2, 0.03, painter, 0.05)
        check(#rects == 1 and rects[1].x == 0.1,
            "a shape without a count must ignore shapeRight")
        painter = newPainter()
        Badge.draw({}, nil, 0.1, 0.2, 0.03, painter)
        check(#rects == 0 and #texts == 0, "nil badge must draw nothing")

        -- Image drawing.
        painter = newPainter()
        renderOverlay = function(overlay, x, y, width, height)
            overlayCalls[#overlayCalls + 1] = { overlay = overlay, x = x,
                y = y, width = width, height = height }
        end
        setOverlayColor = function(overlay, red, green, blue, alpha)
            overlayColors[#overlayColors + 1] = { overlay = overlay,
                red = red, green = green, blue = blue, alpha = alpha }
        end
        Badge.draw({ unreadCircle = 11 }, seven, 0.1, 0.2, 0.03, painter)
        check(#overlayCalls == 1 and overlayCalls[1].overlay == 11
            and #rects == 0, "image should replace the fallback rectangle")
        check(overlayColors[1].red == 0.5 and overlayColors[1].green == 0.25,
            "image was not tinted with the state colour")
        check(#texts == 1 and texts[1].text == "7",
            "count should still be drawn over the image")

        -- Snapshot collection: failures and junk are absent, never invented.
        check(next(Badge.collect(nil)) == nil, "nil context produced a snapshot")
        check(next(Badge.collect({})) == nil, "empty context produced a snapshot")
        local calls = 0
        local snapshot = Badge.collect({
            getRegisteredAppIds = function() return { "a", "b", "c", "d" } end,
            getApplicationAttention = function(appId)
                calls = calls + 1
                if appId == "b" then error("provider failure") end
                if appId == "c" then return "junk" end
                if appId == "d" then return nil end
                return { state = "warning", count = 2 }
            end
        })
        check(calls == 4, "every registered app should be queried once")
        check(snapshot.a ~= nil and snapshot.a.state == "warning",
            "good attention missing from snapshot")
        check(snapshot.b == nil and snapshot.c == nil and snapshot.d == nil,
            "failed or malformed attention entered the snapshot")
    end)
    renderOverlay, setOverlayColor = oldRenderOverlay, oldSetOverlayColor

    if not succeeded then
        return false, failure
    end
    FORGE.Logger:info(FORGE.Definitions.LogSource.TEST,
        "Attention Badge test harness passed")
    return true
end
