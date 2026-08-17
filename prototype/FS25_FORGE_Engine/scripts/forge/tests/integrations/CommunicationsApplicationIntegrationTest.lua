---=============================================================================
--- FORGE Communications Application Integration Tests
---
--- Verifies the M3.004 application, presentation adapter, and domain boundary.
---=============================================================================

FORGE.Tests = FORGE.Tests or {}

function FORGE.Tests.runCommunicationsApplicationIntegrationTests()
    FORGE.Logger:info(
        FORGE.Definitions.LogSource.TEST,
        "Communications Application integration test started"
    )

    local ForgeResult = FORGE.Definitions.ForgeOSResult
    local DomainResult = FORGE.Definitions.CommunicationsResult
    local AppId = FORGE.Definitions.CommunicationsAppId.COMMUNICATIONS

    local function cleanup()
        FORGE.Communications:shutdown()
        FORGE.ForgeOS:shutdown()
        FORGE.EventBus:clearAll()
        FORGE.StateStore:clearAll()
        FORGE.SaveManager:clearAllRegistrations()
    end

    local succeeded, failure = pcall(function()
        cleanup()
        if FORGE.ForgeOS:start() ~= ForgeResult.SUCCESS
            or FORGE.Communications:start() ~= DomainResult.SUCCESS
            or FORGE.Communications:completeRestoration()
                ~= DomainResult.SUCCESS
            or FORGE.Communications:registerApplication()
                ~= ForgeResult.SUCCESS then
            error("Communications application registration setup failed")
        end

        local definition = FORGE.ForgeOS:getAppDefinition(AppId)
        if definition == nil
            or definition.presentations.phone.id
                ~= "forge.communications.phone"
            or definition.presentations.laptop.id
                ~= "forge.communications.laptop"
            or definition.presentations.phone.controller ~= nil then
            error("Communications registration identity or isolation failed")
        end

        if FORGE.ForgeOS:completeStartup() ~= ForgeResult.SUCCESS
            or FORGE.ForgeOS:openApp("phone", AppId) ~= ForgeResult.SUCCESS
            or FORGE.ForgeOS:activateApp("phone", AppId)
                ~= ForgeResult.SUCCESS
            or FORGE.ForgeOS:showDevice("phone") ~= ForgeResult.SUCCESS
            or FORGE.ForgeOS:openApp("laptop", AppId) ~= ForgeResult.SUCCESS
            or FORGE.ForgeOS:activateApp("laptop", AppId)
                ~= ForgeResult.SUCCESS
            or FORGE.ForgeOS:showDevice("laptop") ~= ForgeResult.SUCCESS then
            error("Communications application runtime setup failed")
        end

        local firstResult, firstId = FORGE.Communications:createMessage({
            source = "forge.system",
            subject = "First",
            body = "Complete body without transformation.",
            channel = FORGE.Definitions.MessageChannel.SYSTEM,
            recipient = "player.local"
        })
        local secondResult, secondId = FORGE.Communications:createMessage({
            source = "forge.sender",
            senderDisplayName = "FORGE Sender",
            subject = "Second",
            body = "Second body",
            channel = FORGE.Definitions.MessageChannel.MAIL,
            recipient = "player.local"
        })
        if firstResult ~= DomainResult.SUCCESS
            or secondResult ~= DomainResult.SUCCESS then
            error("Communications application fixture creation failed")
        end

        local inbox = FORGE.ForgeOS:getApplicationPresentationModel(
            "phone",
            AppId
        )
        if inbox == nil
            or inbox.presentationId ~= "forge.communications.phone"
            or inbox.routeId ~= "inbox"
            or inbox.badgeCount ~= 2
            or #inbox.content.rows ~= 2
            or inbox.content.rows[1].messageId ~= firstId
            or inbox.content.rows[1].preview
                ~= "Complete body without transformation."
            or inbox.content.rows[1].sender ~= "forge.system"
            or inbox.content.rows[2].sender ~= "FORGE Sender"
            or FORGE.ForgeOS:getApplicationBadge("laptop", AppId) ~= 2 then
            error("Inbox model, sender, preview, or shared badge failed")
        end

        inbox.content.rows[1].subject = "mutated"
        if FORGE.Communications:getMessage(firstId).subject ~= "First" then
            error("Presentation model exposed authoritative state")
        end

        local openResult, openOutcome =
            FORGE.ForgeOS:performApplicationAction(
                "phone",
                AppId,
                "communications.openMessage",
                { messageId = firstId }
            )
        local routeId, routeParameters = FORGE.ForgeOS:getCurrentRoute(
            "phone",
            AppId
        )
        if openResult ~= ForgeResult.SUCCESS
            or not openOutcome.completed
            or routeId ~= "messageDetail"
            or routeParameters.messageId ~= firstId then
            error("Open-message action or navigation failed")
        end

        local detail = FORGE.ForgeOS:getApplicationPresentationModel(
            "phone",
            AppId
        )
        if detail == nil
            or detail.content.message.body
                ~= "Complete body without transformation." then
            error("Message detail model failed")
        end

        local readResult, readOutcome =
            FORGE.ForgeOS:performApplicationAction(
                "phone",
                AppId,
                "communications.markRead",
                { messageId = firstId }
            )
        if readResult ~= ForgeResult.SUCCESS
            or not readOutcome.completed
            or readOutcome.navigation ~= nil
            or FORGE.ForgeOS:getCurrentRoute("phone", AppId)
                ~= "messageDetail"
            or FORGE.ForgeOS:getApplicationBadge("laptop", AppId) ~= 1 then
            error("Mark-read action or shared badge failed")
        end

        local archiveResult, archiveOutcome =
            FORGE.ForgeOS:performApplicationAction(
                "phone",
                AppId,
                "communications.archive",
                { messageId = firstId }
            )
        if archiveResult ~= ForgeResult.SUCCESS
            or not archiveOutcome.completed
            or archiveOutcome.navigation.operation ~= "home"
            or FORGE.ForgeOS:getCurrentRoute("phone", AppId) ~= "inbox" then
            error("Archive action did not return to default inbox")
        end

        local missingResult, missingOutcome =
            FORGE.ForgeOS:performApplicationAction(
                "phone",
                AppId,
                "communications.openMessage",
                { messageId = "message.9999" }
            )
        if missingResult ~= ForgeResult.SUCCESS
            or missingOutcome.completed
            or missingOutcome.domainResult ~= DomainResult.NOT_FOUND
            or missingOutcome.navigation ~= nil
            or FORGE.ForgeOS:getCurrentRoute("phone", AppId) ~= "inbox" then
            error("Controlled missing-message action failed")
        end

        if FORGE.ForgeOS:navigate(
                "phone",
                AppId,
                "messageDetail",
                { messageId = "message.9999" }
            ) ~= ForgeResult.SUCCESS then
            error("Missing detail navigation fixture failed")
        end
        local missingModel = FORGE.ForgeOS:getApplicationPresentationModel(
            "phone",
            AppId
        )
        if missingModel == nil
            or missingModel.content.kind
                ~= "communications.messageDetail"
            or missingModel.content.message ~= nil then
            error("Bounded not-found detail model failed")
        end

        if FORGE.ForgeOS:hideDevice("phone") ~= ForgeResult.SUCCESS
            or FORGE.ForgeOS:getApplicationPresentationModel("phone", AppId)
                ~= nil
            or FORGE.ForgeOS:getApplicationBadge("phone", AppId) ~= 0 then
            error("Hidden Host presentation gate failed")
        end

        cleanup()
    end)

    cleanup()
    if not succeeded then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.TEST,
            "Communications Application integration test failed: %s",
            FORGE.Logger:safeToString(failure, "<unprintable error>")
        )
        return false, failure
    end
    FORGE.Logger:info(
        FORGE.Definitions.LogSource.TEST,
        "Communications Application integration test passed"
    )
    return true
end
