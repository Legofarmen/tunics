local Class = require 'lib/class'
local util = require 'lib/util'


local Layout = {}


Layout.DIRECTIONS = { east=0, north=1, west=2, south=3, }


local BaseVisitor = Class:new()

function BaseVisitor:render(tree)
    self.leaf = 0
    self.depth = 0
    self.dir = self.entrance_dir
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

function BaseVisitor:down(my_depth, child)
    self.depth = my_depth + 1
    self.dir = 'down'
    child:accept(self)
end

function BaseVisitor:forward(my_depth, child)
    self.depth = my_depth
    self.dir = 'forward'
    child:accept(self)
end

function BaseVisitor:catch_up(my_depth, my_leaf, leaf_max)
    while my_leaf < leaf_max do
        my_leaf = my_leaf + 1
        self:room({}, my_depth, my_leaf, 'forward')
    end
end

function BaseVisitor:get_weight(child)
    if child.dir then
        if child.dir == self.forward_dir then
            return math.huge
        elseif child.dir == self.down_dir then
            return -1
        else
            error('cannot satisfy room with direction ' .. child.dir)
        end
    else
        return child:get_weight()
    end
end

function BaseVisitor:visit_room(room)
    assert(self.dir)
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
            local weight = self:get_weight(child)
            if weight > 0 and not heavy_key then
                heavy_key = key
                heavy_weight = child:get_weight()
            else
                if weight > heavy_weight then
                    child = room.children[heavy_key]
                    heavy_weight = weight
                    heavy_key = key
                end
                self:catch_up(my_depth, my_leaf, self.leaf)
                my_leaf = self.leaf
                self:down(my_depth, child)
                light_count = light_count + 1
            end
        end
    end)
    if heavy_key then
        local child = room.children[heavy_key]
        if light_count == 0 and not child.dir then
            self:catch_up(my_depth, my_leaf, self.leaf - 1)
            self:down(my_depth, child)
        else
            self:catch_up(my_depth, my_leaf, self.leaf - 1)
            self.leaf = math.max(my_leaf + 1, self.leaf)
            self:forward(my_depth, child)
        end
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
        self.min_depth = nil
        self.max_depth = nil
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
        self.min_depth = math.min(self.min_depth or 0, depth)
        self.max_depth = math.max(self.max_depth or 0, depth)
        return info
    end

    function object.reverse(native_dir)
        local opposites = { forward='backward', up='down', down='up', backward='forward', }
        return opposites[native_dir]
    end

    function object.step(depth, leaf, native_dir)
        assert(native_dir)
        local depth_delta = { forward=0, up=-1, down=1, backward=0, }
        local leaf_delta = { forward=1, up=0, down=0, backward=-1, }
        return depth + depth_delta[native_dir], leaf + leaf_delta[native_dir]
    end

    function object:each_room(f)
        for depth, row in util.pairs_by_keys(self.rooms) do
            for leaf, native_room in util.pairs_by_keys(row) do
                f(depth, leaf, native_room)
            end
        end
    end

    function object:treasure(treasure, depth, leaf)
        assert(treasure)
        local info = self:get_room(depth, leaf)
        local data = {
            item_name = treasure.name,
        }
        if treasure.reach ~= 'nothing' then data.reach=treasure.reach end
        if treasure.open ~= 'nothing' then data.open=treasure.open end
        table.insert(info.treasures, data)
    end

    function object:enemy(enemy, depth, leaf)
        local info = self:get_room(depth, leaf)
        table.insert(info.enemies, enemy)
    end

    function object:room(room, depth, leaf, native_dir)
        assert(native_dir)
        local from_dir = self.reverse(native_dir)
        local parent_depth, parent_leaf = self.step(depth, leaf, from_dir)
        local native_pos = { depth=depth, leaf=leaf, dir=native_dir }
        local info = {
            doors={
                [from_dir]={
                    native_pos=native_pos,
                    reach=room.exit,
                },
            },
            treasures={},
            enemies={},
        }
        self:new_room(depth, leaf, info)
        if self:has_room(parent_depth, parent_leaf) then
            local data = {
                native_pos=native_pos,
            }
            if room.reach ~= 'nothing' then data.reach = room.reach end
            if room.open ~= 'nothing' then data.open = room.open end
            if room.exit ~= 'nothing' then data.exit = room.exit end
            self:get_room(parent_depth, parent_leaf).doors[native_dir] = data
        end
    end

    return object
end

