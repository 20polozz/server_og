function SplitStr(str, delimiter)
    local result = {}
    local from = 1
    local delim_from, delim_to = string.find(str, delimiter, from)
    repeat
        local last_pos = delim_from and delim_from - 1 or #str
        result[#result + 1] = string.sub(str, from, last_pos)
        from = delim_to and delim_to + 1 or nil
        if from then
            delim_from, delim_to = string.find(str, delimiter, from)
        end
    until not from
    return result
end
