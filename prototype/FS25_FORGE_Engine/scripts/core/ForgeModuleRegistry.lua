-- FORGE Engine - registry for optional FORGE modules.

ForgeModuleRegistry = {}
ForgeModuleRegistry.modules = {}
ForgeModuleRegistry.order = {}

function ForgeModuleRegistry.register(moduleId, moduleInstance, version)
    if moduleId == nil or moduleId == "" then
        ForgeLogger.error("Cannot register a module without a module ID")
        return false
    end

    if moduleInstance == nil then
        ForgeLogger.error("Cannot register module '%s': instance is nil", tostring(moduleId))
        return false
    end

    if ForgeModuleRegistry.modules[moduleId] == nil then
        table.insert(ForgeModuleRegistry.order, moduleId)
    else
        ForgeLogger.warning("Replacing already registered module '%s'", tostring(moduleId))
    end

    ForgeModuleRegistry.modules[moduleId] = {
        id = moduleId,
        instance = moduleInstance,
        version = version or "unknown"
    }

    ForgeLogger.info("Registered module '%s' v%s", tostring(moduleId), tostring(version or "unknown"))
    ForgeEventBus.publish("forge.module.registered", moduleId, moduleInstance, version)
    return true
end

function ForgeModuleRegistry.unregister(moduleId)
    local module = ForgeModuleRegistry.modules[moduleId]
    if module == nil then
        return false
    end

    ForgeEventBus.unsubscribeOwner(module.instance)
    ForgeModuleRegistry.modules[moduleId] = nil

    local retained = {}
    for _, registeredId in ipairs(ForgeModuleRegistry.order) do
        if registeredId ~= moduleId then
            table.insert(retained, registeredId)
        end
    end
    ForgeModuleRegistry.order = retained

    ForgeLogger.info("Unregistered module '%s'", tostring(moduleId))
    return true
end

function ForgeModuleRegistry.get(moduleId)
    local module = ForgeModuleRegistry.modules[moduleId]
    return module ~= nil and module.instance or nil
end

function ForgeModuleRegistry.has(moduleId)
    return ForgeModuleRegistry.modules[moduleId] ~= nil
end

function ForgeModuleRegistry.getCount()
    return #ForgeModuleRegistry.order
end

function ForgeModuleRegistry.clear()
    ForgeModuleRegistry.modules = {}
    ForgeModuleRegistry.order = {}
end
