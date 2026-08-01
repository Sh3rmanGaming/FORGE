-- FORGE Engine - savegame-embedded persistence.

ForgeSaveManager = {}
ForgeSaveManager.FILE_NAME = "forge.xml"
ForgeSaveManager.ROOT_KEY = "forge"
ForgeSaveManager.SCHEMA_VERSION = 1
ForgeSaveManager.sections = {}

ForgeSaveManager.data = {
    schemaVersion = ForgeSaveManager.SCHEMA_VERSION,
    totalSessions = 0,
    lastLoadedVersion = "unknown"
}

local function getSavegameDirectory()
    if g_currentMission == nil or g_currentMission.missionInfo == nil then
        return nil
    end
    return g_currentMission.missionInfo.savegameDirectory
end

function ForgeSaveManager.getFilePath()
    local directory = getSavegameDirectory()
    if directory == nil or directory == "" then
        return nil
    end
    return directory .. "/" .. ForgeSaveManager.FILE_NAME
end

function ForgeSaveManager.isAuthoritative()
    -- In single-player g_server exists. On dedicated multiplayer only the server writes.
    return g_server ~= nil
end

function ForgeSaveManager.registerSection(sectionId, owner, loadCallback, saveCallback)
    if sectionId == nil or sectionId == "" or owner == nil then
        ForgeLogger.error("Invalid save section registration")
        return false
    end

    ForgeSaveManager.sections[sectionId] = {
        owner = owner,
        loadCallback = loadCallback,
        saveCallback = saveCallback
    }
    ForgeLogger.debug("Registered save section '%s'", tostring(sectionId))
    return true
end

function ForgeSaveManager.unregisterOwner(owner)
    for sectionId, section in pairs(ForgeSaveManager.sections) do
        if section.owner == owner then
            ForgeSaveManager.sections[sectionId] = nil
        end
    end
end

function ForgeSaveManager.resetToDefaults()
    ForgeSaveManager.data = {
        schemaVersion = ForgeSaveManager.SCHEMA_VERSION,
        totalSessions = 0,
        lastLoadedVersion = ForgeEngine ~= nil and ForgeEngine.VERSION or "unknown"
    }
end

function ForgeSaveManager.load()
    ForgeSaveManager.resetToDefaults()

    if not ForgeSaveManager.isAuthoritative() then
        ForgeLogger.info("Client session detected; waiting for future FORGE network synchronisation")
        return true
    end

    local filePath = ForgeSaveManager.getFilePath()
    if filePath == nil then
        ForgeLogger.warning("No savegame directory is available; persistence is disabled")
        return false
    end

    if fileExists ~= nil and not fileExists(filePath) then
        ForgeSaveManager.data.totalSessions = 1
        ForgeLogger.info("No existing forge.xml found; starting session 1")
        return true
    end

    if XMLFile == nil then
        ForgeLogger.error("GIANTS XMLFile API is unavailable")
        return false
    end

    local xmlFile = XMLFile.load("forgeSaveXML", filePath, ForgeSaveManager.ROOT_KEY)
    if xmlFile == nil then
        ForgeSaveManager.data.totalSessions = 1
        ForgeLogger.warning("Could not read '%s'; defaults will be used", tostring(filePath))
        return false
    end

    ForgeSaveManager.data.schemaVersion = xmlFile:getInt(ForgeSaveManager.ROOT_KEY .. "#schemaVersion", ForgeSaveManager.SCHEMA_VERSION)
    ForgeSaveManager.data.totalSessions = xmlFile:getInt(ForgeSaveManager.ROOT_KEY .. ".runtime#totalSessions", 0) + 1
    ForgeSaveManager.data.lastLoadedVersion = xmlFile:getString(ForgeSaveManager.ROOT_KEY .. ".runtime#lastLoadedVersion", "unknown")

    for sectionId, section in pairs(ForgeSaveManager.sections) do
        if section.loadCallback ~= nil then
            local success, err = pcall(section.loadCallback, section.owner, xmlFile, ForgeSaveManager.ROOT_KEY .. ".sections." .. sectionId)
            if not success then
                ForgeLogger.error("Failed loading section '%s': %s", tostring(sectionId), tostring(err))
            end
        end
    end

    xmlFile:delete()
    ForgeLogger.info("Loaded forge.xml: schema=%d session=%d", ForgeSaveManager.data.schemaVersion, ForgeSaveManager.data.totalSessions)
    return true
end

function ForgeSaveManager.save()
    if not ForgeSaveManager.isAuthoritative() then
        return true
    end

    local filePath = ForgeSaveManager.getFilePath()
    if filePath == nil then
        ForgeLogger.warning("Cannot save FORGE data because no savegame directory is available")
        return false
    end

    if XMLFile == nil then
        ForgeLogger.error("GIANTS XMLFile API is unavailable")
        return false
    end

    local xmlFile = XMLFile.create("forgeSaveXML", filePath, ForgeSaveManager.ROOT_KEY)
    if xmlFile == nil then
        ForgeLogger.error("Could not create '%s'", tostring(filePath))
        return false
    end

    xmlFile:setInt(ForgeSaveManager.ROOT_KEY .. "#schemaVersion", ForgeSaveManager.SCHEMA_VERSION)
    xmlFile:setString(ForgeSaveManager.ROOT_KEY .. "#engineVersion", ForgeEngine ~= nil and ForgeEngine.VERSION or "unknown")
    xmlFile:setInt(ForgeSaveManager.ROOT_KEY .. ".runtime#totalSessions", ForgeSaveManager.data.totalSessions)
    xmlFile:setString(ForgeSaveManager.ROOT_KEY .. ".runtime#lastLoadedVersion", ForgeEngine ~= nil and ForgeEngine.VERSION or "unknown")

    if g_currentMission ~= nil and g_currentMission.environment ~= nil then
        xmlFile:setInt(ForgeSaveManager.ROOT_KEY .. ".runtime#currentDay", g_currentMission.environment.currentDay or 0)
        xmlFile:setInt(ForgeSaveManager.ROOT_KEY .. ".runtime#dayTime", g_currentMission.environment.dayTime or 0)
    end

    for sectionId, section in pairs(ForgeSaveManager.sections) do
        if section.saveCallback ~= nil then
            local success, err = pcall(section.saveCallback, section.owner, xmlFile, ForgeSaveManager.ROOT_KEY .. ".sections." .. sectionId)
            if not success then
                ForgeLogger.error("Failed saving section '%s': %s", tostring(sectionId), tostring(err))
            end
        end
    end

    xmlFile:save()
    xmlFile:delete()
    ForgeLogger.info("Saved FORGE data to '%s'", tostring(filePath))
    ForgeEventBus.publish("forge.save.completed", filePath)
    return true
end
