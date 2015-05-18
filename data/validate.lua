local zentropy = require 'lib/zentropy'
local util = require 'lib/util'

local alignments = {
    ["wall.1"] = {{ x=0, y=8, }},
    ["wall.2"] = {{ x=0, y=0, }},
    ["wall.3"] = {{ x=8, y=0, }},
    ["wall.4"] = {{ x=0, y=0, }},
    ["wall_diag.1"] = {{ x=0, y=0, }, { x=8, y=8, }},
    ["wall_diag.2"] = {{ x=0, y=0, }, { x=8, y=8, }},
    ["wall_diag.3"] = {{ x=0, y=0, }, { x=8, y=8, }},
    ["wall_diag.4"] = {{ x=0, y=0, }, { x=8, y=8, }},
    ["wall_diag.border.1"] = {{ x=0, y=0, }, { x=8, y=8, }},
    ["wall_diag.border.2"] = {{ x=0, y=0, }, { x=8, y=8, }},
    ["wall_diag.border.3"] = {{ x=0, y=0, }, { x=8, y=8, }},
    ["wall_diag.border.4"] = {{ x=0, y=0, }, { x=8, y=8, }},
}

local function rect_string(rect)
    zentropy.assert(rect)
    return string.format("(%3d;%3d)-(%3d;%3d)", rect.x, rect.y, rect.x + rect.width, rect.y + rect.height)
end

local function coord_string(coord)
    return string.format("(%3d;%3d)", coord.x, coord.y)
end

local function intersects(a, b)
    local result =
        a.x < b.x + b.width and
        b.x < a.x + a.width and
        a.y < b.y + b.height and
        b.y < a.y + a.height
    return result
end

local function contains(outer, inner)
    local result =
        inner.x >= outer.x and
        inner.x + inner.width <= outer.x + outer.width and
        inner.y >= outer.y and
        inner.y + inner.height <= outer.y + outer.height
    return result
end

local function validate_entity_layer(fname, description, properties)
    if properties.layer == 0 then
        zentropy.debug(string.format("%s:  in low layer in component: %s", description, fname))
    end
end

local function validate_entity_mask(fname, description, properties, sections)
    local entire_room = { x = 0, y = 0, width = 320, height = 240, }
    for name, rect in pairs(sections) do
        if intersects(rect, properties) then
            zentropy.debug(string.format("%s:  intersects with %s in component: %s", description, name, fname))
        end
        if not contains(entire_room, properties) then
            zentropy.debug(string.format("%s:  not contained within %s in component: %s", description, rect_string(entire_room), fname))
        end
    end
end

local function validate_entity_placeholder(fname, description, properties)
    local floor_area = { x = 32, y = 32, width = 256, height = 176, }

    -- Pot
    if properties.pattern == 'floor_pot' then
        if not properties.name or not properties.name:find('^pot_') then
            zentropy.debug(string.format("%s:  not named pot_* in component: %s", description, fname))
        end
    elseif properties.name and properties.name:find('^pot_') then
        zentropy.debug(string.format("%s:  named pot* in component: %s", description, fname))
    end

    -- Enemy
    if properties.pattern == 'placeholder_enemy' then
        if not properties.name or not properties.name:find('^enemy_') then
            zentropy.debug(string.format("%s:  not named enemy_* in component: %s", description, fname))
        end
        if not contains(floor_area, properties) then
            zentropy.debug(string.format("%s:  not contained within %s in component: %s", description, rect_string(floor_area), fname))
        end
    elseif properties.name and properties.name:find('^enemy_') then
        zentropy.debug(string.format("%s:  only tiles of pattern placeholder_enemy may be named enemy* in component: %s", description, fname))
    end

    -- Treasure obstacle/puzzle
    if properties.pattern == 'placeholder_treasure_obstacle' or properties.pattern == 'placeholder_treasure_puzzle' then
        if properties.name ~= 'treasure_obstacle_chest' then
            zentropy.debug(string.format("%s:  not named treasure_obstacle_chest in component: %s", description, fname))
        end
        if not contains(floor_area, properties) then
            zentropy.debug(string.format("%s:  not contained within %s in component: %s", description, rect_string(floor_area), fname))
        end
    elseif properties.name == 'treasure_obstacle_chest' then
        zentropy.debug(string.format("%s:  only tiles of pattern placeholder_treasure_obstacle or placeholder_treasure_puzzle may be named treasure_obstacle_chest in component: %s", description, fname))
    end
