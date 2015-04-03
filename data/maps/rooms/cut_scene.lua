local map, data = ...
local game = map:get_game()

function map:on_started()
    game:set_value('tier', game:get_value('tier'))
    game:get_hero():teleport('dungeons/dungeon1')
end