function coord_mixin(object, transforms)
    assert(transforms.pos_from_native)
    assert(transforms.dir_from_native)

    function object:treasure_name(depth, leaf, n)
        return string.format("%s_treasure_%d", self:room_name(depth, leaf), n)
    end

    function object:room_name(depth, leaf)
        local map_x, map_y = self:pos_from_native(depth, leaf)
        return string.format('room_%d_%d', map_x, map_y)
    end

    function object:door_name(depth, leaf, native_dir)
        local map_x, map_y = self:pos_from_native(depth, leaf)
        local map_dir = self:dir_from_native(native_dir)
        if map_dir == 'east' then
            map_x = map_x + 1
            map_dir = 'west'
        elseif map_dir == 'south' then
            map_y = map_y + 1
            map_dir = 'north'
        end
        return string.format('room_%d_%d_%s', map_x, map_y, map_dir)
    end

    object.pos_from_native = transforms.pos_from_native

    object.dir_from_native = transforms.dir_from_native

    return object
end


Layout.NorthEastwardVisitor = collect_mixin(BaseVisitor:new{
    entrance_dir='down',
    forward_dir='east',
    down_dir='north',
})
Layout.NorthEastwardVisitor = coord_mixin(Layout.NorthEastwardVisitor, {
    pos_from_native = function (self, depth, leaf)
        local left = math.floor((10 - self.leaf) / 2)
        local bottom = math.floor((10 - self.max_depth) / 2)
        return left + leaf, 10 - bottom - depth
    end,
    dir_from_native = function (self, dir)
        local dirs = {
            forward='east',
            down='north',
            up='south',
            backward='west',
        }
        return dirs[dir]
    end,
})

Layout.NorthWestwardVisitor = collect_mixin(BaseVisitor:new{
    entrance_dir='down',
    forward_dir='west',
    down_dir='north',
})
Layout.NorthWestwardVisitor = coord_mixin(Layout.NorthWestwardVisitor, {
    pos_from_native = function (self, depth, leaf)
        local right = math.floor((10 - self.leaf) / 2)
        local bottom = math.floor((10 - self.max_depth) / 2)
        return 10 - right - leaf, 10 - bottom - depth
    end,
    dir_from_native = function (self, dir)
        local dirs = {
            forward='west',
            down='north',
            up='south',
            backward='east',
        }
        return dirs[dir]
    end,
})


Layout.BidiVisitor = collect_mixin(BaseVisitor:new{
    entrance_dir='forward',
    forward_dir='north',
})
Layout.BidiVisitor = coord_mixin(Layout.BidiVisitor, {
    pos_from_native = function (self, depth, leaf)
        local left = math.floor((10 - (self.max_depth - self.min_depth)) / 2) - self.min_depth
        local bottom = math.floor((10 - math.max(self.left.leaf, self.right.leaf, self.leaf)) / 2)
        return left + depth, 9 - bottom - leaf
    end,
    dir_from_native = function (self, dir)
        local dirs = {
            forward='north',
            down='east',
            up='west',
            backward='south',
        }
        return dirs[dir]
    end,
})

function Layout.BidiVisitor:new(o)
    o = o or {}
    local left_dir = {
        forward='forward',
        down='up',
    }
    o.left = BaseVisitor:new{
        entrance_dir='down',
        forward_dir='north',
        down_dir='west',
        room = function (self, room, depth, leaf, dir)
            assert(dir)
            o:room(room, -(depth + 1), leaf, left_dir[dir])
        end,
        enemy = function (self, enemy, depth, leaf) o:enemy(enemy, -(depth + 1), leaf, left_dir[dir]) end,
        treasure = function (self, treasure, depth, leaf) o:treasure(treasure, -(depth + 1), leaf, left_dir[dir]) end,
    }
    o.right = BaseVisitor:new{
        entrance_dir='down',
        forward_dir='north',
        down_dir='east',
        room = function (self, room, depth, leaf, dir)
            o:room(room, depth + 1, leaf, dir)
        end,
        enemy = function (self, enemy, depth, leaf) o:enemy(enemy, depth + 1, leaf, dir) end,
        treasure = function (self, treasure, depth, leaf) o:treasure(treasure, depth + 1, leaf, dir) end,
    }
    return BaseVisitor.new(self, o)
end

