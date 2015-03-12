local map, properties = ...

if properties.open then
    local my_door = {
        layer=1,
        x=152,
        y=16,
        direction=1,
    }
    if properties.open == 'big_key' then
        my_door.sprite='entities/door_big_key'
        my_door.savegame_variable='door_big_key1'
        my_door.opening_method='interaction_if_savegame_variable'
        my_door.opening_condition='big_key'
        door(my_door)
    elseif properties.open == 'small_key' then
        my_door.sprite='entities/door_small_key'
        my_door.savegame_variable=properties.name
        my_door.opening_method='interaction_if_savegame_variable'
        my_door.opening_condition='small_key_amount'
        my_door.opening_condition_consumed=true
        door(my_door)
    end
end
