-- FORGE Engine
-- Farming Operations & Regional Growth Engine

ForgeEngine = {}
ForgeEngine.MOD_NAME = g_currentModName or "FS25_FORGE_Engine"
ForgeEngine.MOD_DIRECTORY = g_currentModDirectory or ""
ForgeEngine.VERSION = "0.4.1.0"
ForgeEngine.isMissionLoaded = false
ForgeEngine.mapName = nil

-- General mod event listeners do not receive saveToXMLFile callbacks.
-- Hook the mission save routine once so FORGE persistence runs with normal FS saves.
function ForgeEngine.onMissionSave(mission, ...)
    if ForgeEngine ~= nil and ForgeEngine.isMissionLoaded then
        ForgeLogger.info("Game save detected; writing FORGE persistence")
        ForgeSaveManager.save()
    end
end

function ForgeEngine.installSaveHook()
    if FSBaseMission == nil or Utils == nil or Utils.appendedFunction == nil then
        ForgeLogger.error("Unable to install save hook: FSBaseMission or Utils.appendedFunction unavailable")
        return false
    end

    if FSBaseMission.forgeSaveHookInstalled ~= true then
        FSBaseMission.saveSavegame = Utils.appendedFunction(FSBaseMission.saveSavegame, ForgeEngine.onMissionSave)
        FSBaseMission.forgeSaveHookInstalled = true
        ForgeLogger.info("Installed FSBaseMission save hook")
    else
        ForgeLogger.debug("FSBaseMission save hook already installed")
    end

    return true
end

function ForgeEngine:loadMap(mapName)
    self.mapName = mapName
    ForgeLogger.info("Loading FORGE Engine v%s on map '%s'", self.VERSION, tostring(mapName))

    ForgeEventBus.clear()
    ForgeModuleRegistry.clear()
    ForgeStateStore.clear()

    ForgeModuleRegistry.register("forge.engine", self, self.VERSION)
    ForgeStateStore.set("engine.version", self.VERSION, true)
    ForgeStateStore.set("engine.mapName", tostring(mapName), true)
    ForgeStateStore.set("engine.isServer", g_server ~= nil, true)

    ForgeCampaignManager:onMissionLoad()
    ForgePhoneOS:onMissionLoad()
    ForgeSaveManager.load()
    self.isMissionLoaded = true
    self.installSaveHook()

    ForgeEventBus.publish("forge.engine.ready", self)
    ForgeLogger.info(
        "FORGE ready: modules=%d session=%d authority=%s",
        ForgeModuleRegistry.getCount(),
        ForgeSaveManager.data.totalSessions,
        tostring(ForgeSaveManager.isAuthoritative())
    )
end

function ForgeEngine:deleteMap()
    ForgeLogger.info("Unloading FORGE Engine")
    ForgeEventBus.publish("forge.engine.shutdown", self)
    ForgePhoneOS:onMissionDelete()
    ForgeCampaignManager:onMissionDelete()
    ForgeSaveManager.unregisterOwner(self)
    self.isMissionLoaded = false
    self.mapName = nil
    ForgeModuleRegistry.clear()
    ForgeEventBus.clear()
    ForgeStateStore.clear()
end


function ForgeEngine:update(dt)
end

function ForgeEngine:draw()
    ForgePhoneOS:draw()
end

function ForgeEngine:keyEvent(unicode, sym, modifier, isDown)
    ForgePhoneOS:keyEvent(unicode, sym, modifier, isDown)
end

function ForgeEngine:mouseEvent(posX, posY, isDown, isUp, button)
    ForgePhoneOS:mouseEvent(posX, posY, isDown, isUp, button)
end

addModEventListener(ForgeEngine)
ForgeLogger.info("Lua sources loaded; waiting for mission lifecycle")
