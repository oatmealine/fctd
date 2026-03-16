local jillo = require 'lib.jillo'
local Rotatable = require 'src.scene.game.tiles.Rotatable'
jillo.shouldScissor = false -- for shame
local class = require 'lib.lowerclass'
local Conveyor = require 'src.scene.game.tiles.attack.Conveyor'

---@class GameScene : Scene
local game = {}

local SCALE = 32
local ZOOM = 3

---@enum GamePhase
GamePhase = {
  -- factory builder
  Attack = 0,
  -- tower defense
  Defense = 1,
}

game.transform = love.math.newTransform()

local uiContainer = jillo.RelativeContainer:new(0, 0)

---@type Tile?
local placing
local placingAngle = 0

local placables = jillo.Container:new(0, 64, 0, 0.5, jillo.Direction.Right, 16)

---@class Placable : Element
local Placable = class('Placable', jillo.Element)

function Placable:getWidth() return 64 end
function Placable:getHeight() return 64 end
---@param thing Tile
function Placable:__init(thing)
  self.thing = thing
end
function Placable:onClicked()
  placing = self.thing
  return true
end
function Placable:draw(x, y)
  love.graphics.push()
  love.graphics.translate(x, y)
  love.graphics.setColor(1, 1, 1, self.hover and 1 or 0.5)
  love.graphics.rectangle('line', -self:getWidth()/2, -self:getHeight()/2, self:getWidth(), self:getHeight())
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.print('$' .. formatNum(self.thing.getCost()), -self:getWidth()/2, self:getHeight()/2 - 14)

  self.thing.drawHUD()
  love.graphics.pop()
end

placables:add(Placable:new(Conveyor))

uiContainer:add(placables, jillo.Anchor.BottomLeft, 16, -48)

---@class GameState
game.state = {
  money = 0,
  phase = GamePhase.Attack,
  ---@type table<number, table<number, Tile>>
  map = {},
}
local defaultState = deepcopy(game.state)

local cameraX = easable(-1, 20)

local TRANSITION_TILES = 3

---@param x number
---@param y number
---@overload fun(pos: vector2D): Tile
---@return Tile | nil
local function getTile(x, y)
  if type(x) == 'cdata' then
    local vec = x
    x, y = round(vec.x), round(vec.y)
  end
  return game.state.map[x] and game.state.map[x][y]
end
game.getTile = getTile
---@param x number
---@param y number
---@param tile Tile | nil
---@overload fun(pos: vector2D, tile: Tile): Tile
local function setTile(x, y, tile)
  if type(x) == 'cdata' then
    local vec = x
    x, y = round(vec.x), round(vec.y)
  end
  local oldTile = getTile(x, y)
  game.state.map[x] = game.state.map[x] or {}
  game.state.map[x][y] = tile
  if oldTile then
    oldTile:removed()
  end
end
game.setTile = setTile

local function getMapMiddle()
  if TRANSITION_TILES % 2 == 1 then
    return 1
  end
  return 0.5
end

local function isValidPlacement(tile, x, y)
  if x < -game.mapWidth then return false end
  if x > game.mapWidth then return false end
  if y < -math.floor(game.mapHeight/2) then return false end
  if y > math.ceil(game.mapHeight/2) then return false end

  if game.state.phase == GamePhase.Attack then
    if x > getMapMiddle() - TRANSITION_TILES/2 then
      return false
    end
  elseif game.state.phase == GamePhase.Defense then
    if x < getMapMiddle() + TRANSITION_TILES/2 then
      return false
    end
  end

  local spot = getTile(x, y)

  return spot == nil or spot:is(tile)
end

local function updateTransform()
  game.transform:reset()
  game.transform:translate(mix(sw, 0, (cameraX.eased / 2 + 0.5)), sh/2)
  game.transform:scale(SCALE * ZOOM)
  game.transform:translate(-(getMapMiddle() + 0.5), 0)
  if game.mapHeight % 2 == 0 then
    game.transform:translate(0, -0.5)
  end
end

function game.init()
  game.state = deepcopy(defaultState)
  game.state.money = game.state.money + 10000
  state = game.state

  map = {}

  placing = nil
  placingAngle = 0

  game.mapWidth = 12 * 2 -- both sides
  game.mapHeight = 6

  updateTransform()
end

local awakeQueue = {}

game.callbacks = {}
function game.callbacks.update(dt)
  uiContainer:update(dt)

  for _, tile in ipairs(awakeQueue) do
    tile:awake()
  end
  awakeQueue = {}
  for x, row in pairs(game.state.map) do
    for y, tile in pairs(row) do
      tile:update(dt)
    end
  end

  cameraX.target = game.state.phase == GamePhase.Attack and -1 or 1
  cameraX:update(dt)

  updateTransform()
