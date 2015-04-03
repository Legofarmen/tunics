local treasure = {}

function treasure.init(map, data)

    local chest = map:get_entity('chest')
        local switch = map:get_entity('switch')
    local switch_u = switch:get_userdata()

    local placeholders = {}
    for entity in map:get_entities('placeholder_') do
        table.insert(placeholders, entity)
    end
    local hideout = placeholders[data.rng:random(#placeholders)]

    hideout:set_enabled(false)
    switch:set_position(hideout:get_position())

    local block = map:get_entity('block_' .. hideout:get_name())
    if block then
         block:set_pushable(true)
    end

    function switch_u:on_activated()
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

return treasure
