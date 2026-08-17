---=============================================================================
--- FORGE Phone Communications Presentation Integration Tests
---=============================================================================

FORGE.Tests = FORGE.Tests or {}

function FORGE.Tests.runPhoneCommunicationsPresentationIntegrationTests()
    FORGE.Logger:info(FORGE.Definitions.LogSource.TEST,
        "Phone Communications presentation integration test started")

    local Result = FORGE.Definitions.ForgeOSResult
    local Visibility = FORGE.Definitions.DeviceVisibility
    local activeAppId = nil
    local routeId = nil
    local badge = 6
    local labels = {}
    local sequence = {}
    local actions = {}
    local notificationsQueried = 0
    local failModel = false
    local failAction = false
    local failClose = false
    local closeCalls = 0
    local closedAppIds = {}
    local rows = {}
    for index = 1, 6 do
        rows[index] = {
            messageId = "message." .. tostring(index),
            subject = index == 6
                and "A subject long enough to require deterministic clipping"
                or "Subject " .. tostring(index),
            sender = index == 6
                and "A sender name that is wider than the Phone row"
                or "Sender " .. tostring(index),
            preview = index == 6
                and "A preview body that is deliberately longer than two Phone visual lines and must be clipped without changing this model value."
                or "Preview " .. tostring(index),
            channel = "mail", priority = "normal",
            unread = true, archived = false
        }
    end
    local originalNewestSubject = rows[6].subject
    local originalNewestPreview = rows[6].preview

    local function inboxModel()
        local modelActions = {}
        for _, row in ipairs(rows) do
            modelActions[#modelActions + 1] = {
                id = "communications.openMessage", label = "Open",
                parameters = { messageId = row.messageId }
            }
        end
        return {
            modelVersion = 1, appId = "forge.communications",
            presentationId = "forge.communications.phone",
            routeId = "inbox", title = "Communications",
            badgeCount = badge,
            content = { kind = "communications.inbox",
                emptyText = "No messages", rows = rows },
            actions = modelActions
        }
    end

    local function detailModel(message)
        local modelActions = {
            { id = "communications.openInbox", label = "Inbox", parameters = {} },
            { id = "communications.back", label = "Back", parameters = {} }
        }
        if message ~= nil then
            modelActions[#modelActions + 1] = {
                id = "communications.markRead", label = "Mark read",
                parameters = { messageId = message.messageId }
            }
            modelActions[#modelActions + 1] = {
                id = "communications.archive", label = "Archive",
                parameters = { messageId = message.messageId }
            }
        end
        return {
            modelVersion = 1, appId = "forge.communications",
            presentationId = "forge.communications.phone",
            routeId = "messageDetail", title = "Communications",
            badgeCount = badge,
            content = { kind = "communications.messageDetail", message = message },
            actions = modelActions
        }
    end

    local selected = {
        messageId = "message.6", subject = "Selected subject",
        sender = "Selected sender",
        body = string.rep("Complete detail body remains authoritative. ", 12),
        channel = "mail", priority = "normal", unread = true, archived = false
    }
    local missing = false
    local context = {
        getVisibility = function() return Visibility.VISIBLE end,
        show = function() return Result.SUCCESS end,
        hide = function() return Result.SUCCESS end,
        getActiveAppId = function() return activeAppId end,
        getRegisteredAppIds = function()
            return { "forge.communications" }
        end,
        getAppDefinition = function()
            return { id = "forge.communications", displayName = "Communications",
                supportedDevices = { phone = true } }
        end,
        resolvePresentation = function()
            return Result.SUCCESS,
                { presentationId = "forge.communications.phone" }
        end,
        getCurrentRoute = function() return routeId end,
        getValidatedResumeDestination = function()
            return Result.SUCCESS, nil
        end,
        openApp = function(appId)
            sequence[#sequence + 1] = "open:" .. appId
            return Result.SUCCESS
        end,
        activateApp = function(appId)
            sequence[#sequence + 1] = "activate:" .. appId
            activeAppId = appId
            return Result.SUCCESS
        end,
        navigate = function(appId, destination, parameters)
            sequence[#sequence + 1] = "navigate:" .. appId .. ":" .. destination
            routeId = destination
            return parameters ~= nil and Result.SUCCESS or Result.INTERNAL_ERROR
        end,
        closeApp = function(appId)
            closeCalls = closeCalls + 1
            if failClose then return Result.STATE_ERROR end
            closedAppIds[#closedAppIds + 1] = appId
            activeAppId = nil
            routeId = nil
            return Result.SUCCESS
        end,
        getApplicationPresentationModel = function()
            if failModel then return nil end
            if routeId == "inbox" then return inboxModel() end
            local message = selected
            if missing then
                message = nil
            end
            return detailModel(message)
        end,
        performApplicationAction = function(_, actionId, parameters)
            actions[#actions + 1] = actionId
            if failAction then return Result.STATE_ERROR, nil end
            if actionId == "communications.openMessage" then
                routeId = "messageDetail"
            elseif actionId == "communications.markRead" then
                selected.unread = false
                badge = badge - 1
            elseif actionId == "communications.archive"
                or actionId == "communications.openInbox"
                or actionId == "communications.back" then
                routeId = "inbox"
            end
            return Result.SUCCESS, {
                completed = parameters ~= nil, domainResult = "success"
            }
        end,
        getApplicationBadge = function() return badge end,
        getNotifications = function()
            notificationsQueried = notificationsQueried + 1
            return {}
        end,
        markNotificationRead = function() return Result.SUCCESS end,
        dismissNotification = function() return Result.SUCCESS end,
        isUiBlocked = function() return false end
    }

    local originalDrawFilledRect = drawFilledRect
    local originalRenderText = renderText
    local originalSetTextColor = setTextColor
    local originalCreateImageOverlay = createImageOverlay
    local originalRenderOverlay = renderOverlay
    local originalSetOverlayColor = setOverlayColor
    local originalDelete = delete
    drawFilledRect = function() end
    renderText = function(_, _, _, text) labels[#labels + 1] = text end
    setTextColor = function() end
    createImageOverlay = function() return 100 end
    renderOverlay = function() end
    setOverlayColor = function() end
    delete = function() end

    local succeeded, failure = pcall(function()
        local host = FORGE.PhoneHost.create(context)
        if host:initialize() ~= Result.SUCCESS then
            error("Phone Communications Host initialization failed")
        end

        host:draw()
        local notificationsAtHome = notificationsQueried
        local badgeSeen = false
        for _, label in ipairs(labels) do
            if label == "6" then badgeSeen = true end
        end
        if not badgeSeen then error("Exact launcher badge was not rendered") end

        if not host:onPointer(0.73, 0.56, true, false, 1)
            or #sequence ~= 0
            or not host:onPointer(0.73, 0.56, false, true, 1)
            or sequence[1] ~= "open:forge.communications"
            or sequence[2] ~= "activate:forge.communications"
            or sequence[3] ~= "navigate:forge.communications:inbox" then
            error("Launcher release activation sequence failed")
        end

        labels = {}
        host:draw()
        if notificationsQueried ~= notificationsAtHome
            or rows[6].subject ~= originalNewestSubject
            or rows[6].preview ~= originalNewestPreview then
            error("Active composition or model immutability failed")
        end
        local clipped = 0
        local newestIndex = nil
        local olderIndex = nil
        for index, label in ipairs(labels) do
            if string.find(label, "%.%.%.") ~= nil then clipped = clipped + 1 end
            if string.find(label, "A sender name", 1, true) == 1 then
                newestIndex = index
            elseif label == "Sender 5" then
                olderIndex = index
            end
        end
        if clipped < 3 or newestIndex == nil or olderIndex == nil
            or newestIndex >= olderIndex then
            error("Newest-first ordering or deterministic clipping failed")
        end

        host:onPointer(0.80, 0.50, true, false, 4)
        host:onPointer(0.80, 0.50, true, false, 4)
        host:onPointer(0.80, 0.50, true, false, 4)
        if host.inboxScrollOffset ~= 2 then
            error("Inbox scroll clamp failed")
        end
        host:onPointer(0.80, 0.50, true, false, 5)
        if host.inboxScrollOffset ~= 1 then
            error("Inbox reverse scrolling failed")
        end

        local beforeActions = #actions
        host:onPointer(0.73, 0.67, true, false, 1)
        host:onPointer(0.60, 0.67, false, true, 1)
        if #actions ~= beforeActions then
            error("Release outside did not cancel activation")
        end
        host:onPointer(0.73, 0.67, true, false, 2)
        host:onPointer(0.73, 0.60, false, true, 2)
        if #actions ~= beforeActions then
            error("Secondary pointer activated Communications control")
        end
        host:onPointer(0.73, 0.60, true, false, 1)
        host:onPointer(0.73, 0.60, false, true, 1)
        if actions[#actions] ~= "communications.openMessage"
            or routeId ~= "messageDetail"
            or host.inboxScrollOffset ~= 0 then
            error("Inbox row action or route reset failed")
        end

        host:draw()
        host:onPointer(0.80, 0.50, true, false, 4)
        if host.detailScrollOffset ~= 1 then
            error("Detail body scrolling failed")
        end
        host:onPointer(0.73, 0.33, true, false, 1)
        host:onPointer(0.73, 0.33, false, true, 1)
        if actions[#actions] ~= "communications.markRead" or badge ~= 5 then
            error("Mark-read action or badge refresh failed")
        end

        host:draw()
        failAction = true
        host:onPointer(0.84, 0.33, true, false, 1)
        host:onPointer(0.84, 0.33, false, true, 1)
        if routeId ~= "messageDetail" then
            error("Adapter failure inferred navigation")
        end
        failAction = false
        host:onPointer(0.84, 0.33, true, false, 1)
        host:onPointer(0.84, 0.33, false, true, 1)
        if actions[#actions] ~= "communications.archive" or routeId ~= "inbox" then
            error("Archive action did not follow adapter navigation")
        end

        local populatedRows = rows
        rows = {}
        labels = {}
        host:update(500)
        host:draw()
        local emptySeen = false
        for _, label in ipairs(labels) do
            if label == "No messages" then emptySeen = true end
        end
        if not emptySeen then error("Empty inbox state was not rendered") end
        rows = populatedRows

        routeId = "messageDetail"
        missing = true
        host:update(500)
        labels = {}
        host:draw()
        local missingSeen = false
        for _, label in ipairs(labels) do
            if label == "Message unavailable" then missingSeen = true end
        end
        if not missingSeen then error("Missing-message state was not rendered") end

        failModel = true
        host:update(500)
        if not pcall(host.draw, host) then
            error("Model acquisition failure escaped Host containment")
        end
        failModel = false

        host:draw()
        local callsBeforeHome = closeCalls
        host:onPointer(0.82, 0.14, true, false, 1)
        host:onPointer(0.60, 0.14, false, true, 1)
        if closeCalls ~= callsBeforeHome or activeAppId == nil then
            error("Phone Home release-outside cancellation failed")
        end
        failClose = true
        host:onPointer(0.82, 0.14, true, false, 1)
        host:onPointer(0.82, 0.14, false, true, 1)
        if closeCalls ~= callsBeforeHome + 1 or activeAppId == nil then
            error("Phone Home lifecycle failure was not contained")
        end
        failClose = false
        host:onPointer(0.82, 0.14, true, false, 1)
        host:onPointer(0.82, 0.14, false, true, 1)
        if closeCalls ~= callsBeforeHome + 2 or activeAppId ~= nil
            or closedAppIds[#closedAppIds] ~= "forge.communications" then
            error("Phone Home did not close Communications")
        end
        labels = {}
        host:draw()
        local launcherSeen = false
        for _, label in ipairs(labels) do
            if label == "APPLICATIONS" then launcherSeen = true end
        end
        if not launcherSeen then
            error("Phone Home did not restore the launcher")
        end
        activeAppId = "forge.other"
        routeId = "otherRoute"
        host:draw()
        host:onPointer(0.82, 0.14, true, false, 1)
        host:onPointer(0.82, 0.14, false, true, 1)
        if activeAppId ~= nil
            or closedAppIds[#closedAppIds] ~= "forge.other" then
            error("Phone Home was not reusable for another active app")
        end
        if host.inboxScrollOffset ~= 0 or host.detailScrollOffset ~= 0
            or host:shutdown() ~= Result.SUCCESS then
            error("Communications close/restart scroll reset failed")
        end
    end)

    drawFilledRect = originalDrawFilledRect
    renderText = originalRenderText
    setTextColor = originalSetTextColor
    createImageOverlay = originalCreateImageOverlay
    renderOverlay = originalRenderOverlay
    setOverlayColor = originalSetOverlayColor
    delete = originalDelete
    if not succeeded then
        FORGE.Logger:error(FORGE.Definitions.LogSource.TEST,
            "Phone Communications presentation integration test failed: %s",
            FORGE.Logger:safeToString(failure, "<unknown>"))
        return false, failure
    end
    FORGE.Logger:info(FORGE.Definitions.LogSource.TEST,
        "Phone Communications presentation integration test passed")
    return true
end
