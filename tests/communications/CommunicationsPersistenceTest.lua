---=============================================================================
--- FORGE Communications Persistence Tests
---=============================================================================

FORGE.Tests = FORGE.Tests or {}

function FORGE.Tests.runCommunicationsPersistenceTests()
    FORGE.Logger:info(FORGE.Definitions.LogSource.TEST,
        "Communications Persistence test harness started")

    local Namespace = FORGE.Definitions.CommunicationsNamespace.STATE
    local function record(id, order)
        return {
            id = id, playerId = "player.local", source = "forge.test",
            subject = id, body = "", channel = "system",
            priority = "normal", createdOrder = order,
            read = false, archived = false,
            metadata = { safe = true }
        }
    end
    local function cleanup()
        FORGE.Communications:shutdown()
        FORGE.StateStore:clearAll()
        FORGE.SaveManager:clearAllRegistrations()
    end

    local succeeded, failure = pcall(function()
        cleanup()
        if not FORGE.CommunicationsPersistence:registerNamespace() then
            error("Communications namespace registration failed")
        end
        if not FORGE.StateStore:replaceNamespace(Namespace, {
            unrelated = { preserved = true },
            players = {
                ["player.other"] = { sentinel = "preserved" },
                ["player.local"] = {
                    sentinel = "preserved",
                    messages = {
                        ["message.1"] = record("message.1", 1),
                        alias = record("message.1", 2),
                        ["message.3"] = record("message.3", 3),
                        ["message.4"] = record("message.4", 3),
                        ["message.5"] = record("message.5", 5),
                        malformed = { id = "bad" }
                    },
                    messageNextSequence = 2
                }
            }
        }) then
            error("Unable to stage Communications restoration state")
        end
        local staged = FORGE.StateStore:snapshot(Namespace)
        staged.players["player.local"].messages["message.5"]
            .notificationId = "notification.8"
        if not FORGE.StateStore:replaceNamespace(Namespace, staged)
            or not FORGE.CommunicationsPersistence:restore() then
            error("Communications restoration failed")
        end
        local state = FORGE.StateStore:snapshot(Namespace)
        local player = state.players["player.local"]
        local survivorCount = 0
        for _ in pairs(player.messages) do
            survivorCount = survivorCount + 1
        end
        if player.messages["message.5"] == nil
            or player.messages["message.5"].notificationId
                ~= "notification.8"
            or survivorCount ~= 1
            or player.messageNextSequence ~= 6
            or player.sentinel ~= "preserved"
            or state.players["player.other"].sentinel ~= "preserved"
            or state.unrelated.preserved ~= true then
            error("Deterministic conflict repair or preservation failed")
        end

        if not FORGE.StateStore:replaceNamespace(Namespace, {})
            or not FORGE.CommunicationsPersistence:restore() then
            error("Older empty state restoration failed")
        end
        state = FORGE.StateStore:snapshot(Namespace)
        player = state.players["player.local"]
        if state.schemaVersion ~= 1 or next(player.messages) ~= nil
            or player.messageNextSequence ~= 1 then
            error("Older-state defaults failed")
        end

        local invalidState = { schemaVersion = 2, sentinel = true }
        if not FORGE.StateStore:replaceNamespace(Namespace, invalidState)
            or FORGE.CommunicationsPersistence:restore() ~= false then
            error("Unsupported schema did not fail restoration")
        end
        state = FORGE.StateStore:snapshot(Namespace)
        if state.schemaVersion ~= 2 or state.sentinel ~= true then
            error("Failed restoration was not atomic")
        end
        cleanup()
    end)

    cleanup()
    if not succeeded then
        FORGE.Logger:error(FORGE.Definitions.LogSource.TEST,
            "Communications Persistence test harness failed: %s",
            FORGE.Logger:safeToString(failure, "<unknown>"))
        return false, failure
    end
    FORGE.Logger:info(FORGE.Definitions.LogSource.TEST,
        "Communications Persistence test harness passed")
    return true
end
