---=============================================================================
--- FORGE PF.006 Notification Cue View Tests
---
--- Verifies cue queues, limits, timing, expiry, drawing geometry, and tap
--- handling for the shared Phone banner and Laptop toast view.
---=============================================================================

FORGE.Tests = FORGE.Tests or {}

function FORGE.Tests.runNotificationCueViewTests()
    local CueView = FORGE.NotificationCueView
    local Token = FORGE.Definitions.PresentationToken

    local function check(condition, message)
        if not condition then
            error(message)
        end
    end

    local rects, texts
    local function newPainter()
        rects, texts = {}, {}
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

    local function cue(id, severity, actionable)
        return { notificationId = id, source = "forge.test",
            title = "Title " .. id, body = "Body " .. id,
            severity = severity or "info", actionable = actionable ~= false }
    end

    local function phoneView()
        return CueView.create({ maxVisible = 1, maxWaiting = 3,
            durationMs = 5000, showWaiting = true, anchorX = 0.7,
            anchorY = 0.7, width = 0.24, height = 0.06, gap = 0.006,
            padding = 0.012, sizes = { app = 0.0075, title = 0.011,
                body = 0.009 } })
    end

    local function laptopView()
        return CueView.create({ maxVisible = 3, maxWaiting = 0,
            durationMs = 6000, showWaiting = false, anchorX = 0.7,
            anchorY = 0.1, width = 0.23, height = 0.08, gap = 0.012,
            padding = 0.01, sizes = { app = 0.0085, title = 0.013,
                body = 0.0105 } })
    end

    local succeeded, failure = pcall(function()
        -- Phone: one at a time, three waiting, oldest waiting dropped.
        local view = phoneView()
        check(not view:hasCues(), "new view reported cues")
        check(view:push(cue("a")), "first cue rejected")
        check(not view:push(cue("a")), "duplicate cue accepted")
        check(not view:push({ title = "x" }), "cue without id accepted")
        view:push(cue("b")); view:push(cue("c")); view:push(cue("d"))
        check(view:getVisibleCount() == 1 and view:getWaitingCount() == 3,
            "phone should show one and keep three waiting")
        view:push(cue("e"))
        check(view:getWaitingCount() == 3, "waiting limit exceeded")
        view:update(4999)
        check(view:getVisibleCount() == 1, "cue expired early")
        view:update(1)
        check(view:getVisibleCount() == 1 and view:getWaitingCount() == 2,
            "next waiting cue was not promoted on expiry")
        -- 'b' was dropped when 'e' arrived, so 'c' is now showing.
        local painter = newPainter()
        view:draw(painter)
        local shownTitle
        for _, entry in ipairs(texts) do
            if string.sub(entry.text, 1, 5) == "Title" then
                shownTitle = entry.text
            end
        end
        check(shownTitle == "Title c", "wrong cue promoted: "
            .. tostring(shownTitle))

        -- Phone draws a waiting-count pill, with the accent colour.
        local pill = false
        for _, rect in ipairs(rects) do
            if rect.token == Token.ACCENT_PRIMARY then pill = true end
        end
        check(pill, "waiting pill was not drawn")
        local label = false
        for _, entry in ipairs(texts) do
            if entry.text == "+2" then label = true end
        end
        check(label, "waiting count text wrong")

        -- Laptop: three stack, newest nearest the anchor, a fourth pushes the
        -- oldest out.
        view = laptopView()
        view:push(cue("a")); view:push(cue("b")); view:push(cue("c"))
        check(view:getVisibleCount() == 3, "laptop should show three")
        view:push(cue("d"))
        check(view:getVisibleCount() == 3 and view:getWaitingCount() == 0,
            "laptop overflow should drop the oldest")
        painter = newPainter()
        view:draw(painter)
        local titles = {}
        for _, entry in ipairs(texts) do
            if string.sub(entry.text, 1, 5) == "Title" then
                titles[#titles + 1] = entry
            end
        end
        check(#titles == 3 and titles[1].text == "Title d"
            and titles[3].text == "Title b",
            "stack order should be newest first from the anchor")
        check(titles[1].y < titles[2].y and titles[2].y < titles[3].y,
            "older toasts should sit above newer ones")

        -- No pill on the Laptop; no waiting.
        for _, rect in ipairs(rects) do
            check(rect.token ~= Token.ACCENT_PRIMARY,
                "laptop toast drew a waiting pill")
        end

        -- Severity colours.
        local seen = {}
        view = laptopView()
        view:push(cue("w", "warning")); view:push(cue("x", "error"))
        view:push(cue("y", "critical")); view:draw(newPainter())
        for _, rect in ipairs(rects) do seen[rect.token] = true end
        check(seen[Token.SEMANTIC_WARNING] and seen[Token.SEMANTIC_ERROR],
            "severity colours missing")

        -- Expiry removes a cue from view only.
        view = laptopView()
        view:push(cue("a")); view:update(6000)
        check(not view:hasCues(), "cue did not expire")
        check(next(view.regions) == nil, "expired cue left a hit region")

        -- Hit testing and tap semantics.
        view = laptopView()
        view:push(cue("a")); view:push(cue("b", "info", false))
        view:draw(newPainter())
        local region
        for _, candidate in ipairs(view.regions) do
            if candidate.notificationId == "a" then region = candidate end
        end
        check(region ~= nil, "actionable cue region missing")
        local inside = { region.x + region.width / 2,
            region.y + region.height / 2 }
        local handled, activated = view:pointer(inside[1], inside[2], true,
            false, 1, 1)
        check(handled and activated == nil, "press should be handled only")
        handled, activated = view:pointer(inside[1], inside[2], false, true,
            1, 1)
        check(handled and activated == region.notificationId,
            "release over the pressed cue should activate it")
        view:draw(newPainter())
        handled = view:pointer(0.01, 0.01, true, false, 1, 1)
        check(not handled, "press outside a cue was handled")
        -- Press on one cue, release elsewhere: no activation.
        view:pointer(inside[1], inside[2], true, false, 1, 1)
        handled, activated = view:pointer(0.01, 0.01, false, true, 1, 1)
        check(handled and activated == nil,
            "release elsewhere must not activate")
        -- Secondary button never activates.
        handled = view:pointer(inside[1], inside[2], true, false, 2, 1)
        check(not handled, "secondary button was handled")
        -- A cue with no destination swallows the tap but activates nothing.
        view:draw(newPainter())
        local plain
        for _, candidate in ipairs(view.regions) do
            if not candidate.actionable then plain = candidate end
        end
        check(plain ~= nil, "non-actionable cue region missing")
        view:pointer(plain.x + 0.01, plain.y + 0.01, true, false, 1, 1)
        handled, activated = view:pointer(plain.x + 0.01, plain.y + 0.01,
            false, true, 1, 1)
        check(handled and activated == nil,
            "cue without a destination activated something")

        -- Removing a cue promotes a waiting one; clearing empties the view.
        view = phoneView()
        view:push(cue("a")); view:push(cue("b"))
        view:remove("a")
        check(view:getVisibleCount() == 1 and view:getWaitingCount() == 0,
            "removal should promote the waiting cue")
        view:clear()
        check(not view:hasCues(), "clear left cues behind")

        -- Long text is cut to one line, never wider than the card.
        view = laptopView()
        view:push({ notificationId = "long", source = "forge.test",
            title = string.rep("W", 200), body = string.rep("x", 400),
            severity = "info", actionable = true })
        painter = newPainter()
        view:draw(painter)
        for _, entry in ipairs(texts) do
            check(string.len(entry.text) < 100, "text was not cut: "
                .. string.len(entry.text))
        end
    end)

    if not succeeded then
        return false, failure
    end
    FORGE.Logger:info(FORGE.Definitions.LogSource.TEST,
        "Notification Cue View test harness passed")
    return true
end
