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
    self.overlay = sol.surface.create("menus/dungeon_map_background.png")
    self.overlay:set_xy(center_x - 112, center_y - 61)
    self.dungeon_map = sol.surface.create(118, 120)
    self.dungeon_map:set_xy(center_x - 15, center_y - 55)
end

function MapMenu:on_command_pressed(command)
    return command ~= 'pause'
end

function MapMenu:on_draw(dst_surface)
    self.game:get_map():render_map(self.dungeon_map)
    local width, height = dst_surface:get_size()
    self.backgrounds:draw_region(320, 0, 320, 240, dst_surface, (width - 320) / 2, (height - 240) / 2)
    self.overlay:draw(dst_surface)
    self.dungeon_map:draw(dst_surface)
end

function sol.main:on_started()
    sol.language.set_language("en")

    local exists = sol.game.exists("zentropy1.dat")
    local game = sol.game.load("zentropy1.dat")
    if not exists then
        game:set_max_life(12)
        game:set_life(game:get_max_life())
    end

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
