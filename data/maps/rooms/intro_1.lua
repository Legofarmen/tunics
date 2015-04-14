local map = ...

local hero = map:get_game():get_hero()
local zelda = map:get_entity('zelda')
local move_z = sol.movement.create("target")

function map:on_opening_transition_finished()
	hero:freeze()
	start_intro()
end

function start_intro()
	sol.timer.start(500,function()
		map:set_entities_enabled('cover', false)
		local move_h = sol.movement.create("straight")
		sol.audio.play_sound("hero_falls")
		hero:set_animation("falling",function()
			local x, y, layer = hero:get_position()
			hero:set_position(x+8,y,0)
		end)	
		sol.timer.start(200, move_zelda)
	end)
end

function move_zelda()
	zelda:get_sprite():set_animation("walking")
	move_z:start(zelda)
	sol.timer.start(500,function()
		zelda:get_sprite():set_animation("stopped")
		sol.timer.start(1000, function()
			return_zelda()
		end)
	end)
end

function return_zelda()
	local x, y, layer = hero:get_position()
	zelda:get_sprite():set_direction(0)
	move_z:set_speed(32)
	zelda:get_sprite():set_animation("walking")
	hero:set_position(x+40,y,0)
	sol.timer.start(1100,function()
		move_z:stop()
		zelda:get_sprite():set_direction(3)
	end)
		
end

function map:on_started()
	
	sol.audio.play_music("lost_woods")
			
    	
end
