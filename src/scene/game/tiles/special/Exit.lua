local class = require 'lib.lowerclass'
local Tile = require 'src.scene.game.tiles.Tile'
local Entrance = require 'src.scene.game.tiles.special.Entrance'

---@class Exit : Tile
local Exit = class('Exit', Tile)

function Exit:toMirrored()
  return Entrance(self)
end

function Exit:drawInner()
  if state.phase == GamePhase.Defense then return end
  Entrance.drawStatic()
end

return Exit