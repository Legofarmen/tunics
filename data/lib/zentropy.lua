local Class = require 'lib/class'
local util = require 'lib/util'
local Prng = require 'lib/prng'
local Quest = require 'lib/quest'
local map_include = require 'lib/map_include'
local bindings = require 'lib/bindings'
local map_menu = require 'menus/map_menu'
local help_menu = require 'menus/help_menu'
local inventory_menu = require 'menus/inventory_menu'
local dialog_box = require 'menus/dialog_box'
local game_over_menu = require 'menus/game_over'
local Menu = require 'menus/menu'
local condition_manager = require 'lib/hero_condition'

bit32 = bit32 or bit

zentropy = zentropy or {
    version = "0.2",
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
    enemy_strategies = {},
    game = {
        savefile = 'save.dat',
    },
    settings = {
        filename = 'tunics.dat',
        defaults = {
            debug_filename = 'wdebug.txt',
            quest_sword_ability = 1,
            quest_seed = function () return os.time() end,
            quest_tier = 1,
        },
    },
}

zentropy.db.Project.__index = zentropy.db.Project

local settings_meta = {}

function settings_meta:__index(key)
    local value = sol.game.load(self.filename):get_value(key) or self.defaults[key]
    if type(value) == 'function' then
        return value()
    else
        return value
    end
end

setmetatable(zentropy.settings, settings_meta)

function zentropy.init()

    io.open(zentropy.settings.debug_filename, "w"):close()

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

function zentropy.debug(...)
    local args = { ... }
    zentropy.debug_callback(function (write)
        write(unpack(args))
    end)
end

function zentropy.debug_table(prefix, data)
    zentropy.debug_callback(function (write)
        util.table_lines(prefix, data, write)
    end)
end

function zentropy.debug_callback(callback)
    local filename = zentropy.settings.debug_filename
    if filename == '-' then
        callback(print)
    else
        local f = io.open(filename, "a")
        callback(function (...)
            local args = { n = select("#", ...), ... }
            local message = ''
            local sep = ''
            for i = 1, args.n do
                message = message .. sep .. tostring(args[i])
                sep = "\t"
            end
            f:write(message .. "\n")
        end)
        f:close()
    end
end

function zentropy.assert(v, message)
    if not v then
        error(debug.traceback(message or 'assertion failed!', 2))
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
    o.fillers = o.fillers or {}
    o.enemies = o.enemies or {}
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
    if not dir:find('^n?s?e?w?$') then return false end
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
    dir = string.sub(dir, 1, 1)
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

function zentropy.get_door_mask(dir)
    local door_mask = 0
    if dir:find('north') then door_mask = bit32.bor(door_mask, util.oct('200000')) end
    if dir:find('south') then door_mask = bit32.bor(door_mask, util.oct('002000')) end
    if dir:find('east') then door_mask = bit32.bor(door_mask, util.oct('010000')) end
    if dir:find('west') then door_mask = bit32.bor(door_mask, util.oct('040000')) end
    return door_mask
end

local function get_component_size(mask)
    local count = 0
    while mask > 0 do
        if bit32.band(mask, 1) ~= 0 then
            count = count + 1
        end
        mask = bit32.rshift(mask, 1)
    end
    return count
end

function zentropy.db.Components:get_obstacle(item, dir, mask, rng)
    if not self.obstacles[item] then
        return
    end

    local door_bits = 0
    if dir:find('north') then door_bits = door_bits + 8 end
    if dir:find('south') then door_bits = door_bits + 4 end
    if dir:find('east') then door_bits = door_bits + 2 end
    if dir:find('west') then door_bits = door_bits + 1 end

    local doors = {}
    for i = 0, 15 do
        local bits = bit32.bor(i, door_bits)
        local d = ''
        if bit32.band(bits, 8) ~= 0 then d = d .. 'n' end
        if bit32.band(bits, 4) ~= 0 then d = d .. 's' end
        if bit32.band(bits, 2) ~= 0 then d = d .. 'e' end
        if bit32.band(bits, 1) ~= 0 then d = d .. 'w' end
        doors[d] = true
    end

    local chosen = nil
    local seq = rng:seq()
    for d in util.pairs_by_keys(doors) do
        for _, entry in util.pairs_by_keys(self.obstacles[item][d] or {}) do
            if bit32.band(mask, entry.mask) == 0 and seq(get_component_size(entry.mask) ^ 1.5) then
                chosen = entry
            end
        end
    end
    if chosen then
        return chosen.id, bit32.bor(chosen.mask, zentropy.get_door_mask(dir))
    else
        return
    end
