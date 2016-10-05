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

    function mt:bounce_enemies()
        self_x, self_y = self:get_position()
        self_ox, self_oy = self:get_origin()
        self_w, self_h = self:get_size()

        to_kill = {}
        for enemy in self:get_map():get_entities('') do
            if enemy:get_type() == 'enemy' and enemy:overlaps(self) then
                enemy_x, enemy_y = enemy:get_position()
                enemy_ox, enemy_oy = enemy:get_origin()
                enemy_w, enemy_h = enemy:get_size()

                if enemy_x == self_x and enemy_y == self_y then
                    enemy_dx = 0
                    enemy_dy = 0
                elseif enemy_x == self_x then
                    if enemy_y < self_y then
                        enemy_yb = self_y - self_oy - enemy_h + enemy_oy
                    else
                        enemy_yb = self_y - self_oy + self_h + enemy_oy
                    end
                    enemy_dx = 0
                    enemy_dy = enemy_yb - enemy_y
                elseif enemy_y == self_y then
                    if enemy_x < self_x then
                        enemy_xb = self_x - self_ox - enemy_w + enemy_ox
                    else
                        enemy_xb = self_x - self_ox + self_w + enemy_ox
                    end
                    enemy_dx = enemy_xb - enemy_x
                    enemy_dy = 0
                else
                    if enemy_x < self_x then
                        enemy_xa = self_x - self_ox - enemy_w + enemy_ox
                    else
                        enemy_xa = self_x - self_ox + self_w + enemy_ox
                    end
                    enemy_dxa = enemy_xa - enemy_x
                    enemy_dya = math.floor(enemy_dxa * (enemy_y - self_y) / (enemy_x - self_x) + 0.5)

                    if enemy_y < self_y then
                        enemy_yb = self_y - self_oy - enemy_h + enemy_oy
                    else
                        enemy_yb = self_y - self_oy + self_h + enemy_oy
                    end
                    enemy_dyb = enemy_yb - enemy_y
                    enemy_dxb = math.floor(enemy_dyb * (enemy_x - self_x) / (enemy_y - self_y) + 0.5)

                    if enemy_dxa * enemy_dxa + enemy_dya * enemy_dya <= enemy_dyb * enemy_dyb + enemy_dxb * enemy_dxb then
                        enemy_dx = enemy_dxa
                        enemy_dy = enemy_dya
                    else
                        enemy_dx = enemy_dxb
                        enemy_dy = enemy_dyb
                    end
                end

                if enemy:test_obstacles(enemy_dx, enemy_dy) then
                    enemy:set_life(0)
                else
                    enemy:set_position(enemy_x + enemy_dx, enemy_y + enemy_dy - 1)
                    enemy:restart() -- work around solarus bug (fixed in 1.5)
                end
            end
        end
    end

end

return entity_mixin
