local Class = require 'lib/class'
local Util = require 'lib/util'


local Layout = {}


Layout.DIRECTIONS = { east=0, north=1, west=2, south=3, }


local BaseVisitor = Class:new()

function BaseVisitor:render(tree)
    self.leaf = 0
    self.depth = 0
    self.dir = self.inwards
    self:on_start()
    tree:accept(self)
    self:on_finish()
end

function BaseVisitor:visit_enemy(enemy)
    self:enemy(enemy, self.depth, self.leaf)
end

function BaseVisitor:visit_treasure(treasure)
    self:treasure(treasure, self.depth, self.leaf)
end

function BaseVisitor:visit_room(room)
    local my_depth = self.depth
    local my_leaf = self.leaf

    self:room(room, my_depth, my_leaf, self.dir)

    self.depth = my_depth
    room:each_child(function (key, child)
        if child.class ~= 'Room' then
            child:accept(self)
        end
    end)

    local heavy_key = nil
    local heavy_weight = 0
    local light_count = 0
    room:each_child(function (key, child)
        if child.class == 'Room' then
            if heavy_key then
                local weight = child:get_weight()
                if weight > heavy_weight then
                    child = room.children[heavy_key]
                    heavy_weight = weight
                    heavy_key = key
                end
                while my_leaf < self.leaf do
                    my_leaf = my_leaf + 1
                    self:room({}, my_depth, my_leaf, 'forward')
                end
                self.depth = my_depth + 1
                self.dir = 'down'
                child:accept(self)
                light_count = light_count + 1
            else
                heavy_key = key
                heavy_weight = child:get_weight()
            end
        end
    end)
    if heavy_key then
        if light_count == 0 then
            self.depth = my_depth + 1
            self.dir = 'down'
        else
            self.depth = my_depth
            self.dir = 'forward'
        end
        room.children[heavy_key]:accept(self)
    else
        self.leaf = self.leaf + 1
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

    function object:has_room(depth, leaf)
        return self.rooms[depth] and self.rooms[depth][leaf]
    end

    function object:get_room(depth, leaf)
        self.rooms[depth] = self.rooms[depth] or {}
        return self.rooms[depth][leaf]
    end

    function object:new_room(depth, leaf, info)
        if self:has_room(depth, leaf) then
            error(string.format('room already exists: %d %d', depth, leaf))
        end
        for dir, door_info in pairs(info.doors) do
            assert(door_info.native_pos)
        end
        self.rooms[depth] = self.rooms[depth] or {}
        self.rooms[depth][leaf] = info
        return info
    end

    function object.reverse(native_dir)
        local opposites = { forward='backward', up='down', down='up', backward='forward', }
        return opposites[native_dir]
    end

    function object.step(depth, leaf, native_dir)
        local depth_delta = { forward=0, up=-1, down=1, backward=0, }
        local leaf_delta = { forward=1, up=0, down=0, backward=-1, }
        return depth + depth_delta[native_dir], leaf + leaf_delta[native_dir]
    end

    function object:each_room(f)
        for depth, row in Util.pairs_by_keys(self.rooms) do
            for leaf, native_room in Util.pairs_by_keys(row) do
                local map_doors = {}
                for native_dir, native_door in pairs(native_room.doors) do
                    map_doors[native_dir] = {
                        name=self.door_name(native_door.native_pos.depth, native_door.native_pos.leaf, native_door.native_pos.dir),
                        see=native_door.see,
                        reach=native_door.reach,
                        open=native_door.open,
                    }
                end
                local map_info = {
                    doors=map_doors,
                    treasures=native_room.treasures,
                    enemies=native_room.enemies,
                }
                f(depth, leaf, map_info)
            end
        end
    end

    function object:treasure(treasure, depth, leaf)
        local info = self:get_room(depth, leaf)
        local data = {
            item_name = treasure.name,
        }
        if treasure.see ~= 'nothing' then data.see=treasure.see end
        if treasure.reach ~= 'nothing' then data.reach=treasure.reach end
        if treasure.open ~= 'nothing' then data.open=treasure.open end
        table.insert(info.treasures, data)
    end

    function object:enemy(enemy, depth, leaf)
        local info = self:get_room(depth, leaf)
        table.insert(info.enemies, enemy)
    end

    function object.treasure_name(depth, leaf, n)
        return string.format("%s_treasure_%d", object.room_name(depth, leaf), n)
    end

    function object.room_name(depth, leaf)
        local map_x, map_y = object.pos_from_native(depth, leaf)
        return string.format('room_%d_%d', map_x, map_y)
    end

    function object.door_name(depth, leaf, native_dir)
        local map_x, map_y = object.pos_from_native(depth, leaf)
        local map_dir = object.dir_from_native(native_dir)
        if map_dir == 'east' then
            map_x = map_x + 1
            map_dir = 'west'
        elseif map_dir == 'south' then
            map_y = map_y + 1
            map_dir = 'north'
        end
        return string.format('room_%d_%d_%s', map_x, map_y, dir)
    end

    function object:room(room, depth, leaf, native_dir)
        local from_dir = self.reverse(native_dir)
        local parent_depth, parent_leaf = self.step(depth, leaf, from_dir)
        local native_pos = { depth=depth, leaf=leaf, dir=native_dir }
        local info = {
            doors={
                [from_dir]={
                    native_pos=native_pos,
                    see=room.see,
                    open=room.open,
                },
            },
            treasures={},
            enemies={},
        }
        self:new_room(depth, leaf, info)
        if self:has_room(parent_depth, parent_leaf) then
            self:get_room(parent_depth, parent_leaf).doors[native_dir] = {
                native_pos=native_pos,
                see=room.see,
                reach=room.reach,
                open=room.open,
            }
        end
    end

    return object
