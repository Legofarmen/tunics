local hookshot = {}

local util = require 'lib/util'

function hookshot.init(map, data)
	local door_names = {}
	for dir, door_data in util.pairs_by_keys(data.doors) do
		data.room:door({open=door_data.open or 'open', name=door_data.name, door_names=door_names}, dir)
	end

    local hidden_chest = nil
	
	local obstacle_x, obstacle_y = map:get_entity('treasure_obstacle_chest'):get_position()
	obstacle_x, obstacle_y = obstacle_x + 8, obstacle_y + 13
	
	if data.treasure1 then
		map:create_chest{
            sprite="entities/chest",
            layer=1,
            x = obstacle_x,
            y = obstacle_y,
            treasure_name=data.treasure1.item_name,
            treasure_savegame_variable=data.treasure1.name,
		}
	map:set_entities_enabled('treasure_obstacle_', true)
	else
		map:create_block{
            layer = 1,
            x = obstacle_x,
            y = obstacle_y,
            direction = -1,
            sprite = "entities/block",
            pushable = false,
            pullable = false,
            maximum_moves = 0,
        }		
	end
	
	local open_x, open_y = map:get_entity('treasure_open_chest'):get_position()
	open_x, open_y = open_x + 8, open_y + 13
	
	if data.treasure2 then
			map:create_chest{
            sprite="entities/chest",
            layer=1,
            x = open_x,
            y = open_y,
            treasure_name=data.treasure2.item_name,
            treasure_savegame_variable=data.treasure2.name,
        }
	map:set_entities_enabled('treasure_open_', true)
	else
		map:create_block{
            layer = 1,
            x = open_x,
            y = open_y,
            direction = -1,
            sprite = "entities/block",
            pushable = false,
            pullable = false,
            maximum_moves = 0,
        }
	end
	
end

return hookshot
