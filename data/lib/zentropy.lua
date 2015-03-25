local Class = require 'lib/class'
local Util = require 'lib/util'

bit32 = bit32 or bit

zentropy = zentropy or {
    db = {
        Project = {},
        Components = Class:new{
            SECTION_MASKS = {
                Util.oct('000001'),
                Util.oct('000002'),
                Util.oct('000004'),
                Util.oct('000010'),
                Util.oct('000020'),
                Util.oct('000040'),
                Util.oct('000100'),
                Util.oct('000200'),
                Util.oct('000400'),
            },
        },
    },
}

zentropy.db.Project.__index = zentropy.db.Project

function zentropy.init()
    zentropy.components = zentropy.db.Components:new():parse()
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
    o.bossrooms = o.bossrooms or {}
    return Class.new(self, o)
end

function zentropy.db.Components:floor(id, iterator)
    table.insert(self.floors, id)
end

function zentropy.db.Components:obstacle(id, iterator)
    local item = iterator()
    local dir = iterator()
    local mask_string = iterator()
    local mask = Util.oct(mask_string)
    self.obstacles[item] = self.obstacles[item] or {}
    self.obstacles[item][dir] = self.obstacles[item][dir] or {}
    table.insert(self.obstacles[item][dir], {
        id=id,
        mask=mask,
    })
end

function zentropy.db.Components:treasure(id, iterator)
    local open = iterator()
    local mask_string = iterator()
    local mask
    if mask_string == 'any' then
        mask = mask_string
    else
        mask = Util.oct(mask_string)
    end
    self.treasures[open] = self.treasures[open] or {}
    table.insert(self.treasures[open], {
        id=id,
        mask=mask,
    })
end

function zentropy.db.Components:door(id, iterator)
    local open = iterator()
    local dir = iterator()
    local mask_string = iterator()
    local mask = Util.oct(mask_string)
    self.doors[open] = self.doors[open] or {}
    self.doors[open][dir] = self.doors[open][dir] or {}
    table.insert(self.doors[open][dir], {
        id=id,
        mask=mask,
    })
end

function zentropy.db.Components:enemy(id, iterator)
    local mask_string = iterator()
    local mask
    if mask_string == 'any' then
        mask = mask_string
    else
        mask = Util.oct(mask_string)
    end
    table.insert(self.enemies, {
        id=id,
        mask=mask,
    })
end

function zentropy.db.Components:filler(id, iterator)
    local mask_string = iterator()
    local mask
    if mask_string == 'any' then
        mask = mask_string
    else
        mask = Util.oct(mask_string)
    end
    table.insert(self.fillers, {
        id=id,
        mask=mask,
    })
end

function zentropy.db.Components:bossroom(id, iterator)
    local mask_string = iterator()
    local mask = Util.oct(mask_string)
    table.insert(self.bossrooms, {
        id=id,
        mask=mask,
    })
end

function zentropy.db.Components:parse(maps)
    maps = maps or zentropy.db.Project:parse().map

    for k, v in pairs(maps) do
        if string.sub(v.id, 0, 11) == 'components/' then
            local parts = string.gmatch(string.sub(v.id, 12), '[^_]+')
            local part = parts()
            if self[part] then
                self[part](self, v.id, parts)
            else
                print('ignoring component: ', v.id)
            end
        end
    end

    return self
end

function zentropy.db.Components:get_door(open, dir, mask, rng)
    open = open or 'open'
    if not self.doors[open] then
        print('first', open, dir)
        return
    end
    if not self.doors[open][dir] then
        print('second')
        return
    end
    local entries = {}
    for _, entry in pairs(self.doors[open][dir]) do
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
    for _, entry in pairs(self.obstacles[item][dir]) do
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
    for _, entry in pairs(self.fillers) do
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
    for _, entry in pairs(self.treasures[open]) do
        if entry.mask == 'any' then
            for _, section in ipairs(self.SECTION_MASKS) do
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

function zentropy.db.Components:get_floors(rng)
    local i = rng:random(#self.floors)
    local j = rng:random(#self.floors - 1)
    if j >= i then
        j = j + 1
    end
    return self.floors[i], self.floors[j]
end

function zentropy.db.Components:get_bossroom(mask, rng)
    local entries = {}
    for _, entry in pairs(self.bossrooms) do
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




return zentropy
