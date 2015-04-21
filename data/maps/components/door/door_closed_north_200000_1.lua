local map, data = ...

local zentropy = require 'lib/zentropy'

local door = zentropy.inject_door(map:get_entity('doorway'), {
    savegame_variable = data.name,
    direction = 1,
    sprite = "entities/door_normal",
})
data.door_names.north = door:get_userdata():get_name()
map:set_doors_open(door:get_name(), true)
