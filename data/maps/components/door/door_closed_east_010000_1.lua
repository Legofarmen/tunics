local map, data = ...

local zentropy = require 'lib/zentropy'

local door = zentropy.inject_door(map:get_entity('doorway'), {
    direction = 0,
    sprite = "entities/door_normal",
})
data.door_names.east = door:get_userdata():get_name()
