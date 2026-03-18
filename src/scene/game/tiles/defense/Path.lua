local class = require 'lib.lowerclass'
local Tile  = require 'src.scene.game.tiles.Tile'
local Rotatable = require 'src.scene.game.tiles.Rotatable'

---@class Path : Tile, Rotatable
local Path = class('Path', Tile, Rotatable)

local sprite = assets.sprites.tiles.path
local frames = {}

for i, v in ipairs({'straight', 'curved'}) do
  frames[v] = {}
  for angle = 0, 3 do
    local a = angle
    if v == 'straight' then a = a % 2 end
    frames[v][angle] = love.graphics.newQuad((i - 1) * 32 * 2 + a * 32, 0, 32, 32, sprite)
  end
end

function Path:__init(angle)
  Tile.__init(self)
  Rotatable.__init(self, angle)
  self.curved = false
  self.flipped = false
end

function Path.getConnectionState(x, y, angle)
  local pos = vector.new(x, y)

  local forwardsVec = vector.new(0, -1):rotate(angle * 90)

  local backwardsVec = -forwardsVec
  local backwardsTile = scenes.scene.game.getTile(pos + backwardsVec)
  local backwards = backwardsTile and backwardsTile:is(Path) and backwardsTile.angle == angle

  local rightVec = forwardsVec:rotate(90)
  local rightTile = scenes.scene.game.getTile(pos + rightVec)
  local right = rightTile and rightTile:is(Path) and rightTile.angle == (angle + 3) % 4

  local leftVec = -rightVec
  local leftTile = scenes.scene.game.getTile(pos + leftVec)
  local left = leftTile and leftTile:is(Path) and leftTile.angle == (angle + 1) % 4

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

function Path:updateConnections()
  if self.excludeFromConnectionsCheck then
    return
  end

  self.curved, self.flipped =
    Path.getConnectionState(self.pos.x, self.pos.y, self.angle)

  local forwardsVec = vector.new(0, -1):rotate(self.angle * 90)
  local forwardsTile = scenes.scene.game.getTile(self.pos + forwardsVec)

  if forwardsTile and forwardsTile:is(Path) then
    self.excludeFromConnectionsCheck = true
    forwardsTile--[[@as Path]]:updateConnections()
    self.excludeFromConnectionsCheck = false
  end
end

function Path:awake()
  self:updateConnections()
end

function Path:drawInner()
  local w, h = 32, 32

  local base = frames.straight
  if self.curved then base = frames.curved end
  local angle = self.angle
  if self.flipped then angle = (self.angle + 3) % 4 end
  local frame = base[(angle + 3) % 4]

  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(
    sprite, frame,
    w/2, h/2,
    0,
    1, 1,
    w/2, h/2
  )
end

return Path