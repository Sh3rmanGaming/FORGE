---=============================================================================
--- FORGE Event Bus
---
--- Allows FORGE systems to communicate without directly depending on each other.
---
--- Responsibilities:
---     • Register event listeners.
---     • Publish events.
---     • Remove listeners.
---     • Clear listeners during shutdown.
---
--- This service must never contain gameplay logic.
---=============================================================================

FORGE.EventBus = {
    listeners = {}
}

--- Returns whether an event name is valid.
-- @param eventName any
-- @return boolean isValid
function FORGE.EventBus:isValidEventName(eventName)
    return type(eventName) == "string"
        and string.match(eventName, "%S") ~= nil
end

--- Returns whether a listener and callback are already subscribed.
-- @param eventName string
-- @param listener any
-- @param callback function
-- @return boolean isDuplicate
function FORGE.EventBus:isDuplicateSubscription(
    eventName,
    listener,
    callback
)
    local eventListeners = self.listeners[eventName]

    if eventListeners == nil then
        return false
    end

    for _, subscription in ipairs(eventListeners) do
        if subscription.listener == listener
            and subscription.callback == callback then
            return true
        end
    end

    return false
end

--- Registers a listener callback for an event.
-- @param eventName any
-- @param listener any
-- @param callback any
-- @return boolean success
function FORGE.EventBus:subscribe(
    eventName,
    listener,
    callback
)
    if not self:isValidEventName(eventName) then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.EVENT_BUS,
            "Cannot subscribe using invalid event name '%s'",
            FORGE.Logger:safeToString(eventName, "<unprintable>")
        )

        return false
    end

    if listener == nil then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.EVENT_BUS,
            "Cannot subscribe nil listener to event '%s'",
            eventName
        )

        return false
    end

    if type(callback) ~= "function" then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.EVENT_BUS,
            "Cannot subscribe invalid callback to event '%s'",
            eventName
        )

        return false
    end

    if self:isDuplicateSubscription(
        eventName,
        listener,
        callback
    ) then
        FORGE.Logger:warning(
            FORGE.Definitions.LogSource.EVENT_BUS,
            "Duplicate subscription rejected for event '%s'",
            eventName
        )

        return false
    end

    self.listeners[eventName] =
        self.listeners[eventName] or {}

    table.insert(
        self.listeners[eventName],
        {
            listener = listener,
            callback = callback
        }
    )

    return true
end

--- Removes one listener callback from an event.
-- @param eventName any
-- @param listener any
-- @param callback any
-- @return boolean removed
function FORGE.EventBus:unsubscribe(
    eventName,
    listener,
    callback
)
    if not self:isValidEventName(eventName) then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.EVENT_BUS,
            "Cannot unsubscribe using invalid event name '%s'",
            FORGE.Logger:safeToString(eventName, "<unprintable>")
        )

        return false
    end

    if listener == nil then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.EVENT_BUS,
            "Cannot unsubscribe nil listener from event '%s'",
            eventName
        )

        return false
    end

    if type(callback) ~= "function" then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.EVENT_BUS,
            "Cannot unsubscribe invalid callback from event '%s'",
            eventName
        )

        return false
    end

    local eventListeners = self.listeners[eventName]

    if eventListeners == nil then
        return false
    end

    for index = #eventListeners, 1, -1 do
        local subscription = eventListeners[index]

        if subscription.listener == listener
            and subscription.callback == callback then
            table.remove(eventListeners, index)

            if #eventListeners == 0 then
                self.listeners[eventName] = nil
            end

            return true
        end
    end

    return false
end

--- Publishes an event to all listeners registered at publication start.
-- @param eventName any
-- @param ... any Event arguments.
-- @return table result Publication metrics.
function FORGE.EventBus:publish(eventName, ...)
    local result = {
        called = 0,
        succeeded = 0,
        failed = 0
    }

    if not self:isValidEventName(eventName) then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.EVENT_BUS,
            "Cannot publish invalid event name '%s'",
            FORGE.Logger:safeToString(eventName, "<unprintable>")
        )

        return result
    end

    local eventListeners = self.listeners[eventName]

    if eventListeners == nil or #eventListeners == 0 then
        if FORGE.Logger:isDevelopmentMode() then
            FORGE.Logger:debug(
                FORGE.Definitions.LogSource.EVENT_BUS,
                "Event '%s' published with no listeners",
                eventName
            )
        end

        return result
    end

    local snapshot = {}

    for index, subscription in ipairs(eventListeners) do
        snapshot[index] = subscription
    end

    for _, subscription in ipairs(snapshot) do
        result.called = result.called + 1

        local success, errorMessage = pcall(
            subscription.callback,
            subscription.listener,
            ...
        )

        if success then
            result.succeeded = result.succeeded + 1
        else
            result.failed = result.failed + 1

            if FORGE.Logger:isDevelopmentMode() then
                FORGE.Logger:error(
                    FORGE.Definitions.LogSource.EVENT_BUS,
                    "Listener '%s' failed while handling event '%s': %s",
                    FORGE.Logger:safeToString(
                        subscription.listener,
                        "<unprintable listener>"
                    ),
                    eventName,
                    FORGE.Logger:safeToString(
                        errorMessage,
                        "<unprintable error>"
                    )
                )
            end
        end
    end

    if result.failed > 0 then
        FORGE.Logger:warning(
            FORGE.Definitions.LogSource.EVENT_BUS,
            "Event '%s' completed: %d called, %d succeeded, %d failed",
            eventName,
            result.called,
            result.succeeded,
            result.failed
        )
    end

    return result
end

--- Removes all listeners registered for one event.
-- @param eventName any
-- @return boolean cleared
function FORGE.EventBus:clear(eventName)
    if not self:isValidEventName(eventName) then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.EVENT_BUS,
            "Cannot clear invalid event name '%s'",
            FORGE.Logger:safeToString(eventName, "<unprintable>")
        )

        return false
    end

    if self.listeners[eventName] == nil then
        return false
    end

    self.listeners[eventName] = nil
    return true
end

--- Removes every listener from the Event Bus.
-- @return integer clearedEventCount
function FORGE.EventBus:clearAll()
    local clearedEventCount = 0

    for _ in pairs(self.listeners) do
        clearedEventCount = clearedEventCount + 1
    end

    self.listeners = {}

    return clearedEventCount
end