local map, data = ...

local util = require 'lib/util'

map:include(0, 0, 'components/door/door_open_north_200000_1', {room_events=data.room_events})
