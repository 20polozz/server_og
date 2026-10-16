function RandomStr(length)
    if length <= 0 then return '' end
    local chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    local result = ''
    for i = 1, length do
        local rand = math.random(1, #chars)
        result = result .. string.sub(chars, rand, rand)
    end
    return result
end

function RandomInt(length)
    if length <= 0 then return '' end
    local result = ''
    for i = 1, length do
        result = result .. math.random(0, 9)
    end
    return result
end

function GenerateGangId()
    return "gang_" .. RandomStr(3) .. RandomInt(4) .. RandomStr(2)
end

function GenerateMemberId()
    return "member_" .. RandomInt(8)
end
