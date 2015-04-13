local item = ...
-- Script of the Lamp

local game = item:get_game()

--[[item.temporary_lit_torches = {} -- List of torches that will be unlit by timers soon (FIFO).
item.was_dark_room = false]]

function item:on_created()

  self:set_savegame_variable("lamp")
  self:set_assignable(true)
end

-- Called when the hero uses the Lamp.
function item:on_using()

  local magic_needed = 2  -- Number of magic points required
  if self:get_game():get_magic() >= magic_needed then
    sol.audio.play_sound("lamp")
    self:get_game():remove_magic(magic_needed)
    self:create_fire()
  else
    sol.audio.play_sound("wrong")
  end
  self:set_finished()
end

-- Creates some fire on the map.
function item:create_fire()

  local hero = self:get_map():get_entity("hero")
  local direction = hero:get_direction()
  local dx, dy
  if direction == 0 then
    dx, dy = 18, -4
  elseif direction == 1 then
    dx, dy = 0, -24
  elseif direction == 2 then
    dx, dy = -20, -4
  else
    dx, dy = 0, 16
  end

  local x, y, layer = hero:get_position()
  self:get_map():create_fire{
    x = x + dx,
    y = y + dy,
    layer = layer
  }
end

-- Called when the player obtains the Lamp.
function item:on_obtained(variant, savegame_variable)

    zentropy.game.assign_item(self)

    -- Give the magic bar if necessary.
    local magic_bar = self:get_game():get_item("magic_bar")
    if not magic_bar:has_variant() then
        magic_bar:set_variant(1)
    end
end
