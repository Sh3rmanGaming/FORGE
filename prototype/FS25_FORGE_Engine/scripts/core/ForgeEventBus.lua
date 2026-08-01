-- FORGE Engine - lightweight internal event bus.
-- Modules use this to communicate without direct dependencies.

ForgeEventBus = {}
ForgeEventBus.listeners = {}

function ForgeEventBus.subscribe(eventName, owner, callback)
    if eventName == nil or eventName == "" then
        ForgeLogger.error("Cannot subscribe to an unnamed event")
        return false
    end

    if owner == nil or callback == nil then
        ForgeLogger.error("Cannot subscribe to '%s': owner or callback is nil", tostring(eventName))
        return false
    end

    if ForgeEventBus.listeners[eventName] == nil then
        ForgeEventBus.listeners[eventName] = {}
    end

    table.insert(ForgeEventBus.listeners[eventName], {
        owner = owner,
        callback = callback
    })

    return true
end

function ForgeEventBus.unsubscribeOwner(owner)
    if owner == nil then
        return
    end

    for eventName, listeners in pairs(ForgeEventBus.listeners) do
        local retained = {}
        for _, listener in ipairs(listeners) do
            if listener.owner ~= owner then
                table.insert(retained, listener)
            end
        end
        ForgeEventBus.listeners[eventName] = retained
    end
end

function ForgeEventBus.publish(eventName, ...)
    local listeners = ForgeEventBus.listeners[eventName]
    if listeners == nil then
        return 0
    end

    local called = 0
    for _, listener in ipairs(listeners) do
        local success, err = pcall(listener.callback, listener.owner, ...)
        if success then
            called = called + 1
        else
            ForgeLogger.error("Listener failed for event '%s': %s", tostring(eventName), tostring(err))
        end
    end

    return called
end

function ForgeEventBus.clear()
    ForgeEventBus.listeners = {}
end
