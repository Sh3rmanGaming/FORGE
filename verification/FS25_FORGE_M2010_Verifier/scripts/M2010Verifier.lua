---=============================================================================
--- FORGE M2.010 Controlled Runtime Verifier
---
--- Temporary external-consumer fixture. This companion registers one
--- declarative app during the real registration window, then uses only public
--- ForgeOS operations to create or inspect controlled runtime evidence.
---=============================================================================

M2010Verifier = {
    appId = "forge.verification.m2_010",
    deviceId = "phone",
    initialized = false,
    registrationSucceeded = false,
    runtimeEvaluated = false,
    visibleEvidenceReported = false,
    forgeOS = nil
}

local DEPENDENCY_MOD = "FS25_FORGE_Engine"
local BRIDGE_VERSION = 1
local BRIDGE_TOPIC = "forge.crossMod.forgeOS.request.v1"
local REQUIRED_APP_API = 1
local SUCCESS = "success"
local REGISTRATION_OPEN = "registrationOpen"
local RUNTIME_ACTIVE = "runtimeActive"
local VISIBLE = "visible"

local TITLES = {
    unread = "M2.010 Verification Unread",
    read = "M2.010 Verification Read",
    dismissed = "M2.010 Verification Dismissed"
}

local function log(level, message, ...)
    if Logging ~= nil and type(Logging[level]) == "function" then
        Logging[level]("M2.010 verifier: " .. message, ...)
    else
        print(string.format("M2.010 verifier: " .. message, ...))
    end
end

local function disableSetup(reason)
    M2010Verifier.initialized = false
    M2010Verifier.registrationSucceeded = false
    M2010Verifier.runtimeEvaluated = false
    M2010Verifier.visibleEvidenceReported = false
    M2010Verifier.forgeOS = nil
    log("error", "setup disabled: %s", reason)
end

local function acquireForgeOS()
    if g_modManager == nil
        or type(g_modManager.getModByName) ~= "function" then
        return nil, "GIANTS ModManager dependency lookup unavailable"
    end
    if g_modManager:getModByName(DEPENDENCY_MOD) == nil then
        return nil, "dependency is not known"
    end
    if g_modIsLoaded == nil or g_modIsLoaded[DEPENDENCY_MOD] ~= true then
        return nil, "dependency is not loaded"
    end
    if type(g_messageCenter) ~= "table"
        or type(g_messageCenter.publish) ~= "function" then
        return nil, "GIANTS MessageCenter carrier unavailable"
    end

    local response = {
        requestedBridgeVersion = BRIDGE_VERSION,
        responderCount = 0
    }
    local published, publishFailure = pcall(
        g_messageCenter.publish,
        g_messageCenter,
        BRIDGE_TOPIC,
        response
    )
    if not published then
        return nil, "bridge publication failed: " .. tostring(publishFailure)
    end
    if response.responderCount ~= 1 then
        return nil,
            "bridge responder count is " .. tostring(response.responderCount)
    end
    if response.bridgeVersion ~= BRIDGE_VERSION then
        return nil,
            "bridge version is " .. tostring(response.bridgeVersion)
    end

    local forgeOS = response.forgeOS
    response = nil
    if type(forgeOS) ~= "table" then
        return nil, "FORGE.ForgeOS façade did not resolve to a table"
    end

    local requiredOperations = {
        "getAppApiVersion",
        "supportsAppApiVersion",
        "getPhase",
        "registerApp",
        "getNotifications",
        "createNotification",
        "markNotificationRead",
        "dismissNotification",
        "openApp",
        "activateApp",
        "navigate",
        "getCurrentRoute",
        "getDeviceVisibility",
        "getActiveAppId"
    }
    for _, operation in ipairs(requiredOperations) do
        if type(forgeOS[operation]) ~= "function" then
            return nil, "required public operation unavailable: " .. operation
        end
    end

    if forgeOS:getAppApiVersion() ~= REQUIRED_APP_API
        or forgeOS:supportsAppApiVersion(REQUIRED_APP_API) ~= true then
        return nil, "App API version 1 is incompatible"
    end

    return forgeOS, nil
end

local function controlledNotifications()
    local found = {}
    local notifications = M2010Verifier.forgeOS:getNotifications("phone", true)
    for _, notification in ipairs(notifications) do
        if notification.source == M2010Verifier.appId then
            for state, title in pairs(TITLES) do
                if notification.title == title
                    and type(notification.metadata) == "table"
                    and notification.metadata.verification == "M2.010"
                    and notification.metadata.expectedState == state then
                    found[state] = notification
                end
            end
        end
    end
    return found
end

local function createNotification(expectedState, body)
    local result, notificationId = M2010Verifier.forgeOS:createNotification({
        source = M2010Verifier.appId,
        title = TITLES[expectedState],
        body = body,
        severity = "info",
        persistence = "savegame",
        targetDevices = { phone = true },
        metadata = {
            verification = "M2.010",
            expectedState = expectedState
        }
    })
    if result ~= SUCCESS or notificationId == nil then
        error("controlled " .. expectedState
            .. " notification creation failed: " .. tostring(result))
    end
    return notificationId
end

