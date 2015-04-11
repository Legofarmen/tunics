local map, data = ...

local zentropy = require 'lib/zentropy'

local door = zentropy.inject_door(map:get_entity('doorway'), {
    savegame_variable = data.name,
    direction = 0,
    sprite = "entities/door_very_weak_wall",
    opening_method = "explosion",
})

function door:on_opened()
    door_closed:set_enabled(false)
    top_open:set_enabled(true)
end
