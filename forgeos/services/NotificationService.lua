---=============================================================================
--- FORGE ForgeOS Notification Service
---
--- Owns local-player notification delivery records and their state.
---
--- Responsibilities:
---     • Generate monotonic notification identifiers.
---     • Maintain bounded session and savegame notification records.
---     • Validate, repair, query, read, and dismiss detached records.
---     • Publish completed notification events.
---
--- This service must never own gameplay facts, rendering, or navigation.
---=============================================================================

FORGE.NotificationService = {}

local Service = FORGE.NotificationService
local Result = FORGE.Definitions.ForgeOSResult
local Phase = FORGE.Definitions.ForgeOSPhase
local Persistence = FORGE.Definitions.NotificationPersistence
local Severity = FORGE.Definitions.NotificationSeverity
local Event = FORGE.Definitions.ForgeOSEvent
local PlayerId = FORGE.Definitions.ForgeOSPlayerId.LOCAL
local Namespace = FORGE.Definitions.ForgeOSNamespace.OS
local MAX_RETAINED = 256

local sessionRecords = {}
local repaired = false
local repairFailed = false

local validSeverity = {
    [Severity.INFO] = true,
    [Severity.SUCCESS] = true,
    [Severity.WARNING] = true,
    [Severity.ERROR] = true,
    [Severity.CRITICAL] = true
}

local validPersistence = {
    [Persistence.TRANSIENT] = true,
    [Persistence.SESSION] = true,
    [Persistence.SAVEGAME] = true
}

local function isIdentifier(value)
    return type(value) == "string"
        and value ~= ""
        and string.find(value, "%s") == nil
end

local function isPositiveInteger(value)
    return type(value) == "number"
        and value == value
        and value ~= math.huge
        and value ~= -math.huge
        and value >= 1
        and value == math.floor(value)
end

local function copyPlain(value, visited)
    local valueType = type(value)
    if valueType == "string" or valueType == "boolean" then
        return true, value
    end
    if valueType == "number" then
        return value == value
            and value ~= math.huge
            and value ~= -math.huge,
            value
    end
    if valueType ~= "table"
        or getmetatable(value) ~= nil
        or visited[value] then
        return false, nil
    end

    visited[value] = true
    local copy = {}
    for key, nested in pairs(value) do
        if type(key) ~= "string" then
            return false, nil
        end
        local valid, nestedCopy = copyPlain(nested, visited)
        if not valid then
            return false, nil
        end
        copy[key] = nestedCopy
    end
    return true, copy
end

local function detached(value)
    if value == nil then
        return true, nil
    end
    return copyPlain(value, {})
end

local function getState()
    local state, found = FORGE.StateStore:snapshot(Namespace)
    if not found or type(state.players) ~= "table"
        or type(state.players[PlayerId]) ~= "table" then
        return nil, nil
    end
    return state, state.players[PlayerId]
end

local function recordSequence(identifier)
    if type(identifier) ~= "string" then
        return nil
    end
    local value = string.match(identifier, "^notification%.(%d+)$")
    local number = value ~= nil and tonumber(value) or nil
    return isPositiveInteger(number) and number or nil
end

local function validateTargets(targets, requireRegistration)
    if type(targets) ~= "table"
        or getmetatable(targets) ~= nil then
        return false, nil
    end
    local copy = {}
    local count = 0
    for deviceId, selected in pairs(targets) do
        if not isIdentifier(deviceId) or selected ~= true then
            return false, nil
        end
        if requireRegistration
            and not FORGE.DeviceRegistry:isDeviceRegistered(deviceId) then
            return false, nil
        end
        copy[deviceId] = true
        count = count + 1
    end
    return count > 0, copy
end

local function validateRoute(route)
    if route == nil then
        return true, nil
    end
    if type(route) ~= "table" or getmetatable(route) ~= nil
        or not isIdentifier(route.appId)
        or not isIdentifier(route.routeId) then
        return false, nil
    end
    for key in pairs(route) do
        if key ~= "appId" and key ~= "routeId"
            and key ~= "parameters" then
            return false, nil
        end
    end
    local valid, parameters = detached(route.parameters or {})
    if not valid then
        return false, nil
    end
    return true, {
        appId = route.appId,
        routeId = route.routeId,
        parameters = parameters
    }
