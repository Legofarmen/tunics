local item = ...

-- When it is created, this item creates another item randomly chosen
-- and then destroys itself.

local drop_rate = 1/6

-- Probabilities are proportional
local probabilities = {
    [{ "heart", 1}]        = 24,   -- Heart.
    [{ "fairy", 1}]        = 2,    -- Fairy.
    [{ "magic_flask", 1 }] = 12,   -- Small magic jar.
    [{ "magic_flask", 2 }] = 3,    -- Big magic jar.
    [{ "bomb", 1 }]        = 8,    -- 1 bomb.
    [{ "bomb", 2 }]        = 5,    -- 3 bombs.
    [{ "bomb", 3 }]        = 2,    -- 8 bombs.
    [{ "arrow", 1 }]       = 8,    -- 1 arrow.
    [{ "arrow", 2 }]       = 5,    -- 5 arrows.
    [{ "arrow", 3 }]       = 2,    -- 10 arrows.
}

function item:on_pickable_created(pickable)

    local treasure_name, treasure_variant = self:choose_random_item()
    if treasure_name ~= nil then
        local map = pickable:get_map()
        local x, y, layer = pickable:get_position()
        map:create_pickable{
            layer = layer,
            x = x,
            y = y,
            treasure_name = treasure_name,
            treasure_variant = treasure_variant,
        }
    end
    pickable:remove()
end

-- Returns an item name and variant.
function item:choose_random_item()
    local name, variant
    if math.random() < drop_rate then

        local total = 0
        local choose = function(weight)
            total = total + weight
            return total * math.random() <= weight
        end

        for key, probability in pairs(probabilities) do
            if self:get_game():get_item(key[1]):is_obtainable() and choose(probability) then
                name, variant = key[1], key[2]
            end
        end
    end

    return name, variant
end
