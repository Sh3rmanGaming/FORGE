---=============================================================================
--- FORGE M3 Communications Cross-Launch Verifier
---
--- Development-only two-process verifier for the bounded M3.008 gate.
--- This source is loaded only by reviewed verification packages.
---=============================================================================

FORGE.Tests = FORGE.Tests or {}

local Verifier = {
    executed = false,
    appId = "forge.communications",
    marker = "M3.008"
}

local fixtureDefinitions = {
    unreadActive = {
        source = "forge.verification.unread",
        senderDisplayName = "M3 Verification",
        subject = "M3.008 unread active",
        body = "Cross-launch unread active message body.",
        channel = "message",
        priority = "important",
        read = false,
        archived = false
    },
    readActive = {
        source = "forge.verification.read",
        senderDisplayName = "M3 Verification Read",
        subject = "M3.008 read active",
        body = "Cross-launch read active message body.",
        channel = "mail",
        priority = "normal",
        read = true,
        archived = false
    },
    archived = {
        source = "forge.verification.archive",
        subject = "M3.008 archived",
        body = "Cross-launch archived unread message body.",
        channel = "system",
        priority = "normal",
        read = false,
        archived = true
    },
    linkedNotification = {
        source = "forge.verification.linked",
        senderDisplayName = "M3 Verification Link",
        subject = "M3.008 linked notification",
        body = "Cross-launch linked notification message body.",
        channel = "system",
        priority = "important",
        read = true,
        archived = false
    },
    crossDevice = {
        source = "forge.verification.devices",
        senderDisplayName = "M3 Verification Devices",
        subject = "M3.008 cross-device",
        body = "Cross-launch shared Phone and Laptop message body.",
        channel = "message",
        priority = "normal",
        read = false,
        archived = false
    }
}

local function fail(message)
    error(message, 0)
end

local function requireValue(condition, message)
    if not condition then
        fail(message)
    end
end

local function fixtureMetadata(name)
    return {
        verification = Verifier.marker,
        fixture = name
    }
end

