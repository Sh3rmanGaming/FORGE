---=============================================================================
--- FORGE Engine Host Input Integration Tests
---=============================================================================

FORGE.Tests = FORGE.Tests or {}

function FORGE.Tests.runForgeOSEngineInputIntegrationTests()
    local Result = FORGE.Definitions.ForgeOSResult
    local originalInputBinding = g_inputBinding
    local originalGui = g_gui
    local originalLocalPlayer = g_localPlayer
    local cursorChanges = {}
    local inputLocks, inputUnlocks = 0, 0
    local success, errorMessage = pcall(function()
        FORGE.ForgeOS:shutdown()
        FORGE.EventBus:clearAll()
        FORGE.StateStore:clearAll()
        FORGE.SaveManager:clearAllRegistrations()
        g_inputBinding = {
            setShowMouseCursor = function(_, visible)
                table.insert(cursorChanges, visible)
            end
        }
        g_gui = { getIsGuiVisible = function() return false end }
        g_localPlayer = {
            inputComponent = {
                lock = function() inputLocks = inputLocks + 1 end,
                unlock = function() inputUnlocks = inputUnlocks + 1 end
            }
        }
        if FORGE.ForgeOS:start() ~= Result.SUCCESS
            or FORGE.ForgeOS:completeStartup() ~= Result.SUCCESS
            or FORGE.Engine.onToggleLaptop(nil, nil, 1) ~= true
            or FORGE.Engine.onToggleCursorMode(nil, nil, 1) ~= true
            or cursorChanges[#cursorChanges] ~= true
            or inputLocks ~= 1 then
            error("Laptop and cursor activation adapter failed")
        end
        if FORGE.Engine.onToggleLaptop(nil, nil, 1) ~= true then
            error("Laptop hide adapter failed")
        end
        FORGE.Engine:update(0)
        if cursorChanges[#cursorChanges] ~= false
            or inputUnlocks ~= 1 then
            error("Final-device hide did not restore gameplay cursor")
        end
        g_gui = { getIsGuiVisible = function() return true end }
        if FORGE.Engine.onToggleCursorMode(nil, nil, 1) ~= false then
            error("Higher-priority GIANTS GUI did not block cursor mode")
        end
    end)
    FORGE.ForgeOS:shutdown()
    g_inputBinding = originalInputBinding
    g_gui = originalGui
    g_localPlayer = originalLocalPlayer
    if not success then return false, errorMessage end
    return true
end
