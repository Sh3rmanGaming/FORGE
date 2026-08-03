---=============================================================================
--- FORGE Save Manager Tests
---
--- Manual test harness for Save Manager persistence registration.
---
--- Responsibilities:
---     • Verify persistence namespace validation.
---     • Verify existing State Store namespace requirements.
---     • Verify persistence registration.
---     • Verify duplicate registration behaviour.
---     • Restore shared Save Manager and State Store state after testing.
---=============================================================================

FORGE.Tests = FORGE.Tests or {}

function FORGE.Tests.runSaveManagerTests()
    local previousDevelopmentMode =
        FORGE.Logger:isDevelopmentMode()

    local previousMinimumLevel =
        FORGE.Logger:getMinimumLevel()

    local previousNamespaces =
        FORGE.StateStore.namespaces

    local previousPersistentNamespaces =
        FORGE.SaveManager.persistentNamespaces

    FORGE.StateStore.namespaces = {}
    FORGE.SaveManager.persistentNamespaces = {}

    local success, errorMessage = pcall(
        function()
            FORGE.Logger:setDevelopmentMode(true)

            FORGE.Logger:setMinimumLevel(
                FORGE.Definitions.LogLevel.TRACE
            )

            local namespace = "forge.test.persistence"

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

            local validNamespace =
                "forge.test.validPersistence"

            local invalidNamespace =
                "forge.test.invalidPersistence"

            local cyclicNamespace =
                "forge.test.cyclicPersistence"

            FORGE.StateStore:register(validNamespace)

            FORGE.StateStore:set(
                validNamespace,
                "settings",
                {
                    enabled = true,
                    threshold = 42,
                    label = "FORGE"
                }
            )

            FORGE.SaveManager:registerNamespace(
                validNamespace
            )

            local validNamespaceResult =
                FORGE.SaveManager:validateNamespace(
                    validNamespace
                )

            FORGE.StateStore:register(
                invalidNamespace
            )

            FORGE.StateStore:set(
                invalidNamespace,
                "callback",
                function()
                end
            )

            FORGE.SaveManager:registerNamespace(
                invalidNamespace
            )

            local invalidNamespaceResult =
                FORGE.SaveManager:validateNamespace(
                    invalidNamespace
                )

            local cyclicValue = {}
            cyclicValue.self = cyclicValue

            FORGE.StateStore:register(
                cyclicNamespace
            )

            FORGE.StateStore:set(
                cyclicNamespace,
                "cycle",
                cyclicValue
            )

            FORGE.SaveManager:registerNamespace(
                cyclicNamespace
            )

            local cyclicNamespaceResult =
                FORGE.SaveManager:validateNamespace(
                    cyclicNamespace
                )

            local unregisteredValidation =
                FORGE.SaveManager:validateNamespace(
                    "forge.test.notPersistent"
                )

            FORGE.Logger:info(
                FORGE.Definitions.LogSource.TEST,
                "Save Manager registration: stateCreated=%s registered=%s duplicate=%s isRegistered=%s missingRegistered=%s invalidRegistered=%s missingIsRegistered=%s",
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
                "Save Manager validation: valid=%s unsupported=%s cyclic=%s unregistered=%s",
                FORGE.Logger:safeToString(
                    validNamespaceResult,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    invalidNamespaceResult,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    cyclicNamespaceResult,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    unregisteredValidation,
                    "false"
                )
            )
        end
    )

    FORGE.StateStore.namespaces =
        previousNamespaces

    FORGE.SaveManager.persistentNamespaces =
        previousPersistentNamespaces

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