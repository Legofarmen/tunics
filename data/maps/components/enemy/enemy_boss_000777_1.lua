local map, data = ...

local util = require 'lib/util'

local door_names = {}

map:include(0, 0, 'components/door/door_open_north_200000_1', {door_names=door_names})

for _, name in util.pairs_by_keys(door_names) do
    map:open_doors(name)
end

