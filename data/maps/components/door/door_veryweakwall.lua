local zentropy = require 'lib/zentropy'

local door_veryweakwall = {}

function door_veryweakwall.init(map, data, direction)

    local door = zentropy.inject_door(map:get_entity('door_open'), {
        name = 'door',
        savegame_variable = data.name,
        direction = 0,
        sprite = "entities/door_very_weak_wall",
        opening_method = "explosion",
    })

    local sensor = map:get_entity('sensor')

    function sensor:on_activated()
        data.room_events:door_sensor_activated(direction)
    end

    local component = {}

    return component
end

return door_veryweakwall
