local zentropy = require 'lib/zentropy'

local door_closed = {}

function door_closed.init(map, data, direction)

    local door = zentropy.inject_door(map:get_entity('door_open'), {
        savegame_variable = data.name,
        direction = direction,
        sprite = "entities/door_normal",
    })

    local sensor = map:get_entity('sensor')

    function sensor:on_activated()
        data.room_events:door_sensor_activated(direction)
    end

    local component = {}

    function component:open()
        map:open_doors(door:get_name())
    end

    function component:close()
        map:close_doors(door:get_name())
    end

    function component:set_open(open)
        map:set_doors_open(door:get_name(), open)
    end

    component:set_open(true)

    return component
end

return door_closed