function Layout.BidiVisitor:down(my_depth, child)
    if self.left.leaf <= self.right.leaf then
        self.left.depth = 0
        self.left.dir = self.left.entrance_dir
        child:accept(self.left)
    else
        self.right.depth = 0
        self.right.dir = self.right.entrance_dir
        child:accept(self.right)
    end
    self.leaf = math.min(self.left.leaf, self.right.leaf)
end

function Layout.BidiVisitor:forward(my_depth, child)
    self.left.leaf = math.max(self.left.leaf, self.leaf)
    self.right.leaf = math.max(self.right.leaf, self.leaf)
    self.depth = my_depth
    self.dir = 'forward'
    child:accept(self)
end


local old_on_start = Layout.BidiVisitor.on_start
function Layout.BidiVisitor:on_start()
    self.left.leaf = 0
    self.left.depth = 0
    self.right.leaf = 0
    self.right.depth = 0
    old_on_start(self)
end


function Layout.print_mixin(object)

    function object:collect_on_finish()
        self:each_room(function (depth, leaf, info)
            function print_access(thing)
                if not thing:is_reachable() then print(string.format("\t\tto reach: %s", thing.reach)) end
                if not thing:is_open() then print(string.format("\t\tto open: %s", thing.open)) end
                if not thing:is_exit() then print(string.format("\t\tto exit: %s", thing.exit)) end
            end
            print(string.format("Room %d;%d", x, y))
            for dir, door in util.pairs_by_keys(info.doors) do
                print(string.format("  Door %s", dir))
                print_access(door)
            end

            for n, treasure in ipairs(info.treasures) do
                print(string.format("  Item %s", self:treasure_name(depth, leaf, n)))
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
            local room_perception = self:room_perception(self:room_name(depth, leaf))
            local x, y = self:pos_from_native(depth, leaf)

            if room_perception > 0 then
                map_menu:draw_room(x, y, room_perception)
                for native_dir, door in pairs(info.doors) do

                    local door_name = self:door_name(door.native_pos.depth, door.native_pos.leaf, door.native_pos.dir)

                    local dir = self:dir_from_native(native_dir)
                    local door_info = doors[door_name] or {}

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
                    door_info.is_entrance = (door.exit == 'entrance')
                    if door.open ~= 'weakwall' or self.game:get_value(door_name) then
                        door_info.perception = math.max(door_info.perception or 0, room_perception)
                        doors[door_name] = door_info
                    end
                end
            end

            if self.has_compass then
                for n, treasure in ipairs(info.treasures) do
                    local treasure_name = self:treasure_name(depth, leaf, n)
                    if not self.game:get_value(treasure_name) then
                        if treasure.open == 'bigkey' then
                            map_menu:draw_big_chest(x, y)
                        else
                            map_menu:draw_chest(x, y)
                        end
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

    local map_width, map_height = map:get_size()

    function mark_known_room(x, y)
        map:get_game():set_value(string.format('room_%d_%d', x, y), true)
    end

    function object:move_hero_to_start()
        local start_x, start_y = self:pos_from_native(0, 0)
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
        mark_known_room(self:pos_from_native(0, 0))
        self:each_room(function (depth, leaf, info)
            local map_x, map_y = self:pos_from_native(depth, leaf)
            self:separator(map_x, map_y, 'north')
            self:separator(map_x, map_y, 'west')
            self:separator(map_x, map_y+1, 'north')
            self:separator(map_x+1, map_y, 'west')

            local room_rng=self.rng:refine('room_' .. map_x .. '_' .. map_y)
            local map_info = {
                name=self:room_name(depth, leaf),
                doors={},
                treasures={},
                enemies=info.enemies,
                rng=room_rng,
            }
            local doors = {}
            for native_dir, native_door in pairs(info.doors) do
                local door_name = self:door_name(native_door.native_pos.depth, native_door.native_pos.leaf, native_door.native_pos.dir)
                map_info.doors[self:dir_from_native(native_dir)] = {
                    name=door_name,
                    reach=native_door.reach,
                    open=native_door.open,
                    exit=native_door.exit,
                }
            end
            for n, treasure in ipairs(info.treasures) do
                table.insert(map_info.treasures, {
                    name=self:treasure_name(depth, leaf, n),
                    item_name=treasure.item_name,
                    reach=treasure.reach,
                    open=treasure.open,
                })
            end

            local x, y = 320 * map_x, 240 * map_y
            map:include(x, y, floors[room_rng:refine('floor'):random(#floors)], {})
            map:include(x, y, 'rooms/room1', map_info)
        end)
    end

    return object
end


return Layout
