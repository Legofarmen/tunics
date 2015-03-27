local map, data = ...

local rng = data.rng

local components_rng = rng:create()
local room_rng = rng:create()
local treasures_rng = rng:create()
local puzzle_rng = rng:create()

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


local mask = 0
function door(data, dir)
    if not data then return end
    local component_name, component_mask = Zentropy.components:get_door(data.open, dir, mask, components_rng)
    if not component_name then
        for _, msg in ipairs(messages) do print(msg) end
        error(string.format("door not found: open=%s dir=%s mask=%06o", data.open, dir, mask))
    end
    mask = bit32.bor(mask, component_mask)
    data.rewrite = {}
    function data.rewrite.door(properties)
        properties.savegame_variable = data.name
        return properties
    end
    map:include(0, 0, component_name, data)
    data_messages('component', component_name)
end

function obstacle(data, dir, item)
    if not data then return end
    local component_name, component_mask = Zentropy.components:get_obstacle(item, dir, mask, components_rng)
    if not component_name then
        for _, msg in ipairs(messages) do print(msg) end
        error(string.format("obstacle not found: item=%s dir=%s mask=%06o", item, dir, mask))
    end
    mask = bit32.bor(mask, component_mask)
    map:include(0, 0, component_name, data)
    data_messages('component', component_name)
end

local open_doors = {}

function filler()
    local filler_data = {}
    local component_name, component_mask = Zentropy.components:get_filler(mask, components_rng)
    if component_name then
        mask = bit32.bor(mask, component_mask)
        if puzzle_rng:random() < 0.5 then
            filler_data.doors = open_doors
            filler_data.rng = puzzle_rng
            open_doors = {}
        else
            filler_data.doors = {}
        end
        map:include(0, 0, component_name, filler_data)
        data_messages('component', component_name)
        return true
    end
    return false
end

function treasure(treasure_data)
    local component_name, component_mask
    local component_type
    if treasure_data.see then
        component_name, component_mask = Zentropy.components:get_puzzle(mask, components_rng)
        component_type = 'puzzle'
        treasure_data.doors = {}
    else
        component_name, component_mask = Zentropy.components:get_treasure(treasure_data.open, mask, components_rng)
        component_type = 'treasure'
    end
    if not component_name then
        for _, msg in ipairs(messages) do print(msg) end
        error(string.format("%s not found: open=%s mask=%06o", component_type, treasure_data.open, mask))
    end
    mask = bit32.bor(mask, component_mask)

    treasure_data.section = component_mask
    treasure_data.rewrite = {}
    function treasure_data.rewrite.chest(properties)
        properties.treasure_savegame_variable = treasure_data.name
        properties.treasure_name = treasure_data.item_name
        return properties
    end
    treasure_data.rng = treasures_rng:biased(component_mask)
    map:include(0, 0, component_name, treasure_data)
    data_messages('component', component_name)
end

function enemy(data)
    if data.name == 'boss' then
        local component_name, component_mask = zentropy.components:get_bossroom(mask, components_rng)
        map:include(0, 0, component_name, data)
    else
        local sections = {'400', '200', '100', '040', '020', '010', '004', '002', '001'}
        List.shuffle(rng:create(), sections)
        for _, section_string in ipairs(sections) do
            local section = Util.oct(section_string)
            if bit32.band(mask, section) == 0 then
                local component_name = string.format('components/enemy_any_1')
                data.section = section
                data.rng = components_rng
                map:include(0, 0, component_name, data)
                data_messages('component', component_name)
                mask = bit32.bor(mask, section)
                return

            end
        end
        for _, msg in ipairs(messages) do print(msg) end
        error('cannot fit enemy')
    end
end

function sign(data)
    for _, section_string in ipairs{'400', '200', '100', '040', '020', '010', '004', '002', '001'} do
        local section = Util.oct(section_string)
        if bit32.band(mask, section) == 0 then
            local component_name = string.format('components/sign')
            data.section = section
            map:include(0, 0, component_name, data)
            data_messages('component', component_name)
            mask = bit32.bor(mask, section)
            return
        end
    end
    for _, msg in ipairs(messages) do print(msg) end
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
        if data.doors[dir].open then
            open_doors[dir] = true
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

    if obstacle_treasure then
        if info.flip then
            obstacle_data.treasure2 = obstacle_treasure
        else
            obstacle_data.treasure1 = obstacle_treasure
        end
    end

    obstacle(obstacle_data, info.dir, obstacle_item)

    if info.flip then
        mask = bit32.bor(mask, Util.oct('000777'))
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
