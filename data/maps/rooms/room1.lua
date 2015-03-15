local map, data = ...


local messages = {}
local function data_messages(data, prefix)
    if type(data) == 'table' then
        for key, value in pairs(data) do
            data_messages(value, prefix .. '.' .. key)
        end
    else
        table.insert(messages, prefix .. ' = ' .. data)
    end
end
data_messages(data, 'data')


if data.doors.east then
    data.doors.east.name = data.name .. '_e'
    map:include(0, 0, 'components/door_east', data.doors.east)
end
if data.doors.north then
    if data.doors.north.open == 'big_key' then
        map:include(0, 0, 'components/door_boss', data.doors.north)
    elseif data.doors.north.open == 'bomb' then
        map:include(0, 0, 'components/bomb_north', data.doors.north)
    else
        if data.doors.north.open ~= 'small_key' then
        end
        map:include(0, 0, 'components/door_north', data.doors.north)
    end

    if data.doors.north.reach == 'hookshot' then
        map:include(0, 0, 'components/moat_north')
    else
    end
end
if data.doors.west then
    map:include(0, 0, 'components/door_west', data.doors.west)
end
if data.doors.south then
    if data.doors.south.open == 'entrance' then
        map:include(0, 0, 'components/entrance', data.doors.south)
    elseif data.doors.south.open == 'bomb' then
        map:include(0, 0, 'components/bomb_south')
    else
        map:include(0, 0, 'components/door_south', data.doors.south)
    end
end

for i, item in ipairs(data.items) do
    local my_item = {
        layer=1,
        x=160,
        y=120,
        treasure_name=item.name,
        treasure_savegame_variable=item.savegame_variable
    }
    if item.open == 'big_key' then
        my_item.sprite = "entities/big_chest"
        my_item.opening_method = "interaction_if_savegame_variable"
        my_item.opening_condition = "big_key"
        map:create_chest(my_item)
    else
        my_item.sprite = "entities/chest"
        map:create_chest(my_item)
    end
end

if #messages > 0 then
    local sign = map:create_npc{
        x=64,
        y=164,
        layer=1,
        direction=3,
        subtype=0,
        sprite='entities/sign',
    }

    function sign:on_interaction(...)
        print()
        for _, message in ipairs(messages) do
            print(message)
        end
    end
end

