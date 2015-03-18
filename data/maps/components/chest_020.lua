local map, data = ...   

map:create_chest{
    sprite="entities/chest",
    layer=1,
    x=288,
    y=192,
    treasure_name=data.item_name,
    treasure_savegame_variable=data.name,
}
