---=============================================================================
--- FORGE Device State Service Tests
---=============================================================================

FORGE.Tests = FORGE.Tests or {}

function FORGE.Tests.runDeviceStateServiceTests()
    local Result = FORGE.Definitions.ForgeOSResult
    local Visibility = FORGE.Definitions.DeviceVisibility
    local Event = FORGE.Definitions.ForgeOSEvent
    local changes = {}
    local observer = {}
    function observer:onChanged(payload) table.insert(changes, payload) end

    local success, errorMessage = pcall(function()
        FORGE.ForgeOS:shutdown()
        FORGE.EventBus:clearAll()
        FORGE.StateStore:clearAll()
        FORGE.SaveManager:clearAllRegistrations()

        if FORGE.ForgeOS:showDevice(nil) ~= Result.INVALID_ARGUMENT
            or FORGE.ForgeOS:showDevice("phone") ~= Result.NOT_AVAILABLE
            or FORGE.ForgeOS:getDeviceVisibility("phone") ~= nil
            or FORGE.ForgeOS:start() ~= Result.SUCCESS
            or FORGE.ForgeOS:completeStartup() ~= Result.SUCCESS then
            error("Device visibility gate failed")
        end

        FORGE.EventBus:subscribe(Event.DEVICE_VISIBILITY_CHANGED, observer, observer.onChanged)
        if FORGE.ForgeOS:getDeviceVisibility("phone") ~= Visibility.HIDDEN
            or FORGE.ForgeOS:showDevice("missing") ~= Result.NOT_REGISTERED
            or FORGE.ForgeOS:showDevice("phone") ~= Result.SUCCESS
            or FORGE.ForgeOS:getDeviceVisibility("phone") ~= Visibility.VISIBLE
            or FORGE.ForgeOS:showDevice("phone") ~= Result.SUCCESS
            or #changes ~= 1
            or changes[1].previousVisibility ~= Visibility.HIDDEN
            or changes[1].currentVisibility ~= Visibility.VISIBLE
            or changes[1].deviceId ~= "phone"
            or changes[1].playerId ~= FORGE.Definitions.ForgeOSPlayerId.LOCAL then
            error("Device visibility transition contract failed")
        end

        if FORGE.ForgeOS:hideDevice("phone") ~= Result.SUCCESS
            or FORGE.ForgeOS:hideDevice("phone") ~= Result.SUCCESS
            or #changes ~= 2
            or FORGE.ForgeOS:shutdown() ~= Result.SUCCESS
            or FORGE.ForgeOS:getDeviceVisibility("phone") ~= nil then
            error("Device visibility idempotence or cleanup failed")
        end
    end)

    FORGE.ForgeOS:shutdown()
    if not success then return false, errorMessage end
    return true
end
