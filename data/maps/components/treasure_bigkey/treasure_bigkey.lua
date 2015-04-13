local treasure = {}

function treasure.init(map, data)

    local switch = map:get_entity('switch')
    local enemy = map:get_entity('enemy')

    zentropy.inject_big_chest(map:get_entity('chest'), data)

    if enemy then
        zentropy.inject_enemy(enemy, data.rng:refine('enemy'))
    end
end

return treasure

