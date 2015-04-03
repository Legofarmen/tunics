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

local master_prng = Prng.from_seed(seed, tier)
local dungeon_rng = master_prng:create()
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
    'bow',
    'hookshot',
    'lamp',
}
local brought_items = {}
local big_treasure = nil
local n = 1
for i, item_name in ipairs(all_items) do
    local item = game:get_item(item_name)
    if item:get_variant() >= 1 then
        table.insert(brought_items, item_name)
    else
        if dungeon_rng:random(n) == 1 then
            big_treasure = item_name
        end
        n = n + 1
    end
end

local puzzle = Puzzle.alpha_dungeon(puzzle_rng, nkeys, nfairies, nculdesacs, { big_treasure }, brought_items)
--puzzle:accept(Tree.PrintVisitor:new{})

local floor1, floor2 = zentropy.components:get_floors(presentation_rng)

map:set_tileset(tileset_override or zentropy.tilesets.dungeon[presentation_rng:random(#zentropy.tilesets.dungeon)])

local music = zentropy.musics.dungeon[presentation_rng:random(#zentropy.musics.dungeon)].id
sol.audio.play_music(music)

local solarus_layout = Layout.solarus_mixin(layout:new{rng=layout_rng}, map, {floor1, floor2})
solarus_layout:render(puzzle)
--Layout.print_mixin(layout:new()):render(puzzle)


function map:render_map(map_menu)
    Layout.minimap_mixin(layout:new{ game=game }, map_menu):render(puzzle)
end

map:add_on_started(function ()
    solarus_layout:move_hero_to_start()
end)
