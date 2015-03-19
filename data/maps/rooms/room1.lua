local map, data = ...

local rng = data.rng

bit32 = bit32 or bit

local Class = require 'lib/class.lua'
local Util = require 'lib/util'
local List = require 'lib/list'

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
    else
        table.insert(messages, prefix .. ' = ' .. data)
    end
end
data_messages(data, 'data')


local SECTIONS = {
    east=Util.oct('010'),
    north=Util.oct('200'),
    west=Util.oct('040'),
    south=Util.oct('002'),
}


local door_mask = 0
local floor_mask = 0
function door(data, dir)
    if not data then return end
    if bit32.band(door_mask, SECTIONS[dir]) == 0 then
        door_mask = bit32.bor(door_mask, SECTIONS[dir])
    else
        error('cannot fit door')
    end
    local component_name = string.format('components/door_%s_%s', data.open or 'normal', dir)
    data.rewrite = {}
    function data.rewrite.door(properties)
        properties.savegame_variable = data.name
        return properties
    end
    map:include(0, 0, component_name, data)
end

function obstacle(data, dir, item)
    if not data or data.reach ~= item then return end
    local sections = Util.oct('771')
    if bit32.band(floor_mask, sections) == 0 then
        floor_mask = bit32.bor(floor_mask, sections)
    else
        error('cannot fit obstacle')
    end
    local component_name = string.format('components/obstacle_%s_%s', item, dir)
    map:include(0, 0, component_name, data)
end

function filler(sections)
    if bit32.band(floor_mask, sections) == 0 then
        floor_mask = bit32.bor(floor_mask, sections)
        local component_name = string.format('components/filler_%03o', sections)
        map:include(0, 0, component_name, data)
    end
end

function treasure(data)
    local sections = {'400', '200', '100', '040', '020', '010', '004', '002', '001'}
    List.shuffle(rng:create(), sections)

    for _, section_string in ipairs(sections) do
        local section = Util.oct(section_string)
        if bit32.band(floor_mask, section) == 0 then
            local component_name = string.format('components/chest_%s', data.open or 'normal')
            data.section = section
            map:include(0, 0, component_name, data)
            floor_mask = bit32.bor(floor_mask, section)
            return
        end
    end
    error('cannot fit treasure')
end

function enemy(data)
    local sections = {'400', '200', '100', '040', '020', '010', '004', '002', '001'}
    List.shuffle(rng:create(), sections)
    for _, section_string in ipairs(sections) do
        local section = Util.oct(section_string)
        if bit32.band(floor_mask, section) == 0 then
            local component_name = string.format('components/enemy')
            data.section = section
            map:include(0, 0, component_name, data)
            floor_mask = bit32.bor(floor_mask, section)
            return
        end
    end
    error('cannot fit enemy')
end

function sign(data)
    for _, section_string in ipairs{'400', '200', '100', '040', '020', '010', '004', '002', '001'} do
        local section = Util.oct(section_string)
        if bit32.band(floor_mask, section) == 0 then
            local component_name = string.format('components/sign')
            data.section = section
            map:include(0, 0, component_name, data)
            floor_mask = bit32.bor(floor_mask, section)
            return
        end
    end
    error('cannot fit sign')
end

function is_special_room(data)
    for dir, door in pairs(data.doors) do
        if door.open == 'entrance' or door.open == 'big_key' then
            return true
        end
    end
end



for _, dir in ipairs{'east', 'north', 'west', 'south'} do
    door(data.doors[dir], dir)
    obstacle(data.doors[dir], dir, 'hookshot')
end

floor_mask = bit32.bor(floor_mask, door_mask)

for _, data in ipairs(data.treasures) do
    treasure(data)
end

for _, data in ipairs(data.enemies) do
    enemy(data)
end

if #messages > 0 then
     sign({menu=DialogBox:new{text=messages, game=map:get_game()}})
end

if not is_special_room(data) then
    local sections = {'111', '700', '444', '007', '100', '400', '004', '001'}
    List.shuffle(rng:create(), sections)
    for _, section_string in ipairs(sections) do
        filler(Util.oct(section_string))
    end
end
