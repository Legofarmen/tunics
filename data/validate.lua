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

local high_layer_tiles = {
    ["ceiling"] = true,
    ["door_boss.1.pillar.1.top"] = true,
    ["door_boss.1.pillar.2.top"] = true,
    ["door_cache.1"] = true,
    ["door_cache.2"] = true,
    ["door_cache.3"] = true,
    ["door_cache.4"] = true,
    ["door_top.blast.1"] = true,
    ["door_top.blast.2"] = true,
    ["door_top.blast.3"] = true,
    ["door_top.blast.4"] = true,
    ["door_top.closed.1"] = true,
    ["door_top.closed.2"] = true,
    ["door_top.closed.3"] = true,
    ["door_top.closed.4"] = true,
    ["door_top.low.1"] = true,
    ["door_top.low.2"] = true,
    ["door_top.low.3"] = true,
    ["door_top.low.4"] = true,
    ["entrance_pillar.1.1.top"] = true,
    ["entrance_pillar.1.2.top"] = true,
    ["hole"] = true,
    ["pillar.top"] = true,
    ["torch_big.top"] = true,
    ["wall.3"] = true,
    ["wall.4"] = true,
    ["wall_hole.3"] = true,
    ["wall_hole.4"] = true,
}

local function rect_string(rect)
    zentropy.assert(rect)
    zentropy.assert(rect.x)
    zentropy.assert(rect.y)
    zentropy.assert(rect.width)
    zentropy.assert(rect.height)
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
    if properties.layer == 2 and not high_layer_tiles[properties.pattern] and properties.x ~= 0 and properties.x + properties.width ~= 320 then
        zentropy.debug(string.format("%s:  in high layer in component: %s", description, fname))
    end
end

local function validate_entity_mask(fname, description, properties, sections)
    local entire_room = { x = 0, y = 0, width = 320, height = 240, }
    if properties.pattern and properties.pattern:find('^door_cache.') then
        return
    end
    for name, rect in pairs(sections) do
        if intersects(rect, properties) then
            zentropy.debug(string.format("%s:  intersects with %s in component: %s", description, name, fname))
        end
        if not contains(entire_room, properties) then
            zentropy.debug(string.format("%s:  not contained within %s in component: %s", description, rect_string(entire_room), fname))
        end
    end
end

