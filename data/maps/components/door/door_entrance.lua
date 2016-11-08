local zentropy = require 'lib/zentropy'

local door_entrance = {}

function door_entrance.init(map, data, direction)
	
    local placeholder = map:get_entity('entrance')
    local x, y, layer = placeholder:get_position()

    map:create_dynamic_tile({
        layer=layer,
        x=x+32,
        y=y+24,
        pattern='entrance_floor.1.1',
        width=16,
        height=48,
        enabled_at_start=true,
    })

    map:create_dynamic_tile({
        layer=layer,
        x=x+24,
        y=y,
        pattern='entrance_floor.1.2',
        width=32,
        height=24,
        enabled_at_start=true,
    })

    map:create_dynamic_tile({
        layer=layer,
        x=x+24,
        y=y+24,
        pattern='entrance_door_support.1.r',
        width=8,
        height=16,
        enabled_at_start=true,
    })

    map:create_dynamic_tile({
        layer=layer,
        x=x+48,
        y=y+24,
        pattern='entrance_door_support.1.l',
        width=8,
        height=16,
        enabled_at_start=true,
    })

    placeholder:remove()
	for door in map:get_entities("door_entrance", true) do
        door:bring_to_front()
    end

    local sensor = map:get_entity('sensor')

    function sensor:on_activated()
        data.room_events:on_door_sensor_activated(direction)
		map:close_doors("door_entrance")
		local carpet = map:get_entity("entrance_carpet")
        if carpet then
            local x, y = carpet:get_position()
            
            carpet:set_position(x,y+8)
            sol.timer.start(100, function()
                carpet:set_position(x,y+24)
            end)
        end
	end
	
	map:set_doors_open("door_entrance", true)
	
	
	
    local component = {}
    return component
end

return door_entrance
