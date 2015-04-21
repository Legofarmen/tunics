local zentropy = require 'lib/zentropy'

local door_bigkey = {}

function door_bigkey.init(map, data, direction)

    zentropy.inject_door(map:get_entity('door_open'), {
        savegame_variable = data.name,
        direction = direction,
        sprite = "entities/door_big_key",
        opening_method = "interaction_if_savegame_variable",
        opening_condition = "bigkey",
    })

    local sensor = map:get_entity('sensor')

    function sensor:on_activated()
        data.room_events:door_sensor_activated(direction)
    end

    local component = {}

    return component
end

return door_bigkey
