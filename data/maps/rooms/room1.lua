local map, data = ...

local rng = data.rng
local room_rng = rng:create()


bit32 = bit32 or bit

local Class = require 'lib/class.lua'
local Util = require 'lib/util'
local List = require 'lib/list'
local zentropy = require 'lib/zentropy'

local messages = {}
function data_messages(prefix, data)
    if type(data) == 'table' then
        local n = 0
        for key, value in Util.pairs_by_keys(data) do
            data_messages(prefix .. '.' .. key, value)
            n = n + 1
        end
        if n == 0 then
            table.insert(messages, prefix .. ' = {}')
        end
    elseif type(data) ~= 'function' then
        table.insert(messages, prefix .. ' = ' .. data)
    end
end
data_messages('data', data)

local room = zentropy.Room:new{rng=rng:create(), map=map, data_messages=data_messages}

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



local DIRS = {
    [Util.oct('200000')]='north',
    [Util.oct('040000')]='west',
    [Util.oct('010000')]='east',
    [Util.oct('002000')]='south',
}

local obstacle_mask = 0
local walls = {}
for dir_mask, dir in pairs(DIRS) do
    if data.doors[dir] then
        room:door({open=data.doors[dir].open, name=data.doors[dir].name}, dir)
        if not data.doors[dir].open and data.doors[dir].reach ~= 'bomb' then
            room.open_doors[dir] = true
        end
        if data.doors[dir].reach then
            obstacle_mask = bit32.bor(obstacle_mask, dir_mask)
            obstacle_item = data.doors[dir].reach
        end
    else
        table.insert(walls, dir_mask)
    end
end

for _, dir_mask in ipairs(walls) do
    if room_rng:random(2) == 2 then
        map:get_entity('crack_' .. DIRS[dir_mask]):set_enabled(true)
    end
end



local obstacle_treasure = nil
local normal_treasures = {}
for _, treasure_data in ipairs(data.treasures) do
    if treasure_data.reach then
        obstacle_treasure = treasure_data
    else
        table.insert(normal_treasures, treasure_data)
    end
end

if obstacle_treasure and obstacle_mask == 0 then
    obstacle_mask = walls[room_rng:random(#walls)]
    obstacle_item = obstacle_treasure.reach
end

if obstacle_mask ~= 0 then

    local OBSTACLE_MAP = {
        [Util.oct('200000')] = { dir='north' },
        [Util.oct('010000')] = { dir='east' },
        [Util.oct('002000')] = { dir='south' },
        [Util.oct('040000')] = { dir='west' },
        [Util.oct('202000')] = { dir='northsouth' },
        [Util.oct('210000')] = { dir='northeast' },
        [Util.oct('240000')] = { dir='northwest' },
        [Util.oct('012000')] = { dir='northwest', flip=true },
        [Util.oct('042000')] = { dir='northwest', flip=true },
        [Util.oct('050000')] = { dir='eastwest' },
        [Util.oct('212000')] = { dir='west', flip=true },
        [Util.oct('250000')] = { dir='south', flip=true },
        [Util.oct('242000')] = { dir='east', flip=true },
        [Util.oct('052000')] = { dir='north', flip=true },
    }

    local info = OBSTACLE_MAP[obstacle_mask]
    local obstacle_data = {}

    if info.flip then
        obstacle_data.treasure1 = table.remove(normal_treasures)
        obstacle_data.treasure2 = obstacle_treasure
    else
        obstacle_data.treasure1 = obstacle_treasure
        obstacle_data.treasure2 = table.remove(normal_treasures)
    end

    room:obstacle(obstacle_data, info.dir, obstacle_item)

    if info.flip then
        mask = bit32.bor(mask, Util.oct('000777'))
    end
end

for _, treasure_data in ipairs(normal_treasures) do
    room:treasure(treasure_data)
end

for _, enemy_data in ipairs(data.enemies) do
    room:enemy(enemy_data)
end

if #messages > 0 then
     --room:sign({menu=DialogBox:new{text=messages, game=map:get_game()}})
end

if not is_special_room(data) then
    local sections = {'111', '700', '444', '007', '100', '400', '004', '001'}
    List.shuffle(rng:create(), sections)
    repeat until not room:filler()
end
