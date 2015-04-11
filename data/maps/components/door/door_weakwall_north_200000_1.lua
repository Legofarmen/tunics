local map, data = ...

local zentropy = require 'lib/zentropy'

local door = zentropy.inject_door(map:get_entity('doorway'), {
    direction = 1,
    sprite = "entities/door_weak_wall",
    opening_method = "explosion",
})

function door:on_opened()
    door_closed:set_enabled(false)
    top_open:set_enabled(true)
end
