local item = ...

function item:on_created()
    self:set_savegame_variable('small_key')
    self:set_amount_savegame_variable('small_key_amount')
    self:set_max_amount(9)
end

function item:on_obtained()
    self:add_amount(1)
end
