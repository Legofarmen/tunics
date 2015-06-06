local treasure = {}

function treasure.init(map, data)

    zentropy.assert(data.room, 'missing property: data.room')

    zentropy.inject_big_chest(map:get_entity('chest'), data)

    for entity in map:get_entities('enemy') do
        data.room:inject_enemy(entity, data.rng:refine(entity:get_name()))
    end

    for entity in map:get_entities('pot_') do
        zentropy.inject_pot(entity, data.rng:refine(entity:get_name()))
    end

    for placeholder in map:get_entities('stone_') do
        data.room:inject_stone(placeholder)
    end

end

return treasure
