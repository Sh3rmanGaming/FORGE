---=============================================================================
--- FORGE Communications Persistence
---
--- Owns Communications namespace registration and deterministic restoration.
---=============================================================================

FORGE.CommunicationsPersistence = {}

local Persistence = FORGE.CommunicationsPersistence
local Namespace = FORGE.Definitions.CommunicationsNamespace.STATE
local PlayerId = "player.local"
local SchemaVersion = 1
local MAX_RETAINED = 256

local function positiveInteger(value)
    return type(value) == "number"
        and value == value
        and value ~= math.huge
        and value ~= -math.huge
        and value >= 1
        and value == math.floor(value)
end

local function sequenceFromId(identifier)
    if type(identifier) ~= "string" then
        return nil
    end
    local digits = string.match(identifier, "^message%.(%d+)$")
    local sequence = digits ~= nil and tonumber(digits) or nil
    return positiveInteger(sequence) and sequence or nil
end

local function copyMetadata(value)
    if value == nil then
        return true, nil
    end
    return FORGE.CommunicationsValidation:copyControlledData(value)
end

local function validRecord(record)
    local Channel = FORGE.Definitions.MessageChannel
    local Priority = FORGE.Definitions.MessagePriority
    local validChannels = {
        [Channel.SYSTEM] = true,
        [Channel.MAIL] = true,
        [Channel.MESSAGE] = true
    }
    local validPriorities = {
        [Priority.NORMAL] = true,
        [Priority.IMPORTANT] = true
    }

    if type(record) ~= "table" or getmetatable(record) ~= nil
        or sequenceFromId(record.id) == nil
        or record.playerId ~= PlayerId
        or not FORGE.CommunicationsValidation:isIdentifier(record.source)
        or type(record.subject) ~= "string" or record.subject == ""
        or type(record.body) ~= "string"
        or not validChannels[record.channel]
        or not validPriorities[record.priority]
        or not positiveInteger(record.createdOrder)
        or type(record.read) ~= "boolean"
        or type(record.archived) ~= "boolean"
        or record.senderDisplayName ~= nil
            and (type(record.senderDisplayName) ~= "string"
                or record.senderDisplayName == "")
        or record.notificationId ~= nil
            and not FORGE.CommunicationsValidation:isIdentifier(
                record.notificationId) then
        return false, nil
    end

    local allowed = {
        id = true, playerId = true, source = true, subject = true,
        body = true, channel = true, priority = true,
        senderDisplayName = true, metadata = true, createdOrder = true,
        read = true, archived = true, notificationId = true
    }
    for key in pairs(record) do
        if not allowed[key] then
            return false, nil
        end
    end

    local metadataValid, metadata = copyMetadata(record.metadata)
    if not metadataValid then
        return false, nil
    end

    local copy = {
        id = record.id,
        playerId = PlayerId,
        source = record.source,
        subject = record.subject,
        body = record.body,
        channel = record.channel,
        priority = record.priority,
        createdOrder = record.createdOrder,
        read = record.read,
        archived = record.archived
    }
    if record.senderDisplayName ~= nil then
        copy.senderDisplayName = record.senderDisplayName
    end
    if metadata ~= nil then
        copy.metadata = metadata
    end
    if record.notificationId ~= nil then
        copy.notificationId = record.notificationId
    end
    return true, copy
end

function Persistence:registerNamespace()
    if not FORGE.StateStore:exists(Namespace) then
        if not FORGE.StateStore:register(Namespace)
            or not FORGE.StateStore:replaceNamespace(Namespace, {
                schemaVersion = SchemaVersion,
                players = {
                    [PlayerId] = {
                        messages = {},
                        messageNextSequence = 1
                    }
                }
            }) then
            return false
        end
    end

    if not FORGE.SaveManager:isNamespaceRegistered(Namespace)
        and not FORGE.SaveManager:registerNamespace(Namespace) then
        return false
    end
    return true
end

function Persistence:restore()
    local state, found = FORGE.StateStore:snapshot(Namespace)
    if not found or type(state) ~= "table" or getmetatable(state) ~= nil then
        return false
    end
    if state.schemaVersion ~= nil and state.schemaVersion ~= SchemaVersion then
        return false
    end

    state.schemaVersion = SchemaVersion
    state.players = type(state.players) == "table" and state.players or {}
    local player = type(state.players[PlayerId]) == "table"
        and state.players[PlayerId] or {}
    state.players[PlayerId] = player
    local source = type(player.messages) == "table" and player.messages or {}

    local candidates = {}
    local idCounts = {}
    local orderCounts = {}
    local discarded = 0
    local observedHighest = 0
    for mapKey, raw in pairs(source) do
        local valid, record = validRecord(raw)
        if valid then
            record._mapKeyMatches = mapKey == record.id
            candidates[#candidates + 1] = record
            idCounts[record.id] = (idCounts[record.id] or 0) + 1
            orderCounts[record.createdOrder] =
                (orderCounts[record.createdOrder] or 0) + 1
            observedHighest = math.max(
                observedHighest,
                record.createdOrder,
                sequenceFromId(record.id))
        else
            discarded = discarded + 1
        end
    end

    table.sort(candidates, function(left, right)
        if left.createdOrder ~= right.createdOrder then
            return left.createdOrder < right.createdOrder
        end
        return left.id < right.id
    end)

    local records = {}
    local survivors = {}
    for _, record in ipairs(candidates) do
        if record._mapKeyMatches
            and idCounts[record.id] == 1
            and orderCounts[record.createdOrder] == 1 then
            record._mapKeyMatches = nil
            records[record.id] = record
            survivors[#survivors + 1] = record
        else
            discarded = discarded + 1
        end
    end

    while #survivors > MAX_RETAINED do
        local reclaimIndex = nil
        for index, record in ipairs(survivors) do
            if record.archived then
                reclaimIndex = index
                break
            end
        end
        if reclaimIndex == nil then
            return false
        end
        records[survivors[reclaimIndex].id] = nil
        table.remove(survivors, reclaimIndex)
        discarded = discarded + 1
    end

    local nextSequence = player.messageNextSequence
    if not positiveInteger(nextSequence) or nextSequence <= observedHighest then
        nextSequence = observedHighest + 1
    end
    player.messages = records
    player.messageNextSequence = nextSequence

    if not FORGE.StateStore:replaceNamespace(Namespace, state) then
        return false
    end
    if discarded > 0 and FORGE.Logger:isDevelopmentMode() then
        FORGE.Logger:warning(
            "Communications",
            "Communications restoration discarded %d invalid or conflicting records",
            discarded)
    end
    return true
end
