local class = require 'lib.lowerclass'
local Tile = require 'src.scene.game.tiles.Tile'
local Rotatable = require 'src.scene.game.tiles.Rotatable'

---@class Conveyor : Tile, Rotatable
local Conveyor = class('Conveyor', Tile, Rotatable)

local FPS = 10
local sprite = assets.sprites.conveyor
local frames = {
  straight = {},
  curved = {},
}

for i = 1, 8 do
  frames.curved[i] = love.graphics.newQuad((i - 1) * 32, 0, 32, 32, sprite)
  frames.straight[i] = love.graphics.newQuad((i - 1) * 32, 32, 32, 32, sprite)
end

function Conveyor:__init(angle)
  Rotatable.__init(self, angle)
  -- todo
  self.curved = false
  self.flipped = false
end

function Conveyor:updateConnections()
  if self.excludeFromConnectionsCheck then
    return
  end

  local forwardsVec = vector.new(0, -1):rotate(self.angle * 90)
  local forwardsTile = scenes.scene.game.getTile(self.pos + forwardsVec)

  if forwardsTile and forwardsTile:is(Conveyor) then
    self.excludeFromConnectionsCheck = true
    forwardsTile:updateConnections()
    self.excludeFromConnectionsCheck = false
  end

  local backwardsVec = -forwardsVec
  local backwardsTile = scenes.scene.game.getTile(self.pos + backwardsVec)
  local backwards = backwardsTile and backwardsTile:is(Conveyor) and backwardsTile.angle == self.angle

  local rightVec = forwardsVec:rotate(90)
  local rightTile = scenes.scene.game.getTile(self.pos + rightVec)
  local right = rightTile and rightTile:is(Conveyor) and rightTile.angle == (self.angle + 3) % 4

  local leftVec = -rightVec
  local leftTile = scenes.scene.game.getTile(self.pos + leftVec)
  local left = leftTile and leftTile:is(Conveyor) and leftTile.angle == (self.angle + 1) % 4

  self.curved = false
  self.flipped = false

  if backwards then return end -- prioritize going forwards over elsewhere
  if left and right then return end
  if left then
    self.curved = true
    self.flipped = true
    return
  end
  if right then
    self.curved = true
  end
end

function Conveyor:placed(x, y, angle)
  Tile.placed(self, x, y, angle)
end
function Conveyor:awake()
  self:updateConnections()
end

function Conveyor.getCost()
  return 200
end

function Conveyor.drawHUD()
  local w, h = 32, 32
  love.graphics.setColor(1, 1, 1)
  love.graphics.draw(assets.sprites.conveyor, frames.straight[1], -w/2, -h/2)
end

function Conveyor.drawPreview(angle, valid)
  local t = love.timer.getTime()
  love.graphics.setColor(1, 1, 1, 0.5)
  if not valid then love.graphics.setColor(1, 0, 0, 0.5) end
  local w, h = 32, 32

  love.graphics.draw(
    assets.sprites.conveyor, frames.straight[math.floor(t * FPS) % #frames.straight + 1],
    w/2, h/2,
    angle * math.pi/2,
    1, 1,
    w/2, h/2
  )
end

function Conveyor:draw()
  local t = love.timer.getTime()
  love.graphics.setColor(1, 1, 1, 1)
  local w, h = 32, 32
  local baseFrames = self.curved and frames.curved or frames.straight

  local scaleSide = self.flipped and -1 or 1

  local scaleX, scaleY = 1, scaleSide

  local angle = self.angle
  if self.curved then angle = (angle + 3) % 4 end

  love.graphics.draw(
    assets.sprites.conveyor, baseFrames[math.floor(t * FPS) % #baseFrames + 1],
    w/2, h/2,
    angle * math.pi/2,
    scaleX, scaleY,
    w/2, h/2
  )
end

return Conveyor