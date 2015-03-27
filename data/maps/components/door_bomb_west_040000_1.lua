local map, data = ...

local door_u = door:get_userdata()

function door_u:on_opened()
    door_closed:set_enabled(false)
    top_open:set_enabled(true)
end
