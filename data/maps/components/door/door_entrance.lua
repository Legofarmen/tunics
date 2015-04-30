local zentropy = require 'lib/zentropy'

local door_entrance = {}

function door_entrance.init(map, data, direction)
	
    local sensor = map:get_entity('sensor')

    function sensor:on_activated()
        data.room_events:on_door_sensor_activated(direction)
		map:close_doors("door_entrance")
		local carpet = map:get_entity("entrance_carpet")
		local x, y = carpet:get_position()
		
		carpet:set_position(x,y+8)
		sol.timer.start(100, function()
			carpet:set_position(x,y+24)
		end)
		
		end
	
	map:set_doors_open("door_entrance", true)
	
	
	
    local component = {}
    return component
end

return door_entrance
