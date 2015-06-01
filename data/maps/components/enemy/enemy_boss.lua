local util = require 'lib/util'

local enemy_boss = {}

function enemy_boss.init(map, data)
    local boss_exit = map:include(0, 0, 'components/door/door_exit_n_200000_1', {room_events=data.room_events, name="boss_exit"})
    local boss_entrance = map:include(0, 0, 'components/door/door_bigkey_s_002000_1', {room_events=data.room_events, name="boss_entrance"})

    enemy_boss.init_agahnim(map:get_entity("agahnim"), boss_exit)

    data.room_events:add_door_sensor_activated_listener(function ()
        if map:has_entity('agahnim') then
            local agahnim = map:get_entity("agahnim")
            agahnim:set_enabled(true)
            sol.audio.play_music('agahnim')
            agahnim:restart()
            boss_exit:close()
        end
    end)
end

function enemy_boss.init_agahnim(agahnim, boss_exit)
    if not agahnim then return end
    local map = agahnim:get_map()
    local agahnim_u = agahnim:get_userdata()

    agahnim:set_enabled(false)

    local x1, y1 = map:get_entity('boss_1'):get_userdata():get_position()
    table.insert(agahnim_u.positions, {x = x1, y = y1, direction4 = 3})
    local x2, y2 = map:get_entity('boss_2'):get_userdata():get_position()
    table.insert(agahnim_u.positions, {x = x2, y = y2, direction4 = 0})
    local x3, y3 = map:get_entity('boss_3'):get_userdata():get_position()
    table.insert(agahnim_u.positions, {x = x3, y = y3, direction4 = 2})

    function agahnim_u:on_dead()
        sol.audio.stop_music()
        boss_exit:open()
        sol.audio.play_sound('secret')
    end
end

return enemy_boss
