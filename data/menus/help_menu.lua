local help_menu = {}

function help_menu:start(ctx)
    sol.menu.start(ctx, self)
end

function help_menu:on_started()
    self.surface = sol.surface.create("menus/help.png")
end

function help_menu:on_command_pressed(key)
    local handled = false
    if key == "action" or key == "escape" then
        sol.menu.stop(self)
        handled = true
    end
    return handled
end

function help_menu:on_draw(dst_surface)
    self.surface:draw(dst_surface)
end

return help_menu
