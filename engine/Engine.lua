---=============================================================================
--- FORGE Engine
---
--- Responsible only for the FORGE engine lifecycle.
---
--- Responsibilities:
---     • Receive FS25 mission lifecycle callbacks.
---     • Coordinate FORGE startup.
---     • Coordinate development test execution.
---     • Coordinate ForgeOS startup and shutdown.
---     • Register engine-owned persistent state.
---     • Coordinate persistence loading and saving.
---     • Coordinate FORGE shutdown.
---     • Dispatch frame and input callbacks.
---
--- This class must never implement gameplay systems or persistence formats.
---=============================================================================

FORGE.Engine = {}

FORGE.Engine.isMissionLoaded = false
FORGE.Engine.mapName = nil

-----------------------------------------------------------------------------
-- Private State
-----------------------------------------------------------------------------

local ENGINE_NAMESPACE =
    "forge.engine"

local saveHookInstalled = false
local forgeOSCompletionPending = false
local hostActionsRegistered = false
local hostActionEventIds = {}
local cursorMode = "GAMEPLAY"
local cursorLockedInputComponent = nil

-----------------------------------------------------------------------------
-- Private Helpers
-----------------------------------------------------------------------------

--- Returns whether the current game instance owns authoritative state.
-- @param mission table|nil
-- @return boolean authoritative
local function isAuthoritative(mission)
    mission = mission or g_currentMission

    if mission ~= nil
        and mission.getIsServer ~= nil then
        local callSucceeded, isServer = pcall(
            mission.getIsServer,
            mission
        )

        if callSucceeded then
            return isServer == true
        end
    end

    return g_server ~= nil
end

--- Returns the active mission savegame directory.
-- @param mission table|nil
-- @return string|nil saveDirectory
local function getSaveDirectory(mission)
    mission = mission or g_currentMission

    if mission == nil
        or mission.missionInfo == nil then
        return nil
    end

    local saveDirectory =
        mission.missionInfo.savegameDirectory

    if type(saveDirectory) ~= "string"
        or string.match(
            saveDirectory,
            "%S"
        ) == nil then
        return nil
    end

    return saveDirectory
end

--- Registers and initialises the engine-owned persistent namespace.
-- @return boolean success
local function registerEngineState()
    if not FORGE.StateStore:exists(
        ENGINE_NAMESPACE
    ) then
        local namespaceCreated =
            FORGE.StateStore:register(
                ENGINE_NAMESPACE
            )

        if not namespaceCreated then
            FORGE.Logger:error(
                FORGE.Definitions.LogSource.ENGINE,
                "Unable to create engine state namespace '%s'",
                ENGINE_NAMESPACE
            )

            return false
        end

        local firstRunStored =
            FORGE.StateStore:set(
                ENGINE_NAMESPACE,
                "firstRun",
                true
            )

        local saveCountStored =
            FORGE.StateStore:set(
                ENGINE_NAMESPACE,
                "saveCount",
                0
            )

        local saveVersionStored =
            FORGE.StateStore:set(
                ENGINE_NAMESPACE,
                "saveVersion",
                FORGE.SaveManager.SAVE_VERSION
            )

        if not firstRunStored
            or not saveCountStored
            or not saveVersionStored then
            FORGE.Logger:error(
                FORGE.Definitions.LogSource.ENGINE,
                "Unable to initialise engine state namespace '%s'",
                ENGINE_NAMESPACE
            )

            return false
        end
    end

    if not FORGE.SaveManager:isNamespaceRegistered(
        ENGINE_NAMESPACE
    ) then
        local namespaceRegistered =
            FORGE.SaveManager:registerNamespace(
                ENGINE_NAMESPACE
            )

        if not namespaceRegistered then
            FORGE.Logger:error(
                FORGE.Definitions.LogSource.ENGINE,
                "Unable to register engine state namespace '%s' for persistence",
                ENGINE_NAMESPACE
            )

            return false
        end
    end

    return true
end

