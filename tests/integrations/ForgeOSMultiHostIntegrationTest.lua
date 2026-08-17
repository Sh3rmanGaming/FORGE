---=============================================================================
--- FORGE Multi-Host Integration Tests
---=============================================================================

FORGE.Tests = FORGE.Tests or {}

function FORGE.Tests.runForgeOSMultiHostIntegrationTests()
    local Result = FORGE.Definitions.ForgeOSResult
    local Phase = FORGE.Definitions.ForgeOSPhase
    local Visibility = FORGE.Definitions.DeviceVisibility
    local originalPhoneCreate = FORGE.PhoneHost.create
    local originalLaptopCreate = FORGE.LaptopHost.create
    local success, errorMessage = pcall(function()
        local function reset()
            FORGE.ForgeOS:shutdown()
            FORGE.EventBus:clearAll()
            FORGE.StateStore:clearAll()
            FORGE.SaveManager:clearAllRegistrations()
        end

        local function runFailure(phoneMode, laptopMode)
            local shutdowns = {}
            local function factory(deviceId, mode)
                return function()
                    if mode == "construct" then return nil end
                    return {
                        initialize = function()
                            if mode == "initialize" then return Result.INTERNAL_ERROR end
                            return Result.SUCCESS
                        end,
                        isOperational = function() return true end,
                        shutdown = function()
                            table.insert(shutdowns, deviceId)
                            return Result.SUCCESS
                        end
                    }
                end
            end
            FORGE.PhoneHost.create = factory("phone", phoneMode)
            FORGE.LaptopHost.create = factory("laptop", laptopMode)
            reset()
            if FORGE.ForgeOS:start() ~= Result.SUCCESS
                or FORGE.ForgeOS:completeStartup() == Result.SUCCESS
                or FORGE.ForgeOS:getPhase() ~= Phase.STOPPED
                or FORGE.ForgeOS:getDeviceVisibility("phone") ~= nil
                or FORGE.ForgeOS:getDeviceVisibility("laptop") ~= nil then
                error("Atomic Host startup failure cleanup failed")
            end
            reset()
            return shutdowns
        end

        runFailure("construct", nil)
        runFailure("initialize", nil)
        local laptopConstructionShutdowns = runFailure(nil, "construct")
        if laptopConstructionShutdowns[1] ~= "phone" then
            error("Laptop construction failure did not clean Phone")
        end
        local laptopInitializationShutdowns = runFailure(nil, "initialize")
        if laptopInitializationShutdowns[1] ~= "laptop"
            or laptopInitializationShutdowns[2] ~= "phone" then
            error("Laptop initialization failure cleanup order failed")
        end

        local draws, pointers = {}, {}
        local function presentationFactory(deviceId)
            return function()
                return {
                    initialize = function() return Result.SUCCESS end,
                    isOperational = function() return true end,
                    update = function() end,
                    draw = function() table.insert(draws, deviceId) end,
                    containsPoint = function(_, x)
                        return deviceId == "laptop" or x >= 0.70
                    end,
                    onPointer = function()
                        table.insert(pointers, deviceId)
                        return deviceId == "laptop"
                    end,
                    onInput = function() return false end,
                    shutdown = function() return Result.SUCCESS end
                }
            end
        end
        FORGE.PhoneHost.create = presentationFactory("phone")
        FORGE.LaptopHost.create = presentationFactory("laptop")
        reset()
        if FORGE.ForgeOS:start() ~= Result.SUCCESS
            or FORGE.ForgeOS:completeStartup() ~= Result.SUCCESS
            or FORGE.ForgeOS:showDevice("phone") ~= Result.SUCCESS
            or FORGE.ForgeOS:showDevice("laptop") ~= Result.SUCCESS then
            error("Layered Host presentation setup failed")
        end
        FORGE.ForgeOS:drawRuntimeHost()
        if draws[1] ~= "laptop" or draws[2] ~= "phone" then
            error("Laptop-first Phone-last presentation order failed")
        end
        if not FORGE.ForgeOS:dispatchHostPointer(0.80, 0.50,
                true, false, 1)
            or pointers[1] ~= "phone" or pointers[2] ~= nil then
            error("Visible Phone did not occlude Laptop pointer input")
        end
        pointers = {}
        if not FORGE.ForgeOS:dispatchHostPointer(0.20, 0.50,
                true, false, 1)
            or pointers[1] ~= "laptop" then
            error("Laptop did not receive pointer outside Phone bounds")
        end

        FORGE.PhoneHost.create = originalPhoneCreate
        FORGE.LaptopHost.create = originalLaptopCreate
        FORGE.ForgeOS:shutdown()
        FORGE.EventBus:clearAll()
        FORGE.StateStore:clearAll()
        FORGE.SaveManager:clearAllRegistrations()
        if FORGE.ForgeOS:start() ~= Result.SUCCESS
            or FORGE.ForgeOS:completeStartup() ~= Result.SUCCESS
            or FORGE.ForgeOS:showDevice("phone") ~= Result.SUCCESS
            or FORGE.ForgeOS:showDevice("laptop") ~= Result.SUCCESS
            or FORGE.ForgeOS:getDeviceVisibility("phone") ~= Visibility.VISIBLE
            or FORGE.ForgeOS:getDeviceVisibility("laptop") ~= Visibility.VISIBLE
            or not FORGE.ForgeOS:hasVisibleRuntimeHost()
            or FORGE.ForgeOS:hideDevice("laptop") ~= Result.SUCCESS
            or FORGE.ForgeOS:getDeviceVisibility("phone") ~= Visibility.VISIBLE
            or FORGE.ForgeOS:getDeviceVisibility("laptop") ~= Visibility.HIDDEN
            or FORGE.ForgeOS:hideDevice("phone") ~= Result.SUCCESS
            or FORGE.ForgeOS:hasVisibleRuntimeHost() then
            error("Independent multi-Host visibility failed")
        end
        local state = FORGE.StateStore:snapshot(FORGE.Definitions.ForgeOSNamespace.OS)
        if state.players[FORGE.Definitions.ForgeOSPlayerId.LOCAL].activeDeviceId ~= nil then
            error("Multi-Host visibility mutated activeDeviceId")
        end
    end)
    FORGE.PhoneHost.create = originalPhoneCreate
    FORGE.LaptopHost.create = originalLaptopCreate
    FORGE.ForgeOS:shutdown()
    if not success then return false, errorMessage end
    return true
end
