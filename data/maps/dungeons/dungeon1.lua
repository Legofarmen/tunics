local map = ...
local game = map:get_game()

local Tree = require 'lib/tree'
local Puzzle = require 'lib/puzzle'
local Prng = require 'lib/prng'
local Layout = require 'lib/layout'
local zentropy = require 'lib/zentropy'

local tier = game:get_value('tier')
local seed = game:get_value('seed')
local nkeys = game:get_value('override_keys') or 3
local nfairies = game:get_value('override_fairies') or 1
local nculdesacs = game:get_value('override_culdesacs') or 3
local tileset_override = game:get_value('override_tileset')
local treasure_override = game:get_value('override_treasure')

local master_prng = Prng.from_seed(tier, seed)
local game_prng = master_prng:create()
local puzzle_rng = master_prng:create()
local layout_rng = master_prng:create()
local presentation_rng = master_prng:create()

local layout = Layout.BidiVisitor

local on_started_handlers = {}

function map:add_on_started(f)
    table.insert(on_started_handlers, f)
end

function map:on_started()
    for _, f in ipairs(on_started_handlers) do
        f()
    end
end

local all_items = {
    'bomb',
    'hookshot',
    'lamp',
}
local big_treasure = treasure_override or all_items[game_prng:random(#all_items)]

local puzzle = Puzzle.alpha_dungeon(puzzle_rng, nkeys, nfairies, nculdesacs, { big_treasure })
--puzzle:accept(Tree.PrintVisitor:new{})

local floor1, floor2 = zentropy.components:get_floors(presentation_rng)

map:set_tileset(tileset_override or zentropy.tilesets.dungeon[presentation_rng:random(#zentropy.tilesets.dungeon)])

local solarus_layout = Layout.solarus_mixin(layout:new{rng=layout_rng}, map, {floor1, floor2})
solarus_layout:render(puzzle)
--Layout.print_mixin(layout:new()):render(puzzle)


function map:render_map(map_menu)
    Layout.minimap_mixin(layout:new{ game=game }, map_menu):render(puzzle)
end

map:add_on_started(function ()
    solarus_layout:move_hero_to_start()
end)
