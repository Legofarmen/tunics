local map, data = ...

function door:on_opened()
    door_closed:set_enabled(false)
    top_open:set_enabled(true)
end
