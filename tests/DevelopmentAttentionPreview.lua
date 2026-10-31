---=============================================================================
--- FORGE Development Attention Preview
---
--- Development-only. Registers a few inert preview applications whose
--- launcher badges show each PF.005 attention state, so the shapes, sizes and
--- counts can be judged on screen. Registered only when the Logger is in
--- development mode; the operational build never calls it.
---
--- The preview applications own no domain state, take no actions, and persist
--- nothing.
---=============================================================================

FORGE.DevelopmentAttentionPreview = {}

local Preview = FORGE.DevelopmentAttentionPreview
local DeviceId = FORGE.Definitions.DeviceId

local ROUTE = "home"
local Entries = {
    { key = "unread7", name = "Unread 7",
        attention = { state = "unread", count = 7 } },
    { key = "unread42", name = "Unread 42",
        attention = { state = "unread", count = 42 } },
    { key = "unread150", name = "Unread 150",
        attention = { state = "unread", count = 150 } },
    { key = "attention", name = "Attention",
        attention = { state = "attention" } },
    { key = "warning3", name = "Warning 3",
        attention = { state = "warning", count = 3 } },
    { key = "error", name = "Error",
        attention = { state = "error" } }
}

local function createProvider(entry)
    local provider = { protocolVersion = 1 }

    function provider:getModel(context)
        return {
            modelVersion = 2,
            appId = context.appId,
            presentationId = context.presentationId,
            routeId = context.routeId,
            title = entry.name,
            actions = {},
            view = {
                component = "layout.stack",
                properties = {},
                children = {
                    {
                        component = "content.text",
                        properties = {
                            text = "Attention preview. This application is "
                                .. "for development verification only.",
                            textWrap = "word",
                            textOverflow = "ellipsis"
                        }
                    }
                }
            }
        }
    end

    function provider:getBadge(_)
        return entry.attention.count or 0
    end

    function provider:getAttention(_)
        local copy = {}
        for key, value in pairs(entry.attention) do
            copy[key] = value
        end
        return copy
    end

    function provider:performAction(_, _, _)
        return { completed = false, domainResult = "notAvailable" }
    end

    return provider
end

local function presentation(identifier, provider)
    return {
        id = identifier,
        controller = provider,
        defaultRoute = ROUTE,
        routes = { [ROUTE] = {} },
        actions = {}
    }
end

local testMessageCount = 0
local testNotificationCount = 0
local consoleRegistered = false

--- Console command target: creates one unread Communications message, with a
--- linked notification for both devices, so the unread badge, the Phone banner,
--- the Laptop toast and the tap-to-open path can be exercised in the game.
--- Development builds only. The message is saved with the savegame, so use a
--- throwaway save.
function Preview:consoleCreateTestMessage()
    testMessageCount = testMessageCount + 1
    local result = FORGE.Communications:createMessage({
        source = "forge.verification.preview",
        subject = "Test message " .. tostring(testMessageCount),
        body = "Created by the forgeTestMessage development command.",
        channel = "system",
        recipient = "player.local",
        notification = {
            title = "Test message " .. tostring(testMessageCount),
            body = "Created by the forgeTestMessage development command.",
            severity = FORGE.Definitions.NotificationSeverity.INFO,
            persistence = FORGE.Definitions.NotificationPersistence.SAVEGAME,
            targetDevices = { [DeviceId.PHONE] = true,
                [DeviceId.LAPTOP] = true }
        }
    })
    if result ~= FORGE.Definitions.CommunicationsResult.SUCCESS then
        return "forgeTestMessage failed: "
            .. FORGE.Logger:safeToString(result, "<unknown>")
    end
    return "FORGE test message " .. tostring(testMessageCount)
        .. " created; unread count is "
        .. tostring(FORGE.Communications:getUnreadCount())
end

local Destinations = {
    inbox = { appId = "forge.communications", routeId = "inbox" },
    missing = { appId = "forge.communications", routeId = "noSuchRoute" },
    badparams = { appId = "forge.communications", routeId = "messageDetail",
        parameters = { bogus = 1 } }
}

