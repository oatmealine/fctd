-- from https://github.com/oatmealine/jadelib

local color = require 'lib.color'

local self = {}

local function isEscaped(str, i)
  if i <= 0 or i > #str then return false end
  local charBefore = string.utf8sub(str, i - 1, i - 1)
  if charBefore == '\\' then
    return not isEscaped(str, i - 1)
  else
    return false
  end
end

---@generic T table<any>
---@param tab T
---@return T
local function deepcopy(tab)
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

---@class TextState
---@field letterIsShaky boolean
---@field letterIsBold boolean
---@field letterIsItalic boolean
---@field letterIsWavy boolean
---@field letterIsHighlighted boolean
---@field letterDelayedBy number

---@alias TextChunk {text: string, state: TextState, width: number, textObj: love.Text}

---@param str string
---@param maxWidth number
---@param font? love.Font
---@return TextChunk[][]
function self.parse(str, maxWidth, font)
  font = font or love.graphics.getFont()

  ---@type TextState
  local textState = {
    letterIsShaky = false,
    letterIsBold = false,
    letterIsItalic = false,
    letterIsWavy = false,
    letterIsHighlighted = false,
    letterDelayedBy = 0,

    -- internal
    letterMightBeBold = false
  }

  local statesTable = {}

  local stringsTable = {}
  local textBuffer = {}

  local stateModified = false
  local newState = deepcopy(textState)

  local realIndex = 0
  for i = 1, #str do
    local char = string.utf8sub(str, i, i)
    local prevChar = string.utf8sub(str, i - 1, i - 1)
    local escaped = isEscaped(str, i)

    if char == '[' and not escaped then
      newState.letterIsHighlighted = true
      stateModified = true
    elseif char == ']' and not escaped then
      newState.letterIsHighlighted = false
      stateModified = true
    elseif char == '_' and not escaped then
      newState.letterIsItalic = not newState.letterIsItalic
      stateModified = true
    elseif char == '~' and not escaped then
      newState.letterIsWavy = not newState.letterIsWavy
      stateModified = true
    elseif char == '*' and not escaped then
      if newState.letterMightBeBold then
        newState.letterIsBold = not newState.letterIsBold
        newState.letterMightBeBold = false
        stateModified = true
      else
        newState.letterMightBeBold = true
      end
    elseif char == '|' and not escaped then
      newState.letterDelayedBy = newState.letterDelayedBy + 1
      stateModified = true
    elseif not (char == '\\' and not escaped) then
      realIndex = realIndex + 1

      if newState.letterMightBeBold then
        newState.letterMightBeBold = false
        newState.letterIsShaky = not newState.letterIsShaky
        stateModified = true
      end

      if char == ' ' and (prevChar == '!' or prevChar == '?' or prevChar == '.' or prevChar == ',' or prevChar == ';') then
        newState.letterDelayedBy = newState.letterDelayedBy + (prevChar == ',' and 1 or 3)
        stateModified = true
      end

      if stateModified then
        stateModified = false
        if #textBuffer ~= 0 then
          --print(table.concat(textBuffer), forceToString(textState))
          table.insert(stringsTable, table.concat(textBuffer))
          table.insert(statesTable, deepcopy(textState))
          textBuffer = {}
        end
        textState = newState
        newState = deepcopy(textState)
        if newState.letterDelayedBy > 0 then
          newState.letterDelayedBy = 0
          stateModified = true
        end
      end
      table.insert(textBuffer, char)
    end
  end

  if #textBuffer ~= 0 then
    table.insert(stringsTable, table.concat(textBuffer))
    table.insert(statesTable, deepcopy(textState))
    textBuffer = {}
  end

  -- step 1: split everything into words (space-seperated tables of text/state)
  -- inbetween words there also sit the characters that broke those into words,
  -- in the form of a `after =` entry in the word table elements

  ---@type {[1]: ({[1]: string, [2]: TextState}[]), after: string}[]
  local words = {}
  do
    ---@type {[1]: string, [2]: TextState}[]
    local wordBuffer = {}
    for strI, chunk in ipairs(stringsTable) do
      for i = 1, string.utf8len(chunk) do
        local char = string.utf8sub(chunk, i, i)
        if char == ' ' or char == '\n' then
          table.insert(words, {wordBuffer, after = char})
          wordBuffer = {}
        else
          table.insert(wordBuffer, {char, statesTable[strI]})
        end
      end
    end
    if #wordBuffer > 0 then
      table.insert(words, {wordBuffer, after = nil})
    end
  end


  -- step 2: lay it out into lines
  -- this will also require calculating the width of each word, which is.. fun

  ---@type {[1]: ({[1]: string, [2]: TextState}[]), after: string}[][]
  local lines = {{}}

  do
    local x = 0
    local line = 1

    for _, word in ipairs(words) do
      local stringified = {}
      for _, c in ipairs(word[1]) do table.insert(stringified, c[1]) end
      if word.after then
        table.insert(stringified, word.after)
      end
      local width = font:getWidth(table.concat(stringified))

      if x + width > maxWidth then
        -- place THIS word on next line
        x = 0
        line = line + 1
        lines[line] = {}
      end

      table.insert(lines[line], word)
      x = x + width

      if word.after == '\n' then
        -- place NEXT word on next line
        x = 0
        line = line + 1
        lines[line] = {}
      end
    end
  end

  -- step 3: join them back together
  -- we also need to merge the states whenever possible

  local formattedLines = {}

  do
    for _, line in ipairs(lines) do
      local lastState
      local chunks = {}
      local chunksBuffer = {}
      for _, word in ipairs(line) do
        for _, char in ipairs(word[1]) do
          if lastState and char[2] ~= lastState then
            table.insert(chunks, { text = table.concat(chunksBuffer), state = lastState })
            chunksBuffer = {}
          end
          lastState = char[2]
          table.insert(chunksBuffer, char[1])
        end
        if word.after and word.after ~= '\n' then table.insert(chunksBuffer, word.after) end
      end
      if #chunksBuffer > 0 then
        table.insert(chunks, { text = table.concat(chunksBuffer), state = lastState })
      end

      table.insert(formattedLines, chunks)
    end
  end

  -- step 4: widths

  for _, line in ipairs(formattedLines) do
    for _, chunk in ipairs(line) do
      local text = love.graphics.newText(font, chunk.text)
      chunk.width = text:getWidth()
      chunk.textObj = text
    end
  end

  return formattedLines
