local map, doors, items, enemies = ...

for i, v in ipairs(items) do
    print(v)
    pickable{
        layer=1,
        x=48 * i + 64,
        y=120,
        treasure_name=v.name,
        treasure_savegame_variable=v.name .. '1'
    }
end

if doors.east then
    map:include(0, 0, 'components/door_east', doors.east)
end
if doors.north then
    map:include(0, 0, 'components/door_north', doors.north)
end
if doors.west then
    map:include(0, 0, 'components/door_west', doors.west)
end
if doors.south then
    map:include(0, 0, 'components/door_south', doors.south)
end
