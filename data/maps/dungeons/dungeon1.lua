local map = ...

local game = map:get_game()



map:include(3200-160, 2400-120, 'rooms/room1', 'here', 'be', 'dragons')
map:include(3200-160, 2400-120-240, 'rooms/room1', 'here', 'be', 'dragons')

local x0 = 3200-160
local y0 = 2400-120

map:create_dynamic_tile{ layer = 1, x = x0 + 144, y = y0 - 16, width = 16, height = 32, pattern = "ceiling", enabled_at_start = true }
map:create_dynamic_tile{ layer = 1, x = x0 + 136, y = y0 - 8, width = 8, height = 16, pattern = "barrier.2", enabled_at_start = true }
map:create_dynamic_tile{ layer = 1, x = x0 + 160, y = y0 - 8, width = 8, height = 16, pattern = "barrier.2", enabled_at_start = true }
