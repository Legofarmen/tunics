local enemy = ...

-- Keese (bat): Basic flying enemy.

local state = "stopped"
local timer

function enemy:on_created()
  self:set_life(1)
  self:set_damage(1)
  self:create_sprite("enemies/keese")
  self:set_hurt_style("monster")
  self:set_pushed_back_when_hurt(true)
  self:set_push_hero_on_sword(false)
  self:set_obstacle_behavior("flying")
  self:set_layer_independent_collisions(true)
  self:set_size(16, 16)
  self:set_origin(8, 13)
  self:get_sprite():set_animation("stopped")
end

function enemy:on_update()
    local sprite = self:get_sprite()
    local hero = self:get_map():get_hero()
    if not self:is_in_same_region(hero) then
        return
    end
    -- Check whether the hero is close.
    if self:get_life() > 0 then
		if self:get_distance(hero) <= 96 and state ~= "going" then
			local m = sol.movement.create("target")
			self:get_sprite():set_animation("walking")
			m:set_speed(56)
			m:start(self)
			state = "going"
					
		elseif self:get_distance(hero) > 144 then
			self:get_sprite():set_animation("stopped")
			state = "stopped"
			self:stop_movement()
			
		elseif self:get_distance(hero) > 96 and state ~= "random" then
			local m = sol.movement.create("random")
			self:get_sprite():set_animation("walking")
			m:set_speed(24)
			m:start(self)
			state = "random"
			sol.audio.play_sound("keese")
		end    
	end
end

function enemy:on_restarted()
    self:get_sprite():set_animation("stopped")
    state = "stopped"

end