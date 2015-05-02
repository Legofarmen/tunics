local map, data = ...

local door_closed = require 'maps/components/door/door_closed'

local destination = ""

if zentropy.game.game:get_value('tier') == 6 then
	destination = "rooms/game_complete_1"
else
	destination = "rooms/cutscene"

end

map:create_teletransporter({
		layer = 1,
		x = 152,
		y = 16,
		width = 16,
		height = 16,
		destination_map = destination,
})

return door_closed.init(map, data, 1)


