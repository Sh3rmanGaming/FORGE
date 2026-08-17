---=============================================================================
--- FORGE Communications Service
---
--- Owns the bounded authoritative received-message inbox.
---=============================================================================

FORGE.CommunicationsService = {}

local Service = FORGE.CommunicationsService
local Result = FORGE.Definitions.CommunicationsResult
local Event = FORGE.Definitions.CommunicationsEvent
local Namespace = FORGE.Definitions.CommunicationsNamespace.STATE
local PlayerId = "player.local"
local NotificationSource = "forge.communications"
local NotificationAppId = "forge.communications"
local NotificationRouteId = "messageDetail"
local MAX_RETAINED = 256
local available = false

local validChannels = {
    [FORGE.Definitions.MessageChannel.SYSTEM] = true,
    [FORGE.Definitions.MessageChannel.MAIL] = true,
    [FORGE.Definitions.MessageChannel.MESSAGE] = true
}
local validPriorities = {
    [FORGE.Definitions.MessagePriority.NORMAL] = true,
    [FORGE.Definitions.MessagePriority.IMPORTANT] = true
}

local function positiveInteger(value)
    return type(value) == "number" and value >= 1
        and value == math.floor(value)
end

local function statePlayer()
    local state, found = FORGE.StateStore:snapshot(Namespace)
    if not found or type(state.players) ~= "table"
        or type(state.players[PlayerId]) ~= "table" then
        return nil, nil
    end
    return state, state.players[PlayerId]
end

local function copyRecord(record)
    local valid, copy =
        FORGE.CommunicationsValidation:copyControlledData(record)
    return valid and copy or nil
end

local function validateNotification(request)
    if request == nil then
        return true
    end
    if type(request) ~= "table" or getmetatable(request) ~= nil then
        return false
    end
    local allowed = {
        title = true, body = true, severity = true,
        persistence = true, targetDevices = true
    }
    for key in pairs(request) do
        if not allowed[key] then
            return false
        end
    end
    local validSeverity = {
        [FORGE.Definitions.NotificationSeverity.INFO] = true,
        [FORGE.Definitions.NotificationSeverity.SUCCESS] = true,
        [FORGE.Definitions.NotificationSeverity.WARNING] = true,
        [FORGE.Definitions.NotificationSeverity.ERROR] = true,
        [FORGE.Definitions.NotificationSeverity.CRITICAL] = true
    }
    if request.title ~= nil and type(request.title) ~= "string"
        or request.body ~= nil and type(request.body) ~= "string"
        or not validSeverity[request.severity]
        or request.persistence
            ~= FORGE.Definitions.NotificationPersistence.SAVEGAME
        or type(request.targetDevices) ~= "table"
        or getmetatable(request.targetDevices) ~= nil then
        return false
    end
    local targets = 0
    for deviceId, selected in pairs(request.targetDevices) do
        if not FORGE.CommunicationsValidation:isIdentifier(deviceId)
            or selected ~= true then
            return false
        end
        targets = targets + 1
    end
    if targets == 0 then
        return false
    end
    local valid, copy =
        FORGE.CommunicationsValidation:copyControlledData(request)
    return valid, copy
end

local function validateDefinition(definition)
    if type(definition) ~= "table" then
        return Result.INVALID_ARGUMENT, nil
    end
    if getmetatable(definition) ~= nil then
        return Result.INVALID_DEFINITION, nil
    end
    local priority = definition.priority
        or FORGE.Definitions.MessagePriority.NORMAL
    if not FORGE.CommunicationsValidation:isIdentifier(definition.source)
        or type(definition.subject) ~= "string" or definition.subject == ""
        or type(definition.body) ~= "string"
        or not validChannels[definition.channel]
        or definition.recipient ~= PlayerId
        or not validPriorities[priority]
        or definition.senderDisplayName ~= nil
            and (type(definition.senderDisplayName) ~= "string"
                or definition.senderDisplayName == "") then
        return Result.INVALID_DEFINITION, nil
    end
    local metadataValid, metadata = true, nil
    if definition.metadata ~= nil then
        metadataValid, metadata =
            FORGE.CommunicationsValidation:copyControlledData(
                definition.metadata)
    end
    local notificationValid, notification =
        validateNotification(definition.notification)
    if not metadataValid or not notificationValid then
        return Result.INVALID_DEFINITION, nil
    end

    local normalized = {
        source = definition.source,
        subject = definition.subject,
        body = definition.body,
        channel = definition.channel,
        recipient = PlayerId,
        priority = priority,
        metadata = metadata,
        notification = notification
    }
    if definition.senderDisplayName ~= nil then
        normalized.senderDisplayName = definition.senderDisplayName
    end
    return Result.SUCCESS, normalized