end

function zentropy.db.Components:get_filler(mask, rng)
    local chosen = nil
    local seq = rng:seq()
    for _, entry in util.pairs_by_keys(self.fillers) do
        if bit32.band(mask, entry.mask) == 0 and seq(get_component_size(entry.mask) ^ 1.5) then
            chosen = entry
        end
    end
    for _, obstacle_data in util.pairs_by_keys(self.obstacles.puzzle) do
        for dir, entry in pairs(obstacle_data) do
            if bit32.band(mask, entry.mask) == 0 and seq(get_component_size(entry.mask) ^ 1.5) then
                chosen = entry
            end
        end
    end
    if chosen then
        return chosen.id, chosen.mask
    else
        return
    end
end

function zentropy.db.Components:get_puzzle(mask, rng)
    local chosen = nil
    local seq = rng:seq()
    for _, entry in util.pairs_by_keys(self.obstacles.puzzle.northsoutheastwest) do
        if bit32.band(mask, entry.mask) == 0 and seq(get_component_size(entry.mask) ^ 1.5) then
            chosen = entry
        end
    end
    if chosen then
        return chosen.id, chosen.mask
    else
        return
    end
end

function zentropy.db.Components:get_treasure(open, mask, rng)
    open = open or 'open'
    if not self.treasures[open] then
        return
    end
    local chosen = nil
    local seq = rng:seq()
    for _, entry in util.pairs_by_keys(self.treasures[open]) do
        if entry.mask == 'any' then
            for _, section in ipairs(self.CORNER_SECTION_MASKS) do
                if bit32.band(mask, section) == 0 and seq() then
                    chosen = {mask=section, id=entry.id}
                end
            end
        elseif bit32.band(mask, entry.mask) == 0 and seq() then
            chosen = entry
        end
    end
    if chosen then
        return chosen.id, chosen.mask
    else
        return
    end
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

function zentropy.db.Tilesets:new(o)
    o = o or {}
    o.dungeon = o.dungeon or {}
    return Class.new(self, o)
end

function zentropy.db.Tilesets:parse(tilesets)
    tilesets = tilesets or zentropy.db.Project:parse().tileset

    for k, v in util.pairs_by_keys(tilesets) do
        local parts = string.gmatch(v.id, '[^_]+')
        local kind = parts()
        local family = parts()
        if self[kind] then
            self[kind][family] = self[kind][family] or {}
            table.insert(self[kind][family], v.id)
        else
            zentropy.debug('ignoring tileset: ', v.id)
        end
    end

    return self
end

zentropy.Room = Class:new()

function zentropy.Room:new(o)
    zentropy.assert(o.rng, 'property not found: o.rng')
    zentropy.assert(o.map, 'property not found: o.map')
    o.mask = o.mask or 0
    o.data_messages = o.data_messages or function () end
    return Class.new(self, o)
end

function zentropy.Room:door(data, dir)
    local include = self:delayed_door(data, dir)
    return include()
end

function zentropy.Room:hint_door(dir)
    self.mask = bit32.bor(self.mask, zentropy.get_door_mask(dir))
end

function zentropy.Room:delayed_door(data, dir)
    zentropy.assert(data.room_events)
    if not data then return end
    self.mask = bit32.band(self.mask, bit32.bnot(zentropy.get_door_mask(dir)))
    local component_name, component_mask = zentropy.components:get_door(data.open, dir, self.mask, self.rng:refine('door_' .. dir))
    if not component_name then
        self.data_messages('error', string.format("door not found: open=%s dir=%s mask=%06o", data.open, dir, self.mask))
        return
    end
    self.mask = bit32.bor(self.mask, component_mask)
    self.data_messages('component', component_name)
    data.rng = self.rng:refine('component')
    return function ()
        return self.map:include(0, 0, component_name, data)
    end
