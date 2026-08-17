---=============================================================================
--- FORGE Communications Manager Integration Tests
---=============================================================================

FORGE.Tests = FORGE.Tests or {}

function FORGE.Tests.runCommunicationsManagerIntegrationTests()
    FORGE.Logger:info(FORGE.Definitions.LogSource.TEST,
        "Communications Manager integration test harness started")

    local Result = FORGE.Definitions.CommunicationsResult
    local ForgeResult = FORGE.Definitions.ForgeOSResult
    local Namespace = FORGE.Definitions.CommunicationsNamespace.STATE
    local function cleanup()
        FORGE.Communications:shutdown()
        FORGE.ForgeOS:shutdown()
        FORGE.EventBus:clearAll()
        FORGE.StateStore:clearAll()
        FORGE.SaveManager:clearAllRegistrations()
        FORGE.NotificationService:clearRuntimeState()
    end
    local succeeded, failure = pcall(function()
        cleanup()
        if FORGE.ForgeOS:start() ~= ForgeResult.SUCCESS
            or FORGE.ForgeOS:completeStartup() ~= ForgeResult.SUCCESS
            or FORGE.Communications:start() ~= Result.SUCCESS
            or FORGE.CommunicationsService:isAvailable()
            or not FORGE.SaveManager:isNamespaceRegistered(Namespace)
            or FORGE.Communications:completeRestoration() ~= Result.SUCCESS
            or not FORGE.CommunicationsService:isAvailable() then
            error("Communications lifecycle integration failed")
        end
        local result, identifier = FORGE.Communications:createMessage({
            source = "forge.integration", subject = "Integrated",
            body = "Persistent", channel = "mail",
            recipient = "player.local"
        })
        if result ~= Result.SUCCESS or identifier ~= "message.1" then
            error("Facade creation integration failed")
        end
        local linkedResult, linkedId, linkedDetail =
            FORGE.Communications:createMessage({
                source = "forge.integration", subject = "Linked",
                body = "Authoritative message", channel = "system",
                recipient = "player.local",
                notification = {
                    severity = FORGE.Definitions.NotificationSeverity.INFO,
                    persistence =
                        FORGE.Definitions.NotificationPersistence.SAVEGAME,
                    targetDevices = { phone = true, laptop = true }
                }
            })
        local linkedNotification = linkedDetail ~= nil
            and FORGE.ForgeOS:getNotification(linkedDetail.notificationId)
            or nil
        if linkedResult ~= Result.SUCCESS or linkedId ~= "message.2"
            or linkedDetail.notificationResult ~= ForgeResult.SUCCESS
            or linkedNotification == nil
            or linkedNotification.metadata.communicationsMessageId ~= linkedId
            or linkedNotification.route.parameters.messageId ~= linkedId
            or FORGE.Communications:markMessageRead(linkedId) ~= Result.SUCCESS
            or not FORGE.ForgeOS:getNotification(
                linkedDetail.notificationId).read then
            error("Linked notification integration failed")
        end

        local separateResult, separateId, separateDetail =
            FORGE.Communications:createMessage({
                source = "forge.integration", subject = "Separate",
                body = "Independent lifecycle", channel = "mail",
                recipient = "player.local",
                notification = {
                    body = "", severity =
                        FORGE.Definitions.NotificationSeverity.WARNING,
                    persistence =
                        FORGE.Definitions.NotificationPersistence.SAVEGAME,
                    targetDevices = { phone = true }
                }
            })
        if separateResult ~= Result.SUCCESS
            or FORGE.ForgeOS:markNotificationRead(
                separateDetail.notificationId) ~= ForgeResult.SUCCESS
            or FORGE.Communications:getMessage(separateId).read
            or FORGE.ForgeOS:dismissNotification(
                separateDetail.notificationId) ~= ForgeResult.SUCCESS
            or FORGE.Communications:getMessage(separateId).archived
            or FORGE.Communications:getMessage(separateId).read
            or FORGE.Communications:archiveMessage(separateId) ~= Result.SUCCESS
            or not FORGE.ForgeOS:getNotification(
                separateDetail.notificationId).dismissed then
            error("Notification/message lifecycle separation failed")
        end
        local persisted = FORGE.StateStore:snapshot(Namespace)
        FORGE.Communications:shutdown()
        if FORGE.Communications:getMessage(identifier) ~= nil
            or FORGE.Communications:getUnreadCount() ~= 0 then
            error("Shutdown availability gate failed")
        end
        if not FORGE.StateStore:replaceNamespace(Namespace, persisted)
            or FORGE.Communications:completeRestoration() ~= Result.SUCCESS
            or FORGE.Communications:getMessage(identifier).subject
                ~= "Integrated"
            or FORGE.Communications:getMessage(linkedId).notificationId
                ~= linkedDetail.notificationId then
            error("Restart restoration integration failed")
        end
        cleanup()
    end)
    cleanup()
    if not succeeded then
        FORGE.Logger:error(FORGE.Definitions.LogSource.TEST,
            "Communications Manager integration test harness failed: %s",
            FORGE.Logger:safeToString(failure, "<unknown>"))
        return false, failure
    end
    FORGE.Logger:info(FORGE.Definitions.LogSource.TEST,
        "Communications Manager integration test harness passed")
    return true
end
