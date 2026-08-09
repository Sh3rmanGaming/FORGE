---=============================================================================
--- FORGE ForgeOS Presentation Resolver Integration Tests
---
--- Manual integration harness for the M2.006 resolver boundary.
---
--- Responsibilities:
---     • Verify production Device and App Registry integration.
---     • Verify the production Host Registry enables runtime resolution.
---     • Verify exact, capability, and default public facade results.
---     • Verify the production registration set freezes together.
---
--- This manual harness is invoked only by the Engine development test runner.
---=============================================================================

FORGE.Tests = FORGE.Tests or {}

function FORGE.Tests
    .runForgeOSPresentationResolverIntegrationTests()
    FORGE.Logger:info(
        FORGE.Definitions.LogSource.TEST,
        "ForgeOS Presentation Resolver integration test started"
    )

    local success, errorMessage = pcall(
        function()
            local Result =
                FORGE.Definitions.ForgeOSResult
            local Match =
                FORGE.Definitions.PresentationMatchType
            local Capability =
                FORGE.Definitions.DeviceCapability
            local Phase =
                FORGE.Definitions.ForgeOSPhase
            local function presentation(id, requirements)
                return {
                    id = id,
                    defaultRoute = "home",
                    routes = { home = {} },
                    requiredCapabilities = requirements
                }
            end

            FORGE.ForgeOS:shutdown()
            FORGE.EventBus:clearAll()
            FORGE.StateStore:clearAll()
            FORGE.SaveManager:clearAllRegistrations()

            if FORGE.ForgeOS:start()
                    ~= Result.SUCCESS
                or FORGE.ForgeOS:getPhase()
                    ~= Phase.REGISTRATION_OPEN
                or FORGE.ForgeOS
                    :resolvePresentation(
                        "forge.exact",
                        "phone"
                    ) ~= Result.NOT_AVAILABLE then
                error("Production resolver gate failed")
            end

            local touch = {
                [Capability.TOUCH_INPUT] = true
            }
            if FORGE.ForgeOS:registerDevice({
                    id = "tablet",
                    displayName = "Tablet",
                    capabilities = touch
                }) ~= Result.SUCCESS then
                error("Resolver integration devices failed")
            end

            local apps = {
                {
                    id = "forge.exact",
                    apiVersion = 1,
                    displayName = "Exact",
                    supportedDevices = {
                        phone = true
                    },
                    presentations = {
                        phone = presentation(
                            "exact.phone"
                        )
                    }
                },
                {
                    id = "forge.capability",
                    apiVersion = 1,
                    displayName = "Capability",
                    supportedDevices = {},
                    allowCapabilityFallback = true,
                    presentations = {
                        compact = presentation(
                            "capability.compact",
                            touch
                        )
                    }
                },
                {
                    id = "forge.default",
                    apiVersion = 1,
                    displayName = "Default",
                    supportedDevices = {},
                    allowCapabilityFallback = true,
                    defaultPresentation = "fallback",
                    presentations = {
                        fallback = presentation(
                            "default.fallback"
                        )
                    }
                }
            }
            for _, definition in ipairs(apps) do
                if FORGE.ForgeOS:registerApp(
                    definition
                ) ~= Result.SUCCESS then
                    error("Resolver integration app failed")
                end
            end

            if FORGE.ForgeOS:completeStartup()
                    ~= Result.SUCCESS
                or FORGE.ForgeOS:getPhase()
                    ~= Phase.RUNTIME_ACTIVE
                or not FORGE.DeviceRegistry
                    :isRegistrationSetFrozen()
                or not FORGE.AppRegistry
                    :isRegistrationSetFrozen() then
                error("Resolver integration runtime failed")
            end

            local exactResult, exact =
                FORGE.ForgeOS:resolvePresentation(
                    "forge.exact",
                    "phone"
                )
            local capabilityResult, capability =
                FORGE.ForgeOS:resolvePresentation(
                    "forge.capability",
                    "tablet"
                )
            local defaultResult, default =
                FORGE.ForgeOS:resolvePresentation(
                    "forge.default",
                    "tablet"
                )

            if exactResult ~= Result.SUCCESS
                or exact.matchType
                    ~= Match.EXACT_DEVICE
                or capabilityResult
                    ~= Result.SUCCESS
                or capability.matchType
                    ~= Match.CAPABILITY
                or defaultResult ~= Result.SUCCESS
                or default.matchType
                    ~= Match.DEFAULT then
                error("Public resolver integration failed")
            end

            if FORGE.ForgeOS:shutdown()
                    ~= Result.SUCCESS
                or FORGE.ForgeOS:start()
                    ~= Result.SUCCESS
                or FORGE.ForgeOS:getPhase()
                    ~= Phase.REGISTRATION_OPEN
                or FORGE.ForgeOS:shutdown()
                    ~= Result.SUCCESS then
                error("Resolver production restart failed")
            end

            FORGE.EventBus:clearAll()
            FORGE.StateStore:clearAll()
            FORGE.SaveManager:clearAllRegistrations()
        end
    )

    if not success then
        pcall(function()
            FORGE.ForgeOS:shutdown()
            FORGE.EventBus:clearAll()
            FORGE.StateStore:clearAll()
            FORGE.SaveManager:clearAllRegistrations()
        end)
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.TEST,
            "ForgeOS Presentation Resolver integration test failed: %s",
            FORGE.Logger:safeToString(
                errorMessage,
                "<unprintable error>"
            )
        )
        return false, errorMessage
    end

    FORGE.Logger:info(
        FORGE.Definitions.LogSource.TEST,
        "ForgeOS Presentation Resolver integration test passed"
    )
    return true
end