end

function zentropy.Room:obstacle(data, dir, item)
    zentropy.assert(data.room_events)
    if not data then return end
    local component_name, component_mask = zentropy.components:get_obstacle(item, dir, self.mask, self.rng:refine('obstacle_' .. dir))
    if not component_name then
        self.data_messages('error', string.format("obstacle not found: item=%s dir=%s mask=%06o", item, dir, self.mask))
        return false
    end
    local mask0 = self.mask
    local mask1 = bit32.bor(mask0, component_mask)
    self.mask = mask1  -- make sure the obstacle and separate treasure component don't overlap
    if data.treasure2 then
        if self:treasure(data.treasure2) then
            data.treasure2 = nil
        end
    end
    local mask2 = self.mask
    self.mask = mask0  -- make sure the obstacle can draw its doors
    self.map:include(0, 0, component_name, data)
    self.mask = bit32.bor(self.mask, mask2)  -- keep the bits from both obstacle and treasure components
    self.data_messages('component', component_name)
    return true
end

function zentropy.Room:filler(n)
    local rng = self.rng:refine('filler_' .. n)
    local component_name, component_mask = zentropy.components:get_filler(self.mask, rng)
    if component_name then
        local filler_data = {
            rng=rng:refine('component'),
            doors={},
            room=self,
        }
        self.map:include(0, 0, component_name, filler_data)
        self.mask = bit32.bor(self.mask, component_mask)
        self.data_messages('component', component_name)
        return true
    end
    return false
end

function zentropy.Room:trap(open_doors)
    local rng = self.rng:refine('trap')
    local component_name, component_mask = zentropy.components:get_puzzle(self.mask, rng)
    if component_name then
        local filler_data = {
            rng=rng:refine('component'),
            doors = open_doors,
            room = self,
        }
        self.map:include(0, 0, component_name, filler_data)
        self.mask = bit32.bor(self.mask, component_mask)
        self.data_messages('component', component_name)
        return true
    else
        return false
    end
end

function zentropy.Room:treasure(treasure_data)
    zentropy.assert(not treasure_data.see)
    local rng = self.rng:refine('treasure')
    local component_name, component_mask = zentropy.components:get_treasure(treasure_data.open, self.mask, rng)
    if not component_name then
        self.data_messages('error', string.format("treasure not found: open=%s mask=%06o", treasure_data.open, self.mask))
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
    zentropy.debug(util.ijoin("\n", data))
    self.data_messages('error', 'cannot fit sign')
    return true
end

function zentropy.game.get_tier()
    return zentropy.game.game:get_value('tier')
end

function zentropy.game.get_seed()
    return zentropy.game.game:get_value('seed')
end

function zentropy.game.get_items_sequence(rng)
    local d = Quest.Dependencies:new()
    d:single('bow_1', {item_name='bow'})
    d:single('lamp_1', {item_name='lamp'})
    d:single('hookshot_1', {item_name='hookshot'})
    d:single('bomb_1', {item_name='bombs_counter'})
    d:single('flippers_1', {item_name='flippers'})
    d:single('glove_1', {item_name='glove'})
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
    if sol.game.exists(zentropy.game.savefile) then
        local env = {}
        local luaf = sol.main.load_file(zentropy.game.savefile)
        local result = { pcall(setfenv(luaf, env)) }
        local success = table.remove(result, 1)
        if success then
            return env.tier
        else
            error("executing '" .. luafile .. "':\n" .. result[1])
        end
    else
        return false
    end
end

function zentropy.game.resume_game()
    zentropy.game.game = zentropy.game.init(sol.game.load(zentropy.game.savefile))
    zentropy.game.setup_quest_invariants()

    zentropy.game.game:set_starting_location('dungeons/dungeon1')
    zentropy.game.game:start()
    sol.game.delete(zentropy.game.savefile)
end