local function collectFixtures()
    local found = {}
    local count = 0
    for _, message in ipairs(FORGE.Communications:getMessages(true)) do
        local metadata = message.metadata
        if type(metadata) == "table"
            and metadata.verification == Verifier.marker then
            count = count + 1
            local name = metadata.fixture
            if type(name) ~= "string" then
                fail("fixture marker has no controlled fixture identity")
            end
            found[name] = found[name] or {}
            found[name][#found[name] + 1] = message
        end
    end
    return found, count
end

local function parseSequence(identifier)
    local digits = type(identifier) == "string"
        and string.match(identifier, "^message%.(%d+)$") or nil
    return digits ~= nil and tonumber(digits) or nil
end

local function assertMessage(name, message)
    local expected = fixtureDefinitions[name]
    requireValue(expected ~= nil, "unexpected fixture identity: " .. name)
    requireValue(message ~= nil, "missing fixture: " .. name)
    requireValue(message.playerId == "player.local",
        name .. " recipient ownership did not restore")
    requireValue(message.source == expected.source,
        name .. " source did not restore")
    requireValue(message.senderDisplayName == expected.senderDisplayName,
        name .. " sender display did not restore")
    requireValue(message.subject == expected.subject,
        name .. " subject did not restore")
    requireValue(message.body == expected.body,
        name .. " body did not restore")
    requireValue(message.channel == expected.channel,
        name .. " channel did not restore")
    requireValue(message.priority == expected.priority,
        name .. " priority did not restore")
    requireValue(message.read == expected.read,
        name .. " read state did not restore")
    requireValue(message.archived == expected.archived,
        name .. " archive state did not restore")
    requireValue(type(message.metadata) == "table"
        and message.metadata.verification == Verifier.marker
        and message.metadata.fixture == name,
        name .. " metadata did not restore")
    local sequence = parseSequence(message.id)
    requireValue(sequence ~= nil and message.createdOrder == sequence,
        name .. " identifier or createdOrder is invalid")
end

local function createFixture(name)
    local expected = fixtureDefinitions[name]
    local definition = {
        source = expected.source,
        senderDisplayName = expected.senderDisplayName,
        subject = expected.subject,
        body = expected.body,
        channel = expected.channel,
        recipient = "player.local",
        priority = expected.priority,
        metadata = fixtureMetadata(name)
    }
    if name == "linkedNotification" then
        definition.notification = {
            title = "M3.008 linked notification alert",
            body = "M3.008 controlled notification summary.",
            severity = FORGE.Definitions.NotificationSeverity.INFO,
            persistence = FORGE.Definitions.NotificationPersistence.SAVEGAME,
            targetDevices = {
                [FORGE.Definitions.DeviceId.PHONE] = true,
                [FORGE.Definitions.DeviceId.LAPTOP] = true
            }
        }
    end
    local result, identifier, detail =
        FORGE.Communications:createMessage(definition)
    requireValue(result == FORGE.Definitions.CommunicationsResult.SUCCESS
        and identifier ~= nil, name .. " creation failed")
    local message = FORGE.Communications:getMessage(identifier)
    requireValue(message ~= nil, name .. " was not committed")
    FORGE.Logger:info(FORGE.Definitions.LogSource.TEST,
        "M3.008 Cycle 1 fixture %s committed as %s (createdOrder=%d)",
        name, identifier, message.createdOrder)
    return identifier, detail
end

local function requireBadge(expected)
    local phone = FORGE.ForgeOS:getApplicationBadge(
        FORGE.Definitions.DeviceId.PHONE, Verifier.appId)
    local laptop = FORGE.ForgeOS:getApplicationBadge(
        FORGE.Definitions.DeviceId.LAPTOP, Verifier.appId)
    requireValue(phone == expected and laptop == expected,
        string.format("shared badge mismatch: expected %d, phone=%s laptop=%s",
            expected, tostring(phone), tostring(laptop)))
end

local function openDetail(deviceId, messageId)
    local Result = FORGE.Definitions.ForgeOSResult
    requireValue(FORGE.ForgeOS:openApp(deviceId, Verifier.appId)
        == Result.SUCCESS, deviceId .. " open failed")
    requireValue(FORGE.ForgeOS:activateApp(deviceId, Verifier.appId)
        == Result.SUCCESS, deviceId .. " activate failed")
    requireValue(FORGE.ForgeOS:navigate(deviceId, Verifier.appId,
        "messageDetail", { messageId = messageId }) == Result.SUCCESS,
        deviceId .. " detail navigation failed")
    local routeId, parameters = FORGE.ForgeOS:getCurrentRoute(
        deviceId, Verifier.appId)
    requireValue(routeId == "messageDetail"
        and parameters.messageId == messageId,
        deviceId .. " independent detail route mismatch")
end

local function verifyNotification(message, expectedRead)
    requireValue(message.notificationId ~= nil,
        "linked notificationId is missing")
    local notification = FORGE.ForgeOS:getNotification(message.notificationId)
    requireValue(notification ~= nil,
        "linked notification did not restore")
    requireValue(notification.source == "forge.communications",
        "linked notification source mismatch")
    requireValue(notification.title == "M3.008 linked notification alert"
        and notification.body == "M3.008 controlled notification summary.",
        "linked notification content mismatch")
    requireValue(notification.persistence == "savegame"
        and notification.severity == "info",
        "linked notification definition mismatch")
    requireValue(notification.targetDevices.phone == true
        and notification.targetDevices.laptop == true,
        "linked notification targets mismatch")
    requireValue(notification.metadata.communicationsMessageId == message.id,
        "linked notification metadata mismatch")
    requireValue(notification.route.appId == Verifier.appId
        and notification.route.routeId == "messageDetail"
        and notification.route.parameters.messageId == message.id,
        "linked notification route mismatch")
    requireValue(notification.read == expectedRead,
        "linked notification read state mismatch")
end

local function findMetadataOnlyNotification(messageId)
    local matches = {}
    for _, notification in ipairs(FORGE.ForgeOS:getNotifications(
        FORGE.Definitions.DeviceId.PHONE, true)) do
        if notification.source == "forge.communications"
            and notification.metadata ~= nil
            and notification.metadata.communicationsMessageId == messageId
            and notification.metadata.verification == Verifier.marker
            and notification.metadata.fixture == "metadataOnly" then
            matches[#matches + 1] = notification
        end
    end
    return matches
end

local function runCycle1()
    FORGE.Logger:info(FORGE.Definitions.LogSource.TEST,
        "M3.008 cross-launch verifier Cycle 1 started; no fixture marker exists")
    requireValue(FORGE.ForgeOS:showDevice("phone")
        == FORGE.Definitions.ForgeOSResult.SUCCESS
        and FORGE.ForgeOS:showDevice("laptop")
            == FORGE.Definitions.ForgeOSResult.SUCCESS,
        "Cycle 1 Host visibility setup failed")
    requireBadge(0)

    local ids = {}
    ids.unreadActive = createFixture("unreadActive")
    ids.readActive = createFixture("readActive")
    ids.archived = createFixture("archived")
    local linkedId, linkedDetail = createFixture("linkedNotification")
    ids.linkedNotification = linkedId
    ids.crossDevice = createFixture("crossDevice")
    requireBadge(5)

    requireValue(FORGE.Communications:markMessageRead(ids.readActive)
        == FORGE.Definitions.CommunicationsResult.SUCCESS,
        "read fixture mutation failed")
    requireBadge(4)
    requireValue(FORGE.Communications:archiveMessage(ids.archived)
        == FORGE.Definitions.CommunicationsResult.SUCCESS,
        "archive fixture mutation failed")
    requireBadge(3)
    requireValue(linkedDetail ~= nil
        and linkedDetail.notificationResult
            == FORGE.Definitions.ForgeOSResult.SUCCESS
        and linkedDetail.notificationId ~= nil
        and linkedDetail.integrationResult == nil,
        "linked notification integration failed")
    requireValue(FORGE.Communications:markMessageRead(linkedId)
        == FORGE.Definitions.CommunicationsResult.SUCCESS,
        "linked message read mutation failed")
    requireBadge(2)
    verifyNotification(FORGE.Communications:getMessage(linkedId), true)

    local metadataResult, metadataNotificationId =
        FORGE.ForgeOS:createNotification({
            source = "forge.communications",
            title = "M3.008 metadata-only notification",
            body = "Must not reconstruct Communications linkage.",
            severity = FORGE.Definitions.NotificationSeverity.INFO,
            persistence = FORGE.Definitions.NotificationPersistence.SAVEGAME,
            targetDevices = {
                [FORGE.Definitions.DeviceId.PHONE] = true,
                [FORGE.Definitions.DeviceId.LAPTOP] = true
            },
            route = {
                appId = Verifier.appId,
                routeId = "messageDetail",
                parameters = { messageId = ids.crossDevice }
            },
            metadata = {
                communicationsMessageId = ids.crossDevice,
                verification = Verifier.marker,
                fixture = "metadataOnly"
            }
        })
    requireValue(metadataResult == FORGE.Definitions.ForgeOSResult.SUCCESS
        and metadataNotificationId ~= nil,
        "metadata-only notification creation failed")
    requireValue(FORGE.Communications:getMessage(
        ids.crossDevice).notificationId == nil,
        "metadata-only notification created authoritative linkage")
    requireValue(#findMetadataOnlyNotification(ids.crossDevice) == 1,
        "metadata-only notification query mismatch")
    FORGE.Logger:info(FORGE.Definitions.LogSource.TEST,
        "M3.008 Cycle 1 metadata-only notification %s retained without message linkage",
        metadataNotificationId)

    for name, identifier in pairs(ids) do
        assertMessage(name, FORGE.Communications:getMessage(identifier))
    end

    openDetail(FORGE.Definitions.DeviceId.PHONE, ids.unreadActive)
    openDetail(FORGE.Definitions.DeviceId.LAPTOP, ids.readActive)
    requireValue(FORGE.ForgeOS:getApplicationPresentationModel(
        "phone", Verifier.appId).content.message.messageId
            == ids.unreadActive,
        "Phone restored-data presentation fixture failed")
    requireValue(FORGE.ForgeOS:getApplicationPresentationModel(
        "laptop", Verifier.appId).content.message.messageId
            == ids.readActive,
        "Laptop restored-data presentation fixture failed")
    FORGE.ForgeOS:hideDevice("phone")
    FORGE.ForgeOS:hideDevice("laptop")

    FORGE.Logger:info(FORGE.Definitions.LogSource.TEST,
        "M3.008 cross-launch verifier Cycle 1 passed: fixtures=5 badge=2 phone=%s laptop=%s",
        ids.unreadActive, ids.readActive)
end

local function runCycle2(found, count)
    FORGE.Logger:info(FORGE.Definitions.LogSource.TEST,
        "M3.008 cross-launch verifier Cycle 2 restoration started")
    requireValue(count == 5,
        "restored fixture count is not exactly five")

    local messages = {}
    local highestSequence = 0
    for name in pairs(fixtureDefinitions) do
        requireValue(found[name] ~= nil and #found[name] == 1,
            name .. " fixture is missing or duplicated")
        local message = found[name][1]
        assertMessage(name, message)
        requireValue(messages[message.id] == nil,
            "restored message identifier collision")
        messages[message.id] = true
        highestSequence = math.max(highestSequence, parseSequence(message.id))
        FORGE.Logger:info(FORGE.Definitions.LogSource.TEST,
            "M3.008 Cycle 2 restored fixture %s as %s (createdOrder=%d read=%s archived=%s)",
            name, message.id, message.createdOrder,
            tostring(message.read), tostring(message.archived))
    end

    verifyNotification(found.linkedNotification[1], true)
    requireValue(found.crossDevice[1].notificationId == nil,
        "notification metadata incorrectly reconstructed message linkage")
    requireValue(#findMetadataOnlyNotification(found.crossDevice[1].id) == 1,
        "metadata-only notification did not restore exactly once")
    requireValue(FORGE.ForgeOS:getDeviceVisibility("phone") == "hidden"
        and FORGE.ForgeOS:getDeviceVisibility("laptop") == "hidden",
        "runtime-only Host visibility unexpectedly survived restart")
    requireValue(FORGE.ForgeOS:showDevice("phone")
        == FORGE.Definitions.ForgeOSResult.SUCCESS
        and FORGE.ForgeOS:showDevice("laptop")
            == FORGE.Definitions.ForgeOSResult.SUCCESS,
        "restored Host resume failed")
    requireBadge(2)

    local phoneRoute, phoneParameters = FORGE.ForgeOS:getCurrentRoute(
        "phone", Verifier.appId)
    local laptopRoute, laptopParameters = FORGE.ForgeOS:getCurrentRoute(
        "laptop", Verifier.appId)
    requireValue(phoneRoute == "messageDetail"
        and phoneParameters.messageId == found.unreadActive[1].id,
        "Phone route or parameters did not restore independently")
    requireValue(laptopRoute == "messageDetail"
        and laptopParameters.messageId == found.readActive[1].id,
        "Laptop route or parameters did not restore independently")
    requireValue(FORGE.ForgeOS:getApplicationPresentationModel(
        "phone", Verifier.appId).content.message.messageId
            == found.unreadActive[1].id,
        "Phone restored presentation failed")
    requireValue(FORGE.ForgeOS:getApplicationPresentationModel(
        "laptop", Verifier.appId).content.message.messageId
            == found.readActive[1].id,
        "Laptop restored presentation failed")

    local result, sequenceId = FORGE.Communications:createMessage({
        source = "forge.verification.sequence",
        subject = "M3.008 sequence continuation",
        body = "Created only after all Cycle 2 restoration assertions passed.",
        channel = "system",
        recipient = "player.local",
        metadata = {
            verification = "M3.008.sequence",
            fixture = "postRestoration"
        }
    })
    local sequence = parseSequence(sequenceId)
    requireValue(result == FORGE.Definitions.CommunicationsResult.SUCCESS
        and sequence ~= nil and sequence > highestSequence,
        "message sequence did not continue safely after restoration")
    requireValue(FORGE.Communications:archiveMessage(sequenceId)
        == FORGE.Definitions.CommunicationsResult.SUCCESS,
        "sequence continuation cleanup archive failed")
    requireBadge(2)

    FORGE.Logger:info(FORGE.Definitions.LogSource.TEST,
        "M3.008 cross-launch verifier Cycle 2 passed: fixtures=5 badge=2 sequence=%s runtimeVisibilityReset=true reverseLinkInference=false",
        sequenceId)
end

function Verifier:loadMap()
    self.executed = false
end

function Verifier:update()
    if self.executed
        or not FORGE.Logger:isDevelopmentMode()
        or FORGE.ForgeOS:getPhase()
            ~= FORGE.Definitions.ForgeOSPhase.RUNTIME_ACTIVE
        or not FORGE.CommunicationsService:isAvailable() then
        return
    end
    self.executed = true
    local succeeded, failure = pcall(function()
        local found, count = collectFixtures()
        if count == 0 then
            runCycle1()
            return
        end
        for name, records in pairs(found) do
            if fixtureDefinitions[name] == nil or #records ~= 1 then
                fail("unexpected or duplicate persisted fixture: " .. name)
            end
        end
        runCycle2(found, count)
    end)
    if succeeded then
        FORGE.Logger:info(FORGE.Definitions.LogSource.TEST,
            "M3.008 cross-launch runtime gate completed successfully")
    else
        FORGE.Logger:error(FORGE.Definitions.LogSource.TEST,
            "M3.008 cross-launch verifier STOP: %s",
            FORGE.Logger:safeToString(failure, "<unknown>"))
    end
end

function Verifier:deleteMap()
end

function Verifier:draw()
end

function Verifier:keyEvent()
end

function Verifier:mouseEvent()
end

FORGE.Tests.M3CommunicationsCrossLaunchVerifier = Verifier
addModEventListener(Verifier)
