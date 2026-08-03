---=============================================================================
--- FORGE State Store Tests
---
--- Manual test harness for the FORGE State Store service.
---
--- Responsibilities:
---     • Verify namespace registration and validation.
---     • Verify value storage and retrieval.
---     • Verify missing-value handling.
---     • Verify value removal.
---     • Verify namespace clearing.
---     • Verify full State Store cleanup.
---     • Restore shared State Store state after testing.
---=============================================================================

FORGE.Tests = FORGE.Tests or {}

function FORGE.Tests.runStateStoreTests()
    local previousDevelopmentMode =
        FORGE.Logger:isDevelopmentMode()

    local previousMinimumLevel =
        FORGE.Logger:getMinimumLevel()

    local previousNamespaces =
        FORGE.StateStore.namespaces

    FORGE.StateStore.namespaces = {}

    local success, errorMessage = pcall(
        function()
            FORGE.Logger:setDevelopmentMode(true)

            FORGE.Logger:setMinimumLevel(
                FORGE.Definitions.LogLevel.TRACE
            )

            local namespace = "forge.test.state"

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

            local removedNumber =
                FORGE.StateStore:remove(
                    namespace,
                    "numberValue"
                )

            local removedNumberAgain =
                FORGE.StateStore:remove(
                    namespace,
                    "numberValue"
                )

            local _, numberFoundAfterRemoval =
                FORGE.StateStore:get(
                    namespace,
                    "numberValue"
                )

            local clearedNamespace =
                FORGE.StateStore:clear(namespace)

            local existsAfterClear =
                FORGE.StateStore:exists(namespace)

            local _, booleanFoundAfterClear =
                FORGE.StateStore:get(
                    namespace,
                    "booleanValue"
                )

            FORGE.StateStore:register(
                "forge.test.second"
            )

            local clearedNamespaceCount =
                FORGE.StateStore:clearAll()

            local existsAfterClearAll =
                FORGE.StateStore:exists(namespace)

            FORGE.Logger:info(
                FORGE.Definitions.LogSource.TEST,
                "State Store registration: created=%s duplicate=%s exists=%s missing=%s invalid=%s",
                FORGE.Logger:safeToString(created, "false"),
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
                "State Store removal: removed=%s removedAgain=%s foundAfterRemoval=%s",
                FORGE.Logger:safeToString(
                    removedNumber,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    removedNumberAgain,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    numberFoundAfterRemoval,
                    "false"
                )
            )

            FORGE.Logger:info(
                FORGE.Definitions.LogSource.TEST,
                "State Store cleanup: namespaceCleared=%s namespacePreserved=%s valueRemoved=%s clearedNamespaces=%d existsAfterClearAll=%s",
                FORGE.Logger:safeToString(
                    clearedNamespace,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    existsAfterClear,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    booleanFoundAfterClear,
                    "false"
                ),
                clearedNamespaceCount,
                FORGE.Logger:safeToString(
                    existsAfterClearAll,
                    "false"
                )
            )
        end
    )

    FORGE.StateStore.namespaces =
        previousNamespaces

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

        return false
    end

    return true
end