local class = require 'lib.lowerclass'

-- describes some machine you can pull items from
---@class Pullable : Class
local Pullable = class('Pullable')

---@param side vector2D @ (1, 0), (0, 1), (-1, 0) or (0, -1)
function Pullable:canPullFromSide(side)
  return false
end

---@param side vector2D @ (1, 0), (0, 1), (-1, 0) or (0, -1)
---@return Item?
function Pullable:pullItem(side)
end

return Pullable