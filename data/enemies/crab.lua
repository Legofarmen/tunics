local enemy = ...

-- Crab: a basic enemy.

function enemy:on_created()
  self:set_life(2)
  self:set_damage(2)
  self:create_sprite("enemies/crab")
  self:set_size(24, 16)
  self:set_origin(12, 12)
end

function enemy:on_restarted()
  local m = sol.movement.create("path_finding")
  m:set_speed(40)
  m:start(self)
end