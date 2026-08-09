---=============================================================================
--- FORGE ForgeOS Presentation Resolver Tests
---
--- Manual component harness for the M2.006 Presentation Resolver.
---
--- Responsibilities:
---     • Verify runtime gating and controlled failure results.
---     • Verify exact, capability, priority, tie, and default selection.
---     • Verify deterministic capability diagnostics and detached results.
---     • Verify read-only behaviour across shutdown and restart.
---
--- This manual harness is invoked only by the Engine development test runner.
---=============================================================================

FORGE.Tests = FORGE.Tests or {}

function FORGE.Tests.runPresentationResolverTests()
    FORGE.Logger:info(
        FORGE.Definitions.LogSource.TEST,
        "Presentation Resolver test harness started"
    )

    local Result =
        FORGE.Definitions.ForgeOSResult
    local Reason =
        FORGE.Definitions.AppAvailabilityReason
    local Match =
        FORGE.Definitions.PresentationMatchType
    local Event =
        FORGE.Definitions.ForgeOSEvent
    local Capability =
        FORGE.Definitions.DeviceCapability
    local function presentation(
        id,
        requirements,
        priority
    )
        return {
            id = id,
            defaultRoute = "home",
            routes = {
                home = {}
            },
            requiredCapabilities = requirements,
            priority = priority
        }
    end

    local function app(
        appId,
        supportedDevices,
        presentations,
        options
    )
        options = options or {}
        return {
            id = appId,
            apiVersion =
                FORGE.Definitions
                    .ForgeOSVersion.APP_API,
            displayName = appId,
            supportedDevices = supportedDevices,
            presentations = presentations,
            allowCapabilityFallback =
                options.allowFallback,
            defaultPresentation =
                options.defaultPresentation,
            requiredCapabilities =
                options.requiredCapabilities,
            controller = options.controller
        }
    end

    local function device(deviceId, capabilities)
        return {
            id = deviceId,
            displayName = deviceId,
            capabilities = capabilities or {}
        }
    end

    local function reset()
        FORGE.ForgeOS:shutdown()
        FORGE.EventBus:clearAll()
        FORGE.StateStore:clearAll()
        FORGE.SaveManager:clearAllRegistrations()
    end

    local function startRuntime(
        devices,
        apps
    )
        reset()
        if FORGE.ForgeOS:start()
                ~= Result.SUCCESS then
            error("Resolver lifecycle did not start")
        end
        for _, definition in ipairs(devices) do
            if definition.id ~= "phone"
                and FORGE.ForgeOS
                :registerDevice(definition)
                    ~= Result.SUCCESS then
                error("Resolver device setup failed")
            end
        end
        for _, definition in ipairs(apps) do
            if FORGE.ForgeOS
                :registerApp(definition)
                    ~= Result.SUCCESS then
                error("Resolver app setup failed")
            end
        end
        if FORGE.ForgeOS:completeStartup()
                ~= Result.SUCCESS then
            error("Resolver runtime setup failed")
        end
    end

    local function expect(
        appId,
        deviceId,
        expectedResult,
        expectedKey,
        expectedMatch,
        expectedReason,
        expectedMissing
    )
        local result, resolution =
            FORGE.ForgeOS:resolvePresentation(
                appId,
                deviceId
            )
        if result ~= expectedResult then
            error("Unexpected resolver result")
        end
        if expectedKey ~= nil then
            if resolution == nil
                or resolution.presentationKey
                    ~= expectedKey
                or resolution.matchType
                    ~= expectedMatch then
                error("Unexpected resolved presentation")
            end
        elseif expectedReason ~= nil then
            if resolution == nil
                or resolution.reason
                    ~= expectedReason
                or resolution.missingCapability
                    ~= expectedMissing then
                error("Unexpected resolver diagnostic")
            end
        elseif resolution ~= nil then
            error("Unexpected resolver payload")
        end
        return resolution
    end

    local success, errorMessage = pcall(
        function()
            reset()
            expect(
                nil,
                "phone",
                Result.INVALID_ARGUMENT
            )
            expect(
                "forge.app",
                "bad id",
                Result.INVALID_ARGUMENT
            )
            expect(
                "forge.app",
                "phone",
                Result.NOT_AVAILABLE
            )

            startRuntime(
                { device("phone") },
                {
                    app(
                        "forge.base",
                        { phone = true },
                        {
                            phone =
                                presentation(
                                    "base.phone"
                                )
                        }
                    )
                }
            )
            expect(
                "forge.missing",
                "phone",
                Result.NOT_REGISTERED,
                nil,
                nil,
                Reason.APP_NOT_REGISTERED
            )
            expect(
                "forge.base",
                "tablet",
                Result.NOT_REGISTERED,
                nil,
                nil,
                Reason.DEVICE_NOT_REGISTERED
            )

            startRuntime(
                {
                    device("phone"),
                    device("tablet")
                },
                {
                    app(
                        "forge.support",
                        {
                            phone = true,
                            tablet = false
                        },
                        {
                            phone =
                                presentation(
                                    "support.phone"
                                )
                        }
                    ),
                    app(
                        "forge.closedFallback",
                        { phone = true },
                        {
                            phone =
                                presentation(
                                    "closed.phone"
                                )
                        }
                    )
                }
            )
            expect(
                "forge.support",
                "tablet",
                Result.NOT_AVAILABLE,
                nil,
                nil,
                Reason.DEVICE_NOT_SUPPORTED
            )
            expect(
                "forge.closedFallback",
                "tablet",
                Result.NOT_AVAILABLE,
                nil,
                nil,
                Reason.DEVICE_NOT_SUPPORTED
            )

            local touch = {
                [Capability.TOUCH_INPUT] = true
            }
            startRuntime(
                {
                    device("phone", touch),
                    device("tablet", touch)
                },
                {
                    app(
                        "forge.exact",
                        { phone = true },
                        {
                            phone =
                                presentation(
                                    "exact.phone"
                                )
                        }
                    ),
                    app(
                        "forge.fallback",
                        { phone = true },
                        {
                            phone = presentation(
                                "fallback.phone",
                                {
                                    [Capability
                                        .WINDOWED_APPS] =
                                            true
                                }
                            ),
                            compact = presentation(
                                "fallback.compact",
                                touch,
                                10
                            )
                        },
                        { allowFallback = true }
                    )
                }
            )
            expect(
                "forge.exact",
                "phone",
                Result.SUCCESS,
                "phone",
                Match.EXACT_DEVICE
            )
            expect(
                "forge.fallback",
                "phone",
                Result.SUCCESS,
                "compact",
                Match.CAPABILITY
            )
            expect(
                "forge.fallback",
                "tablet",
                Result.SUCCESS,
                "compact",
                Match.CAPABILITY
            )

            startRuntime(
                {
                    device("tablet", touch)
                },
                {
                    app(
                        "forge.priority",
                        {},
                        {
                            negative = presentation(
                                "priority.negative",
                                touch,
                                -1
                            ),
                            omitted = presentation(
                                "priority.omitted",
                                touch
                            ),
                            fractional =
                                presentation(
                                    "priority.fractional",
                                    touch,
                                    0.5
                                )
                        },
                        { allowFallback = true }
                    ),
                    app(
                        "forge.tie",
                        {},
                        {
                            zeta = presentation(
                                "tie.zeta",
                                touch,
                                4
                            ),
                            alpha = presentation(
                                "tie.alpha",
                                touch,
                                4
                            )
                        },
                        { allowFallback = true }
                    )
                }
            )
            expect(
                "forge.priority",
                "tablet",
                Result.SUCCESS,
                "fractional",
                Match.CAPABILITY
            )
            expect(
                "forge.tie",
                "tablet",
                Result.SUCCESS,
                "alpha",
                Match.CAPABILITY
            )

            startRuntime(
                {
                    device("tablet", {})
                },
                {
                    app(
                        "forge.universalMissing",
                        {},
                        {
                            default =
                                presentation(
                                    "universal.default"
                                )
                        },
                        {
                            allowFallback = true,
                            defaultPresentation =
                                "default",
                            requiredCapabilities = {
                                [Capability
                                    .TOUCH_INPUT] = true,
                                [Capability
                                    .KEYBOARD_INPUT] =
                                        true
                            }
                        }
                    ),
                    app(
                        "forge.diagnostic",
                        {},
                        {
                            high = presentation(
                                "diagnostic.high",
                                {
                                    [Capability
                                        .TOUCH_INPUT] =
                                            true,
                                    [Capability
                                        .KEYBOARD_INPUT] =
                                            true
                                },
                                10
                            ),
                            low = presentation(
                                "diagnostic.low",
                                {
                                    [Capability
                                        .FULL_SCREEN_APPS] =
                                            true
                                },
                                1
                            )
                        },
                        { allowFallback = true }
                    )
                }
            )
            expect(
                "forge.universalMissing",
                "tablet",
                Result.CAPABILITY_MISSING,
                nil,
                nil,
                Reason.MISSING_CAPABILITY,
                Capability.KEYBOARD_INPUT
            )
            expect(
                "forge.diagnostic",
                "tablet",
                Result.CAPABILITY_MISSING,
                nil,
                nil,
                Reason.MISSING_CAPABILITY,
                Capability.KEYBOARD_INPUT
            )

            startRuntime(
                {
                    device("tablet", touch)
                },
                {
                    app(
                        "forge.default",
                        {},
                        {
                            fallback =
                                presentation(
                                    "default.fallback",
                                    touch
                                )
                        },
                        {
                            allowFallback = true,
                            defaultPresentation =
                                "fallback"
                        }
                    ),
                    app(
                        "forge.defaultMissing",
                        {},
                        {
                            fallback = presentation(
                                "default.missing",
                                {
                                    [Capability
                                        .KEYBOARD_INPUT] =
                                            true
                                }
                            )
                        },
                        {
                            allowFallback = true,
                            defaultPresentation =
                                "fallback"
                        }
                    ),
                    app(
                        "forge.notFound",
                        { tablet = true },
                        {
                            unused =
                                presentation(
                                    "notFound.unused"
                                )
                        },
                        { allowFallback = true }
                    )
                }
            )
            local eventObserver = { count = 0 }
            function eventObserver:onEvent()
                self.count = self.count + 1
            end
            for _, eventId in pairs(Event) do
                FORGE.EventBus:subscribe(
                    eventId,
                    eventObserver,
                    eventObserver.onEvent
                )
            end
            local resolution = expect(
                "forge.default",
                "tablet",
                Result.SUCCESS,
                "fallback",
                Match.DEFAULT
            )
            expect(
                "forge.defaultMissing",
                "tablet",
                Result.CAPABILITY_MISSING,
                nil,
                nil,
                Reason.MISSING_CAPABILITY,
                Capability.KEYBOARD_INPUT
            )
            expect(
                "forge.notFound",
                "tablet",
                Result.PRESENTATION_NOT_FOUND,
                nil,
                nil,
                Reason.PRESENTATION_NOT_FOUND
            )

            resolution.presentation.id = "mutated"
            local repeated = expect(
                "forge.default",
                "tablet",
                Result.SUCCESS,
                "fallback",
                Match.DEFAULT
            )
            if repeated.presentation.id
                    ~= "default.fallback"
                or repeated.presentation.controller
                    ~= nil
                or #FORGE.ForgeOS
                    :getRegisteredAppIds() ~= 3
                or #FORGE.ForgeOS
                    :getRegisteredDeviceIds() ~= 2 then
                error("Resolver was not detached or read-only")
            end
            if eventObserver.count ~= 0 then
                error("Resolver published an event")
            end

            if FORGE.ForgeOS:shutdown()
                    ~= Result.SUCCESS
                or FORGE.ForgeOS:start()
                    ~= Result.SUCCESS
                or FORGE.ForgeOS:shutdown()
                    ~= Result.SUCCESS then
                error("Resolver cleanup or restart failed")
            end
        end
    )

    local cleanupSucceeded, cleanupError =
        pcall(reset)
    if not cleanupSucceeded and success then
        success = false
        errorMessage = cleanupError
    end

    if not success then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.TEST,
            "Presentation Resolver test harness failed: %s",
            FORGE.Logger:safeToString(
                errorMessage,
                "<unprintable error>"
            )
        )
        return false, errorMessage
    end

    FORGE.Logger:info(
        FORGE.Definitions.LogSource.TEST,
        "Presentation Resolver test harness passed"
    )
    return true
end
