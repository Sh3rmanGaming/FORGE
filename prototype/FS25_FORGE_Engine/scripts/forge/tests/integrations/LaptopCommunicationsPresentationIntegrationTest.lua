---=============================================================================
--- FORGE Laptop Communications Presentation Integration Tests
---=============================================================================

FORGE.Tests = FORGE.Tests or {}

function FORGE.Tests.runLaptopCommunicationsPresentationIntegrationTests()
    FORGE.Logger:info(FORGE.Definitions.LogSource.TEST,
        "Laptop Communications presentation integration test started")
    local Result = FORGE.Definitions.ForgeOSResult
    local Visibility = FORGE.Definitions.DeviceVisibility
    local activeAppId, routeId = nil, nil
    local badge, failAction, failModel, failClose = 8, false, false, false
    local labels, sequence, actions, closed = {}, {}, {}, {}
    local notificationQueries, missing = 0, false
    local rows = {}
    for index = 1, 8 do
        rows[index] = {
            messageId = "laptop.message." .. tostring(index),
            sender = index == 8 and string.rep("Wide sender ", 8)
                or "Sender " .. tostring(index),
            subject = index == 8 and string.rep("Wide subject ", 8)
                or "Subject " .. tostring(index),
            preview = index == 8 and string.rep("Wide preview content ", 12)
                or "Preview " .. tostring(index),
            unread = true
        }
    end
    local originalValues = { rows[8].sender, rows[8].subject, rows[8].preview }
    local selected = { messageId = rows[8].messageId,
        sender = "Selected sender", subject = "Selected subject",
        body = string.rep("Laptop detail body remains authoritative. ", 40),
        unread = true }

    local function inboxModel()
        local declared = {}
        for _, row in ipairs(rows) do
            declared[#declared + 1] = { id = "communications.openMessage",
                parameters = { messageId = row.messageId } }
        end
        return { presentationId = "forge.communications.laptop",
            routeId = "inbox", badgeCount = badge,
            content = { kind = "communications.inbox",
                emptyText = "No messages", rows = rows }, actions = declared }
    end

    local function detailModel(message)
        local declared = {
            { id = "communications.back", parameters = {} },
            { id = "communications.openInbox", parameters = {} }
        }
        if message ~= nil then
            declared[#declared + 1] = { id = "communications.markRead",
                parameters = { messageId = message.messageId } }
            declared[#declared + 1] = { id = "communications.archive",
                parameters = { messageId = message.messageId } }
        end
        return { presentationId = "forge.communications.laptop",
            routeId = "messageDetail", badgeCount = badge,
            content = { kind = "communications.messageDetail", message = message },
            actions = declared }
    end

    local context = {
        getVisibility = function() return Visibility.VISIBLE end,
        show = function() return Result.SUCCESS end,
        hide = function() return Result.SUCCESS end,
        getActiveAppId = function() return activeAppId end,
        getRegisteredAppIds = function() return { "forge.communications" } end,
        getAppDefinition = function(appId) return { id = appId,
            displayName = "Communications", supportedDevices = { laptop = true } }
        end,
        resolvePresentation = function() return Result.SUCCESS,
            { presentationId = "forge.communications.laptop" } end,
        getCurrentRoute = function() return routeId end,
        getValidatedResumeDestination = function() return Result.SUCCESS, nil end,
        openApp = function(appId)
            sequence[#sequence + 1] = "open:" .. appId; return Result.SUCCESS
        end,
        activateApp = function(appId)
            sequence[#sequence + 1] = "activate:" .. appId
            activeAppId = appId; return Result.SUCCESS
        end,
        navigate = function(appId, destination, parameters)
            sequence[#sequence + 1] = "navigate:" .. appId .. ":" .. destination
            routeId = destination
            return parameters ~= nil and Result.SUCCESS or Result.INTERNAL_ERROR
        end,
        closeApp = function(appId)
            if failClose then return Result.STATE_ERROR end
            closed[#closed + 1] = appId
            activeAppId, routeId = nil, nil; return Result.SUCCESS
        end,
        getApplicationBadge = function() return badge end,
        getApplicationPresentationModel = function()
            if failModel then return nil end
            if routeId == "inbox" then return inboxModel() end
            local message = selected
            if missing then message = nil end
            return detailModel(message)
        end,
        performApplicationAction = function(_, actionId, parameters)
            actions[#actions + 1] = actionId
            if failAction then return Result.STATE_ERROR, nil end
            if actionId == "communications.openMessage" then
                routeId = "messageDetail"
            elseif actionId == "communications.markRead" then
                selected.unread, badge = false, badge - 1
            elseif actionId == "communications.archive"
                or actionId == "communications.back"
                or actionId == "communications.openInbox" then routeId = "inbox" end
            return Result.SUCCESS, { completed = parameters ~= nil,
                domainResult = "success" }
        end,
        getNotifications = function()
            notificationQueries = notificationQueries + 1; return {}
        end,
        markNotificationRead = function() return Result.SUCCESS end,
        dismissNotification = function() return Result.SUCCESS end,
        isUiBlocked = function() return false end
    }

    local originalDraw, originalText, originalColor =
        drawFilledRect, renderText, setTextColor
    local originalCreateImageOverlay, originalRenderOverlay =
        createImageOverlay, renderOverlay
    local originalSetOverlayColor, originalDelete = setOverlayColor, delete
    drawFilledRect = function() end
    renderText = function(_, _, _, text) labels[#labels + 1] = text end
    setTextColor = function() end
    createImageOverlay = function() return 200 end
    renderOverlay = function() end
    setOverlayColor = function() end
    delete = function() end

    local succeeded, failure = pcall(function()
        local host = FORGE.LaptopHost.create(context)
        if host:initialize() ~= Result.SUCCESS then error("Laptop init failed") end
        host:draw()
        local homeQueries, badgeSeen = notificationQueries, false
        for _, label in ipairs(labels) do if label == "8" then badgeSeen = true end end
        if not badgeSeen then error("Exact Laptop badge was not rendered") end
        if not host:onPointer(0.10, 0.76, true, false, 1) or #sequence ~= 0
            or not host:onPointer(0.10, 0.76, false, true, 1)
            or sequence[1] ~= "open:forge.communications"
            or sequence[2] ~= "activate:forge.communications"
            or sequence[3] ~= "navigate:forge.communications:inbox" then
            error("Laptop launcher sequence failed")
        end

        labels = {}; host:draw()
        local clipped, newestIndex, olderIndex = 0, nil, nil
        local sixthSeen, seventhSeen = false, false
        for index, label in ipairs(labels) do
            if string.find(label, "...", 1, true) then clipped = clipped + 1 end
            if string.find(label, "Wide sender", 1, true) == 1 then newestIndex = index end
            if label == "Sender 7" then olderIndex = index end
            if label == "Sender 3" then sixthSeen = true end
            if label == "Sender 2" then seventhSeen = true end
        end
        if notificationQueries ~= homeQueries or clipped < 3
            or newestIndex == nil or olderIndex == nil or newestIndex >= olderIndex
            or not sixthSeen or seventhSeen
            or rows[8].sender ~= originalValues[1]
            or rows[8].subject ~= originalValues[2]
            or rows[8].preview ~= originalValues[3] then
            error("Laptop composition, order, clipping, or detachment failed")
        end

        for _ = 1, 4 do host:onPointer(0.30, 0.50, true, false, 4) end
        if host.inboxScrollOffset ~= 2 then error("Laptop inbox clamp failed") end
        host:onPointer(0.30, 0.50, true, false, 5)
        if host.inboxScrollOffset ~= 1 then error("Laptop reverse scroll failed") end
        local before = #actions
        host:onPointer(0.20, 0.76, true, false, 1)
        host:onPointer(0.99, 0.99, false, true, 1)
        if #actions ~= before then error("Laptop release outside activated") end
        host:onPointer(0.20, 0.76, true, false, 2)
        host:onPointer(0.20, 0.76, false, true, 2)
        if #actions ~= before then error("Laptop secondary action activated") end
        host:onPointer(0.20, 0.76, true, false, 1)
        host:onPointer(0.20, 0.76, false, true, 1)
        if actions[#actions] ~= "communications.openMessage"
            or routeId ~= "messageDetail" or host.inboxScrollOffset ~= 0 then
            error("Laptop row action or route reset failed")
        end

        host:draw(); host:onPointer(0.30, 0.45, true, false, 4)
        if host.detailScrollOffset ~= 1 then error("Laptop detail scroll failed") end
        host:onPointer(0.36, 0.11, true, false, 1)
        host:onPointer(0.36, 0.11, false, true, 1)
        if actions[#actions] ~= "communications.markRead" or badge ~= 7 then
            error("Laptop mark-read action failed")
        end
        host:draw(); failAction = true
        host:onPointer(0.46, 0.11, true, false, 1)
        host:onPointer(0.46, 0.11, false, true, 1)
        if routeId ~= "messageDetail" then error("Laptop inferred navigation") end
        failAction = false
        host:onPointer(0.46, 0.11, true, false, 1)
        host:onPointer(0.46, 0.11, false, true, 1)
        if actions[#actions] ~= "communications.archive" or routeId ~= "inbox" then
            error("Laptop archive action failed")
        end

        local populated = rows
        rows, labels = {}, {}; host:update(500); host:draw()
        local emptySeen = false
        for _, label in ipairs(labels) do if label == "No messages" then emptySeen = true end end
        if not emptySeen then error("Laptop empty state missing") end
        rows = populated
        routeId, missing, labels = "messageDetail", true, {}
        host:update(500); host:draw()
        local missingSeen = false
        for _, label in ipairs(labels) do
            if label == "Message unavailable" then missingSeen = true end
        end
        if not missingSeen then error("Laptop missing-message state missing") end
        failModel = true; host:update(500)
        if not pcall(host.draw, host) then error("Laptop model failure escaped") end
        failModel = false

        host:draw(); failClose = true
        host:onPointer(0.28, 0.06, true, false, 1)
        host:onPointer(0.28, 0.06, false, true, 1)
        if activeAppId == nil then error("Laptop Home failure was not contained") end
        failClose = false
        host:onPointer(0.28, 0.06, true, false, 1)
        host:onPointer(0.28, 0.06, false, true, 1)
        if activeAppId ~= nil or closed[#closed] ~= "forge.communications" then
            error("Laptop Home did not close active app")
        end
        labels = {}; host:draw()
        local launcherSeen = false
        for _, label in ipairs(labels) do if label == "APPLICATIONS" then launcherSeen = true end end
        if not launcherSeen or host.inboxScrollOffset ~= 0
            or host.detailScrollOffset ~= 0 then error("Laptop Home reset failed") end

        activeAppId, routeId = "forge.other", "other"; host:draw()
        host:onPointer(0.28, 0.06, true, false, 1)
        host:onPointer(0.28, 0.06, false, true, 1)
        if closed[#closed] ~= "forge.other" then error("Laptop Home not reusable") end
        if host:shutdown() ~= Result.SUCCESS then error("Laptop shutdown failed") end
    end)

    drawFilledRect, renderText, setTextColor = originalDraw, originalText, originalColor
    createImageOverlay, renderOverlay = originalCreateImageOverlay,
        originalRenderOverlay
    setOverlayColor, delete = originalSetOverlayColor, originalDelete
    if not succeeded then
        FORGE.Logger:error(FORGE.Definitions.LogSource.TEST,
            "Laptop Communications presentation integration test failed: %s",
            FORGE.Logger:safeToString(failure, "<unknown>"))
        return false, failure
    end
    FORGE.Logger:info(FORGE.Definitions.LogSource.TEST,
        "Laptop Communications presentation integration test passed")
    return true
end
