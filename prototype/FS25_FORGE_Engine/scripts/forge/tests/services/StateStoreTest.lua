---=============================================================================
--- FORGE State Store Tests
---
--- Manual test harness for the FORGE State Store service.
---
--- Responsibilities:
---     • Verify namespace registration and validation.
---     • Verify value storage and retrieval.
---     • Verify missing-value handling.
---     • Verify detached namespace snapshots.
---     • Verify nested-table snapshot isolation.
---     • Verify cyclic and shared reference preservation.
---     • Verify atomic namespace replacement.
---     • Verify replacement input isolation.
---     • Verify value removal.
---     • Verify namespace clearing.
---     • Verify full State Store cleanup.
---     • Restore shared Logger state after testing.
---
--- This harness assumes it runs before production namespaces are registered.
---=============================================================================

FORGE.Tests = FORGE.Tests or {}

function FORGE.Tests.runStateStoreTests()
    local previousDevelopmentMode =
        FORGE.Logger:isDevelopmentMode()

    local previousMinimumLevel =
        FORGE.Logger:getMinimumLevel()

    local success, errorMessage = pcall(
        function()
            FORGE.Logger:setDevelopmentMode(true)

            FORGE.Logger:setMinimumLevel(
                FORGE.Definitions.LogLevel.TRACE
            )

            local namespacesClearedBeforeTest =
                FORGE.StateStore:clearAll()

            local namespace =
                "forge.test.state"

            local secondNamespace =
                "forge.test.second"

            -----------------------------------------------------------------
            -- Namespace Registration
            -----------------------------------------------------------------

            local created =
                FORGE.StateStore:register(namespace)

            local duplicateCreated =
                FORGE.StateStore:register(namespace)

            local existsAfterRegister =
                FORGE.StateStore:exists(namespace)

            local missingExists =
                FORGE.StateStore:exists(
                    "forge.test.missing"
                )

            local invalidRegister =
                FORGE.StateStore:register("   ")

            -----------------------------------------------------------------
            -- Value Storage and Retrieval
            -----------------------------------------------------------------

            local storedNumber =
                FORGE.StateStore:set(
                    namespace,
                    "numberValue",
                    42
                )

            local storedFalse =
                FORGE.StateStore:set(
                    namespace,
                    "booleanValue",
                    false
                )

            local rejectedNil =
                FORGE.StateStore:set(
                    namespace,
                    "nilValue",
                    nil
                )

            local numberValue, numberFound =
                FORGE.StateStore:get(
                    namespace,
                    "numberValue"
                )

            local booleanValue, booleanFound =
                FORGE.StateStore:get(
                    namespace,
                    "booleanValue"
                )

            local missingValue, missingFound =
                FORGE.StateStore:get(
                    namespace,
                    "missingValue"
                )

            -----------------------------------------------------------------
            -- Snapshot Isolation
            -----------------------------------------------------------------

            local nestedSource = {
                label = "original",

                settings = {
                    enabled = true,
                    threshold = 0.8
                }
            }

            local storedNested =
                FORGE.StateStore:set(
                    namespace,
                    "nestedValue",
                    nestedSource
                )

            local snapshot, snapshotFound =
                FORGE.StateStore:snapshot(namespace)

            local snapshotIsDetached =
                snapshotFound
                and type(snapshot) == "table"
                and snapshot ~= nestedSource

            if snapshotFound
                and type(snapshot.nestedValue) == "table"
                and type(
                    snapshot.nestedValue.settings
                ) == "table" then
                snapshot.nestedValue.label =
                    "modified snapshot"

                snapshot.nestedValue.settings.enabled =
                    false
            end

            local liveSnapshotAfterMutation,
                liveSnapshotFound =
                    FORGE.StateStore:snapshot(namespace)

            local snapshotMutationIsolated =
                liveSnapshotFound
                and liveSnapshotAfterMutation
                    .nestedValue.label == "original"
                and liveSnapshotAfterMutation
                    .nestedValue.settings.enabled == true

            -----------------------------------------------------------------
            -- Cyclic and Shared Reference Preservation
            -----------------------------------------------------------------

            local cyclicValue = {}
            cyclicValue.self = cyclicValue

            local storedCycle =
                FORGE.StateStore:set(
                    namespace,
                    "cyclicValue",
                    cyclicValue
                )

            local sharedValue = {
                marker = "shared"
            }

            local sharedContainer = {
                left = sharedValue,
                right = sharedValue
            }

            local storedSharedReference =
                FORGE.StateStore:set(
                    namespace,
                    "sharedValue",
                    sharedContainer
                )

            local referenceSnapshot,
                referenceSnapshotFound =
                    FORGE.StateStore:snapshot(
                        namespace
                    )

            local copiedCycle =
                referenceSnapshotFound
                and referenceSnapshot.cyclicValue
                or nil

            local cyclePreserved =
                type(copiedCycle) == "table"
                and copiedCycle ~= cyclicValue
                and copiedCycle.self == copiedCycle

            local copiedSharedContainer =
                referenceSnapshotFound
                and referenceSnapshot.sharedValue
                or nil

            local sharedReferencePreserved =
                type(copiedSharedContainer) == "table"
                and type(
                    copiedSharedContainer.left
                ) == "table"
                and copiedSharedContainer.left
                    == copiedSharedContainer.right
                and copiedSharedContainer.left
                    ~= sharedValue

            -----------------------------------------------------------------
            -- Atomic Namespace Replacement
            -----------------------------------------------------------------

            local replacementSource = {
                status = "loaded",

                nested = {
                    count = 7
                }
            }

            local replacedNamespace =
                FORGE.StateStore:replaceNamespace(
                    namespace,
                    replacementSource
                )

            replacementSource.status =
                "modified caller"

            replacementSource.nested.count =
                99

            local replacementSnapshot,
                replacementSnapshotFound =
                    FORGE.StateStore:snapshot(
                        namespace
                    )

            local replacementApplied =
                replacementSnapshotFound
                and replacementSnapshot.status
                    == "loaded"
                and replacementSnapshot.nested.count
                    == 7

            local replacementInputIsolated =
                replacementSnapshotFound
                and replacementSnapshot.status
                    ~= replacementSource.status
                and replacementSnapshot.nested.count
                    ~= replacementSource.nested.count

            local rejectedNonTableReplacement =
                FORGE.StateStore:replaceNamespace(
                    namespace,
                    "invalid"
                )

            local rejectedMissingReplacement =
                FORGE.StateStore:replaceNamespace(
                    "forge.test.missing",
                    {}
                )

            local rejectedInvalidReplacement =
                FORGE.StateStore:replaceNamespace(
                    "   ",
                    {}
                )

            -----------------------------------------------------------------
            -- Removal and Clearing
            -----------------------------------------------------------------

            FORGE.StateStore:set(
                namespace,
                "removableValue",
                100
            )

            local removedValue =
                FORGE.StateStore:remove(
                    namespace,
                    "removableValue"
                )

            local removedValueAgain =
                FORGE.StateStore:remove(
                    namespace,
                    "removableValue"
                )

            local _, valueFoundAfterRemoval =
                FORGE.StateStore:get(
                    namespace,
                    "removableValue"
                )

            local clearedNamespace =
                FORGE.StateStore:clear(namespace)

            local existsAfterClear =
                FORGE.StateStore:exists(namespace)

            local clearedSnapshot,
                clearedSnapshotFound =
                    FORGE.StateStore:snapshot(
                        namespace
                    )

            local namespaceEmptyAfterClear =
                clearedSnapshotFound
                and type(clearedSnapshot) == "table"
                and next(clearedSnapshot) == nil

            local secondNamespaceCreated =
                FORGE.StateStore:register(
                    secondNamespace
                )

            local clearedNamespaceCount =
                FORGE.StateStore:clearAll()

            local existsAfterClearAll =
                FORGE.StateStore:exists(namespace)

            local secondExistsAfterClearAll =
                FORGE.StateStore:exists(
                    secondNamespace
                )

            -----------------------------------------------------------------
            -- Results
            -----------------------------------------------------------------

            FORGE.Logger:info(
                FORGE.Definitions.LogSource.TEST,
                "State Store registration: preTestCleared=%d created=%s duplicate=%s exists=%s missing=%s invalid=%s",
                namespacesClearedBeforeTest,
                FORGE.Logger:safeToString(
                    created,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    duplicateCreated,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    existsAfterRegister,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    missingExists,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    invalidRegister,
                    "false"
                )
            )

            FORGE.Logger:info(
                FORGE.Definitions.LogSource.TEST,
                "State Store set/get: numberStored=%s number=%s numberFound=%s falseStored=%s falseValue=%s falseFound=%s nilRejected=%s missingValue=%s missingFound=%s",
                FORGE.Logger:safeToString(
                    storedNumber,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    numberValue,
                    "<nil>"
                ),
                FORGE.Logger:safeToString(
                    numberFound,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    storedFalse,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    booleanValue,
                    "<nil>"
                ),
                FORGE.Logger:safeToString(
                    booleanFound,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    rejectedNil,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    missingValue,
                    "<nil>"
                ),
                FORGE.Logger:safeToString(
                    missingFound,
                    "false"
                )
            )

            FORGE.Logger:info(
                FORGE.Definitions.LogSource.TEST,
                "State Store snapshot: nestedStored=%s snapshotFound=%s detached=%s mutationIsolated=%s cycleStored=%s cyclePreserved=%s sharedStored=%s sharedPreserved=%s",
                FORGE.Logger:safeToString(
                    storedNested,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    snapshotFound,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    snapshotIsDetached,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    snapshotMutationIsolated,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    storedCycle,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    cyclePreserved,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    storedSharedReference,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    sharedReferencePreserved,
                    "false"
                )
            )

            FORGE.Logger:info(
                FORGE.Definitions.LogSource.TEST,
                "State Store replacement: replaced=%s applied=%s inputIsolated=%s nonTableRejected=%s missingRejected=%s invalidRejected=%s",
                FORGE.Logger:safeToString(
                    replacedNamespace,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    replacementApplied,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    replacementInputIsolated,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    rejectedNonTableReplacement,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    rejectedMissingReplacement,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    rejectedInvalidReplacement,
                    "false"
                )
            )

            FORGE.Logger:info(
                FORGE.Definitions.LogSource.TEST,
                "State Store removal: removed=%s removedAgain=%s foundAfterRemoval=%s",
                FORGE.Logger:safeToString(
                    removedValue,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    removedValueAgain,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    valueFoundAfterRemoval,
                    "false"
                )
            )

            FORGE.Logger:info(
                FORGE.Definitions.LogSource.TEST,
                "State Store cleanup: namespaceCleared=%s namespacePreserved=%s namespaceEmpty=%s secondCreated=%s clearedNamespaces=%d existsAfterClearAll=%s secondExistsAfterClearAll=%s",
                FORGE.Logger:safeToString(
                    clearedNamespace,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    existsAfterClear,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    namespaceEmptyAfterClear,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    secondNamespaceCreated,
                    "false"
                ),
                clearedNamespaceCount,
                FORGE.Logger:safeToString(
                    existsAfterClearAll,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    secondExistsAfterClearAll,
                    "false"
                )
            )
        end
    )

    FORGE.Logger:setDevelopmentMode(
        previousDevelopmentMode
    )

    FORGE.Logger:setMinimumLevel(
        previousMinimumLevel
    )

    if not success then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.TEST,
            "State Store test harness failed unexpectedly: %s",
            FORGE.Logger:safeToString(
                errorMessage,
                "<unprintable error>"
            )
        )

        FORGE.StateStore:clearAll()

        return false
    end

    return true
end