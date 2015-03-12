local item = ...

function item:on_created()
    self:set_savegame_variable('big_key')
end
