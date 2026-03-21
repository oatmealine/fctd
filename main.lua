require 'lib.color'
cargo = require 'lib.cargo'
easable = require 'lib.easable'
tweenable = require 'lib.tweenable'
require 'lib.ease'
require 'lib.utf8'
log = require 'lib.log'
vector = require 'lib.vector2D'
local audio = require 'src.audio'

DEBUG = false

require 'src.constants'

require 'src.lib.util'
require 'src.lib.draw'
require 'src.lib.fp'

local save  = require 'src.save'

local excel = require 'lib.excel'
excel.setBase('assets/sprites/')

love.graphics.setDefaultFilter('nearest', 'nearest', 0)

local function audioLoader(filename)
  if startsWith(filename, 'assets/bgm') then
    return love.audio.newSource(filename, 'stream')
  else
    return audio.makeSoundPool(filename)
  end
end

fonts = {
  main = love.graphics.newFont('assets/fonts/fibberish.ttf', 16, 'none'),
  main_2x = love.graphics.newFont('assets/fonts/fibberish.ttf', 32, 'none'),
}

---@type CargoAssets
assets = cargo.init({
  dir = 'assets',
  loaders = {
    wav = audioLoader,
    ogg = audioLoader,
  },
})()

assets.shaders.colorize:send('diff', {1, 1, 1, 1})

require 'src.scenes'

function updateFullscreen()
  if save.data.settings.fullscreen then
    local _, _, flags = love.window.getMode()
    local w, h = love.window.getDesktopDimensions(flags.display)
    love.window.updateMode(w, h, { fullscreen = true, fullscreentype = 'desktop' })
    love.resize()
  else
    love.window.updateMode(1200, 800, { fullscreen = false })
    love.resize()
  end
end

function love.load(args)
  for i, arg in ipairs(args) do
    if arg == '--debug' then
      DEBUG = true
    end
    if arg == '--save' then
      local newName = args[i + 1] or '1'
      log.info('switching save to ' .. newName)
      save.name = newName
    end
  end

  if DEBUG then
    ---@diagnostic disable-next-line: param-type-mismatch
    love.window.setMode(1200, 800, { resizable = false })
  end

  save.load()

  scenes.scene.game.init()
  scenes.setScene(scenes.scene.game)

  updateFullscreen()
end

function love.update(dt)
  scenes.callbacks.update(dt)
  save.update(dt)
end

function love.draw()
  love.graphics.setFont(fonts.main)

  scenes.callbacks.draw()

  if DEBUG then
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(fonts.main)
    love.graphics.print(love.timer.getFPS() .. 'FPS', 0, 0)
  end

  save.draw()
end

function love.resize(w, h)
  scenes.callbacks.resize(w, h)
end
function love.keypressed(...)
  scenes.callbacks.keypressed(...)
end
function love.mousepressed(...)
  scenes.callbacks.mousepressed(...)
end
function love.mousereleased(...)
  scenes.callbacks.mousereleased(...)
end
function love.mousemoved(...)
  scenes.callbacks.mousemoved(...)
end
function love.wheelmoved(...)
  scenes.callbacks.wheelmoved(...)
end