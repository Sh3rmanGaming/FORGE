---=============================================================================
--- FORGE ForgeOS Route Parameter Schema
---
--- Optional, bounded parameter declarations for application routes (ADR-008).
---
--- Responsibilities:
---     • Validate and detach a route's declared parameter schema.
---     • Validate route parameters against a declared schema.
---
--- A route that declares no schema keeps the legacy behaviour: any controlled
--- plain data is accepted. A declared schema, including an empty one, is
--- strict: unknown, missing-required, or wrongly typed parameters are rejected.
--- This module never reads application or notification state.
---=============================================================================

FORGE.RouteParameterSchema = {}

local Schema = FORGE.RouteParameterSchema

local ValueTypes = {
    string = true,
    number = true,
    boolean = true
}

local function isIdentifier(value)
    return type(value) == "string"
        and value ~= ""
        and string.find(value, "%s") == nil
end

--- Validates a declared schema and returns a detached copy.
-- A nil schema is valid and means "no schema declared".
-- @param schema any
-- @return boolean valid
-- @return table|nil copy
function Schema:copySchema(schema)
    if schema == nil then
        return true, nil
    end
    if type(schema) ~= "table" or getmetatable(schema) ~= nil then
        return false, nil
    end
    local copy = {}
    for name, rule in pairs(schema) do
        if not isIdentifier(name)
            or type(rule) ~= "table"
            or getmetatable(rule) ~= nil
            or not ValueTypes[rule.type]
            or (rule.required ~= nil and type(rule.required) ~= "boolean") then
            return false, nil
        end
        for key in pairs(rule) do
            if key ~= "type" and key ~= "required" then
                return false, nil
            end
        end
        copy[name] = {
            type = rule.type,
            required = rule.required == true
        }
    end
    return true, copy
end

--- Validates route parameters against a declared schema.
-- @param schema table|nil Detached schema, or nil for the legacy behaviour
-- @param parameters any
-- @return boolean valid
function Schema:validate(schema, parameters)
    if schema == nil then
        return true
    end
    if parameters == nil then
        parameters = {}
    end
    if type(parameters) ~= "table" then
        return false
    end
    for name, value in pairs(parameters) do
        local rule = schema[name]
        if rule == nil or type(value) ~= rule.type then
            return false
        end
        if rule.type == "number" and value ~= value then
            return false
        end
    end
    for name, rule in pairs(schema) do
        if rule.required and parameters[name] == nil then
            return false
        end
    end
    return true
end
