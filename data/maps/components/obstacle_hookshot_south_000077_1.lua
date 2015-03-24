local map, data = ...

function replace(placeholder, data)
    local x, y = map:translate(placeholder:get_position())
    x, y = x + 8, y + 13
    if data then
        map:create_chest{
            sprite="entities/chest",
            layer=1,
            x = x,
            y = y,
            treasure_name=data.item_name,
            treasure_savegame_variable=data.name,
        }
    else
        map:create_block{
            layer = 1,
            x = x,
            y = y,
            direction = -1,
            sprite = "entities/block",
            pushable = false,
            pullable = false,
            maximum_moves = 0,
        }
    end
end

replace(placeholder1, data.treasure1)
replace(placeholder2, data.treasure2)
