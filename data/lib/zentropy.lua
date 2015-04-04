local Class = require 'lib/class'
local util = require 'lib/util'
local Prng = require 'lib/prng'
local Puzzle = require 'lib/puzzle'
local map_include = require 'lib/map_include'
local dialog_box = require 'menus/dialog_box'
local Pause = require 'menus/pause'


bit32 = bit32 or bit

zentropy = zentropy or {
    db = {
        Project = {},
        Components = Class:new{
            CORNER_SECTION_MASKS = {
                util.oct('000001'),
                util.oct('000004'),
                util.oct('000100'),
                util.oct('000400'),
            },
        },
        Tilesets = Class:new{},
    },
    game = {},
}

zentropy.db.Project.__index = zentropy.db.Project

function zentropy.init()
    entries = zentropy.db.Project:parse()
    zentropy.components = zentropy.db.Components:new():parse(entries.map)
    zentropy.tilesets = zentropy.db.Tilesets:new():parse(entries.tileset)

    zentropy.musics = {}
    for k, v in ipairs(entries.music) do
        local parts = string.gmatch(v.id, '[^_]+')
        local kind = parts()
        zentropy.musics[kind] = zentropy.musics[kind] or {}
        table.insert(zentropy.musics[kind], v)
    end
end

function zentropy.db.Project:parse()
    local entries = {}
    local filename = 'project_db.dat'
    local f = sol.main.load_file(filename)
    if not f then
        error("error: loading file: " .. filename)
    end

    local env = setmetatable({}, {__index=function(t, key)
        return function(properties)
            entries[key] = entries[key] or {}
            table.insert(entries[key], properties)
        end
    end})

    setfenv(f, env)()
    return entries
end

function zentropy.db.Components:new(o)
    o = o or {}
    o.floors = o.floors or {}
    o.obstacles = o.obstacles or {}
    o.treasures = o.treasures or {}
    o.doors = o.doors or {}
    o.enemies = o.enemies or {}
    o.fillers = o.fillers or {}
    o.enemies = o.enemies or {}
    o.puzzles = o.puzzles or {}
    return Class.new(self, o)
end

function zentropy.db.Components:floor(id, iterator)
    table.insert(self.floors, id)
    return true
end

function zentropy.db.Components:obstacle(id, iterator)
    local item = iterator()
    local dir = iterator()
    local mask_string = iterator()
    if mask_string == nil then return false end
    local mask = util.oct(mask_string)
    self.obstacles[item] = self.obstacles[item] or {}
    self.obstacles[item][dir] = self.obstacles[item][dir] or {}
    table.insert(self.obstacles[item][dir], {
        id=id,
        mask=mask,
    })
    return true
end

function zentropy.db.Components:treasure(id, iterator)
    local open = iterator()
    local mask_string = iterator()
    if mask_string == nil then return false end
    local mask
    if mask_string == 'any' then
        mask = mask_string
    else
        mask = util.oct(mask_string)
    end
    self.treasures[open] = self.treasures[open] or {}
    table.insert(self.treasures[open], {
        id=id,
        mask=mask,
    })
    return true
end

function zentropy.db.Components:puzzle(id, iterator)
    local mask_string = iterator()
    if mask_string == nil then return false end
    local mask
    mask = util.oct(mask_string)
    table.insert(self.puzzles, {
        id=id,
        mask=mask,
    })
    return true
end

function zentropy.db.Components:door(id, iterator)
    local open = iterator()
    local dir = iterator()
    local mask_string = iterator()
    if mask_string == nil then return false end
    local mask = util.oct(mask_string)
    self.doors[open] = self.doors[open] or {}
    self.doors[open][dir] = self.doors[open][dir] or {}
    table.insert(self.doors[open][dir], {
        id=id,
        mask=mask,
    })
    return true
end

function zentropy.db.Components:enemy(id, iterator)
    local mask_string = iterator()
    if mask_string == nil then return false end
    local mask
    if mask_string == 'any' then
        mask = mask_string
    else
        mask = util.oct(mask_string)
    end
    table.insert(self.enemies, {
        id=id,
        mask=mask,
    })
    return true
end

function zentropy.db.Components:filler(id, iterator)
    local mask_string = iterator()
    if mask_string == nil then return false end
    local mask
    if mask_string == 'any' then
        mask = mask_string
    else
        mask = util.oct(mask_string)
    end
    table.insert(self.fillers, {
        id=id,
        mask=mask,
    })
    return true
end

