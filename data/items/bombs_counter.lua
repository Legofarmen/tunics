local item = ...

function item:on_created()

    self:set_savegame_variable("bomb")
    self:set_amount_savegame_variable("bomb_amount")
    self:set_assignable(true)
end

function item:on_obtained(variant, savegame_variable)

    zentropy.game.assign_item(self)
    self:set_amount(self:get_max_amount())
end

function item:on_variant_changed(variant)

    -- The bomb bag determines the maximum amount of the bomb counter.
    local bomb = self:get_game():get_item("bomb")
    if variant == 0 then
        self:set_max_amount(0)
        bomb:set_obtainable(false)
    else
        local max_amounts = {10, 30, 99}
        local max_amount = max_amounts[variant]

        -- Set the max value of the bomb counter.
        self:set_variant(1)
        self:set_max_amount(max_amount)

        -- Unlock pickable bombs.
        bomb:set_obtainable(true)
    end
end

-- Called when the player uses the bombs of his inventory by pressing the corresponding item key.
function item:on_using()

    if self:get_amount() == 0 then
        sol.audio.play_sound("wrong")
    else
        self:remove_amount(1)
        self:create_bomb()
        sol.audio.play_sound("bomb")
    end
    self:set_finished()
end

function item:create_bomb()

    local hero = self:get_map():get_entity("hero")
    local x, y, layer = hero:get_position()
    local direction = hero:get_direction()
    if direction == 0 then
        x = x + 16
    elseif direction == 1 then
        y = y - 16
    elseif direction == 2 then
        x = x - 16
    elseif direction == 3 then
        y = y + 16
    end

    self:get_map():create_bomb{
        x = x,
        y = y,
        layer = layer
    }
end