--- Runs all currently registered manual development tests.
local function runDevelopmentTests()
    if not FORGE.Logger:isDevelopmentMode()
        or FORGE.Tests == nil then
        return
    end

    FORGE.Logger:info(
        FORGE.Definitions.LogSource.TEST,
        "FORGE development test suite started"
    )

    local suitePassed = true

    local function runHarness(operation)
        if operation == nil then
            return
        end

        local callSucceeded, harnessResult, harnessDetail =
            pcall(operation)

        if not callSucceeded
            or harnessResult == false then
            suitePassed = false
            FORGE.Logger:error(
                FORGE.Definitions.LogSource.TEST,
                "Development test harness failed: %s",
                FORGE.Logger:safeToString(
                    callSucceeded and harnessDetail or harnessResult,
                    "<no failure detail>"
                )
            )
        end
    end

    runHarness(
        FORGE.Tests.runForgeOSDefinitionsTests
    )

    runHarness(FORGE.Tests.runLoggerTests)

    runHarness(FORGE.Tests.runEventBusTests)

    runHarness(FORGE.Tests.runStateStoreTests)

    runHarness(FORGE.Tests.runSaveManagerTests)

    runHarness(FORGE.Tests.runXMLWriterTests)

    runHarness(FORGE.Tests.runXMLReaderTests)

    runHarness(
        FORGE.Tests
            .runSaveManagerIntegrationTests
    )

    runHarness(FORGE.Tests.runForgeOSCoreTests)

    runHarness(
        FORGE.Tests.runForgeOSBootstrapTests
    )

    runHarness(
        FORGE.Tests
            .runForgeOSCoreLifecycleIntegrationTests
    )

    runHarness(
        FORGE.Tests
            .runForgeOSRegistrationCoordinatorTests
    )

    runHarness(
        FORGE.Tests
            .runForgeOSRegistrationLifecycleIntegrationTests
    )

    runHarness(
        FORGE.Tests.runDeviceRegistryTests
    )

    runHarness(
        FORGE.Tests
            .runForgeOSDeviceRegistryIntegrationTests
    )

    runHarness(
        FORGE.Tests.runAppRegistryTests
    )

    runHarness(
        FORGE.Tests
            .runForgeOSAppRegistryIntegrationTests
    )

    runHarness(
        FORGE.Tests.runPresentationResolverTests
    )

    runHarness(
        FORGE.Tests
            .runForgeOSPresentationResolverIntegrationTests
    )

    runHarness(
        FORGE.Tests.runAppLifecycleServiceTests
    )

    runHarness(
        FORGE.Tests
            .runForgeOSAppLifecycleIntegrationTests
    )

    runHarness(FORGE.Tests.runNavigationServiceTests)

    runHarness(
        FORGE.Tests.runForgeOSNavigationIntegrationTests
    )

    runHarness(FORGE.Tests.runNotificationServiceTests)

    runHarness(
        FORGE.Tests.runForgeOSNotificationIntegrationTests
    )

    runHarness(FORGE.Tests.runDeviceHostRegistryTests)
    runHarness(FORGE.Tests.runDeviceStateServiceTests)
    runHarness(FORGE.Tests.runPhoneHostTests)
    runHarness(FORGE.Tests.runLaptopHostTests)
    runHarness(FORGE.Tests.runForgeOSExportBridgeTests)
    runHarness(FORGE.Tests.runForgeOSPhoneHostIntegrationTests)
    runHarness(FORGE.Tests.runForgeOSLaptopHostIntegrationTests)
    runHarness(FORGE.Tests.runForgeOSMultiHostIntegrationTests)
    runHarness(FORGE.Tests.runForgeOSEngineInputIntegrationTests)
    runHarness(FORGE.Tests.runForgeOSCrossModBridgeIntegrationTests)
    runHarness(FORGE.Tests.runForgeOSProductionStartupIntegrationTests)
    runHarness(FORGE.Tests.runForgeOSEndToEndIntegrationTests)

    if suitePassed then
        FORGE.Logger:info(
            FORGE.Definitions.LogSource.TEST,
            "FORGE development test suite passed"
        )
    else
        FORGE.Logger:warning(
            FORGE.Definitions.LogSource.TEST,
            "FORGE development test suite completed with one or more reported failures"
        )
    end
end

