---=============================================================================
--- FORGE Logging Service
---
--- Provides resilient, structured diagnostic logging for the FORGE Engine.
---
--- Responsibilities:
---     • Validate log levels and sources.
---     • Normalise recognised raw source values.
---     • Format log messages.
---     • Filter messages by configured severity.
---     • Write formatted messages to the active output.
---
--- The logger must never cause the engine to fail.
---=============================================================================

FORGE.Logger = {}

FORGE.Logger.Settings = {
    developmentMode = false,
    showTimestamp = false,
    minimumLevel = FORGE.Definitions.LogLevel.INFO
}

--- Writes a formatted log message to the active output.
-- @param formattedMessage string
function FORGE.Logger:write(formattedMessage)
    print(tostring(formattedMessage or ""))
end

--- Returns the current real-world time formatted for log output.
-- @return string timestamp
function FORGE.Logger:getTimestamp()
    if os ~= nil and os.date ~= nil then
        local success, timestamp = pcall(
            os.date,
            "%H:%M:%S"
        )

        if success and timestamp ~= nil then
            return tostring(timestamp)
        end
    end

    return "--:--:--"
end

--- Formats a log entry for output.
-- @param level table Normalised log-level definition.
-- @param source string Normalised log source.
-- @param message any Message or format string.
-- @param ... any Optional format arguments.
-- @return string formattedMessage
function FORGE.Logger:format(level, source, message, ...)
    local levelLabel = tostring(level.label or "INFO")
    local sourceText = tostring(source or FORGE.Definitions.LogSource.UNKNOWN)
    local messageText = tostring(message or "")

    if select("#", ...) > 0 then
        local success, formattedMessage = pcall(
            string.format,
            messageText,
            ...
        )

        if success then
            messageText = formattedMessage
        else
            messageText = string.format(
                "Log formatting failed for message '%s'",
                messageText
            )
        end
    end

    local prefix = string.format(
        "[FORGE][%s][%s]",
        sourceText,
        levelLabel
    )

    if self.Settings.showTimestamp then
        prefix = string.format(
            "[%s]%s",
            self:getTimestamp(),
            prefix
        )
    end

    return string.format("%s %s", prefix, messageText)
end

--- Validates and normalises a log source.
-- @param source any
-- @return string normalisedSource
-- @return boolean wasNormalised
function FORGE.Logger:normaliseSource(source)
    local LogSource = FORGE.Definitions.LogSource

    if source == nil then
        return LogSource.UNKNOWN, true
    end

    local sourceText = tostring(source)
    local sourceLower = string.lower(sourceText)

    for _, definedSource in pairs(LogSource) do
        if string.lower(tostring(definedSource)) == sourceLower then
            return definedSource, definedSource ~= sourceText
        end
    end

    return LogSource.UNKNOWN, true
end

--- Validates and normalises a log level.
-- @param level any
-- @return table normalisedLevel
-- @return boolean wasNormalised
-- @return boolean isValid
function FORGE.Logger:normaliseLevel(level)
    local LogLevel = FORGE.Definitions.LogLevel

    for _, definedLevel in pairs(LogLevel) do
        if level == definedLevel then
            return definedLevel, false, true
        end
    end

    if type(level) == "string" then
        local levelUpper = string.upper(level)

        for definitionName, definedLevel in pairs(LogLevel) do
            if definitionName == levelUpper
                or string.upper(definedLevel.label) == levelUpper then
                return definedLevel, true, true
            end
        end
    end

    return LogLevel.INFO, true, false
end

--- Returns whether a log level passes the configured severity filter.
-- @param level table
-- @return boolean shouldWrite
function FORGE.Logger:shouldWrite(level)
    local minimumLevel = self.Settings.minimumLevel
        or FORGE.Definitions.LogLevel.INFO

    return level.severity >= minimumLevel.severity
end

