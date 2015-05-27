local treasure = {}

function treasure.init(map, data)

    zentropy.assert(data.room, 'property not found: data.room')
    zentropy.assert(map.add_on_started, 'method not found: map.add_on_started')

    local chest_placeholder = map:get_entity('chest')
    zentropy.assert(chest_placeholder, 'entity not found: chest')
    local chest = zentropy.inject_chest(chest_placeholder, data)

    for entity in map:get_entities('enemy') do
        data.room:inject_enemy(entity, data.rng:refine(entity:get_name()))
    end

    zentropy.pots(data.rng:refine('pots'), map:get_entities('pot_'))

    if map:has_entities('switch') then
        local switch = map:get_entity('switch')

        local hideout = zentropy.hideout(data.rng:refine('hideout'):seq(), map:get_entities('pot_'), map:get_entities('block_'))
        zentropy.hide_switch(switch, hideout)

        function switch:on_activated()
            chest:set_enabled(true)
            sol.audio.play_sound('chest_appears')
        end

        map:add_on_started(function ()
            if chest:is_open() then
                switch:set_activated(true)
            else
                chest:set_enabled(false)
            end
        end)
    else
        zentropy.hideout(function () return false end, map:get_entities('pot_'), map:get_entities('block_'))
    end
end

return treasure
