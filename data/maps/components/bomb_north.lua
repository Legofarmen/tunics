local map, data = ...

local game = map:get_game()

local door = map:get_entity(data.name)
local closed = map:get_entity(data.name .. '_closed')

function map:on_created()
    door:set_savegame_variable(data.name)
end

function door:on_opened()
    closed:set_enabled(false)
end
