local help_menu = {}

function help_menu:start(ctx)
    sol.menu.start(ctx, self)
end

function help_menu:on_started()
    self.help = {
        sol.surface.create("menus/help_1.png"),
        sol.surface.create("menus/help_2.png"),
    }
    self.current_item = 1
end

function help_menu:on_command_pressed(key)
    local handled = false
    if key == "escape" then
        sol.menu.stop(self)
        handled = true
    elseif key == "action" then
        self.current_item = self.current_item % 2 + 1
        handled = true
    end
    return handled
end

function help_menu:on_draw(dst_surface)
    self.help[self.current_item]:draw(dst_surface)
end

return help_menu
