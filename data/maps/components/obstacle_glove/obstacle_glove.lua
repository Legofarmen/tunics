local glove = {}

local util = require 'lib/util'
local zentropy = require 'lib/zentropy'

function glove.init(map, data)

    for entity in map:get_entities('enemy') do
        data.room:inject_enemy(entity, data.rng:refine(entity:get_name()))
    end

	local door_names = {}
	for dir, door_data in util.pairs_by_keys(data.doors) do
        assert((door_data.open or 'open') == 'open')
		data.room:door({open='open', name=door_data.name, door_names=door_names, room_events=data.room_events}, dir)
	end

    for entity in map:get_entities('pot_') do
        zentropy.inject_pot(entity, data.rng:refine(entity:get_name()))
    end

    if data.treasure1 then
        local placeholder = map:get_entity('treasure_obstacle_chest')
        local x, y = placeholder:get_position()
        x, y = x + 8, y + 13
        map:create_chest{
            sprite = "entities/chest",
            layer = 1,
            x = x,
            y = y,
            treasure_name=data.treasure1.item_name,
            treasure_savegame_variable=data.treasure1.name,
        }
        placeholder:remove()
    else
        map:set_entities_enabled('treasure_obstacle_', false)
    end

    if data.treasure2 then
        local placeholder = map:get_entity('treasure_open_chest')
        local x, y = placeholder:get_position()
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

    for placeholder in map:get_entities('stone_') do
        local x, y, layer = placeholder:get_position()
        local stone = map:create_destructible{
            layer = layer,
            x = x,
            y = y,
            sprite = zentropy.Room.destructibles.stone1,
            destruction_sound = 'stone',
            weight = 1,
        }
        local x_origin, y_origin = stone:get_origin()
        stone:set_position(x + x_origin, y + y_origin)
        placeholder:remove()
    end

end

return glove
