local filler = {}

local zentropy = require 'lib/zentropy'

function filler.init(map, data)
    if map:has_entity('enemy') then
        zentropy.inject_enemy(map:get_entity('enemy'), data.rng:refine('enemy'))
    end
end

return filler
