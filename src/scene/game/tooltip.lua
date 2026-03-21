local oatml = require 'src.lib.oatml'

local tooltip = {}

local TOOLTIP_WIDTH = 200

function tooltip.draw(title, desc, highlightCol, fromBottom)
  love.graphics.push()
  love.graphics.translate(0, 12)

  local width = TOOLTIP_WIDTH

  local font = fonts.main
  local em = font:getHeight() * font:getLineHeight()
  local titleFont = fonts.main_2x
  local tem = titleFont:getHeight() * titleFont:getLineHeight()

  local parsed = oatml.parse(desc, width, font)

  local totalHeight = 8 + tem + 2 + #parsed * em

  if fromBottom then
    love.graphics.translate(0, -totalHeight)
  end

  local lx,ly = love.graphics.inverseTransformPoint(0, 0)
  local rx,ry = love.graphics.inverseTransformPoint(sw, sh)

  if fromBottom then
    if -totalHeight < ly then
      love.graphics.translate(0, ly - totalHeight)
    end
  else
    if totalHeight > ry then
      love.graphics.translate(0, ry - totalHeight)
    end
  end
  if width/2 > rx then
    love.graphics.translate(rx - width/2, 0)
  end
  if -width/2 < lx then
    love.graphics.translate(lx + width/2, 0)
  end

  love.graphics.setColor(0.1, 0.1, 0.1, 0.9)
  love.graphics.rectangle('fill', -width/2 - 4, -4, width + 8, totalHeight + 8, 2, 2)
  love.graphics.setLineWidth(2)
  love.graphics.setColor(0.15, 0.15, 0.4, 1)
  love.graphics.rectangle('line', -width/2 - 2, -2, width + 4, totalHeight + 4)

  love.graphics.translate(0, 4)

  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.setFont(titleFont)
  love.graphics.printf(title, -width/2, 0, width, 'center')

  love.graphics.push()
  love.graphics.translate(0, tem + 2)

  love.graphics.setColor(0.7, 0.7, 0.7, 1)
  love.graphics.setFont(font)
  oatml.draw(parsed, highlightCol, 'center')

  love.graphics.pop()

  love.graphics.pop()
end

return tooltip