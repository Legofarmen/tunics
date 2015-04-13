local map = ...

function map:on_started()
    
end

function map:on_opening_transition_finished()
	if zentropy.settings.skip_cinematics then
		zentropy.game.game:set_ability('sword', 1)
		map:get_game():get_hero():teleport('dungeons/dungeon1')	
		
	else
		hero:freeze()
 		hero:set_direction(1)
		sol.timer.start(500,intro_2_dialog_1)
	end
end

function intro_2_dialog_1()
	--dialog: on_finished
	 hero:start_treasure('sword', 1, "i1129",function()
		sol.timer.start(200,function()
			map:open_doors("door")
			sol.timer.start(300, function()
				sol.audio.play_music("beginning")
				
			end)
		end)
	 end)
		
	 
	 
	 
	
end
