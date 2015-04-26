local map, data = ...

local util = require 'lib/util'

map:include(0, 0, 'components/door/door_open_north_200000_1', {room_events=data.room_events})

local agahnim = map:get_entity("agahnim"):get_userdata()
zentropy.debug("map")

local x1, y1 = map:get_entity('boss_1'):get_userdata():get_position()
table.insert(agahnim.positions, {x = x1, y = y1, direction4 = 3})
local x2, y2 = map:get_entity('boss_2'):get_userdata():get_position()
table.insert(agahnim.positions, {x = x2, y = y2, direction4 = 0})
local x3, y3 = map:get_entity('boss_3'):get_userdata():get_position()
table.insert(agahnim.positions, {x = x3, y = y3, direction4 = 2})