end

local function validate_entity_alignment(fname, description, properties)
    local is_aligned = nil
    for i, alignment in ipairs(alignments[properties.pattern] or {}) do
        if is_aligned or (properties.x % 16 == alignment.x and properties.y % 16 == alignment.y) then
            is_aligned = true
        else
            is_aligned = false
        end
    end
    if is_aligned == false then
        zentropy.debug(string.format("%s:  misaligned: %s", description, fname))
    end
end

local function validate_map(fname, mask, tilesets, patterns)
    local all_sections = {
        { x = 176, y = 136, width = 144, height = 104, },
        { x = 144, y = 136, width =  32, height = 72, },
        { x =   0, y = 136, width = 144, height = 104, },
        { x = 176, y = 104, width = 108, height =  32, },
        { x = 144, y = 104, width =  32, height =  32, },
        { x =  32, y = 104, width = 108, height =  32, },
        { x = 176, y =   0, width = 144, height = 104, },
        { x = 144, y =  32, width =  32, height = 72, },
        { x =   0, y =   0, width = 144, height = 104, },
    }
    local i = 1
    local sections = {}
    for i = 1, 9 do
        local section_mask = bit32.lshift(1, i-1)
        if bit32.band(mask, section_mask) == 0 then
            sections[util.fromoct(section_mask)] = all_sections[i]
        end
    end

    local datf = sol.main.load_file(fname)
    if not datf then
        error("error: loading file: " .. fname)
    end
    local mt = {}
    function mt.properties(properties)
        if properties.x ~= 0 or properties.y ~= 0 then
            zentropy.debug('component origin not (0;0): ' .. fname)
        end
        if properties.width ~= 320 or properties.height ~= 240 then
            zentropy.debug('component size not (320;200): ' .. fname)
        end
        if not tilesets[properties.tileset] then
            zentropy.debug(string.format('unknown tileset (%s) in component: %s', properties.tileset, fname))
        end
    end
    function mt.custom_entity(properties)
        local description = string.format("custom entity %s", rect_string(properties))
        if properties.name then
            description = description .. string.format(" name=%s", properties.name)
        end
        validate_entity_layer(fname, description, properties)
        validate_entity_mask(fname, description, properties, sections)
    end
    function mt.dynamic_tile(properties)
        local description = string.format("dynamic tile  %s", rect_string(properties))
        if properties.name then
            description = description .. string.format(" name=%s", properties.name)
        else
            description = description .. string.format(" pattern=%s", properties.pattern)
        end
        validate_entity_layer(fname, description, properties)
        validate_entity_mask(fname, description, properties, sections)
        validate_entity_placeholder(fname, description, properties)
        validate_entity_alignment(fname, description, properties)
    end
    function mt.jumper(properties)
        local description = string.format("jumper        %s", rect_string(properties))
        if properties.name then
            description = description .. string.format(" name=%s", properties.name)
        end
        validate_entity_layer(fname, description, properties)
        validate_entity_mask(fname, description, properties, sections)
    end
    function mt.sensor(properties)
        local description = string.format("sensor        %s", rect_string(properties))
        if properties.name then
            description = description .. string.format(" name=%s", properties.name)
        end
        validate_entity_layer(fname, description, properties)
        validate_entity_mask(fname, description, properties, sections)
    end
    function mt.tile(properties)
        local description = string.format("tile          %s", rect_string(properties))
        if properties.name then
            description = description .. string.format(" name=%s", properties.name)
        else
            description = description .. string.format(" pattern=%s", properties.pattern)
        end
        validate_entity_layer(fname, description, properties)
        validate_entity_mask(fname, description, properties, sections)
        validate_entity_placeholder(fname, description, properties)
        validate_entity_alignment(fname, description, properties)
    end
    function mt.wall(properties)
        local description = string.format("wall          %s", rect_string(properties))
        if properties.name then
            description = description .. string.format(" name=%s", properties.name)
        end
        validate_entity_layer(fname, description, properties)
        validate_entity_mask(fname, description, properties, sections)
    end
    function mt.enemy(properties)
        local description = string.format("enemy         %s breed=%s", coord_string(properties), properties.breed)
    end
    function mt.block(properties) end
    function mt.bomb(properties) end
    function mt.chest(properties) end
    function mt.crystal(properties) end
    function mt.crystal_block(properties) end
    function mt.destination(properties) end
    function mt.destructible(properties) end
    function mt.door(properties) end
    function mt.explosion(properties) end
    function mt.fire(properties) end
    function mt.npc(properties) end
    function mt.pickable(properties) end
    function mt.separator(properties) end
    function mt.shop_treasure(properties) end
    function mt.stairs(properties) end
    function mt.stream(properties) end
    function mt.switch(properties) end
    function mt.teletransporter(properties) end
    setfenv(datf, mt)()
