local class = require 'lib.lowerclass'

local registry = {
  dough = {
    sprite = assets.sprites.items.dough,
    cooked = 'cake'
  },
  frozen_dough = {
    sprite = assets.sprites.items.frozen_dough,
    cooked = 'dough',
  },
  cake = {
    sprite = assets.sprites.items.cake,
  },
  ash = {
    sprite = assets.sprites.items.ash,
  }
}

---@class Item : Class
local Item = class('Item')

function Item:__init(id)
  self.id = id
  self.data = registry[id]
  if not self.data then
    log.warn('no item with id ' + id)
    self.data = {}
  end

  self.spawnAnim = 0
end

function Item:transform(id)
  self.id = id
  self.data = registry[id]
  if not self.data then
    log.warn('no item with id ' + id)
    self.data = {}
  end
end

function Item:cook()
  self:transform(self.data.cooked or 'ash')
end

function Item:playSpawnAnim()
  self.spawnAnim = 1
end

function Item:update(dt)
  self.spawnAnim = self.spawnAnim - dt / 0.6
end

function Item:draw()
  love.graphics.push()
  if self.spawnAnim > 0 then
    love.graphics.scale(0.5 + 0.5 * outElastic(1 - self.spawnAnim))
  end
  love.graphics.scale(0.7)

  local spr = self.data.sprite or assets.sprites.items.missing
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(spr, 0, 0, 0, 1, 1, spr:getWidth()/2, spr:getHeight()/2)

  love.graphics.pop()
end

return Item