local function createPlainNotification(severity, destinationName, label)
    testNotificationCount = testNotificationCount + 1
    local result, identifier = FORGE.ForgeOS:createNotification({
        source = "forge.verification.preview",
        title = label .. " " .. tostring(testNotificationCount),
        body = "Development " .. severity .. " notification, destination "
            .. destinationName .. ".",
        severity = severity,
        persistence = FORGE.Definitions.NotificationPersistence.SESSION,
        targetDevices = { [DeviceId.PHONE] = true, [DeviceId.LAPTOP] = true },
        route = Destinations[destinationName]
    })
    return result, identifier
end

--- Console command target: forgeTestNotification [severity] [destination].
--- Severity: info (default), success, warning, error, critical. Destination:
--- none (default), inbox, missing (a route that does not exist), badparams (a
--- route with parameters its schema rejects). Not saved with the savegame.
function Preview:consoleCreateTestNotification(severity, destination)
    severity = severity or FORGE.Definitions.NotificationSeverity.INFO
    destination = destination or "none"
    if not Destinations[destination] and destination ~= "none" then
        return "Unknown destination '" .. tostring(destination)
            .. "'; use none, inbox, missing or badparams"
    end
    local result = createPlainNotification(severity, destination, "Test")
    if result ~= FORGE.Definitions.ForgeOSResult.SUCCESS then
        return "forgeTestNotification failed: "
            .. FORGE.Logger:safeToString(result, "<unknown>")
    end
    return "FORGE test notification " .. tostring(testNotificationCount)
        .. " created (" .. severity .. ", destination " .. destination .. ")"
end

--- Console command target: creates five notifications at once to exercise the
--- Phone waiting queue and the Laptop toast stack limit. Not saved.
function Preview:consoleCreateTestNotificationBurst()
    local created = 0
    for _ = 1, 5 do
        if createPlainNotification(
            FORGE.Definitions.NotificationSeverity.INFO, "inbox", "Burst")
            == FORGE.Definitions.ForgeOSResult.SUCCESS then
            created = created + 1
        end
    end
    return "FORGE test notification burst: " .. tostring(created)
        .. " of 5 created"
end

-----------------------------------------------------------------------------
-- Guided test run (development builds only)
--
-- One key starts a scripted tour of the PF.006 behaviours and walks through it
-- by itself, asking for a screenshot at each point that needs one. The
-- game's own screenshot call is tried first; if it does not produce a file the
-- run waits at each point and the player takes the screenshot, then presses
-- the key again to continue. Taps are simulated by calling the same activation
-- the Hosts use, so no pointer mode is needed.
-----------------------------------------------------------------------------

local Severity = FORGE.Definitions.NotificationSeverity
local Stage = FORGE.Definitions.NotificationActivationStage

local SETTLE_MS = 1500
local AFTER_SNAP_MS = 700
local AUTO_CHECK_MS = 2000
local SOUND_GAP_MS = 2000

local run = nil
local autoScreenshot = nil -- nil unknown, true works, false unavailable

local function log(message, ...)
    FORGE.Logger:info(FORGE.Definitions.LogSource.TEST, message, ...)
end

local function closeBoth()
    FORGE.ForgeOS:hideDevice(DeviceId.PHONE)
    FORGE.ForgeOS:hideDevice(DeviceId.LAPTOP)
end

local function newestNotificationId(deviceId)
    local newest = nil
    for _, record in ipairs(FORGE.ForgeOS:getNotifications(deviceId, false)) do
        if newest == nil or record.createdOrder > newest.createdOrder then
            newest = record
        end
    end
    return newest ~= nil and newest.id or nil
end

--- Taps the newest notification on one device, as a banner or toast tap does.
local function tapNewest(deviceId)
    local id = newestNotificationId(deviceId)
    if id == nil then
        return
    end
    local outcome = FORGE.NotificationActivationService:activate(deviceId, id)
    if type(outcome) == "table"
        and (outcome.stage == Stage.NAVIGATE
            or outcome.stage == Stage.COMPLETE) then
        FORGE.ForgeOS:showDevice(deviceId)
    end
end

local function sendPlain(severity, destination, label)
    createPlainNotification(severity, destination, label)
end