local function validate_entity_placeholder(fname, description, properties, counts)
    local floor_area = { x = 32, y = 32, width = 256, height = 176, }

    -- Pot
    if properties.pattern == 'floor_pot' then
        if not properties.name or not properties.name:find('^pot_') then
            zentropy.debug(string.format("%s:  not named pot_* in component: %s", description, fname))
        end
    elseif properties.name and properties.name:find('^pot_') then
        zentropy.debug(string.format("%s:  named pot* in component: %s", description, fname))
    end

    -- Stone
    if properties.pattern == 'placeholder_stone' then
        if not properties.name or not properties.name:find('^stone_') then
            zentropy.debug(string.format("%s:  not named stone_* in component: %s", description, fname))
        end
    elseif properties.name and properties.name:find('^stone_') then
        zentropy.debug(string.format("%s:  named stone* in component: %s", description, fname))
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
        if properties.name == 'treasure_obstacle_chest' then
            counts.treasure_obstacle_chest = (counts.treasure_obstacle_chest or 0) + 1
        else
            zentropy.debug(string.format("%s:  not named treasure_obstacle_chest in component: %s", description, fname))
        end
        if not contains(floor_area, properties) then
            zentropy.debug(string.format("%s:  not contained within %s in component: %s", description, rect_string(floor_area), fname))
        end
    elseif properties.name == 'treasure_obstacle_chest' then
        zentropy.debug(string.format("%s:  only tiles of pattern placeholder_treasure_obstacle or placeholder_treasure_puzzle may be named treasure_obstacle_chest in component: %s", description, fname))
    end

    -- Treasure open
    if properties.pattern == 'placeholder_treasure_open' then
        if properties.name == 'chest' then
            counts.chest = (counts.chest or 0) + 1
        elseif properties.name == 'treasure_open_chest' then
            counts.treasure_open_chest = (counts.treasure_open_chest or 0) + 1
        else
            zentropy.debug(string.format("%s:  named neither chest nor treasure_open_chest in component: %s", description, fname))
        end
        if not contains(floor_area, properties) then
            zentropy.debug(string.format("%s:  not contained within %s in component: %s", description, rect_string(floor_area), fname))
        end
    elseif properties.pattern == 'placeholder_treasure_block' then
        if properties.name == 'treasure_open_chest' then
            counts.treasure_open_chest = (counts.treasure_open_chest or 0) + 1
        else
            zentropy.debug(string.format("%s:  not named treasure_open_chest in component: %s", description, fname))
        end
        if not contains(floor_area, properties) then
            zentropy.debug(string.format("%s:  not contained within %s in component: %s", description, rect_string(floor_area), fname))
        end
    elseif properties.pattern == 'placeholder_bigchest' then
        if properties.name == 'chest' then
            counts.chest = (counts.chest or 0) + 1
        else
            zentropy.debug(string.format("%s:  not named chest in component: %s", description, fname))
        end
        if not contains(floor_area, properties) then
            zentropy.debug(string.format("%s:  not contained within %s in component: %s", description, rect_string(floor_area), fname))
        end
    elseif properties.name == 'chest' then
        zentropy.debug(string.format("%s:  only tiles of pattern placeholder_treasure_open or placeholder_bigchest may be named chest in component: %s", description, fname))
    elseif properties.name == 'treasure_open_chest' then
        zentropy.debug(string.format("%s:  only tiles of pattern placeholder_treasure_open or placeholder_treasure_block may be named treasure_open_chest in component: %s", description, fname))
    end

    -- Entrance floor
    if properties.pattern == 'door_main.2.floor.1' then
        if properties.name ~= 'entrance_carpet' then
            zentropy.debug(string.format("%s:  not named entrance_carpet in component: %s", description, fname))
        end
        if not contains(floor_area, properties) then
            zentropy.debug(string.format("%s:  not contained within %s in component: %s", description, rect_string(floor_area), fname))
        end
    elseif properties.name == 'entrance_carpet' then
        zentropy.debug(string.format("%s:  only tiles of pattern door_main.2.floor.1 may be named entrance_carpet in component: %s", description, fname))
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

local function validate_carpet_alignment(fname, description, properties)
    local directions = {
        north = {
            outer = { x = 0, y = 0, width = 320, height = 32, },
            middle = { x = 0, y = 0, width = 320, height = 40, },
            inner = { x = 0, y = 0, width = 320, height = 48, },
        },
        south = {
            outer = { x = 0, y = 208, width = 320, height = 32, },
            middle = { x = 0, y = 200, width = 320, height = 40, },
            inner = { x = 0, y = 192, width = 320, height = 48, },
        },
        east = {
            outer = { x = 288, y = 0, width = 32, height = 240, },
            middle = { x = 280, y = 0, width = 40, height = 240, },
            inner = { x = 272, y = 0, width = 48, height = 240, },
        },
        west = {
            outer = { x = 0, y = 0, width = 32, height = 240, },
            middle = { x = 0, y = 0, width = 40, height = 240, },
            inner = { x = 0, y = 0, width = 48, height = 240, },
        },
    }
    if properties.pattern == 'floor_border.2' then
        for dir, areas in pairs(directions) do
            if intersects(areas.middle, properties) then
                zentropy.debug(string.format("%s:  intersects with %s wall in component: %s", description, dir, fname))
            end
        end
    elseif properties.pattern == 'floor_small.2' then
        for dir, areas in pairs(directions) do
            if intersects(areas.outer, properties) then
                zentropy.debug(string.format("%s:  intersects with %s wall in component: %s", description, dir, fname))
            elseif intersects(areas.inner, properties) and not intersects(areas.middle, properties) then
                zentropy.debug(string.format("%s:  does not overlap %s wall border in component: %s", description, dir, fname))
            end
        end
    end
