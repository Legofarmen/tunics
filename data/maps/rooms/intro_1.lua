local map = ...
function map:on_started()
    map:get_game():get_hero():teleport('dungeons/dungeon1')
end
