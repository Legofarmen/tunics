local bow = {}

local util = require 'lib/util'

function bow.init(map, data, timeout)
	local door_names = {}
	for dir, door_data in pairs(data.doors) do
		data.room:door({open='closed', name=door_data.name, door_names=door_names}, dir)
	end

    local hidden_chest = nil

	if data.treasure1 then
		local x, y = map:get_entity('treasure_obstacle_chest'):get_position()
		x, y = x + 8, y + 13
		hidden_chest = map:create_chest{
            sprite="entities/chest",
            layer=1,
            x = x,
            y = y,
            treasure_name=data.treasure1.item_name,
            treasure_savegame_variable=data.treasure1.name,
        }
        hidden_chest:set_enabled(false)
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

	local switch = map:get_entity('switch')
	local switch_u = switch:get_userdata()
	function switch_u:on_activated()
		local sound = nil
		if data.treasure1 then
			hidden_chest:set_enabled(true)
			sound = 'chest_appears'
		end
		for dir, name in pairs(door_names) do
			map:open_doors(name)
			sound = 'secret'
		end
		sol.audio.play_sound(sound)
	end

end

return bow
