local map, data = ...

for i, item in ipairs(data.items) do
    local my_item = {
        layer=1,
        x=48 * i + 32,
        y=120,
        treasure_name=item.name,
        treasure_savegame_variable=item.savegame_variable
    }
    if item.open == 'big_key' then
        my_item.sprite = "entities/big_chest"
        my_item.opening_method = "interaction_if_savegame_variable"
        my_item.opening_condition = "big_key"
        chest(my_item)
    else
        my_item.sprite = "entities/chest"
        chest(my_item)
    end
end

if data.doors.east then
    map:include(0, 0, 'components/door_east', data.doors.east)
end
if data.doors.north then
    if data.doors.north.open == 'big_key' then
        map:include(0, 0, 'components/door_boss', data.doors.north)
    elseif data.doors.north.open == 'bomb' then
        map:include(0, 0, 'components/bomb_north', data.doors.north)
    else
        map:include(0, 0, 'components/door_north', data.doors.north)
    end
    if data.doors.north.reach == 'hookshot' then
        map:include(0, 0, 'components/moat_north')
    end
end
if data.doors.west then
    map:include(0, 0, 'components/door_west', data.doors.west)
end
if data.doors.south then
    if data.doors.south.open == 'entrance' then
        map:include(0, 0, 'components/entrance', data.doors.south)
    else
        map:include(0, 0, 'components/door_south', data.doors.south)
    end
end
