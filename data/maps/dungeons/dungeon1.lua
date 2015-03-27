local map = ...

local Tree = require 'lib/tree'
local Puzzle = require 'lib/puzzle'
local Prng = require 'lib/prng'
local Layout = require 'lib/layout'
local zentropy = require 'lib/zentropy'

local master_prng = Prng.from_seed(57)
local layout = Layout.NorthEastwardVisitor

local puzzle_rng = master_prng:create()
local layout_rng = master_prng:create()
local presentation_rng = master_prng:create()

local on_started_handlers = {}

function map:add_on_started(f)
    table.insert(on_started_handlers, f)
end

function map:on_started()
    for _, f in ipairs(on_started_handlers) do
        f()
    end
end

local puzzle = Puzzle.alpha_dungeon(puzzle_rng, 3, {'hookshot'})
--puzzle:accept(Tree.PrintVisitor:new{})

local tileset = zentropy.tilesets.dungeon[presentation_rng:random(#zentropy.tilesets.dungeon)]
local floor1, floor2 = zentropy.components:get_floors(presentation_rng)

map:set_tileset(tileset)

local solarus_layout = Layout.solarus_mixin(layout:new{rng=layout_rng}, map, {floor1, floor2})
solarus_layout:render(puzzle)
--Layout.print_mixin(layout:new()):render(puzzle)


function map:render_map(map_menu)
    Layout.minimap_mixin(layout:new{ game=map:get_game() }, map_menu):render(puzzle)
end

map:add_on_started(function ()
    solarus_layout:move_hero_to_start()
end)