function zentropy.db.Components:enemy(id, iterator)
    local name = iterator()
    local mask_string = iterator()
    if mask_string == nil then return false end
    local mask = util.oct(mask_string)
    self.enemies[name] = self.enemies[name] or {}
    table.insert(self.enemies[name], {
        id=id,
        mask=mask,
    })
    return true
end

function zentropy.db.Components:parse(maps)
    maps = maps or zentropy.db.Project:parse().map

    for k, v in util.pairs_by_keys(maps) do
        if string.sub(v.id, 0, 11) == 'components/' then
            local parts = string.gmatch(string.gsub(v.id, '.*/', ''), '[^_]+')
            local part = parts()
            if not self[part] then
                print('ignoring component: ', v.id)
            elseif not self[part](self, v.id, parts) then
                print('ignoring component: ', v.id)
            end
        end
    end

    return self
end

function zentropy.db.Components:get_door(open, dir, mask, rng)
    open = open or 'open'
    if not self.doors[open] then
        return
    end
    if not self.doors[open][dir] then
        return
    end
    local entries = {}
    for _, entry in util.pairs_by_keys(self.doors[open][dir]) do
        if bit32.band(mask, entry.mask) == 0 then
            table.insert(entries, entry)
        end
    end
    if #entries == 0 then
        return
    end
    local entry = entries[rng:random(#entries)]
    return entry.id, entry.mask
end

function zentropy.db.Components:get_obstacle(item, dir, mask, rng)
    open = open or 'open'
    if not self.obstacles[item] then
        return
    end
    if not self.obstacles[item][dir] then
        return
    end
    local entries = {}
    for _, entry in util.pairs_by_keys(self.obstacles[item][dir]) do
        if bit32.band(mask, entry.mask) == 0 then
            table.insert(entries, entry)
        end
    end
    if #entries == 0 then
        return
    end
    local entry = entries[rng:random(#entries)]
    return entry.id, entry.mask
end

function zentropy.db.Components:get_filler(mask, rng)
    local entries = {}
    for _, entry in util.pairs_by_keys(self.fillers) do
        if bit32.band(mask, entry.mask) == 0 then
            table.insert(entries, entry)
        end
    end
    for _, entry in util.pairs_by_keys(self.puzzles) do
        if bit32.band(mask, entry.mask) == 0 then
            table.insert(entries, entry)
        end
    end
    if #entries == 0 then
        return
    end
    local entry = entries[rng:random(#entries)]
    return entry.id, entry.mask
end

function zentropy.db.Components:get_treasure(open, mask, rng)
    open = open or 'open'
    if not self.treasures[open] then
        return
    end
    local entries = {}
    for _, entry in util.pairs_by_keys(self.treasures[open]) do
        if entry.mask == 'any' then
            for _, section in ipairs(self.CORNER_SECTION_MASKS) do
                if bit32.band(mask, section) == 0 then
                    table.insert(entries, {mask=section, id=entry.id})
                end
            end
        elseif bit32.band(mask, entry.mask) == 0 then
            table.insert(entries, entry)
        end
    end
    if #entries == 0 then
        return
    end
    local entry = entries[rng:random(#entries)]
    return entry.id, entry.mask
end

function zentropy.db.Components:get_puzzle(mask, rng)
    local entries = {}
    for _, entry in util.pairs_by_keys(self.puzzles) do
        table.insert(entries, entry)
    end
    if #entries == 0 then
        return
    end
    local entry = entries[rng:random(#entries)]
    return entry.id, entry.mask
end

function zentropy.db.Components:get_floors(rng)
    local i = rng:random(#self.floors)
    local j = rng:random(#self.floors - 1)
    if j >= i then
        j = j + 1
    end
    return self.floors[i], self.floors[j]
end

function zentropy.db.Components:get_enemy(name, mask, rng)
    if not self.enemies[name] then
        return
    end
    local entries = {}
    for _, entry in util.pairs_by_keys(self.enemies[name]) do
        if bit32.band(mask, entry.mask) == 0 then
            table.insert(entries, entry)
        end
    end
    if #entries == 0 then
        return
    end
    local entry = entries[rng:random(#entries)]
    return entry.id, entry.mask
end

function zentropy.db.Tilesets:new(o)
    o = o or {}
    o.dungeon = o.dungeon or {}
    return Class.new(self, o)
end

function zentropy.db.Tilesets:parse(tilesets)
    tilesets = tilesets or zentropy.db.Project:parse().tileset

    for k, v in util.pairs_by_keys(tilesets) do
        local parts = string.gmatch(v.id, '[^_]+')
        local part = parts()
        if self[part] then
            table.insert(self[part], v.id)
        else
            print('ignoring tileset: ', v.id)
        end
    end

    return self
end

zentropy.Room = Class:new()

function zentropy.Room:new(o)
    assert(o.rng)
    assert(o.map)
    o.component_rng = o.component_rng or o.rng:create()
    o.puzzle_rng = o.puzzle_rng or o.rng:create()
    o.treasure_rng = o.treasure_rng or o.rng:create()
    o.mask = o.mask or 0
    o.open_doors = o.open_doors or {}
    o.data_messages = o.data_messages or function () end
    return Class.new(self, o)
end

function zentropy.Room:door(data, dir)
    if not data then return end
    local component_name, component_mask = zentropy.components:get_door(data.open, dir, self.mask, self.component_rng)
    if not component_name then
        self.data_messages('error', string.format("door not found: open=%s dir=%s mask=%06o", data.open, dir, self.mask))
        return false
    end
    self.mask = bit32.bor(self.mask, component_mask)
    data.rewrite = {}
    function data.rewrite.door(properties)
        properties.savegame_variable = data.name
        return properties
    end
    self.map:include(0, 0, component_name, data)
    self.data_messages('component', component_name)
    return true
end

function zentropy.Room:obstacle(data, dir, item)
    if not data then return end
    local component_name, component_mask = zentropy.components:get_obstacle(item, dir, self.mask, self.component_rng)
    if not component_name then
        self.data_messages('error', string.format("obstacle not found: item=%s dir=%s mask=%06o", item, dir, self.mask))
        return false
    end
    self.mask = bit32.bor(self.mask, component_mask)

    if data.treasure2 then
        if self:treasure(data.treasure2) then
            data.treasure2 = nil
        end
    end
    self.map:include(0, 0, component_name, data)
    self.data_messages('component', component_name)
    return true
end

function zentropy.Room:filler()
    local filler_data = {
        rng=self.puzzle_rng,
    }
    local component_name, component_mask = zentropy.components:get_filler(self.mask, self.component_rng)
    if component_name then
        self.mask = bit32.bor(self.mask, component_mask)
        if self.puzzle_rng:random() < 0.5 then
            filler_data.doors = self.open_doors
            self.open_doors = {}
        else
            filler_data.doors = {}
        end
        self.map:include(0, 0, component_name, filler_data)
        self.data_messages('component', component_name)
        return true
    end
    return false
end

function zentropy.Room:treasure(treasure_data)
    local component_name, component_mask
    local component_type
    if treasure_data.see then
        component_name, component_mask = zentropy.components:get_puzzle(self.mask, self.component_rng)
        component_type = 'puzzle'
        treasure_data.doors = {}
        treasure_data.rng = self.puzzle_rng
    else
        component_name, component_mask = zentropy.components:get_treasure(treasure_data.open, self.mask, self.component_rng)
        component_type = 'treasure'
    end
    self.open_doors = {}
    if not component_name then
        self.data_messages('error', string.format("%s not found: open=%s mask=%06o", component_type, treasure_data.open, self.mask))
        return false
    end
    self.mask = bit32.bor(self.mask, component_mask)

    treasure_data.section = component_mask
    treasure_data.rewrite = {}
    function treasure_data.rewrite.chest(properties)
        properties.treasure_savegame_variable = treasure_data.name
        properties.treasure_name = treasure_data.item_name
        return properties
    end
    treasure_data.rng = self.treasure_rng:biased(component_mask)
    self.map:include(0, 0, component_name, treasure_data)
    self.data_messages('component', component_name)
    return true
end

function zentropy.Room:enemy(data)
    local component_name, component_mask = zentropy.components:get_enemy(data.name, self.mask, self.component_rng)
    self.map:include(0, 0, component_name, data)
    self.mask = bit32.bor(self.mask, component_mask)
    return true
end

function zentropy.Room:sign(data)
    for _, section_string in ipairs{'400', '200', '100', '040', '020', '010', '004', '002', '001'} do
        local section = util.oct(section_string)
        if bit32.band(self.mask, section) == 0 then
            local component_name = string.format('components/sign')
            data.section = section
            self.map:include(0, 0, component_name, data)
            self.data_messages('component', component_name)
            self.mask = bit32.bor(self.mask, section)
            return true
        end
    end
    for _, msg in ipairs(messages) do print(msg) end
    self.data_messages('error', 'cannot fit sign')
    return true
end

function zentropy.game.get_items_sequence(rng)
    local d = Puzzle.Dependencies:new()
    d:single('bow_1', {item_name='bow'})
    d:single('lamp_1', {item_name='lamp'})
    d:single('hookshot_1', {item_name='hookshot'})
    d:single('bomb_1', {item_name='bomb'})
    local items = Puzzle.sequence(rng, d.result)
    local i = 1
    local brought_items = {}
    local result = {}
    for _, item in ipairs(items) do
        table.insert(result, item.step.item_name)
    end
    return result
end

function zentropy.game.get_items()
    local items = {}
    for _, item_name in ipairs{'bow','bomb','hookshot','lamp'} do
        items[item_name] = zentropy.game.game:get_item(item_name):get_variant()
    end
    return items
end

function zentropy.game.set_items(items)
    for item_name, variant in pairs(items) do
        zentropy.game.game:get_item(item_name):set_variant(variant)
    end
end

function zentropy.game.new_game(filename)
    zentropy.game.filename = filename

    local old_game = sol.game.load(filename)
    local overrides = {}
    for _, name in pairs{'override_seed', 'override_tier', 'override_tileset', 'override_keys', 'override_fairies', 'override_culdesacs'} do
        overrides[name] = old_game:get_value(name)
    end
    sol.game.delete(zentropy.game.filename)
    zentropy.game.game = zentropy.game.init(sol.game.load(filename))
    local game = zentropy.game.game
    zentropy.game.game = game
    for name, value in pairs(overrides) do
        game:set_value(name, value)
    end
    game:save()

    local seed = game:get_value('override_seed') or math.random(32768 * 65536 - 1)
    local last_tier = (game:get_value('override_tier') or 1) - 1
    local rng = Prng.from_seed(seed, 1)
    game:set_value('seed', seed)
    game:set_value('tier', 0)
    game:set_ability('sword', 1)
    game:set_max_life(12)
    game:set_life(12)
    zentropy.game.items = zentropy.game.get_items_sequence(rng)
    for i = 1, last_tier do
        local item_name = table.remove(zentropy.game.items, 1)
        if item_name then
            local item = game:get_item(item_name)
            item:set_variant(1)
            item:on_obtained()
        end
    end
    game:set_value('tier', last_tier)
    return game
end

function zentropy.game.next_tier()
    local game = zentropy.game.game
    local tier = game:get_value('tier') + 1

    local luafile = zentropy.game.filename
    game:save()
    local luaf = sol.main.load_file(luafile)
    sol.game.delete(zentropy.game.filename)
    if not luaf then
        error("error: loading file: " .. luafile)
    end
    local luaenv = setmetatable({}, {__newindex=function (table, key, value)
        if string.sub(key, 1, 5) == 'room_' then
            game:set_value(key, nil)
        end
    end})
    setfenv(luaf, luaenv)(map, data)

    game:set_value('tier', tier)
    local treasure_item = table.remove(zentropy.game.items, 1)
    game:set_value('treasure_item', treasure_item)
    game:set_value('small_key_amount', 0)
    game:set_value(game:get_item('bigkey'):get_savegame_variable(), nil)
    game:set_value(game:get_item('map'):get_savegame_variable(), nil)
    game:set_value(game:get_item('compass'):get_savegame_variable(), nil)

    game:save()

    return game
end

function zentropy.game.init(game)
    sol.main.load_file("hud/hud")(game)

    game:set_starting_location('dungeons/dungeon1')

    game.dialog_box = dialog_box:new{game=game}

    local pause = Pause:new{game=game}

    function game:on_command_pressed(command)
        if command == 'pause' and game:is_paused() then
            game:save()
            print("saved")
        end
    end

    function game:on_paused()
        pause:start_pause_menu()
        self:hud_on_paused()
    end

    function game:on_unpaused()
        pause:stop_pause_menu()
        self:hud_on_unpaused()
    end

    function game:on_started()
        game:get_hero():set_walking_speed(160)
        self.dialog_box:initialize_dialog_box()
        self:initialize_hud()
    end

    -- Called by the engine when a dialog starts.
    function game:on_dialog_started(dialog, info)

        self.dialog_box.dialog = dialog
        self.dialog_box.info = info
        sol.menu.start(self, self.dialog_box)
    end

    -- Called by the engine when a dialog finishes.
    function game:on_dialog_finished(dialog)

        sol.menu.stop(self.dialog_box)
        self.dialog_box.dialog = nil
        self.dialog_box.info = nil
    end

    function game:on_game_over_finished()
        sol.main.reset()
    end

    function game:on_finished()
        self:quit_hud()
        self.dialog_box:quit_dialog_box()
    end

    function game:on_map_changed(map)
        self:hud_on_map_changed(map)
    end

    return game
end

return zentropy
