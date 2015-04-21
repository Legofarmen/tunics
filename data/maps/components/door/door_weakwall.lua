local zentropy = require 'lib/zentropy'

local door_weakwall = {}

function door_weakwall.init(map, data, direction)

    zentropy.inject_door(map:get_entity('door_open'), {
        savegame_variable = data.name,
        direction = direction,
        sprite = "entities/door_weak_wall",
        opening_method = "explosion",
    })

    local sensor = map:get_entity('sensor')

    function sensor:on_activated()
        data.room_events:on_door_sensor_activated(direction)
    end

    local component = {}

    return component
end

return door_weakwall
