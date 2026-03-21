local class = require 'lib.lowerclass'
local Tile = require 'src.scene.game.tiles.Tile'

---@class Wall : Tile
local Wall = class('Wall', Tile)

local sprites = {
  cafe = {
    spritesheet = assets.sprites.stage.cafe,
    floor = {
      { {0, 1} }
    },
    wall = {
      { {1, 3} },
      d = { {0, 2} },
      r = { {1, 2} },
      l = { {2, 2} },
      u = { {3, 2} },
      cdr = { {4, 2} },
      cdl = { {5, 2} },
      cur = { {6, 2} },
      cul = { {7, 2} },
      dl = { {4, 3} },
      ul = { {5, 3} },
      ur = { {6, 3} },
      dr = { {7, 3} },
    },
    wall_top = {
      { {0, 3} }
    },
    wood = {
      { {2, 0} },
      lr = { {0, 0}, {1, 0} },
      ud = { {3, 0}, {4, 0} },
    },
    table = {
      { {0, 4}, {1, 4}, {2, 4}, {3, 4} },
    },
    shelf = {
      { {4, 4}, {5, 4} },
    },
    bigshelf = {
      pr = { {6, 4} },
      pl = { {7, 4} },
    }
  },
  factory = {
    spritesheet = assets.sprites.stage.factory,
    floor = { {
      {0, 0}, {1, 0}, {2, 0},
      {0, 1}, {1, 1},
      -- pad out the pool
      {0, 1}, {0, 1}, {0, 1}, {0, 1}, {0, 1}, {0, 1},
    } },
    wall = {
      { {3, 4} },
      d = { {0, 3} },
      r = { {1, 3} },
      l = { {2, 3} },
      u = { {3, 3} },
      cdr = { {4, 3} },
      cdl = { {5, 3} },
      cur = { {6, 3} },
      cul = { {7, 3} },
      dl = { {4, 4} },
      ul = { {5, 4} },
      ur = { {6, 4} },
      dr = { {7, 4} },
    },
    wall_top = {
      { {2, 4} }
    },
    wall_pillar = {
      { {1, 4} }
    },
    wall_door = {
      { {0, 4} }
    },
    border = {
      { {0, 2} },
      lr = { {1, 2} },
      ud = { {2, 2} },
    },
    litter = {
      {
        {0, 5}, {1, 5}, {2, 5},
        {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}
      }
    },
    prop = {
      { {0, 6}, {1, 6} },
    },
  }
}

function Wall:__init(spriteRef, mirroredSpriteRef)
  Tile.__init(self)

  self.spriteRef = spriteRef
  self.mirroredSpriteRef = mirroredSpriteRef
  self.sprite = nil
  self.quad = nil
end

---@param other Wall
function Wall:shouldConnect(other)
  return self.spriteRef == other.spriteRef or self.spriteRef == other.mirroredSpriteRef
end

function Wall:update(dt)
  Tile.update(self, dt)
end

function Wall:awake()
  if not self.spriteRef then return end

  local x, y = self.pos:unpack()
  local z = self.z

  local ut = scenes.scene.game.getTile(x, y - 1, z)
  local u = scenes.scene.game.isOOB(x, y - 1) or (ut and ut:is(Wall) and self:shouldConnect(ut))

  local rt = scenes.scene.game.getTile(x + 1, y, z)
  local r = scenes.scene.game.isOOB(x + 1, y) or (rt and rt:is(Wall) and self:shouldConnect(rt))

  local dt = scenes.scene.game.getTile(x, y + 1, z)
  local d = scenes.scene.game.isOOB(x, y + 1) or (dt and dt:is(Wall) and self:shouldConnect(dt))

  local lt = scenes.scene.game.getTile(x - 1, y, z)
  local l = scenes.scene.game.isOOB(x - 1, y) or (lt and lt:is(Wall) and self:shouldConnect(lt))

  local subspr = 'o'

  if l then
    subspr = 'pl'
  end
  if r then
    subspr = 'pr'
  end
  if u then
    subspr = 'pu'
  end
  if d then
    subspr = 'pd'
  end
  if u and d then
    subspr = 'ud'
  end
  if l and r then
    subspr = 'lr'
  end
  if u and r then
    subspr = 'cdl'
  end
  if d and r then
    subspr = 'cul'
  end
  if u and l then
    subspr = 'cdr'
  end
  if d and l then
    subspr = 'cur'
  end
  if u and l and r then
    subspr = 'd'
  end
  if d and l and r then
    subspr = 'u'
  end
  if d and l and u then
    subspr = 'r'
  end
  if d and r and u then
    subspr = 'l'
  end
  if d and r and u and l then
    subspr = 'x'

    local urt = scenes.scene.game.getTile(x + 1, y - 1, z)
    local ur = scenes.scene.game.isOOB(x + 1, y - 1) or (urt and urt:is(Wall) and self:shouldConnect(urt))

    local drt = scenes.scene.game.getTile(x + 1, y + 1, z)
    local dr = scenes.scene.game.isOOB(x + 1, y + 1) or (drt and drt:is(Wall) and self:shouldConnect(drt))

    local ult = scenes.scene.game.getTile(x - 1, y - 1, z)
    local ul = scenes.scene.game.isOOB(x - 1, y - 1) or (ult and ult:is(Wall) and self:shouldConnect(ult))

    local dlt = scenes.scene.game.getTile(x - 1, y + 1, z)
    local dl = scenes.scene.game.isOOB(x - 1, y + 1) or (dlt and dlt:is(Wall) and self:shouldConnect(dlt))

    if ur and dr and ul and not dl then
      subspr = 'dl'
    end
    if dr and ul and dl and not ur then
      subspr = 'ur'
    end
    if ur and ul and dl and not dr then
      subspr = 'dr'
    end
    if ur and dr and dl and not ul then
      subspr = 'ul'
    end
  end

  local segments = split(self.spriteRef, '.')
  local sheet = sprites[segments[1]]
  if not sheet then
    self.spriteRef = nil
    return
  end

  self.sprite = sheet.spritesheet

  local sprite = sheet[segments[2]]
  if not sprite then
    return
  end

  local refs = sprite[subspr] or sprite[1]
  if #refs == 0 then
    return
  end

  local ref = refs[math.random(#refs)]
  if not ref[1] then
    self.spriteRef = nil
    return
  end
  self.quad = love.graphics.newQuad(ref[1] * 32, ref[2] * 32, 32, 32, self.sprite)
end

function Wall:toMirrored()
  return Wall(self.mirroredSpriteRef, self.spriteRef)
end

function Wall:drawInner()
  if not self.spriteRef then
    return
  end
  if self.sprite and self.quad then
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(self.sprite, self.quad)
  else
    love.graphics.setColor(1, 0, 1, 1)
    love.graphics.rectangle('fill', 0, 0, 32, 32)
  end
end

return Wall