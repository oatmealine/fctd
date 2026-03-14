-- from https://github.com/oatmealine/jadelib

---@class vector2D A vector can be defined as a set of 2 coordinates. They can be obtained by doing either vect.x and vect.y or vect[1] and vect[2], for compatibility purposes.
---The reason such a simple class exists is to do simplified math with it - math abstracted as :length(), :angle(), etc is much easier to read.
---@field public x number @x coordinate
---@field public y number @y coordinate
---@operator add(vector2D): vector2D
---@operator add(number): vector2D
---@operator sub(vector2D): vector2D
---@operator sub(number): vector2D
---@operator mul(vector2D): vector2D
---@operator mul(number): vector2D
---@operator div(vector2D): vector2D
---@operator div(number): vector2D
---@operator unm: vector2D
local vect = {}

local ffi
local __construct, isVector, vec_t

if rawget(_G, 'jit') and jit.status() and package.preload.ffi then
	ffi = require('ffi')
	vec_t = ffi.typeof('struct {double x, y;}')

	---@param x? number
	---@param y? number
	function __construct(x, y)
		return vec_t(x or 0, y or 0) --[[@as vector2D]]
	end

	function isVector(a)
		return type(a) == 'cdata' and ffi.istype(a, vec_t)
	end
else
	---@param x? number
	---@param y? number
	function __construct(x, y)
		return setmetatable({x = x or 0, y = y or 0}, vect)
	end

	function isVector(a)
		return getmetatable(a) == vect
	end
end

-- basic operations

---@return number, number
function vect:unpack()
  return self.x, self.y
end

---@return number
function vect:length()
  return math.sqrt(self.x * self.x + self.y * self.y)
end

---@return number
function vect:lengthSquared()
  return self.x * self.x + self.y * self.y
end

---@return number @angle in degrees
function vect:angle()
  return math.deg(math.atan2(self.y, self.x))
end

-- modifications

---@return vector2D
function vect:normalize()
  local len = self:length()
  if len ~= 0 and len ~= 1 then
    return vect.new(self.x / len, self.y / len)
  else
    return self
  end
end

---@return vector2D
function vect:resize(x)
  local n = self:normalize()
  return vect.new(n.x * x, n.y * x)
end

---@param ang number @angle in degrees
---@return vector2D
function vect:rotate(ang)
  local a = self:angle()
  local len = self:length()
  return vect.fromAngle(a + ang, len)
end

---@param max number
---@return vector2D
function vect:trim(max)
	local s = max * max / (self.x * self.x + self.y * self.y)
	s = (s > 1 and 1) or math.sqrt(s)
	return vect.new(self.x * s, self.y * s)
end

---@param min number
---@param max number
---@return vector2D
function vect:clamp(min, max)
  local len = self:length()
  local newLength = math.min(math.max(len, min), max)
  if len == newLength then return self end
  return self:resize(newLength)
end

-- comparing w/ other vectors

---@param v2 vector2D
---@return number
function vect:distance(v2)
  return (self - v2):length()
end

---@param v2 vector2D
---@return number
function vect:distanceSquared(v2)
  return (self - v2):lengthSquared()
end

---@param v2 vector2D
---@return number
function vect:dot(v2)
  return self.x * v2.x + self.y * v2.y
end

---@param v2 vector2D
---@return number
function vect:cross(v2)
  return self.x * v2.y - self.y * v2.x
end

-- lua operations

local function typ(a)
  return isVector(a) and 'vector' or type(a)
end

local function genericop(f, name)
  return function(a, b)
    local typea = typ(a)
    local typeb = typ(b)
    if typea == 'number' then
      return vect.new(f(b.x, a), f(b.y, a))
    elseif typeb == 'number' then
      return vect.new(f(a.x, b), f(a.y, b))
    elseif typea == 'vector' and typeb == 'vector' then
      return vect.new(f(a.x, b.x), f(a.y, b.y))
    end
    error('cant apply ' .. name .. ' to ' .. typea .. ' and ' .. typeb, 3)
  end
end

local add = function(a, b) return a + b end
vect.__add = genericop(add, 'add')
local sub = function(a, b) return a - b end
vect.__sub = genericop(sub, 'sub')
local mul = function(a, b) return a * b end
vect.__mul = genericop(mul, 'mul')
local div = function(a, b) return a / b end
vect.__div = genericop(div, 'div')

function vect.__eq(a, b)
  return isVector(a) and isVector(b) and (a.x == b.x and a.y == b.y)
end

function vect:__unm()
  return vect.new(-self.x, -self.y)
end

function vect:__tostring()
  return '(' .. self.x .. ', ' .. self.y .. ')'
end
vect.__name = 'vector'

vect.__index = vect

if vec_t then
	-- FFI metatype set for FFI accelerated version
	ffi.metatype(vec_t, vect)
end

--- create a new vector
---@param x number | nil
---@param y number | nil
---@return vector2D
function vect.new(x, y)
  x = x or 0
  y = y or x
  return __construct(x, y)
end

--- create a new vector from an angle
---@param ang number | nil @angle in degrees
---@param amp number | nil
---@return vector2D
function vect.fromAngle(ang, amp)
  ang = math.rad(ang or 0)
  amp = amp or 1
  return vect.new(math.cos(ang) * amp, math.sin(ang) * amp)
end

---@param amp number?
---@param rng rng?
---@return vector2D
function vect.random(amp, rng)
  if not rng then
    return vect.fromAngle(math.random() * 360, amp)
  else
    return vect.fromAngle(rng:float(360), amp)
  end
end

-- the null vector; eg (0, 0)
vect.null = vect.new(0, 0)
-- the one vector; eg (1, 1)
vect.one = vect.new(1, 1)
-- the X unit vector; eg (1, 0)
vect.unitX = vect.new(1, 0)
-- the Y unit vector; eg (0, 1)
vect.unitY = vect.new(0, 1)

return vect