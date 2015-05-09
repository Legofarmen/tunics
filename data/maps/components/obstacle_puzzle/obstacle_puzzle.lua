local puzzle = {}

local util = require 'lib/util'
local zentropy = require 'lib/zentropy'

function puzzle.init(map, data)

    local switch = map:get_entity('switch')
    assert(switch, "obstacle_puzzle components must contain a 'switch'")

    for entity in map:get_entities('enemy') do
        zentropy.inject_enemy(entity, data.rng:refine(entity:get_name()))
    end

    zentropy.pots(data.rng:refine('pots'), map:get_entities('pot_'))


	local doors = {}
	for dir, door_data in util.pairs_by_keys(data.doors) do
        zentropy.assert((door_data.open or 'open') == 'open')
		local door = data.room:door({open='closed', name=door_data.name, room_events=data.room_events}, dir)
        table.insert(doors, door)
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
        zentropy.hideout(data.rng:refine('hideout'), switch, map:get_entities('pot_'), map:get_entities('block_'))

        data.room_events:add_door_sensor_activated_listener(function ()
            if not switch:is_activated() then
                for _, component in ipairs(doors) do
                    component:close()
                end
            end
        end)

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
            if sound then
                sol.audio.play_sound(sound)
            end
        end
    else
        switch:set_enabled(false)
    end
end

return puzzle
