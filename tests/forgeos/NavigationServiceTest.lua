---=============================================================================
--- FORGE ForgeOS Navigation Service Tests
---
--- Manual component harness for the M2.008 Navigation Service.
---
--- Responsibilities:
---     • Verify navigation gates, routes, parameters, history, and back.
---     • Verify detached resume and event state.
---     • Verify cleanup without executing private application assets.
---
--- This manual harness is invoked only by the Engine development test runner.
---=============================================================================

FORGE.Tests = FORGE.Tests or {}

function FORGE.Tests.runNavigationServiceTests()
    FORGE.Logger:info(
        FORGE.Definitions.LogSource.TEST,
        "Navigation Service test harness started"
    )

    local Result = FORGE.Definitions.ForgeOSResult
    local originalResolve = FORGE.PresentationResolver.resolvePresentation
    local providerCalls = 0
    local eventCount = 0
    local lastEvent = nil

    local function app()
        local routes = {}
        for index = 1, 35 do
            local routeId = string.format("route%02d", index)
            routes[routeId] = {
                controller = "privateController",
                availabilityProviders = {
                    {
                        isAvailable = function()
                            providerCalls = providerCalls + 1
                            return true
                        end
                    }
                }
            }
        end
        return {
            id = "forge.navigation",
            apiVersion = FORGE.Definitions.ForgeOSVersion.APP_API,
            displayName = "Navigation",
            supportedDevices = { phone = true },
            presentations = {
                phone = {
                    id = "navigation.phone",
                    defaultRoute = "route01",
                    routes = routes
                }
            }
        }
    end

    local function cleanup()
        FORGE.PresentationResolver.resolvePresentation = originalResolve
        FORGE.ForgeOS:shutdown()
        FORGE.EventBus:clearAll()
        FORGE.StateStore:clearAll()
        FORGE.SaveManager:clearAllRegistrations()
    end

    local success, errorMessage = pcall(function()
        cleanup()
        local cyclic = {}
        cyclic.self = cyclic
        local shared = {}
        local sharedParameters = { left = shared, right = shared }
        if FORGE.ForgeOS:navigate(nil, "app", "route", {})
                ~= Result.INVALID_ARGUMENT
            or FORGE.ForgeOS:navigate("phone", "app", "route", cyclic)
                ~= Result.INVALID_ARGUMENT
            or FORGE.ForgeOS:navigate(
                "phone", "app", "route", sharedParameters
            ) ~= Result.INVALID_ARGUMENT
            or FORGE.ForgeOS:navigate(
                "phone", "app", "route", { [1] = "invalid" }
            ) ~= Result.INVALID_ARGUMENT
            or FORGE.ForgeOS:navigate(
                "phone", "app", "route", { value = math.huge }
            ) ~= Result.INVALID_ARGUMENT
            or FORGE.ForgeOS:navigate("phone", "app", "route", {})
                ~= Result.NOT_AVAILABLE then
            error("Navigation argument or phase precedence failed")
        end

        if FORGE.ForgeOS:start() ~= Result.SUCCESS
            or FORGE.ForgeOS:registerApp(app()) ~= Result.SUCCESS
            or FORGE.ForgeOS:completeStartup() ~= Result.SUCCESS then
            error("Navigation runtime setup failed")
        end

        if FORGE.ForgeOS:navigate("missing", "forge.navigation", "route01")
                ~= Result.NOT_REGISTERED
            or FORGE.ForgeOS:navigate("phone", "forge.missing", "route01")
                ~= Result.NOT_REGISTERED
            or FORGE.ForgeOS:navigate("phone", "forge.navigation", "route01")
                ~= Result.INVALID_TRANSITION
            or FORGE.ForgeOS:openApp("phone", "forge.navigation")
                ~= Result.SUCCESS
            or FORGE.ForgeOS:navigate("phone", "forge.navigation", "route01")
                ~= Result.INVALID_TRANSITION
            or FORGE.ForgeOS:activateApp("phone", "forge.navigation")
                ~= Result.SUCCESS
            or FORGE.ForgeOS:navigate("phone", "forge.navigation", "missing")
                ~= Result.ROUTE_NOT_FOUND
            or FORGE.ForgeOS:goBack("phone", "forge.navigation")
                ~= Result.ROUTE_NOT_FOUND then
            error("Navigation registration or lifecycle gates failed")
        end

        local observer = {}
        function observer:onEvent(payload)
            eventCount = eventCount + 1
            lastEvent = payload
        end
        FORGE.EventBus:subscribe(
            FORGE.Definitions.ForgeOSEvent.NAVIGATION_CHANGED,
            observer,
            observer.onEvent
        )

        local parameters = {
            projectId = "project.one",
            nested = { enabled = true, amount = 1.5 }
        }
        if FORGE.ForgeOS:navigate(
                "phone", "forge.navigation", "route01", parameters
            ) ~= Result.SUCCESS then
            error("First navigation failed")
        end
        parameters.nested.enabled = false
        local route, queryParameters = FORGE.ForgeOS:getCurrentRoute(
            "phone", "forge.navigation"
        )
        if route ~= "route01"
            or queryParameters.nested.enabled ~= true
            or lastEvent.currentRoute ~= "route01"
            or lastEvent.previousRoute ~= nil
            or lastEvent.isBackNavigation ~= false then
            error("Navigation detached state or event failed")
        end
        queryParameters.nested.enabled = false

        local eventsBeforeIdempotence = eventCount
        if FORGE.ForgeOS:navigate(
                "phone", "forge.navigation", "route01",
                { nested = { amount = 1.5, enabled = true }, projectId = "project.one" }
            ) ~= Result.SUCCESS
            or eventCount ~= eventsBeforeIdempotence
            or #FORGE.ForgeOS:getNavigationHistory(
                "phone", "forge.navigation"
            ) ~= 0 then
            error("Navigation idempotence failed")
        end

        for index = 2, 35 do
            if FORGE.ForgeOS:navigate(
                "phone",
                "forge.navigation",
                string.format("route%02d", index),
                { index = index }
            ) ~= Result.SUCCESS then
                error("Navigation history setup failed")
            end
        end
        local history = FORGE.ForgeOS:getNavigationHistory(
            "phone", "forge.navigation"
        )
        if #history ~= 32
            or history[1].routeId ~= "route03"
            or history[32].routeId ~= "route34" then
            error("Bounded navigation history failed")
        end
        history[1].routeId = "mutated"

        if FORGE.ForgeOS:goBack("phone", "forge.navigation")
                ~= Result.SUCCESS then
            error("Back navigation failed")
        end
        route = FORGE.ForgeOS:getCurrentRoute("phone", "forge.navigation")
        if route ~= "route34"
            or lastEvent.isBackNavigation ~= true
            or lastEvent.previousRoute ~= "route35" then
            error("Back navigation state failed")
        end

        local failing = {}
        function failing:onEvent()
            error("intentional Navigation listener failure")
        end
        FORGE.EventBus:subscribe(
            FORGE.Definitions.ForgeOSEvent.NAVIGATION_CHANGED,
            failing,
            failing.onEvent
        )
        if FORGE.ForgeOS:navigate(
                "phone", "forge.navigation", "route35"
            ) ~= Result.SUCCESS then
            error("Navigation listener isolation failed")
        end

        FORGE.PresentationResolver.resolvePresentation = function(self, appId, deviceId)
            local result, resolution = originalResolve(self, appId, deviceId)
            if result == Result.SUCCESS then
                resolution.presentation.routes = { route03 = {} }
            end
            return result, resolution
        end
        if FORGE.ForgeOS:goBack("phone", "forge.navigation")
                ~= Result.SUCCESS
            or FORGE.ForgeOS:getCurrentRoute("phone", "forge.navigation")
                ~= "route03" then
            error("Invalid history repair failed")
        end
        FORGE.PresentationResolver.resolvePresentation = originalResolve

        local state, found = FORGE.StateStore:snapshot(
            FORGE.Definitions.ForgeOSNamespace.OS
        )
        local resume = found
            and state.players[FORGE.Definitions.ForgeOSPlayerId.LOCAL]
                .devices.phone.resume
            or nil
        if resume == nil
            or resume.appId ~= "forge.navigation"
            or resume.presentationId ~= "navigation.phone"
            or resume.routeId ~= "route03"
            or providerCalls ~= 0 then
            error("Navigation resume or executable isolation failed")
        end

        local resumeResult, validatedResume =
            FORGE.NavigationService
                :getValidatedResumeDestination("phone")
        if resumeResult ~= Result.SUCCESS
            or validatedResume == nil
            or validatedResume.routeId ~= "route03" then
            error("Validated resume destination was not returned")
        end
        validatedResume.routeParameters.mutated = true
        local _, secondResume = FORGE.NavigationService
            :getValidatedResumeDestination("phone")
        if secondResume.routeParameters.mutated ~= nil then
            error("Validated resume destination was not detached")
        end

        if FORGE.ForgeOS:shutdown() ~= Result.SUCCESS
            or FORGE.ForgeOS:getCurrentRoute(
                "phone", "forge.navigation"
            ) ~= nil
            or #FORGE.ForgeOS:getNavigationHistory(
                "phone", "forge.navigation"
            ) ~= 0
            or FORGE.ForgeOS:start() ~= Result.SUCCESS
            or FORGE.ForgeOS:shutdown() ~= Result.SUCCESS then
            error("Navigation cleanup or restart failed")
        end
        cleanup()
    end)

    if not success then
        pcall(cleanup)
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.TEST,
            "Navigation Service test harness failed: %s",
            FORGE.Logger:safeToString(errorMessage, "<unprintable error>")
        )
        return false, errorMessage
    end

    FORGE.Logger:info(
        FORGE.Definitions.LogSource.TEST,
        "Navigation Service test harness passed"
    )
    return true
end
