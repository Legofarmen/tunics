local map,data = ...

map:create_chest{
    sprite = "entities/big_chest",
    opening_method = "interaction_if_savegame_variable",
    opening_condition = "big_key",
    layer=1,
    x=160,
    y=125,
    treasure_name=data.item_name,
    treasure_savegame_variable=data.name,
}
