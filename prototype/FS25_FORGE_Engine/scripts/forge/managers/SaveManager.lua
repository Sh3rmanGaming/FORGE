---=============================================================================
--- FORGE Save Manager
---
--- Coordinates persistence of FORGE runtime state.
---
--- Responsibilities:
---     • Register State Store namespaces for persistence.
---     • Coordinate savegame loading.
---     • Coordinate savegame writing.
---     • Validate persistence boundaries.
---     • Track and validate save format versions.
---
--- This service does not own runtime state or perform
--- XML serialization directly.
---=============================================================================

FORGE.SaveManager = {
    SAVE_VERSION = 1,
    FILE_NAME = "forge.xml"
}

-----------------------------------------------------------------------------
-- Private State
-----------------------------------------------------------------------------

local persistentNamespaces = {}

-----------------------------------------------------------------------------
-- Private Helpers
-----------------------------------------------------------------------------

local function isValidNamespace(namespace)
    return type(namespace) == "string"
        and string.match(namespace, "%S") ~= nil
end

local function hasPersistentNamespace(namespace)
    return persistentNamespaces[namespace] == true
end

local function isFiniteNumber(value)
    return value == value
        and value ~= math.huge
        and value ~= -math.huge
end

--- Creates a validated detached copy of one persistable value.
-- @param value any
-- @param visitedTables table|nil
-- @return boolean success
-- @return any copiedValue
local function copyPersistableValue(
    value,
    visitedTables
)
    local valueType = type(value)

    if valueType == "string"
        or valueType == "boolean" then
        return true, value
    end

    if valueType == "number" then
        if not isFiniteNumber(value) then
            return false, nil
        end

        return true, value
    end

    if valueType ~= "table" then
        return false, nil
    end

    visitedTables = visitedTables or {}

    if visitedTables[value] then
        return false, nil
    end

    visitedTables[value] = true

    local copiedValue = {}

    for key, nestedValue in pairs(value) do
        if type(key) ~= "string"
            or string.match(key, "%S") == nil then
            visitedTables[value] = nil

            return false, nil
        end

        local copied, copiedNestedValue =
            copyPersistableValue(
                nestedValue,
                visitedTables
            )

        if not copied then
            visitedTables[value] = nil

            return false, nil
        end

        copiedValue[key] =
            copiedNestedValue
    end

    visitedTables[value] = nil

    return true, copiedValue
end

--- Returns table keys in deterministic alphabetical order.
-- @param values table
-- @return table sortedKeys
local function getSortedKeys(values)
    local sortedKeys = {}

    for key in pairs(values) do
        table.insert(
            sortedKeys,
            key
        )
    end

    table.sort(sortedKeys)

    return sortedKeys
end

local function isValidSaveDirectory(saveDirectory)
    return type(saveDirectory) == "string"
        and string.match(saveDirectory, "%S") ~= nil
end

--- Builds the full FORGE persistence file path.
-- @param saveDirectory string
-- @param fileName string
-- @return string filePath
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

--- Returns whether a file exists without allowing engine errors to escape.
-- @param filePath string
-- @return boolean success
-- @return boolean exists
local function filePathExists(filePath)
    local callSucceeded, exists = pcall(
        fileExists,
        filePath
    )

    if not callSucceeded then
        return false, false
    end

    return true, exists == true
end

--- Builds a detached persistence document from registered namespaces.
-- @return boolean success
-- @return table|nil document
local function buildPersistenceDocument()
    local document = {
        version = FORGE.SaveManager.SAVE_VERSION,
        namespaces = {}
    }

    local sortedNamespaces =
        getSortedKeys(
            persistentNamespaces
        )

    for _, namespace in ipairs(sortedNamespaces) do
        local namespaceSnapshot, snapshotFound =
            FORGE.StateStore:snapshot(namespace)

        if not snapshotFound
            or type(namespaceSnapshot) ~= "table" then
            FORGE.Logger:error(
                FORGE.Definitions.LogSource.SAVE_MANAGER,
                "Persistent namespace '%s' no longer exists in the State Store",
                namespace
            )

            return false, nil
        end

        local copied, copiedNamespace =
            copyPersistableValue(
                namespaceSnapshot
            )

        if not copied then
            FORGE.Logger:error(
                FORGE.Definitions.LogSource.SAVE_MANAGER,
                "Persistent namespace '%s' contains unsupported, non-finite, or cyclic values",
                namespace
            )

            return false, nil
        end

        document.namespaces[namespace] =
            copiedNamespace
    end

    return true, document
