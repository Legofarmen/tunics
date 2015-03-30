local bomb = {}

function bomb.init(map, data, directions)
	for _, dir in ipairs(directions) do
		local door_u = map:get_entity('door_' .. dir):get_userdata()
		function door_u:on_opened()
			map:get_entity('door_'  .. dir .. '_closed'):set_enabled(false)
			map:get_entity('top_'  .. dir .. '_open'):set_enabled(true)
			sol.audio.play_sound('secret')
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
		map:set_enities_enabled('treasure_obstacle_', false)
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
		map:set_enities_enabled('treasure_open_', false)
	end
end

return bomb