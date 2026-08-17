---=============================================================================
--- FORGE Communications
---
--- Coordinates the bounded Communications domain lifecycle and facade.
--- Registers the built-in application through its dedicated adapter.
---=============================================================================

FORGE.Communications = {}

local Communications = FORGE.Communications
local Result = FORGE.Definitions.CommunicationsResult

function Communications:start()
    local call = {
        pcall(FORGE.CommunicationsPersistence.registerNamespace,
            FORGE.CommunicationsPersistence)
    }
    if not call[1] or call[2] ~= true then
        if not call[1] then
            FORGE.Logger:error("Communications",
                "Unexpected Communications startup failure: %s",
                FORGE.Logger:safeToString(call[2], "<unprintable error>"))
        end
        return Result.STATE_ERROR
    end

    FORGE.CommunicationsService:setAvailable(false)
    return Result.SUCCESS
end

function Communications:completeRestoration()
    local call = {
        pcall(FORGE.CommunicationsPersistence.restore,
            FORGE.CommunicationsPersistence)
    }
    if not call[1] or call[2] ~= true then
        FORGE.CommunicationsService:setAvailable(false)
        if not call[1] then
            FORGE.Logger:error("Communications",
                "Unexpected Communications restoration failure: %s",
                FORGE.Logger:safeToString(call[2], "<unprintable error>"))
        end
        return Result.STATE_ERROR
    end

    FORGE.CommunicationsService:setAvailable(true)
    return Result.SUCCESS
end

function Communications:registerApplication()
    return FORGE.CommunicationsApp:register()
end

function Communications:shutdown()
    FORGE.CommunicationsService:clearRuntimeState()
    return Result.SUCCESS
end

function Communications:createMessage(definition)
    return FORGE.CommunicationsService:createMessage(definition)
end

function Communications:markMessageRead(messageId)
    return FORGE.CommunicationsService:markMessageRead(messageId)
end

function Communications:archiveMessage(messageId)
    return FORGE.CommunicationsService:archiveMessage(messageId)
end

function Communications:getMessage(messageId)
    return FORGE.CommunicationsService:getMessage(messageId)
end

function Communications:getMessages(includeArchived)
    return FORGE.CommunicationsService:getMessages(includeArchived)
end

function Communications:getUnreadCount()
    return FORGE.CommunicationsService:getUnreadCount()
end
