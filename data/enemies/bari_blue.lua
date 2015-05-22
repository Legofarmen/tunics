local enemy = ...

-- Bari: a flying enemy that follows the hero
--       and tries to electrocute him.

local bari_mixin = require 'enemies/bari_mixin'

function enemy:on_created()
    self:set_life(2)
    self:set_damage(2)
    self:create_sprite("enemies/bari_blue")
    self:set_size(16, 16)
    self:set_origin(8, 13)
    self:set_obstacle_behavior("flying")
    bari_mixin.mixin(self)
end
