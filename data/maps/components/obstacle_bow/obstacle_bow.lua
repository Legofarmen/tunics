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

    for entity in map:get_entities('enemy') do
        zentropy.inject_enemy(entity, data.rng:refine(entity:get_name()))
    end

	for entity in map:get_entities('pot_') do
        zentropy.inject_pot(entity, data.rng:refine(entity:get_name()))
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
        if not hidden_chest:is_open() then
            hidden_chest:set_enabled(false)
        end
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
