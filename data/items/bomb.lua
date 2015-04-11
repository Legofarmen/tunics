local item = ...

function item:on_created()

    self:set_shadow("small")
    self:set_can_disappear(true)
    self:set_brandish_when_picked(false)
end

function item:on_started()

    -- Disable pickable bombs if the player has no bombs_counter.
    -- We cannot do this from on_created() because we don't know if the
    -- bombs_counter is already created there.
    self:set_obtainable(self:get_game():has_item("bombs_counter"))
end

function item:on_obtaining(variant, savegame_variable)

    -- Obtaining bombs increases the counter of the bombs_counter.
    local amounts = {1, 3, 8}
    local amount = amounts[variant]
    if amount == nil then
        error("Invalid variant '" .. variant .. "' for item 'bomb'")
    end
    self:get_game():get_item("bombs_counter"):add_amount(amount)
end
