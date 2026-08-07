---=============================================================================
--- FORGE ForgeOS App Registry Tests
---
--- Manual component harness for the M2.005 App Registry capability.
---
--- Responsibilities:
---     • Verify app, presentation, route, and action validation.
---     • Verify API compatibility, atomicity, copies, and deterministic lookup.
---     • Verify event completion and executable-reference isolation.
---     • Verify participant freeze, cleanup, and restart behaviour.
---
--- This manual harness is invoked only by the Engine development test runner.
---=============================================================================

FORGE.Tests = FORGE.Tests or {}

function FORGE.Tests.runAppRegistryTests()
    FORGE.Logger:info(
        FORGE.Definitions.LogSource.TEST,
        "App Registry test harness started"
    )

    local success, errorMessage = pcall(function()
        local Result =
            FORGE.Definitions.ForgeOSResult
        local Event =
            FORGE.Definitions.ForgeOSEvent
        local Capability =
            FORGE.Definitions.DeviceCapability

        local function createApp(appId)
            return {
                id = appId,
                ownerId = "forge",
                apiVersion = FORGE.Definitions
                    .ForgeOSVersion.APP_API,
                displayName = "Test App",
                controller = {
                    open = function()
                    end
                },
                supportedDevices = {
                    phone = true,
                    laptop = false
                },
                requiredCapabilities = {
                    [Capability.NOTIFICATIONS] = true
                },
                presentations = {
                    phone = {
                        id = appId .. ".phone",
                        defaultRoute = "overview",
                        routes = {
                            overview = {
                                controller = "showOverview",
                                metadata = {
                                    title = "Overview"
                                }
                            }
                        },
                        actions = {
                            open = true,
                            inspect = {
                                handler = "inspect",
                                enabled = true
                            }
                        },
                        priority = 100
                    }
                },
                callbacks = {
                    onOpen = function()
                    end
                },
                availabilityProviders = {
                    {
                        isAvailable = function()
                            return true
                        end
                    }
                },
                metadata = {
                    category = "test"
                },
                ignored = "unknown"
            }
        end

        FORGE.ForgeOS:shutdown()
        FORGE.EventBus:clearAll()
        FORGE.StateStore:clearAll()
        FORGE.SaveManager:clearAllRegistrations()

        if FORGE.ForgeOS:start()
            ~= Result.SUCCESS then
            error("App Registry lifecycle did not start")
        end

        local observed = {
            count = 0,
            appId = nil
        }
        function observed:onRegistered(payload)
            self.count = self.count + 1
            self.appId = payload.appId
        end
        FORGE.EventBus:subscribe(
            Event.APP_REGISTERED,
            observed,
            observed.onRegistered
        )

        if FORGE.ForgeOS:registerApp(nil)
                ~= Result.INVALID_ARGUMENT
            or FORGE.ForgeOS:registerApp("app")
                ~= Result.INVALID_ARGUMENT then
            error("Invalid app argument was accepted")
        end

        local invalidApps = {
            {},
            {
                id = "bad id",
                apiVersion = 1,
                displayName = "Bad",
                supportedDevices = {},
                presentations = {}
            },
            {
                id = "forge.badCapability",
                apiVersion = 1,
                displayName = "Bad",
                supportedDevices = {
                    phone = true
                },
                requiredCapabilities = {
                    unknown = true
                },
                presentations = {}
            },
            {
                id = "forge.badRoute",
                apiVersion = 1,
                displayName = "Bad",
                supportedDevices = {
                    phone = true
                },
                presentations = {
                    phone = {
                        id = "bad.phone",
                        defaultRoute = "missing",
                        routes = {
                            overview = {}
                        }
                    }
                }
            },
            {
                id = "forge.badMetadata",
                apiVersion = 1,
                displayName = "Bad",
                supportedDevices = {
                    phone = true
                },
                presentations = {
                    phone = {
                        id = "bad.metadata.phone",
                        defaultRoute = "overview",
                        routes = {
                            overview = {}
                        }
                    }
                },
                metadata = {
                    value = math.huge
                }
            }
        }

        for _, app in ipairs(invalidApps) do
            if FORGE.ForgeOS:registerApp(app)
                ~= Result.INVALID_DEFINITION then
                error("Invalid app definition was accepted")
            end
        end

        local unsupported = createApp(
            "forge.unsupported"
        )
        unsupported.apiVersion = 999
        if FORGE.ForgeOS:registerApp(unsupported)
            ~= Result.API_VERSION_UNSUPPORTED then
            error("Unsupported app API was accepted")
        end

        if #FORGE.ForgeOS:getRegisteredAppIds()
                ~= 0
            or observed.count ~= 0 then
            error("Rejected app retained state or published")
        end

        local app = createApp("forge.projects")
        if FORGE.ForgeOS:registerApp(app)
                ~= Result.SUCCESS
            or observed.count ~= 1
            or observed.appId ~= "forge.projects"
            or not FORGE.ForgeOS
                :isAppRegistered("forge.projects") then
            error("Valid app did not commit")
        end

        app.displayName = "Mutated"
        app.presentations.phone
            .routes.overview.metadata.title =
                "Mutated"

        local snapshot =
            FORGE.ForgeOS:getAppDefinition(
                "forge.projects"
            )
        if snapshot.displayName ~= "Test App"
            or snapshot.presentations.phone
                .routes.overview.metadata.title
                ~= "Overview"
            or snapshot.controller ~= nil
            or snapshot.callbacks ~= nil
            or snapshot.availabilityProviders
                ~= nil
            or snapshot.ignored ~= nil then
            error("App snapshot isolation failed")
        end

        snapshot.displayName = "Query mutation"
        if FORGE.ForgeOS:getAppDefinition(
            "forge.projects"
        ).displayName ~= "Test App" then
            error("App query exposed registry storage")
        end

        if FORGE.ForgeOS:registerApp(app)
                ~= Result.ALREADY_REGISTERED
            or observed.count ~= 1 then
            error("Duplicate app was accepted")
        end

        if FORGE.ForgeOS:registerApp(
            createApp("forge.bank")
        ) ~= Result.SUCCESS then
            error("Second app registration failed")
        end

        local failingListener = {}
        function failingListener:onRegistered()
            error("intentional App Registry listener failure")
        end
        FORGE.EventBus:subscribe(
            Event.APP_REGISTERED,
            failingListener,
            failingListener.onRegistered
        )

        if FORGE.ForgeOS:registerApp(
            createApp("forge.listener")
        ) ~= Result.SUCCESS
            or not FORGE.ForgeOS
                :isAppRegistered("forge.listener")
            or observed.count ~= 3 then
            error("Listener failure changed registration completion")
        end

        local ids =
            FORGE.ForgeOS:getRegisteredAppIds()
        if ids[1] ~= "forge.bank"
            or ids[2] ~= "forge.listener"
            or ids[3] ~= "forge.projects" then
            error("App identifiers are not lexical")
        end

        if FORGE.AppRegistry
                :freezeRegistrationSet()
                ~= Result.SUCCESS
            or not FORGE.AppRegistry
                :isRegistrationSetFrozen()
            or FORGE.ForgeOS:registerApp(
                createApp("forge.late")
            ) ~= Result.REGISTRATION_CLOSED then
            error("App freeze or late gate failed")
        end

        if FORGE.ForgeOS:shutdown()
                ~= Result.SUCCESS
            or #FORGE.ForgeOS
                :getRegisteredAppIds() ~= 0 then
            error("App Registry cleanup failed")
        end

        if FORGE.ForgeOS:start()
                ~= Result.SUCCESS
            or FORGE.ForgeOS:shutdown()
                ~= Result.SUCCESS then
            error("App Registry restart failed")
        end

        FORGE.EventBus:clearAll()
        FORGE.StateStore:clearAll()
        FORGE.SaveManager:clearAllRegistrations()
    end)

    if not success then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.TEST,
            "App Registry test harness failed: %s",
            FORGE.Logger:safeToString(
                errorMessage,
                "<unprintable error>"
            )
        )
        return false, errorMessage
    end

    FORGE.Logger:info(
        FORGE.Definitions.LogSource.TEST,
        "App Registry test harness passed"
    )
    return true
end
