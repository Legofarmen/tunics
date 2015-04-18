local Class = require 'lib/class'
local util = require 'lib/util'
local Prng = require 'lib/prng'
local Quest = require 'lib/quest'
local map_include = require 'lib/map_include'
local dialog_box = require 'menus/dialog_box'
local Pause = require 'menus/pause'
local game_over_menu = require 'menus/game_over'

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
        Enemies = Class:new{},
    },
    game = {
        savefile = 'save.dat',
    },
    settings = {
        filename = 'settings.dat',
        defaults = {
            debug_filename = 'wdebug.txt',
            quest_sword_ability = 1,
            quest_seed = os.time(),
            quest_tier = 1,
            tier_keys = 3,
            tier_fairies = 1,
            tier_culdesacs = 3,
        },
    },
}

zentropy.db.Project.__index = zentropy.db.Project

local settings_meta = {}

function settings_meta:__index(key)
    return sol.game.load(self.filename):get_value(key) or self.defaults[key]
end

setmetatable(zentropy.settings, settings_meta)

function zentropy.init()

    io.open(zentropy.settings.debug_filename, "w"):close()

    entries = zentropy.db.Project:parse()
    zentropy.components = zentropy.db.Components:new():parse(entries.map)
    zentropy.tilesets = zentropy.db.Tilesets:new():parse(entries.tileset)
    zentropy.enemies = zentropy.db.Enemies:new():parse(entries.enemy)

    zentropy.musics = {}
    for k, v in ipairs(entries.music) do
        local parts = string.gmatch(v.id, '[^_]+')
        local kind = parts()
        zentropy.musics[kind] = zentropy.musics[kind] or {}
        table.insert(zentropy.musics[kind], v)
    end
end

