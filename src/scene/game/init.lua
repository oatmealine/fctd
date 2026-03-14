---@class GameScene : Scene
local game = {}

function game.init()
end

game.callbacks = {}
function game.callbacks.update(dt)
end
 
function game.callbacks.draw()
  sw, sh = love.graphics.getWidth(), love.graphics.getHeight()

  love.graphics.print('freddy fazbear', sw/2 + math.sin(love.timer.getTime()) * sw/2)
end

function game.callbacks.mousepressed(x, y, button)
end

function game.callbacks.mousereleased(x, y, button)
end

function game.callbacks.wheelmoved(x, y)
end

function game.callbacks.keypressed(key, code)
end

function game.callbacks.resize(w, h)
end

return game