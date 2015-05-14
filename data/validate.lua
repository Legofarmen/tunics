local zentropy = require 'lib/zentropy'

function validate_projectdb_components()
    local patterns = get_patterns(zentropy.tilesets)
    --[[
    for k, v in pairs(zentropy.components.floors) do
        zentropy.debug('floor', k, v)
    end
    for k, v in pairs(zentropy.components.treasures) do
        zentropy.debug('treasure', k, v)
    end
    for k, v in pairs(zentropy.components.obstacles) do
        zentropy.debug('obstacle', k, v)
    end
    for k, v in pairs(zentropy.components.doors) do
        zentropy.debug('door', k, v)
    end
    for k, v in pairs(zentropy.components.enemies) do
        zentropy.debug('enemy', k, v)
    end
    for k, v in pairs(zentropy.components.fillers) do
        for j, u in pairs(v) do
            zentropy.debug('filler', k, j, u)
        end
    end
    ]]
    zentropy.debug_callback(function (write)
        for id, size in pairs(patterns) do
            write(string.format("%2dx%2d %s", size.width, size.height, id))
        end
    end)
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
            end
        end
    end
    for id, info in pairs(patterns) do
        if #info.tilesets == tileset_count then
            info.tilesets = nil
        else
            error("tile pattern not present in all tilesets: " .. id)
        end
    end
    return patterns
end

validate_projectdb_components()
zentropy.debug('DONE')