local family_tier = {
    cave = 1,
    brick = 2,
    smoothbrick = 4,
    ice = 4,
    ganon = 6,
    house = 10,
}

local family_music = {
    brick = {
        'dungeon_dark',
        'dungeon_light',
    },
    smoothbrick = {
        'dungeon_castle',
        'dungeon_dark',
        'dungeon_light',
    },
    cave = {
        'dungeon_cave',
        'dungeon_dark',
        'dungeon_light',
    },
    ice = {
        'dungeon_castle',
        'dungeon_dark',
        'dungeon_light',
    },
    house = {
        'dungeon_castle',
        'dungeon_village',
    },
    ganon = {
        'dungeon_castle',
        'dungeon_dark',
    },
}

local tier_complexity = {
    [1] = {
        keys=1,
        culdesacs=0,
        fairies=0,
        max_heads=3,
    },
    [3] = {
        keys=2,
        culdesacs=1,
        fairies=0,
        max_heads=4,
    },
    [5] = {
        keys=3,
        culdesacs=2,
        fairies=1,
        max_heads=5,
    },
    [10] = {
        keys=4,
        culdesacs=3,
        fairies=1,
        max_heads=6,
    },
}

local family_destructibles = {
    smoothbrick = {
        pot = 'entities/vase',
        stone1 = 'entities/stone_white',
        stone2 = 'entities/stone_black',
    },
    house = {
        pot = 'entities/vase',
        stone1 = 'entities/stone_white',
        stone2 = 'entities/stone_black',
    },
    brick = {
        pot = 'entities/vase_skull',
        stone1 = 'entities/stone_white_skull',
        stone2 = 'entities/stone_black_skull',
    },
    cave = {
        pot = 'entities/vase_skull',
        stone1 = 'entities/stone_white_skull',
        stone2 = 'entities/stone_black_skull',
    },
    ganon = {
        pot = 'entities/vase_skull',
        stone1 = 'entities/stone_white_skull',
        stone2 = 'entities/stone_black_skull',
    },
    ice = {
        pot = 'entities/vase_skull',
        stone1 = 'entities/stone_white_skull',
        stone2 = 'entities/stone_black_skull',
    },
}

local enemy_tier = {
    tentacle = 1,
    keese = 1,
    rat = 1,
    simple_green_soldier = 1,
    bari_blue = 2,
    rope = 2,
    crab = 2,
    green_knight_soldier = 2,
    bari_red = 3,
    poe = 3,
    blue_knight_soldier = 3,
    red_knight_soldier = 4,
    snap_dragon = 4,
    ropa = 4,
    hardhat_beetle_blue = 4,
    gibdo = 5,
    red_hardhat_beetle = 6,
    red_helmasaur = 6,
    bubble = 6,
}

local function choose_family(current_tier, rng)
    local mode = 'past'
    local families = {}
    for f, tier in pairs(family_tier) do
        if tier == current_tier then
            if mode == 'past' then
                families = {}
                mode = 'current'
            end
            table.insert(families, f)
        elseif tier <= current_tier and mode == 'past' then
            table.insert(families, f)
        end
    end
    local i, family = rng:ichoose(families)
    return family
end

local function get_enemies(current_tier)
    local enemies = {}
    for enemy, tier in pairs(enemy_tier) do
        if tier <= current_tier then
            enemies[enemy] = tier
        end
    end
    return enemies
end

function get_complexity(current_tier)
    local max = 0
    local result = nil
    for tier, complexity in pairs(tier_complexity) do
        if tier <= current_tier and tier > max then
            max = tier
            result = complexity
        end
    end
    return result
end

local mappings = {}

function mappings.choose(current_tier, rng)
    local family = choose_family(current_tier, rng:refine('family'))
    local _, music = rng:refine('music'):ichoose(family_music[family])
    local destructibles = family_destructibles[family]
    local enemies = get_enemies(current_tier)
    local complexity = get_complexity(current_tier)
    return {
        family=family,
        music=music,
        destructibles=destructibles,
        enemies=enemies,
        complexity=complexity,
    }
end

return mappings
