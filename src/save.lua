local _M = {}

local binser = require 'lib.binser'

_M.name = '1'
_M.data = {
  settings = {
    music = 0.5,
    sfx = 0.5,
    fullscreen = false,
  }
}

function _M.getFilename()
  return 'save' .. _M.name .. '.fctd'
end

function _M.load()
  local filename = _M.getFilename()
  local exists = love.filesystem.getInfo(filename, 'file')
  if exists then
    local dataStr, msg = love.filesystem.read(filename)
    if not dataStr then
      log.error('error reading savedata: ' .. msg)
      return
    end

    local ok, res = pcall(binser.deserializeN, dataStr, 1)
    if not ok then
      log.error('error loading savedata: ' .. res)
      return
    end

    log.info('savedata', fullDump(res))
    _M.data = mergeTableLenient(_M.data, res)
  end
end

local DO_MULTITHREADING = not IS_WEB

local saveThreadCode = love.filesystem.read('src/save.thread.lua')
---@type love.Thread?
local saveThread
local saveStartedAt = 0
local callback

local saveAnim = 0
local SAVE_ANIM_DUR = 1.5

local function canSave()
  --if scenes.scene.game.isStartup then
  --  return false
  --end
  return true
end

function _M.save(setCallback)
  if not canSave() then
    log.info('REFUSING TO SAVE')
    return
  end

  --if not scenes.scene.game.isStartup then physics.saveEggs() end
  local data = binser.serialize(_M.data)

  if DO_MULTITHREADING then
    local res, err = loadstring(saveThreadCode, 'save thread')
    assert(res, err)
    res(_M.getFilename(), data)
    saveAnim = SAVE_ANIM_DUR
    if setCallback then setCallback() end
  else
    if saveThread then
      log.error('trying to save while already saving!! wtf!!!!!')
      return
    end

    callback = setCallback
    saveThread = love.thread.newThread(saveThreadCode)
    saveThread:start(_M.getFilename(), data)
    saveStartedAt = os.clock()
    log.info('writing save...')

    saveAnim = 9e9
  end
end

function _M.update(dt)
  if saveThread and (not saveThread:isRunning()) then
    local err = saveThread:getError()
    if err then
      log.error(err)
    end
    log.info('wrote save, took ' .. math.floor((os.clock() - saveStartedAt) * 1000) .. 'ms')
    saveThread = nil
    saveAnim = SAVE_ANIM_DUR
    if callback then
      callback()
    end
  end
  if saveAnim > 0 then
    saveAnim = saveAnim - dt
  end
end

function _M.draw()
  -- TODO
  --[[if saveAnim > 0 then
    local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
    local framesN = 9
    local t = love.timer.getTime()
    local frame = (t * 10) % framesN
    local quad = love.graphics.newQuad(math.floor(frame) * 32, 0, 32, 32, 32 * framesN, 32)
    love.graphics.setColor(1, 1, 1, clamp(saveAnim, 0, 1))
    love.graphics.draw(assets.sprites.ui.saveicon, quad, sw - 16, sh - 16, 0, 2, 2, 32, 32)
  end]]
end

return _M