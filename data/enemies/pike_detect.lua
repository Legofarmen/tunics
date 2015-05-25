local enemy = ...

local zentropy = require 'lib/zentropy'

-- Pike that moves when the hero is close.

local state = "stopped"  -- "stopped", "moving", "going_back" or "paused".
local initial_xy = {}
local activation_distance = 24
local last_direction4

function enemy:get_speed(direction4)
    local hero = enemy:get_game():get_hero()
    local hero_speed = hero:get_walking_speed() -- assume hero walking speed doesn't change
    local hero_w, hero_h = hero:get_size() -- assume hero size doesn't change
    local pike_w, pike_h = enemy:get_size()

    local door_distance, size
    if direction4 % 2 == 0 then
        door_distance = 120
        size = (hero_h + pike_h) / 2
    else
        door_distance = 80
        size = (hero_w + pike_w) / 2
    end
    return hero_speed * (door_distance - size) / (activation_distance + size)
end

function enemy:get_direction4(dest_x, dest_y)
    local x, y = self:get_position()
    local dx, dy = math.abs(dest_x - x), math.abs(dest_y - y)
    if dx < dy then
        if dx < activation_distance then
            if y < dest_y then
                return 3
            else
                return 1
            end
        else
            return nil
        end
    else
        if dy < activation_distance then
            if x < dest_x then
                return 0
            else
                return 2
            end
        else
            return nil
        end
    end
end

function enemy:on_created()

  self:set_life(1)
  self:set_damage(4)
  self:create_sprite("enemies/pike_detect")
  self:set_size(16, 16)
  self:set_origin(8, 13)
  self:set_can_hurt_hero_running(true)
  self:set_invincible()
  self:set_obstacle_behavior("flying")
  self:set_attack_consequence("sword", "protected")
  self:set_attack_consequence("thrown_item", "protected")
  self:set_attack_consequence("arrow", "protected")
  self:set_attack_consequence("hookshot", "protected")
  self:set_attack_consequence("boomerang", "protected")

  initial_xy.x, initial_xy.y = self:get_position()
end

function enemy:on_update()

    local hero = self:get_map():get_entity("hero")
    if state == "stopped" and self:is_in_same_region(hero) then
        local direction4 = self:get_direction4(hero:get_position())
        if direction4 then
            self:go(direction4)
        end
    end
end

function enemy:go(direction4)

  local dxy = {
    { x =  8, y =  0},
    { x =  0, y = -8},
    { x = -8, y =  0},
    { x =  0, y =  8}
  }

  -- Check that we can make the move.
  local index = direction4 + 1
  if not self:test_obstacles(dxy[index].x * 2, dxy[index].y * 2) then

    state = "moving"

    local x, y = self:get_position()
    local angle = direction4 * math.pi / 2
    local m = sol.movement.create("straight")
    m:set_speed(self:get_speed(direction4))
    m:set_angle(angle)
    m:set_max_distance(320)
    m:set_smooth(false)
    m:start(self)
  end
end

function enemy:on_obstacle_reached()

    sol.audio.play_sound("sword_tapping")
    self:go_back()
end

function enemy:on_movement_finished()

  self:go_back()
end

function enemy:on_collision_enemy(other_enemy, other_sprite, my_sprite)

    if other_enemy:get_breed() == self:get_breed() and state == "moving" then
        sol.audio.play_sound("sword_tapping")
        self:go_back()
    end
end

function enemy:go_back()

    if state == "moving" then

        state = "going_back"
        local direction4 = self:get_direction4(initial_xy.x, initial_xy.y)
        zentropy.assert(direction4)
        local m = sol.movement.create("target")
        m:set_speed(self:get_speed(direction4) / 3)
        m:set_target(initial_xy.x, initial_xy.y)
        m:set_smooth(false)
        m:start(self)

    elseif state == "going_back" then

        state = "paused"
        sol.timer.start(self, 500, function() self:unpause() end)
    end
end

function enemy:unpause()
  state = "stopped"
end
