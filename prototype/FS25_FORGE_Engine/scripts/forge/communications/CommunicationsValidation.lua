---=============================================================================
--- FORGE Communications Validation
---
--- Provides pure shared validation for Communications definitions and data.
---
--- Responsibilities:
---     • Validate stable non-whitespace identifiers.
---     • Validate and detach controlled plain data.
---     • Reject executable, cyclic, shared-reference, and metatable values.
---
--- This helper must not own message state, persistence, logging, or events.
---=============================================================================

FORGE.CommunicationsValidation = {}

--- Returns whether a value is a valid stable identifier.
-- @param value any
-- @return boolean valid
function FORGE.CommunicationsValidation:isIdentifier(value)
    return type(value) == "string"
        and value ~= ""
        and string.match(value, "%s") == nil
end

local function copyControlled(value, observed)
    local valueType = type(value)

    if valueType == "string" or valueType == "boolean" then
        return true, value
    end

    if valueType == "number" then
        if value ~= value
            or value == math.huge
            or value == -math.huge then
            return false, nil
        end

        return true, value
    end

    if valueType ~= "table"
        or getmetatable(value) ~= nil
        or observed[value] then
        return false, nil
    end

    observed[value] = true

    local detached = {}

    for key, nestedValue in pairs(value) do
        if type(key) ~= "string" then
            return false, nil
        end

        local valid, nestedCopy =
            copyControlled(nestedValue, observed)

        if not valid then
            return false, nil
        end

        detached[key] = nestedCopy
    end

    return true, detached
end

--- Validates and detaches one controlled plain-data value.
-- @param value any
-- @return boolean valid
-- @return any detachedValue
function FORGE.CommunicationsValidation:copyControlledData(value)
    return copyControlled(value, {})
end

--- Returns whether one value satisfies controlled plain-data rules.
-- @param value any
-- @return boolean valid
function FORGE.CommunicationsValidation:isControlledData(value)
    local valid = self:copyControlledData(value)

    return valid
end
