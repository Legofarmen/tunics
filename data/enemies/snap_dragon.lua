local enemy = ...

-- Snap Dragon.

enemy:set_life(3)
enemy:set_damage(4)
enemy:set_hurt_style("normal")
enemy:set_size(16, 16)
enemy:set_origin(8, 13)
local sprite = enemy:create_sprite("enemies/snap_dragon")

function enemy:on_restarted()
	self:go_random()
end

function enemy:on_movement_finished(movement)
	sprite:set_animation("immobilized")
	sol.timer.start(self, 600, function()
		sprite:set_animation("bite")
		sol.timer.start(200, function()
			sprite:set_animation("immobilized")
			sol.timer.start(600, function()
				sprite:set_animation("bite")
				sol.timer.start(200, function()
					self:go_random()
				end)
			end)
		end)
	end)

end

function enemy:on_obstacle_reached(movement)
	self:get_movement():set_angle(self:set_direction())
end

function enemy:set_direction()
	local rand4 = math.random(4)
	local direction8 = rand4 * 2 - 1
	local angle = direction8 * math.pi / 4
	
	sprite:set_direction(rand4 - 1)
	return angle
end

function enemy:go_random()

	-- Random diagonal direction.
	sprite:set_animation("walking")
	local m = sol.movement.create("straight")
	self:set_direction()
	m:set_speed(math.random(32,72))
	m:start(self)
	m:set_angle(self:set_direction())
	sol.timer.start(self, math.random(5,9) * (2000 / 7), function()
		m:stop()
		self:on_movement_finished()
	end)
end

function sprite:on_animation_finished(animation)

end