local Class = require 'lib/class'
local Util = require 'lib/util'


local Layout = {}


Layout.DIRECTIONS = { east=0, north=1, west=2, south=3, }


local BaseVisitor = Class:new()

function BaseVisitor:render(tree)
    self.leaf = 0
    self.depth = -1
    self.dir = 'entrance'
    self:on_start()
    tree:accept(self)
    self:on_finish()
end

function BaseVisitor:visit_enemy(enemy)
    self:enemy(enemy, self.coord_transform(self.depth, self.leaf))
end

function BaseVisitor:visit_treasure(treasure)
    self:treasure(treasure, self.coord_transform(self.depth, self.leaf))
end

function BaseVisitor:visit_room(room)
    local my_depth = self.depth + 1

    while room do
        local heavy_key, heavy_child = room:heavy_child()

        self:room(room, self.coord_transform(my_depth, self.leaf, self.dir))
        local my_x = self.leaf

        room:each_child(function (key, child)
            if key ~= heavy_key then

                local leaf0 = self.leaf
                self.depth = my_depth
                self.dir = 'down'
                child:accept(self)
                for leaf = leaf0 + 1, self.leaf do
                    self:room({}, self.coord_transform(my_depth, leaf, 'forward'))
                end
            end
        end)

        self.leaf = self.leaf + 1
        room = heavy_child
        self.dir = 'forward'
    end
end

function BaseVisitor:on_start() end
function BaseVisitor:on_finish() end


function collect_mixin(object)

    function object:collect_on_start() end
    function object:collect_on_finish() end

    function object:on_start()
        self.rooms = {}
        self:collect_on_start()
    end

    function object:on_finish()
        self:collect_on_finish()
    end

    function object:has_room(x, y)
        return self.rooms[y] and self.rooms[y][x]
    end

    function object:get_room(x, y)
        self.rooms[y] = self.rooms[y] or {}
        return self.rooms[y][x]
    end

    function object:new_room(x, y, info)
        if self:has_room(x, y) then
            error(string.format('room already exists: %d %d', x, y))
        end
        self.rooms[y] = self.rooms[y] or {}
        self.rooms[y][x] = info
    end

    function object.reverse(dir)
        local opposites = { east='west', north='south', south='north', west='east', }
        return opposites[dir]
    end

    function object.step(x, y, dir)
        local x_delta = { east=1, north=0, south=0, west=-1, }
        local y_delta = { east=0, north=-1, south=1, west=0, }
        return x + x_delta[dir], y + y_delta[dir]
    end

    function object:each_room(f)
        for y, row in Util.pairs_by_keys(self.rooms) do
            for x, info in Util.pairs_by_keys(row) do
                f(x, y, info)
            end
        end
    end

    function object:treasure(treasure, x, y)
        local info = self:get_room(x, y)
        table.insert(info.treasures, treasure)
    end

    function object:enemy(enemy, x, y)
        local info = self:get_room(x, y)
        table.insert(info.enemies, enemy)
    end

    function object.room_name(x, y)
        return string.format('room_%d_%d', x, y)
    end

    function object:room(room, x, y, dir)
        local from_dir = self.reverse(dir)
        local parent_x, parent_y = self.step(x, y, from_dir)
        local name = self.room_name(x, y)
        local info = {
            name=name,
            doors={},
            treasures={},
            enemies={},
        }
        self:new_room(x, y, info)
        if self:has_room(parent_x, parent_y) then
            self:get_room(parent_x, parent_y).doors[dir] = {
                see=room.see,
                reach=room.reach,
                open=room.open,
            }
        end
        self:get_room(x, y).doors[from_dir] = {
            see=room.see,
            open=room.open,
        }
    end

    return object
end


Layout.NorthEastwardVisitor = BaseVisitor:new{
    coord_transform = function (depth, leaf, dir)
        local dirs = {
            entrance='north',
            forward='east',
            down='north',
        }
        return leaf, 9-depth, dirs[dir]
    end,
}

