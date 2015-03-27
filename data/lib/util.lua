local Util = {}

function Util.filter_keys(table, keys)
    local result = {}
    for _, key in ipairs(keys) do
        if table[key] then result[key] = table[key] end
    end
    return result
end

function Util.pairs_by_keys (t, f)
    local a = {}
    for n in pairs(t) do table.insert(a, n) end
    table.sort(a, f)
    local i = 0      -- iterator variable
    local iter = function ()   -- iterator function
        i = i + 1
        if a[i] == nil then return nil
        else return a[i], t[a[i]]
        end
    end
    return iter
end

function Util.values_by_keys (t, f)
    local a = {}
    for n in pairs(t) do table.insert(a, n) end
    table.sort(a, f)
    local i = 0      -- iterator variable
    local iter = function ()   -- iterator function
        i = i + 1
        if a[i] == nil then return nil
        else return t[a[i]]
        end
    end
    return iter
end

function Util.oct(s)
    local i = tonumber(s, 8)
    return i
end

function Util.fromoct(n)
    return string.format("%06o", n)
end

return Util