end


Layout.NorthEastwardVisitor = BaseVisitor:new{
    inwards='down',
    pos_from_native = function (depth, leaf)
        return leaf, 9-depth
    end,
    dir_from_native = function (dir)
        local dirs = {
            forward='east',
            down='north',
            up='south',
            backward='west',
        }
        return dirs[dir]
    end,
}

Layout.NorthWestwardVisitor = BaseVisitor:new{
    inwards='down',
    pos_from_native = function (depth, leaf)
        return 9-leaf, 9-depth
    end,
    dir_from_native = function (dir)
        local dirs = {
            forward='west',
            down='north',
            up='south',
            backward='east',
        }
        return dirs[dir]
    end,
}


function Layout.print_mixin(object)

    object = collect_mixin(object)

    function object:collect_on_finish()
        self:each_room(function (depth, leaf, info)
            local map_x, map_y = self.pos_from_native(depth, leaf)
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

            for n, treasure in ipairs(info.treasures) do
                print(string.format("  Item %s", self.treasure_name(depth, leaf, n)))
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

    object = collect_mixin(object)

    function object:collect_on_start()
        self.has_map = self.game:get_value('map')
        self.has_compass = self.game:get_value('compass')
    end

    function object:room_perception(room_id)
        if self.game:get_value(room_id) then
            return 2
        elseif self.has_map then
            return 1
        else
            return 0
        end
    end

    function object:collect_on_finish()
        local doors = {}

        self:each_room(function (depth, leaf, info)
            local room_perception = self:room_perception(self.room_name(depth, leaf))
            local x, y = self.pos_from_native(depth, leaf)

            if room_perception > 0 then
                map_menu:draw_room(x, y, room_perception)
                for native_dir, door in pairs(info.doors) do
                    local dir = self.dir_from_native(native_dir)
                    local door_info = doors[door.name] or {}

                    if dir == 'south' then
                        door_info.dir = 'north'
                        door_info.x = x
                        door_info.y = y + 1
                    elseif dir == 'east' then
                        door_info.dir = 'west'
                        door_info.x = x + 1
                        door_info.y = y
                    else
                        door_info.dir = dir
                        door_info.x = x
                        door_info.y = y
                    end
                    door_info.is_entrance = (door.open == 'entrance')
                    if not door.see or self.game:get_value(door.name) then
                        door_info.perception = math.max(door_info.perception or 0, room_perception)
                        doors[door.name] = door_info
                    end
                end
            end

            if self.has_compass then
                for n, treasure in ipairs(info.treasures) do
                    local treasure_name = self.treasure_name(depth, leaf, n)
                    if treasure.open == 'bigkey' then
                        map_menu:draw_big_chest(x, y)
                    else
                        map_menu:draw_chest(x, y)
                    end
                end
                for _, enemy in ipairs(info.enemies) do
                    if enemy.name == 'boss' then
                        map_menu:draw_boss(x, y)
                    end
                end
            end
        end)
        for _, info in pairs(doors) do
            if info.is_entrance then
                map_menu:draw_entrance(info.x, info.y, info.dir)
            else
                map_menu:draw_door(info.x, info.y, info.dir, info.perception)
            end
        end
        if self.has_compass then
            map_menu:draw_hero_point()
        end
    end

    return object
end

function Layout.solarus_mixin(object, map, floors)

    object = collect_mixin(object)

    local map_width, map_height = map:get_size()

    function mark_known_room(x, y)
        map:get_game():set_value(string.format('room_%d_%d', x, y), true)
    end

    function object:move_hero_to_start()
        local start_x, start_y = self.pos_from_native(0, 0)
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
        mark_known_room(self.pos_from_native(0, 0))
        self:each_room(function (depth, leaf, info)
            local map_x, map_y = self.pos_from_native(depth, leaf)
            self:separator(map_x, map_y, 'north')
            self:separator(map_x, map_y, 'west')
            self:separator(map_x, map_y+1, 'north')
            self:separator(map_x+1, map_y, 'west')

            local map_info = {
                name=self.room_name(depth, leaf),
                doors={},
                treasures={},
                enemies=info.enemies,
                rng=self.rng:biased(10 * map_y + map_x),
            }
            local doors = {}
            for native_dir, door in pairs(info.doors) do
                map_info.doors[self.dir_from_native(native_dir)] = door
            end
            for n, treasure in ipairs(info.treasures) do
                table.insert(map_info.treasures, {
                    name=self.treasure_name(depth, leaf, n),
                    item_name=treasure.item_name,
                    see=treasure.see,
                    reach=treasure.reach,
                    open=treasure.open,
                })
            end

            local floor_rng = self.rng:biased(10 * map_y + map_x)
            local x, y = 320 * map_x, 240 * map_y
            map:include(x, y, floors[floor_rng:random(#floors)], {})
            map:include(x, y, 'rooms/room1', map_info)
        end)
    end

    return object
end


return Layout