local function setCursorMode(requestedMode)
    local pointerRequested = requestedMode == "FORGE_POINTER"
    if pointerRequested and (g_gui ~= nil and g_gui:getIsGuiVisible()
        or not FORGE.ForgeOS:hasVisibleRuntimeHost()) then
        return false
    end
    if pointerRequested then
        local inputComponent = g_localPlayer ~= nil
            and g_localPlayer.inputComponent or nil
        if g_inputBinding == nil
            or type(g_inputBinding.setShowMouseCursor) ~= "function"
            or inputComponent == nil
            or type(inputComponent.lock) ~= "function" then
            return false
        end
        local cursorShown = pcall(
            g_inputBinding.setShowMouseCursor,
            g_inputBinding,
            true
        )
        local inputLocked = cursorShown and pcall(
            inputComponent.lock,
            inputComponent
        )
        if not inputLocked then
            pcall(
                g_inputBinding.setShowMouseCursor,
                g_inputBinding,
                false
            )
            return false
        end
        cursorLockedInputComponent = inputComponent
        cursorMode = "FORGE_POINTER"
        return true
    end

    local cursorReleased = g_inputBinding ~= nil
        and type(g_inputBinding.setShowMouseCursor) == "function"
        and pcall(
            g_inputBinding.setShowMouseCursor,
            g_inputBinding,
            false
        )
    local inputReleased = true
    if cursorLockedInputComponent ~= nil then
        inputReleased = type(cursorLockedInputComponent.unlock) == "function"
            and pcall(
                cursorLockedInputComponent.unlock,
                cursorLockedInputComponent
            )
    end
    cursorLockedInputComponent = nil
    cursorMode = "GAMEPLAY"
    return cursorReleased and inputReleased
end

local function registerHostActions()
    if hostActionsRegistered then
        return true
    end

    if g_inputBinding == nil
        or type(g_inputBinding.registerActionEvent) ~= "function"
        or type(g_inputBinding.beginActionEventsModification) ~= "function"
        or type(g_inputBinding.endActionEventsModification) ~= "function"
        or type(g_inputBinding.setActionEventActive) ~= "function"
        or PlayerInputComponent == nil
        or PlayerInputComponent.INPUT_CONTEXT_NAME == nil
        or InputAction == nil
        or InputAction.FORGE_TOGGLE_PHONE == nil
        or InputAction.FORGE_TOGGLE_LAPTOP == nil
        or InputAction.FORGE_TOGGLE_CURSOR_MODE == nil then
        return false
    end

    local contextOpened = pcall(
        g_inputBinding.beginActionEventsModification,
        g_inputBinding,
        PlayerInputComponent.INPUT_CONTEXT_NAME
    )
    if not contextOpened then
        return false
    end

    local definitions = {
        { InputAction.FORGE_TOGGLE_PHONE, FORGE.Engine.onTogglePhone },
        { InputAction.FORGE_TOGGLE_LAPTOP, FORGE.Engine.onToggleLaptop },
        { InputAction.FORGE_TOGGLE_CURSOR_MODE, FORGE.Engine.onToggleCursorMode }
    }
    for _, definition in ipairs(definitions) do
        local succeeded, registered, eventId = pcall(
            g_inputBinding.registerActionEvent, g_inputBinding,
            definition[1], FORGE.Engine, definition[2],
            false, true, false, true)
        if not succeeded or registered ~= true or eventId == nil then
            g_inputBinding:removeActionEventsByTarget(FORGE.Engine)
            hostActionEventIds = {}
            pcall(
                g_inputBinding.endActionEventsModification,
                g_inputBinding
            )
            return false
        end
        local activated = pcall(
            g_inputBinding.setActionEventActive,
            g_inputBinding,
            eventId,
            true
        )
        if not activated then
            g_inputBinding:removeActionEventsByTarget(FORGE.Engine)
            hostActionEventIds = {}
            pcall(
                g_inputBinding.endActionEventsModification,
                g_inputBinding
            )
            return false
        end
        hostActionEventIds[definition[1]] = eventId
        FORGE.Logger:info(
            FORGE.Definitions.LogSource.ENGINE,
            "Registered Host input action '%s' with event id '%s'",
            FORGE.Logger:safeToString(definition[1], "<unknown>"),
            FORGE.Logger:safeToString(eventId, "<unknown>")
        )
    end
    local contextClosed = pcall(
        g_inputBinding.endActionEventsModification,
        g_inputBinding
    )
    if not contextClosed then
        g_inputBinding:removeActionEventsByTarget(FORGE.Engine)
        hostActionEventIds = {}
        return false
    end
    hostActionsRegistered = true
    return true
end

