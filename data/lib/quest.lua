local Tree = require 'lib/tree'
local Class = require 'lib/class'

local HideTreasuresVisitor = {}

setmetatable(HideTreasuresVisitor, HideTreasuresVisitor)

function HideTreasuresVisitor:visit_room(room)
    room:each_child(function (key, child)
        if child.class == 'Treasure' and child:is_reachable() and child:is_open() then
            room:update_child(key, child:with_needs{see='compass',reach='puzzle',open='nothing'})
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
    local found = false
    room:each_child(function (key, child)
        if not found and child.open ~= 'smallkey' and child:accept(self) then
            found = true
        end
    end)
    return found
end

function BigKeyDetectorVisitor:visit_treasure(treasure)
    return treasure.name == 'bigkey'
end

function BigKeyDetectorVisitor:visit_enemy(enemy)
    return false
end

local BigkeyDistanceVisitor = {}

setmetatable(BigkeyDistanceVisitor, BigkeyDistanceVisitor)

function BigkeyDistanceVisitor:visit_room(room)
    if room.open == 'bigkey' then
        return 1
    else
        local nearest = math.huge
        room:each_child(function (key, child)
            nearest = math.min(nearest, child:accept(self) + 1)
        end)
        return nearest
    end
end
function BigkeyDistanceVisitor:visit_enemy(enemy)
    return math.huge
end
function BigkeyDistanceVisitor:visit_treasure(treasure)
    if treasure.item_name == 'bigkey' or treasure.open == 'bigkey' then
        return 1
    else
        return math.huge
    end
end


local FillerObstacleVisitor = Class:new()

function FillerObstacleVisitor:new(o)
    assert(o.rng)
    assert(o.obstacles)
    o.counter = 0
    return Class.new(self, o)
end

function FillerObstacleVisitor:visit_treasure(treasure) end
function FillerObstacleVisitor:visit_enemy(enemy) end
function FillerObstacleVisitor:visit_room(room)
    local need = {
        open = 'open',
        reach = self.obstacles[self.rng:refine('' .. self.counter):random(2 * #self.obstacles)],
    }
    local old_metric = room:get_children_metric()
    room:each_child(function (key, child)
        child:accept(self)
        if child:can_need(need) and self.open ~= 'entrance' then
            local new_metric = old_metric - child:get_node_metric() + child:get_node_metric_with(need)
            if new_metric:is_valid() then
                child:with_needs(need)
                old_metric = new_metric
            end
        end
    end)
end

local Quest = {}

function Quest.treasure_step(item_name)
    return function (root)
        root:add_child(Tree.Treasure:new{name=item_name})
    end
end

function Quest.boss_step(root)
    root:add_child(Tree.Enemy:new{name='boss'}:with_needs{open='bigkey',reach='nothing',dir='north'})
end

function Quest.fairy_step(root)
    root:add_child(Tree.Enemy:new{name='fairy'}:with_needs{see='map',reach='puzzle',open='open'})
end

function Quest.culdesac_step(root)
    root:add_child(Tree.Room:new{})
end

function Quest.hide_treasures_step(root)
    root:accept(HideTreasuresVisitor)
end

function Quest.obstacle_step(item_name, open, see)
    return function (root)
        root:each_child(function (key, head)
            root:update_child(key, head:with_needs{see=see,reach=item_name,open=open})
        end)
    end
end

function Quest.big_chest_step(item_name)
    return function (root)
        root:add_child(Tree.Treasure:new{name=item_name, see='nothing', reach='nothing', open='bigkey'})
    end
end

function Quest.locked_door_step(rng, blackboard)
    return function (root)
        local bigkey_found = false
        local chosen_key, chosen_child = root:random_child(rng, function (key, child)
            if bigkey_found then
                return 0
            elseif child:accept(BigKeyDetectorVisitor) then
                bigkey_found = true
                return math.huge
            else
                return 1
            end
        end)
        if chosen_key then
            root:update_child(chosen_key, chosen_child:with_needs{open='smallkey'})
            blackboard.smallkeys = (blackboard.smallkeys or 0) + 1
        end
    end
end

function Quest.smallkey_step(blackboard)
    return function (root)
        if blackboard.smallkeys > 0 then
            Quest.treasure_step('smallkey')(root)
            blackboard.smallkeys = blackboard.smallkeys - 1
        end
    end
end

function Quest.max_heads(rng, n)
    return function (root)
        while #root.children > n do
            local node1 = root:remove_child(root:random_child(rng:refine('node1')))
            local f
            if node1:accept(BigkeyDistanceVisitor) < math.huge then
                f = function(node) return math.min(node:accept(BigkeyDistanceVisitor), 10) end
            else
                f = function(node) return 11 - math.min(node:accept(BigkeyDistanceVisitor), 10) end
            end
            local chosen = root:random_child(rng:refine('node2'), function (key, child)
                local d = 2 * f(child)
                if child.get_weight then
                    return d - child:get_weight()
                else
                    return d
                end
            end)
            local node2 = root:remove_child(chosen)

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

function Quest.sequence(rng, elements)

    function calc_weight(element)
        if not element.weight then
            element.weight = 1
            for dep in pairs(element.deps) do
                element.weight = element.weight + calc_weight(elements[dep])
            end
        end
        return element.weight
    end

    for name, element in pairs(elements) do
        calc_weight(element)
    end

    -- Pick something with no rdeps.
    -- Selection is weighted according to element weight.
    function pick(rng, elements)
        return rng:choose(elements, function (name, element)
            if next(element.rdeps) == nil then
                return element.weight
            else
                return 0
            end
        end)
    end

    local result = {}
    local counter = 1
    while next(elements) do
        local name, element = pick(rng:refine('' .. counter), elements)
        counter = counter + 1
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

Quest.Dependencies = Class:new()

function Quest.Dependencies:new(o)
    o = o or {}
    o.result = o.result or {}
    return Class.new(self, o)
end

function Quest.Dependencies:single(name, element)
    self.result[name] = { step=element, deps={}, rdeps={} }
end

function Quest.Dependencies:dependency(deep_name, shallow_name)
    self.result[deep_name].deps[shallow_name] = true
    self.result[shallow_name].rdeps[deep_name] = true
end

function Quest.Dependencies:multiple(name, count, factory, rng)
    local first = nil
    local last = nil
    for i = 1, count do
        local current = string.format('%s_%d', name, i)
        if rng then
            self:single(current, factory(rng:refine('' .. i)))
        else
            self:single(current, factory())
        end
        if last then
            self:dependency(last, current)
        end
        first = first or current
        last = current
    end
    return first, last
end

function Quest.alpha_dungeon(rng, nkeys, nfairies, nculdesacs, treasure_items, brought_items)
    brought_items = brought_items or {}

    function get_obstacle_types(item_name, has_map)
        if item_name ~= 'bombs_counter' then
            return {item_name}
        elseif has_map then
            return {'veryweakwall','weakwall'}
        else
            return {'veryweakwall'}
        end
    end

    function get_obstacle_step(obstacle_type)
        local see, open
        if obstacle_type == 'weakwall' then
            see = 'nothing'
            open = 'weakwall'
        elseif obstacle_type == 'veryweakwall' then
            see = 'nothing'
            open = 'veryweakwall'
        else
            see = 'nothing'
            open = 'open'
        end
        return Quest.obstacle_step(obstacle_type, open, see)
    end

    local d = Quest.Dependencies:new()

    d:single('boss', Quest.boss_step)
    d:single('bigkey', Quest.treasure_step('bigkey'))
    d:dependency('boss', 'bigkey')

    d:single('map', Quest.treasure_step('map'))

    d:single('hidetreasures', Quest.hide_treasures_step)
    d:single('compass', Quest.treasure_step('compass'))
    d:dependency('hidetreasures', 'compass')

    for _, item_name in ipairs(treasure_items) do
        local bigchest_name = string.format('bigchest_%s', item_name)
        d:single(bigchest_name, Quest.big_chest_step(item_name))
        d:dependency(bigchest_name, 'bigkey')

        local obstacle_types = get_obstacle_types(item_name, true)
        for _, obstacle_type in ipairs(obstacle_types) do
            local obstacle_name = string.format('obstacle_%s', obstacle_type)
            d:single(obstacle_name, get_obstacle_step(obstacle_type))
            d:dependency('boss', obstacle_name)
            d:dependency(obstacle_name, bigchest_name)
        end
        if item_name == 'bombs_counter' then
            d:dependency('obstacle_weakwall', 'map')
            d:dependency('obstacle_weakwall', 'obstacle_veryweakwall')
        end
    end

    local blackboard = {}
    local lockeddoors_rng = rng:refine('locked_doors')
    local first_lock, last_lock = d:multiple('lockeddoor', nkeys, function (rng) return Quest.locked_door_step(rng, blackboard) end, lockeddoors_rng)
    if first_lock then
        d:dependency('bigkey', last_lock)
        d:dependency('compass', last_lock)
        d:dependency('map', last_lock)
        local first_key, last_key = d:multiple('smallkey', nkeys, function () return Quest.smallkey_step(blackboard) end)
        d:dependency(last_lock, first_key)
    end

    d:multiple('culdesac', nculdesacs, function () return Quest.culdesac_step end)
    d:multiple('fairy', nfairies, function () return Quest.fairy_step end)

    local obstacle_types = {'puzzle'}
    for _, item_name in ipairs(brought_items) do
        for _, obstacle in ipairs(get_obstacle_types(item_name, false)) do
            table.insert(obstacle_types, obstacle)
        end
    end

    local steps = Quest.sequence(rng:refine('steps'), d.result)
    return Quest.render_steps(rng, steps, obstacle_types)
end

function Quest.render_steps(rng, steps, filler_obstacle_types)
    -- Build puzzle tree using the sequence of steps
    local heads = Tree.Room:new()
    for i, element in ipairs(steps) do
        Quest.max_heads(rng:refine('step_' .. i), 6)(heads)
        element.step(heads)
    end

    -- Put entrance room at the the tree root
    local tree = Tree.Room:new{ open='entrance' }
    heads:each_child(function (key, child)
        if not (child.class == 'Room' and child:is_reachable() and child:is_open()) then
            child = Tree.Room:new{ children={child} }
        end
        child:accept(FillerObstacleVisitor:new{
            obstacles = filler_obstacle_types,
            rng = rng:refine('obstacles'),
        })
        tree:add_child(child)
    end)

    return tree
end

return Quest
