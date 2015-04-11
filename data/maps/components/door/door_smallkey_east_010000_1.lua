local map, data = ...

local zentropy = require 'lib/zentropy'

zentropy.inject_door(map:get_entity('doorway'), {
    savegame_variable = data.name,
    direction = 0,
    sprite = "entities/door_small_key",
    opening_method = "interaction_if_savegame_variable",
    opening_condition = "small_key_amount",
    opening_condition_consumed = true,
})
