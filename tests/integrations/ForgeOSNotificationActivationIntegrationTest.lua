---=============================================================================
--- FORGE ForgeOS Notification Activation Integration Tests
---
--- Manual integration harness for PF.006 deep links and route parameter
--- schemas.
---
--- Responsibilities:
---     • Verify preflight changes nothing and reports exact outcomes.
---     • Verify open, activate, navigate order and read-after-navigation.
---     • Verify the route schema on direct, deep-link and resume paths.
---     • Verify the coordinator delivers one cue per targeted device.
---
--- This manual harness is invoked only by the Engine development test runner.
---=============================================================================

FORGE.Tests = FORGE.Tests or {}

function FORGE.Tests.runForgeOSNotificationActivationIntegrationTests()
    FORGE.Logger:info(
        FORGE.Definitions.LogSource.TEST,
        "ForgeOS Notification Activation integration test started"
    )
    local Result = FORGE.Definitions.ForgeOSResult
    local Outcome = FORGE.Definitions.NotificationActivationResult
    local Stage = FORGE.Definitions.NotificationActivationStage
    local Lifecycle = FORGE.Definitions.AppLifecycleState
    local Severity = FORGE.Definitions.NotificationSeverity
    local Persistence = FORGE.Definitions.NotificationPersistence

    local function check(condition, message)
        if not condition then
            error(message)
        end
    end

    local function cleanup()
        FORGE.NotificationPresentationCoordinator:setSoundPlayer(nil)
        FORGE.ForgeOS:shutdown()
        FORGE.EventBus:clearAll()
        FORGE.StateStore:clearAll()
        FORGE.SaveManager:clearAllRegistrations()
    end

    local function create(route, targets)
        local result, id = FORGE.ForgeOS:createNotification({
            source = "forge.test",
            title = "Title",
            body = "Body",
            severity = Severity.INFO,
            persistence = Persistence.SESSION,
            targetDevices = targets or { phone = true },
            route = route
        })
        check(result == Result.SUCCESS and id ~= nil,
            "notification creation failed")
        return id
    end

    local success, errorMessage = pcall(function()
        cleanup()
        check(FORGE.ForgeOS:start() == Result.SUCCESS,
            "ForgeOS start failed")
        check(FORGE.ForgeOS:registerApp({
            id = "forge.act",
            apiVersion = FORGE.Definitions.ForgeOSVersion.APP_API,
            displayName = "Activation",
            supportedDevices = { phone = true, laptop = true },
            presentations = {
                phone = {
                    id = "act.phone",
                    defaultRoute = "home",
                    routes = {
                        home = { parameters = {} },
                        detail = { parameters = {
                            itemId = { type = "string", required = true } } },
                        legacy = {}
                    }
                },
                laptop = {
                    id = "act.laptop",
                    defaultRoute = "home",
                    routes = { home = { parameters = {} } }
                }
            }
        }) == Result.SUCCESS, "app registration failed")
        check(FORGE.ForgeOS:registerApp({
            id = "forge.bad",
            apiVersion = FORGE.Definitions.ForgeOSVersion.APP_API,
            displayName = "Bad schema",
            supportedDevices = { phone = true },
            presentations = { phone = { id = "bad.phone",
                defaultRoute = "home",
                routes = { home = { parameters = { x = { type = "table" } } } }
            } }
        }) ~= Result.SUCCESS, "invalid route schema was registered")
        check(FORGE.ForgeOS:completeStartup() == Result.SUCCESS,
            "startup completion failed")

        local sounds = 0
        FORGE.NotificationPresentationCoordinator:setSoundPlayer(function()
            sounds = sounds + 1
        end)

        -- Direct navigation obeys the declared schema.
        check(FORGE.ForgeOS:openApp("phone", "forge.act") == Result.SUCCESS
            and FORGE.ForgeOS:activateApp("phone", "forge.act")
                == Result.SUCCESS, "direct setup failed")
        check(FORGE.ForgeOS:navigate("phone", "forge.act", "detail",
            { itemId = "x" }) == Result.SUCCESS, "valid navigation rejected")
        check(FORGE.ForgeOS:navigate("phone", "forge.act", "detail",
            { itemId = "x", extra = 1 }) == Result.INVALID_ARGUMENT,
            "unknown parameter accepted on direct navigation")
        check(FORGE.ForgeOS:navigate("phone", "forge.act", "detail")
            == Result.INVALID_ARGUMENT,
            "missing required parameter accepted on direct navigation")
        check(FORGE.ForgeOS:navigate("phone", "forge.act", "home",
            { x = 1 }) == Result.INVALID_ARGUMENT,
            "empty schema accepted a parameter")
        check(FORGE.ForgeOS:navigate("phone", "forge.act", "legacy",
            { anything = true }) == Result.SUCCESS,
            "legacy route without a schema was rejected")
        check(FORGE.ForgeOS:closeApp("phone", "forge.act") == Result.SUCCESS,
            "close failed")

        -- A valid deep link opens, activates, navigates, then marks read.
        local valid = create({ appId = "forge.act", routeId = "detail",
            parameters = { itemId = "item.1" } })
        check(FORGE.NotificationPresentationCoordinator
            :getPendingCount("phone") >= 1, "no cue was queued for the Phone")
        check(sounds >= 1, "no sound cue requested")
        local before = sounds
        local outcome = FORGE.NotificationActivationService
            :activate("phone", valid)
        check(outcome.result == Outcome.SUCCESS
            and outcome.stage == Stage.COMPLETE, "valid deep link failed: "
            .. tostring(outcome.result) .. " at " .. tostring(outcome.stage))
        check(FORGE.ForgeOS:getActiveAppId("phone") == "forge.act"
            and FORGE.ForgeOS:getCurrentRoute("phone", "forge.act")
                == "detail", "deep link did not land on the route")
        check(FORGE.ForgeOS:getNotification(valid).read == true,
            "notification not marked read after navigation")
        check(sounds == before, "activation requested another sound")
        -- A first-time open seeds the default route, so Back has a target.
        check(#FORGE.ForgeOS:getNavigationHistory("phone", "forge.act") == 1,
            "deep link did not seed the default route beneath the destination")
        check(FORGE.ForgeOS:goBack("phone", "forge.act") == Result.SUCCESS
            and FORGE.ForgeOS:getCurrentRoute("phone", "forge.act") == "home",
            "Back after a deep link did not return to the default route")

        -- Preflight failures change nothing and name the failure.
        local function untouched()
            return FORGE.ForgeOS:getAppLifecycleState("laptop", "forge.act")
                == Lifecycle.CLOSED
        end
        outcome = FORGE.NotificationActivationService
            :activate("phone", "notification.999")
        check(outcome.result == Outcome.VALIDATION_FAILED
            and outcome.stage == Stage.NONE, "unknown notification wrong")

        local noRoute = create(nil, { laptop = true })
        outcome = FORGE.NotificationActivationService:activate("laptop", noRoute)
        check(outcome.result == Outcome.VALIDATION_FAILED and untouched(),
            "destination-less notification wrong")

        local wrongDevice = create({ appId = "forge.act", routeId = "home" },
            { laptop = true })
        outcome = FORGE.NotificationActivationService
            :activate("phone", wrongDevice)
        check(outcome.result == Outcome.VALIDATION_FAILED,
            "wrong device accepted")

        local missingApp = create({ appId = "forge.nope", routeId = "home" },
            { laptop = true })
        outcome = FORGE.NotificationActivationService
            :activate("laptop", missingApp)
        check(outcome.result == Outcome.VALIDATION_FAILED and untouched(),
            "unregistered app wrong")

        local missingRoute = create({ appId = "forge.act", routeId = "gone" },
            { laptop = true })
        outcome = FORGE.NotificationActivationService
            :activate("laptop", missingRoute)
        check(outcome.result == Outcome.VALIDATION_FAILED
            and outcome.detail == Result.ROUTE_NOT_FOUND and untouched(),
            "missing route wrong")

        local badParameters = create({ appId = "forge.act", routeId = "home",
            parameters = { bogus = 1 } }, { laptop = true })
        outcome = FORGE.NotificationActivationService
            :activate("laptop", badParameters)
        check(outcome.result == Outcome.VALIDATION_FAILED and untouched()
            and FORGE.ForgeOS:getNotification(badParameters).read == false,
            "invalid parameters were not stopped in preflight")

        -- A lifecycle failure stops the sequence and leaves it unread.
        local blocked = create({ appId = "forge.act", routeId = "home" },
            { laptop = true })
        check(FORGE.AppLifecycleService:setAppEnabled("forge.act", false)
            == Result.SUCCESS, "disable failed")
        outcome = FORGE.NotificationActivationService
            :activate("laptop", blocked)
        check(outcome.result == Outcome.OPEN_FAILED
            and outcome.stage == Stage.PREFLIGHT
            and outcome.detail == Result.POLICY_REJECTED,
            "disabled app did not report an open failure")
        check(FORGE.ForgeOS:getNotification(blocked).read == false
            and untouched(), "failed activation changed state")
        FORGE.AppLifecycleService:setAppEnabled("forge.act", true)

        -- Phone and Laptop each get exactly their own cue.
        FORGE.NotificationPresentationCoordinator:takeCues("phone")
        FORGE.NotificationPresentationCoordinator:takeCues("laptop")
        local both = create({ appId = "forge.act", routeId = "home" },
            { phone = true, laptop = true })
        check(#FORGE.NotificationPresentationCoordinator:takeCues("phone")
            == 1 and #FORGE.NotificationPresentationCoordinator
                :takeCues("laptop") == 1, "each device should get one cue")

        -- Resume restoration obeys the same schema.
        local state = FORGE.StateStore:snapshot(
            FORGE.Definitions.ForgeOSNamespace.OS)
        local player = state.players[FORGE.Definitions.ForgeOSPlayerId.LOCAL]
        player.devices.phone.resume = { appId = "forge.act",
            presentationId = "act.phone", routeId = "detail",
            routeParameters = { itemId = 5 } }
        check(FORGE.StateStore:replaceNamespace(
            FORGE.Definitions.ForgeOSNamespace.OS, state),
            "resume setup failed")
        local resumeResult, resume = FORGE.NavigationService
            :getValidatedResumeDestination("phone")
        check(resumeResult == Result.SUCCESS and resume == nil,
            "resume with a bad parameter type was accepted")
        check(both ~= nil, "unused")

        cleanup()
    end)

    if not success then
        pcall(cleanup)
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.TEST,
            "ForgeOS Notification Activation integration test failed: %s",
            FORGE.Logger:safeToString(errorMessage, "<unprintable error>")
        )
        return false, errorMessage
    end
    FORGE.Logger:info(
        FORGE.Definitions.LogSource.TEST,
        "ForgeOS Notification Activation integration test passed"
    )
    return true
end
