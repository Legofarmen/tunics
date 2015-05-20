local hookshot = {}

local util = require 'lib/util'

function hookshot.init(map, data)
	for dir, door_data in util.pairs_by_keys(data.doors) do
		data.room:door({open=door_data.open or 'open', name=door_data.name, room_events=data.room_events}, dir)
	end

    for entity in map:get_entities('enemy_') do
        zentropy.inject_enemy(entity, data.rng:refine(entity:get_name()))
    end

	for entity in map:get_entities('pot_') do
        zentropy.inject_pot(entity, data.rng:refine(entity:get_name()))
    end
	
	local treasure_obstacle_chest = map:get_entity('treasure_obstacle_chest')
	if data.treasure1 then
        zentropy.inject_chest(treasure_obstacle_chest, data.treasure1)
        map:set_entities_enabled('treasure_obstacle_', true)
	else
        zentropy.inject_block(treasure_obstacle_chest)
	end
	
	local treasure_open_chest = map:get_entity('treasure_open_chest')
	if data.treasure2 then
        zentropy.inject_chest(treasure_open_chest, data.treasure2)
        map:set_entities_enabled('treasure_open_', true)
	else
        zentropy.inject_block(treasure_open_chest)
	end
	
end

return hookshot
