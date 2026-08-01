---=============================================================================
--- FORGE Logger
---
--- Central logging service for the FORGE Engine.
---
--- Responsibilities:
---     • Debug logging
---     • Information logging
---     • Warning logging
---     • Error logging
---
--- This class should never contain gameplay logic.
---=============================================================================

FORGE.Logger = {}

FORGE.Logger.debugEnabled = true

--- Formats a FORGE log message.
-- @param level string Log level label.
-- @param source string System or module producing the message.
-- @param message string Message or format string.
-- @param ... any Optional format arguments.
-- @return string formattedMessage
function FORGE.Logger:format(level, source, message, ...)
    local sourceText = tostring(source or "Unknown")
    local messageText = tostring(message or "")

    if select("#", ...) > 0 then
        local success, formatted = pcall(string.format, messageText, ...)

        if success then
            messageText = formatted
        else
            messageText = string.format(
                "Log formatting failed for message '%s'",
                messageText
            )
        end
    end

    return string.format(
        "[FORGE][%s] %s: %s",
        sourceText,
        level,
        messageText
    )
end

--- Writes a debug message.
function FORGE.Logger:debug(message, ...)
    if not self.debugEnabled then
        return
    end

    print(self:format("DEBUG", message, ...))
end

--- Writes an informational message.
function FORGE.Logger:info(message, ...)
    print(self:format("INFO", message, ...))
end

--- Writes a warning message.
function FORGE.Logger:warning(message, ...)
    print(self:format("WARNING", message, ...))
end

--- Writes an error message.
function FORGE.Logger:error(message, ...)
    print(self:format("ERROR", message, ...))
end

--- Enables or disables debug logging.
-- @param enabled boolean
function FORGE.Logger:setDebugEnabled(enabled)
    self.debugEnabled = enabled == true
end

--- Returns whether debug logging is enabled.
-- @return boolean
function FORGE.Logger:isDebugEnabled()
    return self.debugEnabled
end