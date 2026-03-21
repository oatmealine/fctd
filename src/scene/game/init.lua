local jillo = require 'lib.jillo'
local Burner= require 'src.scene.game.tiles.attack.Burner'
local tooltip = require 'src.scene.game.tooltip'
local color   = require 'lib.color'
local flexibox= require 'src.lib.flexibox'
jillo.shouldScissor = false -- for shame
local class = require 'lib.lowerclass'

local Rotatable = require 'src.scene.game.tiles.Rotatable'
local Conveyor = require 'src.scene.game.tiles.attack.Conveyor'
local Exit = require 'src.scene.game.tiles.special.Exit'
local Wall = require 'src.scene.game.tiles.special.Wall'
local DoughBox = require 'src.scene.game.tiles.attack.DoughBox'

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
local placingAngleEase = easable(0, 24)
local placingPosEase = easable(vector.new(-9999, -9999), 64)

---@type Tile?
local inspecting
local inspectingTween = tweenable(0)

local inspectBoxLink

local function removeInspect()
  if inspectBoxLink then uiContainer:remove(inspectBoxLink.element) end
  inspectBoxLink = nil
  inspecting = nil
end

local currentTooltip = {}

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
  removeInspect()
  placingPosEase:reset(vector.new(-9999, -9999))
  return true
end
function Placable:draw(x, y)
  love.graphics.push()
  love.graphics.translate(x, y)
  love.graphics.setColor(0, 0, 0, 0.2)
  love.graphics.rectangle('fill', -self:getWidth()/2, -self:getHeight()/2, self:getWidth(), self:getHeight())
  love.graphics.setColor(1, 1, 1, self.hover and 1 or 0.5)
  love.graphics.rectangle('line', -self:getWidth()/2, -self:getHeight()/2, self:getWidth(), self:getHeight())

  love.graphics.push()
  love.graphics.scale(1.5)
  self.thing.drawHUD()
  love.graphics.pop()

  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.setFont(fonts.main)
  printWithShadow('$' .. formatNum(self.thing.getCost()), -self:getWidth()/2 + 4, self:getHeight()/2 - 16)

  love.graphics.pop()

  if self.hover then
    currentTooltip = { x = x, y = y - self:getHeight()/2, self.thing.getName(), self.thing.getDescription(), true }
  end
end

placables:add(Placable:new(Conveyor))
placables:add(Placable:new(DoughBox))
placables:add(Placable:new(Burner))

uiContainer:add(placables, jillo.Anchor.BottomLeft, 16, -48)

local roundUI = jillo.Sprite(assets.sprites.ui.round_ui, 2)

uiContainer:add(roundUI, jillo.Anchor.BottomRight, 0, 0)

---@class InspectBox : Element
local InspectBox = class('InspectBox', jillo.Element)

---@param tile Tile
function InspectBox:__init(tile)
  self.tile = tile
  self.title = love.graphics.newText(fonts.main_2x, tile.getName())
  self.text = love.graphics.newText(fonts.main, tile.getDescription())
end

function InspectBox:getWidth()
  return 175
end
function InspectBox:getHeight()
  return 200
end

function InspectBox:update(dt)
  local x, y = game.transform:transformPoint(self.tile.pos:unpack())

  if x > sw/2 then
    x, y = game.transform:transformPoint((self.tile.pos):unpack())
    x = x - self:getWidth() - 16
  else
    x, y = game.transform:transformPoint((self.tile.pos + vector.new(1, 0)):unpack())
    x = x + 16
  end

  inspectBoxLink.x = x + self:getWidth()/2
  inspectBoxLink.y = y + self:getHeight()/2
end

local panelDark = flexibox.new(assets.sprites.ui.panel_dark)

function InspectBox:draw(x, y)
  love.graphics.push()

  love.graphics.translate(x, y)
  love.graphics.scale(inspectingTween.eased)
  love.graphics.translate(-self:getWidth()/2, -self:getHeight()/2)

  love.graphics.setColor(1, 1, 1)
  panelDark:draw(0, 0, self:getWidth(), self:getHeight(), 2)

  love.graphics.setColor(1, 1, 1)
  love.graphics.setFont(fonts.main_2x)
  love.graphics.printf(self.tile.getName(), 16, 16, self:getWidth() - 32, 'left')

  love.graphics.pop()
end

---@class GameState
game.state = {
  money = 0,
  phase = GamePhase.Attack,
  ---@type table<number, table<number, table<number, Tile>>>
  map = {},
}
local defaultState = deepcopy(game.state)

