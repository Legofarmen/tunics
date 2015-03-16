local map,data = ...

    local my_item = {
        layer=1,
        x=160,
        y=128,
        treasure_name=data.name,
        treasure_savegame_variable=data.savegame_variable
    }
    my_item.sprite = "entities/big_chest"
    my_item.opening_method = "interaction_if_savegame_variable"
    my_item.opening_condition = "big_key"
    map:create_chest(my_item)
   