end

--- Prepares registered namespaces from a decoded persistence document.
---
--- Saved namespaces that are not registered in the current runtime are
--- deliberately ignored.
-- @param document table
-- @return boolean success
-- @return table|nil preparedNamespaces
local function prepareLoadedNamespaces(
    document
)
    if type(document) ~= "table"
        or type(document.namespaces) ~= "table" then
        return false, nil
    end

    local preparedNamespaces = {}

    local sortedNamespaces =
        getSortedKeys(
            persistentNamespaces
        )

    for _, namespace in ipairs(sortedNamespaces) do
        local loadedValues =
            document.namespaces[namespace]

        if loadedValues ~= nil then
            if not FORGE.StateStore:exists(namespace) then
                FORGE.Logger:error(
                    FORGE.Definitions.LogSource.SAVE_MANAGER,
                    "Cannot load persistent namespace '%s' because it no longer exists in the State Store",
                    namespace
                )

                return false, nil
            end

            if type(loadedValues) ~= "table" then
                FORGE.Logger:error(
                    FORGE.Definitions.LogSource.SAVE_MANAGER,
                    "Loaded persistence namespace '%s' does not contain table state",
                    namespace
                )

                return false, nil
            end

            local copied, copiedValues =
                copyPersistableValue(
                    loadedValues
                )

            if not copied then
                FORGE.Logger:error(
                    FORGE.Definitions.LogSource.SAVE_MANAGER,
                    "Loaded persistence namespace '%s' contains unsupported, non-finite, or cyclic values",
                    namespace
                )

                return false, nil
            end

            preparedNamespaces[namespace] =
                copiedValues
        end
    end

    return true, preparedNamespaces
end

--- Applies prepared namespace state with rollback support.
-- @param preparedNamespaces table
-- @return boolean success
local function applyLoadedNamespaces(
    preparedNamespaces
)
    local sortedNamespaces =
        getSortedKeys(preparedNamespaces)

    local previousSnapshots = {}
    local appliedNamespaces = {}

    for _, namespace in ipairs(sortedNamespaces) do
        local previousSnapshot, snapshotFound =
            FORGE.StateStore:snapshot(namespace)

        if not snapshotFound then
            FORGE.Logger:error(
                FORGE.Definitions.LogSource.SAVE_MANAGER,
                "Cannot capture rollback state for namespace '%s'",
                namespace
            )

            return false
        end

        previousSnapshots[namespace] =
            previousSnapshot
    end

    for _, namespace in ipairs(sortedNamespaces) do
        local replaced =
            FORGE.StateStore:replaceNamespace(
                namespace,
                preparedNamespaces[namespace]
            )

        if not replaced then
            FORGE.Logger:error(
                FORGE.Definitions.LogSource.SAVE_MANAGER,
                "Unable to apply loaded persistence namespace '%s'",
                namespace
            )

            for index = #appliedNamespaces, 1, -1 do
                local appliedNamespace =
                    appliedNamespaces[index]

                local rollbackSucceeded =
                    FORGE.StateStore:replaceNamespace(
                        appliedNamespace,
                        previousSnapshots[
                            appliedNamespace
                        ]
                    )

                if not rollbackSucceeded then
                    FORGE.Logger:error(
                        FORGE.Definitions.LogSource.SAVE_MANAGER,
                        "Unable to roll back persistence namespace '%s'",
                        appliedNamespace
                    )
                end
            end

            return false
        end

        table.insert(
            appliedNamespaces,
            namespace
        )
    end

    return true
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

    return hasPersistentNamespace(namespace)
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

    if hasPersistentNamespace(namespace) then
        if FORGE.Logger:isDevelopmentMode() then
            FORGE.Logger:debug(
                FORGE.Definitions.LogSource.SAVE_MANAGER,
                "Persistence namespace '%s' is already registered",
                namespace
            )
        end

        return false
    end

    persistentNamespaces[namespace] = true

    return true
end

