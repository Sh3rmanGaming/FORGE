-- FORGE Engine - shared runtime state.
-- Server remains authoritative; network replication will be added later.

ForgeStateStore = {}
ForgeStateStore.values = {}

function ForgeStateStore.set(key, value, silent)
    if key == nil or key == "" then
        ForgeLogger.error("Cannot set state with an empty key")
        return false
    end

    local previousValue = ForgeStateStore.values[key]
    ForgeStateStore.values[key] = value

    if silent ~= true and previousValue ~= value then
        ForgeEventBus.publish("forge.state.changed", key, value, previousValue)
    end

    return true
end

function ForgeStateStore.get(key, defaultValue)
    local value = ForgeStateStore.values[key]
    if value == nil then
        return defaultValue
    end
    return value
end

function ForgeStateStore.has(key)
    return ForgeStateStore.values[key] ~= nil
end

function ForgeStateStore.remove(key)
    local previousValue = ForgeStateStore.values[key]
    ForgeStateStore.values[key] = nil
    if previousValue ~= nil then
        ForgeEventBus.publish("forge.state.changed", key, nil, previousValue)
    end
end

function ForgeStateStore.clear()
    ForgeStateStore.values = {}
end
