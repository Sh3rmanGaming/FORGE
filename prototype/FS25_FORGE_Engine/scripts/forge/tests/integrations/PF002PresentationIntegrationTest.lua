---=============================================================================
--- FORGE PF.002 Neutral Cross-Host Presentation Integration Tests
---=============================================================================

FORGE.Tests = FORGE.Tests or {}

function FORGE.Tests.runPF002PresentationIntegrationTests()
    local Result = FORGE.Definitions.ForgeOSResult
    local Visibility = FORGE.Definitions.DeviceVisibility
    local actionCount = { phone = 0, laptop = 0 }
    local function model(presentationId)
        local offered = { target = "application", actionId = "neutral.activate",
            parameters = {} }
        local referenced = { target = "application", actionId = "neutral.activate",
            parameters = {} }
        return { modelVersion = 2, appId = "neutral.app",
            presentationId = presentationId, routeId = "home", title = "Neutral",
            actions = { offered }, view = { component = "layout.stack",
                properties = {}, children = {
                    { component = "layout.scroll", id = "reading", properties = {
                        overflow = "scroll", maximumHeight = "size.md"
                    }, children = { { component = "content.text", properties = {
                        text = string.rep("Long neutral content ", 40),
                        textWrap = "word", textOverflow = "ellipsis"
                    } } } },
                    { component = "control.button", id = "activate", properties = {
                        text = "Activate", actionReference = referenced
                    } }
                } } }
    end
    local function context(device)
        local presentationId = "neutral." .. device
        return {
            getVisibility = function() return Visibility.VISIBLE end,
            getActiveAppId = function() return "neutral.app" end,
            getCurrentRoute = function() return "home", {} end,
            getApplicationPresentationModel = function()
                return FORGE.PresentationRenderer.validateModel(model(presentationId),
                    { appId = "neutral.app", presentationId = presentationId,
                        routeId = "home" }, { actions = { ["neutral.activate"] = true } })
            end,
            performApplicationAction = function()
                actionCount[device] = actionCount[device] + 1
                return Result.SUCCESS, { completed = true, domainResult = "success" }
            end,
            closeApp = function() return Result.SUCCESS end,
            hide = function() return Result.SUCCESS end,
            isUiBlocked = function() return false end
        }
    end
    local oldDraw, oldText, oldColor = drawFilledRect, renderText, setTextColor
    local oldCreateImageOverlay, oldRenderOverlay = createImageOverlay, renderOverlay
    drawFilledRect, renderText, setTextColor = function() end, function() end,
        function() end
    createImageOverlay, renderOverlay = function() return nil end, function() end
    local phone, laptop
    local succeeded, failure = pcall(function()
        phone, laptop = FORGE.PhoneHost.create(context("phone")),
            FORGE.LaptopHost.create(context("laptop"))
        if phone:initialize() ~= Result.SUCCESS or laptop:initialize() ~= Result.SUCCESS then
            error("Neutral Hosts did not initialize")
        end
        phone:draw(); laptop:draw()
        if phone.declarative.session.plan == nil
            or laptop.declarative.session.plan == nil then
            error("Neutral v2 plan did not render on both Hosts")
        end
        phone.declarative.session.scroll.reading = 0.17
        phone.declarative.session.hover = "phone-only"
        if laptop.declarative.session.scroll.reading == 0.17
            or laptop.declarative.session.hover ~= nil then
            error("Phone runtime session mutated Laptop")
        end
        laptop.declarative.session.scroll.reading = 0.29
        laptop.declarative.session.pressed = { id = "laptop-only" }
        if phone.declarative.session.scroll.reading == 0.29
            or phone.declarative.session.pressed ~= nil then
            error("Laptop runtime session mutated Phone")
        end
        local region = phone.declarative.session.plan.hitRegions[1]
        local x, y = region.bounds.x + region.bounds.width / 2,
            region.bounds.y + region.bounds.height / 2
        phone:onPointer(x, y, true, false, 1)
        phone:onPointer(x, y, false, true, 1)
        if actionCount.phone ~= 1 or actionCount.laptop ~= 0 then
            error("Neutral action mediation crossed Host boundary")
        end
    end)
    if phone ~= nil then pcall(phone.shutdown, phone) end
    if laptop ~= nil then pcall(laptop.shutdown, laptop) end
    drawFilledRect, renderText, setTextColor = oldDraw, oldText, oldColor
    createImageOverlay, renderOverlay = oldCreateImageOverlay, oldRenderOverlay
    if not succeeded then return false, failure end
    FORGE.Logger:info(FORGE.Definitions.LogSource.TEST,
        "PF.002 neutral presentation integration test passed")
    return true
end
