local map, data = ...

bit32 = bit32 or bit

local rng = data.rng


local Class = require 'lib/class.lua'
local util = require 'lib/util'
local zentropy = require 'lib/zentropy'

local messages = {}
function data_messages(prefix, data)
    if type(data) == 'table' then
        local n = 0
        for key, value in util.pairs_by_keys(data) do
            data_messages(prefix .. '.' .. key, value)
            n = n + 1
        end
        if n == 0 then
            table.insert(messages, prefix .. ' = {}')
        end
    elseif type(data) ~= 'function' then
        table.insert(messages, prefix .. ' = ' .. tostring(data))
    end
end
data_messages('data', data)

local room = zentropy.Room:new{rng=rng, map=map, data_messages=data_messages}

local DialogBox = Class:new()

function DialogBox:on_started()
    self.lines = {}
    local y = 0
    for _, text in ipairs(self.text) do
        local line = sol.text_surface.create{
            text=text,
            vertical_alignment="top",
        }
        line:set_xy(0, y)
        local width, height = line:get_size()
        y = y + height
        table.insert(self.lines, line)
    end
    self.game:set_hud_enabled(false)
    self.game:get_hero():freeze()
end

function DialogBox:on_finished()
    self.game:set_hud_enabled(true)
    self.game:get_hero():unfreeze()
end

function DialogBox:on_command_pressed(command)
    if command == 'action' then
        sol.menu.stop(self)
    end
    return true
end

function DialogBox:on_draw(dst_surface)
    for _, line in ipairs(self.lines) do
        line:draw(dst_surface)
    end
end


function is_special_room(data)
    for dir, door in pairs(data.doors) do
        if door.open == 'entrance' or door.open == 'bigkey' then
            return true
        end
    end
end



local walls = {}
for _, dir in ipairs{'north','south','east','west'} do
    if data.doors[dir] then
        if not data.doors[dir].reach then
            if not room:door({open=data.doors[dir].open, name=data.doors[dir].name}, dir) then
                for _, msg in ipairs(messages) do print(msg) end
                error('')
            end
        end
        if not data.doors[dir].open and not data.doors[dir].reach and not data.doors[dir].see then
            room.open_doors[dir] = true
        end
        if data.doors[dir].reach then
            assert(not obstacle_item or obstacle_item == data.doors[dir].reach)
            obstacle_item = data.doors[dir].reach
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

    if not room:obstacle(obstacle_data, obstacle_dir, obstacle_item) then
        for _, msg in ipairs(messages) do zentropy.debug(msg) end
        error('')
    end
end

for _, treasure_data in ipairs(normal_treasures) do
    if not room:treasure(treasure_data) then
        for _, msg in ipairs(messages) do zentropy.debug(msg) end
        error('')
    end
end

for _, enemy_data in ipairs(data.enemies) do
    if not room:enemy(enemy_data) then
        for _, msg in ipairs(messages) do zentropy.debug(msg) end
        error('')
    end
end

if #messages > 0 then
    --[[
     if not room:sign({menu=DialogBox:new{text=messages, game=map:get_game()}}) then
        for _, msg in ipairs(messages) do print(msg) end
        error('')
    end
    ]]
end

if not is_special_room(data) then
    repeat until not room:filler()
end
