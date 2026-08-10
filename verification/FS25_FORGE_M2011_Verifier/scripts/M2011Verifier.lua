---=============================================================================
--- FORGE M2.011 Controlled Runtime Verifier
---=============================================================================

M2011Verifier = {
    appId = "forge.verification.m2_011.acceptance",
    forgeOS = nil,
    registered = false,
    evaluated = false
}

local BRIDGE_TOPIC = "forge.crossMod.forgeOS.request.v1"
local SUCCESS = "success"

local function log(level, message, ...)
    if Logging ~= nil and type(Logging[level]) == "function" then
        Logging[level]("M2.011 verifier: " .. message, ...)
    else
        print(string.format("M2.011 verifier: " .. message, ...))
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
    local published = pcall(g_messageCenter.publish, g_messageCenter,
        BRIDGE_TOPIC, response)
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

local function findFixture(forgeOS, deviceId)
    for _, notification in ipairs(forgeOS:getNotifications(deviceId, true)) do
        if notification.source == M2011Verifier.appId
            and type(notification.metadata) == "table"
            and notification.metadata.verification == "M2.011-acceptance"
            and notification.metadata.deviceId == deviceId then
            return notification
        end
    end
    return nil
end

local function createFixture(forgeOS, deviceId)
    local result = forgeOS:openApp(deviceId, M2011Verifier.appId)
    if result == SUCCESS then
        result = forgeOS:activateApp(deviceId, M2011Verifier.appId)
    end
    if result == SUCCESS then
        result = forgeOS:navigate(deviceId, M2011Verifier.appId,
            "verification." .. deviceId, {
                verification = "M2.011-acceptance", deviceId = deviceId, cycle = 1
            })
    end
    if result ~= SUCCESS then
        error(deviceId .. " route fixture failed: " .. tostring(result))
    end
    local notificationResult = forgeOS:createNotification({
        source = M2011Verifier.appId,
        title = "M2.011 " .. deviceId .. " persistence",
        body = "Controlled M2.011 SAVEGAME fixture",
        severity = "info",
        persistence = "savegame",
        targetDevices = { [deviceId] = true },
        metadata = {
            verification = "M2.011-acceptance", deviceId = deviceId, cycle = 1
        }
    })
    if notificationResult ~= SUCCESS then
        error(deviceId .. " notification fixture failed")
    end
end

function M2011Verifier:loadMap()
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
        displayName = "M2.011 Verification",
        supportedDevices = { phone = true, laptop = true },
        presentations = {
            phone = {
                id = "forge.verification.m2_011.acceptance.phone",
                defaultRoute = "verification.phone",
                routes = { ["verification.phone"] = {} }
            },
            laptop = {
                id = "forge.verification.m2_011.acceptance.laptop",
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

function M2011Verifier:update()
    if not self.registered or self.evaluated
        or self.forgeOS:getPhase() ~= "runtimeActive" then
        return
    end
    self.evaluated = true
    local phone = findFixture(self.forgeOS, "phone")
    local laptop = findFixture(self.forgeOS, "laptop")
    local succeeded, failure = pcall(function()
        if phone == nil and laptop == nil then
            createFixture(self.forgeOS, "phone")
            createFixture(self.forgeOS, "laptop")
            log("info", "CYCLE1_FIXTURE complete phoneRoute=verification.phone laptopRoute=verification.laptop")
        elseif phone ~= nil and laptop ~= nil then
            if self.forgeOS:showDevice("phone") ~= SUCCESS
                or self.forgeOS:showDevice("laptop") ~= SUCCESS then
                error("device resume orchestration failed")
            end
            local phoneRoute = self.forgeOS:getCurrentRoute("phone", self.appId)
            local laptopRoute = self.forgeOS:getCurrentRoute("laptop", self.appId)
            if phoneRoute ~= "verification.phone"
                or laptopRoute ~= "verification.laptop" then
                error("independent route restoration failed")
            end
            log("info", "CYCLE2_RESTORATION complete phone=1 laptop=1 routesIndependent=true")
        else
            error("partial persisted fixture detected")
        end
    end)
    if not succeeded then log("error", "%s", tostring(failure)) end
end

function M2011Verifier:deleteMap()
    self.forgeOS = nil
    self.registered = false
    self.evaluated = false
    log("info", "companion lifecycle released")
end

addModEventListener(M2011Verifier)
