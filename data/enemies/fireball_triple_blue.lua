local enemy = ...

local fireball_triple = require 'enemies/fireball_triple'

function enemy:on_created()
    self:create_sprite("enemies/fireball_triple_blue")
    -- Two smaller fireballs just for the displaying.
    self.sprite2 = sol.sprite.create("enemies/fireball_triple_blue")
    self.sprite2:set_animation("small")
    self.sprite3 = sol.sprite.create("enemies/fireball_triple_blue")
    self.sprite3:set_animation("tiny")

    self:set_size(16, 16)
    self:set_origin(8, 8)

    fireball_triple.init(self)
end