local Steps = {
    { snap = "01-banner-phone-closed",
      text = "Phone closed: a message banner appears over the game",
      setup = function()
          closeBoth()
          Preview:consoleCreateTestMessage()
      end },
    { snap = "02-tap-opens-message",
      text = "Banner tapped: Phone opens on the message",
      setup = function() tapNewest(DeviceId.PHONE) end },
    { snap = "03-back-goes-to-inbox",
      text = "Back pressed: Phone returns to the Inbox",
      setup = function()
          FORGE.ForgeOS:goBack(DeviceId.PHONE, "forge.communications")
      end },
    { snap = "04-banner-phone-open",
      text = "Phone open: a message banner appears inside the Phone view",
      setup = function() Preview:consoleCreateTestMessage() end },
    { snap = "05-banner-queue-phone",
      text = "Phone closed: five at once, one banner and a +waiting count",
      setup = function()
          closeBoth()
          Preview:consoleCreateTestNotificationBurst()
      end },
    { snap = "06-toast-laptop",
      text = "Laptop open: one toast, no Phone banner",
      setup = function()
          closeBoth()
          FORGE.ForgeOS:showDevice(DeviceId.LAPTOP)
          Preview:consoleCreateTestMessage()
      end },
    { snap = "07-toast-stack-laptop",
      text = "Laptop open: five at once, three toasts stacked",
      setup = function() Preview:consoleCreateTestNotificationBurst() end },
    { snap = "08-tap-toast-opens-message",
      text = "Toast tapped: Laptop opens the message",
      setup = function() tapNewest(DeviceId.LAPTOP) end },
    { snap = "09-bad-destination",
      text = "Broken destination tapped: nothing opens, nothing breaks",
      setup = function()
          sendPlain(Severity.ERROR, "missing", "Broken")
          tapNewest(DeviceId.LAPTOP)
      end },
    { snap = "10-both-devices",
      text = "Phone and Laptop both open, then a message",
      setup = function()
          FORGE.ForgeOS:showDevice(DeviceId.PHONE)
          FORGE.ForgeOS:showDevice(DeviceId.LAPTOP)
          Preview:consoleCreateTestMessage()
      end },
    { text = "Listen: info, success, warning, error, critical, 2 s apart",
      sounds = true,
      setup = function() closeBoth() end }
}

local SoundSeverities = {
    Severity.INFO, Severity.SUCCESS, Severity.WARNING, Severity.ERROR,
    Severity.CRITICAL
}

local function takeScreenshot(name)
    if autoScreenshot == false or type(getUserProfileAppPath) ~= "function" then
        return false
    end
    local directory = getUserProfileAppPath()
        .. "modSettings/FS25_FORGE_Engine/screenshots/"
    if type(createFolder) == "function" then
        pcall(createFolder, directory)
    end
    local path = directory .. "PF.006-" .. name .. ".png"
    for _, functionName in ipairs({ "saveScreenshot", "takeScreenshot" }) do
        local candidate = rawget(_G, functionName)
        if type(candidate) == "function" and pcall(candidate, path) then
            run.pendingFile = path
            run.pendingMs = AUTO_CHECK_MS
            return true
        end
    end
    autoScreenshot = false
    log("Guided run: no usable in-game screenshot call; "
        .. "take screenshots yourself when prompted")
    return false
end

local function startStep(index)
    local step = Steps[index]
    if step == nil then
        log("Guided run finished")
        run.phase = "done"
        run.timer = 15000
        return
    end
    run.index = index
    local ok, failure = pcall(step.setup)
    if not ok then
        log("Guided run step %d failed: %s", index,
            FORGE.Logger:safeToString(failure, "<unprintable>"))
    end
    run.phase = "settle"
    run.timer = step.sounds and 0 or SETTLE_MS
    run.soundIndex = 0
end

--- Key target: starts the guided run, or moves on from a manual wait.
function Preview:onNextStep()
    if run == nil or run.phase == "done" then
        run = { phase = "idle", index = 0, timer = 0 }
        log("Guided run started")
        startStep(1)
        return true
    end
    if run.phase == "manual" then
        run.phase = "after"
        run.timer = 0
    end
    return true
end

--- Key target: creates one test message without the console.
function Preview:onTestMessage()
    log("%s", Preview:consoleCreateTestMessage())
    return true
end

local function updateSounds(dt)
    run.timer = run.timer - dt
    if run.timer > 0 then
        return
    end
    run.soundIndex = run.soundIndex + 1
    local severity = SoundSeverities[run.soundIndex]
    if severity == nil then
        run.phase = "after"
        run.timer = AFTER_SNAP_MS
        return
    end
    sendPlain(severity, "none", "Sound")
    run.timer = SOUND_GAP_MS
end

