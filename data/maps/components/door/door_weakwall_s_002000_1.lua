local map, data = ...

local door_weakwall = require 'maps/components/door/door_weakwall'

return door_weakwall.init(map, data, 3)
