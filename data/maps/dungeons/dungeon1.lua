local map = ...
local game = map:get_game()

local Tree = require 'lib/tree'
local Quest = require 'lib/quest'
local Prng = require 'lib/prng'
local Layout = require 'lib/layout'
local zentropy = require 'lib/zentropy'
local mappings = require 'lib/mappings'

local nkeys = zentropy.settings.tier_keys
local nfairies = zentropy.settings.tier_fairies
local nculdesacs = zentropy.settings.tier_culdesacs
local tileset_override = zentropy.settings.tier_tileset

local tier = game:get_value('tier')
local tier_prng = zentropy.game.get_rng(tier)
local puzzle_rng = tier_prng:refine('subquest')
local layout_rng = tier_prng:refine('layout')
local presentation_rng = tier_prng:refine('presentation')

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

local big_treasure = zentropy.game.get_tier_treasure()
local treasure_items
if big_treasure then
    treasure_items = { big_treasure }
else
    treasure_items = {}
end

local brought_items = {}
for i = 1, tier - 1 do
    local item = zentropy.game.get_tier_treasure(i)
    if item then
        table.insert(brought_items, item)
    end
end

local puzzle = Quest.alpha_dungeon(puzzle_rng, nkeys, nfairies, nculdesacs, treasure_items, brought_items)
--puzzle:accept(Tree.PrintVisitor:new{})

local floor1, floor2 = zentropy.components:get_floors(presentation_rng:refine('floors'))

local mapping = mappings.choose(tier, presentation_rng:refine('mappings'))
zentropy.Room.enemies = mapping.enemies
zentropy.Room.destructibles = mapping.destructibles

if tileset_override then
    map:set_tileset(tileset_override)
else
    local i, tileset = presentation_rng:refine('tileset'):ichoose(zentropy.tilesets.dungeon[mapping.family])
    map:set_tileset(tileset)
end


if not sol.audio.get_music() then 
	sol.audio.play_music(mapping.music)
end

local solarus_layout = Layout.solarus_mixin(layout:new{rng=layout_rng}, map, {floor1, floor2})
solarus_layout:render(puzzle)
--Layout.print_mixin(layout:new()):render(puzzle)


function map:render_map(map_menu)
    Layout.minimap_mixin(layout:new{ game=game }, map_menu):render(puzzle)
end

map:add_on_started(function ()
    solarus_layout:move_hero_to_start()

    if zentropy.settings.debug_flying then
        local width, height = map:get_size()
        map:create_dynamic_tile{
            layer = 2,
            x = 0,
            y = 0,
            width = width,
            height = height,
            pattern = "invisible_traversable",
            enabled_at_start = true,
        }
        local hero = map:get_hero()
        local x, y = hero:get_position()
        hero:set_position(x, y, 2)
        for entity in map:get_entities('') do
            if entity:get_type() == 'separator' then
                entity:remove()
            end
        end
    end
end)
