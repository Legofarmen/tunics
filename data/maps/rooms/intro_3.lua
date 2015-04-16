local map = ...
local game = map:get_game()

function map:on_started()
		sol.audio.set_music_volume(25)
		hero:set_direction(0)
		hero:set_animation("dead")
		zentropy.debug("got to intro3")
		
end

function map:on_opening_transition_finished()
	if zentropy.game.game:get_value('restarted') == 1 then 
		map:get_sword()
	else
		hero:freeze()
		hero:set_animation("dead")
		sol.timer.start(500,function()
			game:start_dialog("intro_3_1", function()
				hero:set_animation("stopped")
				hero:set_direction(1)
				game:start_dialog("intro_3_2", function()
					map:get_sword()
				end)
			end)	
		end)
	end
end

function map:get_sword()
	hero:start_treasure('sword', 1, "i1129",function()
		sol.timer.start(200,function()
			hero:set_animation("stopped")
			hero:set_direction(1)
			map:open_doors("door")
			sol.timer.start(300, function()
				map.start_quest()
			end)
		end)
	end)
end

function map:start_quest()

	map:get_game():set_hud_enabled(true)
	map:get_game():set_pause_allowed(true)
	sol.audio.play_music("beginning")
	sol.audio.set_music_volume(100)

end