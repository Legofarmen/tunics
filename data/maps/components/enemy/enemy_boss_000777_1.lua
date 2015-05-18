local map, data = ...

local util = require 'lib/util'

local boss_exit = map:include(0, 0, 'components/door/door_exit_n_200000_1', {room_events=data.room_events, name="boss_exit"})
local boss_entrance = map:include(0, 0, 'components/door/door_bigkey_s_002000_1', {room_events=data.room_events, name="boss_entrance"})

local agahnim = map:get_entity("agahnim"):get_userdata()
agahnim:set_enabled(false)

local x1, y1 = map:get_entity('boss_1'):get_userdata():get_position()
table.insert(agahnim.positions, {x = x1, y = y1, direction4 = 3})
local x2, y2 = map:get_entity('boss_2'):get_userdata():get_position()
table.insert(agahnim.positions, {x = x2, y = y2, direction4 = 0})
local x3, y3 = map:get_entity('boss_3'):get_userdata():get_position()
table.insert(agahnim.positions, {x = x3, y = y3, direction4 = 2})

function agahnim:on_dying()
	zentropy.debug("Agahnim dying")
	boss_exit:open()
	
end

local has_escaped = false

function agahnim:on_escape()
	has_escaped = true
    zentropy.debug("Agahnim escape")
	sol.audio.stop_music()
	boss_exit:open()	
end

data.room_events:add_door_sensor_activated_listener(function ()
    if not has_escaped then
        agahnim:set_enabled(true)
        sol.audio.play_music('agahnim')
		agahnim:restart()
        zentropy.debug("Sensor triggered")
        boss_exit:close()
    end
end)
