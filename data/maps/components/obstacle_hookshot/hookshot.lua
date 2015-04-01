local hookshot = {}

local function replace(map, placeholder, data)
    local x, y = placeholder:get_position()
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

function hookshot.init(map, data)
    replace(map, map:get_entity('placeholder1'), data.treasure1)
    replace(map, map:get_entity('placeholder2'), data.treasure2)
    for dir, door_data in pairs(data.doors) do
        data.room:door({open=door_data.open, name=door_data.name}, dir)
    end
end

return hookshot
