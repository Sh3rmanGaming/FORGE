---=============================================================================
--- FORGE XML Reader Tests
---
--- Manual test harness for the FORGE XML Reader service.
---
--- Responsibilities:
---     • Verify XML document loading.
---     • Verify decoded document creation.
---     • Verify persistence-format version decoding.
---     • Verify empty namespace decoding.
---     • Verify primitive value decoding.
---     • Verify recursive table decoding.
---     • Verify invalid path handling.
---     • Verify missing file handling.
---     • Restore shared Logger state after testing.
---
--- This file must not contain production persistence logic.
---=============================================================================

FORGE.Tests = FORGE.Tests or {}

function FORGE.Tests.runXMLReaderTests()
    local previousDevelopmentMode =
        FORGE.Logger:isDevelopmentMode()

    local previousMinimumLevel =
        FORGE.Logger:getMinimumLevel()

    local testDirectory =
        getUserProfileAppPath()
        .. "modSettings/FS25_FORGE_Engine"

    local testFilePath =
        testDirectory
        .. "/XMLWriterTest.xml"

    local missingFilePath =
        testDirectory
        .. "/MissingXMLReaderTest.xml"

    local success, errorMessage = pcall(
        function()
            FORGE.Logger:setDevelopmentMode(true)

            FORGE.Logger:setMinimumLevel(
                FORGE.Definitions.LogLevel.TRACE
            )

            local readSucceeded, document =
                FORGE.XMLReader:read(
                    testFilePath
                )

            local documentExists =
                type(document) == "table"

            local versionValid =
                documentExists
                and document.version == 1

            local namespaces =
                documentExists
                and document.namespaces
                or nil

            local namespacesValid =
                type(namespaces) == "table"

            local emptyNamespace =
                namespacesValid
                and namespaces["forge.test.empty"]
                or nil

            local emptyNamespaceValid =
                type(emptyNamespace) == "table"
                and next(emptyNamespace) == nil

            local writerNamespace =
                namespacesValid
                and namespaces["forge.test.writer"]
                or nil

            local writerNamespaceValid =
                type(writerNamespace) == "table"

            local activeValid =
                writerNamespaceValid
                and writerNamespace.active == true

            local balanceValid =
                writerNamespaceValid
                and writerNamespace.balance == 25000

            local nameValid =
                writerNamespaceValid
                and writerNamespace.name == "FORGE"

            local settings =
                writerNamespaceValid
                and writerNamespace.settings
                or nil

            local settingsValid =
                type(settings) == "table"

            local difficultyValid =
                settingsValid
                and settings.difficulty == "normal"

            local notificationsValid =
                settingsValid
                and settings.notifications == false

            local thresholdValid =
                settingsValid
                and math.abs(
                    settings.threshold - 0.8
                ) < 0.000001

            local decodedDataValid =
                readSucceeded
                and documentExists
                and versionValid
                and namespacesValid
                and emptyNamespaceValid
                and writerNamespaceValid
                and activeValid
                and balanceValid
                and nameValid
                and settingsValid
                and difficultyValid
                and notificationsValid
                and thresholdValid

            local invalidPathSucceeded,
                invalidPathDocument =
                    FORGE.XMLReader:read(
                        "   "
                    )

            local missingFileSucceeded,
                missingFileDocument =
                    FORGE.XMLReader:read(
                        missingFilePath
                    )

            FORGE.Logger:info(
                FORGE.Definitions.LogSource.TEST,
                "XML Reader document: readSucceeded=%s documentExists=%s versionValid=%s namespacesValid=%s emptyNamespaceValid=%s",
                FORGE.Logger:safeToString(
                    readSucceeded,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    documentExists,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    versionValid,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    namespacesValid,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    emptyNamespaceValid,
                    "false"
                )
            )

            FORGE.Logger:info(
                FORGE.Definitions.LogSource.TEST,
                "XML Reader values: writerNamespaceValid=%s activeValid=%s balanceValid=%s nameValid=%s settingsValid=%s difficultyValid=%s notificationsValid=%s thresholdValid=%s",
                FORGE.Logger:safeToString(
                    writerNamespaceValid,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    activeValid,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    balanceValid,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    nameValid,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    settingsValid,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    difficultyValid,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    notificationsValid,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    thresholdValid,
                    "false"
                )
            )

            FORGE.Logger:info(
                FORGE.Definitions.LogSource.TEST,
                "XML Reader validation: decodedDataValid=%s invalidPathSucceeded=%s invalidPathDocument=%s missingFileSucceeded=%s missingFileDocument=%s file='%s'",
                FORGE.Logger:safeToString(
                    decodedDataValid,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    invalidPathSucceeded,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    invalidPathDocument ~= nil,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    missingFileSucceeded,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    missingFileDocument ~= nil,
                    "false"
                ),
                testFilePath
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
            "XML Reader test harness failed unexpectedly: %s",
            FORGE.Logger:safeToString(
                errorMessage,
                "<unprintable error>"
            )
        )

        return false
    end

    return true
end