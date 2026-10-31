---=============================================================================
--- FORGE PF.006 Notification Presentation Coordinator Tests
---
--- Verifies event-driven cue delivery, targeting, per-notification sound
--- de-duplication, bounded queues, and cleanup, without touching real Hosts.
---=============================================================================

FORGE.Tests = FORGE.Tests or {}

function FORGE.Tests.runNotificationPresentationCoordinatorTests()
    local Coordinator = FORGE.NotificationPresentationCoordinator
    local Event = FORGE.Definitions.ForgeOSEvent

    local function check(condition, message)
        if not condition then
            error(message)
        end
    end

    local operational = { phone = true, laptop = true }
    local originalCheck = FORGE.ForgeOS.isRuntimeHostOperational
    local sounds = {}

    local function publish(id, severity, targets, route)
        FORGE.EventBus:publish(Event.NOTIFICATION_CREATED, {
            notificationId = id,
            notification = {
                id = id, source = "forge.test", title = "T " .. id,
                body = "B " .. id, severity = severity,
                targetDevices = targets, route = route,
                createdOrder = 1
            }
        })
    end

    local succeeded, failure = pcall(function()
        FORGE.ForgeOS.isRuntimeHostOperational = function(_, deviceId)
            return operational[deviceId] == true
        end
        Coordinator:stop()
        check(Coordinator:setSoundPlayer(function(cue)
            sounds[#sounds + 1] = cue
        end), "sound player rejected")
        check(not Coordinator:setSoundPlayer("loud"),
            "non-function sound player accepted")
        Coordinator:setSoundPlayer(function(cue) sounds[#sounds + 1] = cue end)

        -- Nothing is delivered before start.
        publish("notification.1", "info", { phone = true })
        check(Coordinator:getPendingCount("phone") == 0,
            "cue delivered before start")

        check(Coordinator:start(), "start failed")
        check(Coordinator:start(), "second start should be harmless")

        -- Targeting and cue types.
        publish("notification.2", "warning", { phone = true, laptop = true },
            { appId = "a", routeId = "r" })
        local phoneCues = Coordinator:takeCues("phone")
        local laptopCues = Coordinator:takeCues("laptop")
        check(#phoneCues == 1 and phoneCues[1].cueType == "phoneBanner"
            and phoneCues[1].notificationId == "notification.2"
            and phoneCues[1].actionable == true
            and phoneCues[1].title == "T notification.2",
            "phone cue wrong")
        check(#laptopCues == 1 and laptopCues[1].cueType == "laptopToast",
            "laptop cue wrong")
        check(phoneCues[1].sourceName == "forge.test",
            "an unregistered source should keep its id as the name")
        check(Coordinator:getPendingCount("phone") == 0,
            "taking cues should clear them")
        check(#Coordinator:takeCues("phone") == 0, "cues delivered twice")

        -- One sound per notification, not one per device.
        check(#sounds == 1 and sounds[1] == "warning",
            "expected one warning sound, got " .. #sounds)

        -- A cue with no destination is not actionable; one device only.
        publish("notification.3", "critical", { laptop = true })
        check(Coordinator:getPendingCount("phone") == 0
            and Coordinator:getPendingCount("laptop") == 1,
            "targeting ignored")
        check(Coordinator:takeCues("laptop")[1].actionable == false,
            "destination-less cue marked actionable")
        check(#sounds == 2 and sounds[2] == "critical",
            "critical severity sound missing")

        -- A repeated event for the same notification does not repeat sound.
        publish("notification.3", "critical", { laptop = true })
        check(#sounds == 2, "sound repeated for the same notification")
        Coordinator:takeCues("laptop")

        -- A device with no operational Host receives nothing and no sound.
        operational.phone = false
        publish("notification.4", "info", { phone = true })
        check(Coordinator:getPendingCount("phone") == 0
            and #sounds == 2, "non-operational Host received a cue")
        operational.phone = true

        -- Unknown devices and junk payloads are ignored.
        publish("notification.5", "info", { tablet = true })
        FORGE.EventBus:publish(Event.NOTIFICATION_CREATED, "junk")
        FORGE.EventBus:publish(Event.NOTIFICATION_CREATED, {})
        check(Coordinator:getPendingCount("phone") == 0
            and Coordinator:getPendingCount("laptop") == 0,
            "junk produced a cue")

        -- Each severity selects its own semantic sound.
        local expected = { info = "information", success = "success",
            warning = "warning", error = "error", critical = "critical" }
        local before = #sounds
        local index = 0
        for severity, cue in pairs(expected) do
            index = index + 1
            publish("notification.s" .. index, severity, { phone = true })
            check(sounds[#sounds] == cue, "severity " .. severity
                .. " selected " .. tostring(sounds[#sounds]))
        end
        check(#sounds == before + 5, "severity sounds missing")
        Coordinator:takeCues("phone")

        -- The pending queue is bounded; the newest cues survive.
        for number = 1, 40 do
            publish("notification.b" .. number, "info", { phone = true })
        end
        check(Coordinator:getPendingCount("phone") == 16,
            "pending queue is not bounded")
        local kept = Coordinator:takeCues("phone")
        check(kept[16].notificationId == "notification.b40",
            "newest cue was dropped")

        -- A failing sound player never breaks delivery.
        Coordinator:setSoundPlayer(function() error("no audio") end)
        publish("notification.6", "info", { phone = true })
        check(Coordinator:getPendingCount("phone") == 1,
            "sound failure blocked the cue")
        Coordinator:takeCues("phone")

        -- Stop drops state and ignores later events.
        publish("notification.7", "info", { phone = true })
        Coordinator:stop()
        check(Coordinator:getPendingCount("phone") == 0,
            "stop left pending cues")
        publish("notification.8", "info", { phone = true })
        check(Coordinator:getPendingCount("phone") == 0,
            "event after stop produced a cue")
    end)

    FORGE.ForgeOS.isRuntimeHostOperational = originalCheck
    Coordinator:setSoundPlayer(nil)
    Coordinator:stop()

    if not succeeded then
        return false, failure
    end
    FORGE.Logger:info(FORGE.Definitions.LogSource.TEST,
        "Notification Presentation Coordinator test harness passed")
    return true
end
