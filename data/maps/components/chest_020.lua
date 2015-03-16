local map, data = ...   
   local my_item = {
        layer=1,
        x=160,
        y=120,
        treasure_name=data.name,
        treasure_savegame_variable=data.savegame_variable
    }
        my_item.sprite = "entities/chest"
        map:create_chest(my_item)