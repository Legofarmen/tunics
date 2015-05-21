local bow = {}

local util = require 'lib/util'
local zentropy = require 'lib/zentropy'

function bow.init(map, data, timeout)
    local doors = {}
    for dir, door_data in util.pairs_by_keys(data.doors) do
        assert((door_data.open or 'open') == 'open')
        local door = data.room:door({open='closed', name=door_data.name, room_events=data.room_events}, dir)
        table.insert(doors, door)
    end

    for entity in map:get_entities('enemy_') do
        zentropy.inject_enemy(entity, data.rng:refine(entity:get_name()))
    end

    for entity in map:get_entities('pot_') do
        zentropy.inject_pot(entity, data.rng:refine(entity:get_name()))
    end

    local hidden_chest = nil

    local treasure_obstacle_chest = map:get_entity('treasure_obstacle_chest')
    if data.treasure1 then
        hidden_chest = zentropy.inject_chest(treasure_obstacle_chest, data.treasure1)
        if not hidden_chest:is_open() then
            hidden_chest:set_enabled(false)
        end
    else
        map:remove_entities('treasure_obstacle_')
    end

    local treasure_open_chest = map:get_entity('treasure_open_chest')
    if data.treasure2 then
        zentropy.inject_chest(treasure_open_chest, data.treasure2)
    else
        map:remove_entities('treasure_open_')
    end

    local switch = map:get_entity('switch')
    function switch:on_activated()
        local sound = nil
        if data.treasure1 then
            hidden_chest:set_enabled(true)
            sound = 'chest_appears'
        end
        for _, component in ipairs(doors) do
            component:open()
            sound = 'secret'
        end
        sol.audio.play_sound(sound)
    end

    data.room_events:add_door_sensor_activated_listener(function ()
        if not switch:is_activated() then
            for _, component in ipairs(doors) do
                component:close()
            end
        end
    end)

end

return bow
