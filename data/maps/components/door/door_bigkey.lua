local zentropy = require 'lib/zentropy'

local door_bigkey = {}

function door_bigkey.init(map, data, direction)

    if direction == 1 then
        zentropy.inject_door(map:get_entity('door_open'), {
            name = 'door',
            direction = direction,
            sprite = "entities/door_big_key",
            opening_method = "interaction_if_item",
            opening_condition = "bigkey",
        })
    else
        local door = zentropy.inject_door(map:get_entity('door_open'), {
            name = 'door',
            direction = direction,
            sprite = "entities/door_normal",
        })
        map:set_doors_open(door:get_name(), true)

        data.room_events:add_door_sensor_activated_listener(function ()
            map:close_doors(door:get_name())
        end)

    end

    local sensor = map:get_entity('sensor')

    function sensor:on_activated()
        data.room_events:on_door_sensor_activated(direction)
    end

    local component = {}

    return component
end

return door_bigkey
