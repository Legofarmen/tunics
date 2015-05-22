local map, data = ...

local door_closed = require 'maps/components/door/door_closed'

local destination = ""

if map:get_game():get_value('tier') == 6 then
	destination = "rooms/game_complete_1"
else
	destination = "rooms/cutscene"
end

local x, y, layer = map:get_entity('stairs'):get_position()

map:create_teletransporter({
		layer = layer,
		x = x,
		y = y,
		width = 16,
		height = 16,
		destination_map = destination,
})

return door_closed.init(map, data, 1)


