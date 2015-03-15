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

Layout.solarus_mixin(layout:new(), map):render(puzzle)
--Layout.print_mixin(layout:new()):render(puzzle)


function map:on_started()
    local hero = map:get_hero()
    map:get_hero():set_direction(1)
    map:get_hero():set_position(3200 - 320 / 2, 240 * 10 - 8, 1)
end
