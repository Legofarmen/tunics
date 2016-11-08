local map = ...
local game = map:get_game()

local start_destination = nil

function map:on_started(destination)
	start_destination = destination:get_name()
	sol.audio.set_music_volume(25)
	
	if start_destination ~= 'retry' then
		hero:set_animation("dead")
		hero:set_direction(0)
	end
	if start_destination == 'endgame' then
		map:set_entities_enabled('light_2', true)
	end
end

function map:on_opening_transition_finished()
	if start_destination == 'retry' then
		map:get_sword()
	elseif start_destination == 'endgame' then
		hero:freeze()
		hero:set_animation("dead")
		sol.timer.start(100,function()
			game:start_dialog("game_complete_3_1", function()
				hero:set_animation("stopped")
				hero:set_direction(1)
				game:start_dialog("game_complete_3_2", function()
					map:open_doors("game_complete")
					sol.timer.start(300, function()
						map.start_quest()
					end)
				end)
			end)	
		end)
	else
		hero:freeze()
		hero:set_animation("dead")
		sol.timer.start(100,function()
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
        hero:start_treasure('shield', 1, "i1130")
        sol.timer.start(200,function()
            hero:set_animation("stopped")
            hero:set_direction(1)
            map:open_doors("first")
            sol.timer.start(500, function()
                map.start_quest()
            end)
        end)
    end)
end



function map:start_quest()
	hero:unfreeze()
	map:get_game():set_hud_enabled(true)
	map:get_game():set_pause_allowed(true)
	sol.audio.play_music("beginning")
	sol.audio.set_music_volume(100)

end