end

local function read_tileset_tiles(fname)
    local datf = sol.main.load_file(fname)
    if not datf then
        error("error: loading file: " .. fname)
    end

    local patterns = {}

    local mt = {}
    function mt.background_color(properties) end
    function mt.tile_pattern(properties)
        patterns[properties.id] = { width=properties.width, height=properties.height }
    end
    setfenv(datf, mt)()
    return patterns
end

local function get_patterns(tilesets)
    local patterns = {}
    local tileset_names = {}
    local tileset_count = 0
    local fmt = "tilesets/%s.dat"
    for k, v in pairs(tilesets) do
        for j, w in pairs(v) do
            for i, tileset in pairs(w) do
                tileset_count = tileset_count + 1
                for id, size in pairs(read_tileset_tiles(fmt:format(tileset))) do
                    if not patterns[id] then
                        patterns[id] = {
                            width=size.width,
                            height=size.height,
                            tilesets={},
                        }
                    elseif size.width ~= patterns[id].width or size.height ~= patterns[id].height then
                        error("tile pattern has different size in different tilesets: " .. id)
                    end
                    table.insert(patterns[id].tilesets, tileset)
                end
                tileset_names[tileset] = true
            end
        end
    end
    for id, info in pairs(patterns) do
        if #info.tilesets == tileset_count then
            info.tilesets = nil
        else
            error(string.format("tile pattern present in %d of %d tilesets: %s", #info.tilesets, tileset_count, id))
        end
    end
    return tileset_names, patterns
end

local function validate_projectdb_components()
    local tilesets, patterns = get_patterns(zentropy.tilesets)
    --[[
    for k, v in pairs(zentropy.components.floors) do
        zentropy.debug('floor', k, v)
    end
    for k, v in pairs(zentropy.components.doors) do
        zentropy.debug('door', k, v)
    end
    for k, v in pairs(zentropy.components.enemies) do
        zentropy.debug('enemy', k, v)
    end
    ]]
    local fmt = "maps/%s.dat"
    for treasure_type, treasures in pairs(zentropy.components.treasures) do
        for i, treasure in ipairs(treasures) do
            validate_map(string.format(fmt, treasure.id), treasure.mask, tilesets, patterns)
        end
    end
    for obstacle_name, obstacle_data in pairs(zentropy.components.obstacles) do
        for dir, obstacles in pairs(obstacle_data) do
            for i, obstacle in ipairs(obstacles) do
                validate_map(string.format(fmt, obstacle.id), obstacle.mask, tilesets, patterns)
            end
        end
    end
    for k, v in pairs(zentropy.components.fillers) do
        validate_map(string.format(fmt, v.id), v.mask, tilesets, patterns)
    end
end

validate_projectdb_components()
zentropy.debug('DONE')
