-- from https://github.com/oatmealine/jadelib

local Object = require 'lib.classic'

---@generic T
---@param a T
---@param b T
---@param x number
---@return T
local function mix(a, b, x)
  return a + (b - a) * x
end

local M = {}

M.shouldScissor = true

---@enum Direction
M.Direction = {
  Down = 0,
  Right = 1,
  Up = 2,
  Left = 3
}

---@class Element : Object
---@operator call(...): Element
M.Element = Object:extend()

function M.Element:new()
  self.hover = false
  self.active = false
end

---@param dt number
function M.Element:update(dt)
end

---@param x number
---@param y number
---@param alpha number?
function M.Element:draw(x, y, alpha)
  error('not implemented', 2)
end

-- shorthand; equivalent of `draw(x + self:getWidth()/2, y + self:getHeight()/2, alpha)`
---@param x number
---@param y number
---@param alpha number?
function M.Element:drawNoncentered(x, y, alpha)
  self:draw(x + self:getWidth()/2, y + self:getHeight()/2, alpha)
end

---@return number
function M.Element:getWidth()
  error('not implemented', 2)
end

---@return number
function M.Element:getHeight()
  error('not implemented', 2)
end

-- todo
---@return boolean
function M.Element:getSelectable()
  return false
end

---@param x number
---@param y number
---@param button number
function M.Element:onClicked(x, y, button)
  if button == 1 then
    self.active = true
  end
end

---@param x number
---@param y number
---@param button number
function M.Element:onRelease(x, y, button)
  if button == 1 then
    self.active = false
  end
end

---@param x number
---@param y number
function M.Element:onMouse(x, y, hover)
  self.hover = hover
  if not hover then self.active = false end
end

-- todo
---@param selected boolean
function M.Element:onSelected(selected)
end

---@class Container : Element
---@operator call(...): Container
M.Container = M.Element:extend()

---@param width number
---@param height number
---@param alignX number
---@param alignY number
---@param direction Direction?
---@param gap number?
function M.Container:new(width, height, alignX, alignY, direction, gap)
  self.width = width
  self.height = height

  ---@type Element[]
  self.elements = {}
  self.alignX = alignX or 0.5
  self.alignY = alignY or 0.5
  self.direction = direction or M.Direction.Down
  self.gap = gap or 0

  self.scroll = 0

  self.posLeft = 0
  self.posTop = 0

  self._positions = {}
  setmetatable(self._positions, {
    __mode = 'k'
  })
end

---@param px number
function M.Container:setWidth(px)
  self.width = px
  return self
end
---@param px number
function M.Container:setHeight(px)
  self.height = px
  return self
end
---@param width number
---@param height number
function M.Container:setDimensions(width, height)
  self.width = width
  self.height = height
  return self
end

---@param element Element
function M.Container:add(element)
  table.insert(self.elements, element)
  return self
end
---@param index number
function M.Container:remove(index)
  table.remove(self.elements, index)
  self:updateScroll()
  return self
end
function M.Container:clear()
  self.elements = {}
  self:updateScroll()
  return self
end

---@param scroll number
function M.Container:setScroll(scroll)
  self.scroll = scroll
  self:updateScroll()
  return self
end

---@param align number
function M.Container:setAlignX(align)
  self.alignX = align
  return self
end
---@param align number
function M.Container:setAlignY(align)
  self.alignY = align
  return self
end

---@param direction Direction
function M.Container:setDirection(direction)
  self.direction = direction
  return self
end

---@param gap number
function M.Container:setGap(gap)
  self.gap = gap
  return self
end

---@param x number
---@param y number
function M.Container:onWheelMoved(x, y)
  self.scroll = self.scroll - y * 40
  self:updateScroll()
end

---@param mx number
---@param my number
---@param button number
function M.Container:onClicked(mx, my, button)
  M.Container.super.onClicked(self, mx, my, button)
  for _, element in ipairs(self.elements) do
    local x, y, w, h = unpack(self._positions[element] or {0, 0, 0, 0})
    if mx >= (x - w/2) and mx < (x + w/2) and my >= (y - h/2) and my < (y + h/2) then
      element:onClicked(mx - x, my - y, button)
      break
    end
  end
end

---@param mx number
---@param my number
---@param button number
function M.Container:onRelease(mx, my, button)
  M.Container.super.onRelease(self, mx, my, button)
  for _, element in ipairs(self.elements) do
    local x, y, w, h = unpack(self._positions[element] or {0, 0, 0, 0})
    if mx >= (x - w/2) and mx < (x + w/2) and my >= (y - h/2) and my < (y + h/2) then
      element:onRelease(mx - x, my - y, button)
      break
    end
  end
end

---@param mx number
---@param my number
---@param hover boolean
function M.Container:onMouse(mx, my, hover)
  M.Container.super.onMouse(self, mx, my, hover)
  for _, element in ipairs(self.elements) do
    local x, y, w, h = unpack(self._positions[element] or {0, 0, 0, 0})
    element:onMouse(mx - x, my - y, hover and (mx >= (x - w/2) and mx < (x + w/2) and my >= (y - h/2) and my < (y + h/2)))
  end
