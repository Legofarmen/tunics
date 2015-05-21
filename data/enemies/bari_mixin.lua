local bari_mixin = {}

function bari_mixin.mixin(enemy)

    local game = enemy:get_game()

    function enemy:set_shocking(shocking)
        if shocking then
            self:get_sprite():set_animation("shaking")
        else
            self:get_sprite():set_animation("walking")
        end
    end

    function enemy:is_shocking()
        return self:get_sprite():get_animation() == "shaking"
    end

    function enemy:shock()
        self:stop_movement()
        self:set_shocking(true)
        sol.timer.start(self, 1000 + 1500 * math.random(), function()
            self:set_shocking(false)
            self:restart()
        end)
    end

    function enemy:on_restarted()
        shocking = false
        self:set_default_attack_consequences()
        self:set_attack_consequence("hookshot", "immobilized")
        local m = sol.movement.create("path_finding")
        m:set_speed(32)
        m:start(self)
        sol.timer.start(enemy, 2000 + 8000 * math.random(), function()
            self:shock()
        end)
    end

    function enemy:on_immobilized()
        self:set_shocking(false)
    end

    function enemy:on_hurt_by_sword(hero, enemy_sprite)
        if self:is_shocking() then
            hero:start_hurt(self:get_damage())
            hero:start_electrocution(1000)
        else
            -- Why doesn't hurt() remove life?
            self:hurt(game:get_ability('sword'))
            self:remove_life(game:get_ability('sword'))
        end
    end

    function enemy:on_attacking_hero(hero, enemy_sprite)
        hero:start_hurt(self:get_damage())
        if self:is_shocking() then
            hero:start_electrocution(1000)
        end
    end
end

return bari_mixin