end

local function ordered(records)
    local values = {}
    for _, record in pairs(records or {}) do
        values[#values + 1] = record
    end
    table.sort(values, function(left, right)
        if left.createdOrder ~= right.createdOrder then
            return left.createdOrder < right.createdOrder
        end
        return left.id < right.id
    end)
    return values
end

local function createMessage(definition)
    local validationResult, normalized = validateDefinition(definition)
    if validationResult ~= Result.SUCCESS then
        return validationResult, nil
    end
    if not available then
        return Result.NOT_AVAILABLE, nil
    end

    local state, player = statePlayer()
    if state == nil then
        return Result.STATE_ERROR, nil
    end
    local messages = player.messages
    local values = ordered(messages)
    if #values >= MAX_RETAINED then
        local reclaimId = nil
        for _, record in ipairs(values) do
            if record.archived then
                reclaimId = record.id
                break
            end
        end
        if reclaimId == nil then
            return Result.CAPACITY_EXHAUSTED, nil
        end
        messages[reclaimId] = nil
    end

    local sequence = player.messageNextSequence
    if not positiveInteger(sequence) then
        return Result.STATE_ERROR, nil
    end
    local identifier = "message." .. tostring(sequence)
    local record = {
        id = identifier,
        playerId = PlayerId,
        source = normalized.source,
        subject = normalized.subject,
        body = normalized.body,
        channel = normalized.channel,
        priority = normalized.priority,
        createdOrder = sequence,
        read = false,
        archived = false
    }
    if normalized.senderDisplayName ~= nil then
        record.senderDisplayName = normalized.senderDisplayName
    end
    if normalized.metadata ~= nil then
        record.metadata = normalized.metadata
    end
    messages[identifier] = record
    player.messageNextSequence = sequence + 1
    if not FORGE.StateStore:replaceNamespace(Namespace, state) then
        return Result.STATE_ERROR, nil
    end

    local detail = nil
    if normalized.notification ~= nil then
        local request = normalized.notification
        local notificationCall = {
            pcall(FORGE.ForgeOS.createNotification, FORGE.ForgeOS, {
                source = NotificationSource,
                title = request.title ~= nil
                    and request.title or record.subject,
                body = request.body ~= nil and request.body or "",
                severity = request.severity,
                persistence = request.persistence,
                targetDevices = request.targetDevices,
                route = {
                    appId = NotificationAppId,
                    routeId = NotificationRouteId,
                    parameters = { messageId = identifier }
                },
                metadata = { communicationsMessageId = identifier }
            })
        }
        local notificationResult = notificationCall[1]
            and notificationCall[2]
            or FORGE.Definitions.ForgeOSResult.INTERNAL_ERROR
        local notificationId = notificationCall[1]
            and notificationCall[3] or nil
        detail = {
            notificationResult = notificationResult,
            notificationId = notificationId
        }
        if notificationResult ~= FORGE.Definitions.ForgeOSResult.SUCCESS
            or notificationId == nil then
            detail.notificationId = nil
            detail.integrationResult = Result.NOTIFICATION_CREATION_FAILED
        else
            local linkState, linkPlayer = statePlayer()
            local linked = linkState ~= nil
                and linkPlayer.messages[identifier] ~= nil
            if linked then
                linkPlayer.messages[identifier].notificationId = notificationId
                linked = FORGE.StateStore:replaceNamespace(
                    Namespace, linkState)
            end
            if not linked then
                detail.integrationResult = Result.NOTIFICATION_LINKAGE_FAILED
                FORGE.Logger:warning(
                    FORGE.Definitions.LogSource.COMMUNICATIONS,
                    "Notification linkage failed for message %s and notification %s",
                    identifier,
                    notificationId)
            end
        end
    end

    FORGE.EventBus:publish(Event.MESSAGE_CREATED, {
        playerId = PlayerId,
        messageId = identifier
    })
    return Result.SUCCESS, identifier, detail
end

local function propagateNotificationRead(identifier, notificationId)
    local ForgeResult = FORGE.Definitions.ForgeOSResult
    local call = {
        pcall(FORGE.ForgeOS.markNotificationRead,
            FORGE.ForgeOS, notificationId)
    }
    local notificationResult = call[1]
        and call[2] or ForgeResult.INTERNAL_ERROR
    if notificationResult ~= ForgeResult.SUCCESS
        and notificationResult ~= ForgeResult.NOT_REGISTERED then
        FORGE.Logger:warning(
            FORGE.Definitions.LogSource.COMMUNICATIONS,
            "Notification read propagation failed for message %s, notification %s: %s",
            identifier,
            notificationId,
            FORGE.Logger:safeToString(
                notificationResult, "<unknown result>"))
    end
end

local function mutateMessage(identifier, field, eventId, propagateRead)
    if not FORGE.CommunicationsValidation:isIdentifier(identifier) then
        return Result.INVALID_ARGUMENT
    end
    if not available then
        return Result.NOT_AVAILABLE
    end
    local state, player = statePlayer()
    if state == nil then
        return Result.STATE_ERROR
    end
    local record = player.messages[identifier]
    if record == nil then
        return Result.NOT_FOUND
    end
    if record[field] then
        return Result.SUCCESS
    end
    record[field] = true
    if not FORGE.StateStore:replaceNamespace(Namespace, state) then
        return Result.STATE_ERROR
    end
    if propagateRead and record.notificationId ~= nil then
        propagateNotificationRead(identifier, record.notificationId)
    end
    FORGE.EventBus:publish(eventId, {
        playerId = PlayerId,
        messageId = identifier,
        [field] = true
    })
    return Result.SUCCESS
end

local function runOperation(operation, ...)
    local call = { pcall(operation, ...) }
    if not call[1] then
        FORGE.Logger:error(
            "Communications",
            "Unexpected Communications Service failure: %s",
            FORGE.Logger:safeToString(call[2], "<unprintable error>"))
        return Result.INTERNAL_ERROR, nil
    end
    return call[2], call[3], call[4]
end

function Service:setAvailable(value)
    available = value == true
end

function Service:isAvailable()
    return available
end

function Service:createMessage(definition)
    return runOperation(createMessage, definition)
end

function Service:markMessageRead(identifier)
    return runOperation(
        mutateMessage, identifier, "read", Event.MESSAGE_READ, true)
end

function Service:archiveMessage(identifier)
    return runOperation(
        mutateMessage, identifier, "archived", Event.MESSAGE_ARCHIVED)
end

function Service:getMessage(identifier)
    local call = { pcall(function()
        if not available
            or not FORGE.CommunicationsValidation:isIdentifier(identifier) then
            return nil
        end
        local _, player = statePlayer()
        return player ~= nil and copyRecord(player.messages[identifier]) or nil
    end) }
    if not call[1] then
        FORGE.Logger:error("Communications",
            "Unexpected Communications query failure: %s",
            FORGE.Logger:safeToString(call[2], "<unprintable error>"))
        return nil
    end
    return call[2]
end

function Service:getMessages(includeArchived)
    local call = { pcall(function()
        if not available
            or includeArchived ~= nil
                and type(includeArchived) ~= "boolean" then
            return {}
        end
        local _, player = statePlayer()
        if player == nil then
            return {}
        end
        local result = {}
        for _, record in ipairs(ordered(player.messages)) do
            if includeArchived == true or not record.archived then
                result[#result + 1] = copyRecord(record)
            end
        end
        return result
    end) }
    if not call[1] then
        FORGE.Logger:error("Communications",
            "Unexpected Communications query failure: %s",
            FORGE.Logger:safeToString(call[2], "<unprintable error>"))
        return {}
    end
    return call[2]
end

function Service:getUnreadCount()
    local call = { pcall(function()
        if not available then
            return 0
        end
        local _, player = statePlayer()
        if player == nil then
            return 0
        end
        local count = 0
        for _, record in pairs(player.messages) do
            if not record.read and not record.archived then
                count = count + 1
            end
        end
        return count
    end) }
    if not call[1] then
        FORGE.Logger:error("Communications",
            "Unexpected Communications query failure: %s",
            FORGE.Logger:safeToString(call[2], "<unprintable error>"))
        return 0
    end
    return call[2]
end

function Service:clearRuntimeState()
    available = false
    return Result.SUCCESS
end
