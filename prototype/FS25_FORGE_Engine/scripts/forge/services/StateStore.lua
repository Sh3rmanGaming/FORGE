---=============================================================================
--- FORGE State Store
---
--- Owns and organises shared FORGE runtime state.
---
--- Responsibilities:
---     • Register explicit state namespaces.
---     • Store runtime state within registered namespaces.
---     • Provide controlled access to runtime state.
---     • Remove and reset runtime state.
---
--- This service must not perform persistence, networking, or gameplay validation.
---=============================================================================

FORGE.StateStore = {
    namespaces = {}
}

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

local function hasNamespace(
    namespaces,
    namespace
)
    return namespaces[namespace] ~= nil
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

    return hasNamespace(
        self.namespaces,
        namespace
    )
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

    if hasNamespace(
        self.namespaces,
        namespace
    ) then
        if FORGE.Logger:isDevelopmentMode() then
            FORGE.Logger:debug(
                FORGE.Definitions.LogSource.STATE_STORE,
                "Namespace '%s' is already registered",
                namespace
            )
        end

        return false
    end

    self.namespaces[namespace] = {}

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

    if not hasNamespace(
        self.namespaces,
        namespace
    ) then
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

    self.namespaces[namespace][key] = value

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

    if not hasNamespace(
        self.namespaces,
        namespace
    ) then
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
        self.namespaces[namespace][key]

    if value == nil then
        return nil, false
    end

    return value, true
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

    if not hasNamespace(
        self.namespaces,
        namespace
    ) then
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

    if self.namespaces[namespace][key] == nil then
        return false
    end

    self.namespaces[namespace][key] = nil

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

    if not hasNamespace(
        self.namespaces,
        namespace
    ) then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.STATE_STORE,
            "Cannot clear unregistered namespace '%s'",
            namespace
        )

        return false
    end

    self.namespaces[namespace] = {}

    return true
end

--- Removes all registered namespaces and their values.
-- @return integer clearedNamespaceCount
function FORGE.StateStore:clearAll()
    local clearedNamespaceCount = 0

    for _ in pairs(self.namespaces) do
        clearedNamespaceCount =
            clearedNamespaceCount + 1
    end

    self.namespaces = {}

    return clearedNamespaceCount
end