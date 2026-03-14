-- wrapper around love2d's RandomGenerator

---@alias int integer
---@alias float number
---@alias void nil

---@class rng 
---@field public state love.RandomGenerator
rng = {}

--- if `max` is not given, `min` will be used as the maximum and the minimum will be 1
--- if min is 1 and max is 4, the returned value can be 1, 2, 3 or 4
---@param min int
---@param max int?
---@return int
function rng:int(min, max)
  if not max then
    local m = min
    min = 1
    max = m
  end

  local _min = min
  local _max = max
  min = math.min(_min, _max)
  max = math.max(_min, _max)

  return self.state:random(min, max)
end

--- if `max` is not given, it will be 1
---@param max float?
---@return float
function rng:float(max)
  return self.state:random() * (max or 1)
end

---@return float
function rng:range(min, max)
  return min + self:float(max - min)
end

--- return either `-1` or `1`
---@return int
function rng:inv()
  return self:bool() and 1 or -1
end
--- returns a number in the range between `-1` and `1`
function rng:invF()
  return self:float() * 2 - 1
end

---@return boolean
function rng:bool()
  return self.state:random() < 0.5
end

---@param chance float
---@return boolean
function rng:chance(chance)
  return self.state:random() < chance
end

---@param seed string | number
function rng:seed(seed)
  if type(seed) == 'string' then
    self.state:setState(seed)
  else
    self.state:setSeed(seed)
  end
end

function rng:getState()
  return self.state:getState()
end

---@generic T
---@param tab T[]
---@return T
function rng:pick(tab)
  local idx = self:int(#tab)
  return tab[idx]
end

---@generic T
---@param tab table<T, number>
---@return T
function rng:weighted(tab)
  local sum = 0
  for k, v in pairs(tab) do
    sum = sum + v
  end
  local roll = self:float(sum)
  for k, v in pairs(tab) do
    roll = roll - v
    if roll < 0 then return k end
  end
  return tab[1]
end

---@return rng
function rng:clone()
  self.state:random()
  self.state:random()
  return rng.init(self.state:getState())
end

local rngmeta = {}

--- acts identical to math.random()
function rngmeta:__call(a, b)
  if a then
    return self:int(a, b)
  end
  return self:float()
end

rngmeta.__index = rng

--- creates a new RNG object
---@return rng
---@overload fun(low: number, high: number): rng
---@overload fun(state: string): rng
---@overload fun(seed: number): rng
function rng.init(low, high)
  local state
  if low and high then
    state = love.math.newRandomGenerator(low, high)
  elseif low then
    if type(low) == 'string' then
      state = love.math.newRandomGenerator()
      state:setState(low)
    else
      state = love.math.newRandomGenerator(low)
    end
  else
    state = love.math.newRandomGenerator(os.clock())
  end
  local this = setmetatable({state = state}, rngmeta)
  return this
end

return rng