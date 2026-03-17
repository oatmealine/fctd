function withFont(font, func)
  local oldFont = love.graphics.getFont()
  love.graphics.setFont(font)
  func()
  love.graphics.setFont(oldFont)
end

---@overload fun(coloredtext: table, x?: number, y?: number, angle?: number, sx?: number, sy?: number, ox?: number, oy?: number, kx?: number, ky?: number)
---@param text string # The text to draw.
---@param x? number # The position to draw the object (x-axis).
---@param y? number # The position to draw the object (y-axis).
---@param r? number # Orientation (radians).
---@param sx? number # Scale factor (x-axis).
---@param sy? number # Scale factor (y-axis).
---@param ox? number # Origin offset (x-axis).
---@param oy? number # Origin offset (y-axis).
---@param kx? number # Shearing factor (x-axis).
---@param ky? number # Shearing factor (y-axis).
function printWithShadow(text, x, y, r, sx, sy, ox, oy, kx, ky)
  local col = {love.graphics.getColor()}
  local font = love.graphics.getFont()
  love.graphics.setColor(0, 0, 0, 0.6)
  love.graphics.print(text, (x or 0) + font:getHeight() * 0.1, (y or 0) + font:getHeight() * 0.1, r, sx, sy, ox, oy, kx, ky)
  love.graphics.setColor(unpack(col))
  love.graphics.print(text, x, y, r, sx, sy, ox, oy, kx, ky)
end

---@overload fun(coloredtext: table, x: number, y: number, limit: number, align: love.AlignMode, angle?: number, sx?: number, sy?: number, ox?: number, oy?: number, kx?: number, ky?: number)
---@param text string # A text string.
---@param x number # The position on the x-axis.
---@param y number # The position on the y-axis.
---@param limit number # Wrap the line after this many horizontal pixels.
---@param align? love.AlignMode # The alignment.
---@param r? number # Orientation (radians).
---@param sx? number # Scale factor (x-axis).
---@param sy? number # Scale factor (y-axis).
---@param ox? number # Origin offset (x-axis).
---@param oy? number # Origin offset (y-axis).
---@param kx? number # Shearing factor (x-axis).
---@param ky? number # Shearing factor (y-axis).
function printfWithShadow(text, x, y, limit, align, r, sx, sy, ox, oy, kx, ky)
  local col = {love.graphics.getColor()}
  local font = love.graphics.getFont()
  love.graphics.setColor(0, 0, 0, 0.6)
  love.graphics.printf(text, x + font:getHeight() * 0.1, y + font:getHeight() * 0.1, limit, align, r, sx, sy, ox, oy, kx, ky)
  love.graphics.setColor(unpack(col))
  love.graphics.printf(text, x, y, limit, align, r, sx, sy, ox, oy, kx, ky)
end