local cameraX = easable(-1, 20)
local previewing = false

local placeUIEase = easable(0, 20)

local TRANSITION_TILES = 3

---@param x number
---@param y number
---@param z number?
---@overload fun(pos: vector2D): Tile
---@return Tile | nil
local function getTile(x, y, z)
  if type(x) == 'cdata' then
    local vec = x
    z = y
    x, y = round(vec.x), round(vec.y)
  end
  z = z or 0
  return game.state.map[z] and game.state.map[z][x] and game.state.map[z][x][y]
end
game.getTile = getTile
---@param x number
---@param y number
---@param z number
---@param tile Tile | nil
---@overload fun(x: number, y: number, tile: Tile | nil)
---@overload fun(pos: vector2D, tile: Tile | nil)
---@overload fun(pos: vector2D, z: number, tile: Tile | nil)
local function setTile(x, y, z, tile)
  if type(x) == 'cdata' then
    local vec = x
    tile = z
    z = y
    x, y = round(vec.x), round(vec.y)

    if not tile then
      tile = z
      z = 0
    end
  else
    if type(z) ~= 'number' then
      tile = z
      z = 0
    end
  end
  z = z or 0
  local oldTile = getTile(x, y)
  game.state.map[z] = game.state.map[z] or {}
  game.state.map[z][x] = game.state.map[z][x] or {}
  game.state.map[z][x][y] = tile
  if oldTile then
    oldTile:removed()
  end
end
game.setTile = setTile

local function getMapMiddle()
  if TRANSITION_TILES % 2 == 1 then
    return 0
  end
  return 0.5
end

local function isValidPlacement(tile, x, y)
  if x < -(game.playWidth - math.ceil(getMapMiddle() - TRANSITION_TILES/2)) then return false end
  if x > game.playWidth + math.floor(TRANSITION_TILES/2) then return false end

  if y < -math.ceil(game.playHeight/2 - 1) then return false end
  if y > math.floor(game.playHeight/2) then return false end

  if game.state.phase == GamePhase.Attack then
    if x > math.floor(getMapMiddle() - TRANSITION_TILES/2) then
      return false
    end
  elseif game.state.phase == GamePhase.Defense then
    if x < math.ceil(getMapMiddle() + TRANSITION_TILES/2) then
      return false
    end
  end

  local spot = getTile(x, y)

  return spot == nil or spot:is(tile)
end

function game.isOOB(x, y)
  if x < -(game.mapWidth - math.ceil(getMapMiddle() - TRANSITION_TILES/2)) then return true end
  if x > game.mapWidth + math.floor(TRANSITION_TILES/2) then return true end
  if y < -math.ceil(game.mapHeight/2 - 1) then return true end
  if y > math.floor(game.mapHeight/2) then return true end
  return false
end

local function updateTransform()
  game.transform:reset()
  game.transform:translate(mix(sw, 0, (cameraX.eased / 2 + 0.5)), sh/2)
  game.transform:scale(SCALE * ZOOM)
  game.transform:translate(-(getMapMiddle() + 0.5), -(1 - game.mapHeight % 2)/2)
  if game.mapHeight % 2 == 0 then
    game.transform:translate(0, -0.5)
  end
end

local maps = {
  {
    width = 12,
    height = 11,
    playWidth = 10,
    playHeight = 5,
    layers = {
      [-2] = {
        '              ',
        '              ',
        '              ',
        '  qqqqqqqqqqq ',
        '  q.........q ',
        '  q.........q ',
        '  q.........q ',
        '  qqqqqqqqqqq ',
        '              ',
        '              ',
        '              ',
      },
      [-1] = {
        '              ',
        '              ',
        '              ',
        '              ',
        '   ?????????  ',
        '   ?????????  ',
        '   ?????????  ',
        '              ',
        '              ',
        '              ',
        '              ',
      },
      [0] = {
        '##############',
        '##############',
        '##|&|^^^^|&|##',
        '##  -   ==  ',
        '##          >',
        '##          ',
        '##  o    o  >',
        '##          ',
        '##############',
        '##############',
        '##############',
      }
    },
    palette = {
      ['>'] = {Exit},

      ['^'] = {Wall, {'cafe.wall_top', 'factory.wall_top'}},
      ['|'] = {Wall, {'cafe.wall_top', 'factory.wall_pillar'}},
      ['&'] = {Wall, {'cafe.wall_top', 'factory.wall_door'}},
      ['#'] = {Wall, {'cafe.wall', 'factory.wall'}},

      ['o'] = {Wall, {'cafe.table', 'factory.prop'}},
      ['-'] = {Wall, {'cafe.shelf', 'factory.prop'}},
      ['='] = {Wall, {'cafe.bigshelf', 'factory.prop'}},

      ['.'] = {Wall, {'cafe.floor', 'factory.floor'}},
      ['q'] = {Wall, {'cafe.wood', 'factory.border'}},

      ['?'] = {Wall, {nil, 'factory.litter'}}
    },
  }
}

