local Class = require 'lib/class'

local tree = {}


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


local Node = Class:new()

local Room = Node:new{class='Room'}
local Treasure = Node:new{class='Treasure', open='nothing'}
local Enemy = Node:new{class='Enemy', see='nothing', reach='nothing', open='nothing'}

function Treasure:new(o)
    o = o or {}
    return Node.new(self, o)
end

function Room:new(o)
    o = o or {}
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
        if self[kind] and not (self[kind] == 'nothing' and need == 'nothing') then
            needs.children = {self}
            return Room:new(needs)
        end
    end
    for kind, need in pairs(needs) do
        self[kind] = need
    end
    return self
end

function Node:is_visible()
    return not self.see or self.see == 'nothing'
end

function Node:is_reachable()
    return not self.reach or self.reach == 'nothing'
end

function Node:is_open()
    return not self.open or self.open == 'nothing'
end

function Node:is_normal()
    return self:is_visible() and self:is_reachable() and self:is_open()
end

function Node:is_directional()
    return self.dir
end

function Room:__tostring()
    return string.format("Room[%s]", self:prop_string{'see', 'reach', 'open', 'dir'})
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

function Room:merge_children(node)
    node:each_child(function (key, child)
        self:add_child(child)
    end)
end

function Room:update_child(key, node)
    if self.children[key] then
        if not (self:get_children_metric() - self.children[key]:get_node_metric() + node:get_node_metric()):is_valid() then
            node = Room:new{ children={node} }
        end
        self.children[key] = node
    else
        error('no such key: ' .. key)
    end
end

function Room:remove_child(key)
    if self.children[key] then
        return table.remove(self.children, key)
    else
        error(string.format('no such key: %s', key))
    end
end

function Room:each_child(f)
    for key, child in ipairs(self.children) do
        f(key, child)
    end
end

function Room:random_child(rng, w)
    return rng:ichoose(self.children, w)
end

function Room:get_weight()
    return self:accept(WeightVisitor)
end

tree.Metric = Class:new()

function tree.Metric:new(o)
    o = o or {}
    o.doors = o.doors or 0
    o.hidden_doors = o.hidden_doors or 0
    o.obstacle_doors = o.obstacle_doors or {}
    o.bigkey_doors = o.bigkey_doors or 0
    o.directional_doors = o.directional_doors or 0
    o.treasures = o.treasures or 0
    o.normal_treasures = o.normal_treasures or 0
    o.hidden_treasures = o.hidden_treasures or 0
    o.obstacle_treasures = o.obstacle_treasures or {}
    o.bigkey_treasures = o.bigkey_treasures or 0
    return Node.new(self, o)
end

function tree.Metric.__add(lhs, rhs)
    local metric = tree.Metric:new()
    for key, value in pairs(lhs) do
        if type(value) == 'table' then
            local result = {}
            for key, value in pairs(lhs[key]) do
                result[key] = value
            end
            for key, value in pairs(rhs[key]) do
                result[key] = (result[key] or 0) + value
            end
            metric[key] = result
        else
            metric[key] = value + rhs[key]
        end
    end
    return metric
end

function tree.Metric.__sub(lhs, rhs)
    local metric = tree.Metric:new()
    for key, value in pairs(lhs) do
        if type(value) == 'table' then
            local result = {}
            for key, value in pairs(lhs[key]) do
                result[key] = value
            end
            for key, value in pairs(rhs[key]) do
                if result[key] == value then
                    result[key] = nil
                else
                    result[key] = result[key] - value
                end
            end
            metric[key] = result
        else
            metric[key] = value - rhs[key]
        end
    end
    return metric
end

function Room:get_node_metric()
    local metric = tree.Metric:new()
    metric.doors = 1
    if not self:is_visible() then metric.hidden_doors = 1 end
    if not self:is_reachable() then metric.obstacle_doors = { [self.reach] = 1 } end
    if self.open == 'bigkey' then metric.bigkey_doors = 1 end
    return metric
end

function Treasure:get_node_metric()
    local metric = tree.Metric:new()
    metric.treasures = 1
    if not self:is_visible() then metric.hidden_treasures = 1 end
    if not self:is_reachable() then metric.obstacle_treasures = { [self.reach] = 1 } end
    if self.open == 'bigkey' then metric.bigkey_treasures = 1 end
    if self:is_normal() then metric.normal_treasures = 1 end
    return metric
end

function Enemy:get_node_metric()
    local metric = tree.Metric:new()
    return metric
end

function Room:get_children_metric()
    local metric = tree.Metric:new()
    self:each_child(function (key, child)
        metric = metric + child:get_node_metric()
    end)
    return metric
end

function Treasure:get_children_metric()
    local metric = tree.Metric:new()
    return metric
end

function Enemy:get_children_metric()
    local metric = tree.Metric:new()
    return metric
end

function tree.Metric:get_obstacles()
    local obstacles = {}
    for k, v in pairs(self.obstacle_doors) do
        obstacles[k] = v
    end
    for k, v in pairs(self.obstacle_treasures) do
        obstacles[k] = math.max(obstacles[k] or 0, v)
    end
    local total = 0
    for k, v in pairs(obstacles) do
        total = total + v
    end
    return total
end

function tree.Metric:get_obstacle_doors()
    local total = 0
    for k, v in pairs(self.obstacle_doors) do
        total = total + v
    end
    return total
end

function tree.Metric:get_obstacle_treasures()
    local total = 0
    for k, v in pairs(self.obstacle_treasures) do
        total = total + v
    end
    return total
end

function tree.Metric:get_obstacle_types()
    local result = 0
    for k, v in pairs(self.obstacle_doors) do
        result = result + 1
    end
    for k, v in pairs(self.obstacle_treasures) do
        if not self.obstacle_doors[k] then
            result = result + 1
        end
    end
    return result
end

function tree.Metric:__tostring()
    return string.format('D:%d (%d,%d,%d,%d) T:%d (%d,%d,%d,%d)',
    self.doors,     self.hidden_doors,     self:get_obstacle_doors(),     self.bigkey_doors,     self.directional_doors,
    self.treasures, self.hidden_treasures, self:get_obstacle_treasures(), self.bigkey_treasures, self.normal_treasures)
end

function tree.Metric:is_valid()
    if self.directional_doors > 1 then return false end
    if self:get_obstacle_types() > 1 then return false end

    if self.bigkey_doors > 0 and self.treasures > 0 then return false end
    if self.bigkey_doors > 0 and self.hidden_doors > 0 then return false end

    if self.treasures > 2 then return false end
    if self.normal_treasures > 1 then return false end
    if self.hidden_treasures > 1 then return false end
    if self.bigkey_treasures > 1 then return false end
    if self:get_obstacle_treasures() > 1 then return false end

    if self.hidden_treasures > 0 and self.bigkey_treasures > 0 then return false end

    if (self.bigkey_treasures > 0 or self.hidden_treasures > 0) and self:get_obstacles() > 0 then return false end
    if self.bigkey_treasures > 0 and self.normal_treasures > 0 then return false end

    return true
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


tree.Node=Node
tree.Room=Room
tree.Treasure=Treasure
tree.Enemy=Enemy
tree.PrintVisitor=PrintVisitor
return tree
