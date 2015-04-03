local map, data = ...
local game = map:get_game()

local zentropy = require 'lib/zentropy'

function map:on_started()
    zentropy.game.next_tier()
    game:get_hero():teleport('dungeons/dungeon1')
end
