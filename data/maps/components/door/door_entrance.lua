local zentropy = require 'lib/zentropy'

local door_entrance = {}

function door_entrance.init(map, data, direction)

    local sensor = map:get_entity('sensor')

    function sensor:on_activated()
        data.room_events:door_sensor_activated(direction)
    end

    local component = {}

    return component
end

return door_entrance
