local Tree = require 'lib/tree'
local List = require 'lib/list'
local Class = require 'lib/class'

local HideTreasuresVisitor = {}

setmetatable(HideTreasuresVisitor, HideTreasuresVisitor)

function HideTreasuresVisitor:visit_room(room)
    room:each_child(function (key, child)
        if child.class == 'Treasure' and child:is_reachable() and child:is_open() then
            room:update_child(key, child:with_needs{see='compass',reach='nothing',open='nothing'})
        end
        child:accept(self)
    end)
end
function HideTreasuresVisitor:visit_treasure(treasure)
end
function HideTreasuresVisitor:visit_enemy(enemy)
end

local KeyDetectorVisitor = {}

setmetatable(KeyDetectorVisitor, KeyDetectorVisitor)

function KeyDetectorVisitor:visit_room(room)
    local is_lockable = nil
    local has_treasures = nil
    room:each_child(function (key, child)
        if is_lockable ~= false then
            is_lockable = is_lockable or child:accept(self)
        end
    end)
    return is_lockable
end

function KeyDetectorVisitor:visit_treasure(treasure)
    if treasure.name == 'smallkey' then
        return false
    else
        return true
    end
end

function KeyDetectorVisitor:visit_enemy(enemy)
    return nil
end

local Puzzle = {}

function Puzzle.treasure_step(item_name)
    return function (root)
        root:add_child(Tree.Treasure:new{name=item_name})
    end
end

function Puzzle.boss_step(root)
    root:add_child(Tree.Enemy:new{name='boss'}:with_needs{open='bigkey',reach='nothing',dir='north'})
end

function Puzzle.fairy_step(root)
    root:add_child(Tree.Enemy:new{name='fairy'}:with_needs{open='bomb',see='map'})
end

function Puzzle.culdesac_step(root)
    root:add_child(Tree.Room:new{})
end

function Puzzle.hide_treasures_step(root)
    root:accept(HideTreasuresVisitor)
end

function Puzzle.obstacle_step(item_name)
    return function (root)
        root:each_child(function (key, head)
            root:update_child(key, head:with_needs{see='nothing',reach=item_name})
        end)
    end
end

function Puzzle.big_chest_step(item_name)
    return function (root)
        root:add_child(Tree.Treasure:new{name=item_name, open='bigkey'})
    end
end

function Puzzle.bomb_doors_step(root)
    root:each_child(function (key, head)
        root:update_child(key, head:with_needs{see='map',open='bomb'})
    end)
end

function Puzzle.locked_door_step(rng, blackboard)
    function lockable_weight(node)
        local is_lockable = node:accept(KeyDetectorVisitor)
        if is_lockable then
            return 1
        else
            return 0
        end
    end
    return function (root)
        local key, child = root:random_child(rng, lockable_weight)
        if key then
            root:update_child(key, child:with_needs{open='smallkey'})
            blackboard.smallkeys = (blackboard.smallkeys or 0) + 1
            return true
        else
            return false
        end
    end
end

function Puzzle.smallkey_step(blackboard)
    return function (root)
        if blackboard.smallkeys > 0 then
            Puzzle.treasure_step('smallkey')(root)
            blackboard.smallkeys = blackboard.smallkeys - 1
        end
    end
end

function Puzzle.max_heads(rng, n)
    return function (root)
        while #root.children > n do
            local node1 = root:remove_child(root:random_child(rng))
            local node2 = root:remove_child(root:random_child(rng))

            local fork = Tree.Room:new()
            local n1 = node1:get_node_metric()
            local n2 = node2:get_node_metric()
            local c1 = node1.class == 'Room' and node1:is_normal() and node1:get_children_metric()
            local c2 = node2.class == 'Room' and node2:is_normal() and node2:get_children_metric()
            if c1 and c2 and (c1 + c2):is_valid() then
                fork:merge_children(node1)
                fork:merge_children(node2)
            elseif c1 and (c1 + n2):is_valid() then
                fork:merge_children(node1)
                fork:add_child(node2)
            elseif c2 and (n1 + c2):is_valid() then
                fork:add_child(node1)
                fork:merge_children(node2)
            elseif (n1 + n2):is_valid() then
                fork:add_child(node1)
                fork:add_child(node2)
            else
                local node2wrapped = Tree.Room:new()
                node2wrapped:add_child(node2)
                fork:add_child(node1)
                fork:add_child(node2wrapped)
            end
            root:add_child(fork)
        end
    end
end

function Puzzle.compass_puzzle()
    return {
        Puzzle.hide_treasures_step,
        Puzzle.treasure_step('compass'),
    }
end

function Puzzle.map_puzzle(rng, nfairies)
    local steps = {
        Puzzle.treasure_step('bomb'),
        Puzzle.treasure_step('map'),
    }
    for i = 1, nfairies do
        table.insert(steps, Puzzle.fairy_step)
    end
    List.shuffle(rng, steps)
    table.insert(steps, 1, Puzzle.bomb_doors_step)
    return steps
end

