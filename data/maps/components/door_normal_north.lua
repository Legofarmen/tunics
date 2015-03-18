local map, data = ...

if data.open then
    local my_door = {
        layer=1,
        x=152,
        y=16,
        direction=1,
    }
    if data.open == 'big_key' then
        my_door.sprite='entities/door_big_key'
        my_door.savegame_variable='door_big_key1'
        my_door.opening_method='interaction_if_savegame_variable'
        my_door.opening_condition='big_key'
        map:create_door(my_door)
    elseif data.open == 'small_key' then
        my_door.sprite='entities/door_small_key'
        my_door.savegame_variable=data.name
        my_door.opening_method='interaction_if_savegame_variable'
        my_door.opening_condition='small_key_amount'
        my_door.opening_condition_consumed=true
        map:create_door(my_door)
    end
end
