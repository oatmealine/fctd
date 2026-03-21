local class = require 'lib.lowerclass'

-- describes some machine you can push items into
---@class Pushable : Class
local Pushable = class('Pushable')

---@param side vector2D @ (1, 0), (0, 1), (-1, 0) or (0, -1)
function Pushable:canPushFromSide(side)
  return false
end

---@param item Item
---@param side vector2D @ (1, 0), (0, 1), (-1, 0) or (0, -1)
---@param dt number?
---@return boolean @ successful?
function Pushable:pushItem(item, side, dt)
  return false
end

return Pushable