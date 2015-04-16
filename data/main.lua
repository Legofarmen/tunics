local zentropy = require 'lib/zentropy'
local title_screen = require 'menus/title_screen'
local solarus_logo = require 'menus/solarus_logo'
local legofarmen_logo = require 'menus/legofarmen_logo'
local game_menu = require 'menus/game_menu'

function sol.main:on_started()
	
    zentropy.init()
		    
	sol.language.set_language("en")
    
	if zentropy.settings.skip_cinematics then
		sol.menu.start(self, game_menu)
	else
		sol.menu.start(self, solarus_logo)
		solarus_logo.on_finished = function()
			sol.menu.start(self, legofarmen_logo)
		end

		legofarmen_logo.on_finished = function()
			sol.menu.start(self, title_screen)
		end
		
		title_screen.on_finished = function()
			sol.menu.start(self, game_menu)
		end
	end

end
