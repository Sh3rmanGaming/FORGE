---=============================================================================
--- FORGE Phone Host Integration Tests
---=============================================================================

FORGE.Tests = FORGE.Tests or {}

function FORGE.Tests.runForgeOSPhoneHostIntegrationTests()
    local Result = FORGE.Definitions.ForgeOSResult
    local Visibility = FORGE.Definitions.DeviceVisibility
    local success, errorMessage = pcall(function()
        FORGE.ForgeOS:shutdown()
        FORGE.EventBus:clearAll()
        FORGE.StateStore:clearAll()
        FORGE.SaveManager:clearAllRegistrations()
        if FORGE.ForgeOS:start() ~= Result.SUCCESS
            or FORGE.ForgeOS:completeStartup() ~= Result.SUCCESS
            or FORGE.ForgeOS:getDeviceVisibility("phone") ~= Visibility.HIDDEN
            or FORGE.ForgeOS:showDevice("phone") ~= Result.SUCCESS
            or FORGE.ForgeOS:getDeviceVisibility("phone") ~= Visibility.VISIBLE
            or FORGE.ForgeOS:hideDevice("phone") ~= Result.SUCCESS
            or FORGE.ForgeOS:getDeviceVisibility("phone") ~= Visibility.HIDDEN
            or FORGE.ForgeOS:shutdown() ~= Result.SUCCESS then
            error("Phone Host integration lifecycle failed")
        end
    end)
    FORGE.ForgeOS:shutdown()
    if not success then return false, errorMessage end
    return true
end
