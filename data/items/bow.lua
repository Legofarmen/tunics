local item = ...
local game = item:get_game()

function item:on_created()

    self:set_savegame_variable("bow")
    self:set_amount_savegame_variable("bow_amount")
    self:set_assignable(true)
    self:set_max_amount(20)
end

function item:on_using()

    if self:get_amount() == 0 then
        sol.audio.play_sound("wrong")
    else
        -- we remove the arrow from the equipment after a small delay because the hero
        -- does not shoot immediately
        sol.timer.start(300, function()
            self:remove_amount(1)
        end)
        self:get_map():get_entity("hero"):start_bow()
    end
    self:set_finished()
end

function item:on_amount_changed(amount)

    if self:get_variant() ~= 0 then
        -- update the icon (with or without arrow)
        if amount == 0 then
            self:set_variant(1)
        else
            self:set_variant(2)
        end
    end
end

function item:on_obtained(variant, savegame_variable)

    game:set_item_assigned(2, self)
    self:set_amount(self:get_max_amount())

    -- Unlock pickable arrows.
    local arrow = game:get_item("arrow")
    arrow:set_obtainable(true)
end
