local item = ...

function item:on_created()

    self:set_savegame_variable("magic_bar")
end

function item:on_variant_changed(variant)

    local game = self:get_game()

    -- Obtaining a magic bar changes the max magic.
    local max_magics = {42, 84}
    local max_magic = max_magics[variant]
    if max_magic == nil then
        error("Invalid variant '" .. variant .. "' for item 'magic_bar'")
    end

    game:set_max_magic(max_magic)

    -- Unlock pickable magic jars.
    local magic_flask = game:get_item("magic_flask")
    magic_flask:set_obtainable(true)
end
