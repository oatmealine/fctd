local class = require 'lib.lowerclass'
local Rotatable = require 'src.scene.game.tiles.Rotatable'

---@class Tile : Class
local Tile = class('Tile')

function Tile:__init()
  self.pos = vector.new()
end

function Tile:getWidth()
  return 1
end
function Tile:getHeight()
  return 1
end

function Tile.getCost()
  return -1
end

function Tile:update(dt)
end

function Tile:placed(x, y, angle)
  self.pos = vector.new(x, y)
  if self:is(Rotatable) then
    self.angle = angle
  end
end
function Tile:awake()
end

function Tile.drawHUD()
end
function Tile.drawPreview(angle, valid)
end
function Tile:draw()
end

return Tile