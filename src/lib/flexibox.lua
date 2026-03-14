---@class Flexibox
local Flexibox = {}
Flexibox.__index = Flexibox

---@param sprite love.Image
function Flexibox.new(sprite)
  local w, h = sprite:getDimensions()
  local seg = math.floor(math.max(w, h)/3 + 0.5)

  ---@class Flexibox
  self = setmetatable({}, Flexibox)

  self.w, self.h = w, h
  self.seg = seg

  self.quads = {
    tl = love.graphics.newQuad(0,       0,       seg,     seg,     w, h),
    t  = love.graphics.newQuad(seg,     0,       w-seg*2, seg,     w, h),
    tr = love.graphics.newQuad(w - seg, 0,       seg,     seg,     w, h),
    l  = love.graphics.newQuad(0,       seg,     seg,     h-seg*2, w, h),
    m  = love.graphics.newQuad(seg,     seg,     w-seg*2, h-seg*2, w, h),
    r  = love.graphics.newQuad(w - seg, seg,     seg,     h-seg*2, w, h),
    bl = love.graphics.newQuad(0,       h - seg, seg,     seg,     w, h),
    b  = love.graphics.newQuad(seg,     h - seg, w-seg*2, seg,     w, h),
    br = love.graphics.newQuad(w - seg, h - seg, seg,     seg,     w, h),
  }

  self.sprite = sprite

  return self
end

function Flexibox:draw(x, y, w, h, scale)
  scale = scale or 1
  local fillX = (w - self.seg*2*scale) / (self.w - self.seg*2)
  local fillY = (h - self.seg*2*scale) / (self.h - self.seg*2)
  love.graphics.draw(self.sprite, self.quads.tl, x,                        y,                        0, scale, scale)
  love.graphics.draw(self.sprite, self.quads.t,  x + self.seg * scale,     y,                        0, fillX, scale)
  love.graphics.draw(self.sprite, self.quads.tr, x + w - self.seg * scale, y,                        0, scale, scale)
  love.graphics.draw(self.sprite, self.quads.l,  x,                        y + self.seg * scale,     0, scale, fillY)
  love.graphics.draw(self.sprite, self.quads.m,  x + self.seg * scale,     y + self.seg * scale,     0, fillX, fillY)
  love.graphics.draw(self.sprite, self.quads.r,  x + w - self.seg * scale, y + self.seg * scale,     0, scale, fillY)
  love.graphics.draw(self.sprite, self.quads.bl, x,                        y + h - self.seg * scale, 0, scale, scale)
  love.graphics.draw(self.sprite, self.quads.b,  x + self.seg * scale,     y + h - self.seg * scale, 0, fillX, scale)
  love.graphics.draw(self.sprite, self.quads.br, x + w - self.seg * scale, y + h - self.seg * scale, 0, scale, scale)
end

function Flexibox:drawRep(x, y, w, h, scale)
  scale = scale or 1
  local u = (self.w - self.seg*2)*scale
  for sx = x + self.seg * scale, x + w - self.seg * scale - u, u do
    love.graphics.draw(self.sprite, self.quads.t, sx, y,                        0, scale, scale)
    love.graphics.draw(self.sprite, self.quads.b, sx, y + h - self.seg * scale, 0, scale, scale)
    for sy = y + self.seg * scale, y + h - self.seg * scale, (self.h - self.seg*2)*scale do
      love.graphics.draw(self.sprite, self.quads.m, sx, sy, 0, scale, scale)
    end
  end
  local u = (self.h - self.seg*2)*scale
  for sy = y + self.seg * scale, y + h - self.seg * scale - u, u do
    love.graphics.draw(self.sprite, self.quads.l, x,                        sy, 0, scale, scale)
    love.graphics.draw(self.sprite, self.quads.r, x + w - self.seg * scale, sy, 0, scale, scale)
  end
  love.graphics.draw(self.sprite, self.quads.tl, x,                        y,                        0, scale, scale)
  love.graphics.draw(self.sprite, self.quads.tr, x + w - self.seg * scale, y,                        0, scale, scale)
  love.graphics.draw(self.sprite, self.quads.bl, x,                        y + h - self.seg * scale, 0, scale, scale)
  love.graphics.draw(self.sprite, self.quads.br, x + w - self.seg * scale, y + h - self.seg * scale, 0, scale, scale)
end

return Flexibox