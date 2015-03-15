local map = ...

local Tree = require 'lib/tree'
local Puzzle = require 'lib/puzzle'
local Prng = require 'lib/prng'
local Layout = require 'lib/layout'
local Util = require 'lib/util'


local function stdout_room(properties)
    function print_access(thing)
        if thing.see and thing.see ~= 'nothing' then print(string.format("\t\tto see: %s", thing.see)) end
        if thing.reach and thing.reach ~= 'nothing' then print(string.format("\t\tto reach: %s", thing.reach)) end
        if thing.open and thing.open ~= 'nothing' then print(string.format("\t\tto open: %s", thing.open)) end
    end
    print(string.format("Room %d;%d", properties.x, properties.y))
    for dir, door in pairs(properties.doors) do
        print(string.format("  Door %s", dir))
        print_access(door)
    end
    for _, item in ipairs(properties.items) do
        print(string.format("  Item %s", item.name))
        print_access(item)
    end
    for _, enemy in ipairs(properties.enemies) do
        print(string.format("  Enemy %s", enemy.name))
        print_access(enemy)
    end
    print()
end


local entrance_x, entrance_y = map:get_entity('entrance'):get_position()

local function solarus_room(properties)
    local x0 = entrance_x - 160 + 320 * properties.x
    local y0 = entrance_y + 3 - 240 + 240 * (properties.y - 9)
    map:include(x0, y0, 'rooms/room1', Util.filter_keys(properties, {'doors', 'items', 'enemies'}))
end

local function mark_known_room(x, y)
    map:get_game():set_value(string.format('room_%d_%d', x, y), true)
end


local master_prng = Prng.from_seed(8)
local tree = Puzzle.alpha_dungeon(master_prng:create(), 3, {'hookshot'})
tree:accept(Tree.PrintVisitor:new{})
local separators = {}
tree:accept(Layout.BetaVisitor:new{
    x=0,
    y=9,
    render=solarus_room,
    --render=stdout_room,
    separators=separators,
})

mark_known_room(0, 9)
for y, row in pairs(separators) do
    for x, room in pairs(row) do
        if room[Layout.DIRECTIONS.north] ~= nil or room[Layout.DIRECTIONS.south] ~= nil then
            local properties = {
                x = entrance_x - 160 + 320 * x,
                y = entrance_y + 3 - 240 + 240 * (y - 9) - 8,
                layer = 1,
                width = 320,
                height = 16,
            }
            local sep = map:create_separator(properties)
            if room[Layout.DIRECTIONS.north] then
                function sep:on_activated(dir)
                    local my_y = (dir == Layout.DIRECTIONS.north) and y - 1 or y
                    local my_x = (dir == Layout.DIRECTIONS.west) and x - 1 or x
                    mark_known_room(my_x, my_y)
                end
            end
        end
        if room[Layout.DIRECTIONS.east] ~= nil or room[Layout.DIRECTIONS.west] ~= nil then
            local properties = {
                x = entrance_x - 160 + 320 * x - 8,
                y = entrance_y + 3 - 240 + 240 * (y - 9),
                layer = 1,
                width = 16,
                height = 240,
            }
            local sep = map:create_separator(properties)
            if room[Layout.DIRECTIONS.west] then
                function sep:on_activated(dir)
                    local my_y = (dir == Layout.DIRECTIONS.north) and y - 1 or y
                    local my_x = (dir == Layout.DIRECTIONS.west) and x - 1 or x
                    mark_known_room(my_x, my_y)
                end
            end
        end
    end
end

function map:render_map(map_menu)
    local render = function (properties)
        map_menu:draw_room(properties)
    end
    map_menu:clear_map()
    tree:accept(Layout.BetaVisitor:new{x=0, y=9,render=render, separators={}})
end
