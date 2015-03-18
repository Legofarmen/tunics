local map,data = ...

local Util = require 'lib/util'

local x
local y

if bit32.band(data.section, Util.oct('700')) ~= 0 then
    y = 53
elseif bit32.band(data.section, Util.oct('070')) ~= 0 then
    y = 125
elseif bit32.band(data.section, Util.oct('007')) ~= 0 then
    y = 181
end

if bit32.band(data.section, Util.oct('444')) ~= 0 then
    x = 72
elseif bit32.band(data.section, Util.oct('222')) ~= 0 then
    x = 160
elseif bit32.band(data.section, Util.oct('111')) ~= 0 then
    x = 248
end

map:create_chest{
    sprite = "entities/big_chest",
    opening_method = "interaction_if_savegame_variable",
    opening_condition = "big_key",
    layer=1,
    x=x,
    y=y,
    treasure_name=data.item_name,
    treasure_savegame_variable=data.name,
}
map:create_dynamic_tile {
pattern = "barrier.1",
x=x - 16,
y=y - 21,
width=32,
height=24,
layer=1,
enable_at_start=true,
}
