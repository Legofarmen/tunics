local map, data = ...

local Class = require 'lib/class.lua'
local Util = require 'lib/util'

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

--[[
for k, v in ipairs(messages) do
    print(v)
end
print()
]]


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

for i, item in ipairs(data.treasures) do
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
        --[[
        for k, v in pairs(my_item) do
            print('my_item', k, v)
        end
        print()
        ]]
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
        local dialog_box = DialogBox:new{text=messages, game=map:get_game()}
        sol.menu.start(map:get_userdata(), dialog_box, true)
    end
end

