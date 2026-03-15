local class = require 'lib.lowerclass'

---@class Rotatable : Class
local Rotatable = class('Rotatable')

function Rotatable:__init(angle)
  self.angle = angle or 0
end

return Rotatable