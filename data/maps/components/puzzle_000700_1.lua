local map, data = ...

local function sensor_activated()
    if not switch:is_activated() then
        for dir, _ in pairs(data.doors) do
            map:close_doors('door_' .. dir)
        end
    end
end

if data.item_name or next(data.doors) then
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
        local x, y = block:get_position()
        block:set_position(x, y-1)
    end

    sensor_north:get_userdata().on_activated = sensor_activated
    sensor_south:get_userdata().on_activated = sensor_activated
    sensor_east:get_userdata().on_activated = sensor_activated
    sensor_west:get_userdata().on_activated = sensor_activated

    local switch_u = switch:get_userdata()

    function switch_u:on_activated()
        if data.item_name then
            chest:set_enabled(true)
            sol.audio.play_sound('chest_appears')
        end
        for dir, _ in pairs(data.doors) do
            map:open_doors('door_' .. dir)
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
    if chest:is_open() then
        switch:set_activated(true)
    else
        chest:set_enabled(false)
    end
end)
