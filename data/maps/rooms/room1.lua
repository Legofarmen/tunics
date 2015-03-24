local map, data = ...

local rng = data.rng

local components_rng = rng:create()
local room_rng = rng:create()

bit32 = bit32 or bit

local Class = require 'lib/class.lua'
local Util = require 'lib/util'
local List = require 'lib/list'
local Zentropy = require 'lib/zentropy'

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

local messages = {}
function data_messages(data, prefix)
    if type(data) == 'table' then
        local n = 0
        for key, value in Util.pairs_by_keys(data) do
            data_messages(value, prefix .. '.' .. key)
            n = n + 1
        end
        if n == 0 then
            table.insert(messages, prefix .. ' = {}')
        end
    elseif type(data) ~= 'function' then
        table.insert(messages, prefix .. ' = ' .. data)
    end
end
data_messages(data, 'data')


local mask = 0
function door(data, dir)
    if not data then return end
    local component_name, component_mask = Zentropy.components:get_door(data.open, dir, mask, components_rng)
    if not component_name then
        error(string.format("door not found: open=%s dir=%s mask=%06o", data.open, dir, mask))
    end
    mask = bit32.bor(mask, component_mask)
    data.rewrite = {}
    function data.rewrite.door(properties)
        properties.savegame_variable = data.name
        return properties
    end
    map:include(0, 0, component_name, data)
end

function obstacle(data, dir, item)
    if not data then return end
    local component_name, component_mask = Zentropy.components:get_obstacle(item, dir, mask, components_rng)
    if not component_name then
        error(string.format("obstacle not found: item=%s dir=%s mask=%06o", item, dir, mask))
    end
    mask = bit32.bor(mask, component_mask)
    map:include(0, 0, component_name, data)
end

function filler()
    local component_name, component_mask = Zentropy.components:get_filler(mask, components_rng)
    if component_name then
        mask = bit32.bor(mask, component_mask)
        map:include(0, 0, component_name, data)
        return true
    end
    return false
end

function treasure(data)
    local component_name, component_mask = Zentropy.components:get_treasure(data.open, mask, components_rng)
    if not component_name then
        error(string.format("treasure not found: open=%s mask=%06o", data.open, mask))
    end
    mask = bit32.bor(mask, component_mask)

    data.section = component_mask
    data.rewrite = {}
    function data.rewrite.chest(properties)
        properties.savegame_variable = data.name
        properties.treasure_name = data.item_name
        return properties
    end
    map:include(0, 0, component_name, data)
end

function enemy(data)
    local sections = {'400', '200', '100', '040', '020', '010', '004', '002', '001'}
    List.shuffle(rng:create(), sections)
    for _, section_string in ipairs(sections) do
        local section = Util.oct(section_string)
        if bit32.band(mask, section) == 0 then
            local component_name = string.format('components/enemy_any_1')
            data.section = section
            map:include(0, 0, component_name, data)
            mask = bit32.bor(mask, section)
            return
        end
    end
    error('cannot fit enemy')
end

function sign(data)
    for _, section_string in ipairs{'400', '200', '100', '040', '020', '010', '004', '002', '001'} do
        local section = Util.oct(section_string)
        if bit32.band(mask, section) == 0 then
            local component_name = string.format('components/sign')
            data.section = section
            map:include(0, 0, component_name, data)
            mask = bit32.bor(mask, section)
            return
        end
    end
    error('cannot fit sign')
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
        door({open=data.doors[dir].open, name=data.doors[dir].name}, dir)
        if data.doors[dir].reach then
            obstacle_mask = bit32.bor(obstacle_mask, dir_mask)
            obstacle_item = data.doors[dir].reach
        end
    else
        table.insert(walls, dir_mask)
    end
end



local obstacle_treasure = nil
local normal_treasures = {}
for _, data in ipairs(data.treasures) do
    if data.reach then
        obstacle_treasure = data
    else
        table.insert(normal_treasures, data)
    end
end

if obstacle_treasure and obstacle_mask == 0 then
    obstacle_mask = walls[room_rng:random(#walls)]
    obstacle_item = obstacle_treasure.reach
end

if obstacle_mask ~= 0 then

    local OBSTACLE_MAP = {
        [Util.oct('200000')] = { dir1='north' },
        [Util.oct('010000')] = { dir1='east' },
        [Util.oct('002000')] = { dir1='south' },
        [Util.oct('040000')] = { dir1='west' },
        [Util.oct('202000')] = { dir1='north', dir2='south' },
        [Util.oct('210000')] = { dir1='northeast' },
        [Util.oct('240000')] = { dir1='northwest' },
        [Util.oct('012000')] = { dir1='northwest', flip=true },
        [Util.oct('042000')] = { dir1='northwest', flip=true },
        [Util.oct('050000')] = { dir1='east', dir2='west' },
        [Util.oct('212000')] = { dir1='west', flip=true },
        [Util.oct('250000')] = { dir1='south', flip=true },
        [Util.oct('242000')] = { dir1='east', flip=true },
        [Util.oct('052000')] = { dir1='north', flip=true },
    }

    local info = OBSTACLE_MAP[obstacle_mask]
    local obstacles = {}
    obstacles[info.dir1] = {}
    if info.dir2 then
        obstacles[info.dir2] = {}
    end

    if obstacle_treasure then
        local treasure_obstacle
        if info.dir2 and room_rng:random(2) == 2 then
            treasure_obstacle = obstacles[info.dir2]
        else
            treasure_obstacle = obstacles[info.dir1]
        end
        if info.flip then
            treasure_obstacle.treasure2 = obstacle_treasure
        else
            treasure_obstacle.treasure1 = obstacle_treasure
        end
    end

    for dir, obstacle_data in pairs(obstacles) do
        obstacle(obstacle_data, dir, obstacle_item)
    end
end

for _, treasure_data in ipairs(normal_treasures) do
    treasure(treasure_data)
end

for _, enemy_data in ipairs(data.enemies) do
    enemy(enemy_data)
end

if #messages > 0 then
     --sign({menu=DialogBox:new{text=messages, game=map:get_game()}})
end

if not is_special_room(data) then
    local sections = {'111', '700', '444', '007', '100', '400', '004', '001'}
    List.shuffle(rng:create(), sections)
    repeat until not filler()
end
