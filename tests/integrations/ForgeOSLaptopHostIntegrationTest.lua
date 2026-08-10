---=============================================================================
--- FORGE Laptop Host Integration Tests
---=============================================================================

FORGE.Tests = FORGE.Tests or {}

function FORGE.Tests.runForgeOSLaptopHostIntegrationTests()
    local Result = FORGE.Definitions.ForgeOSResult
    local Visibility = FORGE.Definitions.DeviceVisibility
    local success, errorMessage = pcall(function()
        FORGE.ForgeOS:shutdown()
        FORGE.EventBus:clearAll()
        FORGE.StateStore:clearAll()
        FORGE.SaveManager:clearAllRegistrations()
        if FORGE.ForgeOS:start() ~= Result.SUCCESS
            or FORGE.ForgeOS:completeStartup() ~= Result.SUCCESS
            or not FORGE.ForgeOS:isDeviceRegistered("laptop")
            or FORGE.ForgeOS:getDeviceVisibility("laptop") ~= Visibility.HIDDEN
            or FORGE.ForgeOS:showDevice("laptop") ~= Result.SUCCESS
            or FORGE.ForgeOS:getDeviceVisibility("laptop") ~= Visibility.VISIBLE
            or FORGE.ForgeOS:hideDevice("laptop") ~= Result.SUCCESS
            or FORGE.ForgeOS:getDeviceVisibility("laptop") ~= Visibility.HIDDEN then
            error("Laptop Host integration lifecycle failed")
        end
    end)
    FORGE.ForgeOS:shutdown()
    if not success then return false, errorMessage end
    return true
end
