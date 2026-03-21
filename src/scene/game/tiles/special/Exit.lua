local class = require 'lib.lowerclass'
local Tile = require 'src.scene.game.tiles.Tile'
local Entrance = require 'src.scene.game.tiles.special.Entrance'
local Pushable = require 'src.scene.game.tiles.attack.Pushable'

---@class Exit : Tile
local Exit = class('Exit', Tile, Pushable)

function Exit:toMirrored()
  return Entrance(self)
end

function Exit:canPushFromSide(side)
  return side == vector.new(-1, 0)
end

function Exit:pushItem(item)
  -- TODO
  return true
end

function Exit:drawInner()
  if state.phase == GamePhase.Defense then return end
  Entrance.drawStatic()
end

return Exit