end

function M.Container:updateScroll()
  self.scroll = math.max(math.min(self.scroll, self:getLength()), 0)
end

---@param dt number
function M.Container:update(dt)
  for _, element in ipairs(self.elements) do
    element:update(dt)
  end
end

function M.Container:isVertical()
  return self.direction == M.Direction.Down or self.direction == M.Direction.Up
end

function M.Container:getLength()
  local totalLength = self.gap * (#self.elements - 1)
  for _, element in ipairs(self.elements) do
    if self:isVertical() then
      totalLength = totalLength + element:getHeight()
    else
      totalLength = totalLength + element:getWidth()
    end
  end
  return totalLength
end

---@return number
function M.Container:getWidth()
  return self.width
end
---@return number
function M.Container:getHeight()
  return self.height
end

---@param containerX number
---@param containerY number
---@param alpha number?
function M.Container:draw(containerX, containerY, alpha)
  local left, top = containerX - self.width/2, containerY - self.height/2

  self.posLeft = left
  self.posTop = top

  alpha = alpha or 1

  local alignX = self.alignX
  local alignY = self.alignY
  local reverse = self.direction == M.Direction.Up or self.direction == M.Direction.Left
  local vertical = self:isVertical()

  local totalLength = self:getLength()

  local x
  local y

  if vertical then
    x = mix(left, left + self.width, alignX)
    if alignY == 0 then
      y = top
    elseif alignY == 1 then
      y = top + self.height
    else
      y = top + self.height/2 - totalLength/2
    end
    y = y - self.scroll
  else
    y = mix(top, top + self.height, alignY)
    if alignX == 0 then
      x = left
    elseif alignX == 1 then
      x = left + self.width
    else
      x = left + self.width/2 - totalLength/2
    end
    x = x - self.scroll
  end

  if M.shouldScissor then
    love.graphics.setScissor(left, top, self.width, self.height)
  end

  for _, element in ipairs(self.elements) do
    local w = element:getWidth()
    local h = element:getHeight()

    local drawX
    local drawY
    local shouldDraw = true

    if vertical then
      if y + h < 0 then
        shouldDraw = false
      end
      if y - h > self.height then
        break
      end

      drawX = x + mix(w/2, -w/2, alignX)
      drawY = y + h/2

      y = y + h + self.gap
    else
      if x + w < 0 then
        shouldDraw = false
      end
      if x - w > self.width then
        break
      end

      drawY = y + mix(h/2, -h/2, alignY)
      drawX = x + w/2

      x = x + w + self.gap
    end

    self._positions[element] = {drawX - left - self.width/2, drawY - top - self.height/2, w, h}

    if shouldDraw then
      element:draw(drawX, drawY, alpha)
    end
  end

  if M.shouldScissor then
    love.graphics.setScissor()
  end
end

---@enum Anchor
M.Anchor = {
  Bottom = 0,
  Right = 1,
  Top = 2,
  Left = 3,
  BottomLeft = 4,
  BottomRight = 5,
  TopRight = 6,
  TopLeft = 7,
  Center = 8,
}

---@param anchor Anchor
local function anchorToAlign(anchor)
  if anchor == M.Anchor.Bottom then
    return {0.5, 1}
  elseif anchor == M.Anchor.Right then
    return {1, 0.5}
  elseif anchor == M.Anchor.Top then
    return {0.5, 0}
  elseif anchor == M.Anchor.Left then
    return {0, 0.5}
  elseif anchor == M.Anchor.BottomLeft then
    return {0, 1}
  elseif anchor == M.Anchor.BottomRight then
    return {1, 1}
  elseif anchor == M.Anchor.TopRight then
    return {1, 0}
  elseif anchor == M.Anchor.TopLeft then
    return {0, 0}
  elseif anchor == M.Anchor.Center then
    return {0.5, 0.5}
  end
end

---@class RelativeContainer : Element
---@operator call(...): RelativeContainer
M.RelativeContainer = M.Element:extend()

---@param width number
---@param height number
function M.RelativeContainer:new(width, height)
  self.width = width
  self.height = height

  ---@type { element: Element, x: number, y: number, anchor: Anchor }[]
  self.elements = {}
end

---@param px number
function M.RelativeContainer:setWidth(px)
  self.width = px
  return self
end
---@param px number
function M.RelativeContainer:setHeight(px)
  self.height = px
  return self
end
---@param width number
---@param height number
function M.RelativeContainer:setDimensions(width, height)
  self.width = width
  self.height = height
  return self
end

---@param element Element
---@param anchor? Anchor
---@param x? number
---@param y? number
function M.RelativeContainer:add(element, anchor, x, y)
  table.insert(self.elements, {
    element = element,
    x = x or 0,
    y = y or 0,
    anchor = anchor or M.Anchor.Center,
  })
  return self.elements[#self.elements]
end
---@param ref Element
---@return boolean @ success
function M.RelativeContainer:remove(ref)
  for i = #self.elements, 1, -1 do
    if self.elements[i].element == ref then
      table.remove(self.elements, i)
      return true
    end
  end
  return false
end
function M.RelativeContainer:clear()
  self.elements = {}
  return self
end

---@param elem { element: Element, x: number, y: number, anchor: Anchor }
function M.RelativeContainer:getElementPosition(elem)
  local width, height = elem.element:getWidth(), elem.element:getHeight()
  local ax, ay = unpack(anchorToAlign(elem.anchor))
  local baseX, baseY = self:getWidth() * (ax - 0.5), self:getHeight() * (ay - 0.5)
  local offsetX, offsetY = width * ((1 - ax) - 0.5), height * ((1 - ay) - 0.5)
  return { baseX + offsetX + elem.x, baseY + offsetY + elem.y, width, height }
end

---@param mx number
---@param my number
---@param button number
function M.RelativeContainer:onClicked(mx, my, button)
  M.RelativeContainer.super.onClicked(self, mx, my, button)
  for _, element in ipairs(self.elements) do
    local x, y, w, h = unpack(self:getElementPosition(element))
    if mx >= (x - w/2) and mx < (x + w/2) and my >= (y - h/2) and my < (y + h/2) then
      return element.element:onClicked(mx - x, my - y, button)
    end
  end
  return false
end

---@param mx number
---@param my number
---@param button number
function M.RelativeContainer:onRelease(mx, my, button)
  M.RelativeContainer.super.onRelease(self, mx, my, button)
  for _, element in ipairs(self.elements) do
    local x, y, w, h = unpack(self:getElementPosition(element))
    if mx >= (x - w/2) and mx < (x + w/2) and my >= (y - h/2) and my < (y + h/2) then
      element.element:onRelease(mx - x, my - y, button)
      break
    end
  end
end

---@param mx number
---@param my number
---@param hover boolean
function M.RelativeContainer:onMouse(mx, my, hover)
  M.RelativeContainer.super.onMouse(self, mx, my, hover)
  for _, element in ipairs(self.elements) do
    local x, y, w, h = unpack(self:getElementPosition(element))
    element.element:onMouse(mx - x, my - y, hover and (mx >= (x - w/2) and mx < (x + w/2) and my >= (y - h/2) and my < (y + h/2)))
  end
end

---@param dt number
function M.RelativeContainer:update(dt)
  for _, element in ipairs(self.elements) do
    element.element:update(dt)
  end
end

---@return number
function M.RelativeContainer:getWidth()
  return self.width
end
---@return number
function M.RelativeContainer:getHeight()
  return self.height
end

---@param containerX number
---@param containerY number
---@param alpha number?
function M.RelativeContainer:draw(containerX, containerY, alpha)
  local left, top = containerX - self.width/2, containerY - self.height/2

  alpha = alpha or 1

  if M.shouldScissor then
    love.graphics.setScissor(left, top, self.width, self.height)
  end

  for _, element in ipairs(self.elements) do
    local x, y, _w, _h = unpack(self:getElementPosition(element))
    element.element:draw(containerX + x, containerY + y, alpha)
  end

  if M.shouldScissor then
    love.graphics.setScissor()
  end
end

---@class Sprite : Element
---@operator call(...): Element
M.Sprite = M.Element:extend()

---@param sprite love.Image
---@param scale number
function M.Sprite:new(sprite, scale, offsetX, offsetY)
  self.sprite = sprite
  self.scale = scale or 1
  self.offsetX = offsetX or 0
  self.offsetY = offsetY or 0
end

---@param x number
---@param y number
---@param alpha number?
function M.Sprite:draw(x, y, alpha)
  love.graphics.setColor(1, 1, 1, alpha)
  love.graphics.draw(self.sprite, x + self.offsetX, y + self.offsetY, 0, self.scale, self.scale, self.sprite:getWidth()/2, self.sprite:getHeight()/2)
end

---@return number
function M.Sprite:getWidth()
  return self.sprite:getWidth() * self.scale
end

---@return number
function M.Sprite:getHeight()
  return self.sprite:getHeight() * self.scale
end

---@class Rectangle : Element
---@operator call(...): Element
M.Rectangle = M.Element:extend()

---@param width number
---@param height number
function M.Rectangle:new(width, height)
  self.width = width
  self.height = height
end

---@param x number
---@param y number
---@param alpha number?
function M.Rectangle:draw(x, y, alpha)
  love.graphics.setColor(1, 1, 1, alpha)
  love.graphics.rectangle('line', x - self.width/2, y - self.height/2, self.width, self.height)
  love.graphics.setColor(1, 1, 1, alpha * 0.2)
  love.graphics.rectangle('fill', x - self.width/2, y - self.height/2, self.width, self.height)
end

---@return number
function M.Rectangle:getWidth()
  return self.width
end

---@return number
function M.Rectangle:getHeight()
  return self.height
end

return M