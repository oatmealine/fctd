local class = require 'lib.lowerclass'
local Rotatable = require 'src.scene.game.tiles.Rotatable'
local Path       = require 'src.scene.game.tiles.defense.Path'
local Tile       = require 'src.scene.game.tiles.Tile'
local Pushable   = require 'src.scene.game.tiles.attack.Pushable'
local Pullable   = require 'src.scene.game.tiles.attack.Pullable'

---@class Conveyor : Tile, Rotatable
local Conveyor = class('Conveyor', Tile, Rotatable, Pullable, Pushable)

local FPS = 10
local sprite = assets.sprites.tiles.conveyor
local frames = {
  straight = {},
  curved = {},
}

local PULL_SPEED = 0.25
local SPEED = 0.6

for i = 1, 8 do
  frames.curved[i] = love.graphics.newQuad((i - 1) * 32, 0, 32, 32, sprite)
  frames.straight[i] = love.graphics.newQuad((i - 1) * 32, 32, 32, 32, sprite)
end

function Conveyor:__init(angle)
  Tile.__init(self)
  Rotatable.__init(self, angle)
  self.curved = false
  self.flipped = false

  self.pullT = 0
  ---@type ({item: Item, t: number, overrideSide?: vector2D, appliedBurn?: boolean}[])
  self.itemQueue = {}
end

function Conveyor.getName()
  return 'Conveyor'
end
function Conveyor.getDescription()
  return 'Your basic unit of transport. Gets items from point A to point B.'
end

function Conveyor:hasSpace()
  return not (self.itemQueue[1] and self.itemQueue[1].t <= PULL_SPEED / SPEED)
end

function Conveyor:update(dt)
  Tile.update(self, dt)

  local forwardsVec = vector.new(0, -1):rotate(self.angle * 90)
  local forwardsTile = scenes.scene.game.getTile(self.pos + forwardsVec)

  local backwardsVec = -forwardsVec
  if self.curved then backwardsVec = backwardsVec:rotate(self.flipped and 90 or -90) end
  local backwardsTile = scenes.scene.game.getTile(self.pos + backwardsVec)

  if self.pullT <= 0 then
    if self:hasSpace() and backwardsTile and backwardsTile:is(Pullable) and backwardsTile:canPullFromSide(-backwardsVec) then
      local item = backwardsTile:pullItem(-backwardsVec)
      if item then
        self.pullT = self.pullT + PULL_SPEED - dt
        table.insert(self.itemQueue, 1, { item = item, t = 0 })
      end
    end
  else
    self.pullT = self.pullT - dt
  end

  for i = #self.itemQueue, 1, -1 do
    local item = self.itemQueue[i]
    local next = self.itemQueue[i + 1]
    item.t = math.min(item.t + dt / SPEED, 1)
    if next then
      item.t = math.min(item.t, next.t - PULL_SPEED / SPEED)
    end

    if item.t >= 1 then
      if forwardsTile and forwardsTile:is(Pushable) and forwardsTile:canPushFromSide(-forwardsVec) then
        local success = forwardsTile:pushItem(item.item, -forwardsVec, (item.t - 1) * SPEED)
        if success then table.remove(self.itemQueue, i) end
      end
    end

    item.item:update(dt)
  end
end

function Conveyor:burn(dir)
  local dirAngle = (dir:angle() + 90) / 90
  for _, item in ipairs(self.itemQueue) do
    local shouldBurn =
      dirAngle % 2 == self.angle % 2 or
      item.t > 0.2 and item.t < 0.8
    if shouldBurn and not item.appliedBurn then
      item.appliedBurn = true
      item.item:cook()
    end
  end
end

function Conveyor:pushItem(item, side, dt)
  if not self:hasSpace() then return false end

  table.insert(self.itemQueue, 1, { item = item, t = (dt or 0) / SPEED, overrideSide = side })
  return true
end

function Conveyor:canPushFromSide(side)
  return true
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

function Conveyor.drawStatic(angle, curved, flipped)
  local t = love.timer.getTime()
  local w, h = 32, 32
  local baseFrames = curved and frames.curved or frames.straight

  if curved then angle = (angle + 3) % 4 end

  love.graphics.draw(
    sprite, baseFrames[math.floor(t * FPS) % #baseFrames + 1],
    w/2, h/2,
    angle * math.pi/2,
    1, flipped and -1 or 1,
    w/2, h/2
  )
end

function Conveyor.drawHUD()
  local w, h = 32, 32
  love.graphics.setColor(1, 1, 1)
  love.graphics.draw(sprite, frames.straight[1], -w/2, -h/2)
end

function Conveyor.drawPreview(x, y, valid, angle)
  love.graphics.setColor(1, 1, 1, 0.5)
  if not valid then
    love.graphics.setColor(1, 0, 0, 0.5)
    love.graphics.setShader(assets.shaders.dander)
    assets.shaders.dander:send('time', love.timer.getTime())
  end

  local curved, flipped = Conveyor.getConnectionState(x, y, angle)

  Conveyor.drawStatic(angle, curved, flipped)

  love.graphics.setShader()
end

function Conveyor:drawInner()
  Conveyor.drawStatic(self.angle, self.curved, self.flipped)
end

function Conveyor:drawItems()
  local w, h = 32, 32

  local forwardsVec = vector.new(0, -1):rotate(self.angle * 90)
  local backwardsVec = -forwardsVec
  if self.curved then backwardsVec = backwardsVec:rotate(self.flipped and 90 or -90) end

  for _, item in ipairs(self.itemQueue) do
    local pos = mix(mix(item.overrideSide or backwardsVec, vector.null, math.min(item.t / 0.5, 1)), forwardsVec, math.max(item.t / 0.5 - 1, 0))
    local posAbs = (pos * 0.5 + 0.5) * vector.new(w, h)
    love.graphics.push()
    love.graphics.translate(posAbs:unpack())
    item.item:draw()
    love.graphics.pop()
  end
end

function Conveyor:toMirrored()
  local path = Path()
  local angle = self.angle
  -- vertical flip
  if angle == 0 or angle == 2 then
    angle = (angle + 2) % 4
  end
  -- adjust for corners
  if self.curved then
    angle = (angle + (self.flipped and 3 or 1)) % 4
  end
  path.angle = angle
  return path
end

return Conveyor