end

local function drawWorld()
  love.graphics.push()
  love.graphics.applyTransform(game.transform)

  local endX = game.mapWidth
  if TRANSITION_TILES % 2 == 1 then
    endX = endX + 1
  end
  for x = -game.mapWidth, endX do
    for y = -math.floor(game.mapHeight/2), math.ceil(game.mapHeight/2) do
      love.graphics.push()

      love.graphics.translate(x, y)
      love.graphics.scale(1 / (SCALE))

      love.graphics.setColor(1, 1, 1, 0.3)
      love.graphics.line(0, 0, SCALE, 0)
      love.graphics.line(0, 0, 0, SCALE)

      love.graphics.print(x .. ', ' .. y)

      local tile = getTile(x, y)
      if tile then
        tile:draw()
      end

      love.graphics.pop()
    end
  end

  if placing then
    local mx, my = game.transform:inverseTransformPoint(love.mouse.getPosition())
    local x, y = math.floor(mx), math.floor(my)

    love.graphics.push()

    love.graphics.translate(x, y)
    love.graphics.scale(1 / (SCALE))

    placing.drawPreview(x, y, placingAngle, isValidPlacement(placing, x, y))

    if placing:is(Rotatable) then
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.printf('Q', -16, -16, 16, 'right')
      love.graphics.printf('E', SCALE, -16, 16, 'left')
    end

    love.graphics.pop()
  end

  love.graphics.setColor(0.3, 1, 0.3)
  love.graphics.setLineWidth(0.12)
  love.graphics.line(getMapMiddle() + 0.5, -game.mapHeight, getMapMiddle() + 0.5, game.mapHeight)
  love.graphics.setLineWidth(1)

  love.graphics.pop()
end

local function drawUI()
  love.graphics.setColor(1, 1, 1)

  -- lazy font size
  love.graphics.push()
  love.graphics.translate(8, sh - 8)
  love.graphics.scale(1.5)

  love.graphics.print('$' .. formatNum(state.money), 0, -16)
  love.graphics.pop()

  placables:setWidth(sw - 32)
  uiContainer:setDimensions(sw, sh)
  uiContainer:draw(sw/2, sh/2, 1)
end

function game.callbacks.draw()
  sw, sh = love.graphics.getWidth(), love.graphics.getHeight()

  drawWorld()
  drawUI()
end

function game.callbacks.mousepressed(x, y, button)
  if uiContainer:onClicked(x - sw/2, y - sh/2, button) then return end

  if placing then
    local mx, my = game.transform:inverseTransformPoint(x, y)
    local x, y = math.floor(mx), math.floor(my)

    if isValidPlacement(placing, x, y) then
      local newTile = placing:new()
      local oldTile = getTile(x, y)
      local shouldChargeCost = oldTile == nil or (not oldTile:is(placing))
      local hasFunds = true

      if shouldChargeCost then
        hasFunds = state.money >= placing.getCost()
        if hasFunds then
          state.money = state.money - placing.getCost()
        end
      end

      if hasFunds then
        setTile(x, y, newTile)
        newTile:placed(x, y, placingAngle)
        newTile:awake()
      end
    end
  end
end
function game.callbacks.mousereleased(x, y, button)
  if uiContainer:onRelease(x - sw/2, y - sh/2, button) then return end
end
function game.callbacks.mousemoved(x, y)
  if uiContainer:onMouse(x - sw/2, y - sh/2, true) then return end
end

function game.callbacks.wheelmoved(x, y)
end

local function mirrorTiles()
  for x, row in pairs(game.state.map) do
    if x < getMapMiddle() then
      for y, tile in pairs(row) do
        local mirrored = tile:toMirrored()
        if mirrored then
          local mx, my = math.floor((getMapMiddle() + 1)) - x, y
          setTile(mx, my, mirrored)
          mirrored:placed(mx, my)
          table.insert(awakeQueue, mirrored)
        end
      end
    end
  end
end

---@param phase GamePhase
function game.setPhase(phase)
  if game.state.phase == phase then return end

  game.state.phase = phase

  placing = nil

  if phase == GamePhase.Defense then
    mirrorTiles()
  end
end

---@param key love.KeyConstant
---@param code love.Scancode
function game.callbacks.keypressed(key, code)
  if code == 'q' then
    placingAngle = placingAngle - 1
    if placingAngle < 0 then
      placingAngle = 3
    end
  end
  if code == 'e' then
    placingAngle = placingAngle + 1
    if placingAngle > 3 then
      placingAngle = 0
    end
  end
  if DEBUG then
    if code == 'g' then
      game.setPhase(1 - game.state.phase)
    end
  end
end

function game.callbacks.resize()
end

return game