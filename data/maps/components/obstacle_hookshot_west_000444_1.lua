local map, data = ...

local x1, y1 = map:translate(placeholder1:get_position())
local x2, y2 = map:translate(placeholder2:get_position())
x1, y1 = x1 + 8, y1 + 13
x2, y2 = x2 + 8, y2 + 13

for k, v in pairs(data) do
    print(k, v)
end

if data.treasure1 then
    map:create_chest{
        sprite="entities/chest",
        layer=1,
        x = x1,
        y = y1,
        treasure_name=data.treasure1.item_name,
        treasure_savegame_variable=data.treasure1.name,
    }
else
    map:create_block{
        layer = 1,
        x = x1,
        y = y1,
        direction = -1,
        sprite = "entities/block",
        pushable = false,
        pullable = false,
        maximum_moves = 0,
    }
end
map:create_block{
    layer = 1,
    x = x2,
    y = y2,
    direction = -1,
    sprite = "entities/block",
    pushable = false,
    pullable = false,
    maximum_moves = 0,
}
