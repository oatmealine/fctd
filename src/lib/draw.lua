function withFont(font, func)
  local oldFont = love.graphics.getFont()
  love.graphics.setFont(font)
  func()
  love.graphics.setFont(oldFont)
end