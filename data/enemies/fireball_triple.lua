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
local info = nil

function enemy:on_created()
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
    local hero_x, hero_y = self:get_map():get_entity("hero"):get_position()
    local angle = self:get_angle(hero_x, hero_y - 5)
    local m = sol.movement.create("straight")
    m:set_speed(speed)
    m:set_angle(angle)
    m:set_smooth(false)
    m:start(self)
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

local directions = {
    'ne', 'n', 'nw', 'w', 'sw', 's', 'se', [0] = 'e'
}

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
        mirror = la.Matrix2.reflect2(x, y, x + 1, y - 1),
        angle = -angle + math.pi/2,
        xy = la.Vect2:new{ x, y },
        normal = la.Vect2:new{ -1, -1 },
    }
end
function bouncer.ne(angle, x, y)
    return {
        mirror = la.Matrix2.reflect2(x, y, x + 1, y + 1),
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
        mirror = la.Matrix2.reflect2(x, y, x + 1, y - 1),
        angle = -angle + math.pi/2,
        xy = la.Vect2:new{ x, y },
        normal = la.Vect2:new{ 1, 1 },
    }
end

function enemy:on_obstacle_reached()
    if bounces < max_bounces then
        -- Compute the bouncing angle (works well with horizontal and vertical walls).
        local m = self:get_movement()

        local dir = self:get_obstacle_direction8()
        if dir ~= -1 then
            print(dir, directions[dir])
            info = bouncer[directions[dir]](minrad(m:get_angle()), self:get_position())

            m:set_angle(info.angle)
            m:set_speed(speed)

            bounces = bounces + 1
            speed = speed + 48
        end
    else
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

function is_outside(xy)
    return info and la.Vect2:new{xy[1] - info.xy[1], xy[2] - info.xy[2]}:dot(info.normal) < 0
end

function enemy:on_pre_draw()
    local m = self:get_movement()
    local angle = m:get_angle()
    local x, y = self:get_position()

    local v2 = la.Vect2:new{x - math.cos(angle) * 12, y + math.sin(angle) * 12}
    if is_outside(v2) then v2 = info.mirror:vmul(v2) end
    self:get_map():draw_sprite(sprite2, v2[1], v2[2])
    --if is_outside(v2) then self:get_map():draw_sprite(sprite2, v2[1], v2[2]) end

    local v3 = la.Vect2:new{x - math.cos(angle) * 24, y + math.sin(angle) * 24}
    if is_outside(v3) then v3 = info.mirror:vmul(v3) end
    self:get_map():draw_sprite(sprite3, v3[1], v3[2])
    --if is_outside(v3) then self:get_map():draw_sprite(sprite3, v3[1], v3[2]) end
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
