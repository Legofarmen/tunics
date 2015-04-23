local map, data = ...
local game = map:get_game()

local zentropy = require 'lib/zentropy'

local game_over = {}
local text = sol.language.get_dialog('game_over') 
local text_show = text.text:gsub("X", zentropy.game.game:get_value('tier'))

function map:on_started()
	hero:set_animation("dead")
		
end

function map:on_opening_transition_finished()
	hero:freeze();
	hero:set_animation("dead")
		
	local x, y, layer = map:get_entity('first'):get_position()
	local tier = game:get_value('tier')
	local tiern = 1
	
	x = x + 8 
	y = y + 13
	
	for tiern = 0 , tier, 1 do
		sol.audio.play_sound("heart")
		tunic = map:create_custom_entity{
			sprite="entities/tunic_1",
			direction=0,
			layer=1,
			x = x,
			y = y,
		}
	end
	
	sol.timer.start(800,function()
		sol.menu.start(map, game_over, true)
	end)
	sol.timer.start(2000, game_over.menu)
end

function game_over:on_started()
	self.surface = sol.surface.create(320, 240)
	self.text = sol.text_surface.create{
        font = "dialog",
		horizontal_alignment = "center",
		vertical_alignment = "middle",
		text = text_show,
	}
	self.text:set_xy(170, 60)
end

function game_over:on_draw(dst_surface)
	self.text:set_color{255, 255, 255}
	self.text:draw(dst_surface)
end

function game_over:menu()
    
	game:start_dialog("try_again", function(answer)
		if answer == 1 then
			
			--todo, NEW new game
			
			zentropy.game.new_game(true)
			
		else
			
			sol.main.reset()
		end
	end)
end

function game_over:on_finished()
	
end

