local enemy = ...

local la = require 'lib/la'
local zentropy = require 'lib/zentropy'

-- A bouncing triple fireball, usually shot by another enemy.

local speed = 192
local bounces = 0
local max_bounces = 3
local used_sword = false
local sprite2 = nil
local sprite3 = nil

function enemy:on_created()
    zentropy.debug('on_created')
    self:set_life(1)
    self:set_damage(8)
    self:create_sprite("enemies/fireball_triple")
    self:set_size(16, 16)
    self:set_origin(8, 8)
    self:set_obstacle_behavior("flying")
    self:set_invincible()
    self:set_attack_consequence("sword", "custom")

    -- Two smaller fireballs just for the displaying.
    sprite2 = sol.sprite.create("enemies/fireball_triple")
    sprite2:set_animation("small")
    sprite3 = sol.sprite.create("enemies/fireball_triple")
    sprite3:set_animation("tiny")
end

function enemy:on_restarted()
    zentropy.debug('on_restarted')
    local hero_x, hero_y = self:get_map():get_entity("hero"):get_position()
    local angle = self:get_angle(hero_x, hero_y - 5)
    local m = sol.movement.create("straight")
    m:set_speed(speed)
    m:set_angle(angle)
    m:set_smooth(false)
    m:start(self)
end

local directions = {
    --[0]
    [1]='nw',
    [2]='ne',
    [3]='n',
    [4]='sw',
    [5]='w',
    --[6]
    [7]='nw',
    [8]='se',
    --[9]
    [10]='e',
    [11]='ne',
    [12]='s',
    [13]='sw',
    [14]='se',
    --[15]
}

function enemy:get_obstacle_direction()
    local bits = 0
    if self:test_obstacles(-1, -1) then
        bits = bits + 1
    end
    if self:test_obstacles( 1, -1) then
        bits = bits + 2
    end
    if self:test_obstacles(-1,  1) then
        bits = bits + 4
    end
    if self:test_obstacles( 1,  1) then
        bits = bits + 8
    end
    if not directions[bits] then zentropy.debug('NO DIRECTION ' .. bits) end
    return directions[bits]
end

function minrad(angle)
    while angle <= -math.pi do
        angle = angle + 2 * math.pi
    end
    while angle > math.pi do
        angle = angle - 2 * math.pi
    end
    return angle
end

local bouncer = {}
function bouncer.n(angle, x, y)
    return {
        mirror = la.Matrix2.reflect2(x, y, x + 1, y),
        angle = -angle,
        xy = la.Vect2:new{ x, y },
        normal = la.Vect2:new{ 0, 1 },
    }
end
function bouncer.s(angle, x, y)
    return {
        mirror = la.Matrix2.reflect2(x, y, x + 1, y),
        angle = -angle,
        xy = la.Vect2:new{ x, y },
        normal = la.Vect2:new{ 0, -1 },
    }
end
function bouncer.e(angle, x, y)
    return {
        mirror = la.Matrix2.reflect2(x, y, x, y + 1),
        angle = math.pi - angle,
        xy = la.Vect2:new{ x, y },
        normal = la.Vect2:new{ -1, 0 },
    }
end
function bouncer.w(angle, x, y)
    return {
        mirror = la.Matrix2.reflect2(x, y, x, y + 1),
        angle = math.pi - angle,
        xy = la.Vect2:new{ x, y },
        normal = la.Vect2:new{ 1, 0 },
    }
end
function bouncer.se(angle, x, y)
    return {
        mirror = la.Matrix2.reflect2(x, y, x + 1, y + 1),
        angle = -angle + math.pi/2,
        xy = la.Vect2:new{ x, y },
        normal = la.Vect2:new{ -1, -1 },
    }
end
function bouncer.ne(angle, x, y)
    return {
        mirror = la.Matrix2.reflect2(x, y, x - 1, y + 1),
        angle = -angle - math.pi/2,
        xy = la.Vect2:new{ x, y },
        normal = la.Vect2:new{ -1, 1 },
    }
end
function bouncer.sw(angle, x, y)
    return {
        mirror = la.Matrix2.reflect2(x, y, x + 1, y + 1),
        angle = -angle - math.pi/2,
        xy = la.Vect2:new{ x, y },
        normal = la.Vect2:new{ 1, -1 },
    }
end
function bouncer.nw(angle, x, y)
    return {
        mirror = la.Matrix2.reflect2(x, y, x - 1, y + 1),
        angle = -angle + math.pi/2,
        xy = la.Vect2:new{ x, y },
        normal = la.Vect2:new{ 1, 1 },
    }
end

function enemy:on_obstacle_reached()
    zentropy.debug('on_obstacle_reached')
    if bounces < max_bounces then
        -- Compute the bouncing angle (works well with horizontal and vertical walls).
        local m = self:get_movement()

        local dir = self:get_obstacle_direction()
        zentropy.assert(dir)
        local info = bouncer[dir](minrad(m:get_angle()), self:get_position())

        m:set_angle(info.angle)
        m:set_speed(speed)

        bounces = bounces + 1
        speed = speed + 48
    else
        zentropy.debug('remove2')
        self:remove()
    end
end

function enemy:on_custom_attack_received(attack, sprite)
  if attack == "sword" then
    local hero_x, hero_y = self:get_map():get_entity("hero"):get_position()
    local angle = self:get_angle(hero_x, hero_y - 5) + math.pi
    local m = sol.movement.create("straight")
    m:set_angle(angle)
    m:set_speed(speed)
    m:set_smooth(false)
    m:start(self)
    sol.audio.play_sound("boss_fireball")
    used_sword = true
  end
end

function enemy:on_collision_enemy(other_enemy, other_sprite, my_sprite)
  if used_sword then
    if other_enemy.receive_bounced_fireball ~= nil then
      other_enemy:receive_bounced_fireball(self)
    end
  end
end

function enemy:on_pre_draw()
  local m = self:get_movement()
  local angle = m:get_angle()
  local x, y = self:get_position()

  local x2 = x - math.cos(angle) * 12
  local y2 = y + math.sin(angle) * 12

  local x3 = x - math.cos(angle) * 24
  local y3 = y + math.sin(angle) * 24

  self:get_map():draw_sprite(sprite2, x2, y2)
  self:get_map():draw_sprite(sprite3, x3, y3)
end

-- Method called by other enemies.
function enemy:bounce()
  zentropy.debug('bounce')
  local m = self:get_movement()
  local angle = m:get_angle()
  angle = angle + math.pi

  m:set_angle(angle)
  m:set_speed(speed)
  used_sword = false
end