end

local function mark_pike_tile(properties, pikes)
    if properties.pattern == 'pike' then
        local x, y = properties.x, properties.y
        pikes[y] = pikes[y] or {}
        pikes[y][x] = pikes[y][x] or {
            pike = {},
            wall = {},
        }
        table.insert(pikes[y][x].pike, properties)
    end
end

local function mark_pike_wall(properties, pikes)
    local x, y = properties.x, properties.y
    pikes[y] = pikes[y] or {}
    pikes[y][x] = pikes[y][x] or {
        pike = {},
        wall = {},
    }
    table.insert(pikes[y][x].wall, properties)
end

function file_exists(name)
    local f=io.open(name,"r")
    if f~=nil then io.close(f) return true else return false end
end

local function validate_script(fname)
    if not file_exists(fname) then return end
    local luafname = '' .. fname:gsub('.dat$', '.lua')
    local f=io.open(luafname,"r")
    if f then
        if f:seek('end') == 0 then
            zentropy.debug(string.format('map script empty: %s', luafname))
        end
        io.close(f)
    else
        zentropy.debug(string.format('map script not found: %s', luafname))
    end
end

local function validate_map(fname, mask, tilesets, patterns)

    validate_script(fname)

    local all_sections = {
        { x = 176, y = 136, width = 144, height = 104, },
        { x = 144, y = 136, width =  32, height =  72, },
        { x =   0, y = 136, width = 144, height = 104, },
        { x = 176, y = 104, width = 108, height =  32, },
        { x = 144, y = 104, width =  32, height =  32, },
        { x =  32, y = 104, width = 108, height =  32, },
        { x = 176, y =   0, width = 144, height = 104, },
        { x = 144, y =  32, width =  32, height =  72, },
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
    local placeholder_counts = {}
    local pikes = {}

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
        local my_properties = {
            ["width"] = 16, ["height"] = 16,
        }
        for k,v in pairs(properties) do my_properties[k] = v end
        local description = string.format("custom entity %s", rect_string(my_properties))
        if my_properties.name then
            description = description .. string.format(" name=%s", my_properties.name)
        end
        validate_entity_layer(fname, description, my_properties)
        validate_entity_mask(fname, description, my_properties, sections)
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
        validate_entity_placeholder(fname, description, properties, placeholder_counts)
        validate_entity_alignment(fname, description, properties)
        validate_carpet_alignment(fname, description, properties)
        mark_pike_tile(properties, pikes)
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
        validate_entity_placeholder(fname, description, properties, placeholder_counts)
        validate_entity_alignment(fname, description, properties)
        validate_carpet_alignment(fname, description, properties)
        mark_pike_tile(properties, pikes)
    end
    function mt.wall(properties)
        local description = string.format("wall          %s", rect_string(properties))
        if properties.name then
            description = description .. string.format(" name=%s", properties.name)
        end
        validate_entity_layer(fname, description, properties)
        validate_entity_mask(fname, description, properties, sections)
        mark_pike_wall(properties, pikes)
    end
    function mt.enemy(properties)
        local description = string.format("enemy         %s", coord_string(properties))
        if properties.name then
            description = description .. string.format(" name=%s", properties.name)
        else
            description = description .. string.format(" breed=%s", properties.breed)
        end
    end
    function mt.switch(properties)
        local description = string.format("switch        %s", coord_string(properties))
        if properties.name then
            description = description .. string.format(" name=%s", properties.name)
        end
        if properties.name == 'switch' then
            placeholder_counts.switch = (placeholder_counts.switch or 0) + 1
        end
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
    function mt.teletransporter(properties) end
    setfenv(datf, mt)()
    return placeholder_counts, pikes
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

local function validate_obstacle_counts(fname, counts)
    local treasure_open_chest = counts.treasure_open_chest or 0
    local treasure_obstacle_chest = counts.treasure_obstacle_chest or 0

    if treasure_open_chest ~= 1 then
        zentropy.debug(string.format("obstacle:  expected 1 treasure_open_chest, got %d in component: %s", treasure_open_chest, fname))
    end
    if treasure_obstacle_chest ~= 1 then
        zentropy.debug(string.format("obstacle:  expected 1 treasure_obstacle_chest, got %d in component: %s", treasure_obstacle_chest, fname))
    end
end

local function validate_pikes(fname, pikes)
    for y, row in pairs(pikes) do
        for x, pos in pairs(row) do
            local description = string.format("pike %s", coord_string{x=x, y=y})
            pos.pike = pos.pike or {}
            pos.wall = pos.wall or {}
            if #pos.pike > 1 then
                zentropy.debug(string.format("%s:  expected 1 or less pike tiles, got %d in component: %s", description, #pos.pike, fname))
            elseif #pos.pike == 1 then
                local description = string.format("pike %s", rect_string(pos.pike[1]))
                if #pos.wall ~= 1 then
                    zentropy.debug(string.format("%s:  expected 1 walls, got %d in component: %s", description, #pos.wall, fname))
                else
                    if pos.pike[1].width ~= pos.wall[1].width or pos.pike[1].height ~= pos.wall[1].height then
                        zentropy.debug(string.format("%s:  pike tile %s and wall %s have different size in component: %s", description, rect_string(pos.pike[1]), rect_string(pos.wall[1]), fname))
                    end
                    if pos.wall[1].stops_hero then
                        zentropy.debug(string.format("%s:  wall must not stop hero in component: %s", description, fname))
                    end
                    if not pos.wall[1].stops_enemies then
                        zentropy.debug(string.format("%s:  wall must not stop enemies in component: %s", description, fname))
                    end
                    if not pos.wall[1].stops_blocks then
                        zentropy.debug(string.format("%s:  wall must not stop blocks in component: %s", description, fname))
                    end
                    if not pos.wall[1].stops_projectiles then
                        zentropy.debug(string.format("%s:  wall must not stop projectiles in component: %s", description, fname))
                    end
                end
            end
        end
    end
end

local function validate_projectdb_components()

    if not file_exists('project_db.dat') then
        zentropy.debug('WARNING: unable to validate scripts')
    end

    local tilesets, patterns = get_patterns(zentropy.tilesets)
    --[[
    for k, v in pairs(zentropy.components.floors) do
        zentropy.debug('floor', k, v)
    end
    for k, v in pairs(zentropy.components.enemies) do
        zentropy.debug('enemy', k, v)
    end
    ]]
    local fmt = "maps/%s.dat"
    for door_type, doors in pairs(zentropy.components.doors) do
        for dir_name, dir_components in pairs(doors) do
            for i, component in ipairs(dir_components) do
                local fname = string.format(fmt, component.id)
                local counts, pikes = validate_map(fname, component.mask, tilesets, patterns)
                validate_pikes(fname, pikes)
            end
        end
    end
    for treasure_type, treasures in pairs(zentropy.components.treasures) do
        for i, component in ipairs(treasures) do
            local fname = string.format(fmt, component.id)
            local counts, pikes = validate_map(fname, component.mask, tilesets, patterns)
            validate_pikes(fname, pikes)
        end
    end
    for obstacle_name, obstacle_data in pairs(zentropy.components.obstacles) do
        for dir, obstacles in pairs(obstacle_data) do
            for i, obstacle in ipairs(obstacles) do
                local fname = string.format(fmt, obstacle.id)
                local counts, pikes = validate_map(fname, obstacle.mask, tilesets, patterns)
                validate_obstacle_counts(fname, counts)
                validate_pikes(fname, pikes)
            end
        end
    end
    for k, component in pairs(zentropy.components.fillers) do
        local fname = string.format(fmt, component.id)
        local counts, pikes = validate_map(fname, component.mask, tilesets, patterns)
        validate_pikes(fname, pikes)
    end
end

validate_projectdb_components()
zentropy.debug('DONE')
