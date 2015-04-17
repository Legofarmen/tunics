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

function sol.main:on_key_pressed(key, modifiers)

  local handled = false

  -- Normal features.
  if not handled then

    if key == "f5" then
      -- F5: change the video mode.
      sol.video.switch_mode()
    elseif key == "return" and (modifiers.alt or modifiers.control)
        or key == "f11" then
      -- Alt + Return or Ctrl + Return or F11: switch fullscreen.
      sol.video.set_fullscreen(not sol.video.is_fullscreen())
    elseif key == "f4" and modifiers.alt then
      -- Alt + F4: stop the program.
      sol.main.exit()
	elseif key == "h" then
		zentropy.game.game:set_hud_enabled(false)
    end
  end

  return handled
end
