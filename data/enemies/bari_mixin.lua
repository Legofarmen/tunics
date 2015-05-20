local bari_mixin = {}

function bari_mixin.mixin(enemy)

    local shocking = false

    function enemy:shock()
        self:stop_movement()
        shocking = true
        self:get_sprite():set_animation("shaking")
        sol.timer.start(self, 1000 + 1000 * math.random(), function()
            self:get_sprite():set_animation("walking")
            shocking = false
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
        sol.timer.start(enemy, 1000 + 9000 * math.random(), function()
            self:shock()
        end)
    end

    function enemy:on_immobilized()
      shocking = false
    end

    function enemy:on_hurt_by_sword(hero, enemy_sprite)
      if shocking == true then
        hero:start_electrocution(1500)
      else
        self:hurt(1)
        enemy:remove_life(1)
      end
    end

    function enemy:on_attacking_hero(hero, enemy_sprite)
      if shocking == true then
        hero:start_electrocution(1500)
      else
        hero:start_hurt(1)
      end
    end
end

return bari_mixin
