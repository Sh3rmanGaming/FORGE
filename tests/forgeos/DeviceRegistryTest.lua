---=============================================================================
--- FORGE ForgeOS Device Registry Tests
---
--- Manual component harness for the M2.004 Device Registry capability.
---
--- Responsibilities:
---     • Verify schema validation and deterministic result ordering.
---     • Verify atomic registration, duplicate rejection, and event timing.
---     • Verify detached storage, queries, and lexical identifier ordering.
---     • Verify participant validation, freeze, cleanup, and restart safety.
---
--- This manual harness is invoked only by the Engine development test runner.
---=============================================================================

FORGE.Tests = FORGE.Tests or {}

function FORGE.Tests.runDeviceRegistryTests()
    FORGE.Logger:info(
        FORGE.Definitions.LogSource.TEST,
        "Device Registry test harness started"
    )

    local success, errorMessage = pcall(
        function()
            local Registry =
                FORGE.DeviceRegistry

            local Result =
                FORGE.Definitions.ForgeOSResult

            local Event =
                FORGE.Definitions.ForgeOSEvent

            local Capability =
                FORGE.Definitions.DeviceCapability

            FORGE.ForgeOS:shutdown()
            FORGE.EventBus:clearAll()
            FORGE.StateStore:clearAll()
            FORGE.SaveManager:clearAllRegistrations()

            if FORGE.ForgeOS:start()
                ~= Result.SUCCESS then
                error("Device Registry lifecycle did not start")
            end

            local observed = {
                count = 0,
                lastDeviceId = nil
            }

            function observed:onRegistered(payload)
                self.count = self.count + 1
                self.lastDeviceId =
                    payload.deviceId
            end

            FORGE.EventBus:subscribe(
                Event.DEVICE_REGISTERED,
                observed,
                observed.onRegistered
            )

            if FORGE.ForgeOS:registerDevice(nil)
                    ~= Result.INVALID_ARGUMENT
                or FORGE.ForgeOS:registerDevice(
                    "phone"
                ) ~= Result.INVALID_ARGUMENT then
                error("Invalid registration argument was accepted")
            end

            local invalidDefinitions = {
                {},
                {
                    id = "",
                    displayName = "Invalid",
                    capabilities = {}
                },
                {
                    id = "bad id",
                    displayName = "Invalid",
                    capabilities = {}
                },
                {
                    id = "invalidDisplay",
                    displayName = "",
                    capabilities = {}
                },
                {
                    id = "invalidCapabilities",
                    displayName = "Invalid",
                    capabilities = "touch"
                },
                {
                    id = "unknownCapability",
                    displayName = "Invalid",
                    capabilities = {
                        unknown = true
                    }
                },
                {
                    id = "invalidCapabilityValue",
                    displayName = "Invalid",
                    capabilities = {
                        [Capability.TOUCH_INPUT] =
                            "yes"
                    }
                },
                {
                    id = "invalidHost",
                    displayName = "Invalid",
                    capabilities = {},
                    hostId = "bad host"
                },
                {
                    id = "invalidPolicy",
                    displayName = "Invalid",
                    capabilities = {},
                    policy = {
                        callback = function()
                        end
                    }
                },
                {
                    id = "invalidMetadata",
                    displayName = "Invalid",
                    capabilities = {},
                    metadata = {
                        value = math.huge
                    }
                }
            }

            for _, definition in ipairs(
                invalidDefinitions
            ) do
                if FORGE.ForgeOS:registerDevice(
                    definition
                ) ~= Result.INVALID_DEFINITION then
                    error("Invalid device definition was accepted")
                end
            end

            if #FORGE.ForgeOS
                :getRegisteredDeviceIds() ~= 2
                or observed.count ~= 0 then
                error("Rejected registration retained state or published an event")
            end

            local allCapabilities = {}

            for _, capabilityId in pairs(
                Capability
            ) do
                allCapabilities[capabilityId] =
                    false
            end

            allCapabilities[
                Capability.TOUCH_INPUT
            ] = true

            local phone = {
                id = "test.phone",
                displayName = "Test Phone",
                hostId = "forge.phoneHost",
                capabilities = allCapabilities,
                policy = {
                    enabled = true
                },
                metadata = {
                    labels = {
                        "portable"
                    }
                },
                ignored = "unknown"
            }

            if FORGE.ForgeOS:registerDevice(phone)
                    ~= Result.SUCCESS
                or observed.count ~= 1
                or observed.lastDeviceId ~= "test.phone"
                or not FORGE.ForgeOS
                    :isDeviceRegistered("test.phone") then
                error("Valid device definition did not commit")
            end

            phone.displayName = "Mutated"
            phone.capabilities[
                Capability.TOUCH_INPUT
            ] = false
            phone.metadata.labels[1] = "mutated"

            local stored =
                FORGE.ForgeOS
                    :getDeviceDefinition("test.phone")

            if stored.displayName ~= "Test Phone"
                or stored.capabilities[
                    Capability.TOUCH_INPUT
                ] ~= true
                or stored.metadata.labels[1]
                    ~= "portable"
                or stored.ignored ~= nil then
                error("Controlled storage is not isolated")
            end

            stored.displayName = "Query mutation"

            if FORGE.ForgeOS
                    :getDeviceDefinition("test.phone")
                    .displayName ~= "Test Phone" then
                error("Query result exposed authoritative storage")
            end

            if FORGE.ForgeOS:registerDevice(phone)
                    ~= Result.ALREADY_REGISTERED
                or observed.count ~= 1 then
                error("Duplicate registration was not rejected atomically")
            end

            local failingListener = {}

            function failingListener:onRegistered()
                error("Intentional Device Registry listener failure")
            end

            FORGE.EventBus:subscribe(
                Event.DEVICE_REGISTERED,
                failingListener,
                failingListener.onRegistered
            )

            if FORGE.ForgeOS:registerDevice({
                id = "test.laptop",
                displayName = "Test Laptop",
                capabilities = {}
            }) ~= Result.SUCCESS
                or not FORGE.ForgeOS
                    :isDeviceRegistered("test.laptop")
                or observed.count ~= 2 then
                error("Listener failure changed a committed registration")
            end

            local identifiers =
                FORGE.ForgeOS
                    :getRegisteredDeviceIds()

            if identifiers[1] ~= "laptop"
                or identifiers[2] ~= "phone"
                or identifiers[3] ~= "test.laptop"
                or identifiers[4] ~= "test.phone"
                or identifiers[5] ~= nil then
                error("Device identifiers are not lexically ordered")
            end

            identifiers[1] = "mutated"

            if FORGE.ForgeOS
                    :getRegisteredDeviceIds()[1]
                    ~= "laptop" then
                error("Identifier query was not detached")
            end

            if Registry:validateRegistrationSet()
                    ~= Result.SUCCESS
                or Registry:freezeRegistrationSet()
                    ~= Result.SUCCESS
                or Registry:freezeRegistrationSet()
                    ~= Result.SUCCESS
                or not Registry
                    :isRegistrationSetFrozen() then
                error("Device Registry did not validate and freeze")
            end

            if FORGE.ForgeOS:registerDevice({
                id = "late",
                displayName = "Late",
                capabilities = {}
            }) ~= Result.REGISTRATION_CLOSED then
                error("Late device registration was accepted")
            end

            if FORGE.ForgeOS:shutdown()
                    ~= Result.SUCCESS
                or Registry
                    :isRegistrationSetFrozen()
                or #FORGE.ForgeOS
                    :getRegisteredDeviceIds() ~= 0 then
                error("Device Registry cleanup failed")
            end

            if FORGE.ForgeOS:registerDevice({})
                ~= Result.REGISTRATION_CLOSED then
                error("Registration gate was not checked before schema validation")
            end

            if FORGE.ForgeOS:start()
                    ~= Result.SUCCESS
                or FORGE.ForgeOS:shutdown()
                    ~= Result.SUCCESS then
                error("Device Registry restart failed")
            end

            FORGE.EventBus:clearAll()
            FORGE.StateStore:clearAll()
            FORGE.SaveManager:clearAllRegistrations()
        end
    )

    if not success then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.TEST,
            "Device Registry test harness failed: %s",
            FORGE.Logger:safeToString(
                errorMessage,
                "<unprintable error>"
            )
        )

        return false, errorMessage
    end

    FORGE.Logger:info(
        FORGE.Definitions.LogSource.TEST,
        "Device Registry test harness passed"
    )

    return true
end
