local bomb = {}

local util = require 'lib/util'

function bomb.init(map, data)
	for dir, door_data in util.pairs_by_keys(data.doors) do
        assert(door_data.open == 'veryweakwall')
        data.room:door({open='veryweakwall', name=door_data.name}, dir)
	end
	
	if data.treasure1 then
		local x, y = map:get_entity('treasure_obstacle_chest'):get_position()
		x, y = x + 8, y + 13
		map:create_chest{
            sprite="entities/chest",
            layer=1,
            x = x,
            y = y,
            treasure_name=data.treasure1.item_name,
            treasure_savegame_variable=data.treasure1.name,
        }
	else
		map:set_entities_enabled('treasure_obstacle_', false)
	end

	if data.treasure2 then
		local x, y = map:get_entity('treasure_open_chest'):get_position()
		x, y = x + 8, y + 13
		map:create_chest{
            sprite="entities/chest",
            layer=1,
            x = x,
            y = y,
            treasure_name=data.treasure2.item_name,
            treasure_savegame_variable=data.treasure2.name,
        }
	else
		map:set_entities_enabled('treasure_open_', false)
	end
end

return bomb
