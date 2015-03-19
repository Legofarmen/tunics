local map, data = ...   

local Util = require 'lib/util'

bit32 = bit32 or bit

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
    sprite="entities/chest",
    layer=1,
    x=x,
    y=y,
    treasure_name=data.item_name,
    treasure_savegame_variable=data.name,
}