function Puzzle.items_puzzle(rng, item_names)
    List.shuffle(rng, item_names)
    local steps = {}
    for _, item_name in ipairs(item_names) do
        table.insert(steps, Puzzle.obstacle_step(item_name))
        table.insert(steps, Puzzle.big_chest_step(item_name))
    end
    table.insert(steps, Puzzle.treasure_step('bigkey'))
    return steps
end

function Puzzle.culdesac_puzzle(n)
    local steps = {}
    for i = 1, n do
        table.insert(steps, Puzzle.culdesac_step)
    end
    return steps
end

function Puzzle.lock_puzzle(rng, n)
    return {
        function (root)
            for i = 1, n do
                if not Puzzle.locked_door_step(rng, root) then break end
                Puzzle.treasure_step('smallkey')(root)
            end
        end,
    }
end

function Puzzle.sequence(rng, elements)

    function calc_weight(element)
        if not element.weight then
            element.weight = 1
            for dep in pairs(element.deps) do
                element.weight = element.weight + calc_weight(elements[dep])
            end
        end
        return element.weight
    end

    local total_weight = 0
    for name, element in pairs(elements) do
        total_weight = total_weight + calc_weight(element)
    end

    -- Pick something with no rdeps.
    -- Selection is weighted according to element weight.
    function pick(elements)
        local result = nil
        local n = 0
        for name, element in pairs(elements) do
            if next(element.rdeps) == nil then
                n = n + element.weight
                local r = rng:random()
                if rng:random(n) <= element.weight then
                    result = name
                end
            end
        end
        return result
    end

    local result = {}
    while next(elements) do
        local name = pick(elements)
        local element = elements[name]
        for dep in pairs(element.deps) do
            elements[dep].rdeps[name] = nil
        end
        element.name = name
        element.deps = nil
        element.rdeps = nil
        table.insert(result, element)
        elements[name] = nil
    end
    return result
end

Puzzle.Dependencies = Class:new()

function Puzzle.Dependencies:new(o)
    o = o or {}
    o.result = o.result or {}
    return Class.new(self, o)
end

function Puzzle.Dependencies:single(name, element)
    self.result[name] = { step=element, deps={}, rdeps={} }
end

function Puzzle.Dependencies:dependency(deep_name, shallow_name)
    self.result[deep_name].deps[shallow_name] = true
    self.result[shallow_name].rdeps[deep_name] = true
end

function Puzzle.Dependencies:multiple(name, count, element)
    local first = nil
    local last = nil
    for i = 1, count do
        local current = string.format('%s_%d', name, i)
        self:single(current, element)
        if last then
            self:dependency(last, current)
        end
        first = first or current
        last = current
    end
    return first, last
end

function Puzzle.alpha_dungeon(rng, nkeys, nfairies, nculdesacs, item_names)
    local d = Puzzle.Dependencies:new()

    d:single('boss', Puzzle.boss_step)
    d:single('bigkey', Puzzle.treasure_step('bigkey'))
    for _, item_name in ipairs(item_names) do
        local obstacle_name = string.format('obstacle_%s', item_name)
        local bigchest_name = string.format('bigchest_%s', item_name)
        d:single(obstacle_name, Puzzle.obstacle_step(item_name))
        d:single(bigchest_name, Puzzle.big_chest_step(item_name))
        d:dependency('boss', obstacle_name)
        d:dependency(obstacle_name, bigchest_name)
        d:dependency(bigchest_name, 'bigkey')
    end

    d:single('bomb', Puzzle.treasure_step('bomb'))
    d:single('map', Puzzle.treasure_step('map'))
    d:single('bombdoors', Puzzle.bomb_doors_step)
    d:dependency('bombdoors', 'bomb')
    d:dependency('bombdoors', 'map')
    d:multiple('fairy', nfairies, Puzzle.fairy_step)

    d:single('hidetreasures', Puzzle.hide_treasures_step)
    d:single('compass', Puzzle.treasure_step('compass'))
    d:dependency('hidetreasures', 'compass')

    local blackboard = {}
    local lockeddoors_rng = rng:create()
    local first_lock, last_lock = d:multiple('lockeddoor', nkeys, Puzzle.locked_door_step(lockeddoors_rng, blackboard))
    d:dependency('bigkey', first_lock)
    d:dependency('compass', first_lock)
    d:dependency('map', first_lock)
    local first_key, last_key = d:multiple('smallkey', nkeys, Puzzle.smallkey_step(blackboard))
    d:dependency(last_lock, first_key)

    d:multiple('culdesac', nculdesacs, Puzzle.culdesac_step)

    local steps = Puzzle.sequence(rng:create(), d.result)

    -- Build puzzle tree using the sequence of steps
    local heads = Tree.Room:new()
    for name, element in ipairs(steps) do
        Puzzle.max_heads(rng:create(), 4)(heads)
        element.step(heads)
    end

    -- Put entrance room at the the tree root
    local root = Tree.Room:new{ open='entrance' }
    heads:each_child(function (key, child)
        if child.class == 'Room' and child:is_reachable() and child:is_open() then
            root:add_child(child)
        else
            root:add_child(Tree.Room:new{ children={child} })
        end
    end)

    return root
end

return Puzzle
