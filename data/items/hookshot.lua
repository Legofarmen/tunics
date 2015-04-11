local item = ...

local game = item:get_game()

function item:on_created()

    item:set_savegame_variable('hookshot')
    item:set_assignable()
end

function item:on_obtained()

    zentropy.game.assign_item(self)
end

function item:on_using()

    game:get_hero():start_hookshot()
end