--- Writes an internal logger diagnostic without recursively calling log().
-- @param message string
-- @param ... any
function FORGE.Logger:writeInternalWarning(message, ...)
    if not self.Settings.developmentMode then
        return
    end

    local formattedMessage = self:format(
        FORGE.Definitions.LogLevel.WARNING,
        FORGE.Definitions.LogSource.LOGGER,
        message,
        ...
    )

    self:write(formattedMessage)
end

--- Writes a log entry.
-- @param level any
-- @param source any
-- @param message any
-- @param ... any Optional format arguments.
function FORGE.Logger:log(level, source, message, ...)
    local normalisedLevel, levelWasNormalised =
        self:normaliseLevel(level)

    local normalisedSource, sourceWasNormalised =
        self:normaliseSource(source)

    if levelWasNormalised then
        self:writeInternalWarning(
            "Normalised an invalid or raw log level to '%s'",
            normalisedLevel.label
        )
    end

    if sourceWasNormalised then
        self:writeInternalWarning(
            "Normalised log source '%s' to '%s'; use an authoritative LogSource definition",
            tostring(source),
            normalisedSource
        )
    end

    if not self:shouldWrite(normalisedLevel) then
        return
    end

    local formattedMessage = self:format(
        normalisedLevel,
        normalisedSource,
        message,
        ...
    )

    self:write(formattedMessage)
end

--- Writes a trace-level message.
function FORGE.Logger:trace(source, message, ...)
    self:log(
        FORGE.Definitions.LogLevel.TRACE,
        source,
        message,
        ...
    )
end

--- Writes a debug-level message.
function FORGE.Logger:debug(source, message, ...)
    self:log(
        FORGE.Definitions.LogLevel.DEBUG,
        source,
        message,
        ...
    )
end

--- Writes an informational message.
function FORGE.Logger:info(source, message, ...)
    self:log(
        FORGE.Definitions.LogLevel.INFO,
        source,
        message,
        ...
    )
end

--- Writes a warning message.
function FORGE.Logger:warning(source, message, ...)
    self:log(
        FORGE.Definitions.LogLevel.WARNING,
        source,
        message,
        ...
    )
end

--- Writes an error message.
function FORGE.Logger:error(source, message, ...)
    self:log(
        FORGE.Definitions.LogLevel.ERROR,
        source,
        message,
        ...
    )
end

--- Writes a fatal-level message.
-- Fatal logging does not terminate FORGE by itself.
function FORGE.Logger:fatal(source, message, ...)
    self:log(
        FORGE.Definitions.LogLevel.FATAL,
        source,
        message,
        ...
    )
end

--- Enables or disables development diagnostics.
-- @param enabled boolean
function FORGE.Logger:setDevelopmentMode(enabled)
    self.Settings.developmentMode = enabled == true
end

--- Returns whether development diagnostics are enabled.
-- @return boolean
function FORGE.Logger:isDevelopmentMode()
    return self.Settings.developmentMode
end

--- Enables or disables timestamps in FORGE log prefixes.
-- @param enabled boolean
function FORGE.Logger:setTimestampEnabled(enabled)
    self.Settings.showTimestamp = enabled == true
end

--- Returns whether timestamps are enabled.
-- @return boolean
function FORGE.Logger:isTimestampEnabled()
    return self.Settings.showTimestamp
end

--- Sets the minimum severity that will be written.
-- @param level any
-- @return boolean success
function FORGE.Logger:setMinimumLevel(level)
    local normalisedLevel, _, isValid =
        self:normaliseLevel(level)

    if not isValid then
        self:writeInternalWarning(
            "Rejected invalid minimum log level '%s'",
            tostring(level)
        )

        return false
    end

    self.Settings.minimumLevel = normalisedLevel
    return true
end

--- Returns the configured minimum log level.
-- @return table minimumLevel
function FORGE.Logger:getMinimumLevel()
    return self.Settings.minimumLevel
end