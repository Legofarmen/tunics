local map, data = ...

local door_closed = require 'maps/components/door/door_closed'

return door_closed.init(map, data, 1)
