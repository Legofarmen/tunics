local Class = require 'lib/class'
local MWC = require 'lib/mwc_rng'

local Prng = Class:new()

function Prng.from_seed(seed)
    return Prng:new{mwc=MWC.MakeGenerator(nil, seed), seed=seed}
end

function Prng:random(a, b)
    if not self.mode then
        self.mode = 'number'
    elseif self.mode ~= 'number' then
        error('illegal state')
    end

    local bits = self.mwc()
    if a then
        if not b then
            a, b = 1, a
        end

        return a + bits % (b - a + 1)
    else
        return bits * 2.328306e-10
    end
end

function Prng:create()
    if not self.mode then
        self.mode = 'factory'
    elseif self.mode ~= 'factory' then
        error('illegal state')
    end
    local bits = self.mwc()
    return Prng.from_seed(bits)
end

return Prng