local function unregisterHostActions()
    setCursorMode("GAMEPLAY")
    if hostActionsRegistered
        and g_inputBinding ~= nil
        and type(g_inputBinding.removeActionEventsByTarget)
            == "function" then
        local contextOpened = false
        if type(g_inputBinding.beginActionEventsModification) == "function"
            and PlayerInputComponent ~= nil
            and PlayerInputComponent.INPUT_CONTEXT_NAME ~= nil then
            contextOpened = pcall(
                g_inputBinding.beginActionEventsModification,
                g_inputBinding,
                PlayerInputComponent.INPUT_CONTEXT_NAME
            )
        end
        pcall(
            g_inputBinding.removeActionEventsByTarget,
            g_inputBinding,
            FORGE.Engine
        )
        if contextOpened
            and type(g_inputBinding.endActionEventsModification)
                == "function" then
            pcall(
                g_inputBinding.endActionEventsModification,
                g_inputBinding
            )
        end
    end

    hostActionsRegistered = false
    hostActionEventIds = {}
end

--- Loads FORGE persistence for the active authoritative mission.
-- @param mission table|nil
-- @return boolean success
local function loadPersistence(mission)
    mission = mission or g_currentMission

    if not isAuthoritative(mission) then
        if FORGE.Logger:isDevelopmentMode() then
            FORGE.Logger:debug(
                FORGE.Definitions.LogSource.ENGINE,
                "Skipping persistence load on non-authoritative client"
            )
        end

        return true
    end

    local saveDirectory =
        getSaveDirectory(mission)

    if saveDirectory == nil then
        if FORGE.Logger:isDevelopmentMode() then
            FORGE.Logger:debug(
                FORGE.Definitions.LogSource.ENGINE,
                "No active savegame directory is available; persistence load skipped"
            )
        end

        return true
    end

    local loadSucceeded =
        FORGE.SaveManager:load(
            saveDirectory
        )

    if not loadSucceeded then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.ENGINE,
            "FORGE persistence failed to load from '%s'",
            saveDirectory
        )

        return false
    end

    FORGE.Logger:info(
        FORGE.Definitions.LogSource.ENGINE,
        "FORGE persistence loaded from '%s'",
        saveDirectory
    )

    return true
end

--- Prepares engine-owned state for one save operation.
-- @return boolean success
-- @return table|nil previousState
-- @return integer|nil newSaveCount
local function prepareEngineStateForSave()
    local saveCount, saveCountFound =
        FORGE.StateStore:get(
            ENGINE_NAMESPACE,
            "saveCount"
        )

    if not saveCountFound
        or type(saveCount) ~= "number" then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.ENGINE,
            "Cannot update save count because engine persistence state is invalid"
        )

        return false, nil, nil
    end

    local firstRun, firstRunFound =
        FORGE.StateStore:get(
            ENGINE_NAMESPACE,
            "firstRun"
        )

    if not firstRunFound
        or type(firstRun) ~= "boolean" then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.ENGINE,
            "Cannot update first-run state because engine persistence state is invalid"
        )

        return false, nil, nil
    end

    local previousState = {
        firstRun = firstRun,
        saveCount = saveCount
    }

    local newSaveCount =
        saveCount + 1

    local saveCountUpdated =
        FORGE.StateStore:set(
            ENGINE_NAMESPACE,
            "saveCount",
            newSaveCount
        )

    if not saveCountUpdated then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.ENGINE,
            "Unable to increment FORGE save count"
        )

        return false, nil, nil
    end

    local firstRunUpdated =
        FORGE.StateStore:set(
            ENGINE_NAMESPACE,
            "firstRun",
            false
        )

    if not firstRunUpdated then
        FORGE.StateStore:set(
            ENGINE_NAMESPACE,
            "saveCount",
            saveCount
        )

        FORGE.Logger:error(
            FORGE.Definitions.LogSource.ENGINE,
            "Unable to update FORGE first-run state"
        )

        return false, nil, nil
    end

    return true, previousState, newSaveCount
end

--- Restores engine-owned state after an unsuccessful save.
-- @param previousState table|nil
-- @return boolean success
local function restoreEngineStateAfterFailedSave(
    previousState
)
    if type(previousState) ~= "table" then
        return false
    end

    local saveCountRestored =
        FORGE.StateStore:set(
            ENGINE_NAMESPACE,
            "saveCount",
            previousState.saveCount
        )

    local firstRunRestored =
        FORGE.StateStore:set(
            ENGINE_NAMESPACE,
            "firstRun",
            previousState.firstRun
        )

    if not saveCountRestored
        or not firstRunRestored then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.ENGINE,
            "Unable to restore engine persistence state after failed save"
        )

        return false
    end

    return true
