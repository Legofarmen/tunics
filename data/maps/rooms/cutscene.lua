local map, data = ...
local game = map:get_game()

local zentropy = require 'lib/zentropy'

local cutscene = {}
local text = sol.language.get_dialog('tier_complete') 
local text_show = text.text:gsub("X", zentropy.game.game:get_value('tier'))

local skip = false

function map:on_started()
	game:set_hud_enabled(false)
	game:set_pause_allowed(false)
	sol.audio.stop_music()
    hero:set_direction(0)
	if zentropy.settings.skip_cinematics then
		cutscene:on_finished()
	end
end

function cutscene:on_started()
	cutscene.surface = sol.surface.create(320, 240)
	cutscene.text = sol.text_surface.create{
        font = "la",
		horizontal_alignment = "center",
		vertical_alignment = "middle",
		text = text_show,
	}
	cutscene.text:set_xy(170, 60)
end

function cutscene:on_draw(dst_surface)
	cutscene.text:set_color{255, 255, 255}
	cutscene.text:draw(dst_surface)
end

function cutscene:on_command_pressed(command)
    sol.menu.stop(self)
    return true
end

function cutscene:on_finished()
	zentropy.game.next_tier()
	game:get_hero():teleport('dungeons/dungeon1')
	sol.timer.start(game,2000, function()
		game:set_hud_enabled(true)
		game:set_pause_allowed(true)
	end)
end

function map:on_opening_transition_finished()
	hero:freeze()
	hero:set_animation("walking")
	map:get_entity("zelda"):get_sprite():set_animation("walking")
	local x, y, layer = map:get_entity('first'):get_position()
	local tier = game:get_value('tier')
	local tiern = 1

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
			width = 16,
			height = 16,
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
			sol.timer.start(800,function()
				sol.menu.start(map, cutscene, true)
			end)
		return false
			
			
		end
	end)
end
