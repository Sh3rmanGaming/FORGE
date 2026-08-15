---=============================================================================
--- FORGE Communications Definitions Tests
---
--- Manual test harness for authoritative Communications definitions.
---
--- Responsibilities:
---     • Verify every approved Communications definition and value.
---     • Reject missing, unexpected, or duplicate identifiers.
---     • Verify identifier and controlled-data validation helpers.
---     • Report results through the FORGE Logger.
---
--- This manual harness is invoked by the Engine development test runner.
---=============================================================================

FORGE.Tests = FORGE.Tests or {}

function FORGE.Tests.runCommunicationsDefinitionsTests()
    FORGE.Logger:info(
        FORGE.Definitions.LogSource.TEST,
        "Communications Definitions test harness started"
    )

    local expected = {
        CommunicationsNamespace = {
            STATE = "forge.communications"
        },
        CommunicationsAppId = {
            COMMUNICATIONS = "forge.communications"
        },
        MessageChannel = {
            SYSTEM = "system",
            MAIL = "mail",
            MESSAGE = "message"
        },
        MessagePriority = {
            NORMAL = "normal",
            IMPORTANT = "important"
        },
        CommunicationsResult = {
            SUCCESS = "success",
            INVALID_ARGUMENT = "invalidArgument",
            INVALID_DEFINITION = "invalidDefinition",
            NOT_AVAILABLE = "notAvailable",
            NOT_FOUND = "notFound",
            CAPACITY_EXHAUSTED = "capacityExhausted",
            STATE_ERROR = "stateError",
            NOTIFICATION_CREATION_FAILED =
                "notificationCreationFailed",
            NOTIFICATION_LINKAGE_FAILED =
                "notificationLinkageFailed",
            INTERNAL_ERROR = "internalError"
        },
        CommunicationsEvent = {
            MESSAGE_CREATED = "communication.messageCreated",
            MESSAGE_READ = "communication.messageRead",
            MESSAGE_ARCHIVED = "communication.messageArchived"
        }
    }

    local function verifyTable(name, actual, definition)
        if type(actual) ~= "table" then
            error(name .. " must be a table")
        end

        local values = {}

        for key, value in pairs(definition) do
            if actual[key] ~= value then
                error(name .. "." .. key .. " has an unexpected value")
            end

            if values[value] ~= nil then
                error(name .. " contains duplicate value " .. value)
            end

            values[value] = key
        end

        for key in pairs(actual) do
            if definition[key] == nil then
                error(name .. "." .. tostring(key) .. " is not approved")
            end
        end
    end

    local success, errorMessage = pcall(function()
        if type(FORGE.Definitions.Communications) ~= "table" then
            error("Communications definitions namespace must be a table")
        end

        for name, definition in pairs(expected) do
            verifyTable(name, FORGE.Definitions[name], definition)
        end

        local validation = FORGE.CommunicationsValidation
        if type(validation) ~= "table"
            or not validation:isIdentifier("forge.communications")
            or validation:isIdentifier("")
            or validation:isIdentifier("forge communications")
            or validation:isIdentifier(1) then
            error("Communications identifier validation failed")
        end

        local source = {
            text = "value",
            number = 42,
            enabled = true,
            nested = { identifier = "message.1" }
        }
        local valid, detached = validation:copyControlledData(source)
        if not valid
            or detached == source
            or detached.nested == source.nested
            or detached.nested.identifier ~= "message.1" then
            error("Controlled data detachment failed")
        end
        detached.nested.identifier = "changed"
        if source.nested.identifier ~= "message.1" then
            error("Controlled data result was not detached")
        end

        local cyclic = {}
        cyclic.self = cyclic
        local shared = {}
        local sharedGraph = { left = shared, right = shared }
        local notANumber = math.huge - math.huge
        if notANumber == notANumber then
            error("Unable to construct a safe NaN test value")
        end

        if validation:isControlledData({ executable = function() end })
            or validation:isControlledData({ infinite = math.huge })
            or validation:isControlledData({ notANumber = notANumber })
            or validation:isControlledData(cyclic)
            or validation:isControlledData(sharedGraph)
            or validation:isControlledData(setmetatable({}, {}))
            or validation:isControlledData({ [1] = "numeric key" }) then
            error("Unsafe controlled data was accepted")
        end

        if coroutine ~= nil
            and type(coroutine.create) == "function"
            and validation:isControlledData({
                thread = coroutine.create(function() end)
            }) then
            error("Thread controlled data was accepted")
        end
    end)

    if not success then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.TEST,
            "Communications Definitions test harness failed: %s",
            FORGE.Logger:safeToString(errorMessage, "<unprintable error>")
        )

        return false, errorMessage
    end

    FORGE.Logger:info(
        FORGE.Definitions.LogSource.TEST,
        "Communications Definitions test harness passed"
    )

    return true
end
