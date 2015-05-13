local zentropy = require 'lib/zentropy'
local title_screen = require 'menus/title_screen'
local solarus_logo = require 'menus/solarus_logo'
local legofarmen_logo = require 'menus/legofarmen_logo'
local game_menu = require 'menus/game_menu'
local entity_mixin = require 'lib/entity_mixin'
local bindings = require 'lib/bindings'

function sol.main:on_started()

    entity_mixin.mixin(sol.main.get_metatable('enemy'))
    bindings.mixin(solarus_logo)
    bindings.mixin(legofarmen_logo)
    bindings.mixin(title_screen)
    bindings.mixin(game_menu)

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

function sol.main:on_finished()
    if zentropy.game.game then
        zentropy.game.game:save()
    end
end