Layout.NorthWestwardVisitor = BaseVisitor:new{
    coord_transform = function (depth, leaf, dir)
        local dirs = {
            entrance='north',
            forward='west',
            down='north',
        }
        return 9-leaf, 9-depth, dirs[dir]
    end,
}


function Layout.print_mixin(object)

    object = collect_mixin(object)

    function object:collect_on_finish()
        self:each_room(function (x, y, info)
            function print_access(thing)
                if thing.see and thing.see ~= 'nothing' then print(string.format("\t\tto see: %s", thing.see)) end
                if thing.reach and thing.reach ~= 'nothing' then print(string.format("\t\tto reach: %s", thing.reach)) end
                if thing.open and thing.open ~= 'nothing' then print(string.format("\t\tto open: %s", thing.open)) end
            end
            print(string.format("Room %d;%d", x, y))
            for dir, door in pairs(info.doors) do
                print(string.format("  Door %s", dir))
                print_access(door)
            end
            for _, treasure in ipairs(info.treasures) do
                print(string.format("  Item %s", treasure.name))
                print_access(treasure)
            end
            for _, enemy in ipairs(info.enemies) do
                print(string.format("  Enemy %s", enemy.name))
                print_access(enemy)
            end
            print()
        end)
    end

    return object
end

function Layout.minimap_mixin(object, map_menu)

    function object:render_room(properties)
        map_menu:draw_room(properties)
    end

    local old_on_start = object.on_start

    function object:on_start()
        if old_on_start then
            old_on_start(self)
        end
        map_menu:clear_map()
    end

    return object
end

function Layout.solarus_mixin(object, map)

    object = collect_mixin(object)

    local map_width, map_height = map:get_size()

    function mark_known_room(x, y)
        map:get_game():set_value(string.format('room_%d_%d', x, y), true)
    end

    function object:move_hero_to_start()
        local start_x, start_y = self.coord_transform(0, 0)
        local hero = map:get_hero()
        hero:set_position(320 * start_x + 320 / 2, 240 * start_y + 232, 1)
        hero:set_direction(1)
    end

    function object:collect_on_start()
        self.separators = {}
    end

    function object:separator(map_x, map_y, dir)
        local tag = string.format('%d_%d_%s', map_x, map_y, dir)
        if not self.separators[tag] then
            self.separators[tag] = true
            if dir == 'north' then
                local properties = {
                    x = 320 * map_x,
                    y = 240 * map_y - 8,
                    layer = 1,
                    width = 320,
                    height = 16,
                }
                local sep = map:create_separator(properties)
                function sep:on_activated(dir)
                    local my_y = (dir == Layout.DIRECTIONS.north) and map_y - 1 or map_y
                    local my_x = (dir == Layout.DIRECTIONS.west) and map_x - 1 or map_x
                    mark_known_room(my_x, my_y)
                end
            elseif dir == 'west' then
                local properties = {
                    x = 320 * map_x - 8,
                    y = 240 * map_y,
                    layer = 1,
                    width = 16,
                    height = 240,
                }
                local sep = map:create_separator(properties)
                function sep:on_activated(dir)
                    local my_y = (dir == Layout.DIRECTIONS.north) and map_y - 1 or map_y
                    local my_x = (dir == Layout.DIRECTIONS.west) and map_x - 1 or map_x
                    mark_known_room(my_x, my_y)
                end
            else
                error(string.format('unhandled dir: %s', dir))
            end
        end
    end

    function object:collect_on_finish()
        self:each_room(function (map_x, map_y, info)
            self:separator(map_x, map_y, 'north')
            self:separator(map_x, map_y, 'west')
            self:separator(map_x, map_y+1, 'north')
            self:separator(map_x+1, map_y, 'west')
            map:include(320 * map_x, 240 * map_y, 'rooms/room1', info)
        end)
    end

    return object
end


return Layout
