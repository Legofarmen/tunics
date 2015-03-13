sol.main.load_file('loadmap.lua')

local Class = {}

function Class:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

local MapMenu = Class:new()

function MapMenu:on_started()
    print("MapMenu:on_started")
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

function MapMenu:draw_room(properties)
    local normal = {255,255,255,216}
    local highlight = {255,255,255}
    local x = 12 * properties.x
    local y = 12 * properties.y

    self.map_surface:fill_color(normal, x, y, 10, 10)
    if properties.doors.north then
        self.map_surface:fill_color(normal, x + 4, y - 2, 2, 2)
    end
    if properties.doors.south then
        if properties.doors.south.open == 'entrance' then
            self.map_surface:fill_color(highlight, x + 4, y + 8, 2, 4)
        end
    end
    if properties.doors.west then
        self.map_surface:fill_color(normal, x - 2, y + 4, 2, 2)
    end

    for _, enemy in ipairs(properties.enemies) do
        if enemy.name == 'boss' then
            self.map_icons:draw_region(78, 0, 8, 8, self.map_surface, x + 1, y + 1)
        end
    end
    for _, item in ipairs(properties.items) do
        if item.open == 'big_key' then
            self.map_icons:draw_region(78, 12, 6, 4, self.map_surface, x + 2, y + 2)
        else
            self.map_icons:draw_region(78, 8, 4, 4, self.map_surface, x + 2, y + 2)
        end
    end
    local hero_x, hero_y = self.game:get_hero():get_position()
    self.hero_point_sprite:draw(self.map_surface, 12 * (hero_x - 40) / 320, 12 * (hero_y - 40) / 240)
    print(hero_x, hero_y)
end


function sol.main:on_started()
    sol.language.set_language("en")

    sol.game.delete("zentropy1.dat")
    local game = sol.game.load("zentropy1.dat")

    require('lib/map_include.lua')

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
    end

    function game:on_unpaused()
        sol.menu.stop(map_menu)
    end

    game:start()
end
