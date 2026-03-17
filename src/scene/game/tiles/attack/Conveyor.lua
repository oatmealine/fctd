local class = require 'lib.lowerclass'
local Rotatable = require 'src.scene.game.tiles.Rotatable'
local Path       = require 'src.scene.game.tiles.defense.Path'
local Tile       = require 'src.scene.game.tiles.Tile'

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
  Tile.__init(self)
  Rotatable.__init(self, angle)
  -- todo
  self.curved = false
  self.flipped = false
end

function Conveyor.getConnectionState(x, y, angle)
  local pos = vector.new(x, y)

  local forwardsVec = vector.new(0, -1):rotate(angle * 90)

  local backwardsVec = -forwardsVec
  local backwardsTile = scenes.scene.game.getTile(pos + backwardsVec)
  local backwards = backwardsTile and backwardsTile:is(Conveyor) and backwardsTile.angle == angle

  local rightVec = forwardsVec:rotate(90)
  local rightTile = scenes.scene.game.getTile(pos + rightVec)
  local right = rightTile and rightTile:is(Conveyor) and rightTile.angle == (angle + 3) % 4

  local leftVec = -rightVec
  local leftTile = scenes.scene.game.getTile(pos + leftVec)
  local left = leftTile and leftTile:is(Conveyor) and leftTile.angle == (angle + 1) % 4

  if backwards then return false, false end -- prioritize going forwards over elsewhere
  if left and right then return end
  if left then
    return true, true
  end
  if right then
    return true, false
  end
  return false, false
end

function Conveyor:updateConnections()
  if self.excludeFromConnectionsCheck then
    return
  end

  self.curved, self.flipped =
    Conveyor.getConnectionState(self.pos.x, self.pos.y, self.angle)

  local forwardsVec = vector.new(0, -1):rotate(self.angle * 90)
  local forwardsTile = scenes.scene.game.getTile(self.pos + forwardsVec)

  if forwardsTile and forwardsTile:is(Conveyor) then
    self.excludeFromConnectionsCheck = true
    forwardsTile--[[@as Conveyor]]:updateConnections()
    self.excludeFromConnectionsCheck = false
  end
end

function Conveyor:awake()
  self:updateConnections()
end
function Conveyor:removed()
  local forwardsVec = vector.new(0, -1):rotate(self.angle * 90)
  local forwardsTile = scenes.scene.game.getTile(self.pos + forwardsVec)

  if forwardsTile and forwardsTile:is(Conveyor) then
    forwardsTile--[[@as Conveyor]]:updateConnections()
  end
end

function Conveyor.getCost()
  return 200
end

function Conveyor:canQuickRemove()
  return true
end

function Conveyor.drawHUD()
  local w, h = 32, 32
  love.graphics.setColor(1, 1, 1)
  love.graphics.draw(assets.sprites.conveyor, frames.straight[1], -w/2, -h/2)
end

function Conveyor.drawStatic(x, y, angle, curved, flipped)
  local t = love.timer.getTime()
  local w, h = 32, 32
  local baseFrames = curved and frames.curved or frames.straight

  local scaleSide = flipped and -1 or 1

  local scaleX, scaleY = 1, scaleSide

  if curved then angle = (angle + 3) % 4 end

  love.graphics.draw(
    assets.sprites.conveyor, baseFrames[math.floor(t * FPS) % #baseFrames + 1],
    w/2, h/2,
    angle * math.pi/2,
    scaleX, scaleY,
    w/2, h/2
  )
end

function Conveyor.drawPreview(x, y, angle, valid)
  love.graphics.setColor(1, 1, 1, 0.5)
  if not valid then
    love.graphics.setColor(1, 0, 0, 0.5)
    love.graphics.setShader(assets.shaders.dander)
    assets.shaders.dander:send('time', love.timer.getTime())
  end

  local curved, flipped = Conveyor.getConnectionState(x, y, angle)

  Conveyor.drawStatic(x, y, angle, curved, flipped)

  love.graphics.setShader()
end

function Conveyor:drawInner()
  Conveyor.drawStatic(self.pos.x, self.pos.y, self.angle, self.curved, self.flipped)
end

function Conveyor:toMirrored()
  local path = Path()
  path.angle = (self.angle + 2) % 4
  return path
end

return Conveyor