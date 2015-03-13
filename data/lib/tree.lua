local Class = require 'lib/class.lua'

local function weighted_random_element(array, w)
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

local counters = {}
local function new_id(prefix)
    counters[prefix] = (counters[prefix] or 0) + 1
    return prefix .. counters[prefix]
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

return {
    Node=Node,
    Room=Room,
    Treasure=Treasure,
    Enemy=Enemy,
    PrintVisitor=PrintVisitor,
}
