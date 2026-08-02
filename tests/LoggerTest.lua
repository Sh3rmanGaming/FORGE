---=============================================================================
--- FORGE Logger Tests
---
--- Manual test harness for the FORGE Logging Service.
---
--- Responsibilities:
---     • Verify all supported log levels.
---     • Verify formatted log messages.
---     • Verify source normalisation.
---     • Verify missing-source fallback.
---     • Verify formatting failure handling.
---     • Verify logger setting restoration.
---
--- This file must restore all shared state changed during testing.
---=============================================================================

FORGE.Tests = FORGE.Tests or {}

function FORGE.Tests.runLoggerTests()
    local previousDevelopmentMode =
        FORGE.Logger:isDevelopmentMode()

    local previousTimestampSetting =
        FORGE.Logger:isTimestampEnabled()

    local previousMinimumLevel =
        FORGE.Logger:getMinimumLevel()

    local success, errorMessage = pcall(
        function()
            FORGE.Logger:setDevelopmentMode(true)
            FORGE.Logger:setTimestampEnabled(true)

            FORGE.Logger:setMinimumLevel(
                FORGE.Definitions.LogLevel.TRACE
            )

            FORGE.Logger:trace(
                FORGE.Definitions.LogSource.TEST,
                "Trace message"
            )

            FORGE.Logger:debug(
                FORGE.Definitions.LogSource.TEST,
                "Debug message"
            )

            FORGE.Logger:info(
                FORGE.Definitions.LogSource.TEST,
                "Info message with value %d",
                42
            )

            FORGE.Logger:warning(
                "test",
                "Raw lowercase source should be normalised"
            )

            FORGE.Logger:error(
                nil,
                "Missing source should fall back to Unknown"
            )

            FORGE.Logger:fatal(
                FORGE.Definitions.LogSource.TEST,
                "Fatal message"
            )

            FORGE.Logger:info(
                FORGE.Definitions.LogSource.TEST,
                "Formatting failure: %d",
                "not-a-number"
            )
        end
    )

    FORGE.Logger:setDevelopmentMode(
        previousDevelopmentMode
    )

    FORGE.Logger:setTimestampEnabled(
        previousTimestampSetting
    )

    FORGE.Logger:setMinimumLevel(
        previousMinimumLevel
    )

    if not success then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.TEST,
            "Logger test harness failed unexpectedly: %s",
            FORGE.Logger:safeToString(
                errorMessage,
                "<unprintable error>"
            )
        )

        return false
    end

    return true
end