end

local function validateDefinition(definition, requireRegistration)
    if type(definition) ~= "table" then
        return Result.INVALID_ARGUMENT, nil
    end
    if getmetatable(definition) ~= nil then
        return Result.INVALID_DEFINITION, nil
    end
    if not isIdentifier(definition.source)
        or type(definition.title) ~= "string"
        or type(definition.body) ~= "string"
        or not validSeverity[definition.severity]
        or not validPersistence[definition.persistence] then
        return Result.INVALID_DEFINITION, nil
    end
    local targetsValid, targets = validateTargets(
        definition.targetDevices,
        requireRegistration
    )
    if not targetsValid then
        return requireRegistration
            and Result.NOT_REGISTERED
            or Result.INVALID_DEFINITION,
            nil
    end
    local routeValid, route = validateRoute(definition.route)
    local metadataValid, metadata = detached(definition.metadata)
    if not routeValid or not metadataValid then
        return Result.INVALID_DEFINITION, nil
    end
    return Result.SUCCESS, {
        source = definition.source,
        title = definition.title,
        body = definition.body,
        severity = definition.severity,
        persistence = definition.persistence,
        targetDevices = targets,
        route = route,
        metadata = metadata
    }
end

local function failRepair(reason)
    if not repairFailed then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.NOTIFICATION,
            "Notification restoration failed: %s",
            reason
        )
    end
    repaired = true
    repairFailed = true
    return false
end

local function validateRestoredRecord(record)
    if type(record) ~= "table" or getmetatable(record) ~= nil
        or not isIdentifier(record.id)
        or recordSequence(record.id) == nil
        or record.playerId ~= PlayerId
        or not isIdentifier(record.source)
        or type(record.title) ~= "string"
        or type(record.body) ~= "string"
        or not validSeverity[record.severity]
        or record.persistence ~= Persistence.SAVEGAME
        or not isPositiveInteger(record.createdOrder)
        or type(record.read) ~= "boolean"
        or type(record.dismissed) ~= "boolean" then
        return false, nil
    end
    local allowed = {
        id = true, playerId = true, source = true, title = true,
        body = true, severity = true, persistence = true,
        targetDevices = true, route = true, metadata = true,
        createdOrder = true, read = true, dismissed = true
    }
    for key in pairs(record) do
        if not allowed[key] then
            return false, nil
        end
    end
    local targetsValid, targets = validateTargets(record.targetDevices, true)
    local routeValid, route = validateRoute(record.route)
    local metadataValid, metadata = detached(record.metadata)
    if not targetsValid or not routeValid or not metadataValid then
        return false, nil
    end
    return true, {
        id = record.id,
        playerId = PlayerId,
        source = record.source,
        title = record.title,
        body = record.body,
        severity = record.severity,
        persistence = Persistence.SAVEGAME,
        targetDevices = targets,
        route = route,
        metadata = metadata,
        createdOrder = record.createdOrder,
        read = record.read,
        dismissed = record.dismissed
    }
end