--- Removes all persistence namespace registrations.
-- @return integer clearedRegistrationCount
function FORGE.SaveManager:clearAllRegistrations()
    local clearedRegistrationCount = 0

    for _ in pairs(persistentNamespaces) do
        clearedRegistrationCount =
            clearedRegistrationCount + 1
    end

    persistentNamespaces = {}

    return clearedRegistrationCount
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

    if not hasPersistentNamespace(namespace) then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.SAVE_MANAGER,
            "Cannot validate unregistered persistence namespace '%s'",
            namespace
        )

        return false
    end

    local namespaceSnapshot, snapshotFound =
        FORGE.StateStore:snapshot(namespace)

    if not snapshotFound
        or type(namespaceSnapshot) ~= "table" then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.SAVE_MANAGER,
            "Persistent namespace '%s' no longer exists in the State Store",
            namespace
        )

        return false
    end

    local valid =
        select(
            1,
            copyPersistableValue(
                namespaceSnapshot
            )
        )

    if not valid then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.SAVE_MANAGER,
            "Persistent namespace '%s' contains unsupported, non-finite, or cyclic values",
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
    if not isValidSaveDirectory(saveDirectory) then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.SAVE_MANAGER,
            "Cannot save persistence using invalid save directory '%s'",
            FORGE.Logger:safeToString(
                saveDirectory,
                "<unprintable>"
            )
        )

        return false
    end

    local filePath =
        buildSaveFilePath(
            saveDirectory,
            self.FILE_NAME
        )

    local documentBuilt, document =
        buildPersistenceDocument()

    if not documentBuilt
        or document == nil then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.SAVE_MANAGER,
            "Unable to build persistence document for '%s'",
            filePath
        )

        return false
    end

    local writeSucceeded =
        FORGE.XMLWriter:write(
            filePath,
            document
        )

    if not writeSucceeded then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.SAVE_MANAGER,
            "Unable to write persistence document '%s'",
            filePath
        )

        return false
    end

    if FORGE.Logger:isDevelopmentMode() then
        FORGE.Logger:debug(
            FORGE.Definitions.LogSource.SAVE_MANAGER,
            "Saved FORGE persistence document '%s'",
            filePath
        )
    end

    return true
end

--- Loads registered persistent namespaces from the savegame.
-- @param saveDirectory any
-- @return boolean success
function FORGE.SaveManager:load(saveDirectory)
    if not isValidSaveDirectory(saveDirectory) then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.SAVE_MANAGER,
            "Cannot load persistence using invalid save directory '%s'",
            FORGE.Logger:safeToString(
                saveDirectory,
                "<unprintable>"
            )
        )

        return false
    end

    local filePath =
        buildSaveFilePath(
            saveDirectory,
            self.FILE_NAME
        )

    local existenceCheckSucceeded, exists =
        filePathExists(filePath)

    if not existenceCheckSucceeded then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.SAVE_MANAGER,
            "Unable to check for persistence document '%s'",
            filePath
        )

        return false
    end

    if not exists then
        if FORGE.Logger:isDevelopmentMode() then
            FORGE.Logger:debug(
                FORGE.Definitions.LogSource.SAVE_MANAGER,
                "No persistence document found at '%s'; current State Store values will be preserved",
                filePath
            )
        end

        return true
    end

    local readSucceeded, document =
        FORGE.XMLReader:read(filePath)

    if not readSucceeded
        or type(document) ~= "table" then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.SAVE_MANAGER,
            "Unable to read persistence document '%s'",
            filePath
        )

        return false
    end

    if type(document.version) ~= "number"
        or document.version ~= self.SAVE_VERSION then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.SAVE_MANAGER,
            "Unsupported persistence version '%s' in '%s'; expected version %d",
            FORGE.Logger:safeToString(
                document.version,
                "<missing>"
            ),
            filePath,
            self.SAVE_VERSION
        )

        return false
    end

    local prepared, preparedNamespaces =
        prepareLoadedNamespaces(
            document
        )

    if not prepared
        or preparedNamespaces == nil then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.SAVE_MANAGER,
            "Unable to prepare persistence document '%s' for loading",
            filePath
        )

        return false
    end

    if not applyLoadedNamespaces(
        preparedNamespaces
    ) then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.SAVE_MANAGER,
            "Unable to apply persistence document '%s'",
            filePath
        )

        return false
    end

    local value, found =
    FORGE.StateStore:get(
        "forge.engine",
        "firstRun"
    )

FORGE.Logger:info(
    FORGE.Definitions.LogSource.SAVE_MANAGER,
    "Post-load verification: value=%s found=%s type=%s",
    FORGE.Logger:safeToString(
        value,
        "<nil>"
    ),
    tostring(found),
    type(value)
)

    if FORGE.Logger:isDevelopmentMode() then
        FORGE.Logger:debug(
            FORGE.Definitions.LogSource.SAVE_MANAGER,
            "Loaded FORGE persistence document '%s'",
            filePath
        )
    end

    return true
end