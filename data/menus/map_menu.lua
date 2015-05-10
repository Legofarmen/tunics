local map_menu = {}

map_menu.colors={
    [1] = {150,150,150},
    [2] = {200,200,200},
    entrance = {255,255,255},
}

local dungeon_items_x, dungeon_items_y, dungeon_items_yd = 224, 63, 32


function map_menu:start(game, on_finished_callback)
    self.game = game
    self.on_finished_callback = on_finished_callback
    sol.menu.start(game, self)
end

function map_menu:on_finished()
    self.on_finished_callback()
end

function map_menu:on_started()

    self.map_overlay = sol.surface.create("menus/dungeon_map_background.png")
    self.map_icons = sol.surface.create("menus/dungeon_map_icons.png")
    self.hero_point_sprite = sol.sprite.create("menus/hero_point")
    self.map_surface = sol.surface.create(118, 120)
    self.map_surface:set_xy(77, 59)
    self.small_keys_text = sol.text_surface.create{
        font = "white_digits",
        horizontal_alignment = "right",
        vertical_alignment = "top",
        text = self.game:get_value('small_key_amount')
    }
end

function map_menu:on_draw(dst_surface)
    self.game:get_map():render_map(self)
    local width, height = dst_surface:get_size()
    self.map_overlay:draw(dst_surface)
    self.map_surface:draw(dst_surface)
    self:draw_dungeon_items(dst_surface)
end

function map_menu:draw_dungeon_items(dst_surface)

    -- Map.
    if self.game:get_value('map') then
        self.map_icons:draw_region(0, 0, 17, 17, dst_surface, dungeon_items_x, dungeon_items_y)
    end

    -- Compass.
    if self.game:get_value('compass') then
        self.map_icons:draw_region(17, 0, 17, 17, dst_surface, dungeon_items_x, dungeon_items_y + dungeon_items_yd)
    end

    -- Big key.
    if self.game:get_value('bigkey') then
        self.map_icons:draw_region(34, 0, 17, 17, dst_surface, dungeon_items_x, dungeon_items_y + 2*dungeon_items_yd)
    end

    -- Small keys.
    if self.game:get_value('small_key') then
        self.map_icons:draw_region(68, 0, 9, 17, dst_surface, dungeon_items_x+2, dungeon_items_y + 3*dungeon_items_yd-1)
        self.small_keys_text:set_xy(dungeon_items_x+18, dungeon_items_y + 3*dungeon_items_yd+8)
        self.small_keys_text:draw(dst_surface)
    end
end

function map_menu:clear_map()
    self.map_surface:clear()
end

function map_menu:draw_room(map_x, map_y, perception)
    local x = 12 * map_x
    local y = 12 * map_y
    self.map_surface:fill_color(self.colors[perception], x, y, 10, 10)
end

function map_menu:draw_door(map_x, map_y, dir, perception)
    local x = 12 * map_x
    local y = 12 * map_y
    if dir == 'north' then
        self.map_surface:fill_color(self.colors[perception], x + 4, y - 2, 2, 2)
    elseif dir == 'west' then
        self.map_surface:fill_color(self.colors[perception], x - 2, y + 4, 2, 2)
    end
end

function map_menu:draw_entrance(map_x, map_y, dir)
    local x = 12 * map_x
    local y = 12 * map_y
    if dir == 'north' then
        self.map_surface:fill_color(self.colors.entrance, x + 4, y - 4, 2, 4)
    elseif dir == 'west' then
        self.map_surface:fill_color(self.colors.entrance, x - 4, y + 4, 4, 2)
    end
end

function map_menu:draw_chest(map_x, map_y)
    local x = 12 * map_x
    local y = 12 * map_y
    self.map_icons:draw_region(78, 8, 4, 4, self.map_surface, x + 2, y + 2)
end

function map_menu:draw_big_chest(map_x, map_y)
    local x = 12 * map_x
    local y = 12 * map_y
    self.map_icons:draw_region(78, 12, 6, 4, self.map_surface, x + 2, y + 2)
end

function map_menu:draw_boss(map_x, map_y)
    local x = 12 * map_x
    local y = 12 * map_y
    self.map_icons:draw_region(78, 0, 8, 8, self.map_surface, x + 1, y + 1)
end

function map_menu:draw_hero_point()
    local hero_x, hero_y = self.game:get_hero():get_position()
    self.hero_point_sprite:draw(self.map_surface, 2 * math.floor(6 * (hero_x - 40) / 320), 2 * math.floor(6 * (hero_y - 40) / 240))
end

return map_menu
