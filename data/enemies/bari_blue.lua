local enemy = ...

-- Bari: a flying enemy that follows the hero
--       and tries to electrocute him.

local shocking = false

function enemy:on_created()
    self:set_life(2)
    self:set_damage(2)
    self:create_sprite("enemies/bari_blue")
    self:set_attack_consequence("hookshot", "immobilized")
    self:set_size(16, 16)
    self:set_origin(8, 13)
end

function enemy:shock()
    self:stop_movement()
    shocking = true
    self:get_sprite():set_animation("shaking")
    sol.timer.start(self, 1000, function()
        self:get_sprite():set_animation("walking")
        shocking = false
        self:restart()
    end)
end

function enemy:on_restarted()
    shocking = false
    local m = sol.movement.create("path_finding")
    m:set_speed(32)
    m:start(self)
    sol.timer.start(enemy, 1000 + 5000 * math.random(), function()
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
    hero:start_hurt(2)
  end
end

function enemy:on_dying()
    local function create_mini()
        local mini = enemy:create_enemy({ breed = "bari_mini" })
        mini:set_invincible(true) -- make mini survive the initial attack
        sol.timer.start(mini, 200, function ()
            mini:set_default_attack_consequences()
            mini:set_attack_consequence("hookshot", "immobilized")
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
