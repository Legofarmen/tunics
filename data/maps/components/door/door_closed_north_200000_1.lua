local map, data = ...

local zentropy = require 'lib/zentropy'

local door = zentropy.inject_door(map:get_entity('doorway'), {
    direction = 1,
    sprite = "entities/door_normal",
})
data.door_names.north = door:get_userdata():get_name()
