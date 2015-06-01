local inventory_menu = {}

local active_x = 88
local active_y = 61
local passive_x = 88
local passive_y = 133
local dungeon_x = 201
local dungeon_y = 48
local tunic_x = 220
local tunic_y = 133
local delta_x = 24
local delta_y = 24
local tunic_delta_x = 8
local tunic_delta_y = 4
local num_columns = 4
local num_rows = 3
local num_active_rows = 2

function inventory_menu:start(game, on_finished_callback)
    self.game = game
    self.on_finished_callback = on_finished_callback
    sol.menu.start(game, self)
end

function inventory_menu:on_started()
    self.background = sol.surface.create("inventory_menu.png", true)

    self.cursor_sprite = sol.surface.create("menus/pause_cursor.png", false)
    self.sprites = {}
    self.tunic_counter = nil
    self.assignable_items = {}
    self.passive_items = {}

    for i, item_name in ipairs(zentropy.game.items) do
        local item = self.game:get_item(item_name)
        if item:is_assignable() then
            table.insert(self.assignable_items, item)
        else
            table.insert(self.passive_items, item)
        end
        local variant = item:get_variant()

        if variant > 0 then
            -- Initialize the sprite.
            self.sprites[item_name] = sol.sprite.create("entities/items")
            self.sprites[item_name]:set_animation(item:get_name())
            self.sprites[item_name]:set_direction(variant - 1)
        end
    end

    if self.game:get_value('tier') >= 2 then
        self.sprites.tunic = sol.sprite.create("entities/tunic_1")
        if self.game:get_value('tier') > 6 then
            self.tunic_counter = sol.text_surface.create{
                horizontal_alignment = "center",
                vertical_alignment = "top",
                text = self.game:get_value('tier') - 1,
                font = "white_digits",
            }
        end
    end

    -- Initialize the cursor
    local index = self.game:get_value("pause_inventory_last_item_index") or 0
    local row = math.floor(index / 4)
    if self.from == 'right' then
        column = 3
    else
        column = 0
    end
    self:set_cursor_position(row, column)

    self.map_icons = sol.surface.create("menus/dungeon_map_icons.png")
    self.small_keys_text = sol.text_surface.create{
        font = "white_digits",
        horizontal_alignment = "right",
        vertical_alignment = "top",
        text = self.game:get_value('small_key_amount')
    }
end

function inventory_menu:on_draw(dst_surface)
    for i, item in ipairs(self.items) do
        if i == self.current_item then
            item.surface:set_color{255, 255, 255}
        else
            item.surface:set_color{128, 128, 128}
        end
        item.surface:draw(dst_surface)
    end
end

function inventory_menu:on_finished()

    self.on_finished_callback()

    if self:is_assigning_item() then
        self:finish_assigning_item()
    end

    if self.game.hud ~= nil then
        self.game.hud.item_icon_1.surface:set_opacity(255)
        self.game.hud.item_icon_2.surface:set_opacity(255)
    end
end

function inventory_menu:set_cursor_position(row, column)

  self.cursor_row = row
  self.cursor_column = column

  local index = row * 4 + column
  self.game:set_value("pause_inventory_last_item_index", index)

  -- Update the action icon.
  local item = self.assignable_items[index + 1]
  local variant = item and item:get_variant() or 0

  local item_icon_opacity = 128
  if variant > 0 then
    self.game:set_custom_command_effect("action", "info")
    if item:is_assignable() then
      item_icon_opacity = 255
    end
  else
    self.game:set_custom_command_effect("action", nil)
  end
  self.game.hud.item_icon_1.surface:set_opacity(item_icon_opacity)
  self.game.hud.item_icon_2.surface:set_opacity(item_icon_opacity)
end

function inventory_menu:get_selected_index()

  return self.cursor_row * 4 + self.cursor_column
end

function inventory_menu:is_item_selected()

  local item = self.assignable_items[self:get_selected_index() + 1]
  return item and item:get_variant() > 0
