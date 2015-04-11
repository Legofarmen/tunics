local entity = ...

function entity:on_lit() end
function entity:on_unlighting() end

function entity:on_created()
    self:create_sprite("entities/torch")
    self:get_sprite():set_animation("unlit")
    self:set_traversable_by(false)
    self.timeout = 5000
end

function entity:is_lit()
	return self:get_sprite():get_animation() == "lit"
end

function entity:set_timeout(timeout)
	self.timeout = timeout
end

function entity:light()
    if not self:is_lit() then
        self:get_sprite():set_animation("lit")
        self:on_lit()
    end
    local my_token = {}
    self.lit_token = my_token
    sol.timer.start(self.timeout, function()
        if self.lit_token == my_token then
            self:extinguish()
        end
    end)
end

function entity:extinguish()
    if self:is_lit() and self:on_unlighting() ~= false then
        self:get_sprite():set_animation("unlit")
    end
end

entity:add_collision_test('sprite', function (self, other)
    if other:get_type() == 'fire' then
        self:light()
    end
end)
