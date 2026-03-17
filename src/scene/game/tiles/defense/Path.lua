local class = require 'lib.lowerclass'
local Tile  = require 'src.scene.game.tiles.Tile'

---@class Path : Tile
local Path = class('Path', Tile)

local sprite = assets.sprites.path
local frames = {}

for i, v in ipairs({'cross', 'horizontal', 'vertical'}) do
  frames[v] = love.graphics.newQuad((i - 1) * 32, 0, 32, 32, sprite)
end

function Path:__init()
  Tile.__init(self)

  self.connCross = false
  self.connVertical = false
end

function Path:updateConnections()
  if self.excludeFromConnectionsCheck then
    return
  end

  local x, y = self.pos:unpack()

  local upTile = scenes.scene.game.getTile(x, y - 1)
  local up = upTile and upTile:is(Path)

  local rightTile = scenes.scene.game.getTile(x + 1, y)
  local right = rightTile and rightTile:is(Path)

  local downTile = scenes.scene.game.getTile(x, y + 1)
  local down = downTile and downTile:is(Path)

  local leftTile = scenes.scene.game.getTile(x - 1, y)
  local left = leftTile and leftTile:is(Path)

  self.connCross = false
  self.connVertical = false
  if up and down and (not right) and (not left) then
    self.connVertical = true
  elseif left and right and (not up) and (not down) then
    self.connVertical = false
  else
    self.connCross = true
  end

  self.excludeFromConnectionsCheck = true
  for _, tile in ipairs({upTile, rightTile, downTile, leftTile}) do
    if tile and tile:is(Path) then
      tile--[[@as Path]]:updateConnections()
    end
  end
  self.excludeFromConnectionsCheck = false
end

function Path:awake()
  self:updateConnections()
end

function Path:drawInner()
  local w, h = 32, 32

  local frame = frames.horizontal
  if self.connVertical then frame = frames.vertical end
  if self.connCross then frame = frames.cross end

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