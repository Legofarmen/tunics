local zentropy = require 'lib/zentropy'
local game_menu = require 'menus/game_menu'

function sol.main:on_started()

    zentropy.init()
    sol.language.set_language("en")
    sol.menu.start(self, game_menu)
	sol.audio.preload_sounds()
end
