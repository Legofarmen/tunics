local map = ...
local game = map:get_game()

-- Intro script.

function map:on_started(destination)
	hero:freeze()
	sol.audio.play_music("lost_woods")
	sol.audio.set_music_volume(50)
	game:set_hud_enabled(false)
	game:set_pause_allowed(false)
	game.dialog_box:set_dialog_style("empty")
	--game.dialog_box.set_dialog_style(game.dialog_box, "empty")
	
	sol.timer.start(500, function()
		game:start_dialog("intro_1_1", function()
			game:start_dialog("intro_1_2", function()
				hero:teleport("rooms/intro_2")
			end)
		end)
	end)
end