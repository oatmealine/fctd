-- from https://github.com/oatmealine/jadelib

---@generic T
---@param a T
---@param b T
---@param x number
---@return T
function mix(a, b, x)
  return a + (b - a) * x
end

function stacktrace()
  for i = 2, 100 do
    local info = debug.getinfo(i, 'nSl')
    if not info then return end
    log.debug((info.name or '?') .. ' defined at ' .. (info.source or '?') .. ':' .. (info.currentline or '?'))
  end
  log.debug('...rest cut off')
end

---@param n number
---@return number
function round(n)
  return math.floor(n + 0.5)
end

---@param x number
---@return number
function sign(x)
  if x < 0 then return -1 end
  if x > 0 then return 1 end
  return 0
end

---@param x number
---@return number
function signStrict(x)
  if x < 0 then return -1 end
  return 1
end

---@param x number
---@param a number
---@param b number
---@return number
function clamp(x, a, b)
  return math.max(math.min(x, math.max(a, b)), math.min(a, b))
end

---@param o any
---@param r number?
---@return string
function fullDump(o, r, forceFull)
  if type(o) == 'table' and (not r or r > 0) then
    local s = '{'
    local first = true
    for k,v in pairs(o) do
      if not first then
        s = s .. ', '
      end
      local nr = nil
      if r then
        nr = r - 1
      end
      if type(k) ~= 'number' or forceFull then
        s = s .. tostring(k) .. ' = ' .. fullDump(v, nr)
      else
        s = s .. fullDump(v, nr)
      end
      first = false
    end
    return s .. '}'
  elseif type(o) == 'string' then
    return '"' .. o .. '"'
  else
    return tostring(o)
  end
end

---@param x number
---@return number
function pingpong(x)
  return math.abs(x % 2 - 1)
end

---@param x number
---@param snap number
---@return number
function snap(x, snap)
  return math.floor(x / snap + 0.5) * snap
end

---@param inputstr string
---@param sep string
---@return string[]
function split(inputstr, sep)
  if sep == nil then
    sep = "%s"
  end
  local t={} ; local i=1
  for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
    t[i] = str
    i = i + 1
  end
  return t
end

---@param str string
---@param len number
---@param char string
function lpad(str, len, char)
  if char == nil then char = ' ' end
  return string.rep(char, len - #str) .. str
end

---@param str string
---@return number[]
function hashstr(str)
  local sums = {0, 0, 0, 0}
  for i = 1, #str do
    local c = str:sub(i,i)
    local sumI = (i - 1) % #sums + 1
    sums[sumI] = bit.bxor(sums[sumI], string.byte(c))
  end
  return sums
end

function escapeLuaPattern(str)
  return str:gsub("([%^%$%(%)%.%[%]%*%+%-%?])","%%%1")
end

function replace(s, oldValue, newValue)
  return string.gsub(s, escapeLuaPattern(oldValue), newValue)
end

function startsWith(str, sub)
  return str:sub(1, #sub) == sub
end

function endsWith(str, sub)
  return str:sub(-#sub) == sub
end

local whitespaces = {' ', '\n', '\r'}

---@param str string
function trimLeft(str)
  while includes(whitespaces, string.sub(str, 1, 1)) do
    str = string.sub(str, 2)
  end
  return str
end

---@param str string
function trimRight(str)
  while includes(whitespaces, string.sub(str, -1, -1)) do
    str = string.sub(str, 1, -2)
  end
  return str
end

---@param str string
function trim(str)
  return trimRight(trimLeft(str))
end

---@generic T table<any>
---@param tab T
---@return T
function deepcopy(tab)
  local new = {}
  for k, v in pairs(tab) do
    if type(v) == 'table' then
      local mt = getmetatable(v)
      new[k] = deepcopy(v)
      if mt then
        setmetatable(new[k], deepcopy(mt))
      end
    else
      new[k] = v
    end
  end
  return new
end

function setAlpha(tab, a)
  return {tab[1], tab[2], tab[3], a}
end

function slice(tbl, s, e)
  s = s or 0
  e = e or #tbl
  local pos, new = 1, {}

  for i = s, e do
    new[pos] = tbl[i]
    pos = pos + 1
  end

  return new
end

function joinTable(tab1, tab2)
  local tab3 = {}
  for _, v in ipairs(tab1) do
    table.insert(tab3, v)
  end
  for _, v in ipairs(tab2) do
    table.insert(tab3, v)
  end
  return tab3
end

-- prefers tab1 with type mismatches; prefers tab2 with value mismatches
function mergeTable(tab1, tab2)
  local tab = {}
  for k, v1 in pairs(tab1) do
    local v2 = tab2[k]
    if type(v1) ~= type(v2) then
      tab[k] = v1
    else
      if type(v1) == 'table' then
        tab[k] = mergeTable(v1, v2)
      else
        tab[k] = v2
      end
    end
  end
  return tab
end

-- always prefers tab2 unless it is nil
function mergeTableLenient(tab1, tab2)
  local tab = {}
  for k, v in pairs(tab1) do
    tab[k] = v
  end
  for k, v in pairs(tab2) do
    if type(v) == 'table' and type(tab[k]) == 'table' then
      tab[k] = mergeTableLenient(tab[k], v)
    elseif v ~= nil then
      tab[k] = v
    end
  end
  return tab
end

function countKeys(t)
  local n = 0
  for _ in pairs(t) do
    n = n + 1
  end
  return n
end

-- https://stackoverflow.com/a/10992898
function formatNum(number)
  local i, j, minus, int, fraction = tostring(number):find('([-]?)(%d+)([.]?%d*)')

  -- reverse the int-string and append a comma to all blocks of 3 digits
  int = int:reverse():gsub('(%d%d%d)', '%1,')

  -- reverse the int-string back remove an optional comma and put the 
  -- optional minus and fractional part back
  return minus .. int:reverse():gsub("^,", "") .. fraction
end

function formatTime(s)
  local second = math.floor(s % 60)
  local minute = math.floor(s / 60) % 60
  local hour = math.floor(minute / 60) % 60

  return padLeft(hour, '0', 2) .. ':' .. padLeft(minute, '0', 2) .. ':' .. padLeft(second, '0', 2)
end

-- https://gamedev.stackexchange.com/a/4472
function angleDiff(a1, a2)
  return 180 - math.abs(math.abs(a1 - a2) - 180)
end

function benchmark()
  local start = os.clock()
  return function()
    return string.format('%.2fms', (os.clock() - start) * 1000)
  end
end

---@generic K
---@param tab table<K, number>
---@param rng rng?
---@return K
function pickWeighted(tab, rng)
  local sum = 0
  for _, v in pairs(tab) do
    sum = sum + v
  end
  local roll = (rng and rng:float() or math.random()) * sum
  for k, v in pairs(tab) do
    roll = roll - v
    if roll <= 0 then return k end
  end
  log.warn('got invalid result for pickWeighted')
  log.warn('tab:', fullDump(tab))
  stacktrace()
  return nil
end

---@generic T
---@param tbl T[]
---@return T[]
function shuffle(tbl)
  for i = #tbl, 2, -1 do
    local j = math.random(i)
    tbl[i], tbl[j] = tbl[j], tbl[i]
  end
  return tbl
end

function plur(n)
  if n ~= 1 then return 's' end
  return ''
end