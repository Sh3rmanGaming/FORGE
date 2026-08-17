---=============================================================================
--- FORGE Application Presentation Service Tests
---
--- Verifies M3.004 validation, containment, detachment, and re-entrancy.
---=============================================================================

FORGE.Tests = FORGE.Tests or {}

function FORGE.Tests.runApplicationPresentationServiceTests()
    FORGE.Logger:info(
        FORGE.Definitions.LogSource.TEST,
        "Application Presentation Service test harness started"
    )

    local Result = FORGE.Definitions.ForgeOSResult
    local AppId = FORGE.Definitions.CommunicationsAppId.COMMUNICATIONS
    local mode = "valid"
    local reentrantModel = "unset"
    local reentrantAction = nil
    local provider = { protocolVersion = 1 }

    function provider:getModel(context)
        reentrantModel = FORGE.ForgeOS:getApplicationPresentationModel(
            context.deviceId,
            context.appId
        )
        local model = {
            modelVersion = 1,
            appId = context.appId,
            presentationId = context.presentationId,
            routeId = context.routeId,
            title = "Test",
            badgeCount = 3,
            content = {
                kind = "communications.inbox",
                emptyText = "Empty",
                rows = {}
            },
            actions = {
                {
                    id = "test.valid",
                    label = "Valid",
                    parameters = {}
                }
            }
        }
        if mode == "unknownModelField" then
            model.unknown = true
        end
        return model
    end

    function provider:getBadge(_)
        if mode == "badBadge" then
            return -1
        end
        return 3
    end

    function provider:performAction(context, actionId, _)
        if actionId == "test.failure" then
            error("intentional presentation provider failure")
        end
        if actionId == "test.invalidOutcome" then
            return {
                completed = true,
                domainResult = "success",
                unknown = true
            }
        end
        reentrantAction = FORGE.ForgeOS:performApplicationAction(
            context.deviceId,
            context.appId,
            "test.valid",
            {}
        )
        return {
            completed = true,
            domainResult = "success"
        }
    end

    local function cleanup()
        FORGE.ForgeOS:shutdown()
        FORGE.EventBus:clearAll()
        FORGE.StateStore:clearAll()
        FORGE.SaveManager:clearAllRegistrations()
    end

    local succeeded, failure = pcall(function()
        cleanup()
        if FORGE.ForgeOS:performApplicationAction(
                nil,
                AppId,
                "test.valid",
                {}
            ) ~= Result.INVALID_ARGUMENT
            or FORGE.ForgeOS:getApplicationBadge(
                "phone",
                AppId
            ) ~= 0 then
            error("Presentation argument or phase precedence failed")
        end

        if FORGE.ForgeOS:start() ~= Result.SUCCESS
            or FORGE.ForgeOS:registerApp({
                id = AppId,
                apiVersion = FORGE.Definitions.ForgeOSVersion.APP_API,
                displayName = "Test Presentation",
                supportedDevices = { phone = true },
                presentations = {
                    phone = {
                        id = "forge.communications.phone",
                        controller = provider,
                        defaultRoute = "inbox",
                        routes = { inbox = {} },
                        actions = {
                            ["test.valid"] = true,
                            ["test.failure"] = true,
                            ["test.invalidOutcome"] = true
                        }
                    }
                }
            }) ~= Result.SUCCESS
            or FORGE.ForgeOS:completeStartup() ~= Result.SUCCESS
            or FORGE.ForgeOS:showDevice("phone") ~= Result.SUCCESS
            or FORGE.ForgeOS:getApplicationBadge("phone", AppId) ~= 3
            or FORGE.ForgeOS:openApp("phone", AppId)
                ~= Result.SUCCESS
            or FORGE.ForgeOS:activateApp("phone", AppId)
                ~= Result.SUCCESS then
            error("Presentation Service fixture setup failed")
        end

        local definition = FORGE.ForgeOS:getAppDefinition(
            AppId
        )
        if definition.presentations.phone.controller ~= nil then
            error("Private provider escaped detached app definition")
        end

        local model = FORGE.ForgeOS:getApplicationPresentationModel(
            "phone",
            AppId
        )
        if model == nil
            or model.badgeCount ~= 3
            or reentrantModel ~= nil
            or FORGE.ForgeOS:getApplicationBadge(
                "phone",
                AppId
            ) ~= 3 then
            error("Model, badge, or query re-entrancy failed")
        end
        model.title = "mutated"
        local repeated = FORGE.ForgeOS:getApplicationPresentationModel(
            "phone",
            AppId
        )
        if repeated.title ~= "Test" then
            error("Provider model was not detached")
        end

        mode = "unknownModelField"
        if FORGE.ForgeOS:getApplicationPresentationModel(
                "phone",
                AppId
            ) ~= nil then
            error("Unknown model field was accepted")
        end
        mode = "badBadge"
        if FORGE.ForgeOS:getApplicationBadge(
                "phone",
                AppId
            ) ~= 0 then
            error("Invalid badge was accepted")
        end
        mode = "valid"

        local actionResult, outcome =
            FORGE.ForgeOS:performApplicationAction(
                "phone",
                AppId,
                "test.valid",
                {}
            )
        if actionResult ~= Result.SUCCESS
            or not outcome.completed
            or reentrantAction ~= Result.NOT_AVAILABLE then
            error("Action delivery or re-entrancy failed")
        end

        if FORGE.ForgeOS:performApplicationAction(
                "phone",
                AppId,
                "missing",
                {}
            ) ~= Result.INVALID_ARGUMENT
            or FORGE.ForgeOS:performApplicationAction(
                "phone",
                AppId,
                "test.failure",
                {}
            ) ~= Result.CALLBACK_FAILED
            or FORGE.ForgeOS:performApplicationAction(
                "phone",
                AppId,
                "test.invalidOutcome",
                {}
            ) ~= Result.CALLBACK_FAILED then
            error("Action declaration or failure containment failed")
        end

        cleanup()
    end)

    cleanup()
    if not succeeded then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.TEST,
            "Application Presentation Service test harness failed: %s",
            FORGE.Logger:safeToString(failure, "<unprintable error>")
        )
        return false, failure
    end
    FORGE.Logger:info(
        FORGE.Definitions.LogSource.TEST,
        "Application Presentation Service test harness passed"
    )
    return true
end
