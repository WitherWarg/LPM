function table.merge(...)
    local result = {}

    for _, t in ipairs({...}) do
        for key, value in pairs(t) do
            result[key] = value
        end
    end

    return result
end

function table.len(t)
    local i = 0
    for _, _ in pairs(t) do
        i = i + 1
    end
    return i
end

function table.print(t)
    for key, value in pairs(t) do
        print(key .. ' -> ' .. tostring(value))
    end
end