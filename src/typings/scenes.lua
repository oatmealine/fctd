---@meta

---@class Scene
local scene = {}
scene.callbacks = {}
scene.callbacks.draw = function() end
---@param dt number
scene.callbacks.update = function(dt) end
scene.callbacks.resize = function() end
---@param key love.KeyConstant
---@param scancode love.Scancode
---@param isrepeat boolean
scene.callbacks.keypressed = function(key, scancode, isrepeat) end
---@param x number
---@param y number
---@param button number
---@param istouch boolean
---@param presses number
scene.callbacks.mousepressed = function(x, y, button, istouch, presses) end
---@param x number
---@param y number
---@param button number
---@param istouch boolean
---@param presses number
scene.callbacks.mousereleased = function(x, y, button, istouch, presses) end
---@param x number
---@param y number
---@param dx number
---@param dy number
---@param istouch boolean
scene.callbacks.mousemoved = function(x, y, dx, dy, istouch) end
---@param x number
---@param y number
scene.callbacks.wheelmoved = function(x, y) end