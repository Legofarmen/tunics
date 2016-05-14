local Class = require 'lib/class'

local Menu = Class:new()

function Menu:new(o)
    zentropy.assert(type(o) == 'table')
    zentropy.assert(type(o.entries) == 'table' and #o.entries > 0)
    return Class.new(self, o)
end

function Menu:start(context, on_finished_callback)
    self.on_finished_callback = on_finished_callback
    sol.menu.start(context, self)
end

function Menu:on_started()
    self.surfaces = {}
    for i, title in ipairs(self.entries) do
        local surface = sol.text_surface.create{
            font = "la",
            horizontal_alignment = "center",
            vertical_alignment = "middle",
            text = title,
        }
        table.insert(self.surfaces, surface)
    end
    
    self.current_item = 1

    local item_width, item_height = self.surfaces[1]:get_size()
    local menu_height = item_height * #self.surfaces + math.ceil(0.5 * item_height) * (#self.surfaces - 1)
    local screen_width, screen_height = sol.video.get_quest_size()
    local center_x, start_y = screen_width / 2, (screen_height - menu_height) / 2
    for _, surface in ipairs(self.surfaces) do
        surface:set_xy(center_x, start_y)
        start_y = start_y + math.ceil(1.5 * item_height)
    end

    local zentropy = require 'lib/zentropy'
    self.debug = sol.text_surface.create{
        font = "la",
        horizontal_alignment = "left",
        vertical_alignment = "bottom",
        text = "S:" .. zentropy.game:get_seed() .. " T:" .. zentropy.game:get_tier() .. " V:" .. zentropy.version,
    }
    self.debug:set_xy(3, 240)
    self.debug:set_color{64, 64, 64}
end

function Menu:on_command_pressed(command)
    local handled = false
    if command == "escape" then
        self:on_action(nil)
        handled = true
    elseif command == "action" then
        self:on_action(self.surfaces[self.current_item]:get_text())
        handled = true
    elseif command == "up" then
        if self.current_item > 1 then self.current_item = self.current_item - 1 end
        handled = true
    elseif command == "down" then
        if self.current_item < #self.surfaces then self.current_item = self.current_item + 1 end
        handled = true
    end

    return handled
end

function Menu:on_draw(dst_surface)
    dst_surface:fill_color({0, 0, 0})

    for i, surface in ipairs(self.surfaces) do
        if i == self.current_item then
            surface:set_color{255, 255, 255}
        else
            surface:set_color{128, 128, 128}
        end
        surface:draw(dst_surface)
    end
    self.debug:draw(dst_surface)
end

function Menu:on_finished()
    self.on_finished_callback()
end

return Menu
