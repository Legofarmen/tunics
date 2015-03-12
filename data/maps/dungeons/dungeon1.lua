local map = ...

local game = map:get_game()



local Class = {}

function Class:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

local Node = Class:new()

local Room = Node:new{class='Room'}
local Treasure = Node:new{class='Treasure', open='nothing'}
local Enemy = Node:new{class='Enemy', see='nothing', reach='nothing', open='nothing'}

function Treasure:new(o)
    o = o or {}
    o.savegame_variable = o.savegame_variable or new_id('treasure')
    return Node.new(self, o)
end

function Room:new(o)
    o = o or {}
    o.savegame_variable = o.savegame_variable or new_id('room')
    o.children = o.children or {}
    return Node.new(self, o)
end

function Node:prop_string(keys)
    local s = ''
    local sep = ''
    for _, key in ipairs(keys) do
        local value = self[key] or ''
        if value == 'nothing' then value = '' end
        s = string.format('%s%s%s', s, sep, value)
        sep = ','
    end
    return s
end

function Node:with_needs(needs)
    for kind, need in pairs(needs) do
        if self[kind] then
            needs.children = {self}
            return Room:new(needs)
        end
    end
    for kind, need in pairs(needs) do
        self[kind] = need
    end
    return self
end

function Room:__tostring()
    return string.format("Room[%s]", self:prop_string{'see', 'reach', 'open'})
end

function Treasure:__tostring()
    return string.format("Treasure:%s[%s]", self.name, self:prop_string{'see', 'reach', 'open'})
end

function Enemy:__tostring()
    return string.format("Enemy:%s[]", self.name)
end

function Room:accept(visitor)
    return visitor:visit_room(self)
end

function Treasure:accept(visitor)
    return visitor:visit_treasure(self)
end

function Enemy:accept(visitor)
    return visitor:visit_enemy(self)
end

function Room:add_child(node)
    table.insert(self.children, node)
end

function Room:merge_child(node)
    if node.class ~= 'Room' or node.see or node.reach or node.open then
        self:add_child(node)
    else
        node:each_child(function (key, child)
            self:add_child(child)
        end)
    end
end

function Room:update_child(key, node)
    if self.children[key] then
        self.children[key] = node
    else
        error('no such key: ' .. key)
    end
end

function Room:remove_child(key)
    if self.children[key] then
        return table.remove(self.children, key)
    else
        error('no such key: ' .. key)
    end
end

function Room:each_child(f)
    for key, child in ipairs(self.children) do
        f(key, child)
    end
end


function Room:random_child(w)
    return weighted_random_element(self.children, w)
end



local HideTreasuresVisitor = {}

setmetatable(HideTreasuresVisitor, HideTreasuresVisitor)

function HideTreasuresVisitor:visit_room(room)
    room:each_child(function (key, child)
        if child.class == 'Treasure' and child.open ~= 'big_key' then
            room:update_child(key, child:with_needs{see='compass'})
        end
        child:accept(self)
    end)
end
function HideTreasuresVisitor:visit_treasure(treasure)
end
function HideTreasuresVisitor:visit_enemy(enemy)
end

local TreasureCountVisitor = {}

setmetatable(TreasureCountVisitor, TreasureCountVisitor)

function TreasureCountVisitor:visit_room(room)
    local total_items = 0
    local total_keys
    if room.open == 'small_key' then
        total_keys = -1
    else
        total_keys = 0
    end
    room:each_child(function (key, child)
        local items, keys = child:accept(self)
        total_items = total_items + items
        total_keys = total_keys + keys
    end)
    return total_items, total_keys
end

function TreasureCountVisitor:visit_treasure(treasure)
    local keys
    if treasure.open == 'small_key' then
        keys = -1
    else
        keys = 0
    end
    if treasure.name == 'small_key' then
        return 0, keys + 1
    else
        return 1, keys
    end
end

function TreasureCountVisitor:visit_enemy(enemy)
    return 0, 0
end


