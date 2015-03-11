local x0 = 0
local y0 = 0
local map = nil

local mapmeta = sol.main.get_metatable('map')
function mapmeta:include(x, y, map_id)
    print('here', x, y, map_id)
end

function properties() end
function destination() end
function pickable() end

function tile(properties)
    properties.x = properties.x + x0
    properties.y = properties.y + y0
    if properties.enabled_at_start == nil then
        properties.enabled_at_start = true
    end
    map:create_dynamic_tile(properties)
end

function mapmeta:include(x, y, name, ...)
    local old_map, old_x0, old_y0 = map, x0, y0
    map, x0, y0 = self, x0 + x, y0 + y
    sol.main.load_file(string.format('maps/%s.dat', name))()
    sol.main.load_file(string.format('maps/%s.lua', name))(self, ...)
    map, x0, y0 = old_map, old_x0, old_y0
end
