local item = ...

function item:on_started()
    self:set_savegame_variable('compass')
end