local function assertRoute(expectedMarker)
    local routeId, parameters = M2010Verifier.forgeOS:getCurrentRoute(
        M2010Verifier.deviceId,
        M2010Verifier.appId
    )
    if routeId ~= "verification.resume"
        or type(parameters) ~= "table"
        or parameters.verification ~= "M2.010"
        or parameters.resumeMarker ~= expectedMarker then
        error("route evidence mismatch: route=" .. tostring(routeId))
    end
end

local function establishFixture()
    if M2010Verifier.forgeOS:openApp(
            M2010Verifier.deviceId,
            M2010Verifier.appId
        ) ~= SUCCESS
        or M2010Verifier.forgeOS:activateApp(
            M2010Verifier.deviceId,
            M2010Verifier.appId
        ) ~= SUCCESS
        or M2010Verifier.forgeOS:navigate(
            M2010Verifier.deviceId,
            M2010Verifier.appId,
            "verification.resume",
            {
                verification = "M2.010",
                resumeMarker = "cycle1"
            }
        ) ~= SUCCESS then
        error("controlled app lifecycle/navigation setup failed")
    end

    assertRoute("cycle1")

    createNotification(
        "unread",
        "This SAVEGAME notification must remain unread."
    )
    local readId = createNotification(
        "read",
        "This SAVEGAME notification must restore as read."
    )
    local dismissedId = createNotification(
        "dismissed",
        "This SAVEGAME notification must restore as dismissed."
    )

    if M2010Verifier.forgeOS:markNotificationRead(readId) ~= SUCCESS
        or M2010Verifier.forgeOS:dismissNotification(dismissedId)
            ~= SUCCESS then
        error("controlled notification state setup failed")
    end

    log(
        "info",
        "FIXTURE_CREATION complete; route=verification.resume marker=cycle1 unread=1 read=1 dismissed=1"
    )
end

local function verifyRestoration(found)
    if not found.unread or not found.read or not found.dismissed then
        error("partial controlled notification fixture restored; refusing mutation")
    end
    if found.unread.read or found.unread.dismissed
        or not found.read.read or found.read.dismissed
        or not found.dismissed.dismissed then
        error("restored controlled notification states do not match")
    end

    log(
        "info",
        "RESTORATION_VERIFICATION records confirmed; unread=1 read=1 dismissed=1"
    )
end

function M2010Verifier:loadMap(mapName)
    self.initialized = true
    self.runtimeEvaluated = false
    self.visibleEvidenceReported = false

    local forgeOS, acquisitionFailure = acquireForgeOS()
    if forgeOS == nil then
        disableSetup(acquisitionFailure)
        return
    end
    self.forgeOS = forgeOS

    local phase = forgeOS:getPhase()
    if phase ~= REGISTRATION_OPEN then
        disableSetup("registration phase is " .. tostring(phase))
        return
    end

    local result = forgeOS:registerApp({
        id = self.appId,
        apiVersion = REQUIRED_APP_API,
        displayName = "M2.010 Verification",
        supportedDevices = { phone = true },
        presentations = {
            phone = {
                id = "forge.verification.m2_010.phone",
                defaultRoute = "verification.home",
                routes = {
                    ["verification.home"] = {},
                    ["verification.resume"] = {}
                }
            }
        }
    })
    if result ~= SUCCESS then
        disableSetup("app registration failed: " .. tostring(result))
        return
    end

    self.registrationSucceeded = true
    log(
        "info",
        "cross-mod acquisition VERIFIED dependencyKnown=true dependencyLoaded=true messageCenter=true topicPublished=true responderCount=1 synchronousMutation=true bridgeVersion=1 facade=table appApi=1 supported=true phase=registrationOpen registration=success"
    )
end

function M2010Verifier:update(dt)
    if not self.initialized or not self.registrationSucceeded then
        return
    end

    if self.forgeOS:getPhase() ~= RUNTIME_ACTIVE then
        return
    end

    if not self.runtimeEvaluated then
        self.runtimeEvaluated = true
        local found = controlledNotifications()
        local count = 0
        for _ in pairs(found) do count = count + 1 end

        local succeeded, failure = pcall(function()
            if count == 0 then
                establishFixture()
            else
                verifyRestoration(found)
            end
        end)
        if not succeeded then
            log("error", "%s", tostring(failure))
            return
        end
    end

    if not self.visibleEvidenceReported
        and self.forgeOS:getDeviceVisibility(self.deviceId) == VISIBLE then
        local succeeded, failure = pcall(function()
            if self.forgeOS:getActiveAppId(self.deviceId) ~= self.appId then
                error("visible Phone did not activate verification app")
            end
            assertRoute("cycle1")
        end)
        if succeeded then
            self.visibleEvidenceReported = true
            log(
                "info",
                "visible Phone evidence confirmed; app=%s route=verification.resume marker=cycle1",
                self.appId
            )
        else
            self.visibleEvidenceReported = true
            log("error", "%s", tostring(failure))
        end
    end
end

function M2010Verifier:deleteMap()
    log("info", "companion lifecycle released")
    self.initialized = false
    self.registrationSucceeded = false
    self.runtimeEvaluated = false
    self.visibleEvidenceReported = false
    self.forgeOS = nil
end

addModEventListener(M2010Verifier)
