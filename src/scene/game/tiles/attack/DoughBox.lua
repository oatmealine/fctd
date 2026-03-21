local class = require 'lib.lowerclass'
local Tile  = require 'src.scene.game.tiles.Tile'
local Pullable = require 'src.scene.game.tiles.attack.Pullable'
local Item     = require 'src.scene.game.Item'
local Rotatable= require 'src.scene.game.tiles.Rotatable'

---@class DoughBox : Tile, Pullable, Rotatable
local DoughBox = class('DoughBox', Tile, Pullable, Rotatable)

local sprite = assets.sprites.tiles.machines.doughbox
local frames = {
  box = {},
  dough = {},
}

for i, angle in ipairs({1, 3, 0, 2}) do
  frames.box[angle] = love.graphics.newQuad((i - 1) * 32, 32, 32, 32, sprite)
end
for i = 1, 4 do
  frames.dough[i] = love.graphics.newQuad((i - 1) * 32 + 32 * 8, 32, 32, 32, sprite)
end

function DoughBox:__init(angle)
  Tile.__init(self)
  Rotatable.__init(self, angle)

  self.doughTimer = 4

  self.statDough = 0
  self.statDoughWave = 0
end

function DoughBox.getName()
  return 'Dough Box'
end
function DoughBox.getDescription()
  return 'Acts as a supply of dough. Don\'t ask where the dough comes from.'
end
function DoughBox.canInspect()
  return true
end
function DoughBox:inspectData()
  return {
    { 'Dough Timer', (round(self.doughTimer * 10) / 10) .. 's' },
    { 'Total Dough', self.statDoughWave, total = self.statDough },
  }
end

function DoughBox:canPullFromSide(side)
  return (side:angle() + 90) == self.angle * 90
end
function DoughBox:pullItem()
  if self.doughTimer < 1 then return end
  self.doughTimer = self.doughTimer - 1
  local item = Item('dough')
  item:playSpawnAnim()
  self.statDough = self.statDough + 1
  self.statDoughWave = self.statDoughWave + 1
  return item
end

function DoughBox:update(dt)
  self.doughTimer = math.min(self.doughTimer + dt * 0.5, 4)
  Tile.update(self, dt)
end

function DoughBox.getCost()
  return 4000
end

function DoughBox.drawStatic(angle, dough)
  local w, h = 32, 32

  local frame = frames.box[round(angle) % 4]
  local frameDough = frames.dough[dough]
  local angleDiff = angle - round(angle)
  local rot = angleDiff * math.pi/2

  love.graphics.draw(sprite, frame, w/2, h/2, rot, 1, 1, w/2, h/2)
  if frameDough then
    love.graphics.draw(sprite, frameDough, w/2, h/2, rot, 1, 1, w/2, h/2)
  end
end

function DoughBox.drawHUD()
  local w, h = 32, 32
  love.graphics.setColor(1, 1, 1)
  love.graphics.push()
  love.graphics.translate(-w/2, -h/2)
  DoughBox.drawStatic(2, 4)
  love.graphics.pop()
end

function DoughBox.drawPreview(x, y, valid, angle)
  love.graphics.setColor(1, 1, 1, 0.5)
  if not valid then
    love.graphics.setColor(1, 0, 0, 0.5)
    love.graphics.setShader(assets.shaders.dander)
    assets.shaders.dander:send('time', love.timer.getTime())
  end

  DoughBox.drawStatic(angle, 4)

  love.graphics.setShader()
end


function DoughBox:drawInner()
  love.graphics.setColor(1, 1, 1)
  DoughBox.drawStatic(self.angle, math.floor(self.doughTimer))
end

return DoughBox