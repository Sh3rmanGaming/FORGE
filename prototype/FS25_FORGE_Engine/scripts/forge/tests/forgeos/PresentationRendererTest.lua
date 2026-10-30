---=============================================================================
--- FORGE PF.002 Declarative Presentation Runtime Tests
---=============================================================================

FORGE.Tests = FORGE.Tests or {}

function FORGE.Tests.runPresentationRendererTests()
    local function fail(message) error(message, 0) end
    local presentation = { actions = { ["test.activate"] = true } }
    local context = { appId = "test.neutral", presentationId = "test.phone",
        routeId = "home" }
    local action = { target = "application", actionId = "test.activate",
        parameters = { value = "safe" } }
    local function model()
        local offered = { target = "application", actionId = "test.activate",
            parameters = { value = "safe" } }
        local referenced = { target = "application", actionId = "test.activate",
            parameters = { value = "safe" } }
        return { modelVersion = 2, appId = context.appId,
            presentationId = context.presentationId, routeId = context.routeId,
            title = "Neutral", actions = { offered }, view = {
                component = "layout.stack", id = "root", properties = {
                    gap = "spacing.sm", clipping = "bounds", overflow = "hidden"
                }, children = {
                    { component = "layout.split", properties = {}, children = {
                        { component = "content.text", properties = { text = "Left" } },
                        { component = "content.text", properties = { text = "Right" } }
                    } },
                    { component = "layout.scroll", id = "reader", properties = {
                        overflow = "scroll", maximumHeight = "size.md"
                    }, children = {
                        { component = "content.text", properties = {
                            text = string.rep("bounded reading content ", 20),
                            textWrap = "word", textOverflow = "ellipsis"
                        } }
                    } },
                    { component = "control.button", id = "activate", properties = {
                        text = "Activate", actionReference = referenced
                    } }
                }
            } }
    end
    local profile = { viewport = { x = 0, y = 0, width = 1, height = 1 },
        spacing = { ["spacing.sm"] = 0.01 },
        sizes = { ["size.md"] = 0.25 }, ellipsis = "...",
        scrollStep = 0.1, scrollContentFactor = 3, typography = {
            ["typography.body"] = { size = 0.02, lineHeight = 0.03 }
        }, icons = { ["forge.placeholder"] = "forge.placeholder" },
        iconSize = 0.03, surfaces = {}, borders = {}, semantic = {
            unread = true, attention = true, success = true, warning = true,
            error = true, information = true
        } }
    local backend = {
        measureText = function(text, font) return #text * font.size * 0.5 end,
        drawBox = function() end, drawText = function() end,
        drawIcon = function() end
    }

    local succeeded, failure = pcall(function()
        local source = model()
        local validated = FORGE.PresentationRenderer.validateModel(
            source, context, presentation)
        if validated == nil then fail("Valid frozen model-v2 was rejected") end
        source.view.children[1].children[1].properties.text = "mutated"
        if validated.view.children[1].children[1].properties.text ~= "Left" then
            fail("Validated model was not detached")
        end

        local invalid = model()
        invalid.view.properties.rawColor = "red"
        if FORGE.PresentationRenderer.validateModel(invalid, context, presentation) then
            fail("Unknown property was accepted")
        end
        invalid = model(); invalid.view.children[1].children[3] = {
            component = "content.text", properties = { text = "Third" } }
        if FORGE.PresentationRenderer.validateModel(invalid, context, presentation) then
            fail("Split accepted more than two children")
        end
        invalid = model(); invalid.view.children[1].children[1] = invalid.view.children[2]
        if FORGE.PresentationRenderer.validateModel(invalid, context, presentation) then
            fail("Shared mutable alias was accepted")
        end
        invalid = model(); invalid.actions[129] = action
        if FORGE.PresentationRenderer.validateModel(invalid, context, presentation) then
            fail("Action defensive limit was not enforced")
        end
        invalid = model(); invalid.view.children[2].children[1].properties.maximumLines = 33
        if FORGE.PresentationRenderer.validateModel(invalid, context, presentation) then
            fail("Maximum-lines defensive limit was not enforced")
        end

        local phone = FORGE.PresentationRenderer.createSession()
        local laptop = FORGE.PresentationRenderer.createSession()
        local phonePlan = FORGE.PresentationRenderer.buildPlan(
            validated, profile, backend, phone, "phone")
        local laptopPlan = FORGE.PresentationRenderer.buildPlan(
            validated, profile, backend, laptop, "laptop")
        if phonePlan == nil or laptopPlan == nil or #phonePlan.hitRegions ~= 1
            or #phonePlan.scrolls ~= 1 then fail("Deterministic plan was not built") end
        FORGE.PresentationRenderer.scroll(phone, 0.5, 0.5, 1, 0.1)
        phone.hover, phone.pressed = "phone-only", { id = "phone-only" }
        if laptop.scroll.reader ~= 0 or laptop.hover ~= nil or laptop.pressed ~= nil
            or laptop.generation ~= 1 then fail("Phone state mutated Laptop session") end
        laptop.scroll.reader = 0.2
        if phone.scroll.reader == laptop.scroll.reader then
            fail("Laptop state was shared with Phone session")
        end

        local activated = 0
        local region = phonePlan.hitRegions[1]
        local x = region.bounds.x + region.bounds.width / 2
        local y = region.bounds.y + region.bounds.height / 2
        if not FORGE.PresentationRenderer.pointer(phone, x, y, true, false, 1,
            function() activated = activated + 1 end) then fail("Press not claimed") end
        if not FORGE.PresentationRenderer.pointer(phone, x, y, false, true, 1,
            function() activated = activated + 1 end) or activated ~= 1 then
            fail("Release did not activate exactly once")
        end
        phone.plan.hitRegions = {
            { id = "lower", bounds = { x = 0, y = 0, width = 1, height = 1 },
                generation = 1, action = action, ordinal = 1 },
            { id = "upper", bounds = { x = 0, y = 0, width = 1, height = 1 },
                generation = 1, action = action, ordinal = 2 }
        }
        FORGE.PresentationRenderer.pointer(phone, 0.5, 0.5, true, false, 1,
            function() end)
        if phone.pressed.id ~= "upper" then fail("Overlap order was not deterministic") end
        phone.pressed = nil
        if FORGE.PresentationRenderer.pointer(phone, 0.5, 0.5, true, false, 2,
            function() end) then fail("Secondary pointer was accepted") end
        local ok = FORGE.PresentationRenderer.draw(phonePlan, backend)
        if not ok then fail("Valid render plan failed backend") end
    end)

    if not succeeded then
        FORGE.Logger:error(FORGE.Definitions.LogSource.TEST,
            "PF.002 Presentation Renderer tests failed: %s",
            FORGE.Logger:safeToString(failure, "<unknown>"))
        return false, failure
    end
    FORGE.Logger:info(FORGE.Definitions.LogSource.TEST,
        "PF.002 Presentation Renderer tests passed")
    return true
end
