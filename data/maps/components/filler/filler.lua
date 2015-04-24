local filler = {}

local zentropy = require 'lib/zentropy'

function filler.init(map, data)
    for entity in map:get_entities('enemy') do
        zentropy.inject_enemy(map:get_entity('enemy'), data.rng:refine(entity:get_name()))
    end
    for entity in map:get_entities('pot_') do
        zentropy.inject_pot(entity, data.rng:refine(entity:get_name()))
    end
end

return filler
