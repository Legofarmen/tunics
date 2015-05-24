local filler = {}

local zentropy = require 'lib/zentropy'

function filler.init(map, data)
    zentropy.assert(data.room, 'property not found: data.room')

    for entity in map:get_entities('enemy') do
        data.room:inject_enemy(entity, data.rng:refine(entity:get_name()))
    end

    for entity in map:get_entities('pot_') do
        zentropy.inject_pot(entity, data.rng:refine(entity:get_name()))
    end
end

return filler