end

--- Installs the FORGE callback into the FS25 save lifecycle.
-- @return boolean installed
local function installSaveHook()
    if saveHookInstalled then
        return true
    end

    if FSBaseMission == nil
        or FSBaseMission.saveSavegame == nil
        or Utils == nil
        or Utils.appendedFunction == nil then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.ENGINE,
            "Unable to install the FORGE savegame lifecycle hook"
        )

        return false
    end

    FSBaseMission.saveSavegame =
        Utils.appendedFunction(
            FSBaseMission.saveSavegame,
            FORGE.Engine.onMissionSave
        )

    saveHookInstalled = true

    if FORGE.Logger:isDevelopmentMode() then
        FORGE.Logger:debug(
            FORGE.Definitions.LogSource.ENGINE,
            "Installed FORGE savegame lifecycle hook"
        )
    end

    return true
end

-----------------------------------------------------------------------------
-- Public Lifecycle API
-----------------------------------------------------------------------------

--- Called by Farming Simulator when a mission loads.
-- @param mapName any
function FORGE.Engine:loadMap(mapName)
    self.isMissionLoaded = false
    self.mapName = mapName
    forgeOSCompletionPending = false

    FORGE.Logger:info(
        FORGE.Definitions.LogSource.ENGINE,
        "Loaded map '%s'",
        FORGE.Logger:safeToString(
            mapName,
            "<unknown>"
        )
    )

    -------------------------------------------------------------------------
    -- Development Verification
    -------------------------------------------------------------------------

    runDevelopmentTests()

    -------------------------------------------------------------------------
    -- ForgeOS Bootstrap
    -------------------------------------------------------------------------

    local forgeOSStarted =
        FORGE.ForgeOS:start()
            == FORGE.Definitions
                .ForgeOSResult.SUCCESS

    if not forgeOSStarted then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.ENGINE,
            "FORGE startup could not initialise ForgeOS"
        )
    elseif not FORGE.ForgeOSExportBridge:start(g_messageCenter) then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.ENGINE,
            "FORGE startup could not activate the ForgeOS export bridge"
        )
    end

    -------------------------------------------------------------------------
    -- Production State Registration
    -------------------------------------------------------------------------

    local engineStateRegistered =
        registerEngineState()

    if not engineStateRegistered then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.ENGINE,
            "FORGE startup could not register engine persistence state"
        )
    end

    -------------------------------------------------------------------------
    -- Save Lifecycle Hook
    -------------------------------------------------------------------------

    local hookInstalled =
        installSaveHook()

    if not hookInstalled then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.ENGINE,
            "FORGE startup could not install persistence saving"
        )
    end

    -------------------------------------------------------------------------
    -- Persistence Loading
    -------------------------------------------------------------------------

    local persistenceLoaded = false

    if engineStateRegistered then
        persistenceLoaded =
            loadPersistence(
                g_currentMission
            )
    end

    if not persistenceLoaded then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.ENGINE,
            "FORGE startup completed without loaded persistence"
        )
    end

    self.isMissionLoaded = true

    if forgeOSStarted then
        forgeOSCompletionPending = true
    end

    if not registerHostActions() then
        FORGE.Logger:warning(
            FORGE.Definitions.LogSource.ENGINE,
            "FORGE Host input actions are not available"
        )
    end

    FORGE.Logger:info(
        FORGE.Definitions.LogSource.ENGINE,
        "Engine startup complete"
    )
end

--- Called after Farming Simulator writes the active savegame.
-- @param mission table|nil
function FORGE.Engine.onMissionSave(mission)
    if not FORGE.Engine.isMissionLoaded then
        return
    end

    mission = mission or g_currentMission

    if not isAuthoritative(mission) then
        return
    end

    local saveDirectory =
        getSaveDirectory(mission)

    if saveDirectory == nil then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.ENGINE,
            "Cannot save FORGE persistence because no active savegame directory is available"
        )

        return
    end

    local statePrepared,
        previousState,
        newSaveCount =
            prepareEngineStateForSave()

    if not statePrepared then
        return
    end

    local saveSucceeded =
        FORGE.SaveManager:save(
            saveDirectory
        )

    if not saveSucceeded then
        restoreEngineStateAfterFailedSave(
            previousState
        )

        FORGE.Logger:error(
            FORGE.Definitions.LogSource.ENGINE,
            "FORGE persistence failed to save into '%s'",
            saveDirectory
        )

        return
    end

    FORGE.Logger:info(
        FORGE.Definitions.LogSource.ENGINE,
        "FORGE persistence saved into '%s' (saveCount=%d firstRun=false)",
        saveDirectory,
        newSaveCount
    )
