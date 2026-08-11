---=============================================================================
--- FORGE ForgeOS End-to-End Integration Tests
---
--- Consolidated M2.012 proof over the implemented ForgeOS Foundation.
--- Detailed validation remains owned by the component-specific harnesses.
---=============================================================================

FORGE.Tests = FORGE.Tests or {}

function FORGE.Tests.runForgeOSEndToEndIntegrationTests()
    local Result = FORGE.Definitions.ForgeOSResult
    local Phase = FORGE.Definitions.ForgeOSPhase
    local Visibility = FORGE.Definitions.DeviceVisibility
    local Persist = FORGE.Definitions.NotificationPersistence
    local Severity = FORGE.Definitions.NotificationSeverity

    local function cleanup()
        FORGE.ForgeOS:shutdown()
        FORGE.EventBus:clearAll()
        FORGE.StateStore:clearAll()
        FORGE.SaveManager:clearAllRegistrations()
        FORGE.NotificationService:clearRuntimeState()
    end

    local success, detail = pcall(function()
        cleanup()
        if FORGE.ForgeOS:start() ~= Result.SUCCESS
            or FORGE.ForgeOS:getPhase() ~= Phase.REGISTRATION_OPEN
            or not FORGE.ForgeOS:isDeviceRegistered("phone")
            or not FORGE.ForgeOS:isDeviceRegistered("laptop")
            or FORGE.ForgeOS:completeStartup() ~= Result.SUCCESS
            or FORGE.ForgeOS:getPhase() ~= Phase.RUNTIME_ACTIVE then
            error("End-to-end production startup failed")
        end

        if FORGE.ForgeOS:showDevice("phone") ~= Result.SUCCESS
            or FORGE.ForgeOS:showDevice("laptop") ~= Result.SUCCESS
            or FORGE.ForgeOS:getDeviceVisibility("phone")
                ~= Visibility.VISIBLE
            or FORGE.ForgeOS:getDeviceVisibility("laptop")
                ~= Visibility.VISIBLE
            or not FORGE.ForgeOS:hasVisibleRuntimeHost() then
            error("End-to-end two-Host visibility failed")
        end

        local createResult, notificationId =
            FORGE.ForgeOS:createNotification({
                source = "forge.m2012.integration",
                title = "M2.012 Shared Notification",
                body = "Phone and Laptop project one record",
                severity = Severity.INFO,
                persistence = Persist.SESSION,
                targetDevices = { phone = true, laptop = true }
            })
        if createResult ~= Result.SUCCESS or notificationId == nil
            or #FORGE.ForgeOS:getNotifications("phone") ~= 1
            or #FORGE.ForgeOS:getNotifications("laptop") ~= 1
            or FORGE.ForgeOS:markNotificationRead(notificationId)
                ~= Result.SUCCESS
            or not FORGE.ForgeOS:getNotifications("phone", true)[1].read
            or not FORGE.ForgeOS:getNotifications("laptop", true)[1].read
            or FORGE.ForgeOS:dismissNotification(notificationId)
                ~= Result.SUCCESS
            or #FORGE.ForgeOS:getNotifications("phone") ~= 0
            or #FORGE.ForgeOS:getNotifications("laptop") ~= 0 then
            error("End-to-end shared notification state failed")
        end

        if FORGE.ForgeOS:hideDevice("phone") ~= Result.SUCCESS
            or FORGE.ForgeOS:getDeviceVisibility("laptop")
                ~= Visibility.VISIBLE
            or FORGE.ForgeOS:hideDevice("laptop") ~= Result.SUCCESS
            or FORGE.ForgeOS:hasVisibleRuntimeHost()
            or FORGE.ForgeOS:shutdown() ~= Result.SUCCESS
            or FORGE.ForgeOS:getPhase() ~= Phase.STOPPED then
            error("End-to-end shutdown failed")
        end

        if FORGE.ForgeOS:start() ~= Result.SUCCESS
            or FORGE.ForgeOS:getPhase() ~= Phase.REGISTRATION_OPEN
            or #FORGE.ForgeOS:getNotifications() ~= 0
            or FORGE.ForgeOS:shutdown() ~= Result.SUCCESS then
            error("End-to-end restart cleanliness failed")
        end
        cleanup()
    end)

    pcall(cleanup)
    if not success then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.TEST,
            "ForgeOS end-to-end integration test failed: %s",
            FORGE.Logger:safeToString(detail, "<unprintable error>")
        )
        return false, detail
    end
    FORGE.Logger:info(
        FORGE.Definitions.LogSource.TEST,
        "ForgeOS end-to-end integration test passed"
    )
    return true
end
