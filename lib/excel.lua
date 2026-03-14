-- from https://github.com/oatmealine/jadelib
-- little lib for managing aseprite spreadsheets- er, spritesheets

local json = require 'lib.json'

---@class excel.Sprite
---@field path string
---@field width number
---@field height number
---@field frames love.Quad[]
---@field frameDurations number[]
---@field sprite love.Image
---@field frame number
---@field tag string?
---@field isLoop boolean
---@field playing boolean
---@field tags table<string, { from: number, to: number }>
---@field t number
---@field sourceSizes { x: number, y: number, w: number, h: number }[]
---@field direction number
local Sprite = {}
Sprite.__index = Sprite

local base = ''
function Sprite.setBase(path)
  base = path
end

local jsonCache = {}
local spriteCache = {}

---@return excel.Sprite
function Sprite.new(path)
  local self = {}

  path = base .. path
  local data = jsonCache[path]
  if not data then
    local jsonData = love.filesystem.read(path .. '.json')
    data = json.decode(jsonData)
    jsonCache[path] = data
  end

  self.path = path

  local width = data.meta.size.w
  local height = data.meta.size.h
  self.sheetWidth, self.sheetHeight = width, height

  self.frames = {}
  self.frameDurations = {}
  self.sourceSizes = {}
  for _, frame in ipairs(data.frames) do
    local f = frame.frame
    local quad = love.graphics.newQuad(f.x, f.y, f.w, f.h, width, height)
    table.insert(self.frames, quad)
    table.insert(self.frameDurations, frame.duration)
    table.insert(self.sourceSizes, frame.spriteSourceSize)
  end

  self.tags = {}
  for _, tag in ipairs(data.meta.frameTags) do
    self.tags[tag.name] = { from = tag.from + 1, to = tag.to + 1 }
  end

  self.frame = 1
  self.isLoop = false
  self.tag = nil
  self.playing = false
  self.t = 0
  self.direction = 1

  return setmetatable(self, Sprite)
end

---@param tag string?
---@param dontStartOver boolean?
function Sprite:play(tag, dontStartOver)
  if not self.tags[tag] then
    log.warn('no tag called ' .. tag .. ', ignoring!')
    return
  end

  if dontStartOver and self.tag == tag then
    return
  end
  self.tag = tag
  self.playing = true
  self.frame = 1
end

function Sprite:load()
  self.sprite = spriteCache[self.path] or love.graphics.newImage(self.path .. '.png')
  spriteCache[self.path] = self.sprite
end

function Sprite:drawFrame(frame, x, y, r, sx, sy, ox, oy, kx, ky)
  if not self.sprite then error('Sprite not loaded', 2) end
  --"spriteSourceSize": { "x": 43, "y": 30, "w": 13, "h": 19 },
  x = (x or 0) + self.sourceSizes[frame].x * (sx or 1)
  y = (y or 0) + self.sourceSizes[frame].y * (sy or 1)
  love.graphics.draw(self.sprite, self.frames[frame], x, y, r, sx, sy, ox, oy, kx, ky)
end
function Sprite:drawTagFrame(tag, frame, x, y, r, sx, sy, ox, oy, kx, ky)
  local tagData = self.tags[tag]
  local tagFrame = tagData.from + frame - 1
  self:drawFrame(tagFrame, x, y, r, sx, sy, ox, oy, kx, ky)
end

function Sprite:getSheetFrame()
  if self.tag then
    local tag = self.tags[self.tag]
    return tag.from + self.frame - 1
  end
  return self.frame
end

function Sprite:update(dt)
  if self.playing then
    self.t = self.t + dt
    local dur = self.frameDurations[self:getSheetFrame()]
    if self.t >= dur/1000 then
      self.t = self.t - dur/1000
      self.frame = self.frame + self.direction
      if self.tag then
        local tag = self.tags[self.tag]
        if (tag.from + self.frame - 1) > tag.to then
          self.frame = 1
        end
        if (tag.from + self.frame - 1) < tag.from then
          self.frame = tag.to - tag.from + 1
        end
      else
        if self.frame > #self.frames then
          self.frame = 1
        end
      end
    end
  end
end

function Sprite:draw(x, y, r, sx, sy, ox, oy, kx, ky)
  if not self.sprite then error('Sprite not loaded', 2) end
  self:drawFrame(self:getSheetFrame(), x, y, r, sx, sy, ox, oy, kx, ky)
end

return Sprite