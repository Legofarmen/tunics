local zentropy = require 'lib/zentropy'
local util = require 'lib/util'

zentropy.init()

local savegame_menu = {}

function savegame_menu:on_started()
    local function create_surface(text)
        return sol.text_surface.create{
            font = "dialog",
            horizontal_alignment = "center",
            vertical_alignment = "middle",
            text = text,
        }
    end
    self.items = {}
    if zentropy.game.has_savegame() then
        table.insert(self.items, { surface = create_surface('Continue'), action = zentropy.game.resume_game })
    end
    table.insert(self.items, { surface = create_surface('New game'), action = zentropy.game.new_game })
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

function savegame_menu:on_key_pressed(key)
    local handled = false
    if key == "escape" then
        sol.main.exit()
        handled = true
    elseif key == "return" then
        self.items[self.current_item].action()
        sol.menu.stop(self)
        handled = true
    elseif key == 'up' then
        if self.current_item > 1 then self.current_item = self.current_item - 1 end
        handled = true
    elseif key == 'down' then
        if self.current_item < #self.items then self.current_item = self.current_item + 1 end
        handled = true
    end

    return handled
end

function savegame_menu:on_draw(dst_surface)
    for i, item in ipairs(self.items) do
        if i == self.current_item then
            item.surface:set_color{255, 255, 255}
        else
            item.surface:set_color{128, 128, 128}
        end
        item.surface:draw(dst_surface)
    end
end


function sol.main:on_started()
    sol.language.set_language("en")

    sol.menu.start(self, savegame_menu)
end
