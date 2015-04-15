local map, data = ...
local game = map:get_game()

local zentropy = require 'lib/zentropy'

local skip = false

function map:on_started()
	game:set_hud_enabled(false)
	game:set_pause_allowed(false)
	sol.audio.stop_music()
    hero:set_direction(0)
	--if zentropy.settings.skip_cinematics then
	--	zentropy.game.next_tier()
	--	game:get_hero():teleport('dungeons/dungeon1')
	--end
end

function map:on_opening_transition_finished()
	hero:freeze()
	hero:set_animation("walking")
	map:get_entity("zelda"):get_sprite():set_animation("walking")
	local x, y, layer = map:get_entity('first'):get_position()
	local tier = game:get_value('tier')
	local tiern = 1
	
	zentropy.debug("tier " .. tier)
	zentropy.debug("tiern " .. tiern)
	
	x = x + 8 
	y = y + 13
	
	sol.timer.start(200, function()
		sol.audio.play_sound("heart")
		tunic = map:create_custom_entity{
			sprite="entities/tunic_1",
			direction=0,
			layer=1,
			x = x,
			y = y,
		}

		x=x-16
		if tiern % 6 == 0 then
			y=y+16
			x=x+96

		end
		tiern = tiern + 1
		if tiern <= tier then
			return true 
		else
			game.dialog_box:set_dialog_style("empty")
			
			game:start_dialog("tier_complete", function()
				zentropy.game.next_tier()
				game:get_hero():teleport('dungeons/dungeon1')
				game.dialog_box:set_dialog_style("box")
				sol.timer.start(game, 1200, function()
					game:set_hud_enabled(true)
					game:set_pause_allowed(true)
				end)
			end)
			return false
		end
	end)
end