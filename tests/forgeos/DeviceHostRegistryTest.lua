---=============================================================================
--- FORGE Device Host Registry Tests
---=============================================================================

FORGE.Tests = FORGE.Tests or {}

function FORGE.Tests.runDeviceHostRegistryTests()
    local Result = FORGE.Definitions.ForgeOSResult
    local success, errorMessage = pcall(function()
        FORGE.ForgeOS:shutdown()
        FORGE.EventBus:clearAll()
        FORGE.StateStore:clearAll()
        FORGE.SaveManager:clearAllRegistrations()

        if FORGE.ForgeOS:start() ~= Result.SUCCESS
            or not FORGE.DeviceHostRegistry:isHostRegistered("phoneHost")
            or FORGE.DeviceHostRegistry:getHostDeviceId("phoneHost") ~= "phone"
            or FORGE.DeviceHostRegistry:registerHost(nil)
                ~= Result.INVALID_ARGUMENT
            or FORGE.DeviceHostRegistry:registerHost({})
                ~= Result.INVALID_DEFINITION
            or FORGE.DeviceHostRegistry:registerHost({
                id = "phoneHost",
                deviceId = "phone",
                createInstance = function() return {} end
            }) ~= Result.ALREADY_REGISTERED then
            error("Device Host registration contract failed")
        end

        if FORGE.DeviceHostRegistry:createHostInstance("phoneHost", {})
            ~= Result.NOT_AVAILABLE then
            error("Unfrozen Host construction was permitted")
        end

        if FORGE.ForgeOS:completeStartup() ~= Result.SUCCESS
            or not FORGE.DeviceHostRegistry:isRegistrationSetFrozen() then
            error("Device Host Registry did not freeze")
        end

        local createResult, instance =
            FORGE.DeviceHostRegistry:createHostInstance("phoneHost", {})
        if createResult ~= Result.SUCCESS or type(instance) ~= "table" then
            error("Private Host construction failed")
        end

        if FORGE.ForgeOS:shutdown() ~= Result.SUCCESS
            or FORGE.DeviceHostRegistry:isRegistrationSetFrozen()
            or FORGE.DeviceHostRegistry:isHostRegistered("phoneHost") then
            error("Device Host Registry cleanup failed")
        end
    end)

    FORGE.ForgeOS:shutdown()
    if not success then return false, errorMessage end
    return true
end
