---=============================================================================
--- FORGE Communications Application
---
--- Adapts authoritative Communications state into the bounded M3 application.
---
--- Responsibilities:
---     • Register the built-in Phone and Laptop application presentations.
---     • Produce detached inbox, detail, and badge models.
---     • Translate declared actions into Communications domain operations.
---     • Return declarative navigation without owning ForgeOS navigation.
---
--- This component must never render UI, own messages, or expose services.
---=============================================================================

FORGE.CommunicationsApp = {}

local App = FORGE.CommunicationsApp
local CommunicationsResult = FORGE.Definitions.CommunicationsResult
local AppId = FORGE.Definitions.CommunicationsAppId.COMMUNICATIONS
local DeviceId = FORGE.Definitions.DeviceId

local PHONE_PRESENTATION = "forge.communications.phone"
local LAPTOP_PRESENTATION = "forge.communications.laptop"
local INBOX_ROUTE = "inbox"
local DETAIL_ROUTE = "messageDetail"

local OPEN_MESSAGE = "communications.openMessage"
local MARK_READ = "communications.markRead"
local ARCHIVE = "communications.archive"
local OPEN_INBOX = "communications.openInbox"
local BACK = "communications.back"

local declaredActions = {
    [OPEN_MESSAGE] = true,
    [MARK_READ] = true,
    [ARCHIVE] = true,
    [OPEN_INBOX] = true,
    [BACK] = true
}

local provider = { protocolVersion = 1 }

local function hasOnly(value, allowed)
    if type(value) ~= "table"
        or getmetatable(value) ~= nil then
        return false
    end
    for key in pairs(value) do
        if type(key) ~= "string" or not allowed[key] then
            return false
        end
    end
    return true
end

local function noParameters(parameters)
    return hasOnly(parameters, {})
end

local function messageParameters(parameters)
    return hasOnly(parameters, { messageId = true })
        and FORGE.CommunicationsValidation:isIdentifier(
            parameters.messageId
        )
end

local function sender(record)
    return record.senderDisplayName or record.source
end

local function row(record)
    return {
        messageId = record.id,
        subject = record.subject,
        sender = sender(record),
        preview = record.body,
        channel = record.channel,
        priority = record.priority,
        unread = not record.read,
        archived = record.archived
    }
end

local function detail(record)
    return {
        messageId = record.id,
        subject = record.subject,
        sender = sender(record),
        body = record.body,
        channel = record.channel,
        priority = record.priority,
        unread = not record.read,
        archived = record.archived
    }
end

local function action(actionId, label, parameters)
    return {
        id = actionId,
        label = label,
        parameters = parameters or {}
    }
end

local function baseModel(context)
    return {
        modelVersion = 1,
        appId = AppId,
        presentationId = context.presentationId,
        routeId = context.routeId,
        title = "Communications",
        badgeCount = FORGE.Communications:getUnreadCount()
    }
end

local function inboxModel(context)
    local model = baseModel(context)
    local rows = {}
    local actions = {}
    for _, record in ipairs(FORGE.Communications:getMessages(false)) do
        rows[#rows + 1] = row(record)
        actions[#actions + 1] = action(
            OPEN_MESSAGE,
            "Open",
            { messageId = record.id }
        )
    end
    model.content = {
        kind = "communications.inbox",
        emptyText = "No messages",
        rows = rows
    }
    model.actions = actions
    return model
end

local function detailModel(context)
    local model = baseModel(context)
    local messageId = context.routeParameters.messageId
    local record = FORGE.Communications:getMessage(messageId)
    local actions = {
        action(OPEN_INBOX, "Inbox"),
        action(BACK, "Back")
    }
    if record ~= nil then
        if not record.read then
            actions[#actions + 1] = action(
                MARK_READ,
                "Mark read",
                { messageId = record.id }
            )
        end
        if not record.archived then
            actions[#actions + 1] = action(
                ARCHIVE,
                "Archive",
                { messageId = record.id }
            )
        end
    end
    model.content = {
        kind = "communications.messageDetail",
        message = record ~= nil and detail(record) or nil
    }
    model.actions = actions
    return model
end

function provider:getModel(context)
    if context.routeId == INBOX_ROUTE then
        return inboxModel(context)
    end
    return detailModel(context)
end

function provider:getBadge(_)
    return FORGE.Communications:getUnreadCount()
end

local function completed(domainResult, navigation)
    local outcome = {
        completed = domainResult == CommunicationsResult.SUCCESS,
        domainResult = domainResult
    }
    if navigation ~= nil then
        outcome.navigation = navigation
    end
    return outcome
end

function provider:performAction(context, actionId, parameters)
    if actionId == OPEN_MESSAGE then
        if context.routeId ~= INBOX_ROUTE
            or not messageParameters(parameters) then
            return completed(CommunicationsResult.INVALID_ARGUMENT)
        end
        if FORGE.Communications:getMessage(parameters.messageId) == nil then
            return completed(CommunicationsResult.NOT_FOUND)
        end
        return completed(CommunicationsResult.SUCCESS, {
            operation = "navigate",
            routeId = DETAIL_ROUTE,
            parameters = { messageId = parameters.messageId }
        })
    end

    if actionId == MARK_READ then
        if context.routeId ~= DETAIL_ROUTE
            or not messageParameters(parameters) then
            return completed(CommunicationsResult.INVALID_ARGUMENT)
        end
        return completed(
            FORGE.Communications:markMessageRead(parameters.messageId)
        )
    end

    if actionId == ARCHIVE then
        if context.routeId ~= DETAIL_ROUTE
            or not messageParameters(parameters) then
            return completed(CommunicationsResult.INVALID_ARGUMENT)
        end
        local result = FORGE.Communications:archiveMessage(
            parameters.messageId
        )
        return completed(
            result,
            result == CommunicationsResult.SUCCESS
                and { operation = "home" }
                or nil
        )
    end

    if actionId == OPEN_INBOX then
        if context.routeId ~= DETAIL_ROUTE
            or not noParameters(parameters) then
            return completed(CommunicationsResult.INVALID_ARGUMENT)
        end
        return completed(CommunicationsResult.SUCCESS, {
            operation = "home"
        })
    end

    if actionId == BACK then
        if context.routeId ~= DETAIL_ROUTE
            or not noParameters(parameters) then
            return completed(CommunicationsResult.INVALID_ARGUMENT)
        end
        return completed(CommunicationsResult.SUCCESS, {
            operation = "back"
        })
    end

    return completed(CommunicationsResult.INVALID_ARGUMENT)
end

local function presentation(identifier)
    return {
        id = identifier,
        controller = provider,
        defaultRoute = INBOX_ROUTE,
        routes = {
            [INBOX_ROUTE] = {},
            [DETAIL_ROUTE] = {}
        },
        actions = declaredActions
    }
end

function App:register()
    return FORGE.ForgeOS:registerApp({
        id = AppId,
        ownerId = "forge",
        apiVersion = FORGE.Definitions.ForgeOSVersion.APP_API,
        displayName = "Communications",
        supportedDevices = {
            [DeviceId.PHONE] = true,
            [DeviceId.LAPTOP] = true
        },
        presentations = {
            [DeviceId.PHONE] = presentation(PHONE_PRESENTATION),
            [DeviceId.LAPTOP] = presentation(LAPTOP_PRESENTATION)
        }
    })
end
