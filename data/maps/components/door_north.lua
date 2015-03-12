local map, properties = ...

if properties.open == 'big_key' then
    door{
        layer=1,
        x=152,
        y=16,
        direction=1,
        sprite='entities/door_big_key',
        savegame_variable='door_big_key1',
        opening_method='interaction_if_savegame_variable',
        opening_condition='big_key1',
    }
end
