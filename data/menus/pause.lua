local Class = require 'lib/class'

local inventory_builder = require("menus/pause_inventory")
local map_builder = require("menus/pause_map")

local Pause = Class:new()

function Pause:new(o)
    assert(o.game)
    return Class.new(self, o)
end

function Pause:start_pause_menu()
    self.pause_submenus = {}
    table.insert(self.pause_submenus, inventory_builder:new(self.game, self.pause_submenus))
    table.insert(self.pause_submenus, map_builder:new{game=self.game})

    local submenu_index = self.game:get_value("pause_last_submenu")
    if not submenu_index or submenu_index < 1 or submenu_index > #self.pause_submenus then
        submenu_index = 1
    end
    self.game:set_value("pause_last_submenu", submenu_index)

    sol.audio.play_sound("pause_open")
    sol.menu.start(self.game, self.pause_submenus[submenu_index], false)
end

function Pause:stop_pause_menu()

    sol.audio.play_sound("pause_closed")
    local submenu_index = self.game:get_value("pause_last_submenu")
    sol.menu.stop(self.pause_submenus[submenu_index])
    self.pause_submenus = {}
    self.game:set_custom_command_effect("action", nil)
    self.game:set_custom_command_effect("attack", nil)
end

return Pause
