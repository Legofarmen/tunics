local Class = require 'lib/class'
local Util = require 'lib/util'


local Layout = {}


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


function add_doorway(separators, x, y, direction, savegame_variable)
    separators[y] = separators[y] or {}
    separators[y][x] = separators[y][x] or {}
    separators[y][x][Layout.DIRECTIONS[direction]] = savegame_variable
end


Layout.DIRECTIONS = { east=0, north=1, west=2, south=3, }


local BaseVisitor = Class:new()

function BaseVisitor:visit_enemy(enemy)
    table.insert(self.enemies, enemy)
end

function BaseVisitor:visit_treasure(treasure)
    table.insert(self.items, treasure)
end

function BaseVisitor:visit_room(room)
    local y = self.y
    local x0 = self.x
    local is_eastward = self.is_eastward
    local x1 = x0
    local doors = {}
    local items = {}
    local enemies = {}

    if self.doors then
        if is_eastward then
            self.doors.east = Util.filter_keys(room, {'see','reach','open'})
        else
            self.doors.north = Util.filter_keys(room, {'see','reach','open'})
        end
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

    self.is_eastward = false
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
    self.x = math.max(self.x, x0 + 1)

    if heavy_key then
        x1, self.y, self.is_eastward = self:get_heavy_child_properties(self.x, y)
        doors[x1] = doors[x1] or {}
        self.doors = doors[x1]
        room.children[heavy_key]:accept(self)
    end

    for x = x1, x0, -1 do
        doors[x] = doors[x] or {}
        if x == x0 then
            if is_eastward then
                doors[x].west = Util.filter_keys(room, {'open'})
            else
                doors[x].south = Util.filter_keys(room, {'open'})
            end
        end
        if x < x1 then doors[x].east = {} end
        if x > x0 then doors[x].west = {} end
        if doors[x].north then
            doors[x].north.name = string.format('door_%d_%d_n', x, y)
        end
        self:render_room{
            x=x,
            y=y,
            doors=doors[x],
            items=items,
            enemies=enemies,
        }
        local savegame_variable = room.savegame_variable .. '_' .. (x - x0)
        if self.separators then
            add_doorway(self.separators, x,   y+1, 'north', doors[x].south and savegame_variable or false)
            add_doorway(self.separators, x,   y,   'east',  doors[x].west  and savegame_variable or false)
            add_doorway(self.separators, x,   y,   'south', doors[x].north and savegame_variable or false)
            add_doorway(self.separators, x+1, y,   'west',  doors[x].east  and savegame_variable or false)
        end
        items = {}
        enemies = {}
    end

end

function BaseVisitor:render(tree)
    if self.on_start then
        self:on_start()
    end
    tree:accept(self)
    if self.on_finish then
        self:on_finish()
    end
end


Layout.NorthwardVisitor = BaseVisitor:new{ x=0, y=9 }

function Layout.NorthwardVisitor:get_heavy_child_properties(x, y)
    return x, y - 1, false
end


Layout.NorthEastwardVisitor = BaseVisitor:new{ x=0, y=9 }

function Layout.NorthEastwardVisitor:get_heavy_child_properties(x, y)
    return x - 1, y, true
end

function Layout.print_mixin(object)

    function object:render_room(properties)
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


    return object
end

function Layout.minimap_mixin(object, map_menu)

    function object:render_room(properties)
        map_menu:draw_room(properties)
    end

    function object:on_start()
        map_menu:clear_map()
    end

    return object
end

function Layout.solarus_mixin(object, map)

    local entrance_x, entrance_y = map:get_entity('entrance'):get_position()

    function mark_known_room(x, y)
        map:get_game():set_value(string.format('room_%d_%d', x, y), true)
    end

    function object:on_start()
        self.separators = {}
    end

    function object:render_room(properties)
        local x0 = entrance_x - 160 + 320 * properties.x
        local y0 = entrance_y + 3 - 240 + 240 * (properties.y - 9)
        local room_properties = Util.filter_keys(properties, {'doors', 'items', 'enemies'})
        room_properties.name = string.format('room_%d_%d', properties.x, properties.y)
        map:include(x0, y0, 'rooms/room1', room_properties)
    end

    function object:on_finish()
        mark_known_room(0, 9)
        for y, row in pairs(self.separators) do
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
    end

    return object
end


return Layout
