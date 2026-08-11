---=============================================================================
--- FORGE M2.012 Controlled Runtime Verifier
---=============================================================================

M2012Verifier = {
    appId = "forge.verification.m2_012.acceptance",
    forgeOS = nil,
    registered = false,
    evaluated = false
}

local BRIDGE_TOPIC = "forge.crossMod.forgeOS.request.v1"
local SUCCESS = "success"
local VERIFICATION_KEY = "M2.012-acceptance-final"

local function log(level, message, ...)
    if Logging ~= nil and type(Logging[level]) == "function" then
        Logging[level]("M2.012 verifier: " .. message, ...)
    else
        print(string.format("M2.012 verifier: " .. message, ...))
    end
end

local function acquire()
    if g_modManager == nil
        or g_modManager:getModByName("FS25_FORGE_Engine") == nil
        or g_modIsLoaded == nil
        or g_modIsLoaded.FS25_FORGE_Engine ~= true
        or type(g_messageCenter) ~= "table"
        or type(g_messageCenter.publish) ~= "function" then
        return nil
    end
    local response = { requestedBridgeVersion = 1, responderCount = 0 }
    local published = pcall(
        g_messageCenter.publish,
        g_messageCenter,
        BRIDGE_TOPIC,
        response
    )
    if not published or response.responderCount ~= 1
        or response.bridgeVersion ~= 1
        or type(response.forgeOS) ~= "table" then
        return nil
    end
    local forgeOS = response.forgeOS
    response = nil
    if forgeOS:getAppApiVersion() ~= 1
        or forgeOS:supportsAppApiVersion(1) ~= true then
        return nil
    end
    return forgeOS
end

local function findFixture(forgeOS, fixtureKind)
    for _, notification in ipairs(forgeOS:getNotifications(nil, true)) do
        if notification.source == M2012Verifier.appId
            and type(notification.metadata) == "table"
            and notification.metadata.verification == VERIFICATION_KEY
            and notification.metadata.fixtureKind == fixtureKind then
            return notification
        end
    end
    return nil
end

local function hasDeviceRecord(forgeOS, deviceId, notificationId, dismissed)
    for _, notification in ipairs(
        forgeOS:getNotifications(deviceId, dismissed == true)
    ) do
        if notification.id == notificationId then return notification end
    end
    return nil
end

local function createNotificationFixture(forgeOS, fixtureKind, title)
    local result, identifier = forgeOS:createNotification({
        source = M2012Verifier.appId,
        title = title,
        body = "One notification identity projected to Phone and Laptop",
        severity = "info",
        persistence = "savegame",
        targetDevices = { phone = true, laptop = true },
        metadata = {
            verification = VERIFICATION_KEY,
            fixtureKind = fixtureKind,
            cycle = 1
        }
    })
    if result ~= SUCCESS then
        error(fixtureKind .. " notification creation failed: " .. tostring(result))
    end
    return identifier
end

local function verifySharedState(forgeOS, readId, dismissId)
    local phoneRead = hasDeviceRecord(forgeOS, "phone", readId, true)
    local laptopRead = hasDeviceRecord(forgeOS, "laptop", readId, true)
    local phoneDismiss = hasDeviceRecord(forgeOS, "phone", dismissId, true)
    local laptopDismiss = hasDeviceRecord(forgeOS, "laptop", dismissId, true)
    return phoneRead ~= nil and laptopRead ~= nil
        and phoneRead.read and laptopRead.read
        and phoneDismiss ~= nil and laptopDismiss ~= nil
        and phoneDismiss.dismissed and laptopDismiss.dismissed
        and hasDeviceRecord(forgeOS, "phone", dismissId, false) == nil
        and hasDeviceRecord(forgeOS, "laptop", dismissId, false) == nil
end

