---=============================================================================
--- FORGE ForgeOS Notification Integration Tests
---
--- Manual integration harness for the M2.009 Notification Foundation.
---
--- Responsibilities:
---     • Verify the public notification facade at runtime-active.
---     • Verify session/savegame state, events, shutdown, and restart.
---     • Verify Notifications with the production Device Host Registry.
---
--- This manual harness is invoked only by the Engine development test runner.
---=============================================================================

FORGE.Tests = FORGE.Tests or {}

function FORGE.Tests.runForgeOSNotificationIntegrationTests()
    FORGE.Logger:info(
        FORGE.Definitions.LogSource.TEST,
        "ForgeOS Notification integration test started"
    )
    local Result = FORGE.Definitions.ForgeOSResult
    local Phase = FORGE.Definitions.ForgeOSPhase
    local Persist = FORGE.Definitions.NotificationPersistence
    local Severity = FORGE.Definitions.NotificationSeverity
    local PlayerId = FORGE.Definitions.ForgeOSPlayerId.LOCAL
    local Namespace = FORGE.Definitions.ForgeOSNamespace.OS
    local created = 0

    local function cleanup()
        FORGE.ForgeOS:shutdown()
        FORGE.EventBus:clearAll()
        FORGE.StateStore:clearAll()
        FORGE.SaveManager:clearAllRegistrations()
        FORGE.NotificationService:clearRuntimeState()
    end

    local success, errorMessage = pcall(function()
        cleanup()
        if FORGE.ForgeOS:start() ~= Result.SUCCESS
            or FORGE.ForgeOS:createNotification({})
                ~= Result.INVALID_DEFINITION
            or FORGE.ForgeOS:getPhase() ~= Phase.REGISTRATION_OPEN then
            error("Production Notification gate failed")
        end
        if FORGE.ForgeOS:completeStartup() ~= Result.SUCCESS then
            error("Notification integration setup failed")
        end

        local mission = g_currentMission
        local saveDirectory = mission ~= nil
            and mission.missionInfo ~= nil
            and mission.missionInfo.savegameDirectory
            or nil
        local verificationRoot = getUserProfileAppPath()
            .. "modSettings/FS25_FORGE_Engine"
        local verificationDirectory = type(saveDirectory) == "string"
            and verificationRoot .. "/m2009RuntimeVerification"
            or nil
        if verificationDirectory ~= nil then
            createFolder(verificationRoot)
            createFolder(verificationDirectory)
            FORGE.SaveManager:load(verificationDirectory)
            FORGE.NotificationService:clearRuntimeState()
        end
        local initialState = FORGE.StateStore:snapshot(Namespace)
        local initialSequence = initialState.players[PlayerId]
            .notificationNextSequence or 1

        local observer = {}
        function observer:onEvent() created = created + 1 end
        FORGE.EventBus:subscribe(
            FORGE.Definitions.ForgeOSEvent.NOTIFICATION_CREATED,
            observer,
            observer.onEvent
        )
        local visibleBefore = #FORGE.ForgeOS:getNotifications("phone")
        local base = {
            source = "forge.integration",
            title = "Integration",
            body = "Notification",
            severity = Severity.SUCCESS,
            targetDevices = { phone = true }
        }
        base.persistence = Persist.SESSION
        local sessionResult, sessionId =
            FORGE.ForgeOS:createNotification(base)
        base.persistence = Persist.SAVEGAME
        base.title = "Persisted"
        local saveResult, saveId = FORGE.ForgeOS:createNotification(base)
        if sessionResult ~= Result.SUCCESS
            or saveResult ~= Result.SUCCESS
            or created ~= 2
            or #FORGE.ForgeOS:getNotifications("phone")
                ~= visibleBefore + 2
            or FORGE.ForgeOS:markNotificationRead(saveId) ~= Result.SUCCESS
            or FORGE.ForgeOS:dismissNotification(sessionId) ~= Result.SUCCESS
            or #FORGE.ForgeOS:getNotifications("phone")
                ~= visibleBefore + 1 then
            error("Public Notification integration failed")
        end

        local state, found = FORGE.StateStore:snapshot(Namespace)
        if not found
            or state.players[PlayerId].notifications[saveId] == nil
            or state.players[PlayerId].notifications[sessionId] ~= nil
            or state.players[PlayerId].notificationNextSequence
                ~= initialSequence + 2 then
            error("Notification persistence integration failed")
        end

        if verificationDirectory ~= nil then
            local fixture = nil
            for _, record in ipairs(
                FORGE.ForgeOS:getNotifications(nil, true)
            ) do
                if record.metadata ~= nil
                    and record.metadata.verificationKey
                        == "m2.009.persistence" then
                    fixture = record
                    break
                end
            end

            if fixture == nil then
                local fixtureSessionResult, fixtureSessionId =
                    FORGE.ForgeOS:createNotification({
                        source = "forge.m2009Verification",
                        title = "M2.009 Session Fixture",
                        body = "Must not restore",
                        severity = Severity.INFO,
                        persistence = Persist.SESSION,
                        targetDevices = { phone = true }
                    })
                local fixtureSaveResult, fixtureSaveId =
                    FORGE.ForgeOS:createNotification({
                        source = "forge.m2009Verification",
                        title = "M2.009 Savegame Fixture",
                        body = "Must restore",
                        severity = Severity.INFO,
                        persistence = Persist.SAVEGAME,
                        targetDevices = { phone = true },
                        metadata = {
                            verificationKey = "m2.009.persistence",
                            sessionId = fixtureSessionId
                        }
                    })
                if fixtureSessionResult ~= Result.SUCCESS
                    or fixtureSaveResult ~= Result.SUCCESS
                    or FORGE.ForgeOS:markNotificationRead(fixtureSaveId)
                        ~= Result.SUCCESS
                    or FORGE.ForgeOS:dismissNotification(fixtureSaveId)
                        ~= Result.SUCCESS
                    or not FORGE.SaveManager:save(verificationDirectory) then
                    error("M2.009 persistence cycle 1 preparation failed")
                end
                local verificationState =
                    FORGE.StateStore:snapshot(Namespace)
                FORGE.Logger:info(
                    FORGE.Definitions.LogSource.TEST,
                    "M2.009 persistence verification cycle 1 prepared: "
                        .. "sessionId=%s savegameId=%s nextSequence=%d",
                    fixtureSessionId,
                    fixtureSaveId,
                    verificationState.players[PlayerId]
                        .notificationNextSequence
                )
            else
                local nextBefore = state.players[PlayerId]
                    .notificationNextSequence
                local restoredSessionId = fixture.metadata.sessionId
                local transientResult, transientId =
                    FORGE.ForgeOS:createNotification({
                        source = "forge.m2009Verification",
                        title = "M2.009 Sequence Continuity",
                        body = "Transient gap",
                        severity = Severity.INFO,
                        persistence = Persist.TRANSIENT,
                        targetDevices = { phone = true }
                    })
                local verificationState =
                    FORGE.StateStore:snapshot(Namespace)
                if not fixture.read or not fixture.dismissed
                    or FORGE.ForgeOS:getNotification(restoredSessionId) ~= nil
                    or transientResult ~= Result.SUCCESS
                    or transientId
                        ~= "notification." .. tostring(nextBefore)
                    or verificationState.players[PlayerId]
                        .notificationNextSequence ~= nextBefore + 1 then
                    error("M2.009 persistence cycle 2 restoration failed")
                end
                verificationState.players[PlayerId]
                    .notifications[fixture.id] = nil
                if not FORGE.StateStore:replaceNamespace(
                    Namespace,
                    verificationState
                ) or not FORGE.SaveManager:save(verificationDirectory) then
                    error("M2.009 persistence fixture cleanup failed")
                end
                FORGE.Logger:info(
                    FORGE.Definitions.LogSource.TEST,
                    "M2.009 persistence verification cycle 2 passed: "
                        .. "restored=%s sessionAbsent=true continuedId=%s",
                    fixture.id,
                    transientId
                )
            end
        end

        if FORGE.ForgeOS:shutdown() ~= Result.SUCCESS
            or FORGE.ForgeOS:start() ~= Result.SUCCESS
            or FORGE.ForgeOS:getPhase() ~= Phase.REGISTRATION_OPEN
            or #FORGE.ForgeOS:getNotifications() ~= 0
            or FORGE.ForgeOS:shutdown() ~= Result.SUCCESS then
            error("Notification integration restart failed")
        end
        cleanup()
    end)

    pcall(cleanup)
    if not success then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.TEST,
            "ForgeOS Notification integration test failed: %s",
            FORGE.Logger:safeToString(errorMessage, "<unprintable error>")
        )
        return false, errorMessage
    end
    FORGE.Logger:info(
        FORGE.Definitions.LogSource.TEST,
        "ForgeOS Notification integration test passed"
    )
    return true
end
