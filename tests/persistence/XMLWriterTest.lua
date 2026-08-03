---=============================================================================
--- FORGE XML Writer Tests
---
--- Manual test harness for the FORGE XML Writer service.
---
--- Responsibilities:
---     • Verify document validation.
---     • Verify XML document creation.
---     • Verify recursive value serialisation.
---     • Verify deterministic namespace ordering.
---     • Verify deterministic value ordering.
---     • Verify XML save and cleanup.
---     • Restore shared state after testing.
---
--- This file must not contain production persistence logic.
---=============================================================================

FORGE.Tests = FORGE.Tests or {}

function FORGE.Tests.runXMLWriterTests()
    local previousDevelopmentMode =
        FORGE.Logger:isDevelopmentMode()

    local previousMinimumLevel =
        FORGE.Logger:getMinimumLevel()

    local document = {
        version = 1,

        namespaces = {
            ["forge.test.empty"] = {},

            ["forge.test.writer"] = {
                active = true,
                balance = 25000,
                name = "FORGE",

                settings = {
                    difficulty = "normal",
                    notifications = false,
                    threshold = 0.8
                }
            }
        }
    }

    local testDirectory =
        getUserProfileAppPath()
        .. "modSettings/FS25_FORGE_Engine"

    local testFilePath =
        testDirectory
        .. "/XMLWriterTest.xml"

    local success, errorMessage = pcall(
        function()
            FORGE.Logger:setDevelopmentMode(true)

            FORGE.Logger:setMinimumLevel(
                FORGE.Definitions.LogLevel.TRACE
            )

            createFolder(testDirectory)

            local writeSucceeded =
                FORGE.XMLWriter:write(
                    testFilePath,
                    document
                )

            local invalidPathResult =
                FORGE.XMLWriter:write(
                    "   ",
                    document
                )

            local invalidDocumentResult =
                FORGE.XMLWriter:write(
                    testFilePath,
                    {
                        version = 0,
                        namespaces = {}
                    }
                )

            FORGE.Logger:info(
                FORGE.Definitions.LogSource.TEST,
                "XML Writer results: writeSucceeded=%s invalidPath=%s invalidDocument=%s file='%s'",
                FORGE.Logger:safeToString(
                    writeSucceeded,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    invalidPathResult,
                    "false"
                ),
                FORGE.Logger:safeToString(
                    invalidDocumentResult,
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
            "XML Writer test harness failed unexpectedly: %s",
            FORGE.Logger:safeToString(
                errorMessage,
                "<unprintable error>"
            )
        )

        return false
    end

    return true
end