function M2012Verifier:loadMap()
    self.forgeOS = acquire()
    if self.forgeOS == nil then
        log("error", "bridge acquisition failed")
        return
    end
    if self.forgeOS:getPhase() ~= "registrationOpen" then
        log("error", "registration window closed")
        self.forgeOS = nil
        return
    end
    local result = self.forgeOS:registerApp({
        id = self.appId,
        apiVersion = 1,
        displayName = "M2.012 Verification",
        supportedDevices = { phone = true, laptop = true },
        presentations = {
            phone = {
                id = "forge.verification.m2_012.acceptance.phone",
                defaultRoute = "verification.phone",
                routes = { ["verification.phone"] = {} }
            },
            laptop = {
                id = "forge.verification.m2_012.acceptance.laptop",
                defaultRoute = "verification.laptop",
                routes = { ["verification.laptop"] = {} }
            }
        }
    })
    self.registered = result == SUCCESS
    log(self.registered and "info" or "error",
        "registration=%s responderCount=1 bridgeVersion=1 appApi=1 phase=registrationOpen",
        tostring(result))
end

function M2012Verifier:update()
    if not self.registered or self.evaluated
        or self.forgeOS:getPhase() ~= "runtimeActive" then
        return
    end
    self.evaluated = true
    local readFixture = findFixture(self.forgeOS, "sharedRead")
    local dismissFixture = findFixture(self.forgeOS, "sharedDismiss")
    local succeeded, failure = pcall(function()
        if readFixture == nil and dismissFixture == nil then
            for _, deviceId in ipairs({ "phone", "laptop" }) do
                local result = self.forgeOS:openApp(deviceId, self.appId)
                if result == SUCCESS then
                    result = self.forgeOS:activateApp(deviceId, self.appId)
                end
                if result == SUCCESS then
                    result = self.forgeOS:navigate(
                        deviceId,
                        self.appId,
                        "verification." .. deviceId,
                        { verification = VERIFICATION_KEY, deviceId = deviceId }
                    )
                end
                if result ~= SUCCESS then
                    error(deviceId .. " route fixture failed: " .. tostring(result))
                end
            end
            local readId = createNotificationFixture(
                self.forgeOS, "sharedRead", "M2.012 Mark Read"
            )
            local dismissId = createNotificationFixture(
                self.forgeOS, "sharedDismiss", "M2.012 Dismiss"
            )
            if self.forgeOS:markNotificationRead(readId) ~= SUCCESS
                or self.forgeOS:dismissNotification(dismissId) ~= SUCCESS
                or not verifySharedState(self.forgeOS, readId, dismissId) then
                error("same-runtime shared notification proof failed")
            end
            log("info", "CYCLE1_SHARED_STATE complete readId=%s dismissId=%s phoneRead=true laptopRead=true phoneDismiss=true laptopDismiss=true",
                tostring(readId), tostring(dismissId))
        elseif readFixture ~= nil and dismissFixture ~= nil then
            if not readFixture.read or not dismissFixture.dismissed then
                if self.forgeOS:markNotificationRead(readFixture.id)
                        ~= SUCCESS
                    or self.forgeOS:dismissNotification(dismissFixture.id)
                        ~= SUCCESS
                    or not verifySharedState(
                        self.forgeOS,
                        readFixture.id,
                        dismissFixture.id
                    ) then
                    error("recovered Cycle 1 shared notification proof failed")
                end
                log("info", "CYCLE1_SHARED_STATE complete readId=%s dismissId=%s phoneRead=true laptopRead=true phoneDismiss=true laptopDismiss=true recovered=true",
                    tostring(readFixture.id), tostring(dismissFixture.id))
            elseif not verifySharedState(
                    self.forgeOS,
                    readFixture.id,
                    dismissFixture.id
                ) then
                error("shared notification restoration failed")
            else
                if self.forgeOS:showDevice("phone") ~= SUCCESS
                    or self.forgeOS:showDevice("laptop") ~= SUCCESS then
                    error("device resume orchestration failed")
                end
                if self.forgeOS:getCurrentRoute("phone", self.appId)
                        ~= "verification.phone" then
                    error("Phone route restoration failed")
                end
                if self.forgeOS:getCurrentRoute("laptop", self.appId)
                        ~= "verification.laptop" then
                    error("Laptop route restoration failed")
                end
                log("info", "CYCLE2_RESTORATION complete sharedRead=true sharedDismiss=true routesIndependent=true")
            end
        else
            error("partial persisted M2.012 fixture detected")
        end
    end)
    if not succeeded then log("error", "%s", tostring(failure)) end
end

function M2012Verifier:deleteMap()
    self.forgeOS = nil
    self.registered = false
    self.evaluated = false
    log("info", "companion lifecycle released")
end

addModEventListener(M2012Verifier)
