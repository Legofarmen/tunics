local map, data = ...

if data.treasure then
    map:create_chest{
        sprite="entities/chest",
        layer=1,
        x = x,
        y = y,
        treasure_name=data.treasure.item_name,
        treasure_savegame_variable=data.treasure.name,
    }
end
