local map = ...

local Tree = require 'lib/tree'
local Puzzle = require 'lib/puzzle'
local Prng = require 'lib/prng'
local Layout = require 'lib/layout'

local master_prng = Prng.from_seed(13)
local layout = Layout.NorthWestwardVisitor

local puzzle = Puzzle.alpha_dungeon(master_prng:create(), 3, {'hookshot'})
--puzzle:accept(Tree.PrintVisitor:new{})

function map:render_map(map_menu)
    Layout.minimap_mixin(layout:new(), map_menu):render(puzzle)
end

local solarus_layout = Layout.solarus_mixin(layout:new(), map)
solarus_layout:render(puzzle)
--Layout.print_mixin(layout:new()):render(puzzle)


function map:on_started()
    solarus_layout:move_hero_to_start()
end
