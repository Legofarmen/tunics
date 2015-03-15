local map, data = ...

local messages = {}
local function check_unhandled(keys)
    local d = data
    local sep = 'Unhandled: '
    local msg = ''
    for _, key in ipairs(keys) do
        d = d[key]
        if not d then return end
        msg = msg .. sep .. key
        sep = '.'
    end
    if d then
        table.insert(messages, msg .. ' = ' .. d)
    end
end

if data.doors.east then
    data.doors.east.name = data.name .. '_e'
    map:include(0, 0, 'components/door_east', data.doors.east)
    check_unhandled{'doors', 'east', 'see'}
    check_unhandled{'doors', 'east', 'reach'}
    check_unhandled{'doors', 'east', 'open'}
end
if data.doors.north then
    if data.doors.north.open == 'big_key' then
        map:include(0, 0, 'components/door_boss', data.doors.north)
    elseif data.doors.north.open == 'bomb' then
        map:include(0, 0, 'components/bomb_north', data.doors.north)
    else
        if data.doors.north.open ~= 'small_key' then
            check_unhandled{'doors', 'north', 'open'}
        end
        map:include(0, 0, 'components/door_north', data.doors.north)
    end

    if data.doors.north.reach == 'hookshot' then
        map:include(0, 0, 'components/moat_north')
    else
        check_unhandled{'doors', 'north', 'reach'}
    end
end
if data.doors.west then
    map:include(0, 0, 'components/door_west', data.doors.west)
    check_unhandled{'doors', 'west', 'see'}
    check_unhandled{'doors', 'west', 'reach'}
    check_unhandled{'doors', 'west', 'open'}
end
if data.doors.south then
    if data.doors.south.open == 'entrance' then
        map:include(0, 0, 'components/entrance', data.doors.south)
    elseif data.doors.south.open == 'bomb' then
        map:include(0, 0, 'components/bomb_south')
    else
        check_unhandled{'doors', 'south', 'open'}
        map:include(0, 0, 'components/door_south', data.doors.south)
    end
    check_unhandled{'doors', 'south', 'see'}
    check_unhandled{'doors', 'south', 'reach'}
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
        for _, message in ipairs(messages) do
            print(data.name, message)
        end
    end
end

