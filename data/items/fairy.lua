local item = ...

-- This script defines the behavior of pickable fairies present on the map.

function item:on_created()

  self:set_shadow(nil)
  self:set_brandish_when_picked(false)
end

-- A fairy appears on the map: create its movement.
function item:on_pickable_created(pickable)

   -- Create a movement that goes into random directions,
   -- with a speed of 28 pixels per second.
  local movement = sol.movement.create("random")
  movement:set_speed(28)
  movement:set_ignore_obstacles(true)
  movement:set_max_distance(40)  -- Don't go too far.

  -- Put the fairy on the highest layer to show it above all walls.
  local x, y = pickable:get_position()
  pickable:set_position(x, y, 2)
  pickable:set_layer_independent_collisions(true)  -- But detect collisions with lower layers anyway

  -- When the direction of the movement changes,
  -- update the direction of the fairy's sprite
  function pickable:on_movement_changed(movement)

    if pickable:get_followed_entity() == nil then

      local sprite = pickable:get_sprite()
      local angle = movement:get_angle()  -- Retrieve the current movement's direction.
      if angle >= math.pi / 2 and angle < 3 * math.pi / 2 then
        sprite:set_direction(1)  -- Look to the left.
      else
        sprite:set_direction(0)  -- Look to the right.
      end
    end
  end

  movement:start(pickable)
end

-- Obtaining a fairy.
function item:on_obtaining(variant, savegame_variable)

    self:get_game():add_life(7 * 4)
  
end

