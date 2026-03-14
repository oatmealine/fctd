-- from https://github.com/oatmealine/jadelib

---@class tweenable
---@field eased number
---@field target number
---@field private time number
---@field private tweens { current: number, target: number, ease: fun(n:number):(number), transient: boolean, from: number, to: number, additive: boolean }[]
local tweenable = {}

--- move towards a new target
function tweenable:tween(target, ease, dur)
  local transient = ease(1) < 0.5
  table.insert(self.tweens, {
    current = self.target,
    target = target,
    ease = ease,
    from = self.time,
    to = self.time + dur,
    additive = false,
    transient = ease(1) < 0.5,
  })
  if not transient then self.target = target end
end

--- move towards a new target additively
function tweenable:add(target, ease, dur)
  local transient = ease(1) < 0.5
  table.insert(self.tweens, {
    current = self.target,
    target = target,
    ease = ease,
    from = self.time,
    to = self.time + dur,
    additive = true,
    transient = transient,
  })
  if not transient then self.target = self.target + target end
end

--- set both the eased value and the target
function tweenable:reset(n)
  self.target = n
  self.eased = n
  self.tweens = {}
end

---@param dt number
function tweenable:update(dt)
  self.time = self.time + dt

  self.eased = self.target

  for i = #self.tweens, 1, -1 do
    local tween = self.tweens[i]

    if self.time < tween.to then
      local a = (self.time - tween.from) / (tween.to - tween.from)
      local b = tween.ease(a)

      if tween.transient then
        self.eased = self.eased + b * (tween.target - self.eased)
      else
        self.eased = self.eased - (1 - b) * (tween.target - tween.current)
      end
    else
      table.remove(self.tweens, i)
    end
  end
end

function tweenable:__tostring()
  return 'tweenable (' .. self.eased .. ' towards ' .. self.target .. ', ' .. #self.tweens .. ' tweens)'
end

tweenable.__index = tweenable
tweenable.__name = 'tweenable'

---@return tweenable
return function(default)
  return setmetatable({
    eased = default,
    target = default,
    time = 0,
    tweens = {}
  }, tweenable)
end