local Tree = require 'lib/tree.lua'

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
    local total_keys
    if room.open == 'small_key' then
        total_keys = -1
    else
        total_keys = 0
    end
    room:each_child(function (key, child)
        if (not child.open or child.open == 'nothing') and (not child.reach or child.reach == 'nothing') and (not child.see or child.see == 'nothing') then
            total_keys = total_keys + child:accept(self)
        end
    end)
    return total_keys
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

local TreeBuilder = {}

function TreeBuilder.add_treasure(item_name)
    return function (root)
        root:add_child(Tree.Treasure:new{name=item_name})
    end
end

function TreeBuilder.add_boss(root)
    root:add_child(Tree.Enemy:new{name='boss'}:with_needs{open='big_key'})
end

function TreeBuilder.hide_treasures(root)
    root:accept(HideTreasuresVisitor)
end

function TreeBuilder.hard_to_reach(item_name)
    return function (root)
        root:each_child(function (key, head)
            root:update_child(key, head:with_needs{reach=item_name})
        end)
    end
end

function TreeBuilder.add_big_chest(item_name)
    return function (root)
        root:add_child(Tree.Treasure:new{name=item_name, open='big_key'})
    end
end

function TreeBuilder.bomb_doors(root)
    root:each_child(function (key, head)
        root:update_child(key, head:with_needs{see='map',open='bomb'})
    end)
end

function TreeBuilder.locked_door(root)
    function lockable_weight(node)
        if node.class == 'Room' then
            local keys = node:accept(TreasureCountVisitor)
            if keys > 1 then
                return keys
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

return TreeBuilder