function Preview:update(dt)
    if run == nil then
        return
    end
    if run.pendingFile ~= nil then
        run.pendingMs = run.pendingMs - dt
        if type(fileExists) == "function" and fileExists(run.pendingFile) then
            autoScreenshot = true
            run.pendingFile = nil
        elseif run.pendingMs <= 0 then
            autoScreenshot = false
            run.pendingFile = nil
            log("Guided run: the screenshot call produced no file; "
                .. "take screenshots yourself when prompted")
            if run.phase == "after" then
                run.phase = "manual"
            end
        end
    end
    local step = Steps[run.index]
    if run.phase == "settle" then
        if step.sounds then
            updateSounds(dt)
            return
        end
        run.timer = run.timer - dt
        if run.timer <= 0 then
            log("SNAP %d/%d %s", run.index, #Steps - 1, step.snap)
            if takeScreenshot(step.snap) then
                run.phase = "after"
                run.timer = AFTER_SNAP_MS
            else
                run.phase = "manual"
            end
        end
    elseif run.phase == "after" and run.pendingFile == nil then
        run.timer = run.timer - dt
        if run.timer <= 0 then
            startStep(run.index + 1)
        end
    elseif run.phase == "done" then
        run.timer = run.timer - dt
        if run.timer <= 0 then
            run = nil
        end
    end
end

function Preview:draw()
    if run == nil or type(renderText) ~= "function" then
        return
    end
    local step = Steps[run.index]
    local line
    if run.phase == "done" then
        line = "FORGE test run finished. Save and quit, reload, then "
            .. "screenshot the Phone home screen."
    elseif step == nil then
        return
    elseif run.phase == "manual" then
        line = "TAKE SCREENSHOT NOW (" .. tostring(step.snap)
            .. "), then press the next-step key. " .. step.text
    else
        line = "FORGE test run " .. tostring(run.index) .. "/"
            .. tostring(#Steps) .. ": " .. step.text
    end
    if type(setTextAlignment) == "function" then
        setTextAlignment(RenderText and RenderText.ALIGN_CENTER or 1)
    end
    if type(setTextColor) == "function" then
        setTextColor(1, 0.85, 0.3, 1)
    end
    renderText(0.5, 0.965, 0.016, line)
    if type(setTextAlignment) == "function" then
        setTextAlignment(RenderText and RenderText.ALIGN_LEFT or 0)
    end
end

local function registerConsoleCommand()
    if consoleRegistered or type(addConsoleCommand) ~= "function" then
        return
    end
    consoleRegistered = true
    addConsoleCommand("forgeTestMessage",
        "Creates one unread FORGE Communications test message "
            .. "(development builds only)",
        "consoleCreateTestMessage", Preview)
    addConsoleCommand("forgeTestNotification",
        "Creates a FORGE test notification: [severity] [none|inbox|missing"
            .. "|badparams] (development builds only)",
        "consoleCreateTestNotification", Preview)
    addConsoleCommand("forgeTestNotificationBurst",
        "Creates five FORGE test notifications at once "
            .. "(development builds only)",
        "consoleCreateTestNotificationBurst", Preview)
end

--- Registers every preview application. Returns the number registered.
function Preview:register()
    local registered = 0
    for _, entry in ipairs(Entries) do
        local provider = createProvider(entry)
        local result = FORGE.ForgeOS:registerApp({
            id = "forge.devpreview." .. entry.key,
            ownerId = "forge",
            apiVersion = FORGE.Definitions.ForgeOSVersion.APP_API,
            displayName = entry.name,
            supportedDevices = {
                [DeviceId.PHONE] = true,
                [DeviceId.LAPTOP] = true
            },
            presentations = {
                [DeviceId.PHONE] = presentation(
                    "forge.devpreview." .. entry.key .. ".phone", provider),
                [DeviceId.LAPTOP] = presentation(
                    "forge.devpreview." .. entry.key .. ".laptop", provider)
            }
        })
        if result == FORGE.Definitions.ForgeOSResult.SUCCESS then
            registered = registered + 1
        else
            FORGE.Logger:warning(
                FORGE.Definitions.LogSource.TEST,
                "Attention preview application '%s' was not registered: %s",
                entry.key,
                FORGE.Logger:safeToString(result, "<unknown>")
            )
        end
    end
    registerConsoleCommand()
    return registered
end
