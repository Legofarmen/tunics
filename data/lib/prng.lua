require 'lib/CRC32'
local Class = require 'lib/class'
local MWC = require 'lib/mwc_rng'
local util = require 'lib/util'

local Prng = Class:new()

function Prng:new(o)
    assert(o.seed == bit32.band(o.seed, 2^31-1))
    return Class.new(self, o)
end

function Prng:random(a, b)
    if not self.mwc then
        self.mwc = MWC.MakeGenerator(self.seed, bit32.bxor(self.seed, 2^31-1))
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

function Prng:augment_string(s)
    local bits = bit32.band(CRC32.Hash(s), 2^31-1)
    return Prng:new{ seed=bit32.bxor(self.seed, bits) }
end

function Prng:ichoose(t, w)
    w = w or function () return 1 end
    local j = nil
    local total = 0
    if not self.mwc then
        self.mwc = MWC.MakeGenerator(self.seed, bit32.bxor(self.seed, 2^31-1))
    end
    for i, value in ipairs(t) do
        local weight = w(i, value)
        total = total + weight
        if total * 2.328306e-10 * self.mwc() <= weight then
            j = i
        end
    end
    if j then
        return j, t[j]
    else
        return
    end
end

function Prng:choose(t, w)
    w = w or function () return 1 end
    local j = nil
    local total = 0
    if not self.mwc then
        self.mwc = MWC.MakeGenerator(self.seed, bit32.bxor(self.seed, 2^31-1))
    end
    for key, value in util.pairs_by_keys(t) do
        local weight = w(key, value)
        total = total + weight
        if total * 2.328306e-10 * self.mwc() <= weight then
            j = key
        end
    end
    if j then
        return j, t[j]
    else
        return
    end
end

return Prng
