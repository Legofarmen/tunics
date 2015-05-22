local enemy = ...

-- Bari: a flying enemy that follows the hero
--       and tries to electrocute him.

local bari_mixin = require 'enemies/bari_mixin'

function enemy:on_created()
    self:set_life(3)
    self:set_damage(3)
    self:create_sprite("enemies/bari_red")
    self:set_size(16, 16)
    self:set_origin(8, 13)
    bari_mixin.mixin(self)
    self:set_obstacle_behavior("flying")
    self:set_treasure()
end

function enemy:on_dying()
    local function create_mini(angle)
        sol.timer.start(1000, function ()
            local mini = enemy:create_enemy({ breed = "bari_mini" })
            local move = sol.movement.create("straight")
            move:set_angle(angle)
            move:set_max_distance(16)
            move:set_speed(64)
            move:start(mini)
            mini:set_invincible(true) -- make mini survive the initial attack
            sol.timer.start(mini, 300, function ()
                mini:shock()
            end)
            return mini
        end)
    end
    -- It splits into two mini baris when it dies
    local mini1 = create_mini(0)
    local mini2 = create_mini(math.pi)
        
end
