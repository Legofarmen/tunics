local Class = require 'lib/class'
local Zentropy = require 'lib/zentropy'
local util = require 'lib/util'

Zentropy.init()

util.wdebug_truncate()

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
    self.small_keys_text = sol.text_surface.create{
      font = "white_digits",
      horizontal_alignment = "right",
      vertical_alignment = "top",
      text = self.game:get_value('small_key_amount')
    }
    self.small_keys_text:set_xy(center_x - 20, center_y + 60)
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
    self:draw_dungeon_items(dst_surface)
end

function MapMenu:draw_dungeon_items(dst_surface)

  local width, height = sol.video.get_quest_size()
  local x, y = width / 2 - 110, height / 2 + 48

  -- Map.
  if self.game:get_value('map') then
    self.map_icons:draw_region(0, 0, 17, 17, dst_surface, x, y)
  end

  -- Compass.
  if self.game:get_value('compass') then
    self.map_icons:draw_region(17, 0, 17, 17, dst_surface, x + 19, y)
  end

  -- Big key.
  if self.game:get_value('bigkey') then
    self.map_icons:draw_region(34, 0, 17, 17, dst_surface, x + 38, y)
  end

  -- Small keys.
  self.map_icons:draw_region(68, 0, 9, 17, dst_surface, x + 76, y)
  self.small_keys_text:draw(dst_surface)
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

    local old_game = sol.game.load("zentropy1.dat")
    local seed = old_game:get_value('seed') or 1
    local tier = old_game:get_value('tier') or 1
    sol.game.delete("zentropy1.dat")
    local game = sol.game.load("zentropy1.dat")
    game:set_ability("sword", 1)
    game:set_max_life(12)
    game:set_life(12)
    game:set_value('small_key_amount', 0)
    game:set_value('seed', seed)
    game:set_value('tier', tier)
    game:save()

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
