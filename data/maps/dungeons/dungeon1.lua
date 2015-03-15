local map = ...

local Class = require 'lib/class'
local Tree = require 'lib/tree'
local Puzzle = require 'lib/puzzle'
local Prng = require 'lib/prng'


function filter_keys(table, keys)
    local result = {}
    for _, key in ipairs(keys) do
        if table[key] then result[key] = table[key] end
    end
    return result
end

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
    map:include(x0, y0, 'rooms/room1', filter_keys(properties, {'doors', 'items', 'enemies'}))
end

local LayoutVisitor = Class:new()

function LayoutVisitor:visit_enemy(enemy)
    table.insert(self.enemies, enemy)
end

function LayoutVisitor:visit_treasure(treasure)
    table.insert(self.items, treasure)
end

local DIRECTIONS = { east=0, north=1, west=2, south=3, }
function add_doorway(separators, x, y, direction, savegame_variable)
    separators[y] = separators[y] or {}
    separators[y][x] = separators[y][x] or {}
    separators[y][x][DIRECTIONS[direction]] = savegame_variable
end

local WeightVisitor = {}
setmetatable(WeightVisitor, WeightVisitor)

function WeightVisitor:visit_room(room)
    local weights = {
        Room=0,
        Treasure=0,
        Enemy=0,
    }
    room:each_child(function (key, child)
        weights[child.class] = weights[child.class] + child:accept(self)
    end)
    return math.max(1, weights.Room)
end

function WeightVisitor:visit_treasure(treasure)
    return 0
end

function WeightVisitor:visit_enemy(enemy)
    return 0
end

function LayoutVisitor:visit_room(room)
    local y = self.y
    local x0 = self.x
    local x1 = x0
    local doors = {}
    local items = {}
    local enemies = {}

    if self.doors and not self.is_heavy then
        self.doors.north = filter_keys(room, {'see','reach','open'})
    end


    local total_weight = 0
    local heavy_weight = 0
    local heavy_key = nil
    room:each_child(function (key, child)
        local child_weight = child:accept(WeightVisitor)
        total_weight = total_weight + child_weight
        if child_weight > heavy_weight then
            heavy_weight = child_weight
            heavy_key = key
        end
    end)
    if total_weight == heavy_weight then
        heavy_key = nil
    end

    local is_heavy = self.is_heavy
    self.is_heavy = false
    room:each_child(function (key, child)
        if key ~= heavy_key then
            self.y = y - 1
            self.items = items
            self.enemies = enemies
            if child.class == 'Room' then
                x1 = self.x
                doors[x1] = doors[x1] or {}
                self.doors = doors[x1]
            end
            child:accept(self)
        end
    end)

    if heavy_key then
        x1 = math.max(x1, self.x - 1)
        doors[x1].east = filter_keys(room.children[heavy_key], {'see','reach','open'})
    end
    self.x = math.max(self.x, x0 + 1, x0 + #items, x0 + #enemies)

    for x = x0, x1 do
        doors[x] = doors[x] or {}
        if x == x0 then
            if is_heavy then
                doors[x].west = filter_keys(room, {'open'})
            else
                doors[x].south = filter_keys(room, {'open'})
            end
        end
        if x < x1 then doors[x].east = {} end
        if x > x0 then doors[x].west = {} end
        if doors[x].north then
            doors[x].north.name = string.format('door_%d_%d_n', x, y)
        end
        self.render{
            x=x,
            y=y,
            doors=doors[x],
            items=items,
            enemies=enemies,
        }
        local savegame_variable = room.savegame_variable .. '_' .. (x - x0)
        add_doorway(self.separators, x,   y+1, 'north', doors[x].south and savegame_variable or false)
        add_doorway(self.separators, x,   y,   'east',  doors[x].west  and savegame_variable or false)
        add_doorway(self.separators, x,   y,   'south', doors[x].north and savegame_variable or false)
        add_doorway(self.separators, x+1, y,   'west',  doors[x].east  and savegame_variable or false)
        items = {}
        enemies = {}
    end
    if heavy_key then
        self.y = y
        self.is_heavy = true
        room.children[heavy_key]:accept(self)
    end

end

function mark_known_room(x, y)
    map:get_game():set_value(string.format('room_%d_%d', x, y), true)
end


local master_prng = Prng.from_seed(8)
local tree = Puzzle.alpha_dungeon(master_prng:create(), 3, {'hookshot'})
tree:accept(Tree.PrintVisitor:new{})
local separators = {}
tree:accept(LayoutVisitor:new{
    x=0,
    y=9,
    render=solarus_room,
    --render=stdout_room,
    separators=separators,
})

mark_known_room(0, 9)
for y, row in pairs(separators) do
    for x, room in pairs(row) do
        if room[DIRECTIONS.north] ~= nil or room[DIRECTIONS.south] ~= nil then
            local properties = {
                x = entrance_x - 160 + 320 * x,
                y = entrance_y + 3 - 240 + 240 * (y - 9) - 8,
                layer = 1,
                width = 320,
                height = 16,
            }
            local sep = map:create_separator(properties)
            if room[DIRECTIONS.north] then
                function sep:on_activated(dir)
                    local my_y = (dir == DIRECTIONS.north) and y - 1 or y
                    local my_x = (dir == DIRECTIONS.west) and x - 1 or x
                    mark_known_room(my_x, my_y)
                end
            end
        end
        if room[DIRECTIONS.east] ~= nil or room[DIRECTIONS.west] ~= nil then
            local properties = {
                x = entrance_x - 160 + 320 * x - 8,
                y = entrance_y + 3 - 240 + 240 * (y - 9),
                layer = 1,
                width = 16,
                height = 240,
            }
            local sep = map:create_separator(properties)
            if room[DIRECTIONS.west] then
                function sep:on_activated(dir)
                    local my_y = (dir == DIRECTIONS.north) and y - 1 or y
                    local my_x = (dir == DIRECTIONS.west) and x - 1 or x
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
    tree:accept(LayoutVisitor:new{x=0, y=9,render=render, separators={}})
end
