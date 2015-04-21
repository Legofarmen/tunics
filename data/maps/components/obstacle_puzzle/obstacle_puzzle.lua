local puzzle = {}

local util = require 'lib/util'
local zentropy = require 'lib/zentropy'

function puzzle.init(map, data)

    local switch = map:get_entity('switch')
    local sensor_north = map:get_entity('sensor_north')
    local sensor_south = map:get_entity('sensor_south')
    local sensor_east = map:get_entity('sensor_east')
    local sensor_west = map:get_entity('sensor_west')
    local enemy = map:get_entity('enemy')

    zentropy.inject_enemy(enemy, data.rng:refine('enemy'))

	local door_names = {}
	for dir, door_data in util.pairs_by_keys(data.doors) do
        assert((door_data.open or 'open') == 'open')
		data.room:door({open='closed', name=door_data.name, door_names=door_names}, dir)
	end

    local hidden_chest = nil

    if data.treasure1 then
        local placeholder = map:get_entity('treasure_obstacle_chest')
        local x, y = placeholder:get_position()
        x, y = x + 8, y + 13
        hidden_chest = map:create_chest{
            sprite = "entities/chest",
            layer = 1,
            x = x,
            y = y,
            treasure_name=data.treasure1.item_name,
            treasure_savegame_variable=data.treasure1.name,
        }
        if hidden_chest:is_open() then
            switch:set_activated(true)
        else
            hidden_chest:set_enabled(false)
        end
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

    if data.treasure1 or next(data.doors) then
        local placeholders = {}
        for entity in map:get_entities('placeholder_') do
            table.insert(placeholders, entity)
        end
        local hideout = placeholders[data.rng:random(#placeholders)]

        hideout:set_enabled(false)
        local x, y, layer = hideout:get_position()
        if zentropy.settings.debug_cheat then
            y = y + 4
        end
        switch:set_position(x, y, layer)

        local block = map:get_entity('block_' .. hideout:get_name())
        if block then
            block:set_pushable(true)
        end

        local function sensor_activated()
            if not switch:is_activated() then
                for dir, name in util.pairs_by_keys(door_names) do
                    map:close_doors(name)
                end
            end
        end

        sensor_north.on_activated = sensor_activated
        sensor_south.on_activated = sensor_activated
        sensor_east.on_activated = sensor_activated
        sensor_west.on_activated = sensor_activated

        function switch:on_activated()
            local sound = nil
            if data.treasure1 then
                hidden_chest:set_enabled(true)
                sound = 'chest_appears'
            end
            for dir, name in util.pairs_by_keys(door_names) do
                map:open_doors(name)
                sound = 'secret'
            end
            if sound then
                sol.audio.play_sound(sound)
            end
        end
    else
        switch:set_enabled(false)
    end

    map:add_on_started(function ()
        map:set_doors_open('door_', true)
        for dir, _ in pairs(data.doors) do
            map:get_entity('door_' .. dir .. '_top'):set_enabled(true)
        end
    end)
end

return puzzle
