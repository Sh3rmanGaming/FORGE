---=============================================================================
--- FORGE Save Manager Integration Tests
---
--- Manual integration harness for the complete FORGE persistence pipeline.
---
--- Responsibilities:
---     • Verify registered State Store namespaces can be saved.
---     • Verify saved namespaces can be restored after runtime mutation.
---     • Verify nested tables and primitive values survive a round trip.
---     • Verify empty namespaces survive a round trip.
---     • Verify unregistered namespaces are not persisted or overwritten.
---     • Verify missing persistence files preserve current runtime state.
---     • Verify unsupported persistence versions are rejected safely.
---     • Verify failed version validation does not modify runtime state.
---     • Verify invalid save-directory handling.
---     • Restore shared State Store, Save Manager, and Logger state.
---
--- This harness uses an isolated modSettings directory and must not write to
--- a real Farming Simulator savegame.
---
--- This harness assumes it runs before production namespaces are registered.
---=============================================================================

FORGE.Tests = FORGE.Tests or {}

function FORGE.Tests.runSaveManagerIntegrationTests()
    local previousDevelopmentMode =
        FORGE.Logger:isDevelopmentMode()

    local previousMinimumLevel =
        FORGE.Logger:getMinimumLevel()

    local clearedNamespacesBeforeTest =
        FORGE.StateStore:clearAll()

    local clearedRegistrationsBeforeTest =
        FORGE.SaveManager:clearAllRegistrations()

    local testRootDirectory =
        getUserProfileAppPath()
        .. "modSettings/FS25_FORGE_Engine"

    local integrationDirectory =
        testRootDirectory
        .. "/integration"

    local missingFileDirectory =
        testRootDirectory
        .. "/integrationMissing"

    local persistenceFilePath =
        integrationDirectory
        .. "/"
        .. FORGE.SaveManager.FILE_NAME

    local success, errorMessage = pcall(
        function()
            FORGE.Logger:setDevelopmentMode(true)

            FORGE.Logger:setMinimumLevel(
                FORGE.Definitions.LogLevel.TRACE
            )

            createFolder(testRootDirectory)
            createFolder(integrationDirectory)
            createFolder(missingFileDirectory)

            -----------------------------------------------------------------
            -- Namespace Setup
            -----------------------------------------------------------------

            local primaryNamespace =
                "forge.test.integration.primary"

            local emptyNamespace =
                "forge.test.integration.empty"

            local unregisteredNamespace =
                "forge.test.integration.unregistered"

            local primaryCreated =
                FORGE.StateStore:register(
                    primaryNamespace
                )

            local emptyCreated =
                FORGE.StateStore:register(
                    emptyNamespace
                )

            local unregisteredCreated =
                FORGE.StateStore:register(
                    unregisteredNamespace
                )

            local primaryRegistered =
                FORGE.SaveManager:registerNamespace(
                    primaryNamespace
                )

            local emptyRegistered =
                FORGE.SaveManager:registerNamespace(
                    emptyNamespace
                )

            local originalPrimaryState = {
                active = true,
                balance = 25000,
                name = "FORGE",

                settings = {
                    difficulty = "normal",
                    notifications = false,
                    threshold = 0.8
                }
            }

            local primaryStateApplied =
                FORGE.StateStore:replaceNamespace(
                    primaryNamespace,
                    originalPrimaryState
                )

            local unregisteredInitialStateApplied =
                FORGE.StateStore:replaceNamespace(
                    unregisteredNamespace,
                    {
                        value = "not persisted"
                    }
                )

            -----------------------------------------------------------------
            -- Save
            -----------------------------------------------------------------

            local saveSucceeded =
                FORGE.SaveManager:save(
                    integrationDirectory
                )

            local savedDocumentRead,
                savedDocument =
                    FORGE.XMLReader:read(
                        persistenceFilePath
                    )

            local savedNamespaces =
                savedDocumentRead
                and type(savedDocument) == "table"
                and type(savedDocument.namespaces)
                    == "table"
                and savedDocument.namespaces
                or nil

            local primaryWritten =
                type(savedNamespaces) == "table"
                and type(
                    savedNamespaces[
                        primaryNamespace
                    ]
                ) == "table"

            local emptyWritten =
                type(savedNamespaces) == "table"
                and type(
                    savedNamespaces[
                        emptyNamespace
                    ]
                ) == "table"
                and next(
                    savedNamespaces[
                        emptyNamespace
                    ]
                ) == nil

            local unregisteredExcluded =
                type(savedNamespaces) == "table"
                and savedNamespaces[
                    unregisteredNamespace
                ] == nil

            -----------------------------------------------------------------
            -- Runtime Mutation Before Load
            -----------------------------------------------------------------

            local primaryMutationApplied =
                FORGE.StateStore:replaceNamespace(
                    primaryNamespace,
                    {
                        active = false,
                        balance = -1,
                        name = "MUTATED",

                        settings = {
                            difficulty = "changed",
                            notifications = true,
                            threshold = 99
                        }
                    }
                )

            local emptyMutationApplied =
                FORGE.StateStore:set(
                    emptyNamespace,
                    "temporary",
                    "remove on load"
                )

            local unregisteredMutationApplied =
                FORGE.StateStore:replaceNamespace(
                    unregisteredNamespace,
                    {
                        value = "preserve mutation"
                    }
                )

            -----------------------------------------------------------------
            -- Load and Round-Trip Validation
            -----------------------------------------------------------------

            local loadSucceeded =
                FORGE.SaveManager:load(
                    integrationDirectory
                )

            local restoredPrimary,
                restoredPrimaryFound =
                    FORGE.StateStore:snapshot(
                        primaryNamespace
                    )

            local restoredEmpty,
                restoredEmptyFound =
                    FORGE.StateStore:snapshot(
                        emptyNamespace
                    )

            local preservedUnregistered,
                preservedUnregisteredFound =
                    FORGE.StateStore:snapshot(
                        unregisteredNamespace
                    )

            local activeRestored =
                restoredPrimaryFound
                and restoredPrimary.active == true

            local balanceRestored =
                restoredPrimaryFound
                and restoredPrimary.balance == 25000

            local nameRestored =
                restoredPrimaryFound
                and restoredPrimary.name == "FORGE"

            local settingsRestored =
                restoredPrimaryFound
                and type(restoredPrimary.settings)
                    == "table"

            local difficultyRestored =
                settingsRestored
                and restoredPrimary.settings.difficulty
                    == "normal"

            local notificationsRestored =
                settingsRestored
                and restoredPrimary.settings.notifications
                    == false

            local thresholdRestored =
                settingsRestored
                and type(
                    restoredPrimary.settings.threshold
                ) == "number"
                and math.abs(
                    restoredPrimary.settings.threshold
                    - 0.8
                ) < 0.000001

            local emptyNamespaceRestored =
                restoredEmptyFound
                and type(restoredEmpty) == "table"
                and next(restoredEmpty) == nil

            local unregisteredStatePreserved =
                preservedUnregisteredFound
                and preservedUnregistered.value
                    == "preserve mutation"

            local roundTripValid =
                saveSucceeded
                and savedDocumentRead
                and primaryWritten
                and emptyWritten
                and unregisteredExcluded
                and loadSucceeded
                and activeRestored
                and balanceRestored
                and nameRestored
                and settingsRestored
                and difficultyRestored
                and notificationsRestored
                and thresholdRestored
                and emptyNamespaceRestored
                and unregisteredStatePreserved

            -----------------------------------------------------------------
            -- Missing File Behaviour
            -----------------------------------------------------------------

            local missingFileBaselineApplied =
                FORGE.StateStore:replaceNamespace(
                    primaryNamespace,
                    {
                        marker = "preserve on missing file"
                    }
                )

            local missingFileLoadSucceeded =
                FORGE.SaveManager:load(
                    missingFileDirectory
                )

            local missingFileState,
                missingFileStateFound =
                    FORGE.StateStore:snapshot(
                        primaryNamespace
                    )

            local missingFileStatePreserved =
                missingFileStateFound
                and missingFileState.marker
                    == "preserve on missing file"

            -----------------------------------------------------------------
            -- Unsupported Version Behaviour
            -----------------------------------------------------------------

            local unsupportedBaselineApplied =
                FORGE.StateStore:replaceNamespace(
                    primaryNamespace,
                    {
                        marker = "preserve on bad version"
                    }
                )

            local unsupportedDocumentWritten =
                FORGE.XMLWriter:write(
                    persistenceFilePath,
                    {
                        version =
                            FORGE.SaveManager.SAVE_VERSION
                            + 1,

                        namespaces = {
                            [primaryNamespace] = {
                                marker =
                                    "must not be applied"
                            }
                        }
                    }
                )

            local unsupportedLoadSucceeded =
                FORGE.SaveManager:load(
                    integrationDirectory
                )

            local stateAfterUnsupportedLoad,
                stateAfterUnsupportedLoadFound =
                    FORGE.StateStore:snapshot(
                        primaryNamespace
                    )

            local unsupportedVersionPreservedState =
                stateAfterUnsupportedLoadFound
                and stateAfterUnsupportedLoad.marker
                    == "preserve on bad version"

            -----------------------------------------------------------------
            -- Invalid Directory Handling
            -----------------------------------------------------------------

            local invalidSaveSucceeded =
                FORGE.SaveManager:save(
                    "   "
                )

            local invalidLoadSucceeded =
                FORGE.SaveManager:load(
                    "   "
                )

            -----------------------------------------------------------------
            -- Results
            -----------------------------------------------------------------

            FORGE.Logger:info(
                FORGE.Definitions.LogSource.TEST,
                "Save Manager integration setup: preTestNamespacesCleared=%d preTestRegistrationsCleared=%d primaryCreated=%s emptyCreated=%s unregisteredCreated=%s primaryRegistered=%s emptyRegistered=%s primaryStateApplied=%s unregisteredStateApplied=%s",
                clearedNamespacesBeforeTest,
                clearedRegistrationsBeforeTest,
                FORGE.Logger:safeToString(
                    primaryCreated,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    emptyCreated,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    unregisteredCreated,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    primaryRegistered,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    emptyRegistered,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    primaryStateApplied,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    unregisteredInitialStateApplied,
                    "false"
                )
            )

            FORGE.Logger:info(
                FORGE.Definitions.LogSource.TEST,
                "Save Manager integration save: saveSucceeded=%s documentRead=%s primaryWritten=%s emptyWritten=%s unregisteredExcluded=%s file='%s'",
                FORGE.Logger:safeToString(
                    saveSucceeded,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    savedDocumentRead,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    primaryWritten,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    emptyWritten,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    unregisteredExcluded,
                    "false"
                ),
                persistenceFilePath
            )

            FORGE.Logger:info(
                FORGE.Definitions.LogSource.TEST,
                "Save Manager integration mutation: primaryMutated=%s emptyMutated=%s unregisteredMutated=%s",
                FORGE.Logger:safeToString(
                    primaryMutationApplied,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    emptyMutationApplied,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    unregisteredMutationApplied,
                    "false"
                )
            )

            FORGE.Logger:info(
                FORGE.Definitions.LogSource.TEST,
                "Save Manager integration restore: loadSucceeded=%s active=%s balance=%s name=%s settings=%s difficulty=%s notifications=%s threshold=%s emptyRestored=%s unregisteredPreserved=%s roundTripValid=%s",
                FORGE.Logger:safeToString(
                    loadSucceeded,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    activeRestored,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    balanceRestored,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    nameRestored,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    settingsRestored,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    difficultyRestored,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    notificationsRestored,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    thresholdRestored,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    emptyNamespaceRestored,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    unregisteredStatePreserved,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    roundTripValid,
                    "false"
                )
            )

            FORGE.Logger:info(
                FORGE.Definitions.LogSource.TEST,
                "Save Manager integration missing file: baselineApplied=%s loadSucceeded=%s statePreserved=%s",
                FORGE.Logger:safeToString(
                    missingFileBaselineApplied,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    missingFileLoadSucceeded,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    missingFileStatePreserved,
                    "false"
                )
            )

            FORGE.Logger:info(
                FORGE.Definitions.LogSource.TEST,
                "Save Manager integration unsupported version: baselineApplied=%s documentWritten=%s loadSucceeded=%s statePreserved=%s",
                FORGE.Logger:safeToString(
                    unsupportedBaselineApplied,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    unsupportedDocumentWritten,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    unsupportedLoadSucceeded,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    unsupportedVersionPreservedState,
                    "false"
                )
            )

            FORGE.Logger:info(
                FORGE.Definitions.LogSource.TEST,
                "Save Manager integration boundaries: invalidSave=%s invalidLoad=%s",
                FORGE.Logger:safeToString(
                    invalidSaveSucceeded,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    invalidLoadSucceeded,
                    "false"
                )
            )
        end
    )

    local clearedNamespacesAfterTest =
        FORGE.StateStore:clearAll()

    local clearedRegistrationsAfterTest =
        FORGE.SaveManager:clearAllRegistrations()

    if success then
        FORGE.Logger:info(
            FORGE.Definitions.LogSource.TEST,
            "Save Manager integration cleanup: namespacesCleared=%d registrationsCleared=%d",
            clearedNamespacesAfterTest,
            clearedRegistrationsAfterTest
        )
    end

    FORGE.Logger:setDevelopmentMode(
        previousDevelopmentMode
    )

    FORGE.Logger:setMinimumLevel(
        previousMinimumLevel
    )

    if not success then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.TEST,
            "Save Manager integration test failed unexpectedly: %s",
            FORGE.Logger:safeToString(
                errorMessage,
                "<unprintable error>"
            )
        )

        return false
    end

    return true
end