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

local BigKeyDetectorVisitor = {}

setmetatable(BigKeyDetectorVisitor, BigKeyDetectorVisitor)

function BigKeyDetectorVisitor:visit_room(room)
    room:each_child(function (key, child)
        if not child.open == 'smallkey' and child:accept(self) then
            return true
        end
    end)
    return false
end

function BigKeyDetectorVisitor:visit_treasure(treasure)
    return treasure.name == 'bigkey'
end

function BigKeyDetectorVisitor:visit_enemy(enemy)
    return false
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
    root:add_child(Tree.Enemy:new{name='fairy'}:with_needs{see='map',reach='weakwall',open='weakwall'})
end

function Puzzle.culdesac_step(root)
    root:add_child(Tree.Room:new{})
end

function Puzzle.hide_treasures_step(root)
    root:accept(HideTreasuresVisitor)
end

function Puzzle.obstacle_step(item_name, open, see)
    see = see or 'nothing'
    return function (root)
        root:each_child(function (key, head)
            root:update_child(key, head:with_needs{see=see,reach=item_name,open=open})
        end)
    end
end

function Puzzle.big_chest_step(item_name)
    return function (root)
        root:add_child(Tree.Treasure:new{name=item_name, see='nothing', reach='nothing', open='bigkey'})
    end
end

function Puzzle.locked_door_step(rng, blackboard)
    return function (root)
        local bigkey_found = false
        local chosen_key = nil
        local chosen_child = nil
        local n = 1
        root:each_child(function (key, child)
            if not bigkey_found then
                if rng:random(n) == 1 then
                    chosen_key = key
                    chosen_child = child
                end
                n = n + 1
                if child:accept(BigKeyDetectorVisitor) then
                    bigkey_found = true
                    chosen_key = key
                    chosen_child = child
                end
            end
        end)
        if chosen_key then
            root:update_child(chosen_key, chosen_child:with_needs{open='smallkey'})
            blackboard.smallkeys = (blackboard.smallkeys or 0) + 1
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

    function get_obstacle_step(obstacle_type)
        if obstacle_type == 'weakwall' then
            return Puzzle.obstacle_step(obstacle_type, 'weakwall', 'map')
        else
            return Puzzle.obstacle_step(obstacle_type)
        end
    end

    local d = Puzzle.Dependencies:new()

    d:single('boss', Puzzle.boss_step)
    d:single('bigkey', Puzzle.treasure_step('bigkey'))
    d:dependency('boss', 'bigkey')

    d:single('map', Puzzle.treasure_step('map'))

    d:single('hidetreasures', Puzzle.hide_treasures_step)
    d:single('compass', Puzzle.treasure_step('compass'))
    d:dependency('hidetreasures', 'compass')

    for _, item_name in ipairs(item_names) do
        local obstacle_type
        if item_name == 'bomb' then
            obstacle_type = 'weakwall'
        else
            obstacle_type = item_name
        end
        local obstacle_name = string.format('obstacle_%s', obstacle_type)
        local bigchest_name = string.format('bigchest_%s', item_name)
        d:single(obstacle_name, get_obstacle_step(obstacle_type))
        d:single(bigchest_name, Puzzle.big_chest_step(item_name))
        d:dependency('boss', obstacle_name)
        d:dependency(obstacle_name, bigchest_name)
        d:dependency(bigchest_name, 'bigkey')
        if obstacle_type == 'weakwall' then
            d:dependency(obstacle_name, 'map')
        end
    end

    local blackboard = {}
    local lockeddoors_rng = rng:create()
    local first_lock, last_lock = d:multiple('lockeddoor', nkeys, Puzzle.locked_door_step(lockeddoors_rng, blackboard))
    d:dependency('bigkey', first_lock)
    d:dependency('compass', first_lock)
    d:dependency('map', first_lock)
    local first_key, last_key = d:multiple('smallkey', nkeys, Puzzle.smallkey_step(blackboard))
    d:dependency(last_lock, first_key)

    d:multiple('culdesac', nculdesacs, Puzzle.culdesac_step)
    d:multiple('fairy', nfairies, Puzzle.fairy_step)

    local steps = Puzzle.sequence(rng:create(), d.result)

    return Puzzle.render_steps(rng, steps)
end

function Puzzle.render_steps(rng, steps)
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
