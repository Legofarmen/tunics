local map = ...

local game = map:get_game()

local hero = map:get_game():get_hero()

function map:on_started()

end

function map:on_opening_transition_finished()
	hero:freeze()
	sol.timer.start(500, function()
		game:start_dialog("game_complete_2_1", function()
			sol.audio.play_sound("piece_of_heart")
			sol.timer.start(1000, function()
				sol.main.reset()
			end)
		end)
	end)
end