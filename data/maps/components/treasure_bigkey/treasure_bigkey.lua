local treasure = {}

function treasure.init(map, data)

    local switch = map:get_entity('switch')

    zentropy.inject_big_chest(map:get_entity('chest'), data)

    for entity in map:get_entities('enemy') do
        zentropy.inject_enemy(entity, data.rng:refine(entity:get_name()))
    end

end

return treasure