function zentropy.debug(...)
    local filename = zentropy.settings.debug_filename
    if filename == '-' then
        print(...)
    else
        local args = { n = select("#", ...), ... }
        local message = ''
        local sep = ''
        for i = 1, args.n do
            message = message .. sep .. tostring(args[i])
            sep = "\t"
        end
        local f = io.open(filename, "a")
        f:write(message .. "\n")
        f:close()
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
                zentropy.debug('ignoring component: ', v.id)
            elseif not self[part](self, v.id, parts) then
                zentropy.debug('ignoring component: ', v.id)
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
    if not self.obstacles[item] then
        return
    end
    local dir_bits = 0
    local door_mask = 0
    if string.gmatch(dir, 'north')() then
        dir_bits = bit32.bor(dir_bits, 8)
        door_mask = bit32.bor(door_mask, util.oct('200000'));
    end
    if string.gmatch(dir, 'south')() then
        dir_bits = bit32.bor(dir_bits, 4)
        door_mask = bit32.bor(door_mask, util.oct('040000'));
    end
    if string.gmatch(dir, 'east')() then
        dir_bits = bit32.bor(dir_bits, 2)
        door_mask = bit32.bor(door_mask, util.oct('010000'));
    end
    if string.gmatch(dir, 'west')() then
        dir_bits = bit32.bor(dir_bits, 1)
        door_mask = bit32.bor(door_mask, util.oct('002000'));
    end
    local doors = {}
    for i = 0, 15 do
        local d = ''
        local new_bits = bit32.bor(dir_bits, i)
        if bit32.band(new_bits, 8) ~= 0 then d = d .. 'north' end
        if bit32.band(new_bits, 4) ~= 0 then d = d .. 'south' end
        if bit32.band(new_bits, 2) ~= 0 then d = d .. 'east' end
        if bit32.band(new_bits, 1) ~= 0 then d = d .. 'west' end
        doors[d] = true
    end

    local entries = {}
    for d in util.pairs_by_keys(doors) do
        for _, entry in util.pairs_by_keys(self.obstacles[item][d] or {}) do
            if bit32.band(mask, entry.mask) == 0 then
                table.insert(entries, entry)
            end
        end
    end
    if #entries == 0 then
        return
    end
    local entry = entries[rng:random(#entries)]
    return entry.id, bit32.bor(entry.mask, door_mask)
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

function zentropy.db.Components:get_floors(rng)
    local i = rng:refine('first'):random(#self.floors)
    local j = rng:refine('second'):random(#self.floors - 1)
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

function zentropy.db.Enemies:parse(enemies)
    enemies = enemies or zentropy.db.Project:parse().enemy

    for k, v in util.pairs_by_keys(enemies) do
        table.insert(self, v.id)
    end

    return self
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
            zentropy.debug('ignoring tileset: ', v.id)
        end
    end

    return self
end

zentropy.Room = Class:new()

function zentropy.Room:new(o)
    assert(o.rng)
    assert(o.map)
    o.mask = o.mask or 0
    o.open_doors = o.open_doors or {}
    o.data_messages = o.data_messages or function () end
    return Class.new(self, o)
end

function zentropy.Room:door(data, dir)
    if not data then return end
    local component_name, component_mask = zentropy.components:get_door(data.open, dir, self.mask, self.rng:refine('door_' .. dir))
    if not component_name then
        self.data_messages('error', string.format("door not found: open=%s dir=%s mask=%06o", data.open, dir, self.mask))
        return false
    end
    self.map:include(0, 0, component_name, data)
    self.mask = bit32.bor(self.mask, component_mask)
    self.data_messages('component', component_name)
    return true
end

function zentropy.Room:obstacle(data, dir, item)
    if not data then return end
    local component_name, component_mask = zentropy.components:get_obstacle(item, dir, self.mask, self.rng:refine('obstacle_' .. dir))
    if not component_name then
        self.data_messages('error', string.format("obstacle not found: item=%s dir=%s mask=%06o", item, dir, self.mask))
        return false
    end
    if data.treasure2 then
        if self:treasure(data.treasure2) then
            data.treasure2 = nil
        end
    end
    self.map:include(0, 0, component_name, data)
    self.mask = bit32.bor(self.mask, component_mask)
    self.data_messages('component', component_name)
    return true
end

function zentropy.Room:filler()
    self.filler_count = (self.filler_count or 0) + 1
    local rng = self.rng:refine('filler_' .. self.filler_count)
    local filler_data = {
        rng=rng:refine('component'),
    }
    local component_name, component_mask = zentropy.components:get_filler(self.mask, rng)
    if component_name then
        if rng:refine('puzzle'):random() < 0.5 then
            filler_data.doors = self.open_doors
            self.open_doors = {}
        else
            filler_data.doors = {}
        end
        self.map:include(0, 0, component_name, filler_data)
        self.mask = bit32.bor(self.mask, component_mask)
        self.data_messages('component', component_name)
        return true
    end
    return false
end

function zentropy.Room:treasure(treasure_data)
    local rng = self.rng:refine('treasure')
    local component_name, component_mask
    local component_type
    if treasure_data.see then
        component_name, component_mask = zentropy.components:get_puzzle(self.mask, rng)
        component_type = 'puzzle'
        treasure_data = {
            treasure1 = treasure_data,
            doors = {},
            rng = self.puzzle_rng,
        }
        util.table_lines('treasure_data', treasure_data)
        util.table_lines('component_name', component_name)
    else
        component_name, component_mask = zentropy.components:get_treasure(treasure_data.open, self.mask, rng)
        component_type = 'treasure'
    end
    self.open_doors = {}
    if not component_name then
        self.data_messages('error', string.format("%s not found: open=%s mask=%06o", component_type, treasure_data.open, self.mask))
        return false
    end
    treasure_data.section = component_mask
    treasure_data.rng = rng:refine('component')
    self.map:include(0, 0, component_name, treasure_data)
    self.mask = bit32.bor(self.mask, component_mask)
    self.data_messages('component', component_name)
    return true
end

function zentropy.Room:enemy(data)
    local component_name, component_mask = zentropy.components:get_enemy(data.name, self.mask, self.rng:refine('enemy'))
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
            self.mask = bit32.bor(self.mask, section)
            self.data_messages('component', component_name)
            return true
        end
    end
    for _, msg in ipairs(messages) do zentropy.debug(msg) end
    self.data_messages('error', 'cannot fit sign')
    return true
end

function zentropy.game.get_items_sequence(rng)
    local d = Quest.Dependencies:new()
    d:single('bow_1', {item_name='bow'})
    d:single('lamp_1', {item_name='lamp'})
    d:single('hookshot_1', {item_name='hookshot'})
    d:single('bomb_1', {item_name='bombs_counter'})
    d:single('flippers_1', {item_name='flippers'})
    local items = Quest.sequence(rng, d.result)
    local i = 1
    local brought_items = {}
    local result = {}
    for _, item in ipairs(items) do
        table.insert(result, item.step.item_name)
    end
    return result
end

function zentropy.game.has_savegame()
    return sol.game.exists(zentropy.game.savefile)
end

function zentropy.game.resume_game()
    zentropy.game.game = zentropy.game.init(sol.game.load(zentropy.game.savefile))
    zentropy.game.setup_quest_invariants()

    zentropy.game.game:set_starting_location('dungeons/dungeon1')
    zentropy.game.game:start()
    sol.game.delete(zentropy.game.savefile)
end

function zentropy.game.new_game()
    sol.game.delete(zentropy.game.savefile)

    zentropy.game.game = zentropy.game.init(sol.game.load(zentropy.game.savefile))
    zentropy.game.game:set_value('seed', zentropy.settings.quest_seed)
    zentropy.game.setup_quest_initial()
    zentropy.game.setup_quest_invariants()

    local tier = zentropy.settings.quest_tier
    zentropy.game.catch_up_on_items(tier)
    zentropy.game.setup_tier_initial(tier)

    if zentropy.settings.skip_cinematics then 
		zentropy.game.game:set_starting_location('dungeons/dungeon1')
	else
		zentropy.game.game:set_starting_location('rooms/intro_1')
    end
	zentropy.game.game:start()
end

function zentropy.game.next_tier()
    return zentropy.game.setup_tier_initial(zentropy.game.game:get_value('tier') + 1)
end

function zentropy.game.get_rng(tier)
    local master_rng = Prng:new{ path=zentropy.game.game:get_value('seed') }
    if tier then
        return master_rng:refine('tiers'):refine(tier)
    else
        return master_rng:refine('quest')
    end
end

function zentropy.game.setup_quest_invariants()
    zentropy.game.items = zentropy.game.get_items_sequence(zentropy.game.get_rng())
end

function zentropy.game.setup_quest_initial()
    zentropy.game.game:set_ability('sword', zentropy.settings.quest_sword_ability)
    zentropy.game.game:set_max_life(12)
    zentropy.game.game:set_life(12)
end

function zentropy.game.catch_up_on_items(tier)
    for i = 1, tier - 1 do
        local item_name = zentropy.game.get_tier_treasure(i)
        if item_name then
            local item = zentropy.game.game:get_item(item_name)
            item:set_variant(1)
            if item.on_obtained then
                item:on_obtained()
            end
        end
    end
end

function zentropy.game.setup_tier_initial(tier)
    local game = zentropy.game.game

    -- reset dungeon items
    game:set_value('small_key_amount', 0)
    game:set_value(game:get_item('bigkey'):get_savegame_variable(), nil)
    game:set_value(game:get_item('map'):get_savegame_variable(), nil)
    game:set_value(game:get_item('compass'):get_savegame_variable(), nil)

    -- reset all state related to rooms, doors and treasures
    local luafile = zentropy.game.savefile
    game:save()
    local luaf = sol.main.load_file(luafile)
    sol.game.delete(zentropy.game.savefile)
    if not luaf then
        error("error: loading file: " .. luafile)
    end
    local luaenv = setmetatable({}, {__newindex=function (table, key, value)
        if string.sub(key, 1, 5) == 'room_' then
            game:set_value(key, nil)
        end
    end})
    setfenv(luaf, luaenv)(map, data)

    -- increment tier
    game:set_value('tier', tier)

    return game
end

function zentropy.game.get_tier_treasure(tier)
    return zentropy.game.items[tier or zentropy.game.game:get_value('tier')]
end

function zentropy.game.init(game)
    sol.main.load_file("hud/hud")(game)

    game.dialog_box = dialog_box:new{game=game}

    local pause = Pause:new{game=game}

    function game:on_paused()
        pause:start_pause_menu()
        self:hud_on_paused()
    end

    function game:on_unpaused()
        pause:stop_pause_menu()
        self:hud_on_unpaused()
    end

    function game:on_started()
        if zentropy.settings.debug_walking_speed then
            game:get_hero():set_walking_speed(zentropy.settings.debug_walking_speed)
        end
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
	
	function game:on_game_over_started()
		sol.menu.start(zentropy.game.game:get_map(),game_over_menu)
	end
	
    function game:on_game_over_finished()
        --sol.main.reset()
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

local function get_random_treasure(rng)
    local treasures = {
        heart = { 3/4 }, fairy = { 1/4 },
        bomb = { 8/12, 3/12, 1/12 },
        arrow = { 10/16, 5/16, 1/16 },
        magic_flask = { 7/8, 1/8 },
    }
    local x = 4 * rng:random()
    for item_name, probabilities in pairs(treasures) do
        if zentropy.game.game:get_item(item_name):is_obtainable() then
            for variant, p in ipairs(probabilities) do
                x = x - p
                if x < 0 then
                    return item_name, variant
                end
            end
        else
            x = x - 1
        end
    end
    return nil, nil
end

function zentropy.inject_enemy(placeholder, rng)
    local map = placeholder:get_map()
    local x, y, layer = placeholder:get_position()
    local treasure_name, treasure_variant = get_random_treasure(rng:refine('drop'))
    local _, breed = rng:refine('breed'):ichoose(zentropy.enemies)
    local enemy = map:create_enemy{
        layer=layer,
        x=x,
        y=y,
        direction=3,
        breed=breed,
        treasure_name=treasure_name,
        treasure_variant=treasure_variant,
    }
    local origin_x, origin_y = enemy:get_origin()
    enemy:set_position(x + origin_x, y + origin_y)

    placeholder:remove()
    return enemy
end

function zentropy.inject_chest(placeholder, data)
    local map = placeholder:get_map()
    local x, y, layer = placeholder:get_position()
    local chest = map:create_chest{
        x=x,
        y=y,
        layer=layer,
        treasure_name=data.item_name,
        treasure_variant=data.variant,
        treasure_savegame_variable=data.name,
        sprite='entities/chest',
    }
    local origin_x, origin_y = chest:get_origin()
    chest:set_position(x + origin_x, y + origin_y)
    placeholder:remove()
    return chest
end

function zentropy.inject_big_chest(placeholder, data)
    local map = placeholder:get_map()
    local x, y, layer = placeholder:get_position()
    local chest = map:create_chest{
        x=x,
        y=y,
        layer=layer,
        treasure_name=data.item_name,
        treasure_variant=data.variant,
        treasure_savegame_variable=data.name,
        sprite='entities/big_chest',
        opening_method='interaction_if_savegame_variable',
        opening_condition='bigkey',
    }
    local origin_x, origin_y = chest:get_origin()
    chest:set_position(x + origin_x, y + origin_y)
    placeholder:remove()
    return chest
end

function zentropy.inject_door(position_tile, properties)
    assert(properties.direction)
    assert(properties.sprite)
    local map = position_tile:get_map()
    properties.x, properties.y, properties.layer = position_tile:get_position()
    properties.name = properties.name or 'door'
    return map:create_door(properties)
end

function zentropy.game.assign_item(item)
    local game = item:get_game()
    if not game:get_item_assigned(2) then
        game:set_item_assigned(2, item)
    elseif not game:get_item_assigned(1) then
        game:set_item_assigned(1, item)
    end
end

return zentropy