local function ensureRepaired()
    if repaired then
        return not repairFailed
    end
    local state, player = getState()
    if state == nil then
        return failRepair("ForgeOS state is unavailable")
    end

    local source = type(player.notifications) == "table"
        and player.notifications or {}
    local candidates = {}
    local idCounts = {}
    local orderCounts = {}
    local discarded = 0
    local observedHighest = 0
    for _, raw in pairs(source) do
        local valid, record = validateRestoredRecord(raw)
        if valid then
            candidates[#candidates + 1] = record
            idCounts[record.id] = (idCounts[record.id] or 0) + 1
            orderCounts[record.createdOrder] =
                (orderCounts[record.createdOrder] or 0) + 1
            observedHighest = math.max(
                observedHighest,
                record.createdOrder,
                recordSequence(record.id)
            )
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
    for _, record in ipairs(candidates) do
        if idCounts[record.id] == 1
            and orderCounts[record.createdOrder] == 1 then
            records[record.id] = record
        else
            discarded = discarded + 1
        end
    end

    local survivors = {}
    for _, record in pairs(records) do
        survivors[#survivors + 1] = record
    end
    table.sort(survivors, function(left, right)
        return left.createdOrder < right.createdOrder
    end)
    while #survivors > MAX_RETAINED do
        local reclaimIndex = nil
        for index, record in ipairs(survivors) do
            if record.dismissed then
                reclaimIndex = index
                break
            end
        end
        if reclaimIndex == nil then
            for index, record in ipairs(survivors) do
                if record.read then
                    reclaimIndex = index
                    break
                end
            end
        end
        if reclaimIndex == nil then
            return failRepair(
                "retained state exceeds capacity without a safe reclamation"
            )
        end
        records[survivors[reclaimIndex].id] = nil
        table.remove(survivors, reclaimIndex)
        discarded = discarded + 1
    end

    local nextSequence = player.notificationNextSequence
    if not isPositiveInteger(nextSequence) then
        nextSequence = observedHighest + 1
    elseif nextSequence <= observedHighest then
        nextSequence = observedHighest + 1
    end
    player.notifications = records
    player.notificationNextSequence = nextSequence
    if not FORGE.StateStore:replaceNamespace(Namespace, state) then
        return failRepair("State Store replacement was rejected")
    end

    repaired = true
    repairFailed = false
    if discarded > 0 and FORGE.Logger:isDevelopmentMode() then
        FORGE.Logger:warning(
            FORGE.Definitions.LogSource.NOTIFICATION,
            "Notification restoration discarded %d invalid or conflicting records",
            discarded
        )
    end
    return true
end

local function orderedRecords(saveRecords, sessions)
    local values = {}
    for _, record in pairs(saveRecords or {}) do
        values[#values + 1] = record
    end
    for _, record in pairs(sessions or {}) do
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

local function chooseReclamation(records)
    local dismissedId = nil
    local readId = nil
    for _, record in ipairs(records) do
        if record.dismissed and dismissedId == nil then
            dismissedId = record.id
        elseif record.read and readId == nil then
            readId = record.id
        end
    end
    return dismissedId or readId
end

local function copyRecord(record)
    local valid, copy = detached(record)
    return valid and copy or nil
end

local function publish(eventId, payload)
    FORGE.EventBus:publish(eventId, payload)
end

local function createNotification(definition)
    local structuralResult, normalized = validateDefinition(definition, false)
    if structuralResult ~= Result.SUCCESS then
        return structuralResult, nil
    end
    if FORGE.ForgeOSCore:getPhase() ~= Phase.RUNTIME_ACTIVE then
        return Result.NOT_AVAILABLE, nil
    end
    local targetResult, registered = validateTargets(
        normalized.targetDevices,
        true
    )
    if not targetResult then
        return Result.NOT_REGISTERED, nil
    end
    normalized.targetDevices = registered
    if not ensureRepaired() then
        return Result.STATE_ERROR, nil
    end

    local state, player = getState()
    if state == nil then
        return Result.STATE_ERROR, nil
    end
    local saveRecords = player.notifications
    local stagedSessions = {}
    for id, record in pairs(sessionRecords) do
        stagedSessions[id] = record
    end

    local retained = normalized.persistence ~= Persistence.TRANSIENT
    local reclaimId = nil
    if retained then
        local all = orderedRecords(saveRecords, stagedSessions)
        if #all >= MAX_RETAINED then
            reclaimId = chooseReclamation(all)
            if reclaimId == nil then
                return Result.STATE_ERROR, nil
            end
            saveRecords[reclaimId] = nil
            stagedSessions[reclaimId] = nil
        end
    end

    local sequence = player.notificationNextSequence
    if not isPositiveInteger(sequence) then
        return Result.STATE_ERROR, nil
    end
    local identifier = "notification." .. tostring(sequence)
    local record = {
        id = identifier,
        playerId = PlayerId,
        source = normalized.source,
        title = normalized.title,
        body = normalized.body,
        severity = normalized.severity,
        persistence = normalized.persistence,
        targetDevices = normalized.targetDevices,
        route = normalized.route,
        metadata = normalized.metadata,
        createdOrder = sequence,
        read = false,
        dismissed = false
    }

    player.notificationNextSequence = sequence + 1
    if normalized.persistence == Persistence.SAVEGAME then
        saveRecords[identifier] = record
    end
    if not FORGE.StateStore:replaceNamespace(Namespace, state) then
        return Result.STATE_ERROR, nil
    end
    if normalized.persistence == Persistence.SESSION then
        stagedSessions[identifier] = record
    end
    sessionRecords = stagedSessions

    publish(Event.NOTIFICATION_CREATED, {
        playerId = PlayerId,
        notificationId = identifier,
        source = normalized.source,
        persistence = normalized.persistence,
        notification = copyRecord(record)
    })
    return Result.SUCCESS, identifier
end

local function findRecord(identifier)
    local session = sessionRecords[identifier]
    if session ~= nil then
        return session, false
    end
    local _, player = getState()
    if player == nil then
        return nil, false
    end
    return player.notifications[identifier], true
end

local function mutateRecord(identifier, field, eventId)
    if not isIdentifier(identifier) then
        return Result.INVALID_ARGUMENT
    end
    if FORGE.ForgeOSCore:getPhase() ~= Phase.RUNTIME_ACTIVE then
        return Result.NOT_AVAILABLE
    end
    if not ensureRepaired() then
        return Result.STATE_ERROR
    end
    local record, saved = findRecord(identifier)
    if record == nil then
        return Result.NOT_REGISTERED
    end
    if record[field] then
        return Result.SUCCESS
    end

    local staged = copyRecord(record)
    staged[field] = true
    if saved then
        local state, player = getState()
        if state == nil then
            return Result.STATE_ERROR
        end
        player.notifications[identifier] = staged
        if not FORGE.StateStore:replaceNamespace(Namespace, state) then
            return Result.STATE_ERROR
        end
    else
        sessionRecords[identifier] = staged
    end
    publish(eventId, {
        playerId = PlayerId,
        notificationId = identifier,
        [field] = true
    })
    return Result.SUCCESS
end

local function runOperation(operation, ...)
    local outcome = { pcall(operation, ...) }
    if not outcome[1] then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.NOTIFICATION,
            "Unexpected Notification Service failure: %s",
            FORGE.Logger:safeToString(outcome[2], "<unprintable error>")
        )
        return Result.INTERNAL_ERROR, nil
    end
    return outcome[2], outcome[3]
end

function Service:createNotification(definition)
    return runOperation(createNotification, definition)
end

function Service:markNotificationRead(identifier)
    return runOperation(
        mutateRecord,
        identifier,
        "read",
        Event.NOTIFICATION_READ
    )
end

function Service:dismissNotification(identifier)
    return runOperation(
        mutateRecord,
        identifier,
        "dismissed",
        Event.NOTIFICATION_DISMISSED
    )
end

function Service:getNotification(identifier)
    local call = { pcall(function()
        if FORGE.ForgeOSCore:getPhase() ~= Phase.RUNTIME_ACTIVE
            or not isIdentifier(identifier)
            or not ensureRepaired() then
            return nil
        end
        local record = findRecord(identifier)
        return record ~= nil and copyRecord(record) or nil
    end) }
    if not call[1] then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.NOTIFICATION,
            "Unexpected Notification query failure: %s",
            FORGE.Logger:safeToString(call[2], "<unprintable error>")
        )
        return nil
    end
    return call[2]
end

function Service:getNotifications(deviceId, includeDismissed)
    local call = { pcall(function()
        if FORGE.ForgeOSCore:getPhase() ~= Phase.RUNTIME_ACTIVE then
            return {}
        end
        if deviceId ~= nil and (not isIdentifier(deviceId)
            or not FORGE.DeviceRegistry:isDeviceRegistered(deviceId)) then
            return {}
        end
        if includeDismissed ~= nil and type(includeDismissed) ~= "boolean" then
            return {}
        end
        if not ensureRepaired() then
            return {}
        end
        local _, player = getState()
        if player == nil then
            return {}
        end
        local result = {}
        for _, record in ipairs(orderedRecords(
            player.notifications,
            sessionRecords
        )) do
            if (includeDismissed == true or not record.dismissed)
                and (deviceId == nil or record.targetDevices[deviceId]) then
                result[#result + 1] = copyRecord(record)
            end
        end
        return result
    end) }
    if not call[1] then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.NOTIFICATION,
            "Unexpected Notification query failure: %s",
            FORGE.Logger:safeToString(call[2], "<unprintable error>")
        )
        return {}
    end
    return call[2]
end

function Service:clearRuntimeState()
    sessionRecords = {}
    repaired = false
    repairFailed = false
    return Result.SUCCESS
end
