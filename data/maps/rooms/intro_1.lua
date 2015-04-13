local map = ...
function map:on_started()
    map:get_game():get_hero():teleport('rooms/intro_2')
end
