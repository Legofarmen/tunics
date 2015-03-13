local Tree = require 'lib/tree.lua'
local TreeBuilder = require 'lib/treebuilder.lua'
local List = require 'lib/list.lua'

local Puzzle = {}

function Puzzle.max_heads(n)
    return function (root)
        while #root.children > n do
            local fork = Tree.Room:new()
            fork:merge_child(root:remove_child(root:random_child()))
            fork:merge_child(root:remove_child(root:random_child()))
            root:add_child(fork)
        end
    end
end

function Puzzle.compass_puzzle()
    return {
        TreeBuilder.hide_treasures,
        TreeBuilder.add_treasure('compass'),
    }
end

function Puzzle.map_puzzle()
    local steps = {
        TreeBuilder.add_treasure('bomb'),
        TreeBuilder.add_treasure('map'),
    }
    List.shuffle(steps)
    table.insert(steps, 1, TreeBuilder.bomb_doors)
    return steps
end

function Puzzle.items_puzzle(item_names)
    List.shuffle(item_names)
    local steps = {}
    for _, item_name in ipairs(item_names) do
        table.insert(steps, TreeBuilder.hard_to_reach(item_name))
        table.insert(steps, TreeBuilder.add_big_chest(item_name))
    end
    table.insert(steps, TreeBuilder.add_treasure('big_key'))
    return steps
end

function Puzzle.lock_puzzle()
    return {
        function (root)
            if TreeBuilder.locked_door(root) then
                TreeBuilder.add_treasure('small_key')(root)
            end
        end,
    }
end

return Puzzle
