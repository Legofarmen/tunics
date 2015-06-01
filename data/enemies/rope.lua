local enemy = ...

-- Enemy: rope

enemy:set_life(1)
enemy:set_damage(1)

local sprite = enemy:create_sprite("enemies/rope")

-- The enemy was stopped for some reason and should restart.
function enemy:on_restarted()
   local m = sol.movement.create("straight")
   m:start(self)
   self:go()
end

-- An obstacle is reached: try a new direction
function enemy:on_obstacle_reached()
    self:go()
end

-- Stop for a while, then keep going or change direction
function enemy:on_movement_finished()
    sprite:set_animation("shaking")
    
    sol.timer.start(self, 600, function() 
    self:go()
    if going_hero then 
        self:go()
    else
        self:go_hero()
    end
    local hero = self:get_map():get_hero()
        local _, _, layer = self:get_position()
        local _, _, hero_layer = hero:get_position()
        local near_hero =
            layer == hero_layer
            and self:get_distance(hero) < 128
            and self:is_in_same_region(hero)

        if near_hero then
            self:go_hero()
        else
            self:go()
        end
    
    end)
end

-- Makes the rat walk towards a direction.
function enemy:go()

    -- Set the sprite.
    sprite:set_animation("walking")
    local direction = sprite:get_direction()
 
    local directions = { ((direction + 3) % 4), ((direction + 1) % 4), ((direction) % 4) }
    local direction4 = directions[math.random(3)]

    sprite:set_direction(direction4)
  
    -- Set the movement.
    local m = self:get_movement()
    m:set_speed(24)
    m:set_max_distance(32 + math.random(64))
    m:set_angle(direction4 * math.pi / 2)
    
    
end

function enemy:go_hero()
    -- Set the sprite.
    sprite:set_animation("running")
    
    local t = sol.movement.create("target")
    t:set_target(self:get_map():get_hero())
    t:start(self)
    direction4 = t:get_direction4()
    t:stop()
    
    sprite:set_direction(direction4)
  
    -- Set the movement.
    local m = sol.movement.create("straight")
    m:set_speed(64)
    m:set_max_distance(64 + math.random(128))
    m:set_angle(direction4 * math.pi / 2)
    m:start(self)
    
    
end
