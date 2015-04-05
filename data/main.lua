local zentropy = require 'lib/zentropy'
local util = require 'lib/util'

zentropy.init()

util.wdebug_truncate()

local savegame_menu = {}

function savegame_menu:on_started()
    local width, height = sol.video.get_quest_size()
    local center_x, center_y = width / 2, height / 2
    self.state = 'resume'
    self.resume_text = sol.text_surface.create{
      font = "dialog",
      horizontal_alignment = "left",
      vertical_alignment = "top",
      text = 'Resume game',
    }
    self.resume_text:set_xy(100, center_y - 10)
    self.new_text = sol.text_surface.create{
      font = "dialog",
      horizontal_alignment = "left",
      vertical_alignment = "top",
      text = 'New game',
    }
    self.new_text:set_xy(100, center_y + 10)
    self.cursor_text = sol.text_surface.create{
      font = "dialog",
      horizontal_alignment = "left",
      vertical_alignment = "top",
      text = ">",
    }
end

function savegame_menu:on_draw(dst_surface)
    local x, y
    if self.state == 'new' then
        x, y = self.new_text:get_xy()
    else
        x, y = self.resume_text:get_xy()
    end
    self.cursor_text:set_xy(x - 20, y)
    self.cursor_text:draw(dst_surface)
    self.resume_text:draw(dst_surface)
    self.new_text:draw(dst_surface)
end

function savegame_menu:on_key_pressed(key)

    local handled = false
    if key == "escape" then
        sol.main.exit()
        handled = true
    elseif key == "return" then
        local game = nil
        if self.state == 'new' then
            game = zentropy.game.new_game('zentropy1.dat')
            zentropy.game.next_tier()
        else
            game = zentropy.game.resume_game('zentropy1.dat')
        end
        sol.menu.stop(self)
        game:start()
        handled = true
    elseif key == 'up' then
        if self.state ~= 'resume' then self.state = 'resume' end
        handled = true
    elseif key == 'down' then
        if self.state ~= 'new' then self.state = 'new' end
        handled = true
    end

    return handled
end


function sol.main:on_started()
    sol.language.set_language("en")
    math.randomseed(os.time())

    sol.menu.start(self, savegame_menu)

end
