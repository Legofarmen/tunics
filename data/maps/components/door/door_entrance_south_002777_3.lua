local map, data = ...

local door_entrance = require 'maps/components/door/door_entrance'

return door_entrance.init(map, data, 3)
