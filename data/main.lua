local Class = require 'lib/class.lua'

local Project = Class:new()

function Project:new(o)
    o = o or {}
    o.entries = o.entries or {}
    return Class.new(self, o)
end

function Project:init()
    local filename = 'project_db.dat'
    local f = sol.main.load_file(filename)
    if not f then
        error("error: loading file: " .. filename)
    end

    local entries = self.entries
    local env = setmetatable({}, {__index=function(t, key)
        return function(properties)
            entries[key] = entries[key] or {}
            table.insert(entries[key], properties)
        end
    end})

    setfenv(f, env)()
end

local project = Project:new()
project:init()

local components = {
    obstacles = {},
    treasures = {},
    doors = {},
    enemies = {},
    fillers = {},
}
function components:obstacle(id, iterator)
    local item = iterator()
    local dir = iterator()
    local mask = iterator()
    local sequence = iterator()
    self.obstacles[item] = self.obstacles[item] or {}
    self.obstacles[item][dir] = self.obstacles[item][dir] or {}
    self.obstacles[item][dir][sequence] = {
        id=id,
        mask=mask,
    }
end

function components:treasure(id, iterator)
    local open = iterator()
    local mask = iterator()
    local sequence = iterator()
    self.treasures[open] = self.treasures[open] or {}
    self.treasures[open][sequence] = {
        id=id,
        mask=mask,
    }
end

function components:door(id, iterator)
    local open = iterator()
    local dir = iterator()
    local mask = iterator()
    local sequence = iterator()
    print('door', open, dir, mask, sequence)
    self.doors[open] = self.doors[open] or {}
    self.doors[open][dir] = self.doors[open][dir] or {}
    self.doors[open][dir][sequence] = {
        id=id,
        mask=mask,
    }
end

function components:enemy(id, iterator)
    local mask = iterator()
    local sequence = iterator()
    self.enemies[sequence] = {
        id=id,
        mask=mask,
    }
end

function components:filler(id, iterator)
    local mask = iterator()
    local sequence = iterator()
    self.fillers[sequence] = {
        id=id,
        mask=mask,
    }
end

function components:parse_maps(maps)
    for k, v in pairs(maps) do
        if string.sub(v.id, 0, 11) == 'components/' then
            local parts = string.gmatch(string.sub(v.id, 12), '[^_]+')
            local part = parts()
            if components[part] then
                components[part](components, v.id, parts)
            else
                print('ignoring', v.id)
            end
        end
    end
end

components:parse_maps(project.entries.map)

local MapMenu = Class:new{
    colors={
        [1] = {150,150,150},
        [2] = {200,200,200},
        entrance = {255,255,255},
    },
}

function MapMenu:on_started()
    local width, height = sol.video.get_quest_size()
    local center_x, center_y = width / 2, height / 2
    self.backgrounds = sol.surface.create("pause_submenus.png", true)
    self.map_overlay = sol.surface.create("menus/dungeon_map_background.png")
    self.map_icons = sol.surface.create("menus/dungeon_map_icons.png")
    self.hero_point_sprite = sol.sprite.create("menus/hero_point")
    self.map_overlay:set_xy(center_x - 112, center_y - 61)
    self.map_surface = sol.surface.create(118, 120)
    self.map_surface:set_xy(center_x - 15, center_y - 55)
end

function MapMenu:on_command_pressed(command)
    return command ~= 'pause'
end

function MapMenu:on_draw(dst_surface)
    self.game:get_map():render_map(self)
    local width, height = dst_surface:get_size()
    self.backgrounds:draw_region(320, 0, 320, 240, dst_surface, (width - 320) / 2, (height - 240) / 2)
    self.map_overlay:draw(dst_surface)
    self.map_surface:draw(dst_surface)
end

function MapMenu:clear_map()
    self.map_surface:clear()
end

function MapMenu:draw_room(map_x, map_y, perception)
    local x = 12 * map_x
    local y = 12 * map_y
    self.map_surface:fill_color(self.colors[perception], x, y, 10, 10)
end

function MapMenu:draw_door(map_x, map_y, dir, perception)
    local x = 12 * map_x
    local y = 12 * map_y
    if dir == 'north' then
        self.map_surface:fill_color(self.colors[perception], x + 4, y - 2, 2, 2)
    elseif dir == 'west' then
        self.map_surface:fill_color(self.colors[perception], x - 2, y + 4, 2, 2)
    end
end
function MapMenu:draw_entrance(map_x, map_y, dir)
    local x = 12 * map_x
    local y = 12 * map_y
    if dir == 'north' then
        self.map_surface:fill_color(self.colors.entrance, x + 4, y - 4, 2, 4)
    elseif dir == 'west' then
        self.map_surface:fill_color(self.colors.entrance, x - 4, y + 4, 4, 2)
    end
end
function MapMenu:draw_chest(map_x, map_y)
    local x = 12 * map_x
    local y = 12 * map_y
    self.map_icons:draw_region(78, 8, 4, 4, self.map_surface, x + 2, y + 2)
end
function MapMenu:draw_big_chest(map_x, map_y)
    local x = 12 * map_x
    local y = 12 * map_y
    self.map_icons:draw_region(78, 12, 6, 4, self.map_surface, x + 2, y + 2)
end
function MapMenu:draw_boss(map_x, map_y)
    local x = 12 * map_x
    local y = 12 * map_y
    self.map_icons:draw_region(78, 0, 8, 8, self.map_surface, x + 1, y + 1)
end
function MapMenu:draw_hero_point()
    local hero_x, hero_y = self.game:get_hero():get_position()
    self.hero_point_sprite:draw(self.map_surface, 2 * math.floor(6 * (hero_x - 40) / 320), 2 * math.floor(6 * (hero_y - 40) / 240))
end

function sol.main:on_started()
    sol.language.set_language("en")

    sol.game.delete("zentropy1.dat")
    local game = sol.game.load("zentropy1.dat")
    game:set_ability("sword", 1)
    game:set_max_life(12)
    game:set_life(12)

    require('lib/map_include.lua')
    sol.main.load_file("hud/hud")(game)

    game:set_starting_location('dungeons/dungeon1')

    local map_menu = MapMenu:new{game=game}

    function game:on_command_pressed(command)
        if command == 'pause' and game:is_paused() then
            game:save()
            print("saved")
        end
    end

    function game:on_paused()
        sol.menu.start(self, map_menu, false)
        self:hud_on_paused()
    end

    function game:on_unpaused()
        sol.menu.stop(map_menu)
        self:hud_on_unpaused()
    end
    
    function game:on_started()
        game:get_hero():set_walking_speed(160)
        self:initialize_hud()
    end

    function game:on_finished()
        self:quit_hud()
    end

    function game:on_map_changed(map)
        self:hud_on_map_changed(map)
    end

    game:start()
end
