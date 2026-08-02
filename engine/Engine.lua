---=============================================================================
--- FORGE Engine
---
--- Responsible only for the engine lifecycle.
---
--- Responsibilities:
---     • Receive FS25 mission lifecycle callbacks.
---     • Coordinate FORGE startup.
---     • Coordinate FORGE shutdown.
---     • Dispatch frame updates.
---
--- This class must never implement gameplay systems.
---=============================================================================

FORGE.Engine = {}

FORGE.Engine.isMissionLoaded = false
FORGE.Engine.mapName = nil

--- Called by Farming Simulator when a mission loads.
function FORGE.Engine:loadMap(mapName)
    self.isMissionLoaded = true
    self.mapName = mapName

    FORGE.Logger:info(
        FORGE.Definitions.LogSource.ENGINE,
        "Loaded map '%s'",
        FORGE.Logger:safeToString(
            mapName,
            "<unknown>"
        )
    )

    if FORGE.Tests ~= nil then
        if FORGE.Tests.runLoggerTests ~= nil then
            FORGE.Tests.runLoggerTests()
        end

        if FORGE.Tests.runEventBusTests ~= nil then
            FORGE.Tests.runEventBusTests()
        end

         if FORGE.Tests.runStateStoreTests ~= nil then
        FORGE.Tests.runStateStoreTests()
        end
    end
end

--- Called by Farming Simulator when the mission unloads.
function FORGE.Engine:deleteMap()
    self.isMissionLoaded = false
    self.mapName = nil

    local clearedEvents =
        FORGE.EventBus:clearAll()

    FORGE.Logger:info(
        FORGE.Definitions.LogSource.ENGINE,
        "Engine shutdown complete (%d event groups cleared)",
        clearedEvents
    )
end

function FORGE.Engine:update(dt)

end

function FORGE.Engine:draw()

end

function FORGE.Engine:keyEvent(
    unicode,
    sym,
    modifier,
    isDown
)

end

function FORGE.Engine:mouseEvent(
    posX,
    posY,
    isDown,
    isUp,
    button
)

end

addModEventListener(FORGE.Engine)