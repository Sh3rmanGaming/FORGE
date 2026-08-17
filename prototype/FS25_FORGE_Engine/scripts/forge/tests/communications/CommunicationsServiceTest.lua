---=============================================================================
--- FORGE Communications Service Tests
---=============================================================================

FORGE.Tests = FORGE.Tests or {}

function FORGE.Tests.runCommunicationsServiceTests()
    FORGE.Logger:info(
        FORGE.Definitions.LogSource.TEST,
        "Communications Service test harness started")

    local Result = FORGE.Definitions.CommunicationsResult
    local ForgeResult = FORGE.Definitions.ForgeOSResult
    local Event = FORGE.Definitions.CommunicationsEvent
    local Namespace = FORGE.Definitions.CommunicationsNamespace.STATE

    local function definition(subject)
        return {
            source = "forge.test",
            subject = subject or "Test message",
            body = "Body",
            channel = FORGE.Definitions.MessageChannel.SYSTEM,
            recipient = "player.local",
            metadata = { nested = { value = "detached" } }
        }
    end

    local function cleanup()
        FORGE.Communications:shutdown()
        FORGE.EventBus:clearAll()
        FORGE.StateStore:clearAll()
        FORGE.SaveManager:clearAllRegistrations()
    end

    local originalCreateNotification = FORGE.ForgeOS.createNotification
    local originalMarkNotificationRead = FORGE.ForgeOS.markNotificationRead
    local originalReplace = FORGE.StateStore.replaceNamespace
    local originalWarning = FORGE.Logger.warning

    local succeeded, failure = pcall(function()
        cleanup()
        if FORGE.Communications:createMessage(nil)
                ~= Result.INVALID_ARGUMENT
            or FORGE.Communications:createMessage(definition())
                ~= Result.NOT_AVAILABLE then
            error("Communications validation or availability precedence failed")
        end

        if FORGE.Communications:start() ~= Result.SUCCESS
            or FORGE.Communications:completeRestoration() ~= Result.SUCCESS then
            error("Communications Service setup failed")
        end

        local invalidDefinitions = {
            { source = "bad source", subject = "Subject", body = "",
                channel = "system", recipient = "player.local" },
            { source = "forge.test", subject = "", body = "",
                channel = "system", recipient = "player.local" },
            { source = "forge.test", subject = "Subject", body = 1,
                channel = "system", recipient = "player.local" },
            { source = "forge.test", subject = "Subject", body = "",
                channel = "unknown", recipient = "player.local" },
            { source = "forge.test", subject = "Subject", body = "",
                channel = "system", recipient = "player.other" },
            { source = "forge.test", subject = "Subject", body = "",
                channel = "system", recipient = "player.local",
                metadata = { callback = function() end } }
        }
        for _, invalidDefinition in ipairs(invalidDefinitions) do
            if FORGE.Communications:createMessage(invalidDefinition)
                    ~= Result.INVALID_DEFINITION then
                error("Invalid message definition was accepted")
            end
        end

        local notificationCalls = 0
        local notificationDefinitions = {}
        local readResult = ForgeResult.SUCCESS
        local readCalls = 0
        FORGE.ForgeOS.createNotification = function(_, supplied)
            notificationCalls = notificationCalls + 1
            notificationDefinitions[#notificationDefinitions + 1] = supplied
            return ForgeResult.SUCCESS,
                "notification." .. tostring(notificationCalls)
        end
        FORGE.ForgeOS.markNotificationRead = function(_, notificationId)
            readCalls = readCalls + 1
            if notificationId == nil then
                error("Notification read received no identifier")
            end
            return readResult
        end

        local requested = definition("Notification fallback")
        requested.notification = {
            severity = "info",
            persistence = "savegame",
            targetDevices = { phone = true, laptop = true }
        }
        local requestResult, requestId, requestDetail =
            FORGE.Communications:createMessage(requested)
        local notification = notificationDefinitions[1]
        if requestResult ~= Result.SUCCESS or requestId ~= "message.1"
            or requestDetail.notificationResult ~= ForgeResult.SUCCESS
            or requestDetail.notificationId ~= "notification.1"
            or requestDetail.integrationResult ~= nil
            or notification.source ~= "forge.communications"
            or notification.title ~= "Notification fallback"
            or notification.body ~= ""
            or notification.severity ~= "info"
            or notification.persistence ~= "savegame"
            or not notification.targetDevices.phone
            or not notification.targetDevices.laptop
            or notification.route.appId ~= "forge.communications"
            or notification.route.routeId ~= "messageDetail"
            or notification.route.parameters.messageId ~= requestId
            or notification.metadata.communicationsMessageId ~= requestId
            or FORGE.Communications:getMessage(requestId).notificationId
                ~= "notification.1" then
            error("Successful notification integration contract failed")
        end
        requestDetail.notificationId = "mutated"
        notification.route.parameters.messageId = "mutated"
        if FORGE.Communications:getMessage(requestId).notificationId
                ~= "notification.1" then
            error("Notification integration detail was not detached")
        end

        local explicit = definition("Message subject")
        explicit.notification = {
            title = "Exact alert title", body = "Exact alert body",
            severity = "warning", persistence = "savegame",
            targetDevices = { phone = true }
        }
        local explicitResult, explicitId =
            FORGE.Communications:createMessage(explicit)
        local explicitNotification = notificationDefinitions[2]
        if explicitResult ~= Result.SUCCESS or explicitId ~= "message.2"
            or explicitNotification.title ~= "Exact alert title"
            or explicitNotification.body ~= "Exact alert body" then
            error("Explicit notification title/body were not preserved")
        end

        local empty = definition("Empty body")
        empty.notification = {
            title = "", body = "", severity = "success",
            persistence = "savegame", targetDevices = { phone = true }
        }
        local emptyResult = FORGE.Communications:createMessage(empty)
        if emptyResult ~= Result.SUCCESS
            or notificationDefinitions[3].title ~= ""
            or notificationDefinitions[3].body ~= "" then
            error("Explicit empty notification strings were not preserved")
        end

        FORGE.ForgeOS.createNotification = function()
            notificationCalls = notificationCalls + 1
            return ForgeResult.NOT_AVAILABLE, nil
        end
        local failed = definition("Alert failure")
        failed.notification = requested.notification
        local failedResult, failedId, failedDetail =
            FORGE.Communications:createMessage(failed)
        if failedResult ~= Result.SUCCESS or failedId ~= "message.4"
            or failedDetail.notificationResult ~= ForgeResult.NOT_AVAILABLE
            or failedDetail.notificationId ~= nil
            or failedDetail.integrationResult
                ~= Result.NOTIFICATION_CREATION_FAILED
            or FORGE.Communications:getMessage(failedId).notificationId ~= nil
            or notificationCalls ~= 4 then
            error("Notification creation failure isolation failed")
        end

        FORGE.ForgeOS.createNotification = function()
            notificationCalls = notificationCalls + 1
            return ForgeResult.SUCCESS, "notification.linkage"
        end
        local communicationsReplacements = 0
        FORGE.StateStore.replaceNamespace = function(store, namespace, value)
            if namespace == Namespace then
                communicationsReplacements = communicationsReplacements + 1
                if communicationsReplacements == 2 then
                    return false
                end
            end
            return originalReplace(store, namespace, value)
        end
        local warningCount = 0
        FORGE.Logger.warning = function() warningCount = warningCount + 1 end
        local unlinked = definition("Link failure")
        unlinked.notification = requested.notification
        local linkResult, linkId, linkDetail =
            FORGE.Communications:createMessage(unlinked)
        FORGE.StateStore.replaceNamespace = originalReplace
        FORGE.Logger.warning = originalWarning
        if linkResult ~= Result.SUCCESS or linkId ~= "message.5"
            or linkDetail.notificationResult ~= ForgeResult.SUCCESS
            or linkDetail.notificationId ~= "notification.linkage"
            or linkDetail.integrationResult
                ~= Result.NOTIFICATION_LINKAGE_FAILED
            or FORGE.Communications:getMessage(linkId).notificationId ~= nil
            or warningCount ~= 1 or notificationCalls ~= 5 then
            error("Notification linkage failure isolation failed")
        end

        readResult = ForgeResult.SUCCESS
        if FORGE.Communications:markMessageRead(requestId) ~= Result.SUCCESS
            or readCalls ~= 1 then
            error("Linked notification read propagation failed")
        end
        readResult = ForgeResult.NOT_REGISTERED
        if FORGE.Communications:markMessageRead(explicitId) ~= Result.SUCCESS
            or readCalls ~= 2 then
            error("Missing notification changed message-read success")
        end
        local readWarnings = 0
        FORGE.Logger.warning = function() readWarnings = readWarnings + 1 end
        readResult = ForgeResult.STATE_ERROR
        if FORGE.Communications:markMessageRead("message.3") ~= Result.SUCCESS
            or readCalls ~= 3 or readWarnings ~= 1
            or not FORGE.Communications:getMessage("message.3").read then
            error("Notification infrastructure failure isolation failed")
        end
        FORGE.Logger.warning = originalWarning
        if FORGE.Communications:markMessageRead("message.3") ~= Result.SUCCESS
            or readCalls ~= 3 then
            error("Idempotent message read retried notification propagation")
        end

        FORGE.ForgeOS.createNotification = originalCreateNotification
        FORGE.ForgeOS.markNotificationRead = originalMarkNotificationRead

        local malformedNotification = definition()
        malformedNotification.notification = {
            severity = "invalid",
            persistence = "savegame",
            targetDevices = { phone = true }
        }
        if FORGE.Communications:createMessage(malformedNotification)
                ~= Result.INVALID_DEFINITION then
            error("Malformed notification was accepted")
        end

        cleanup()
        if FORGE.Communications:start() ~= Result.SUCCESS
            or FORGE.Communications:completeRestoration() ~= Result.SUCCESS then
            error("Communications Service reset failed")
        end

        local created, read, archived = 0, 0, 0
        local observer = {}
        function observer:onCreated() created = created + 1 end
        function observer:onRead() read = read + 1 end
        function observer:onArchived() archived = archived + 1 end
        FORGE.EventBus:subscribe(Event.MESSAGE_CREATED, observer,
            observer.onCreated)
        FORGE.EventBus:subscribe(Event.MESSAGE_READ, observer,
            observer.onRead)
        FORGE.EventBus:subscribe(Event.MESSAGE_ARCHIVED, observer,
            observer.onArchived)

        local input = definition("First")
        input.unknown = { ignored = true }
        local result, messageId, creationDetail =
            FORGE.Communications:createMessage(input)
        input.metadata.nested.value = "changed"
        if result ~= Result.SUCCESS or messageId ~= "message.1"
            or creationDetail ~= nil
            or created ~= 1 or FORGE.Communications:getUnreadCount() ~= 1 then
            error("Message creation contract failed")
        end
        local message = FORGE.Communications:getMessage(messageId)
        if message.metadata.nested.value ~= "detached"
            or message.unknown ~= nil then
            error("Message input was not detached or unknown field retained")
        end
        message.subject = "mutated"
        if FORGE.Communications:getMessage(messageId).subject ~= "First" then
            error("Message query was not detached")
        end

        if FORGE.Communications:markMessageRead(messageId) ~= Result.SUCCESS
            or FORGE.Communications:markMessageRead(messageId) ~= Result.SUCCESS
            or read ~= 1 or FORGE.Communications:getUnreadCount() ~= 0
            or FORGE.Communications:archiveMessage(messageId) ~= Result.SUCCESS
            or FORGE.Communications:archiveMessage(messageId) ~= Result.SUCCESS
            or archived ~= 1
            or #FORGE.Communications:getMessages() ~= 0
            or #FORGE.Communications:getMessages(true) ~= 1 then
            error("Read/archive/idempotence/query contract failed")
        end
        if FORGE.Communications:markMessageRead("message.999")
                ~= Result.NOT_FOUND
            or FORGE.Communications:archiveMessage(nil)
                ~= Result.INVALID_ARGUMENT then
            error("Message mutation failure contract failed")
        end

        local failingObserver = {}
        function failingObserver:onCreated()
            error("intentional Communications listener failure")
        end
        FORGE.EventBus:subscribe(Event.MESSAGE_CREATED, failingObserver,
            failingObserver.onCreated)
        local listenerResult, listenerId =
            FORGE.Communications:createMessage(definition("Listener"))
        if listenerResult ~= Result.SUCCESS or listenerId ~= "message.2" then
            error("Listener failure rolled back committed message state")
        end

        FORGE.StateStore.replaceNamespace = function() return false end
        local failedResult =
            FORGE.Communications:createMessage(definition("Rejected"))
        FORGE.StateStore.replaceNamespace = originalReplace
        if failedResult ~= Result.STATE_ERROR then
            error("State Store replacement failure mapping failed")
        end
        local retryResult, retryId =
            FORGE.Communications:createMessage(definition("Retry"))
        if retryResult ~= Result.SUCCESS or retryId ~= "message.3" then
            error("Failed creation consumed a message identifier")
        end
        local orderedMessages = FORGE.Communications:getMessages(true)
        if #orderedMessages ~= 3
            or orderedMessages[1].id ~= "message.1"
            or orderedMessages[2].id ~= "message.2"
            or orderedMessages[3].id ~= "message.3"
            or #FORGE.Communications:getMessages("yes") ~= 0 then
            error("Message ordering or invalid query semantics failed")
        end

        cleanup()
        FORGE.Communications:start()
        FORGE.Communications:completeRestoration()
        local firstId = nil
        for index = 1, 256 do
            local capacityResult, capacityId =
                FORGE.Communications:createMessage(
                    definition("Capacity " .. tostring(index)))
            if capacityResult ~= Result.SUCCESS then
                error("Unable to fill bounded inbox")
            end
            firstId = firstId or capacityId
        end
        if FORGE.Communications:createMessage(definition("Overflow"))
                ~= Result.CAPACITY_EXHAUSTED then
            error("Full active inbox did not reject creation")
        end
        if FORGE.Communications:archiveMessage(firstId) ~= Result.SUCCESS then
            error("Unable to archive reclamation candidate")
        end
        local reclaimedResult, reclaimedId =
            FORGE.Communications:createMessage(definition("Reclaimed"))
        if reclaimedResult ~= Result.SUCCESS
            or reclaimedId ~= "message.257"
            or FORGE.Communications:getMessage(firstId) ~= nil
            or #FORGE.Communications:getMessages(true) ~= 256 then
            error("Archived-first reclamation contract failed")
        end

        cleanup()
    end)

    FORGE.ForgeOS.createNotification = originalCreateNotification
    FORGE.ForgeOS.markNotificationRead = originalMarkNotificationRead
    FORGE.StateStore.replaceNamespace = originalReplace
    FORGE.Logger.warning = originalWarning
    cleanup()
    if not succeeded then
        FORGE.Logger:error(FORGE.Definitions.LogSource.TEST,
            "Communications Service test harness failed: %s",
            FORGE.Logger:safeToString(failure, "<unknown>"))
        return false, failure
    end
    FORGE.Logger:info(FORGE.Definitions.LogSource.TEST,
        "Communications Service test harness passed")
    return true
end
