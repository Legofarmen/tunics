local zentropy = require 'lib/zentropy'

function intersects(r1, r2)
    if r1.x + r1.width <= r2.x then return false end
    if r1.x >= r2.x + r2.width then return false end
    if r1.y + r1.height <= r2.y then return false end
    if r1.y >= r2.y + r2.height then return false end
    return true
end

function validate_entity_layer(fname, description, properties)
    if properties.layer == 0 then
        zentropy.debug(string.format("%s at low layer in component: %s", description, fname))
    end
end

function validate_entity_mask(fname, description, properties, sections)
    for i, section in ipairs(sections) do
        if intersects(section, properties) then
            zentropy.debug(string.format("%s outside mask in component: %s", description, fname))
        end
    end
end

function validate_entity_pot(fname, description, properties)
    if properties.pattern == 'floor_pot' then
        if not properties.name or not properties.name:find('^pot_') then
            zentropy.debug(string.format("%s not named pot_* in component: %s", description, fname))
        end
    elseif properties.name and properties.name:find('^pot_') then
        zentropy.debug(string.format("%s named pot_* in component: %s", description, fname))
    end
end

function read_component_map(fname, mask, tilesets, patterns)
    local all_sections = {
        { x = 176, y = 136, width = 120, height = 80, },
        { x = 144, y = 136, width =  32, height = 80, },
        { x =  24, y = 136, width = 120, height = 80, },
        { x = 176, y = 104, width = 120, height = 32, },
        { x = 144, y = 104, width =  32, height = 32, },
        { x =  24, y = 104, width = 120, height = 32, },
        { x = 176, y =  24, width = 120, height = 80, },
        { x = 144, y =  24, width =  32, height = 80, },
        { x =  24, y =  24, width = 120, height = 80, },
    }
    local i = 1
    local sections = {}
    for i = 1, 9 do
        if bit32.band(mask, bit32.lshift(1, i-1)) == 0 then
            table.insert(sections, all_sections[i])
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
        local description = string.format("custom_entity (%s)", properties.pattern)
        validate_entity_layer(fname, description, properties)
        validate_entity_mask(fname, description, properties, sections)
    end
    function mt.dynamic_tile(properties)
        local description = string.format("dynamic tile (%s)", properties.pattern)
        validate_entity_layer(fname, description, properties)
        validate_entity_mask(fname, description, properties, sections)
        validate_entity_pot(fname, description, properties)
    end
    function mt.jumper(properties)
        local description = string.format("jumper (%s)", properties.pattern)
        validate_entity_layer(fname, description, properties)
        validate_entity_mask(fname, description, properties, sections)
    end
    function mt.sensor(properties)
        local description = string.format("sensor (%s)", properties.pattern)
        validate_entity_layer(fname, description, properties)
        validate_entity_mask(fname, description, properties, sections)
    end
    function mt.tile(properties)
        local description = string.format("tile (%s)", properties.pattern)
        validate_entity_layer(fname, description, properties)
        validate_entity_mask(fname, description, properties, sections)
        validate_entity_pot(fname, description, properties)
    end
    function mt.wall(properties)
        local description = string.format("wall (%s)", properties.pattern)
        validate_entity_layer(fname, description, properties)
        validate_entity_mask(fname, description, properties, sections)
    end
    function mt.block(properties) end
    function mt.bomb(properties) end
    function mt.chest(properties) end
    function mt.crystal(properties) end
    function mt.crystal_block(properties) end
    function mt.destination(properties) end
    function mt.destructible(properties) end
    function mt.door(properties) end
    function mt.enemy(properties) end
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

function validate_projectdb_components()
    local tilesets, patterns = get_patterns(zentropy.tilesets)
    --[[
    for k, v in pairs(zentropy.components.floors) do
        zentropy.debug('floor', k, v)
    end
    for k, v in pairs(zentropy.components.treasures) do
        zentropy.debug('treasure', k, v)
    end
    for k, v in pairs(zentropy.components.doors) do
        zentropy.debug('door', k, v)
    end
    for k, v in pairs(zentropy.components.enemies) do
        zentropy.debug('enemy', k, v)
    end
    ]]
    local fmt = "maps/%s.dat"
    for obstacle_name, obstacle_data in pairs(zentropy.components.obstacles) do
        for dir, obstacles in pairs(obstacle_data) do
            for i, obstacle in ipairs(obstacles) do
                read_component_map(string.format(fmt, obstacle.id), obstacle.mask, tilesets, patterns)
            end
        end
    end
    for k, v in pairs(zentropy.components.fillers) do
        read_component_map(string.format(fmt, v.id), v.mask, tilesets, patterns)
    end
end

function read_tileset_tiles(fname)
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

function get_patterns(tilesets)
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

validate_projectdb_components()
zentropy.debug('DONE')