function zentropy.game.new_game(is_retry)
    sol.game.delete(zentropy.game.savefile)

    zentropy.game.game = zentropy.game.init(sol.game.load(zentropy.game.savefile))
    zentropy.game.game:set_value('seed', zentropy.settings.quest_seed)
    zentropy.game.setup_quest_initial()
    zentropy.game.setup_quest_invariants()

    local tier = zentropy.settings.quest_tier
    if type(tier) == 'string' then
        for i, item_name in ipairs(zentropy.game.items) do
            if tier == item_name then
                tier = i
                break
            end
        end
        if type(tier) == 'string' then
            error('unknown tier: ' .. tier)
        end
    end
    zentropy.game.catch_up_on_items(tier)
    zentropy.game.setup_tier_initial(tier)

    if zentropy.settings.debug_starting_location then
		zentropy.game.game:set_starting_location(zentropy.settings.debug_starting_location)
    elseif zentropy.settings.skip_cinematics then
		zentropy.game.game:set_starting_location('dungeons/dungeon1')
	elseif is_retry then
		zentropy.game.game:set_starting_location('rooms/intro_3', 'retry')
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

    local save_menu = Menu:new{entries = { 'Resume', 'Controls', 'Save & Exit' }}
    function save_menu:on_action(action)
        if action == 'Save & Exit' then
            sol.main.exit()
        elseif action == 'Controls' then
            help_menu:start(self, zentropy.game.game)
        else
            sol.menu.stop(save_menu)
        end
    end

    bindings.mixin(zentropy.game.game)
    bindings.mixin(map_menu)
    bindings.mixin(inventory_menu)
    bindings.mixin(save_menu)
    bindings.mixin(help_menu)

    local native = {
        pause = true,
        attack = true,
        item_1 = true,
        item_2 = true,
        action = true,
        up = true,
        down = true,
        left = true,
        right = true,
    }

    local handling = false
    function zentropy.game.game:on_command_pressed(command)
        if self:get_map():get_id():find('^dungeons/') then
            if command == 'map' then
                if sol.menu.is_started(map_menu) then
                    sol.menu.stop(map_menu)
                else
                    for i, menu in ipairs{map_menu, inventory_menu, save_menu} do
                        sol.menu.stop(menu)
                    end
                    zentropy.game.game:set_paused(true)
                    map_menu:start(zentropy.game.game, function ()
                        zentropy.game.game:set_paused(false)
                    end)
                end
                return true
            elseif command == 'inventory' then
                if sol.menu.is_started(inventory_menu) then
                    sol.menu.stop(inventory_menu)
                else
                    for i, menu in ipairs{map_menu, inventory_menu, save_menu} do
                        sol.menu.stop(menu)
                    end
                    zentropy.game.game:set_paused(true)
                    inventory_menu:start(zentropy.game.game, function ()
                        zentropy.game.game:set_paused(false)
                    end)
                end
                return true
            elseif command == 'escape' then
                if zentropy.game.game:is_paused() then
                    for i, menu in ipairs{map_menu, inventory_menu, save_menu} do
                        sol.menu.stop(menu)
                    end
                else
                    zentropy.game.game:set_paused(true)
                    save_menu:start(zentropy.game.game, function ()
                        zentropy.game.game:set_paused(false)
                    end)
                end
                return true
            end
        end
        if native[command] and not handling then
            handling = true
            self:simulate_command_pressed(command)
            handling = false
            return true
        end
        return false
    end

    function zentropy.game.game:on_command_released(command)
        if native[command] then
            if handling then
                return false
            else
                handling = true
                self:simulate_command_released(command)
                handling = false
                return true
            end
        end
    end
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
    zentropy.game.game:set_max_life(4 * tier + 8)
    zentropy.game.game:set_life(4 * tier + 8)
end

function zentropy.game.setup_tier_initial(tier)
    local game = zentropy.game.game

    -- reset dungeon items
    game:set_value(game:get_item('smallkey'):get_savegame_variable(), nil)
    game:set_value(game:get_item('smallkey'):get_amount_savegame_variable(), 0)
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

    function game:on_started()
        if zentropy.settings.debug_walking_speed then
            game:get_hero():set_walking_speed(zentropy.settings.debug_walking_speed)
        end
        self.dialog_box:initialize_dialog_box()
        self:initialize_hud()
        condition_manager:initialize(self)
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
		local map = zentropy.game.game:get_map()
        game_over_menu.game = zentropy.game.game
        zentropy.game.tier = zentropy.game.game:get_value('tier') - 1
        zentropy.game.game = nil
		sol.menu.start(map, game_over_menu)
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

