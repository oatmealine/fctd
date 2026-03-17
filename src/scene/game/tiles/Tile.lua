local class = require 'lib.lowerclass'
local Rotatable = require 'src.scene.game.tiles.Rotatable'

---@class Tile : Class
local Tile = class('Tile')

function Tile:__init()
  self.pos = vector.new()
  self.z = 0
  self.age = 0
  self.placeAnim = 0
  self.mirrored = false
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
function Tile:getSellValue()
  local cost = self:getCost()
  if self.age == 0 then return cost end
  if cost == -1 then return cost end
  return self:getCost() * 1/(1 + self.age * 0.25)
end
function Tile:canQuickRemove()
  return self.age == 0
end

function Tile:update(dt)
  if self.placeAnim > 0 then
    self.placeAnim = math.max(self.placeAnim - dt / 0.2)
  end
end

function Tile:placed(x, y, z, angle)
  self.pos = vector.new(x, y)
  self.z = z
  if self:is(Rotatable) and angle then
    self.angle = angle
  end
  self.placeAnim = 1
end
function Tile:awake()
end
function Tile:removed()
end

---@return Tile | nil
function Tile:toMirrored()
end

function Tile.drawHUD()
end
function Tile.drawPreview(x, y, angle, valid)
end
function Tile:drawInner()
end
function Tile:draw()
  if self.placeAnim > 0 then
    love.graphics.push()
    love.graphics.translate(16, 16)
    love.graphics.scale(1 + inExpo(self.placeAnim) * 0.15)
    love.graphics.translate(-16, -16)
    --love.graphics.setShader(assets.shaders.colorize)
    --love.graphics.setColor(1, 1, 1, inSine(self.placeAnim * 0.4))
  end
  love.graphics.setColor(1, 1, 1)
  self:drawInner()
  if self.placeAnim > 0 then
    --love.graphics.setShader()
    love.graphics.pop()
  end
end

return Tile