local flippers = {}

local util = require 'lib/util'

function flippers.init(map, data)
    for dir, door_data in util.pairs_by_keys(data.doors) do
        data.room:door({open=door_data.open or 'open', name=door_data.name, room_events=data.room_events}, dir)
    end

    if data.treasure1 then
        zentropy.inject_chest(map:get_entity('treasure_obstacle_chest'), data.treasure1)
        map:set_entities_enabled('treasure_obstacle_', true)
    end

    if data.treasure2 then
        zentropy.inject_chest(map:get_entity('treasure_open_chest'), data.treasure2)
        map:set_entities_enabled('treasure_open_', true)
    end
end

return flippers