end

---@param parsed TextChunk[][]
---@param highlightCol color
---@param align love.AlignMode?
function self.draw(parsed, highlightCol, align)
  local defaultCol = color.fromRGB(love.graphics.getColor())
  local font = love.graphics.getFont()

  local x = 0
  local y = 0

  for _, line in ipairs(parsed) do
    if align ~= 'left' then
      local lineWidth = 0
      for _, chunk in ipairs(line) do
        lineWidth = lineWidth + chunk.width
      end
      if align == 'center' then
        x = -lineWidth/2
      end
      if align == 'right' then
        x = -lineWidth
      end
    end

    for _, chunk in ipairs(line) do
      local offsetX = 0
      local skewX = 0
      local color = defaultCol
      if chunk.state.letterIsHighlighted then
        color = highlightCol
      end
      if chunk.state.letterIsItalic then
        offsetX = 4
        skewX = -0.2
      end

      love.graphics.setColor(color:unpack())
      love.graphics.draw(chunk.textObj, x + offsetX, y, 0, 1, 1, 0, 0, skewX, 0)
      if chunk.state.letterIsBold then
        love.graphics.setColor(color:malpha(0.5):unpack())
        for _, v in ipairs({{1, 0}, {-1, 0}, {0, 1}, {0, -1}}) do
          love.graphics.draw(chunk.textObj, x + offsetX + v[1]*0.5, y + v[2]*0.5, 0, 1, 1, 0, 0, skewX, 0)
        end
      end
      x = x + chunk.width
    end
    x = 0
    y = y + font:getHeight() * font:getLineHeight()
  end
end

return self