local awakeQueue = {}

local function mirrorTilesZ(z, initial)
  local layer = game.state.map[z]
  for x, row in pairs(layer) do
    if x > getMapMiddle() then
      for y, tile in pairs(row) do
        if tile.mirrored and (not tile:is(Wall)) or initial then
          setTile(x, y, z, nil)
        end
      end
    end
  end
  for x, row in pairs(layer) do
    if x < getMapMiddle() then
      for y, tile in pairs(row) do
        if (not tile:is(Wall)) or initial then
          local mirrored = tile:toMirrored()
          if mirrored then
            mirrored.mirrored = true
            local mx, my = math.floor(getMapMiddle() + 0.5) - x, y
            setTile(mx, my, z, mirrored)
            mirrored:placed(mx, my, z)
            table.insert(awakeQueue, mirrored)
          end
        end
      end
    end
  end
end

local function mirrorTiles(initial)
  if initial then
    for z in pairs(game.state.map) do
      mirrorTilesZ(z, true)
    end
  else
    mirrorTilesZ(0)
  end
end

function game.init()
  game.state = deepcopy(defaultState)
  game.state.money = game.state.money + 10000
  state = game.state

  placing = nil
  removeInspect()
  placingAngle = 0
  placingAngleEase:reset(0)
  placingPosEase:reset(vector.new(-9999, -9999))

  local map = maps[1]

  game.mapWidth = map.width
  game.mapHeight = map.height
  game.playWidth = map.playWidth
  game.playHeight = map.playHeight
  game.layers = 0

  for z, layer in pairs(map.layers) do
    game.layers = game.layers + 1
    for y = 1, map.height do
      local row = layer[y] or ''
      for x = 1, #row do
        local char = string.sub(row, x, x)
        local spawnTile = map.palette[char]
        if spawnTile and spawnTile[1] then
          local newTile = spawnTile[1](unpack(spawnTile[2] or {}))
          local tx, ty = x - map.width + math.floor(getMapMiddle() - TRANSITION_TILES/2), y - math.ceil(map.height/2)
          setTile(tx, ty, z, newTile)
          newTile:placed(tx, ty, z)
          table.insert(awakeQueue, newTile)
        end
      end
    end
  end

  mirrorTiles(true)
  updateTransform()
end

game.callbacks = {}
function game.callbacks.update(dt)
  uiContainer:update(dt)

  for _, tile in ipairs(awakeQueue) do
    tile:awake()
  end
  awakeQueue = {}
  for x, row in pairs(game.state.map[0]) do
    for y, tile in pairs(row) do
      tile:update(dt)
    end
  end

  cameraX.target = game.state.phase == GamePhase.Attack and -1 or 1
  --cameraX.target = 0
  cameraX:update(dt)
  placeUIEase.target = placing and 1 or 0
  placeUIEase:update(dt)
  placingAngleEase.target = placingAngle
  placingAngleEase:update(dt)

  updateTransform()

  if placing then
    local mx, my = game.transform:inverseTransformPoint(love.mouse.getPosition())
    local x, y = math.floor(mx), math.floor(my)

    if placingPosEase.target.x == -9999 then
      placingPosEase:reset(vector.new(x, y))
    else
      placingPosEase:set(vector.new(x, y))
    end
    placingPosEase:update(dt)

    if love.mouse.isDown(1) then
      local oldTile = getTile(x, y)
      local notDuplicatePlacement = not (oldTile and oldTile:is(placing))
      if oldTile and oldTile:is(Rotatable) then
        notDuplicatePlacement = notDuplicatePlacement or oldTile.angle ~= (placingAngle % 4)
      end

      if notDuplicatePlacement and isValidPlacement(placing, x, y) then
        local newTile = placing:new()
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
          newTile:placed(x, y, 0, placingAngle % 4, true)
          newTile:awake()
        end
      end
    end

    if love.mouse.isDown(2) then
      local currentTile = getTile(x, y)
      if currentTile and currentTile:is(placing) and currentTile:canQuickRemove() then
        state.money = state.money + placing.getCost()
        setTile(x, y, nil)
      end
    end
  else
    local mx, my = game.transform:inverseTransformPoint(love.mouse.getPosition())
    local x, y = math.floor(mx), math.floor(my)
    local tile = getTile(x, y)

    if tile and tile.canInspect() and tile ~= inspecting then
      tile.hover:set(1)
    end
  end
  if inspecting then
    inspecting.hover:set(1)
  end
  inspectingTween:update(dt)
