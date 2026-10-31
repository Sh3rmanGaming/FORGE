---=============================================================================
--- FORGE ForgeOS Notification Presentation Coordinator
---
--- Turns completed notification-creation events into transient presentation
--- cues for operational Hosts (ADR-007).
---
--- Responsibilities:
---     • Consume only the completed NOTIFICATION_CREATED event.
---     • Hand each targeted Host a detached cue (Phone banner or Laptop toast).
---     • Request one semantic sound cue per notification, never one per device.
---
--- This coordinator owns no notification data, persists nothing, keeps no
--- history, and clears on shutdown. Hosts own queueing, timing and expiry of
--- what they show; expiry never reads or dismisses a notification.
---=============================================================================

FORGE.NotificationPresentationCoordinator = {}

local Coordinator = FORGE.NotificationPresentationCoordinator
local Event = FORGE.Definitions.ForgeOSEvent
local DeviceId = FORGE.Definitions.DeviceId
local CueType = FORGE.Definitions.NotificationCueType
local SoundCue = FORGE.Definitions.NotificationSoundCue
local Severity = FORGE.Definitions.NotificationSeverity

local MAX_PENDING = 16
local MAX_REMEMBERED_SOUNDS = 128

local CueTypeByDevice = {
    [DeviceId.PHONE] = CueType.PHONE_BANNER,
    [DeviceId.LAPTOP] = CueType.LAPTOP_TOAST
}

local SoundBySeverity = {
    [Severity.INFO] = SoundCue.INFORMATION,
    [Severity.SUCCESS] = SoundCue.SUCCESS,
    [Severity.WARNING] = SoundCue.WARNING,
    [Severity.ERROR] = SoundCue.ERROR,
    [Severity.CRITICAL] = SoundCue.CRITICAL
}

-- Provisional placeholders from the base game's interface sounds, chosen only
-- so each severity can be told apart while final audio is undecided. The first
-- name the game has is used; if none exist the cue is silent.
local PlaceholderSamples = {
    [SoundCue.INFORMATION] = { "CLICK" },
    [SoundCue.SUCCESS] = { "CONFIRM", "APPLY", "SUCCESS", "OK", "CLICK" },
    [SoundCue.WARNING] = { "HOVER", "WARNING", "ERROR", "CLICK" },
    [SoundCue.ERROR] = { "BACK", "ERROR", "CANCEL", "CLICK" },
    [SoundCue.CRITICAL] = { "BACK", "ERROR", "CANCEL", "CLICK" }
}

local listener = {}
local started = false
local pending = {}
local soundedNotifications = {}
local soundedCount = 0
local soundPlayer = nil
local soundOutcomeReported = {}
local sampleNamesReported = false
local lastSampleName = nil

local function reportSoundOutcome(soundCue, played, detail)
    if soundOutcomeReported[soundCue] then
        return
    end
    soundOutcomeReported[soundCue] = true
    FORGE.Logger:info(
        FORGE.Definitions.LogSource.NOTIFICATION,
        "Notification sound cue '%s' %s (%s)",
        soundCue,
        played and "played" or "was silent",
        FORGE.Logger:safeToString(detail, "no detail")
    )
end

