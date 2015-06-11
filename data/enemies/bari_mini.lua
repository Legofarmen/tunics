local enemy = ...

-- Bari mini: the small enemy an adult bari
--            splits into.

local bari_mixin = require 'enemies/bari_mixin'

function enemy:on_created()
    self:set_life(1)
    self:set_damage(2)
    self:create_sprite("enemies/bari_mini")
    self:set_size(8, 8)
    self:set_origin(4, 6)
    self:set_obstacle_behavior("flying")
    bari_mixin.mixin(self)
end