end

local function drawKeybind(key, x, y, scale)
  scale = scale or 1

  love.graphics.setColor(1, 1, 1)
  love.graphics.draw(assets.sprites.keys.key, x, y, 0, 2 * scale, 2 * scale)

  local width = fonts.main:getWidth(key)
  local scaleText = math.min(32 / width, 32 / fonts.main:getHeight())

  love.graphics.push()
  love.graphics.translate(x, y)
  love.graphics.translate(32/2 * scale, 32/2 * scale)
  love.graphics.scale(scaleText * scale)

  love.graphics.setFont(fonts.main)
  love.graphics.printf(key, -32/2, -fonts.main:getHeight()/2 + 2, 32, 'center')
  love.graphics.pop()
end
local function drawMouse(button, x, y)
  love.graphics.setColor(1, 1, 1)
  love.graphics.draw(({assets.sprites.keys.lmb, assets.sprites.keys.rmb})[button], x, y, 0, 2, 2)
end

local function drawPlacing()
  if not placing then return end

  local mx, my = game.transform:inverseTransformPoint(love.mouse.getPosition())
  local x, y = math.floor(mx), math.floor(my)

  if
    x < -(game.playWidth - math.ceil(getMapMiddle() - TRANSITION_TILES/2)) or
    x > game.playWidth + math.floor(TRANSITION_TILES/2) or
    y < -math.ceil(game.playHeight/2 - 1) or
    y > math.floor(game.playHeight/2)
  then
    placingPosEase:reset(vector.new(-9999, -9999))
    return
  end

  local shouldDrawUnder = true

  local oldTile = getTile(x, y)
  if oldTile and oldTile:is(placing) then
    shouldDrawUnder = oldTile:is(Rotatable) and oldTile.angle ~= (placingAngle % 4)
  end

  love.graphics.push()

  love.graphics.translate(placingPosEase.eased.x, placingPosEase.eased.y)
  love.graphics.scale(1 / (SCALE))

  if shouldDrawUnder then
    placing.drawPreview(placingPosEase.eased.x, placingPosEase.eased.y, isValidPlacement(placing, x, y), placingAngleEase.eased)
  end

  love.graphics.push()
  love.graphics.translate(16, 16)
  love.graphics.rotate((placingAngle - placingAngleEase.eased) * 0.06 * math.pi/2)

  if placing:is(Rotatable) then
    love.graphics.setColor(1, 1, 1, 1)
    drawKeybind('Q', -32, -32, 0.5)
    drawKeybind('E', 16, -32, 0.5)
  end

  love.graphics.pop()

  love.graphics.pop()
end

local function drawWorld()
  love.graphics.push()
  love.graphics.applyTransform(game.transform)

  for z = -(game.layers - 1), 0 do
    for x = -(game.mapWidth - math.ceil(getMapMiddle() - TRANSITION_TILES/2)), game.mapWidth + math.floor(TRANSITION_TILES/2) do
      for y = -math.ceil(game.mapHeight/2 - 1), math.floor(game.mapHeight/2) do
        love.graphics.push()

        love.graphics.translate(x, y)
        love.graphics.scale(1 / SCALE)

        if z == 0 then
          love.graphics.setColor(1, 1, 1, 0.6)
          --love.graphics.line(0, 0, SCALE, 0)
          --love.graphics.line(0, 0, 0, SCALE)

          love.graphics.print(x .. ',' .. y)
        end

        local tile = getTile(x, y, z)
        if tile then
          tile:draw()
        end

        love.graphics.pop()
      end
    end
  end

  for x = -(game.mapWidth - math.ceil(getMapMiddle() - TRANSITION_TILES/2)), game.mapWidth + math.floor(TRANSITION_TILES/2) do
    for y = -math.ceil(game.mapHeight/2 - 1), math.floor(game.mapHeight/2) do
      love.graphics.push()

      love.graphics.translate(x, y)
      love.graphics.scale(1 / SCALE)

      local tile = getTile(x, y, 0)
      if tile then
        tile:drawItems()
      end

      love.graphics.pop()
    end
  end

  drawPlacing()

  love.graphics.setColor(1, 1, 1)
  love.graphics.setShader(assets.shaders.beam)
  assets.shaders.beam:send('time', love.timer.getTime())
  assets.shaders.beam:send('size', { 3 * SCALE, game.mapHeight * 2 * SCALE })
  love.graphics.draw(assets.sprites.quad, getMapMiddle() + 0.5 - 1.5, -game.mapHeight, 0, 3, game.mapHeight*2)
  love.graphics.setShader()

  love.graphics.pop()
