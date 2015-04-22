local map, data = ...

local door_open = require 'maps/components/door/door_open'

return door_open.init(map, data, 2)
