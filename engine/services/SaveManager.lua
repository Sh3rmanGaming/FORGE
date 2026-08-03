---=============================================================================
--- FORGE Save Manager
---
--- Coordinates persistence of approved FORGE runtime state.
---
--- Responsibilities:
---     • Register State Store namespaces for persistence.
---     • Load persistent FORGE state from the active savegame.
---     • Write persistent FORGE state into the active savegame.
---     • Track and validate the FORGE save format version.
---
--- This service must not own gameplay state or gameplay rules.
---=============================================================================

FORGE.SaveManager = {
    SAVE_VERSION = 1,
    ROOT_KEY = "forge",
    FILE_NAME = "forge.xml",
    persistentNamespaces = {}
}

-----------------------------------------------------------------------------
-- Private Helpers
-----------------------------------------------------------------------------

local function isValidNamespace(namespace)
    return type(namespace) == "string"
        and string.match(namespace, "%S") ~= nil
end

local function hasPersistentNamespace(
    persistentNamespaces,
    namespace
)
    return persistentNamespaces[namespace] == true
end

local function isFiniteNumber(value)
    return value == value
        and value ~= math.huge
        and value ~= -math.huge
end

local function isPersistableValue(
    value,
    visitedTables
)
    local valueType = type(value)

    if valueType == "string"
        or valueType == "boolean" then
        return true
    end

    if valueType == "number" then
        return isFiniteNumber(value)
    end

    if valueType ~= "table" then
        return false
    end

    visitedTables = visitedTables or {}

    if visitedTables[value] then
        return false
    end

    visitedTables[value] = true

    for key, nestedValue in pairs(value) do
        if type(key) ~= "string"
            or string.match(key, "%S") == nil
            or not isPersistableValue(
                nestedValue,
                visitedTables
            ) then
            visitedTables[value] = nil
            return false
        end
    end

    visitedTables[value] = nil
    return true
end

--- Returns table keys in deterministic alphabetical order.
-- @param values table
-- @return table sortedKeys
local function getSortedKeys(values)
    local sortedKeys = {}

    for key in pairs(values) do
        table.insert(sortedKeys, key)
    end

    table.sort(sortedKeys)

    return sortedKeys
end

local function isValidSaveDirectory(saveDirectory)
    return type(saveDirectory) == "string"
        and string.match(saveDirectory, "%S") ~= nil
end

local function buildSaveFilePath(
    saveDirectory,
    fileName
)
    local separator = "/"

    if string.sub(saveDirectory, -1) == "/"
        or string.sub(saveDirectory, -1) == "\\" then
        separator = ""
    end

    return saveDirectory
        .. separator
        .. fileName
end

-----------------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------------

--- Returns whether a namespace is registered for persistence.
-- @param namespace any
-- @return boolean registered
function FORGE.SaveManager:isNamespaceRegistered(namespace)
    if not isValidNamespace(namespace) then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.SAVE_MANAGER,
            "Invalid persistence namespace '%s'",
            FORGE.Logger:safeToString(
                namespace,
                "<unprintable>"
            )
        )

        return false
    end

    return hasPersistentNamespace(
        self.persistentNamespaces,
        namespace
    )
end

--- Registers an existing State Store namespace for persistence.
-- @param namespace any
-- @return boolean registered
function FORGE.SaveManager:registerNamespace(namespace)
    if not isValidNamespace(namespace) then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.SAVE_MANAGER,
            "Cannot register invalid persistence namespace '%s'",
            FORGE.Logger:safeToString(
                namespace,
                "<unprintable>"
            )
        )

        return false
    end

    if not FORGE.StateStore:exists(namespace) then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.SAVE_MANAGER,
            "Cannot register unknown State Store namespace '%s' for persistence",
            namespace
        )

        return false
    end

    if hasPersistentNamespace(
        self.persistentNamespaces,
        namespace
    ) then
        if FORGE.Logger:isDevelopmentMode() then
            FORGE.Logger:debug(
                FORGE.Definitions.LogSource.SAVE_MANAGER,
                "Persistence namespace '%s' is already registered",
                namespace
            )
        end

        return false
    end

    self.persistentNamespaces[namespace] = true

    return true
end

--- Returns whether a persistent namespace contains only supported values.
-- @param namespace any
-- @return boolean valid
function FORGE.SaveManager:validateNamespace(namespace)
    if not isValidNamespace(namespace) then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.SAVE_MANAGER,
            "Cannot validate invalid persistence namespace '%s'",
            FORGE.Logger:safeToString(
                namespace,
                "<unprintable>"
            )
        )

        return false
    end

    if not hasPersistentNamespace(
        self.persistentNamespaces,
        namespace
    ) then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.SAVE_MANAGER,
            "Cannot validate unregistered persistence namespace '%s'",
            namespace
        )

        return false
    end

    local namespaceValues =
        FORGE.StateStore.namespaces[namespace]

    if namespaceValues == nil then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.SAVE_MANAGER,
            "Persistent namespace '%s' no longer exists in the State Store",
            namespace
        )

        return false
    end

    if not isPersistableValue(namespaceValues) then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.SAVE_MANAGER,
            "Persistent namespace '%s' contains unsupported or cyclic values",
            namespace
        )

        return false
    end

    return true
end

--- Writes all registered persistent namespaces into the savegame.
-- @param saveDirectory any
-- @return boolean success
function FORGE.SaveManager:save(saveDirectory)

end

--- Loads registered persistent namespaces from the savegame.
-- @param saveDirectory any
-- @return boolean success
function FORGE.SaveManager:load(saveDirectory)

end