local util = require 'lib/util'

local mapmeta = sol.main.get_metatable('map')

local function component_map(map_userdata, component_x, component_y, component_prefix, data)
    local o = {}

    local component_entity = function (entity_userdata)
        if entity_userdata == nil then
            return nil
        end
        local component_name_start = string.len(component_prefix) + 1
        local entity = {}
        function entity:get_name()
            return string.sub(entity_userdata:get_name(), component_name_start)
        end
        function entity:get_position()
            local x, y, layer = entity_userdata:get_position()
            return x - component_x, y - component_y, layer
        end
        function entity:set_position(x, y, ...)
            return entity_userdata:set_position(x + component_x, y + component_y, ...)
        end
        function entity:get_userdata()
            return entity_userdata
        end
        function entity:get_map()
            return o
        end
        setmetatable(entity, {
            __index = function (table, key)
                if type(entity_userdata[key]) == 'function' then
                    return function (self, ...) return entity_userdata[key](entity_userdata, ...) end
                else
                    return entity_userdata[key]
                end
            end,
            __newindex = function (table, key, value)
                entity_userdata[key] = value
            end,
        })
        return entity
    end
    local add_prefix = function (name)
        if name == nil then
            return nil
        elseif string.sub(name, 0, 2) == '__' then
            return name
        else
            return component_prefix .. name
        end
    end

    local transform = function (properties)
        properties.x = properties.x + component_x
        properties.y = properties.y + component_y
        properties.name = add_prefix(properties.name)
        return properties
    end

    function o:create_block(properties) return component_entity(map_userdata:create_block(transform(properties))) end
    function o:create_bomb(properties) return component_entity(map_userdata:create_bomb(transform(properties))) end
    function o:create_chest(properties) return component_entity(map_userdata:create_chest(transform(properties))) end
    function o:create_crystal(properties) return component_entity(map_userdata:create_crystal(transform(properties))) end
    function o:create_crystal_block(properties) return component_entity(map_userdata:create_crystal_block(transform(properties))) end
    function o:create_custom_entity(properties) return component_entity(map_userdata:create_custom_entity(transform(properties))) end
    function o:create_destination(properties) return component_entity(map_userdata:create_destination(transform(properties))) end
    function o:create_destructible(properties) return component_entity(map_userdata:create_destructible(transform(properties))) end
    function o:create_door(properties) return component_entity(map_userdata:create_door(transform(properties))) end
    function o:create_enemy(properties) return component_entity(map_userdata:create_enemy(transform(properties))) end
    function o:create_explosion(properties) return component_entity(map_userdata:create_explosion(transform(properties))) end
    function o:create_fire(properties) return component_entity(map_userdata:create_fire(transform(properties))) end
    function o:create_jumper(properties) return component_entity(map_userdata:create_jumper(transform(properties))) end
    function o:create_npc(properties) return component_entity(map_userdata:create_npc(transform(properties))) end
    function o:create_pickable(properties) return component_entity(map_userdata:create_pickable(transform(properties))) end
    function o:create_sensor(properties) return component_entity(map_userdata:create_sensor(transform(properties))) end
    function o:create_separator(properties) return component_entity(map_userdata:create_separator(transform(properties))) end
    function o:create_shop_treasure(properties) return component_entity(map_userdata:create_shop_treasure(transform(properties))) end
    function o:create_stairs(properties) return component_entity(map_userdata:create_stairs(transform(properties))) end
    function o:create_stream(properties) return component_entity(map_userdata:create_stream(transform(properties))) end
    function o:create_switch(properties) return component_entity(map_userdata:create_switch(transform(properties))) end
    function o:create_teletransporter(properties) return component_entity(map_userdata:create_teletransporter(transform(properties))) end
    function o:create_wall(properties) return component_entity(map_userdata:create_wall(transform(properties))) end
    function o:create_dynamic_tile(properties)
        if properties.enabled_at_start == nil then properties.enabled_at_start = true end
        return component_entity(map_userdata:create_dynamic_tile(transform(properties)))
    end
    function o:get_entity(name)
        return component_entity(map_userdata:get_entity(add_prefix(name)))
    end
    function o:get_entities(prefix)
        local entities = {}
        for entity_userdata in map_userdata:get_entities(add_prefix(prefix)) do
            ce = component_entity(entity_userdata)
            entities[ce:get_name()] = ce
        end
        return util.values_by_keys(entities)
    end
    function o:has_entity(name)
        return map_userdata:has_entity(add_prefix(name))
    end
    function o:get_entities_count(prefix)
        return map_userdata:get_entities_count(add_prefix(prefix))
    end
    function o:has_entities(prefix)
        return map_userdata:has_entities(add_prefix(prefix))
    end
    function o:set_entities_enabled(prefix, enabled)
        return map_userdata:set_entities_enabled(add_prefix(prefix), enabled)
    end
    function o:remove_entities(prefix)
        return map_userdata:remove_entities(add_prefix(prefix))
    end
    function o:open_doors(prefix)
        return map_userdata:open_doors(add_prefix(prefix))
    end
    function o:close_doors(prefix)
        return map_userdata:close_doors(add_prefix(prefix))
    end
    function o:set_doors_open(prefix, open)
        return map_userdata:set_doors_open(add_prefix(prefix), open)
    end
    function o:include(x, y, name, data)
        return map_userdata:include(x + component_x, y + component_y, name, data)
    end
    function o:get_userdata()
        return map_userdata;
    end
    setmetatable(o, {
        __index = function (table, key)
            if type(map_userdata[key]) == 'function' then
                return function (self, ...) return map_userdata[key](map_userdata, ...) end
            else
                return map_userdata[key]
            end
        end,
    })
    return o
end


local counter = 0

function mapmeta:include(x, y, name, data)
    print(name)
    local component_prefix = string.format('__include_%d_', counter)
    counter = counter + 1

    local map = component_map(self, x, y, component_prefix, data)
    local datfile = string.format('maps/%s.dat', name)
    local datf = sol.main.load_file(datfile)
    if not datf then
        error("error: loading file: " .. datfile)
    end
    local datenv = setmetatable({}, {__index=function (table, key)
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
    setfenv(datf, datenv)()
    local luafile = string.format('maps/%s.lua', name)
    local luaf = sol.main.load_file(luafile)
    if not luaf then
        error("error: loading file: " .. luafile)
    end
    local luaenv = setmetatable({}, {__index=function (table, key)
        if _G[key] then
            return _G[key]
        else
            return map:get_entity(key)
        end
    end})
    local result = { pcall(setfenv(luaf, luaenv), map, data) }
    local success = table.remove(result, 1)
    if success then
        return unpack(result)
    else
        error("executing '" .. luafile .. "':\n" .. result[1])
    end
end
