local enemy = ...

local la = require 'lib/la'

-- A bouncing triple fireball, usually shot by another enemy.

local speed = 192
local bounces = 0
local max_bounces = 3
local used_sword = false
local sprite2 = nil
local sprite3 = nil

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

function enemy:on_position_changed()
    self.last = 'position'
end
function enemy:on_obstacle_reached()
  if bounces < max_bounces and self.last ~= 'obstacle' then
    -- Compute the bouncing angle (works well with horizontal and vertical walls).
    local m = self:get_movement()
    local angle = m:get_angle()

    self.bounce_xy = la.Vect2:new{ self:get_position() }
    if angle < -math.pi then
        angle = angle + math.pi
    elseif angle > math.pi then
        angle = angle - math.pi
    end
    print('before', math.deg(angle))
    if self:test_obstacles(1, 0) then
        if self:test_obstacles(0, 1) then
            self.mirror = la.Matrix2.reflect2(self.bounce_xy[1], self.bounce_xy[2], self.bounce_xy[1] + 1, self.bounce_xy[2] + 1)
            self.normal = la.Vect2:new{ -1, -1 }
            angle = -angle + math.pi/2
            print('SE')
        elseif self:test_obstacles(0, -1) then
            self.mirror = la.Matrix2.reflect2(self.bounce_xy[1], self.bounce_xy[2], self.bounce_xy[1] - 1, self.bounce_xy[2] + 1)
            self.normal = la.Vect2:new{ -1, 1 }
            angle = -angle - math.pi/2
            print('NE')
        else
            self.mirror = la.Matrix2.reflect2(self.bounce_xy[1], self.bounce_xy[2], self.bounce_xy[1], self.bounce_xy[2] + 1)
            self.normal = la.Vect2:new{ -1, 0 }
            angle = math.pi - angle
            print('E')
        end
    elseif self:test_obstacles(-1, 0) then
        if self:test_obstacles(0, 1) then
            self.mirror = la.Matrix2.reflect2(self.bounce_xy[1], self.bounce_xy[2], self.bounce_xy[1] + 1, self.bounce_xy[2] + 1)
            self.normal = la.Vect2:new{ 1, -1 }
            angle = -angle - math.pi/2
            print('SW')
        elseif self:test_obstacles(0, -1) then
            self.mirror = la.Matrix2.reflect2(self.bounce_xy[1], self.bounce_xy[2], self.bounce_xy[1] - 1, self.bounce_xy[2] + 1)
            self.normal = la.Vect2:new{ 1, 1 }
            angle = -angle + math.pi/2
            print('NW')
        else
            self.mirror = la.Matrix2.reflect2(self.bounce_xy[1], self.bounce_xy[2], self.bounce_xy[1], self.bounce_xy[2] + 1)
            self.normal = la.Vect2:new{ 1, 0 }
            angle = math.pi - angle
            print('W')
        end
    elseif self:test_obstacles(0, 1) then
        self.mirror = la.Matrix2.reflect2(self.bounce_xy[1], self.bounce_xy[2], self.bounce_xy[1] + 1, self.bounce_xy[2])
        self.normal = la.Vect2:new{ 0, -1 }
        angle = -angle
        print('S')
    elseif self:test_obstacles(0, -1) then
        self.mirror = la.Matrix2.reflect2(self.bounce_xy[1], self.bounce_xy[2], self.bounce_xy[1] + 1, self.bounce_xy[2])
        self.normal = la.Vect2:new{ 0, 1 }
        angle = -angle
        print('N')
    end
    print('after', math.deg(angle))

    m:set_angle(angle)
    m:set_speed(speed)

    bounces = bounces + 1
    speed = speed + 48
  else
    self:remove()
  end
  self.last = 'obstacle'
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
  local m = self:get_movement()
  local angle = m:get_angle()
  angle = angle + math.pi

  m:set_angle(angle)
  m:set_speed(speed)
  used_sword = false
end
