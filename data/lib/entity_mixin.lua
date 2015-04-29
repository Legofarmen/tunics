local entity_mixin = {}

local directions = {
    3, -- nw
    1, -- ne
    2, -- n
    5, -- sw
    4, -- w
    -1,
    3, -- nw
    7, -- se
    -1,
    0, -- e
    1, -- ne
    6, -- s
    5, -- sw
    7, -- se
    -1,
    [0] = -1,
}

function entity_mixin.mixin(mt)

    function mt:get_obstacle_direction8()
        local bits = 0
        if self:test_obstacles(-1, -1) then
            bits = bits + 1 -- nw
        end
        if self:test_obstacles( 1, -1) then
            bits = bits + 2 -- ne
        end
        if self:test_obstacles(-1,  1) then
            bits = bits + 4 -- sw
        end
        if self:test_obstacles( 1,  1) then
            bits = bits + 8 -- se
        end
        return directions[bits]
    end

end

return entity_mixin
