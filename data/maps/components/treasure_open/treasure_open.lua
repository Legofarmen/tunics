local treasure = {}

function treasure.init(map, data)

    local chest_placeholder = zentropy.assert(map:get_entity('chest'), 'entity not found: chest')
    local chest = zentropy.inject_chest(chest_placeholder, data)

    for entity in map:get_entities('enemy') do
        zentropy.inject_enemy(entity, data.rng:refine(entity:get_name()))
    end

    zentropy.pots(data.rng:refine('pots'), map:get_entities('pot_'))

    if map:has_entities('switch') then
        local switch = map:get_entity('switch')

        zentropy.hideout(data.rng:refine('hideout'), switch, map:get_entities('pot_'), map:get_entities('block_'))

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
    end
end

return treasure