function zentropy.Room:inject_enemy(placeholder, rng)
    zentropy.assert(placeholder, 'placeholder entity must be provided')
    local r = self.enemy_ratio or 1
    local rng2 = rng:refine(r)
    while 1 <= r or rng2:random() < r do
        local map = placeholder:get_map()
        local x, y, layer = placeholder:get_position()
        local breed, treshold = self.next_enemy(rng2:refine('breed'), zentropy.Room.enemies)
        local enemy = map:create_enemy{
            layer=layer,
            x = x,
            y = y + 2,
            direction=3,
            breed=breed,
            treasure_name='random',
        }
        local placeholder_w, placeholder_h = placeholder:get_size()
        local origin_x, origin_y = enemy:get_origin()
        local enemy_w, enemy_h = enemy:get_size()
        enemy:set_position(x + origin_x + (placeholder_w - enemy_w) / 2, y + origin_y + (placeholder_h - enemy_h) / 2)
        local base = math.pow(3, 1/5)
        local tier = zentropy.game.game:get_value('tier')
        local factor = math.pow(base, tier - treshold)
        local life_factor = math.pow(base, math.min(tier, 6) - treshold)
        enemy:set_damage(math.floor(factor * enemy:get_damage() + 0.5))
        enemy:set_life(math.floor(life_factor * enemy:get_life() + 0.5))
        r = r - 1
        rng2 = rng:refine(r)
    end
    placeholder:remove()
    return enemy
end

function zentropy.inject_pot(placeholder, rng)
    zentropy.assert(placeholder, 'placeholder entity must be provided')
    local map = placeholder:get_map()
    local x, y, layer = placeholder:get_position()
    local entity = map:create_destructible{
        layer=layer,
        x = x,
        y = y + 2,
        destruction_sound='stone',
        sprite=zentropy.Room.destructibles.pot,
        treasure_name='random',
    }
    local origin_x, origin_y = entity:get_origin()
    entity:set_position(x + origin_x, y + origin_y)

    return entity
end

function zentropy.Room:inject_stone(placeholder)
    zentropy.assert(placeholder, 'placeholder entity must be provided')
    local map = placeholder:get_map()
    local x, y, layer = placeholder:get_position()
    local weight, sprite = 1, zentropy.Room.destructibles.stone1
    local stone = map:create_destructible{
        layer = layer,
        x = x,
        y = y + 2,
        destruction_sound = 'stone',
        sprite = sprite,
        weight = weight,
        damage_on_enemies = 2 ^ weight,
    }
    local x_origin, y_origin = stone:get_origin()
    stone:set_position(x + x_origin, y + y_origin)
    placeholder:remove()
end

function zentropy.inject_block(placeholder)
    zentropy.assert(placeholder, 'placeholder entity must be provided')
    local map = placeholder:get_map()
    local x, y, layer = placeholder:get_position()
    local entity = map:create_block{
        layer = 1,
        x = x,
        y = y + 2,
        direction = -1,
        sprite = "entities/block",
        pushable = false,
        pullable = false,
        maximum_moves = 0,
    }
    local origin_x, origin_y = entity:get_origin()
    entity:set_position(x + origin_x, y + origin_y)
    placeholder:remove()
    return entity
end

function zentropy.inject_chest(placeholder, data)
    zentropy.assert(placeholder, 'placeholder entity must be provided')
    local map = placeholder:get_map()
    local x, y, layer = placeholder:get_position()
    local chest = map:create_chest{
        x = x,
        y = y + 2,
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
        x = x,
        y = y + 2,
        layer=layer,
        treasure_name=data.item_name,
        treasure_variant=data.variant,
        treasure_savegame_variable=data.name,
        sprite='entities/big_chest',
        opening_method='interaction_if_savegame_variable',
        opening_condition='bigkey',
        cannot_open_dialog="_big_key_required",
    }
    local origin_x, origin_y = chest:get_origin()
    chest:set_position(x + origin_x + 8, y + origin_y + 8)
    return chest
