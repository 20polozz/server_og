function GetTypeSize(a) -- return the size of the variable in bytes
    if type(a) == "number" then
        return 8
    elseif type(a) == "string" then
        return #a
    elseif type(a) == "table" then
        local size = 0
        for k, v in pairs(a) do
            size = size + GetTypeSize(k) + GetTypeSize(v)
        end
        return size
    else
        return 0
    end
end