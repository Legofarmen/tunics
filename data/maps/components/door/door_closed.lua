local zentropy = require 'lib/zentropy'

local door_closed = {}

function door_closed.init(map, data, direction4)

    local door = zentropy.inject_door(map:get_entity('door_open'), {
        savegame_variable = data.name,
        direction = direction4,
        sprite = "entities/door_normal",
    })

    local sensor = map:get_entity('sensor')

    function sensor:on_activated()
        data.room_events:on_door_sensor_activated(direction4)
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

    local entering = map:get_entity('entering')
    function entering:on_activated()
        local hero = map:get_hero()
        local m = sol.movement.create('straight')
        m:set_speed(hero:get_walking_speed())
        m:set_angle(math.pi / 2 * direction4 + math.pi)
        m:set_max_distance(48)
        function m:on_finished()
            hero:unfreeze()
            hero:set_invincible(false)
        end
        hero:set_invincible(true, 9000)  -- Workaround for Solarus-bug: 9000ms is large enough to pass for unlimited
        m:start(hero)
    end

    component:set_open(true)

    function door:on_opened()
        map:remove_entities('entering')
    end

    return component
end

return door_closed
