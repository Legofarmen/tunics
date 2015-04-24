local treasure = {}

function treasure.init(map, data)

    local chest = zentropy.inject_chest(map:get_entity('chest'), data)

    if map:has_entity('enemy') then
        zentropy.inject_enemy(map:get_entity('enemy'), data.rng:refine('enemy'))
    end

    if map:has_entities('placeholder_') or map:has_entities('pot_') then
        local switch = map:get_entity('switch')

        local placeholders = {}
        for entity in map:get_entities('pot_') do
            zentropy.inject_pot(entity, data.rng:refine(entity:get_name()))
            table.insert(placeholders, entity)
        end
        local hideout = placeholders[data.rng:random(#placeholders)]

        hideout:set_enabled(false)
        switch:set_position(hideout:get_position())

        local block = map:get_entity('block_' .. hideout:get_name())
        if block then
             block:set_pushable(true)
        end

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
