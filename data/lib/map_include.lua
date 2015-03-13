local x0 = 0
local y0 = 0
local map0 = nil
local data0 = nil

local mapmeta = sol.main.get_metatable('map')

function properties() end
function destination() end

function wall(properties)
    properties.x = properties.x + x0
    properties.y = properties.y + y0
    map0:create_wall(properties)
end

function enemy(properties)
    properties.x = properties.x + x0
    properties.y = properties.y + y0
    map0:create_enemy(properties)
end

function pickable(properties)
    properties.x = properties.x + x0
    properties.y = properties.y + y0
    map0:create_pickable(properties)
end

function separator(properties)
    properties.x = properties.x + x0
    properties.y = properties.y + y0
    map0:create_separator(properties)
end

function door(properties)
    properties.x = properties.x + x0
    properties.y = properties.y + y0
    if data0 and data0.name then
        if properties.name then
            properties.name = properties.name:gsub('${name}', data0.name)
        end
        if properties.savegame_variable then
            properties.savegame_variable = properties.savegame_variable:gsub('${name}', data0.name)
        end
    end
    map0:create_door(properties)
end

function block(properties)
    properties.x = properties.x + x0
    properties.y = properties.y + y0
    map0:create_block(properties)
end

function chest(properties)
    properties.x = properties.x + x0
    properties.y = properties.y + y0
    map0:create_chest(properties)
end

function tile(properties)
    properties.x = properties.x + x0
    properties.y = properties.y + y0
    if properties.enabled_at_start == nil then
        properties.enabled_at_start = true
    end
    map0:create_dynamic_tile(properties)
end
function dynamic_tile(properties)
    properties.x = properties.x + x0
    properties.y = properties.y + y0
    if properties.enabled_at_start == nil then
        properties.enabled_at_start = true
    end
    if data0 and data0.name and properties.name then
        properties.name = properties.name:gsub('${name}', data0.name)
    end
    map0:create_dynamic_tile(properties)
end


function mapmeta:include(x, y, name, data)
    local old_map0, old_data0, old_x0, old_y0 = map0, data0, x0, y0
    map0, data0, x0, y0 = self, data, x0 + x, y0 + y
    sol.main.load_file(string.format('maps/%s.dat', name))()
    sol.main.load_file(string.format('maps/%s.lua', name))(self, data)
    map0, data0, x0, y0 = old_map0, old_data0, old_x0, old_y0
end
