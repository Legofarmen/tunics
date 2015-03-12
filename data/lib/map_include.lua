local x0 = 0
local y0 = 0
local map = nil

local mapmeta = sol.main.get_metatable('map')

function properties() end
function destination() end

function pickable(properties)
    properties.x = properties.x + x0
    properties.y = properties.y + y0
    map:create_pickable(properties)
end

function separator(properties)
    properties.x = properties.x + x0
    properties.y = properties.y + y0
    map:create_separator(properties)
end

function door(properties)
    properties.x = properties.x + x0
    properties.y = properties.y + y0
    map:create_door(properties)
end

function block(properties)
    properties.x = properties.x + x0
    properties.y = properties.y + y0
    map:create_block(properties)
end

function chest(properties)
    properties.x = properties.x + x0
    properties.y = properties.y + y0
    map:create_chest(properties)
end

local floor = 'floor.1'

function tile(properties)
    properties.x = properties.x + x0
    properties.y = properties.y + y0
    if properties.enabled_at_start == nil then
        properties.enabled_at_start = true
    end

    if properties.pattern == 'floor.1' then properties.pattern = floor or properties.pattern end

    map:create_dynamic_tile(properties)
end


function mapmeta:include(x, y, name, ...)
    local _,_,_,floor1 = ...
    floor = floor1

    local old_map, old_x0, old_y0 = map, x0, y0
    map, x0, y0 = self, x0 + x, y0 + y
    sol.main.load_file(string.format('maps/%s.dat', name))()
    sol.main.load_file(string.format('maps/%s.lua', name))(self, ...)
    map, x0, y0 = old_map, old_x0, old_y0
end
