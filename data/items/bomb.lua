local item = ...

local game = item:get_game()

function item:on_created()
    self:set_savegame_variable('bomb')
    self:set_assignable(true)
    self:set_brandish_when_picked(false)
end

function item:on_obtained()
    game:set_item_assigned(1, self)
end

function item:on_using()
    self:create_bomb()
    self:set_finished()
end

function item:create_bomb()

  local hero = game:get_hero()
  local x, y, layer = hero:get_position()
  local direction = hero:get_direction()
  if direction == 0 then
    x = x + 16
  elseif direction == 1 then
    y = y - 16
  elseif direction == 2 then
    x = x - 16
  elseif direction == 3 then
    y = y + 16
  end

  self:get_map():create_bomb{
    x = x,
    y = y,
    layer = layer
  }
end

 

