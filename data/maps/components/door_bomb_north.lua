local map, data = ...

function door:on_opened()
    door_closed:set_enabled(false)
    top_closed:set_enabled(false)
end