local PrintVisitor = {}
PrintVisitor.__index = PrintVisitor
function PrintVisitor:new(o)
    o = o or {}
    o.prefix = o.prefix or ''
    setmetatable(o, PrintVisitor)
    return o
end
function PrintVisitor:visit_room(room)
    local child_prefix = self.prefix .. '  '
    print(self.prefix .. tostring(room))
    room:each_child(function (key, child)
        self.prefix = child_prefix
        child:accept(self)
    end)
end
function PrintVisitor:visit_treasure(treasure)
    print(self.prefix .. tostring(treasure))
end
function PrintVisitor:visit_enemy(enemy)
    print(self.prefix .. tostring(enemy))
end




local counters = {}
function new_id(prefix)
    counters[prefix] = (counters[prefix] or 0) + 1
    return prefix .. counters[prefix]
end

function add_treasure(item_name)
    return function (root)
        root:add_child(Treasure:new{name=item_name})
    end
end

function add_boss(root)
    root:add_child(Enemy:new{name='boss'}:with_needs{open='big_key'})
end

function hide_treasures(root)
    root:accept(HideTreasuresVisitor)
end

function hard_to_reach(item_name)
    return function (root)
        root:each_child(function (key, head)
            root:update_child(key, head:with_needs{reach=item_name})
        end)
    end
end

function add_big_chest(item_name)
    return function (root)
        root:add_child(Treasure:new{name=item_name, open='big_key'})
    end
end

function bomb_doors(root)
    root:each_child(function (key, head)
        root:update_child(key, head:with_needs{see='map',open='bomb'})
    end)
end

function locked_door(root)
    function lockable_weight(node)
        if node.class == 'Room' then
            local items, keys = node:accept(TreasureCountVisitor)
            if items > 0 or keys > 1 then
                return items + keys
            else
                return 0
            end
        else
            return 0
        end
    end
    local key, child = root:random_child(lockable_weight)
    if key then
        root:update_child(key, child:with_needs{open='small_key'})
        return true
    else
        return false
    end
end

function max_heads(n)
    return function (root)
        while #root.children > n do
            local fork = Room:new()
            fork:merge_child(root:remove_child(root:random_child()))
            fork:merge_child(root:remove_child(root:random_child()))
            root:add_child(fork)
        end
    end
end


function intermingle(a, b)
    local result = {}
    local i = 1
    local j = 1
    local total = #a + #b
    while total > 0 do
        if math.random(total) <= #a - i + 1 then
            table.insert(result, a[i])
            i = i + 1
        else
            table.insert(result, b[j])
            j = j + 1
        end
        total = total - 1
    end
    return result
end

function concat(a, b)
    for _, value in ipairs(b) do
        table.insert(a, value)
    end
    return a
end

