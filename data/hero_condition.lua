local condition_manager = {}
local in_command_pressed = false
local in_command_release = false
local sword_level = 0

condition_manager.timers = {
  slow = nil,
  frozen = nil,
  poison = nil,
  electrocution = nil,
  cursed = nil
}

function condition_manager:initialize(game)
  local hero = game:get_hero()
  hero.condition = {
    slow = false,
    frozen = false,
    poison = false,
    electrocution = false,
    cursed = false
  }

  function hero:is_condition_active(condition)
    return hero.condition[condition]
  end

  function hero:set_condition(condition, active)
      zentropy.debug('set_condition', active)
    hero.condition[condition] = active
  end

  function hero:on_taking_damage(in_damage)
    local damage = in_damage

    if hero:is_condition_active('frozen') then
      damage = damage * 3
      hero:stop_frozen(true)
    end

    if damage == 0 then
      return
    end

    local shield_level = game:get_ability('shield')
    local tunic_level = game:get_ability('tunic')

    local protection_divider = tunic_level * math.ceil(shield_level / 2)
    if protection_divider == 0 then
      protection_divider = 1
    end
    damage = math.floor(damage / protection_divider)

    if damage < 1 then
      damage = 1
    end

    game:remove_life(damage)
  end

  function hero:start_frozen(delay)
    if hero:is_condition_active('frozen') then
      return
    end

    hero:freeze()
    hero:set_animation("frozen")
    sol.audio.play_sound("freeze")

    hero:set_condition('frozen', true)
    condition_manager.timers['frozen'] = sol.timer.start(hero, delay, function()
      hero:stop_frozen()
    end)
  end

  function hero:start_electrocution(delay)
    if hero:is_condition_active('electrocution') then
      return
    end

    hero:freeze()
    hero:set_animation("electrocuted")
    sol.audio.play_sound("spark")

    hero:set_condition('electrocution', true)
    condition_manager.timers['electrocution'] = sol.timer.start(hero, delay, function()
      hero:stop_electrocution()
    end)
  end

  function hero:start_poison(damage, delay, max_iteration)
    if hero:is_condition_active('poison') and condition_manager.timers['poison'] ~= nil then
      condition_manager.timers['poison']:stop()
    end

    local iteration_poison = 0
    function do_poison()
      if hero:is_condition_active("poison") and iteration_poison < max_iteration then
        sol.audio.play_sound("hero_hurt")
        game:remove_life(damage)
        iteration_poison = iteration_poison + 1
      end

      if iteration_poison == max_iteration then
        hero:set_blinking(false)
        hero:set_condition('poison', false)
      else
        condition_manager.timers['poison'] = sol.timer.start(hero, delay, do_poison)
      end
    end

    hero:set_blinking(true, delay)
    hero:set_condition('poison', true)
    do_poison()
  end

  function hero:start_slow(delay)
    if hero:is_condition_active('slow') and condition_manager.timers['slow'] ~= nil then
      condition_manager.timers['slow']:stop()
    end

    hero:set_condition('slow', true)
    hero:set_walking_speed(48)
    condition_manager.timers['slow'] = sol.timer.start(hero, delay, function()
      hero:stop_slow()
    end)
  end

  function hero:start_cursed(delay)
    if hero:is_condition_active('cursed') and condition_manager.timers['cursed'] ~= nil then
      condition_manager.timers['cursed']:stop()
    end

    hero:set_condition('cursed', true)
    sword_level = game:get_ability("sword")
    game:set_ability("sword", 0)
    game:start_dialog("_cursed")

    condition_manager.timers['cursed'] = sol.timer.start(hero, delay, function()
      hero:stop_cursed()
    end)
  end

  function hero:stop_frozen()
    if hero:is_condition_active('frozen') and condition_manager.timers['frozen'] ~= nil then
      condition_manager.timers['frozen']:stop()
    end

    hero:unfreeze()
    hero:set_animation("walking")
    hero:set_condition('frozen', false)
    sol.audio.play_sound("ice_shatter")
  end

  function hero:stop_electrocution()
    if hero:is_condition_active('electrocution') and condition_manager.timers['electrocution'] ~= nil then
      condition_manager.timers['electrocution']:stop()
    end

    hero:unfreeze()
    hero:set_animation("walking")
    hero:set_condition('electrocution', false)
  end

  function hero:stop_slow()
    if hero:is_condition_active('slow') and condition_manager.timers['slow'] ~= nil then
      condition_manager.timers['slow']:stop()
    end

    hero:set_condition('slow', false)
    hero:set_walking_speed(88)
  end

  function hero:stop_cursed()
    if hero:is_condition_active('cursed') and condition_manager.timers['cursed'] ~= nil then
      condition_manager.timers['cursed']:stop()
    end

    hero:set_condition('cursed', false)
    game:set_ability("sword", sword_level)
  end
end

return condition_manager
