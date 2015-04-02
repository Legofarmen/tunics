local lamp = {}

local util = require 'lib/util'
    		
function lamp.init(map, data, timeout)
	local door_names = {}
	for dir, door_data in pairs(data.doors) do
        data.room:door({open='closed', name=door_data.name, door_names=door_names}, dir)
	end
	
	local torches = map:get_entities('torch_')
	local torch_count = map:get_entities_count('torch_')
	local lit_count = 0 
	for torch in torches do
		local torch_u = torch:get_userdata()
		if timeout then torch:set_timeout(timeout) end
		function torch_u:on_lit()
			lit_count = lit_count + 1
		
			if lit_count == torch_count then
				local sound = nil
				if data.item_name then
					chest:set_enabled(true)
					sound = 'chest_appears'
				end
				for dir, name in pairs(door_names) do
					map:open_doors(name)
					sound = 'secret'
				end
				sol.audio.play_sound(sound)
			end	
        end
		function torch_u:on_unlighting()
			if lit_count == torch_count then
				return false
			else
				lit_count = lit_count - 1
			end
		end
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

return lamp