end

function inventory_menu:on_command_pressed(command)
    if command == "action" then
      if self.game:get_command_effect("action") == nil
            and self.game:get_custom_command_effect("action") == "info" then
        self:show_info_message()
        handled = true
      end

    elseif command == "item_1" then
      if self:is_item_selected() then
        self:assign_item(1)
        handled = true
      end

    elseif command == "item_2" then
      if self:is_item_selected() then
        self:assign_item(2)
        handled = true
      end

    elseif command == "left" then
        sol.audio.play_sound("cursor")
        self:set_cursor_position(self.cursor_row, (self.cursor_column - 1) % num_columns)
        handled = true

    elseif command == "right" then
        sol.audio.play_sound("cursor")
        self:set_cursor_position(self.cursor_row, (self.cursor_column + 1) % num_columns)
        handled = true

    elseif command == "up" then
      sol.audio.play_sound("cursor")
      self:set_cursor_position((self.cursor_row - 1) % num_rows, self.cursor_column)
      handled = true

    elseif command == "down" then
      sol.audio.play_sound("cursor")
      self:set_cursor_position((self.cursor_row + 1) % num_rows, self.cursor_column)
      handled = true

    elseif command == "inventory" or command == "escape" then
        sol.menu.stop(self)
        handled = true
    end

    return handled
end

function inventory_menu:on_draw(dst_surface)

  --self:draw_background(dst_surface)
  self.background:draw(dst_surface, 0, 0)

    -- Draw each inventory item.
  local y = active_y
  local k = 0
  for i = 0, 3 do
    local x = active_x

    for j = 0, 3 do
      k = k + 1
      if self.assignable_items[k] ~= nil then
        local item = self.assignable_items[k]
        if item:get_variant() > 0 then
          -- The player has this item: draw it.
          self.sprites[item:get_name()]:draw(dst_surface, x, y)
        end
      end
      x = x + 24
    end
    y = y + 24
  end

    for i, item in ipairs(self.passive_items) do
        if item:get_variant() > 0 then
            local x = passive_x + delta_x * (i - 1)
            local y = passive_y
            self.sprites[item:get_name()]:draw(dst_surface, x, y)
        end
    end

    -- Draw the cursor.
    local cursor_x = active_x + delta_x * self.cursor_column
    local cursor_y
    if self.cursor_row < num_active_rows then
        cursor_y = active_y + delta_y * self.cursor_row
    else
        cursor_y = passive_y + delta_y * (self.cursor_row - num_active_rows)
    end
    if self:is_item_selected() then
        self.cursor_sprite:set_opacity(255)
    else
        self.cursor_sprite:set_opacity(128)
    end
    self.cursor_sprite:draw(dst_surface, cursor_x - 16, cursor_y - 21)

  -- Draw the item being assigned if any.
  if self:is_assigning_item() then
    self.item_assigned_sprite:draw(dst_surface)
  end

        -- Map.
    if self.game:get_value('map') then
        self.map_icons:draw_region(0, 0, 17, 17, dst_surface, dungeon_x, dungeon_y)
    end

    -- Compass.
    if self.game:get_value('compass') then
        self.map_icons:draw_region(17, 0, 17, 17, dst_surface, dungeon_x, dungeon_y + delta_y)
    end

    -- Big key.
    if self.game:get_value('bigkey') then
        self.map_icons:draw_region(34, 0, 17, 17, dst_surface, dungeon_x + delta_x, dungeon_y)
    end

    -- Small keys.
    if self.game:get_value('small_key') then
        self.map_icons:draw_region(68, 0, 9, 17, dst_surface, dungeon_x + delta_x + 2, dungeon_y + delta_y - 1)
        self.small_keys_text:set_xy(dungeon_x + delta_x + 18, dungeon_y + delta_y + 8)
        self.small_keys_text:draw(dst_surface)
    end

    if self.tunic_counter then
        self.sprites.tunic:draw(dst_surface, tunic_x, tunic_y)
        self.tunic_counter:draw(dst_surface, tunic_x + 8, tunic_y)
    else
        for i = 1, self.game:get_value('tier') - 1 do
            local x = tunic_x + ((2 - self.game:get_value('tier')) / 2 + i - 1) * tunic_delta_x
            local y = tunic_y
            if self.game:get_value('tier') > 2 then
                y = y - (i % 2) * tunic_delta_y + tunic_delta_y / 2
            end
            self.sprites.tunic:draw(dst_surface, x, y)
        end
    end
