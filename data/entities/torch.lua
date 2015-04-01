local entity = ...
local map = entity:get_map()
local pushing = nil
local util = require('lib/util')

function entity:on_created()
  self:create_sprite("entities/torch")
  self:get_sprite():set_animation("unlit")
  self:set_traversable_by(false)
  self.timeout = 5000
end

function entity:on_interaction_item(item_used)
	if not self:is_lit() and item_used:get_name() == "lamp" then
    	self:get_sprite():set_animation("lit")
		self:on_lit()
		sol.timer.start(self.timeout, function()
			if self:on_unlighting() ~= false then
				self:get_sprite():set_animation("unlit")
			end
		end)
	end
end

function entity:on_lit()

end

function entity:is_lit()
	return self:get_sprite():get_animation() == "lit"
end

function entity:set_timeout(timeout)
	self.timeout = timeout
end

function entity:on_unlighting()
	
end