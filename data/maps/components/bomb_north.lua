local map, data = ...

local door = map:get_entity(data.id)
local closed = map:get_entity(data.id .. '_closed')

function door:on_opened()
    closed:set_enabled(false)
end
