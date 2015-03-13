local List = {}

function List.intermingle(a, b)
    local result = {}
    local i = 1
    local j = 1
    local total = #a + #b
    while total > 0 do
        if math.random(total) <= #a - i + 1 then
            table.insert(result, a[i])
            i = i + 1
        else
            table.insert(result, b[j])
            j = j + 1
        end
        total = total - 1
    end
    return result
end

function List.concat(a, b)
    for _, value in ipairs(b) do
        table.insert(a, value)
    end
    return a
end

function List.shuffle(array)
    for i, _ in ipairs(array) do
        local j = math.random(#array)
        array[i], array[j] = array[j], array[i]
    end
end

return List
