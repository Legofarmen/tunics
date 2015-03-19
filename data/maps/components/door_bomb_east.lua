local map, data = ...

local door = map.door
local closed = map.door_closed

function door:on_opened()
    closed:set_enabled(false)
end