end

function zentropy.inject_door(position_tile, properties)
    zentropy.assert(position_tile)
    zentropy.assert(properties.direction)
    zentropy.assert(properties.sprite)
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

function zentropy.menu(text)
    local menu = zentropy.game.game.dialog_box:new()
    menu.dialog = {text = text}
    return menu
end

function zentropy.pots(rng, ...)
    for _, entities in ipairs{...} do
        for entity in entities do
            zentropy.inject_pot(entity, rng:refine(entity:get_name()))
        end
    end
end

function zentropy.hideout(rng_seq, ...)
    local hideout = nil
    for _, entities in ipairs{...} do
        for entity in entities do
            if rng_seq() then
                hideout, entity = entity, hideout
            end
            if entity and entity:get_type() == 'block' then
                entity:set_pushable(false)
                entity:set_pullable(false)
            end
        end
    end
    return hideout
end

function zentropy.hide_switch(switch, hideout)
    local x, y, layer = hideout:get_position()
    if zentropy.settings.debug_cheat then
        x, y = x + 4, y + 4
    end
    local origin_x, origin_y = hideout:get_origin()
    switch:set_position(x - origin_x, y - origin_y, layer)

    if hideout:get_type() == 'dynamic_tile' then
        hideout:remove()
    else
        hideout:bring_to_front()
    end
end

function zentropy.enemy_strategies.create_uniform(rng, enemies)
    zentropy.assert(enemies, 'uninitialized: enemies')
    local breed, treshold = rng:refine('enemy'):choose(enemies)
    return function (rng)
        return breed, treshold
    end
end

function zentropy.enemy_strategies.create_halves(rng, enemies)
    local breed0, treshold0 = rng:refine('0'):choose(enemies)
    local breed1, treshold1
    for i = 1, 5 do
        breed1, treshold1 = rng:refine(i):choose(enemies)
        if breed1 ~= breed0 then
            break
        end
    end
    if treshold0 > treshold1 then
        breed0, treshold0, breed1, treshold1 = breed1, treshold1, breed0, treshold0
    end
    local i = -1
    return function (rng)
        i = (i + 1) % 2
        if i == 0 then
            return breed0, treshold0
        else
            return breed1, treshold1
        end
    end
end

function zentropy.enemy_strategies.create_thirds(rng, enemies)
    local breed0, treshold0 = rng:refine('0'):choose(enemies)
    local breed1, treshold1
    local breed2, treshold2
    local i1
    for i = 1, 5 do
        i1 = i
        breed1, treshold1 = rng:refine(i):choose(enemies)
        if breed1 ~= breed0 then
            break
        end
    end
    for j = i1+1, i1+5 do
        breed2, treshold2 = rng:refine(j):choose(enemies)
        if breed2 ~= breed0 and breed2 ~= breed1 then
            break
        end
    end
    if treshold0 > treshold1 then
        breed0, treshold0, breed1, treshold1 = breed1, treshold1, breed0, treshold0
    end
    if treshold1 > treshold2 then
        breed1, treshold1, breed2, treshold2 = breed2, treshold2, breed1, treshold1
    end
    if treshold0 > treshold1 then
        breed0, treshold0, breed1, treshold1 = breed1, treshold1, breed0, treshold0
    end
    local i = -1
    return function (rng)
        i = (i + 1) % 3
        if i == 0 then
            return breed0, treshold0
        elseif i == 1 then
            return breed1, treshold1
        else
            return breed2, treshold2
        end
    end
end

function zentropy.enemy_strategies.create_majority(rng, enemies)
    local breed0, treshold0 = rng:refine('0'):choose(enemies)
    local breed1, treshold1
    for i = 1, 5 do
        breed1, treshold1 = rng:refine(i):choose(enemies)
        if breed1 ~= breed0 then
            break
        end
    end
    if treshold0 > treshold1 then
        breed0, treshold0, breed1, treshold1 = breed1, treshold1, breed0, treshold0
    end
    local i = 0
    return function (rng)
        i = (i + 1) % 4
        if i == 0 then
            return breed1, treshold1
        else
            return breed0, treshold0
        end
    end
end

return zentropy
