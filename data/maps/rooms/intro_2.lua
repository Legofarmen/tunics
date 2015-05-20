local map = ...

local game = map:get_game()

local hero = map:get_game():get_hero()
local zelda = map:get_entity('zelda')

function map:on_started()

end

function map:on_opening_transition_finished()
	hero:freeze()
	sol.timer.start(150, function()
		map:start_intro()
	end)
end

function map:start_intro()
	game.dialog_box:set_dialog_style("box")
	game:start_dialog("intro_2_1")
	sol.timer.start(250,function()
		sol.audio.play_sound('door_closed')
		map:set_entities_enabled('cover', false)
		sol.audio.play_sound("hero_falls")
		
		hero:set_animation("falling",function()
			local x, y, layer = hero:get_position()
			hero:set_position(x+8,y,0)
		end)	
		
		local move_h = sol.movement.create("straight")
		local move_z_1 = sol.movement.create("target")
		move_z_1:set_target(map:get_entity("target_1"), 0, 5)
		move_z_1:set_speed(128)
		
		local move_z_2 = sol.movement.create("target")
		move_z_2:set_target(map:get_entity("target_2"), 0, 5)
		move_z_2:set_speed(64)
		function move_z_1:on_finished()
			zelda:get_sprite():set_animation("stopped")
			game:start_dialog("intro_2_2")
			sol.timer.start(500,function()
				game:start_dialog("intro_2_3")
				sol.timer.start(1000,function()
					zelda:get_sprite():set_direction(3)
					game:start_dialog("intro_2_4")
					zelda:get_sprite():set_direction(0)
					zelda:get_sprite():set_animation("walking")
					move_z_2:start(zelda)
				end)
			end)
		end
		
		function move_z_2:on_finished()
			zelda:get_sprite():set_direction(3)
			sol.timer.start(1000, map.transport)
		end
		
		sol.timer.start(400, function()
			zelda:get_sprite():set_animation("walking")
			move_z_1:start(zelda)

		end)
	end)
end

function map:transport()
	map:get_game():get_hero():teleport('rooms/intro_3')

end