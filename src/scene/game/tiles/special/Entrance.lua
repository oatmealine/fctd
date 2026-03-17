local class = require 'lib.lowerclass'
local Tile = require 'src.scene.game.tiles.Tile'

---@class Entrance : Tile
local Entrance = class('Entrance', Tile)

---@param exit Exit
function Entrance:__init(exit)
  Tile.__init(self)
  self.exit = exit
end

function Entrance.drawStatic()
  love.graphics.setColor(1, 1, 1, 0.5)
  love.graphics.draw(assets.sprites.arrow, 0, math.sin(love.timer.getTime() * 1.5) * 4)
end

function Entrance:drawInner()
  if state.phase == GamePhase.Attack then return end
  self.drawStatic()
end

return Entrance