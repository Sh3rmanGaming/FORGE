---=============================================================================
--- FORGE State Store
---
--- Owns and organises shared FORGE runtime state.
---
--- Responsibilities:
---     • Register explicit state namespaces.
---     • Store runtime state within registered namespaces.
---     • Provide controlled access to runtime state.
---     • Produce detached namespace snapshots.
---     • Replace namespace state atomically.
---     • Remove and reset runtime state.
---
--- This service must not perform persistence, networking, or gameplay validation.
---=============================================================================

FORGE.StateStore = {}

-----------------------------------------------------------------------------
-- Private State
-----------------------------------------------------------------------------

local namespaces = {}

-----------------------------------------------------------------------------
-- Private Helpers
-----------------------------------------------------------------------------

local function isValidNamespace(namespace)
    return type(namespace) == "string"
        and string.match(namespace, "%S") ~= nil
end

local function isValidKey(key)
    return type(key) == "string"
        and string.match(key, "%S") ~= nil
end

local function hasNamespace(namespace)
    return namespaces[namespace] ~= nil
end

--- Creates a detached copy of a runtime value.
---
--- Shared references and cyclic table relationships are preserved within
--- the copied value.
-- @param value any
-- @param copiedTables table|nil
-- @return any copiedValue
local function copyValue(
    value,
    copiedTables
)
    if type(value) ~= "table" then
        return value
    end

    copiedTables = copiedTables or {}

    if copiedTables[value] ~= nil then
        return copiedTables[value]
    end

    local copiedValue = {}

    copiedTables[value] =
        copiedValue

    for key, nestedValue in pairs(value) do
        local copiedKey =
            copyValue(
                key,
                copiedTables
            )

        copiedValue[copiedKey] =
            copyValue(
                nestedValue,
                copiedTables
            )
    end

    return copiedValue
end

-----------------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------------

--- Returns whether a namespace is registered.
-- @param namespace any
-- @return boolean exists
function FORGE.StateStore:exists(namespace)
    if not isValidNamespace(namespace) then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.STATE_STORE,
            "Invalid namespace '%s'",
            FORGE.Logger:safeToString(
                namespace,
                "<unprintable>"
            )
        )

        return false
    end

    return hasNamespace(namespace)
end

--- Registers a new runtime-state namespace.
-- @param namespace any
-- @return boolean created
function FORGE.StateStore:register(namespace)
    if not isValidNamespace(namespace) then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.STATE_STORE,
            "Cannot register invalid namespace '%s'",
            FORGE.Logger:safeToString(
                namespace,
                "<unprintable>"
            )
        )

        return false
    end

    if hasNamespace(namespace) then
        if FORGE.Logger:isDevelopmentMode() then
            FORGE.Logger:debug(
                FORGE.Definitions.LogSource.STATE_STORE,
                "Namespace '%s' is already registered",
                namespace
            )
        end

        return false
    end

    namespaces[namespace] = {}

    return true
end

--- Stores a value within a registered namespace.
-- @param namespace any
-- @param key any
-- @param value any
-- @return boolean stored
function FORGE.StateStore:set(
    namespace,
    key,
    value
)
    if not isValidNamespace(namespace) then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.STATE_STORE,
            "Cannot set value using invalid namespace '%s'",
            FORGE.Logger:safeToString(
                namespace,
                "<unprintable>"
            )
        )

        return false
    end

    if not hasNamespace(namespace) then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.STATE_STORE,
            "Cannot set value in unregistered namespace '%s'",
            namespace
        )

        return false
    end

    if not isValidKey(key) then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.STATE_STORE,
            "Cannot set value using invalid key '%s' in namespace '%s'",
            FORGE.Logger:safeToString(
                key,
                "<unprintable>"
            ),
            namespace
        )

        return false
    end

    if value == nil then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.STATE_STORE,
            "Cannot store nil value for key '%s' in namespace '%s'",
            key,
            namespace
        )

        return false
    end

    namespaces[namespace][key] = value

    return true
end

