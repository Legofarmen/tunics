local map, data = ...

bit32 = bit32 or bit

local rng = data.rng


local util = require 'lib/util'
local zentropy = require 'lib/zentropy'

local messages = {}
function data_messages(prefix, data, depth)
    table.insert(messages, {[prefix]=data})
end
data_messages('data', data)

local room = zentropy.Room:new{rng=rng, map=map, data_messages=data_messages}

function is_special_room(data)
    for dir, door in pairs(data.doors) do
        if door.open == 'entrance' or door.open == 'bigkey' then
            return true
        end
    end
end

local room_events = {
    door_sensor_activated_listeners = {},
}

function room_events:on_door_sensor_activated(direction)
    for listener in pairs(self.door_sensor_activated_listeners) do
        listener(direction)
    end
end

function room_events:add_door_sensor_activated_listener(listener)
    self.door_sensor_activated_listeners[listener] = true
end


local walls = {}
for _, dir in ipairs{'north','south','east','west'} do
    if data.doors[dir] then
        if data.doors[dir].reach then
            assert(not obstacle_item or obstacle_item == data.doors[dir].reach)
            obstacle_item = data.doors[dir].reach
        else
            if not room:door({open=data.doors[dir].open, name=data.doors[dir].name, room_events=room_events}, dir) then
                error(util.table_string('messages', messages))
            end
        end
    else
        table.insert(walls, dir)
    end
end

local obstacle_dir = nil
local obstacle_doors = {}
if data.doors.north and data.doors.north.reach then
    obstacle_dir = (obstacle_dir or '') .. 'north'
    obstacle_doors.north = data.doors.north
end
if data.doors.south and data.doors.south.reach then
    obstacle_dir = (obstacle_dir or '') .. 'south'
    obstacle_doors.south = data.doors.south
end
if data.doors.east and data.doors.east.reach then
    obstacle_dir = (obstacle_dir or '') .. 'east'
    obstacle_doors.east = data.doors.east
end
if data.doors.west and data.doors.west.reach then
    obstacle_dir = (obstacle_dir or '') .. 'west'
    obstacle_doors.west = data.doors.west
end

for _, dir in ipairs(walls) do
    local name = 'crack_' .. dir
    if rng:refine(name):random(3) == 1 then
        map:get_entity(name):set_enabled(true)
    end
end


local obstacle_treasure = nil
local normal_treasures = {}
for _, treasure_data in ipairs(data.treasures) do
    if treasure_data.reach then
        assert(not obstacle_item or obstacle_item == treasure_data.reach)
        obstacle_treasure = treasure_data
    else
        table.insert(normal_treasures, treasure_data)
    end
end

if obstacle_treasure then
    obstacle_dir = obstacle_dir or walls[rng:refine('obstacle_dir'):random(#walls)]
    obstacle_item = obstacle_treasure.reach
end

if obstacle_dir then

    local obstacle_data = {}

    obstacle_data.treasure1 = obstacle_treasure
    obstacle_data.treasure2 = table.remove(normal_treasures)
    obstacle_data.doors = obstacle_doors
    obstacle_data.room = room
    obstacle_data.rng = rng:refine('obstacle')
    obstacle_data.room_events = room_events

    if not room:obstacle(obstacle_data, obstacle_dir, obstacle_item) then
        error(util.table_string('messages', messages))
    end
end

for _, treasure_data in ipairs(normal_treasures) do
    if not room:treasure(treasure_data) then
        error(util.table_string('messages', messages))
    end
end

for _, enemy_data in ipairs(data.enemies) do
    enemy_data.room_events = room_events
    if not room:enemy(enemy_data) then
        error(util.table_string('messages', messages))
    end
end

if not is_special_room(data) then
    --[[
    if #messages > 0 then
        local text = util.table_string('messages', messages)
        if not room:sign{menu=zentropy.menu(text .. "\n")} then
            error(text)
        end
    end
    ]]

    local n = 0
    while room:filler(n) do
        n = n + 1
    end
end
