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
    self.backgrounds = sol.surface.create("pause_submenus.png", true)
end

function MapMenu:on_command_pressed(command)
    return command ~= 'pause'
end

function MapMenu:on_draw(dst_surface)
    local width, height = dst_surface:get_size()
    self.backgrounds:draw_region(320, 0, 320, 240, dst_surface, (width - 320) / 2, (height - 240) / 2)
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

    local map_menu = MapMenu:new{game=self}

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
