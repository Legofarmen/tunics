local map, doors, items, enemies = ...

for i, item in ipairs(items) do
    local my_item = {
        layer=1,
        x=48 * i + 32,
        y=120,
        treasure_name=item.name,
        treasure_savegame_variable=item.savegame_variable
    }
    if item.open == 'big_key' then
        my_item.sprite = "entities/chest"
        my_item.opening_method = "interaction_if_savegame_variable"
        my_item.opening_condition = "big_key"
        chest(my_item)
    else
        pickable(my_item)
    end
end

if doors.east then
    map:include(0, 0, 'components/door_east', doors.east)
end
if doors.north then
    if doors.north.open == 'big_key' then
        map:include(0, 0, 'components/door_boss', doors.north)
    else
        map:include(0, 0, 'components/door_north', doors.north)
    end
    if doors.north.reach == 'hookshot' then
        map:include(0, 0, 'components/moat_north')
    end
end
if doors.west then
    map:include(0, 0, 'components/door_west', doors.west)
end
if doors.south then
    if doors.south.open == 'entrance' then
        map:include(0, 0, 'components/entrance', doors.south)
    else
        map:include(0, 0, 'components/door_south', doors.south)
    end
end