end

local function drawUI()
  love.graphics.setColor(1, 1, 1)

  love.graphics.setColor(1, 1, 1, 0.4)
  love.graphics.draw(assets.sprites.shade, 0, sh, 0, 500/256, 300/256, 128, 128)
  love.graphics.draw(assets.sprites.shade, sw, sh, 0, 500/256, 300/256, 128, 128)
  love.graphics.setColor(1, 1, 1)

  love.graphics.setFont(fonts.main_2x)
  local placeControlsX = mix(-256, 8, placeUIEase.eased)
  printWithShadow('   place\n   remove\n   stop', placeControlsX, sh - 96 - fonts.main_2x:getHeight() * 3 - 16)

  drawMouse(1, placeControlsX, sh - 96 - fonts.main_2x:getHeight() * 3 - 16)
  drawMouse(2, placeControlsX, sh - 96 - fonts.main_2x:getHeight() * 2 - 16)
  drawKeybind('Esc', placeControlsX, sh - 96 - fonts.main_2x:getHeight() * 1 - 16)

  love.graphics.setFont(fonts.main_2x)
  printWithShadow('$' .. formatNum(state.money), 8, sh - 8 - 24)

  placables:setWidth(sw - 32)
  uiContainer:setDimensions(sw, sh)
  uiContainer:draw(sw/2, sh/2, 1)

  if currentTooltip[1] then
    love.graphics.push()
    love.graphics.translate(currentTooltip.x, currentTooltip.y)
    tooltip.draw(currentTooltip[1], currentTooltip[2], color.fromHex('ff4400'), currentTooltip[3])
    love.graphics.pop()
  end
end

function game.callbacks.draw()
  sw, sh = love.graphics.getWidth(), love.graphics.getHeight()

  currentTooltip = {}

  drawWorld()
  drawUI()
end

function game.callbacks.mousepressed(x, y, button)
  if uiContainer:onClicked(x - sw/2, y - sh/2, button) then return end

  local mx, my = game.transform:inverseTransformPoint(x, y)
  local tx, ty = math.floor(mx), math.floor(my)
  local tile = getTile(tx, ty)
  if button == 1 then
    if tile and tile.canInspect() then
      if tile ~= inspecting then
        inspecting = tile
        inspectingTween:reset(0.8)
        inspectingTween:tween(1, outElastic, 0.7)

        local inspectBox = InspectBox(tile)
        inspectBoxLink = uiContainer:add(inspectBox, jillo.Anchor.TopLeft)
      else
        removeInspect()
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

local function applyAge(swappingTo)
  for x, row in pairs(game.state.map[0]) do
    local cond = x < getMapMiddle()
    if swappingTo == GamePhase.Defense then
      cond = x > getMapMiddle()
    end
    if cond then
      for y, tile in pairs(row) do
        tile.age = tile.age + 1
      end
    end
  end
end

---@param phase GamePhase
function game.setPhase(phase)
  if game.state.phase == phase then return end

  game.state.phase = phase

  placing = nil
  removeInspect()

  if phase == GamePhase.Defense then
    mirrorTiles()
  end
  applyAge(phase)
end

---@param key love.KeyConstant
---@param code love.Scancode
function game.callbacks.keypressed(key, code)
  if code == 'q' then
    placingAngle = placingAngle - 1
  end
  if code == 'e' then
    placingAngle = placingAngle + 1
  end
  if code == 'escape' then
    if inspecting then
      removeInspect()
    elseif placing then
      placing = nil
    else
      -- pause menu
    end
  end
  if DEBUG then
    if code == 'g' then
      game.setPhase(1 - game.state.phase)
    end
    if code == 'm' then
      game.state.money = game.state.money + 1000
    end
  end
end

function game.callbacks.resize()
end

return game