--- Logs the base-game sample names once, so working ones can be chosen.
local function reportSampleNames(samples)
    if sampleNamesReported then
        return
    end
    sampleNamesReported = true
    local names = {}
    for name in pairs(samples) do
        names[#names + 1] = tostring(name)
    end
    table.sort(names)
    FORGE.Logger:info(
        FORGE.Definitions.LogSource.NOTIFICATION,
        "Base-game interface samples available: %s",
        table.concat(names, ", ")
    )
end

--- The default player: a provisional base-game interface sound, if present.
local function defaultSoundPlayer(soundCue)
    lastSampleName = nil
    local candidates = PlaceholderSamples[soundCue]
    local player = type(g_gui) == "table" and g_gui.guiSoundPlayer or nil
    local samples = type(GuiSoundPlayer) == "table"
        and GuiSoundPlayer.SOUND_SAMPLES or nil
    if candidates == nil or type(player) ~= "table"
        or type(player.playSample) ~= "function"
        or type(samples) ~= "table" then
        reportSoundOutcome(soundCue, false, "base-game sample unavailable")
        return false
    end
    reportSampleNames(samples)
    for _, sampleName in ipairs(candidates) do
        if samples[sampleName] ~= nil then
            local played = pcall(player.playSample, player, samples[sampleName])
            lastSampleName = sampleName
            reportSoundOutcome(soundCue, played, sampleName)
            return played
        end
    end
    reportSoundOutcome(soundCue, false, "base-game sample unavailable")
    return false
end

local function playSound(soundCue, notificationId)
    if soundedNotifications[notificationId] then
        return
    end
    if soundedCount >= MAX_REMEMBERED_SOUNDS then
        soundedNotifications = {}
        soundedCount = 0
    end
    soundedNotifications[notificationId] = true
    soundedCount = soundedCount + 1
    local call = { pcall(soundPlayer or defaultSoundPlayer, soundCue) }
    if not call[1] then
        FORGE.Logger:warning(
            FORGE.Definitions.LogSource.NOTIFICATION,
            "Notification sound cue failed: %s",
            FORGE.Logger:safeToString(call[2], "<unprintable error>")
        )
    end
end

local function enqueue(deviceId, cue)
    local queue = pending[deviceId]
    if queue == nil then
        queue = {}
        pending[deviceId] = queue
    end
    if #queue >= MAX_PENDING then
        table.remove(queue, 1)
    end
    queue[#queue + 1] = cue
end

--- The app's display name when the source is a registered app.
local function sourceName(source)
    local definition = FORGE.AppRegistry:getAppDefinition(source)
    if type(definition) == "table"
        and type(definition.displayName) == "string" then
        return definition.displayName
    end
    return source
end

local function onNotificationCreated(_, payload)
    local record = type(payload) == "table" and payload.notification or nil
    if type(record) ~= "table" or type(record.id) ~= "string"
        or type(record.targetDevices) ~= "table" then
        return
    end
    local delivered = false
    for deviceId, selected in pairs(record.targetDevices) do
        local cueType = CueTypeByDevice[deviceId]
        if selected == true and cueType ~= nil
            and FORGE.ForgeOS:isRuntimeHostOperational(deviceId) then
            enqueue(deviceId, {
                cueType = cueType,
                notificationId = record.id,
                source = record.source,
                sourceName = sourceName(record.source),
                title = record.title,
                body = record.body,
                severity = record.severity,
                actionable = record.route ~= nil,
                createdOrder = record.createdOrder
            })
            delivered = true
        end
    end
    if delivered then
        playSound(SoundBySeverity[record.severity] or SoundCue.INFORMATION,
            record.id)
    end
end

--- Starts listening for completed notification creation.
-- @return boolean started
function Coordinator:start()
    if started then
        return true
    end
    started = FORGE.EventBus:subscribe(
        Event.NOTIFICATION_CREATED, listener, onNotificationCreated)
    return started
end

--- Stops listening and drops every pending cue.
function Coordinator:stop()
    if started then
        FORGE.EventBus:unsubscribe(
            Event.NOTIFICATION_CREATED, listener, onNotificationCreated)
    end
    self:clearRuntimeState()
end

--- Returns and clears the pending cues for one device.
-- @param deviceId any
-- @return table cues Detached cues, oldest first
function Coordinator:takeCues(deviceId)
    local queue = pending[deviceId]
    if queue == nil then
        return {}
    end
    pending[deviceId] = nil
    return queue
end

--- Returns how many cues wait for one device.
function Coordinator:getPendingCount(deviceId)
    local queue = pending[deviceId]
    return queue ~= nil and #queue or 0
end

--- Returns the base-game sample the default player last used (development
-- builds show it on screen so the sound can be chosen by name).
function Coordinator:getLastSampleName()
    return lastSampleName
end

--- Replaces the sound player (used by tests); nil restores the default.
function Coordinator:setSoundPlayer(player)
    if player ~= nil and type(player) ~= "function" then
        return false
    end
    soundPlayer = player
    return true
end

--- Clears every runtime-only cue and listener flag.
function Coordinator:clearRuntimeState()
    started = false
    pending = {}
    soundedNotifications = {}
    soundedCount = 0
    soundOutcomeReported = {}
    sampleNamesReported = false
    return FORGE.Definitions.ForgeOSResult.SUCCESS
end
