local treasure = {}

function treasure.init(map, data)

    local chest = map:get_entity('chest')
    local switch = map:get_entity('switch')
    local enemy = map:get_entity('enemy')

    if enemy then
        zentropy.inject_enemy(enemy, data.rng:refine('enemy'))
    end
end

return treasure

