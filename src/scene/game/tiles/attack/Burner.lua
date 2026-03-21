local class = require 'lib.lowerclass'
local Tile  = require 'src.scene.game.tiles.Tile'
local Rotatable = require 'src.scene.game.tiles.Rotatable'
local Conveyor  = require 'src.scene.game.tiles.attack.Conveyor'

---@class Burner : Tile, Rotatable
local Burner = class('Burner', Tile, Rotatable)

local sprite = assets.sprites.tiles.machines.burner
local frames = {}
for i, angle in ipairs({1, 0, 2}) do
  frames[angle] = love.graphics.newQuad((i - 1) * 32, 0, 32, 32, sprite)
end

function Burner:__init(angle)
  Tile.__init(self)
  Rotatable.__init(self, angle)
end

function Burner:update(dt)
  Tile.update(self, dt)

  local forwardsVec = vector.new(0, -1):rotate(self.angle * 90)
  local forwardsTile = scenes.scene.game.getTile(self.pos + forwardsVec)
  local forwards2Tile = scenes.scene.game.getTile(self.pos + forwardsVec * 2)

  if forwardsTile and forwardsTile:is(Conveyor) then
    forwardsTile:burn(forwardsVec)
  end
  if forwards2Tile and forwards2Tile:is(Conveyor) then
    forwards2Tile:burn(forwardsVec)
  end
end

function Burner.drawStatic(angle)
  local w, h = 32, 32

  local frame = frames[round(angle) % 4]
  local scaleX = 1
  if not frame then
    frame = frames[1]
    scaleX = -scaleX
  end
  local angleDiff = angle - round(angle)
  local rot = angleDiff * math.pi/2

  love.graphics.draw(sprite, frame, w/2, h/2, rot, scaleX, 1, w/2, h/2)
end

function Burner.getCost()
  return 1000
end

function Burner.getName()
  return 'Burner'
end
function Burner.getDescription()
  return 'A pretty crude way of baking a cake. Be careful around fire!'
end
function Burner.canInspect()
  return true
end

function Burner.drawHUD()
  local w, h = 32, 32
  love.graphics.setColor(1, 1, 1)
  love.graphics.push()
  love.graphics.translate(-w/2, -h/2)
  Burner.drawStatic(1)
  love.graphics.pop()
end

function Burner.drawPreview(x, y, valid, angle)
  love.graphics.setColor(1, 1, 1, 0.5)
  if not valid then
    love.graphics.setColor(1, 0, 0, 0.5)
    love.graphics.setShader(assets.shaders.dander)
    assets.shaders.dander:send('time', love.timer.getTime())
  end

  Burner.drawStatic(angle)

  love.graphics.setShader()
end

function Burner:drawInner()
  love.graphics.setColor(1, 1, 1)
  Burner.drawStatic(self.angle)
end

function Burner:drawItems()
  local w, h = 32, 32
  love.graphics.setColor(1, 1, 1)
  local forwardsVec = vector.new(0, -1):rotate(self.angle * 90)
  love.graphics.push()
  love.graphics.translate(w/2, h/2)
  love.graphics.translate((forwardsVec * w/2):unpack())
  love.graphics.setShader(assets.shaders.wavy)
  assets.shaders.wavy:send('time', love.timer.getTime())
  local spr = assets.sprites.tiles.machines.firestream
  love.graphics.draw(spr, 0, 0, (self.angle - 1) * math.pi/2, 1, 1, 0, spr:getHeight()/2)
  love.graphics.setShader()
  love.graphics.pop()
  if self.angle == 2 then
    love.graphics.draw(assets.sprites.tiles.machines.burnerdownfire)
  end
end

return Burner