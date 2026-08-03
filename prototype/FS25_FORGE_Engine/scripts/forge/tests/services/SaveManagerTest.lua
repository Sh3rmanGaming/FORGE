---=============================================================================
--- FORGE Save Manager Tests
---
--- Manual test harness for FORGE Save Manager registration and validation.
---
--- Responsibilities:
---     • Verify persistence namespace validation.
---     • Verify existing State Store namespace requirements.
---     • Verify persistence registration.
---     • Verify duplicate registration behaviour.
---     • Verify supported persistence values.
---     • Verify unsupported-value rejection.
---     • Verify cyclic-value rejection.
---     • Verify non-finite number rejection.
---     • Verify stale persistence registration handling.
---     • Verify controlled registration cleanup.
---     • Restore shared Logger state after testing.
---
--- This harness assumes it runs before production State Store namespaces are
--- registered.
---=============================================================================

FORGE.Tests = FORGE.Tests or {}

function FORGE.Tests.runSaveManagerTests()
    local previousDevelopmentMode =
        FORGE.Logger:isDevelopmentMode()

    local previousMinimumLevel =
        FORGE.Logger:getMinimumLevel()

    local clearedRegistrationsBeforeTest =
        FORGE.SaveManager:clearAllRegistrations()

    local success, errorMessage = pcall(
        function()
            FORGE.Logger:setDevelopmentMode(true)

            FORGE.Logger:setMinimumLevel(
                FORGE.Definitions.LogLevel.TRACE
            )

            local namespacesClearedBeforeTest =
                FORGE.StateStore:clearAll()

            -----------------------------------------------------------------
            -- Persistence Registration
            -----------------------------------------------------------------

            local namespace =
                "forge.test.persistence"

            local namespaceCreated =
                FORGE.StateStore:register(namespace)

            local registered =
                FORGE.SaveManager:registerNamespace(
                    namespace
                )

            local duplicateRegistered =
                FORGE.SaveManager:registerNamespace(
                    namespace
                )

            local isRegistered =
                FORGE.SaveManager:isNamespaceRegistered(
                    namespace
                )

            local missingRegistered =
                FORGE.SaveManager:registerNamespace(
                    "forge.test.missing"
                )

            local invalidRegistered =
                FORGE.SaveManager:registerNamespace(
                    "   "
                )

            local missingIsRegistered =
                FORGE.SaveManager:isNamespaceRegistered(
                    "forge.test.missing"
                )

            -----------------------------------------------------------------
            -- Valid Persistence State
            -----------------------------------------------------------------

            local validNamespace =
                "forge.test.validPersistence"

            local validNamespaceCreated =
                FORGE.StateStore:register(
                    validNamespace
                )

            local validValuesStored =
                FORGE.StateStore:set(
                    validNamespace,
                    "settings",
                    {
                        enabled = true,
                        threshold = 42,
                        label = "FORGE",

                        nested = {
                            active = false,
                            ratio = 0.8
                        }
                    }
                )

            local validNamespaceRegistered =
                FORGE.SaveManager:registerNamespace(
                    validNamespace
                )

            local validNamespaceResult =
                FORGE.SaveManager:validateNamespace(
                    validNamespace
                )

            -----------------------------------------------------------------
            -- Unsupported Persistence State
            -----------------------------------------------------------------

            local invalidNamespace =
                "forge.test.invalidPersistence"

            local invalidNamespaceCreated =
                FORGE.StateStore:register(
                    invalidNamespace
                )

            local unsupportedValueStored =
                FORGE.StateStore:set(
                    invalidNamespace,
                    "callback",
                    function()
                    end
                )

            local invalidNamespaceRegistered =
                FORGE.SaveManager:registerNamespace(
                    invalidNamespace
                )

            local invalidNamespaceResult =
                FORGE.SaveManager:validateNamespace(
                    invalidNamespace
                )

            -----------------------------------------------------------------
            -- Cyclic Persistence State
            -----------------------------------------------------------------

            local cyclicNamespace =
                "forge.test.cyclicPersistence"

            local cyclicValue = {}
            cyclicValue.self = cyclicValue

            local cyclicNamespaceCreated =
                FORGE.StateStore:register(
                    cyclicNamespace
                )

            local cyclicValueStored =
                FORGE.StateStore:set(
                    cyclicNamespace,
                    "cycle",
                    cyclicValue
                )

            local cyclicNamespaceRegistered =
                FORGE.SaveManager:registerNamespace(
                    cyclicNamespace
                )

            local cyclicNamespaceResult =
                FORGE.SaveManager:validateNamespace(
                    cyclicNamespace
                )

            -----------------------------------------------------------------
            -- Non-Finite Number Rejection
            -----------------------------------------------------------------

            local nonFiniteNamespace =
                "forge.test.nonFinitePersistence"

            local nonFiniteNamespaceCreated =
                FORGE.StateStore:register(
                    nonFiniteNamespace
                )

            local nonFiniteValueStored =
                FORGE.StateStore:set(
                    nonFiniteNamespace,
                    "infiniteValue",
                    math.huge
                )

            local nonFiniteNamespaceRegistered =
                FORGE.SaveManager:registerNamespace(
                    nonFiniteNamespace
                )

            local nonFiniteNamespaceResult =
                FORGE.SaveManager:validateNamespace(
                    nonFiniteNamespace
                )

            -----------------------------------------------------------------
            -- Unregistered Persistence Validation
            -----------------------------------------------------------------

            local stateOnlyNamespace =
                "forge.test.notPersistent"

            local stateOnlyNamespaceCreated =
                FORGE.StateStore:register(
                    stateOnlyNamespace
                )

            local unregisteredValidation =
                FORGE.SaveManager:validateNamespace(
                    stateOnlyNamespace
                )

            -----------------------------------------------------------------
            -- Stale Persistence Registration
            -----------------------------------------------------------------

            local staleNamespace =
                "forge.test.stalePersistence"

            local staleNamespaceCreated =
                FORGE.StateStore:register(
                    staleNamespace
                )

            local staleNamespaceRegistered =
                FORGE.SaveManager:registerNamespace(
                    staleNamespace
                )

            local stateStoreClearedForStaleTest =
                FORGE.StateStore:clearAll()

            local staleNamespaceResult =
                FORGE.SaveManager:validateNamespace(
                    staleNamespace
                )

            -----------------------------------------------------------------
            -- Results
            -----------------------------------------------------------------

            FORGE.Logger:info(
                FORGE.Definitions.LogSource.TEST,
                "Save Manager registration: preTestNamespacesCleared=%d preTestRegistrationsCleared=%d stateCreated=%s registered=%s duplicate=%s isRegistered=%s missingRegistered=%s invalidRegistered=%s missingIsRegistered=%s",
                namespacesClearedBeforeTest,
                clearedRegistrationsBeforeTest,
                FORGE.Logger:safeToString(
                    namespaceCreated,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    registered,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    duplicateRegistered,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    isRegistered,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    missingRegistered,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    invalidRegistered,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    missingIsRegistered,
                    "false"
                )
            )

            FORGE.Logger:info(
                FORGE.Definitions.LogSource.TEST,
                "Save Manager valid state: stateCreated=%s valueStored=%s registered=%s valid=%s",
                FORGE.Logger:safeToString(
                    validNamespaceCreated,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    validValuesStored,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    validNamespaceRegistered,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    validNamespaceResult,
                    "false"
                )
            )

            FORGE.Logger:info(
                FORGE.Definitions.LogSource.TEST,
                "Save Manager unsupported state: stateCreated=%s valueStored=%s registered=%s valid=%s",
                FORGE.Logger:safeToString(
                    invalidNamespaceCreated,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    unsupportedValueStored,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    invalidNamespaceRegistered,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    invalidNamespaceResult,
                    "false"
                )
            )

            FORGE.Logger:info(
                FORGE.Definitions.LogSource.TEST,
                "Save Manager cyclic state: stateCreated=%s valueStored=%s registered=%s valid=%s",
                FORGE.Logger:safeToString(
                    cyclicNamespaceCreated,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    cyclicValueStored,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    cyclicNamespaceRegistered,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    cyclicNamespaceResult,
                    "false"
                )
            )

            FORGE.Logger:info(
                FORGE.Definitions.LogSource.TEST,
                "Save Manager numeric state: stateCreated=%s valueStored=%s registered=%s valid=%s",
                FORGE.Logger:safeToString(
                    nonFiniteNamespaceCreated,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    nonFiniteValueStored,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    nonFiniteNamespaceRegistered,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    nonFiniteNamespaceResult,
                    "false"
                )
            )

            FORGE.Logger:info(
                FORGE.Definitions.LogSource.TEST,
                "Save Manager validation boundaries: stateOnlyCreated=%s unregisteredValid=%s staleCreated=%s staleRegistered=%s clearedForStaleTest=%d staleValid=%s",
                FORGE.Logger:safeToString(
                    stateOnlyNamespaceCreated,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    unregisteredValidation,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    staleNamespaceCreated,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    staleNamespaceRegistered,
                    "false"
                ),
                stateStoreClearedForStaleTest,
                FORGE.Logger:safeToString(
                    staleNamespaceResult,
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
            "Save Manager cleanup: namespacesCleared=%d registrationsCleared=%d",
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
            "Save Manager test harness failed unexpectedly: %s",
            FORGE.Logger:safeToString(
                errorMessage,
                "<unprintable error>"
            )
        )

        return false
    end

    return true
end