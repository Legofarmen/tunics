-- Base class of each submenu.

local submenu = {}

function submenu:new(game, submenus)
  local o = { game = game, pause_submenus = submenus }
  setmetatable(o, self)
  self.__index = self
  return o
end

function submenu:on_started()

  self.background_surfaces = sol.surface.create("pause_submenus.png", true)
  self.background_surfaces:set_opacity(216)

  local dialog_font = 'la'
  local menu_font = 'minecraftia'

  self.question_text_1 = sol.text_surface.create{
    horizontal_alignment = "center",
    vertical_alignment = "middle",
    color = {8, 8, 8},
    font = dialog_font,
  }
  self.question_text_2 = sol.text_surface.create{
    horizontal_alignment = "center",
    vertical_alignment = "middle",
    color = {8, 8, 8},
    font = dialog_font,
  }

  self.caption_text_1 = sol.text_surface.create{
    horizontal_alignment = "center",
    vertical_alignment = "middle",
    font = menu_font,
  }

  self.caption_text_2 = sol.text_surface.create{
    horizontal_alignment = "center",
    vertical_alignment = "middle",
    font = menu_font,
  }

  self.game:set_custom_command_effect("action", nil)
  self.game:set_custom_command_effect("attack", "save")
end

-- Sets the caption text.
-- The caption text can have one or two lines, with 20 characters maximum for each line.
-- If the text you want to display has two lines, use the '$' character to separate them.
-- A value of nil removes the previous caption if any.
function submenu:set_caption(text_key)

  if text_key == nil then
    self.caption_text_1:set_text(nil)
    self.caption_text_2:set_text(nil)
  else
    local text = sol.language.get_string(text_key)
    assert(text, 'text key not found: ' .. text_key)
    local line1, line2 = text:match("([^$]+)%$(.*)")
    if line1 == nil then
      -- Only one line.
      self.caption_text_1:set_text(text)
      self.caption_text_2:set_text(nil)
    else
      -- Two lines.
      self.caption_text_1:set_text(line1)
      self.caption_text_2:set_text(line2)
    end
  end
end

-- Draw the caption text previously set.
function submenu:draw_caption(dst_surface)

  local width, height = dst_surface:get_size()

  if self.caption_text_2:get_text():len() == 0 then
    self.caption_text_1:draw(dst_surface, width / 2, height / 2 + 89)
  else
    self.caption_text_1:draw(dst_surface, width / 2, height / 2 + 83)
    self.caption_text_2:draw(dst_surface, width / 2, height / 2 + 95)
  end
end

function submenu:next_submenu()

  sol.audio.play_sound("pause_closed")
  sol.menu.stop(self)
  local submenus = self.pause_submenus
  local submenu_index = self.game:get_value("pause_last_submenu")
  submenu_index = (submenu_index % #submenus) + 1
  self.game:set_value("pause_last_submenu", submenu_index)
  submenus[submenu_index].from = 'left'
  sol.menu.start(self.game, submenus[submenu_index], false)
end

function submenu:previous_submenu()

  sol.audio.play_sound("pause_closed")
  sol.menu.stop(self)
  local submenus = self.pause_submenus
  local submenu_index = self.game:get_value("pause_last_submenu")
  submenu_index = (submenu_index + 2) % #submenus + 1
  self.game:set_value("pause_last_submenu", submenu_index)
  submenus[submenu_index].from = 'right'
  sol.menu.start(self.game, submenus[submenu_index], false)
end

function submenu:draw_background(dst_surface)

  local submenu_index = self.game:get_value("pause_last_submenu")
  local width, height = dst_surface:get_size()
  self.background_surfaces:draw_region(
      320 * (submenu_index - 1), 0, 320, 240,
      dst_surface, (width - 320) / 2, (height - 240) / 2)
end

function submenu:on_command_pressed(command)
    if command == 'attack' then
        self.game:save()
        sol.main.reset()
    end
    return false
end

return submenu
