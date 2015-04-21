local util = {}

function util.filter_keys(table, keys)
    local result = {}
    for _, key in ipairs(keys) do
        if table[key] then result[key] = table[key] end
    end
    return result
end

function util.pairs_by_keys (t, f)
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

function util.values_by_keys (t, f)
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

function util.oct(s)
    local i = tonumber(s, 8)
    return i
end

function util.fromoct(n)
    return string.format("%06o", n)
end

function util.table_lines(prefix, data, f)
    if not f then
        local zentropy = require 'lib/zentropy'
        f = zentropy.debug
    end
    if type(data) == 'table' then
        local n = 0
        for key, value in util.pairs_by_keys(data) do
            util.table_lines(prefix .. '.' .. key, value, f)
            n = n + 1
        end
        if n == 0 then
            f(string.format('%s = {}', prefix))
        end
    elseif type(data) ~= 'function' then
        f(string.format('%s = %s', prefix, data))
    end
end

function util.table_string(prefix, data)
    local lines = {}
    util.table_lines(prefix, data, function (line)
        table.insert(lines, line)
    end)
    return util.ijoin("\n", lines)
end

function util.ijoin(sep, t)
    if #t == 0 then
        return ''
    elseif #t == 1 then
        return t[1]
    else
        local res = tostring(t[1])
        for i = 2, #t do
            res = res .. sep .. tostring(t[i])
        end
        return res
    end
end

return util
