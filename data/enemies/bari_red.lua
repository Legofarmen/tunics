local enemy = ...

-- Bari: a flying enemy that follows the hero
--       and tries to electrocute him.

local bari_mixin = require 'enemies/bari_mixin'

function enemy:on_created()
    self:set_life(3)
    self:set_damage(2)
    self:create_sprite("enemies/bari_red")
    self:set_size(16, 16)
    self:set_origin(8, 13)
    bari_mixin.mixin(self)
end

function enemy:on_dying()
    local function create_mini()
        local mini = enemy:create_enemy({ breed = "bari_mini" })
        mini:set_invincible(true) -- make mini survive the initial attack
        sol.timer.start(mini, 300, function ()
            mini:restart()
        end)
        return mini
    end
    -- It splits into two mini baris when it dies
    local mini1 = create_mini()
    local mini2 = create_mini()
    mini1:set_treasure(self:get_treasure())
    self:set_treasure()
end
