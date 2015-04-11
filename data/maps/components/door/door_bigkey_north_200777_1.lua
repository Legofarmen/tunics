local map, data = ...

local zentropy = require 'lib/zentropy'

zentropy.inject_door(map:get_entity('doorway'), {
    direction = 1,
    sprite = "entities/door_big_key",
    opening_method = "interaction_if_savegame_variable",
    opening_condition = "bigkey",
})
