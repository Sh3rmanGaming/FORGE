-- FORGE Engine - central logging utility.

ForgeLogger = {}
ForgeLogger.PREFIX = "[FORGE]"
ForgeLogger.debugEnabled = true

local function formatMessage(message, ...)
    if select("#", ...) == 0 then
        return tostring(message)
    end

    local success, result = pcall(string.format, tostring(message), ...)
    if success then
        return result
    end

    return tostring(message)
end

function ForgeLogger.info(message, ...)
    print(string.format("%s INFO: %s", ForgeLogger.PREFIX, formatMessage(message, ...)))
end

function ForgeLogger.warning(message, ...)
    print(string.format("%s WARNING: %s", ForgeLogger.PREFIX, formatMessage(message, ...)))
end

function ForgeLogger.error(message, ...)
    print(string.format("%s ERROR: %s", ForgeLogger.PREFIX, formatMessage(message, ...)))
end

function ForgeLogger.debug(message, ...)
    if ForgeLogger.debugEnabled then
        print(string.format("%s DEBUG: %s", ForgeLogger.PREFIX, formatMessage(message, ...)))
    end
end