--- Retrieves a value from a registered namespace.
-- @param namespace any
-- @param key any
-- @return any value
-- @return boolean found
function FORGE.StateStore:get(
    namespace,
    key
)
    if not isValidNamespace(namespace) then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.STATE_STORE,
            "Cannot get value using invalid namespace '%s'",
            FORGE.Logger:safeToString(
                namespace,
                "<unprintable>"
            )
        )

        return nil, false
    end

    if not hasNamespace(namespace) then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.STATE_STORE,
            "Cannot get value from unregistered namespace '%s'",
            namespace
        )

        return nil, false
    end

    if not isValidKey(key) then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.STATE_STORE,
            "Cannot get value using invalid key '%s' in namespace '%s'",
            FORGE.Logger:safeToString(
                key,
                "<unprintable>"
            ),
            namespace
        )

        return nil, false
    end

    local value =
        namespaces[namespace][key]

    if value == nil then
        return nil, false
    end

    return value, true
end

--- Returns a detached copy of one registered namespace.
---
--- Changes made to the returned table do not modify live State Store state.
-- @param namespace any
-- @return table|nil snapshot
-- @return boolean found
function FORGE.StateStore:snapshot(namespace)
    if not isValidNamespace(namespace) then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.STATE_STORE,
            "Cannot snapshot invalid namespace '%s'",
            FORGE.Logger:safeToString(
                namespace,
                "<unprintable>"
            )
        )

        return nil, false
    end

    if not hasNamespace(namespace) then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.STATE_STORE,
            "Cannot snapshot unregistered namespace '%s'",
            namespace
        )

        return nil, false
    end

    return copyValue(
        namespaces[namespace]
    ), true
end

--- Atomically replaces all values within a registered namespace.
---
--- The supplied values are copied before being stored so subsequent changes
--- made by the caller cannot modify live State Store state.
-- @param namespace any
-- @param values any
-- @return boolean replaced
function FORGE.StateStore:replaceNamespace(
    namespace,
    values
)
    if not isValidNamespace(namespace) then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.STATE_STORE,
            "Cannot replace invalid namespace '%s'",
            FORGE.Logger:safeToString(
                namespace,
                "<unprintable>"
            )
        )

        return false
    end

    if not hasNamespace(namespace) then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.STATE_STORE,
            "Cannot replace unregistered namespace '%s'",
            namespace
        )

        return false
    end

    if type(values) ~= "table" then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.STATE_STORE,
            "Cannot replace namespace '%s' using non-table state '%s'",
            namespace,
            FORGE.Logger:safeToString(
                values,
                "<unprintable>"
            )
        )

        return false
    end

    local copiedValues =
        copyValue(values)

    namespaces[namespace] =
        copiedValues

    return true
end

--- Removes a value from a registered namespace.
-- @param namespace any
-- @param key any
-- @return boolean removed
function FORGE.StateStore:remove(
    namespace,
    key
)
    if not isValidNamespace(namespace) then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.STATE_STORE,
            "Cannot remove value using invalid namespace '%s'",
            FORGE.Logger:safeToString(
                namespace,
                "<unprintable>"
            )
        )

        return false
    end

    if not hasNamespace(namespace) then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.STATE_STORE,
            "Cannot remove value from unregistered namespace '%s'",
            namespace
        )

        return false
    end

    if not isValidKey(key) then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.STATE_STORE,
            "Cannot remove value using invalid key '%s' in namespace '%s'",
            FORGE.Logger:safeToString(
                key,
                "<unprintable>"
            ),
            namespace
        )

        return false
    end

    if namespaces[namespace][key] == nil then
        return false
    end

    namespaces[namespace][key] = nil

    return true
end

--- Removes all values from one registered namespace.
-- @param namespace any
-- @return boolean cleared
function FORGE.StateStore:clear(namespace)
    if not isValidNamespace(namespace) then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.STATE_STORE,
            "Cannot clear invalid namespace '%s'",
            FORGE.Logger:safeToString(
                namespace,
                "<unprintable>"
            )
        )

        return false
    end

    if not hasNamespace(namespace) then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.STATE_STORE,
            "Cannot clear unregistered namespace '%s'",
            namespace
        )

        return false
    end

    namespaces[namespace] = {}

    return true
end

--- Removes all registered namespaces and their values.
-- @return integer clearedNamespaceCount
function FORGE.StateStore:clearAll()
    local clearedNamespaceCount = 0

    for _ in pairs(namespaces) do
        clearedNamespaceCount =
            clearedNamespaceCount + 1
    end

    namespaces = {}

    return clearedNamespaceCount
end