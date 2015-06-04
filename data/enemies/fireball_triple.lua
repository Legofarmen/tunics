local la = require 'lib/la'

-- A bouncing triple fireball, usually shot by another enemy.

local fireball_triple = {}

function fireball_triple.init(enemy)

    local bounces = 0
    local used_sword = false
    local sprite2 = nil
    local sprite3 = nil
    local bounce = nil

    local function get_bounce_info(dir8, x, y)
        local wall = la.Vect2.direction8[(dir8 + 2) % 8]
        local normal = la.Vect2.direction8[(dir8 + 4) % 8]
        return {
            origin = la.Vect2:new{ x, y },
            normal = normal,
            mirror = la.Matrix2.reflect2(x, y, x + wall[1], y + wall[2]),
        }
    end

    local function get_bounce_angle(dir8, angle)
        return ((dir8 + 2) * math.pi / 2) - angle
    end

    local function is_outside(pos)
        return bounce and bounce.normal:dot(pos - bounce.origin) < 0
    end

    local function get_speed()
        return 48 * bounces + 192
    end

    function enemy:on_restarted()
        local hero_x, hero_y = self:get_map():get_entity("hero"):get_position()
        local angle = self:get_angle(hero_x, hero_y - 5)
        local m = sol.movement.create("straight")
        m:set_speed(get_speed())
        m:set_angle(angle)
        m:set_smooth(false)
        m:start(self)
    end

    function enemy:on_obstacle_reached()
        if bounces < self.max_bounces then
            -- Compute the bouncing angle (works well with horizontal and vertical walls).
            local m = self:get_movement()

            local dir = self:get_obstacle_direction8()
            if dir ~= -1 then
                m:set_angle(get_bounce_angle(dir, m:get_angle()))
                m:set_speed(192 + 48 * bounces)

                bounce = get_bounce_info(dir, self:get_position())
                bounces = bounces + 1
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
            m:set_speed(get_speed())
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

        local v2 = la.Vect2:new{x - math.cos(angle) * 12, y + math.sin(angle) * 12}
        if is_outside(v2) then v2 = bounce.mirror:vmul(v2) end
        self:get_map():draw_sprite(self.sprite2, v2[1], v2[2])

        local v3 = la.Vect2:new{x - math.cos(angle) * 24, y + math.sin(angle) * 24}
        if is_outside(v3) then v3 = bounce.mirror:vmul(v3) end
        self:get_map():draw_sprite(self.sprite3, v3[1], v3[2])
    end

    -- Method called by other enemies.
    function enemy:bounce()
        local m = self:get_movement()
        local angle = m:get_angle()
        angle = angle + math.pi

        m:set_angle(angle)
        m:set_speed(get_speed())
        used_sword = false
    end

    enemy:set_life(1)
    enemy:set_damage(4)
    enemy:set_obstacle_behavior("flying")
    enemy:set_invincible()
    enemy.max_bounces = enemy.max_bounces or 3
end

return fireball_triple
