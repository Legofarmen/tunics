local flippers = {}

local util = require 'lib/util'

function flippers.init(map, data)
    for dir, door_data in util.pairs_by_keys(data.doors) do
        data.room:door({open=door_data.open or 'open', name=door_data.name, room_events=data.room_events}, dir)
    end

    for entity in map:get_entities('enemy') do
        zentropy.inject_enemy(entity, data.rng:refine(entity:get_name()))
    end

    local treasure_obstacle_chest = map:get_entity('treasure_obstacle_chest')
    if data.treasure1 then
        zentropy.inject_chest(treasure_obstacle_chest, data.treasure1)
    else
        map:remove_entities('treasure_obstacle_')
    end

    local treasure_open_chest = map:get_entity('treasure_open_chest')
    if data.treasure2 then
        zentropy.inject_chest(treasure_open_chest, data.treasure2)
    else
        map:remove_entities('treasure_open_')
    end
end

return flippers
