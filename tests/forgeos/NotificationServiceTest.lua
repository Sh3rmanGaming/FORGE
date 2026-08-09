---=============================================================================
--- FORGE ForgeOS Notification Service Tests
---
--- Manual component harness for the M2.009 Notification Service.
---
--- Responsibilities:
---     • Verify notification validation, lifetimes, state, and events.
---     • Verify monotonic identifiers, bounded retention, and restoration.
---     • Verify detached data, cleanup, and restart behavior.
---
--- This manual harness is invoked only by the Engine development test runner.
---=============================================================================

FORGE.Tests = FORGE.Tests or {}

function FORGE.Tests.runNotificationServiceTests()
    FORGE.Logger:info(
        FORGE.Definitions.LogSource.TEST,
        "Notification Service test harness started"
    )

    local Result = FORGE.Definitions.ForgeOSResult
    local Phase = FORGE.Definitions.ForgeOSPhase
    local Role = FORGE.ForgeOSRegistrationCoordinator.Role
    local Persist = FORGE.Definitions.NotificationPersistence
    local Severity = FORGE.Definitions.NotificationSeverity
    local PlayerId = FORGE.Definitions.ForgeOSPlayerId.LOCAL
    local Namespace = FORGE.Definitions.ForgeOSNamespace.OS
    local Event = FORGE.Definitions.ForgeOSEvent
    local createdEvents = 0
    local readEvents = 0
    local dismissedEvents = 0
    local lastCreated = nil

    local function host()
        local value = { frozen = false }
        function value:getRegistrationRole()
            return Role.DEVICE_HOST_REGISTRY
        end
        function value:validateRegistrationSet() return Result.SUCCESS end
        function value:freezeRegistrationSet()
            self.frozen = true
            return Result.SUCCESS
        end
        function value:clearRegistrationSet()
            self.frozen = false
            return Result.SUCCESS
        end
        function value:isRegistrationSetFrozen() return self.frozen end
        return value
    end

    local function definition(persistence, title)
        return {
            source = "forge.notificationTest",
            title = title or "Notice",
            body = "Notification body",
            severity = Severity.INFO,
            persistence = persistence,
            targetDevices = { phone = true },
            route = {
                appId = "forge.notice",
                routeId = "detail",
                parameters = { itemId = "item.one" }
            },
            metadata = { category = "test" }
        }
    end

    local function cleanup()
        FORGE.ForgeOS:shutdown()
        FORGE.EventBus:clearAll()
        FORGE.StateStore:clearAll()
        FORGE.SaveManager:clearAllRegistrations()
        FORGE.NotificationService:clearRuntimeState()
    end

    local success, errorMessage = pcall(function()
        cleanup()
        if FORGE.ForgeOS:createNotification(nil) ~= Result.INVALID_ARGUMENT
            or FORGE.ForgeOS:createNotification(
                definition(Persist.TRANSIENT)
            ) ~= Result.NOT_AVAILABLE
            or #FORGE.ForgeOS:getNotifications() ~= 0 then
            error("Notification argument or runtime gate failed")
        end

        if FORGE.ForgeOS:start() ~= Result.SUCCESS
            or FORGE.ForgeOS:registerDevice({
                id = "phone", displayName = "Phone", capabilities = {}
            }) ~= Result.SUCCESS
            or FORGE.ForgeOS:registerDevice({
                id = "laptop", displayName = "Laptop", capabilities = {}
            }) ~= Result.SUCCESS
            or FORGE.ForgeOSRegistrationCoordinator
                :installParticipant(host()) ~= Result.SUCCESS
            or FORGE.ForgeOS:completeStartup() ~= Result.SUCCESS
            or FORGE.ForgeOS:getPhase() ~= Phase.RUNTIME_ACTIVE then
            error("Notification test setup failed")
        end

        if FORGE.ForgeOS:getNotification(nil) ~= nil
            or FORGE.ForgeOS:getNotification("notification.999") ~= nil
            or #FORGE.ForgeOS:getNotifications("missing") ~= 0
            or #FORGE.ForgeOS:getNotifications("phone", "yes") ~= 0 then
            error("Notification primitive query failure contract failed")
        end

        local initialState = FORGE.StateStore:snapshot(Namespace)
        local initialPlayer = initialState.players[PlayerId]
        initialPlayer.notifications = nil
        initialPlayer.notificationNextSequence = nil
        initialPlayer.preferences.notificationSentinel = "preserved"
        if not FORGE.StateStore:replaceNamespace(Namespace, initialState) then
            error("Unable to stage older notification state")
        end
        FORGE.NotificationService:clearRuntimeState()
        if #FORGE.ForgeOS:getNotifications(nil, true) ~= 0 then
            error("Older notification state did not normalize empty")
        end
        initialState = FORGE.StateStore:snapshot(Namespace)
        initialPlayer = initialState.players[PlayerId]
        if initialPlayer.notificationNextSequence ~= 1
            or type(initialPlayer.notifications) ~= "table"
            or next(initialPlayer.notifications) ~= nil
            or initialPlayer.preferences.notificationSentinel
                ~= "preserved" then
            error("Older notification state compatibility failed")
        end

        local observer = {}
        function observer:onCreated(payload)
            createdEvents = createdEvents + 1
            lastCreated = payload
        end
        function observer:onRead() readEvents = readEvents + 1 end
        function observer:onDismissed()
            dismissedEvents = dismissedEvents + 1
        end
        FORGE.EventBus:subscribe(
            Event.NOTIFICATION_CREATED, observer, observer.onCreated
        )
        FORGE.EventBus:subscribe(
            Event.NOTIFICATION_READ, observer, observer.onRead
        )
        FORGE.EventBus:subscribe(
            Event.NOTIFICATION_DISMISSED, observer, observer.onDismissed
        )

        local invalid = definition(Persist.SESSION)
        invalid.severity = "unknown"
        local missingTarget = definition(Persist.SESSION)
        missingTarget.targetDevices = { missing = true }
        local cyclic = definition(Persist.SESSION)
        cyclic.metadata = {}
        cyclic.metadata.self = cyclic.metadata
        local shared = {}
        local sharedGraph = definition(Persist.SESSION)
        sharedGraph.metadata = { left = shared, right = shared }
        local nonFinite = definition(Persist.SESSION)
        nonFinite.metadata = { value = math.huge }
        local numericKey = definition(Persist.SESSION)
        numericKey.metadata = { [1] = "invalid" }
        local executable = definition(Persist.SESSION)
        executable.route.parameters.callback = function() end
        local metatableValue = definition(Persist.SESSION)
        metatableValue.metadata = setmetatable({}, {})
        local falseTarget = definition(Persist.SESSION)
        falseTarget.targetDevices = { phone = false }
        local invalidSource = definition(Persist.SESSION)
        invalidSource.source = "forge invalid"
        local invalidTitle = definition(Persist.SESSION)
        invalidTitle.title = true
        local invalidBody = definition(Persist.SESSION)
        invalidBody.body = {}
        local invalidPersistence = definition(Persist.SESSION)
        invalidPersistence.persistence = "forever"
        local invalidTargetTable = definition(Persist.SESSION)
        invalidTargetTable.targetDevices = "phone"
        local emptyTargets = definition(Persist.SESSION)
        emptyTargets.targetDevices = {}
        local invalidTargetId = definition(Persist.SESSION)
        invalidTargetId.targetDevices = { ["bad device"] = true }
        local invalidRoute = definition(Persist.SESSION)
        invalidRoute.route = "detail"
        local invalidRouteApp = definition(Persist.SESSION)
        invalidRouteApp.route.appId = "bad app"
        local invalidRouteId = definition(Persist.SESSION)
        invalidRouteId.route.routeId = "bad route"
        local unknownRouteField = definition(Persist.SESSION)
        unknownRouteField.route.controller = "forbidden"
        local outerMetatable = setmetatable(
            definition(Persist.SESSION),
            {}
        )
        if FORGE.ForgeOS:createNotification(invalid)
                ~= Result.INVALID_DEFINITION
            or FORGE.ForgeOS:createNotification(missingTarget)
                ~= Result.NOT_REGISTERED
            or FORGE.ForgeOS:createNotification(cyclic)
                ~= Result.INVALID_DEFINITION
            or FORGE.ForgeOS:createNotification(sharedGraph)
                ~= Result.INVALID_DEFINITION
            or FORGE.ForgeOS:createNotification(nonFinite)
                ~= Result.INVALID_DEFINITION
            or FORGE.ForgeOS:createNotification(numericKey)
                ~= Result.INVALID_DEFINITION
            or FORGE.ForgeOS:createNotification(executable)
                ~= Result.INVALID_DEFINITION
            or FORGE.ForgeOS:createNotification(metatableValue)
                ~= Result.INVALID_DEFINITION
            or FORGE.ForgeOS:createNotification(falseTarget)
                ~= Result.INVALID_DEFINITION
            or FORGE.ForgeOS:createNotification(invalidSource)
                ~= Result.INVALID_DEFINITION
            or FORGE.ForgeOS:createNotification(invalidTitle)
                ~= Result.INVALID_DEFINITION
            or FORGE.ForgeOS:createNotification(invalidBody)
                ~= Result.INVALID_DEFINITION
            or FORGE.ForgeOS:createNotification(invalidPersistence)
                ~= Result.INVALID_DEFINITION
            or FORGE.ForgeOS:createNotification(invalidTargetTable)
                ~= Result.INVALID_DEFINITION
            or FORGE.ForgeOS:createNotification(emptyTargets)
                ~= Result.INVALID_DEFINITION
            or FORGE.ForgeOS:createNotification(invalidTargetId)
                ~= Result.INVALID_DEFINITION
            or FORGE.ForgeOS:createNotification(invalidRoute)
                ~= Result.INVALID_DEFINITION
            or FORGE.ForgeOS:createNotification(invalidRouteApp)
                ~= Result.INVALID_DEFINITION
            or FORGE.ForgeOS:createNotification(invalidRouteId)
                ~= Result.INVALID_DEFINITION
            or FORGE.ForgeOS:createNotification(unknownRouteField)
                ~= Result.INVALID_DEFINITION
            or FORGE.ForgeOS:createNotification(outerMetatable)
                ~= Result.INVALID_DEFINITION then
            error("Notification definition validation failed")
        end

        local transientResult, transientId =
            FORGE.ForgeOS:createNotification(
                definition(Persist.TRANSIENT, "Transient")
            )
        local state = FORGE.StateStore:snapshot(Namespace)
        local player = state.players[PlayerId]
        if transientResult ~= Result.SUCCESS
            or transientId ~= "notification.1"
            or player.notificationNextSequence ~= 2
            or next(player.notifications) ~= nil
            or FORGE.ForgeOS:getNotification(transientId) ~= nil
            or createdEvents ~= 1
            or lastCreated.notification.id ~= transientId then
            error("Transient notification semantics failed")
        end

        local sessionDefinition = definition(Persist.SESSION, "Session")
        sessionDefinition.unrecognized = function() end
        local sessionResult, sessionId =
            FORGE.ForgeOS:createNotification(sessionDefinition)
        local saveDefinition = definition(Persist.SAVEGAME, "Savegame")
        local saveResult, saveId =
            FORGE.ForgeOS:createNotification(saveDefinition)
        if sessionResult ~= Result.SUCCESS
            or sessionId ~= "notification.2"
            or saveResult ~= Result.SUCCESS
            or saveId ~= "notification.3" then
            error("Retained notification identifier sequence failed")
        end
        local saveEvent = lastCreated

        for _, severity in ipairs({
            Severity.INFO,
            Severity.SUCCESS,
            Severity.WARNING,
            Severity.ERROR,
            Severity.CRITICAL
        }) do
            local severityDefinition = definition(Persist.TRANSIENT)
            severityDefinition.severity = severity
            if FORGE.ForgeOS:createNotification(severityDefinition)
                    ~= Result.SUCCESS then
                error("Notification severity coverage failed")
            end
        end

        sessionDefinition.title = "mutated"
        local session = FORGE.ForgeOS:getNotification(sessionId)
        session.title = "query mutation"
        saveEvent.notification.title = "event mutation"
        if FORGE.ForgeOS:getNotification(sessionId).title ~= "Session"
            or FORGE.ForgeOS:getNotification(saveId).title ~= "Savegame"
            or FORGE.ForgeOS:getNotification(sessionId).unrecognized ~= nil
            or #FORGE.ForgeOS:getNotifications("phone") ~= 2
            or #FORGE.ForgeOS:getNotifications("laptop") ~= 0 then
            error("Notification detachment or targeting failed")
        end

        local failingObserver = {}
        function failingObserver:onEvent()
            error("intentional Notification listener failure")
        end
        FORGE.EventBus:subscribe(
            Event.NOTIFICATION_READ,
            failingObserver,
            failingObserver.onEvent
        )

        if FORGE.ForgeOS:markNotificationRead(sessionId) ~= Result.SUCCESS
            or FORGE.ForgeOS:markNotificationRead(sessionId) ~= Result.SUCCESS
            or readEvents ~= 1
            or FORGE.ForgeOS:dismissNotification(saveId) ~= Result.SUCCESS
            or FORGE.ForgeOS:dismissNotification(saveId) ~= Result.SUCCESS
            or dismissedEvents ~= 1
            or #FORGE.ForgeOS:getNotifications("phone") ~= 1
            or #FORGE.ForgeOS:getNotifications("phone", true) ~= 2
            or FORGE.ForgeOS:markNotificationRead(transientId)
                ~= Result.NOT_REGISTERED then
            error("Notification read or dismissal behavior failed")
        end

        state = FORGE.StateStore:snapshot(Namespace)
        player = state.players[PlayerId]
        player.notifications = {
            first = {
                id = "notification.20", playerId = PlayerId,
                source = "forge.restore", title = "A", body = "",
                severity = Severity.INFO, persistence = Persist.SAVEGAME,
                targetDevices = { phone = true }, createdOrder = 20,
                read = false, dismissed = false
            },
            second = {
                id = "notification.20", playerId = PlayerId,
                source = "forge.restore", title = "B", body = "",
                severity = Severity.INFO, persistence = Persist.SAVEGAME,
                targetDevices = { phone = true }, createdOrder = 21,
                read = false, dismissed = false
            },
            third = {
                id = "notification.22", playerId = PlayerId,
                source = "forge.restore", title = "C", body = "",
                severity = Severity.INFO, persistence = Persist.SAVEGAME,
                targetDevices = { phone = true }, createdOrder = 22,
                read = false, dismissed = false
            },
            fourth = {
                id = "notification.23", playerId = PlayerId,
                source = "forge.restore", title = "D", body = "",
                severity = Severity.INFO, persistence = Persist.SAVEGAME,
                targetDevices = { phone = true }, createdOrder = 22,
                read = false, dismissed = false
            },
            survivor = {
                id = "notification.24", playerId = PlayerId,
                source = "forge.restore", title = "Survivor", body = "",
                severity = Severity.INFO, persistence = Persist.SAVEGAME,
                targetDevices = { phone = true }, createdOrder = 24,
                read = true, dismissed = false
            }
        }
        player.notificationNextSequence = 30
        player.preferences.repairSentinel = "preserved"
        if not FORGE.StateStore:replaceNamespace(Namespace, state) then
            error("Unable to stage restored notification state")
        end
        FORGE.NotificationService:clearRuntimeState()
        local eventsBeforeRepair = createdEvents + readEvents + dismissedEvents
        local restored = FORGE.ForgeOS:getNotifications(nil, true)
        state = FORGE.StateStore:snapshot(Namespace)
        player = state.players[PlayerId]
        if #restored ~= 1
            or restored[1].id ~= "notification.24"
            or player.notificationNextSequence ~= 30
            or player.preferences.repairSentinel ~= "preserved"
            or eventsBeforeRepair
                ~= createdEvents + readEvents + dismissedEvents then
            error("Notification conflict-safe restoration failed")
        end

        local gapResult, gapId = FORGE.ForgeOS:createNotification(
            definition(Persist.TRANSIENT, "After repair")
        )
        state = FORGE.StateStore:snapshot(Namespace)
        if gapResult ~= Result.SUCCESS
            or gapId ~= "notification.30"
            or state.players[PlayerId].notificationNextSequence ~= 31 then
            error("Notification sequence continuity failed")
        end

        local function restoredRecord(index, read, dismissed)
            return {
                id = "notification." .. tostring(index),
                playerId = PlayerId,
                source = "forge.retention",
                title = "Retained " .. tostring(index),
                body = "",
                severity = Severity.INFO,
                persistence = Persist.SAVEGAME,
                targetDevices = { phone = true },
                createdOrder = index,
                read = read,
                dismissed = dismissed
            }
        end

        state = FORGE.StateStore:snapshot(Namespace)
        player = state.players[PlayerId]
        player.notifications = {}
        for index = 1, 256 do
            player.notifications["slot" .. tostring(index)] =
                restoredRecord(index, false, index == 1)
        end
        player.notificationNextSequence = 300
        FORGE.StateStore:replaceNamespace(Namespace, state)
        FORGE.NotificationService:clearRuntimeState()
        local retainedResult, retainedId =
            FORGE.ForgeOS:createNotification(
                definition(Persist.SAVEGAME, "Capacity")
            )
        state = FORGE.StateStore:snapshot(Namespace)
        player = state.players[PlayerId]
        if retainedResult ~= Result.SUCCESS
            or retainedId ~= "notification.300"
            or player.notifications["notification.1"] ~= nil
            or player.notifications[retainedId] == nil then
            error("Notification bounded reclamation failed")
        end

        player.notifications = {}
        for index = 1, 256 do
            player.notifications["slot" .. tostring(index)] =
                restoredRecord(index, index == 1, false)
        end
        player.notificationNextSequence = 350
        FORGE.StateStore:replaceNamespace(Namespace, state)
        FORGE.NotificationService:clearRuntimeState()
        local readReclaimResult, readReclaimId =
            FORGE.ForgeOS:createNotification(
                definition(Persist.SESSION, "Read reclamation")
            )
        state = FORGE.StateStore:snapshot(Namespace)
        player = state.players[PlayerId]
        if readReclaimResult ~= Result.SUCCESS
            or readReclaimId ~= "notification.350"
            or player.notifications["notification.1"] ~= nil
            or FORGE.ForgeOS:getNotification(readReclaimId) == nil then
            error("Notification read reclamation failed")
        end

        player.notifications = {}
        for index = 1, 256 do
            local record = restoredRecord(index, false, false)
            player.notifications[record.id] = record
        end
        player.notificationNextSequence = 400
        FORGE.StateStore:replaceNamespace(Namespace, state)
        FORGE.NotificationService:clearRuntimeState()
        local fullResult = FORGE.ForgeOS:createNotification(
            definition(Persist.SESSION, "No capacity")
        )
        state = FORGE.StateStore:snapshot(Namespace)
        if fullResult ~= Result.STATE_ERROR
            or state.players[PlayerId].notificationNextSequence ~= 400 then
            error("Unread notification eviction or failed allocation occurred")
        end

        player = state.players[PlayerId]
        player.notifications = {}
        for index = 1, 257 do
            local record = restoredRecord(index, false, false)
            player.notifications[record.id] = record
        end
        player.notificationNextSequence = 500
        player.preferences.failedRepairSentinel = "unchanged"
        FORGE.StateStore:replaceNamespace(Namespace, state)
        FORGE.NotificationService:clearRuntimeState()
        if #FORGE.ForgeOS:getNotifications(nil, true) ~= 0
            or FORGE.ForgeOS:createNotification(
                definition(Persist.SAVEGAME, "Repair failure")
            ) ~= Result.STATE_ERROR then
            error("Notification failed-repair boundary failed")
        end
        local failedState = FORGE.StateStore:snapshot(Namespace)
        local failedPlayer = failedState.players[PlayerId]
        local failedCount = 0
        for _ in pairs(failedPlayer.notifications) do
            failedCount = failedCount + 1
        end
        if failedCount ~= 257
            or failedPlayer.notificationNextSequence ~= 500
            or failedPlayer.preferences.failedRepairSentinel ~= "unchanged" then
            error("Notification failed repair exposed partial state")
        end

        local originalGetPhase = FORGE.ForgeOSCore.getPhase
        FORGE.ForgeOSCore.getPhase = function()
            error("intentional Notification query failure")
        end
        local failedSingle = FORGE.ForgeOS:getNotification("notification.1")
        local failedList = FORGE.ForgeOS:getNotifications()
        FORGE.ForgeOSCore.getPhase = originalGetPhase
        if failedSingle ~= nil or #failedList ~= 0 then
            error("Unexpected Notification query containment failed")
        end

        if FORGE.ForgeOS:shutdown() ~= Result.SUCCESS
            or FORGE.ForgeOS:start() ~= Result.SUCCESS
            or FORGE.ForgeOS:getPhase() ~= Phase.REGISTRATION_OPEN
            or #FORGE.ForgeOS:getNotifications() ~= 0
            or FORGE.ForgeOS:shutdown() ~= Result.SUCCESS then
            error("Notification shutdown or restart cleanup failed")
        end
        cleanup()
    end)

    pcall(cleanup)
    if not success then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.TEST,
            "Notification Service test harness failed: %s",
            FORGE.Logger:safeToString(errorMessage, "<unprintable error>")
        )
        return false, errorMessage
    end
    FORGE.Logger:info(
        FORGE.Definitions.LogSource.TEST,
        "Notification Service test harness passed"
    )
    return true
end
