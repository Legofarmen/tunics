local mapmeta = sol.main.get_metatable('map')

local counter = 0

function room_map(map, x, y, data)

    local userdata
    if map.get_userdata then
        userdata = map:get_userdata()
    else
        userdata = map
    end

    local internal_prefix = string.format('__include_%d_', counter)

    counter = counter + 1

    local rewrite
    if data.rewrite then
        rewrite = function (properties)
            if properties.name then
                if data.rewrite[properties.name] then
                    properties = data.rewrite[properties.name](properties)
                end
                if properties.name then
                    properties.name = internal_prefix .. properties.name
                end
            end
            return properties
        end
    else
        rewrite = function (properties) return properties end
    end
    local translate = function (properties)
        local old_x, old_y = properties.x, properties.y
        properties.x = properties.x + x
        properties.y = properties.y + y
        return properties
    end
    local o = {}
    function o:get_userdata()
        return userdata
    end
    function o:create_chest(properties)
        return map:create_chest(translate(rewrite(properties)))
    end
    function o:create_block(properties)
        return map:create_block(translate(rewrite(properties)))
    end
    function o:create_separator(properties)
        return map:create_separator(translate(rewrite(properties)))
    end
    function o:create_pickable(properties)
        return map:create_pickable(translate(rewrite(properties)))
    end
    function o:create_enemy(properties)
        return map:create_enemy(translate(rewrite(properties)))
    end
    function o:create_wall(properties)
        return map:create_wall(translate(rewrite(properties)))
    end
    function o:create_npc(properties)
        return map:create_npc(translate(rewrite(properties)))
    end
    function o:create_door(properties)
        return map:create_door(translate(rewrite(properties)))
    end
    function o:create_dynamic_tile(properties)
        if properties.enabled_at_start == nil then properties.enabled_at_start = true end
        return map:create_dynamic_tile(translate(rewrite(properties)))
    end
    setmetatable(o, {
        __index=function (table, key)
            if key ~= 'include' and type(map[key]) == 'function' then
                return function (self, ...)
                    return map[key](userdata, ...)
                end
            elseif map[key] then
                return map[key]
            else
                return userdata:get_entity(internal_prefix .. key)
            end
        end
    })
    return o
end

function mapmeta:include(x, y, name, data)
    local map = room_map(self, x, y, data)
    local datf = assert(sol.main.load_file(string.format('maps/%s.dat', name)))
    local env = setmetatable({}, {__index=function (table, key)
        if key == 'properties' then
            return function()end
        end
        local method
        if key == 'tile' then
            method = map.create_dynamic_tile
        else
            method = map['create_' .. key]
        end
        return function (properties)
            method(map, properties)
        end
    end})
    setfenv(datf, env)()
    sol.main.load_file(string.format('maps/%s.lua', name))(map, data)
end
