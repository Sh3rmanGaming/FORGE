---=============================================================================
--- FORGE PF.006 Route Parameter Schema Tests
---
--- Verifies schema validation, detachment, strictness of declared schemas, and
--- the legacy behaviour of routes that declare none.
---=============================================================================

FORGE.Tests = FORGE.Tests or {}

function FORGE.Tests.runRouteParameterSchemaTests()
    local Schema = FORGE.RouteParameterSchema

    local function check(condition, message)
        if not condition then
            error(message)
        end
    end

    local succeeded, failure = pcall(function()
        -- Declaring a schema.
        local valid, copy = Schema:copySchema(nil)
        check(valid and copy == nil, "nil schema should be valid and absent")
        valid, copy = Schema:copySchema({})
        check(valid and next(copy) == nil, "empty schema should be valid")
        local declared = {
            itemId = { type = "string", required = true },
            page = { type = "number" }
        }
        valid, copy = Schema:copySchema(declared)
        check(valid and copy.itemId.required == true
            and copy.page.required == false, "schema copied wrongly")
        check(copy ~= declared and copy.itemId ~= declared.itemId,
            "schema copy was not detached")
        check(not Schema:copySchema("text"), "string schema accepted")
        check(not Schema:copySchema({ itemId = "string" }),
            "non-table rule accepted")
        check(not Schema:copySchema({ itemId = { type = "table" } }),
            "unsupported type accepted")
        check(not Schema:copySchema({ itemId = { type = "string",
            extra = true } }), "unknown rule key accepted")
        check(not Schema:copySchema({ itemId = { type = "string",
            required = "yes" } }), "non-boolean required accepted")
        check(not Schema:copySchema({ ["bad name"] = { type = "string" } }),
            "name with whitespace accepted")

        -- No schema: legacy behaviour accepts anything controlled.
        check(Schema:validate(nil, nil), "legacy route rejected nil parameters")
        check(Schema:validate(nil, { anything = 1 }),
            "legacy route rejected parameters")

        -- Empty schema: strict, no parameters allowed.
        local _, empty = Schema:copySchema({})
        check(Schema:validate(empty, nil), "empty schema rejected nil")
        check(Schema:validate(empty, {}), "empty schema rejected {}")
        check(not Schema:validate(empty, { x = 1 }),
            "empty schema accepted a parameter")

        -- Declared schema.
        local _, schema = Schema:copySchema(declared)
        check(Schema:validate(schema, { itemId = "a" }),
            "valid parameters rejected")
        check(Schema:validate(schema, { itemId = "a", page = 2 }),
            "valid optional parameter rejected")
        check(not Schema:validate(schema, {}), "missing required accepted")
        check(not Schema:validate(schema, nil), "nil with required accepted")
        check(not Schema:validate(schema, { itemId = 5 }),
            "wrong type accepted")
        check(not Schema:validate(schema, { itemId = "a", other = true }),
            "unknown parameter accepted")
        check(not Schema:validate(schema, { itemId = "a", page = 0 / 0 }),
            "NaN number accepted")
        check(not Schema:validate(schema, "text"),
            "non-table parameters accepted")
    end)

    if not succeeded then
        return false, failure
    end
    FORGE.Logger:info(FORGE.Definitions.LogSource.TEST,
        "Route Parameter Schema test harness passed")
    return true
end
