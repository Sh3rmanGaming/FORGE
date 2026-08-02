---=============================================================================
--- FORGE Engine
---
--- Responsible only for the engine lifecycle.
---
--- It does NOT implement gameplay systems.
--- It coordinates them.
---=============================================================================

FORGE.Engine = {}

FORGE.Engine.isMissionLoaded = false
FORGE.Engine.mapName = nil

function FORGE.Engine:loadMap(mapName)

end

function FORGE.Engine:deleteMap()

end

function FORGE.Engine:update(dt)

end

function FORGE.Engine:draw()

end

function FORGE.Engine:keyEvent(unicode, sym, modifier, isDown)

end

function FORGE.Engine:mouseEvent(posX, posY, isDown, isUp, button)

end

addModEventListener(FORGE.Engine)