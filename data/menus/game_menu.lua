local zentropy = require 'lib/zentropy'
local help_menu = require 'menus/help_menu'
local bindings = require 'lib/bindings'

local game_menu = {}

function game_menu:on_started()
    local function create_surface(text)
        return sol.text_surface.create{
            font = "la",
            horizontal_alignment = "center",
            vertical_alignment = "middle",
            text = text,
        }
    end
    bindings.mixin(help_menu)
    local function help_action()
        help_menu:start(self, self.game)
    end
    local function resume_action()
        zentropy.game.resume_game()
        sol.audio.stop_music()
        sol.menu.stop(self)
    end
    local function new_game_action()
        zentropy.game.new_game()
        sol.audio.stop_music()
        sol.menu.stop(self)
    end
    self.items = {}
    local tier = zentropy.game.has_savegame()
    if tier then
        local title = 'Continue (tier X)'
        title = title:gsub('X', tier)
        table.insert(self.items, { surface = create_surface(title), action = resume_action })
    end
    table.insert(self.items, { surface = create_surface('New game'), action = new_game_action })
    table.insert(self.items, { surface = create_surface('Controls'), action = help_action })
    table.insert(self.items, { surface = create_surface('Exit'), action = sol.main.exit })
    self.current_item = 1

    local item_width, item_height = self.items[1].surface:get_size()
    local menu_height = item_height * #self.items + math.ceil(0.5 * item_height) * (#self.items - 1)
    local screen_width, screen_height = sol.video.get_quest_size()
    local center_x, start_y = screen_width / 2, (screen_height - menu_height) / 2
    for _, item in ipairs(self.items) do
        item.surface:set_xy(center_x, start_y)
        start_y = start_y + math.ceil(1.5 * item_height)
    end
end

function game_menu:on_command_pressed(key)
    local handled = false
    if key == "action" then
        self.items[self.current_item].action()
        handled = true
    elseif key == "up" then
        if self.current_item > 1 then self.current_item = self.current_item - 1 end
        handled = true
    elseif key == "down" then
        if self.current_item < #self.items then self.current_item = self.current_item + 1 end
        handled = true
    end

    return handled
end

function game_menu:on_draw(dst_surface)
    for i, item in ipairs(self.items) do
        if i == self.current_item then
            item.surface:set_color{255, 255, 255}
        else
            item.surface:set_color{128, 128, 128}
        end
        item.surface:draw(dst_surface)
    end
end

return game_menu