end

--- Called by Farming Simulator when the mission unloads.
function FORGE.Engine:deleteMap()
    self.isMissionLoaded = false
    self.mapName = nil
    forgeOSCompletionPending = false
    unregisterHostActions()

    if not FORGE.ForgeOSExportBridge:shutdown() then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.ENGINE,
            "ForgeOS export bridge shutdown failed"
        )
    end

    local forgeOSShutdownResult =
        FORGE.ForgeOS:shutdown()

    if forgeOSShutdownResult
        ~= FORGE.Definitions
            .ForgeOSResult.SUCCESS then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.ENGINE,
            "ForgeOS shutdown failed with result '%s'",
            forgeOSShutdownResult
        )
    end

    local clearedEvents =
        FORGE.EventBus:clearAll()

    local clearedNamespaces =
        FORGE.StateStore:clearAll()

    local clearedPersistenceRegistrations =
        FORGE.SaveManager:clearAllRegistrations()

    FORGE.Logger:info(
        FORGE.Definitions.LogSource.ENGINE,
        "Engine shutdown complete (%d event groups, %d state namespaces, and %d persistence registrations cleared)",
        clearedEvents,
        clearedNamespaces,
        clearedPersistenceRegistrations
    )
end

-----------------------------------------------------------------------------
-- Frame and Input Callbacks
-----------------------------------------------------------------------------

function FORGE.Engine:update(dt)
    if forgeOSCompletionPending then
        forgeOSCompletionPending = false

        local completionResult =
            FORGE.ForgeOS:completeStartup()

        if completionResult
            ~= FORGE.Definitions.ForgeOSResult.SUCCESS then
            FORGE.Logger:error(
                FORGE.Definitions.LogSource.ENGINE,
                "Deferred ForgeOS startup completion failed with result '%s'",
                FORGE.Logger:safeToString(
                    completionResult,
                    "<unknown>"
                )
            )
        end
    end

    if cursorMode == "FORGE_POINTER"
        and (not FORGE.ForgeOS:hasVisibleRuntimeHost()
            or g_gui ~= nil and g_gui:getIsGuiVisible()) then
        setCursorMode("GAMEPLAY")
    end

    FORGE.ForgeOS:updateRuntimeHost(dt)
end

function FORGE.Engine:draw()
    FORGE.ForgeOS:drawRuntimeHost()
end

function FORGE.Engine.onTogglePhone(
    target,
    actionName,
    inputValue,
    callbackState,
    isAnalog
)
    return FORGE.ForgeOS:dispatchHostInput(
        "FORGE_TOGGLE_PHONE",
        inputValue
    )
end

function FORGE.Engine.onToggleLaptop(target, actionName, inputValue)
    return FORGE.ForgeOS:dispatchHostInput(
        "FORGE_TOGGLE_LAPTOP", inputValue)
end

function FORGE.Engine.onToggleCursorMode(target, actionName, inputValue)
    if inputValue == 0 then
        return false
    end
    return setCursorMode(cursorMode == "GAMEPLAY"
        and "FORGE_POINTER" or "GAMEPLAY")
end

function FORGE.Engine:keyEvent(
    unicode,
    sym,
    modifier,
    isDown
)
    return FORGE.ForgeOS:dispatchHostInput(
        "KEY_EVENT",
        isDown and 1 or 0,
        {
            unicode = unicode,
            sym = sym,
            modifier = modifier
        }
    )
end

function FORGE.Engine:mouseEvent(
    posX,
    posY,
    isDown,
    isUp,
    button
)
    if cursorMode ~= "FORGE_POINTER"
        or g_gui ~= nil and g_gui:getIsGuiVisible() then
        return false
    end
    return FORGE.ForgeOS:dispatchHostPointer(
        posX,
        posY,
        isDown,
        isUp,
        button
    )
end

addModEventListener(FORGE.Engine)
