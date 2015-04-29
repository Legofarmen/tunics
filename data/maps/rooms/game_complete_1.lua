local map = ...

local game = map:get_game()

local hero = map:get_game():get_hero()
local zelda = map:get_entity('zelda')

function map:on_started()
	game:set_hud_enabled(false)
	game:set_pause_allowed(false)
	sol.audio.stop_music()
	sol.audio.play_music("lost_woods")
	sol.audio.set_music_volume(50)
	game.dialog_box:set_dialog_style("box")
end

function map:on_opening_transition_finished()
	hero:freeze()
	sol.timer.start(500, function()
		map:start_intro()
	end)
end

function map:start_intro()
	zelda:get_sprite():set_direction(1)
	local move_h = sol.movement.create("target")
	move_h:set_target(map:get_entity("hero_1"),0,-6)
	move_h:set_speed(64)
	game:start_dialog("game_complete_1_1", function()
		move_h:start(hero)
		hero:set_animation("walking")
		function move_h:on_finished()
			zelda:get_sprite():set_direction(2)
			hero:set_direction(0)
			hero:set_animation("stopped")
			game:start_dialog("game_complete_1_2", function()
				game:start_dialog("game_complete_1_3", function(answer)
					if answer == 1 then
						hero:teleport('rooms/game_complete_2')
					else
						sol.timer.start(500, function()
							sol.audio.play_sound('door_closed')
							sol.audio.play_sound("hero_falls")
							hero:set_direction(1)
							map:set_entities_enabled('cover', false)
							hero:set_animation("falling",function()
								local x, y, layer = hero:get_position()
								hero:set_position(x+80, y ,0)
								sol.timer.start(700, function()
									game:start_dialog("game_complete_1_4", function()
										zelda:get_sprite():set_direction(3)
										zelda:get_sprite():set_animation("walking")
										sol.timer.start(map, 1000, function()
											hero:teleport('dungeons/dungeon1')
										end)
									end)
								end)
							end)
						end)
					end
				end)
			end)
		end
	end)
end
