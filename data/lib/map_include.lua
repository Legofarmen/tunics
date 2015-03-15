local mapmeta = sol.main.get_metatable('map')

function properties() end
function destination() end

function room_map(map, x, y, data)
    local replace = function (field, properties)
        if data and data.name and properties[field] then
            properties[field] = properties[field]:gsub('${name}', data.name)
        end
        return properties
    end
    local translate = function (properties)
        local old_x, old_y = properties.x, properties.y
        properties.x = properties.x + x
        properties.y = properties.y + y
        return properties
    end
    local o = {}
    function o:get_userdata()
        if map.get_userdata then
            return map.get_userdata
        else
            return map
        end
    end
    function o:create_chest(properties)
        return map:create_chest(translate(properties))
    end
    function o:create_block(properties)
        return map:create_block(translate(properties))
    end
    function o:create_separator(properties)
        return map:create_separator(translate(properties))
    end
    function o:create_pickable(properties)
        return map:create_pickable(translate(properties))
    end
    function o:create_enemy(properties)
        return map:create_enemy(translate(properties))
    end
    function o:create_wall(properties)
        return map:create_wall(translate(properties))
    end
    function o:create_npc(properties)
        return map:create_npc(replace('name', translate(properties)))
    end
    function o:create_door(properties)
        map:create_door(translate(replace('savegame_variable', replace('name', properties))))
    end
    function o:create_dynamic_tile(properties)
        if properties.enabled_at_start == nil then properties.enabled_at_start = true end
        return map:create_dynamic_tile(translate(replace('name', properties)))
    end
    setmetatable(o, {
        __index=function (table, key)
            if key ~= 'include' and type(map[key]) == 'function' then
                return function (self, ...)
                    return map[key](o:get_userdata(), ...)
                end
            else
                return map[key]
            end
        end
    })
    return o
end

function mapmeta:include(x, y, name, data)
    local map = room_map(self, x, y, data)
    local datf = sol.main.load_file(string.format('maps/%s.dat', name))
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