end

-- Shows a message describing the item currently selected.
-- The player is supposed to have this item.
function inventory_menu:show_info_message()

  local item = self.assignable_items[self:get_selected_index() + 1]
  local variant = item:get_variant()
  local map = self.game:get_map()

  -- Position of the dialog (top or bottom).
  if self.cursor_row >= 2 then
    self.game.dialog_box:set_dialog_position("top")  -- Top of the screen.
  else
    self.game.dialog_box:set_dialog_position("bottom")  -- Bottom of the screen.
  end

  self.game:set_custom_command_effect("action", nil)
  self.game:set_custom_command_effect("attack", nil)
  self.game:start_dialog("_item_description." .. item:get_name() .. "." .. variant, function()
    self.game:set_custom_command_effect("action", "info")
    self.game:set_custom_command_effect("attack", "save")
    self.game.dialog_box:set_dialog_position("auto")  -- Back to automatic position.
  end)

end

-- Assigns the selected item to a slot (1 or 2).
-- The operation does not take effect immediately: the item picture is thrown to
-- its destination icon, then the assignment is done.
-- Nothing is done if the item is not assignable.
function inventory_menu:assign_item(slot)

  local index = self:get_selected_index() + 1
  local item = self.assignable_items[index]

  -- If this item is not assignable, do nothing.
  if not item:is_assignable() then
    return
  end

  -- If another item is being assigned, finish it immediately.
  if self:is_assigning_item() then
    self:finish_assigning_item()
  end

  -- Memorize this item.
  self.item_assigned = item
  self.item_assigned_sprite = sol.sprite.create("entities/items")
  self.item_assigned_sprite:set_animation(item:get_name())
  self.item_assigned_sprite:set_direction(item:get_variant() - 1)
  self.item_assigned_destination = slot

  -- Play the sound.
  sol.audio.play_sound("throw")

  -- Compute the movement.
  local x1 = active_x + delta_x * self.cursor_column
  local y1 = active_y + delta_y * self.cursor_row
  local x2, y2 = ((slot == 1) and self.game.hud.item_icon_1 or self.game.hud.item_icon_2):get_item_position()

  self.item_assigned_sprite:set_xy(x1, y1)
  local movement = sol.movement.create("target")
  movement:set_target(x2, y2)
  movement:set_speed(500)
  movement:start(self.item_assigned_sprite, function()
    self:finish_assigning_item()
  end)
end

-- Returns whether an item is currently being thrown to an icon.
function inventory_menu:is_assigning_item()
  return self.item_assigned_sprite ~= nil
end

-- Stops assigning the item right now.
-- This function is called when we want to assign the item without
-- waiting for its throwing movement to end, for example when the inventory submenu
-- is being closed.
function inventory_menu:finish_assigning_item()

  -- If the item to assign is already assigned to the other icon, switch both items.
  local slot = self.item_assigned_destination
  local current_item = self.game:get_item_assigned(slot)
  local other_item = self.game:get_item_assigned(3 - slot)

  if other_item == self.item_assigned then
    self.game:set_item_assigned(3 - slot, current_item)
  end
  self.game:set_item_assigned(slot, self.item_assigned)

  self.item_assigned_sprite:stop_movement()
  self.item_assigned_sprite = nil
  self.item_assigned = nil
end

return inventory_menu
