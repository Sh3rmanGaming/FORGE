---=============================================================================
--- FORGE ForgeOS Application Lifecycle Service Tests
---
--- Manual component harness for the M2.007 Lifecycle Service.
---
--- Responsibilities:
---     • Verify lifecycle transitions, idempotence, policy, and queries.
---     • Verify callback ordering, failure isolation, and re-entrancy.
---     • Verify atomic displacement, events, cleanup, and restart.
---
--- This manual harness is invoked only by the Engine development test runner.
---=============================================================================

FORGE.Tests = FORGE.Tests or {}

function FORGE.Tests.runAppLifecycleServiceTests()
    FORGE.Logger:info(
        FORGE.Definitions.LogSource.TEST,
        "App Lifecycle Service test harness started"
    )

    local Result = FORGE.Definitions.ForgeOSResult
    local State = FORGE.Definitions.AppLifecycleState
    local Capability = FORGE.Definitions.DeviceCapability
    local calls = {}
    local lifecycleEventCount = 0
    local lifecycleEvents = {}
    local failRequested = false
    local reentrantResult = nil

    local function app(appId)
        local function record(name)
            return function(context)
                table.insert(calls, appId .. ":" .. name)
                if name == "activate"
                    and appId == "forge.second" then
                    reentrantResult = FORGE.ForgeOS
                        :closeApp("phone", appId)
                    if failRequested then
                        error("intentional lifecycle callback failure")
                    end
                end
                if context.playerId
                    ~= FORGE.Definitions.ForgeOSPlayerId.LOCAL then
                    error("invalid callback context")
                end
            end
        end
        return {
            id = appId,
            apiVersion = FORGE.Definitions.ForgeOSVersion.APP_API,
            displayName = appId,
            supportedDevices = {
                phone = true,
                terminal = true
            },
            presentations = {
                phone = {
                    id = appId .. ".phone",
                    defaultRoute = "home",
                    routes = { home = {} }
                },
                terminal = {
                    id = appId .. ".terminal",
                    defaultRoute = "home",
                    routes = { home = {} }
                }
            },
            callbacks = {
                onOpen = record("open"),
                onActivate = record("activate"),
                onBackground = record("background"),
                onClose = record("close")
            }
        }
    end

    local function cleanup()
        FORGE.ForgeOS:shutdown()
        FORGE.EventBus:clearAll()
        FORGE.StateStore:clearAll()
        FORGE.SaveManager:clearAllRegistrations()
    end

    local success, errorMessage = pcall(function()
        cleanup()
        if FORGE.ForgeOS:openApp(nil, "bad")
                ~= Result.INVALID_ARGUMENT
            or FORGE.ForgeOS:openApp("phone", "forge.first")
                ~= Result.NOT_AVAILABLE
            or FORGE.ForgeOS:start() ~= Result.SUCCESS then
            error("Lifecycle result precedence failed")
        end

        if FORGE.ForgeOS:registerDevice({
                id = "terminal",
                displayName = "Terminal",
                capabilities = {}
            }) ~= Result.SUCCESS
            or FORGE.ForgeOS:registerApp(app("forge.first"))
                ~= Result.SUCCESS
            or FORGE.ForgeOS:registerApp(app("forge.second"))
                ~= Result.SUCCESS then
            error("Lifecycle registration failed")
        end

        if FORGE.AppRegistry:getLifecycleCallback(
                "forge.first", "onOpen"
            ) == nil
            or FORGE.AppRegistry:getLifecycleCallback(
                "forge.first", "onRegister"
            ) ~= nil
            or FORGE.AppRegistry:getLifecycleCallback(
                "forge.first", "controller"
            ) ~= nil
            or FORGE.AppRegistry:getLifecycleCallback(
                "forge.unknown", "onOpen"
            ) ~= nil then
            error("Lifecycle callback accessor boundary failed")
        end

        local publicSnapshot =
            FORGE.AppRegistry:getAppDefinition("forge.first")
        if publicSnapshot.callbacks ~= nil
            or publicSnapshot.controller ~= nil
            or publicSnapshot.availabilityProviders ~= nil then
            error("Lifecycle callback leaked into public snapshot")
        end

        if FORGE.ForgeOS:completeStartup() ~= Result.SUCCESS
            or FORGE.AppRegistry:getLifecycleCallback(
                "forge.first", "onOpen"
            ) == nil then
            error("Frozen lifecycle setup failed")
        end

        for _, eventId in ipairs({
            FORGE.Definitions.ForgeOSEvent.APP_OPENED,
            FORGE.Definitions.ForgeOSEvent.APP_ACTIVATED,
            FORGE.Definitions.ForgeOSEvent.APP_BACKGROUNDED,
            FORGE.Definitions.ForgeOSEvent.APP_CLOSED
        }) do
            local observer = { eventId = eventId }
            function observer:onEvent(payload)
                if payload.playerId
                        ~= FORGE.Definitions.ForgeOSPlayerId.LOCAL
                    or payload.deviceId == nil
                    or payload.appId == nil
                    or payload.previousState == nil
                    or payload.currentState == nil then
                    error("Lifecycle event payload failed")
                end
                lifecycleEventCount = lifecycleEventCount + 1
                table.insert(lifecycleEvents, {
                    eventId = self.eventId,
                    appId = payload.appId,
                    previousState = payload.previousState,
                    currentState = payload.currentState
                })
            end
            FORGE.EventBus:subscribe(
                eventId,
                observer,
                observer.onEvent
            )
        end

        if FORGE.ForgeOS:openApp("missing", "forge.first")
                ~= Result.NOT_REGISTERED
            or FORGE.ForgeOS:openApp("phone", "forge.missing")
                ~= Result.NOT_REGISTERED
            or FORGE.ForgeOS:activateApp("phone", "forge.first")
                ~= Result.INVALID_TRANSITION
            or FORGE.ForgeOS:backgroundApp("phone", "forge.first")
                ~= Result.INVALID_TRANSITION then
            error("Lifecycle controlled failure results failed")
        end

        if FORGE.ForgeOS:openApp("phone", "forge.first")
                ~= Result.SUCCESS
            or FORGE.ForgeOS:activateApp("phone", "forge.first")
                ~= Result.SUCCESS
            or FORGE.ForgeOS:getActiveAppId("phone")
                ~= "forge.first"
            or FORGE.ForgeOS:getAppLifecycleState(
                "phone", "forge.first"
            ) ~= State.ACTIVE then
            error("Initial lifecycle transition failed")
        end

        local callCount = #calls
        local eventCount = lifecycleEventCount
        if FORGE.ForgeOS:openApp("phone", "forge.first")
                ~= Result.SUCCESS
            or FORGE.ForgeOS:activateApp("phone", "forge.first")
                ~= Result.SUCCESS
            or #calls ~= callCount
            or lifecycleEventCount ~= eventCount then
            error("Lifecycle idempotence failed")
        end

        if FORGE.AppLifecycleService:setAppEnabled(
                "forge.second", false
            ) ~= Result.SUCCESS
            or FORGE.ForgeOS:openApp("phone", "forge.second")
                ~= Result.POLICY_REJECTED
            or FORGE.AppLifecycleService:setAppEnabled(
                "forge.second", true
            ) ~= Result.SUCCESS
            or FORGE.ForgeOS:openApp("phone", "forge.second")
                ~= Result.SUCCESS then
            error("Lifecycle enabled policy failed")
        end

        failRequested = true
        local eventsBeforeFailure = lifecycleEventCount
        if FORGE.ForgeOS:activateApp("phone", "forge.second")
                ~= Result.CALLBACK_FAILED
            or FORGE.ForgeOS:getActiveAppId("phone")
                ~= "forge.first"
            or FORGE.ForgeOS:getAppLifecycleState(
                "phone", "forge.first"
            ) ~= State.ACTIVE
            or FORGE.ForgeOS:getAppLifecycleState(
                "phone", "forge.second"
            ) ~= State.OPEN
            or reentrantResult ~= Result.NOT_AVAILABLE
            or lifecycleEventCount ~= eventsBeforeFailure then
            error("Lifecycle callback rollback boundary failed")
        end

        failRequested = false
        local eventsBeforeDisplacement = lifecycleEventCount
        if FORGE.ForgeOS:activateApp("phone", "forge.second")
                ~= Result.SUCCESS
            or FORGE.ForgeOS:getAppLifecycleState(
                "phone", "forge.first"
            ) ~= State.BACKGROUND
            or FORGE.ForgeOS:getActiveAppId("phone")
                ~= "forge.second"
            or calls[#calls - 1] ~= "forge.first:background"
            or calls[#calls] ~= "forge.second:activate"
            or lifecycleEventCount
                ~= eventsBeforeDisplacement + 2 then
            error("Lifecycle displacement ordering failed")
        end

        local displacedEvent = lifecycleEvents[#lifecycleEvents - 1]
        local requestedEvent = lifecycleEvents[#lifecycleEvents]
        if displacedEvent.eventId
                ~= FORGE.Definitions.ForgeOSEvent.APP_BACKGROUNDED
            or displacedEvent.appId ~= "forge.first"
            or requestedEvent.eventId
                ~= FORGE.Definitions.ForgeOSEvent.APP_ACTIVATED
            or requestedEvent.appId ~= "forge.second" then
            error("Lifecycle event ordering failed")
        end

        if FORGE.ForgeOS:activateApp("phone", "forge.first")
                ~= Result.SUCCESS
            or FORGE.ForgeOS:getAppLifecycleState(
                "phone", "forge.second"
            ) ~= State.BACKGROUND then
            error("Background to active transition failed")
        end

        if FORGE.ForgeOS:openApp("terminal", "forge.first")
                ~= Result.SUCCESS
            or FORGE.ForgeOS:backgroundApp("terminal", "forge.first")
                ~= Result.SUCCESS
            or FORGE.ForgeOS:closeApp("terminal", "forge.first")
                ~= Result.SUCCESS
            or FORGE.ForgeOS:openApp("terminal", "forge.first")
                ~= Result.SUCCESS
            or FORGE.ForgeOS:activateApp("terminal", "forge.first")
                ~= Result.SUCCESS
            or FORGE.ForgeOS:openApp("terminal", "forge.second")
                ~= Result.SUCCESS
            or FORGE.ForgeOS:activateApp("terminal", "forge.second")
                ~= Result.SUCCESS
            or FORGE.ForgeOS:getAppLifecycleState(
                "terminal", "forge.first"
            ) ~= State.CLOSED then
            error("Non-background displacement failed")
        end

        local failingListener = {}
        function failingListener:onEvent()
            error("intentional lifecycle listener failure")
        end
        FORGE.EventBus:subscribe(
            FORGE.Definitions.ForgeOSEvent.APP_CLOSED,
            failingListener,
            failingListener.onEvent
        )
        if FORGE.ForgeOS:closeApp("terminal", "forge.second")
                ~= Result.SUCCESS
            or FORGE.ForgeOS:getAppLifecycleState(
                "terminal", "forge.second"
            ) ~= State.CLOSED then
            error("Lifecycle listener isolation failed")
        end

        if FORGE.ForgeOS:closeApp("phone", "forge.second")
                ~= Result.SUCCESS
            or FORGE.ForgeOS:backgroundApp("phone", "forge.first")
                ~= Result.SUCCESS
            or FORGE.ForgeOS:backgroundApp("phone", "forge.first")
                ~= Result.SUCCESS
            or FORGE.ForgeOS:closeApp("phone", "forge.first")
                ~= Result.SUCCESS
            or FORGE.ForgeOS:closeApp("phone", "forge.first")
                ~= Result.SUCCESS
            or FORGE.ForgeOS:shutdown() ~= Result.SUCCESS
            or FORGE.ForgeOS:getActiveAppId("phone") ~= nil
            or FORGE.ForgeOS:getAppLifecycleState(
                "phone", "forge.first"
            ) ~= State.CLOSED then
            error("Lifecycle cleanup failed")
        end
        cleanup()
    end)

    if not success then
        pcall(cleanup)
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.TEST,
            "App Lifecycle Service test harness failed: %s",
            FORGE.Logger:safeToString(errorMessage, "<unprintable error>")
        )
        return false, errorMessage
    end

    FORGE.Logger:info(
        FORGE.Definitions.LogSource.TEST,
        "App Lifecycle Service test harness passed"
    )
    return true
end