function shuffle(array)
    for i, _ in ipairs(array) do
        local j = math.random(#array)
        array[i], array[j] = array[j], array[i]
    end
end

function weighted_random_element(array, w)
    local total = 0
    local rkey, rchild
    for key, elem in ipairs(array) do
        local weight = w and w(elem) or 1
        total = total + weight
        if weight > math.random() * total then
            rkey = key
            rchild = elem
        end
    end
    return rkey, rchild
end



function compass_puzzle()
    return {
        hide_treasures,
        add_treasure('compass'),
    }
end

function map_puzzle()
    local steps = {
        add_treasure('bomb'),
        add_treasure('map'),
    }
    shuffle(steps)
    table.insert(steps, 1, bomb_doors)
    return steps
end

function items_puzzle(item_names)
    shuffle(item_names)
    local steps = {}
    for _, item_name in ipairs(item_names) do
        table.insert(steps, hard_to_reach(item_name))
        table.insert(steps, add_big_chest(item_name))
    end
    table.insert(steps, add_treasure('big_key'))
    return steps
end

function lock_puzzle()
    return {
        function (root)
            if locked_door(root) then
                add_treasure('small_key')(root)
            end
        end,
    }
end

function dungeon_puzzle(nkeys, item_names)
    local puzzles = {
        items_puzzle(item_names),
        map_puzzle(),
        compass_puzzle(),
    }
    for i = 1, nkeys do
        table.insert(puzzles, lock_puzzle())
    end
    shuffle(puzzles)

    local steps = {}
    for _, puzzle in ipairs(puzzles) do
        local n = math.random(2)
        if n == 1 then
            steps = intermingle(steps, puzzle)
        else
            steps = concat(steps, puzzle)
        end
    end
    table.insert(steps, 1, add_boss)
    return steps
end


function filter_keys(table, keys)
    local result = {}
    for _, key in ipairs(keys) do
        if table[key] then result[key] = table[key] end
    end
    return result
end


local LayoutVisitor = Class:new()

function LayoutVisitor:render_room(properties)

    local floor = string.format('floor.%d',
        (properties.x + 9 * properties.y) % 18 + 1
    )


    function print_access(thing)
        if thing.see and thing.see ~= 'nothing' then print(string.format("\t\tto see: %s", thing.see)) end
        if thing.reach and thing.reach ~= 'nothing' then print(string.format("\t\tto reach: %s", thing.reach)) end
        if thing.open and thing.open ~= 'nothing' then print(string.format("\t\tto open: %s", thing.open)) end
    end
    print(string.format("Room %d;%d %s", properties.x, properties.y, floor))
    for dir, door in pairs(properties.doors) do
        print(string.format("  Door %s", dir))
        --print_access(door)
    end
    --[[
    for _, item in ipairs(properties.items) do
        print(string.format("  Item %s", item.name))
        print_access(item)
    end
    for _, enemy in ipairs(properties.enemies) do
        print(string.format("  Enemy %s", enemy.name))
        print_access(enemy)
    end
    ]]
    print()
    local x0 = 200 - 160 + 320 * properties.x
    local y0 = 1400 - 216 + 240 * properties.y

    map:include(x0, y0, 'rooms/room1', properties.doors, properties.items, properties.items, floor)
end

function LayoutVisitor:visit_enemy(enemy)
    table.insert(self.enemies, enemy)
end

function LayoutVisitor:visit_treasure(treasure)
    table.insert(self.items, treasure)
end

function LayoutVisitor:visit_room(room)
    local y = self.y
    local x0 = self.x
    local x1 = x0
    local doors = {}
    local items = {}
    local enemies = {}
    local old_nkids = self.nkids

    local door_variable = room.savegame_variable:gsub('room', 'door')

    if self.doors then
        self.doors.north = filter_keys(room, {'see','reach','open'})
        self.doors.north.savegame_variable = door_variable
    end

    self.nkids = 0
    room:each_child(function (key, child)
        self.y = y - 1
        self.items = items
        self.enemies = enemies
        if child.class == 'Room' then
            x1 = self.x
            doors[x1] = doors[x1] or {}
            self.doors = doors[x1]
        end
        child:accept(self)
    end)

    for x = x0, x1 do
        doors[x] = doors[x] or {}
        if x == x0 then doors[x].south = filter_keys(room, {'open'}) end
        if x < x1 then doors[x].east = {} end
        if x > x0 then doors[x].west = {} end
        self:render_room{
            x=x,
            y=y,
            doors=doors[x],
            items=items,
            enemies=enemies,
        }
        items = {}
        enemies = {}
    end

    if self.nkids == 0 then
        self.x = self.x + 1
    end
    self.nkids = self.old_nkids
end



local puzzle = dungeon_puzzle(3, {'hookshot'})
local root = Room:new()
for i, step in ipairs(puzzle) do
    max_heads(3)(root)
    step(root)
end
root:each_child(function (key, child)
    if child.class ~= 'Room' then
        local room = Room:new()
        room:add_child(child)
        root:update_child(key, room)
    end
end)
local tree = Room:new{open='entrance'}
local tree = root
tree.open = 'entrance'

tree:accept(PrintVisitor:new{})
tree:accept(LayoutVisitor:new{x=0, y=0})
