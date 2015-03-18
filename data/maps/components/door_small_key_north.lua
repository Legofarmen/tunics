local map, data = ...

map:create_door{
    layer=1,
    x=152,
    y=16,
    direction=1,
    sprite='entities/door_small_key',
    savegame_variable=data.name,
    opening_method='interaction_if_savegame_variable',
    opening_condition='small_key_amount',
    opening_condition_consumed=true,
}
