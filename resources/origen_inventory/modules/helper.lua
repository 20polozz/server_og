Helper = {}
Helper.getItemName = function(name)
    local replacements = {
        ['á'] = 'a',
        ['é'] = 'e',
        ['í'] = 'i',
        ['ó'] = 'o',
        ['ú'] = 'u',
        ['ü'] = 'u',
        ['ñ'] = 'n',
        ['Á'] = 'a',
        ['É'] = 'e',
        ['Í'] = 'i',
        ['Ó'] = 'o',
        ['Ú'] = 'u',
        ['Ü'] = 'u',
        ['Ñ'] = 'n'
    }

    local processed_name = string.lower(name)

    for original, replacement in pairs(replacements) do
        processed_name = string.gsub(processed_name, original, replacement)
    end

    processed_name = string.gsub(processed_name, '%s+', '_')

    return processed_name
end

local function GetLineCountAndMaxLenght(text)
    local count = 0
    local maxLenght = 0
    for line in text:gmatch("([^\n]*)\n?") do
        count = count + 1
        local lenght = string.len(line)
        if lenght > maxLenght then maxLenght = lenght end
    end
    return count, maxLenght
end
Helper.draw3dText = function(data)
    SetTextScale(0.30, 0.30)
    SetTextFont(0)
    SetTextProportional(1)
    SetTextColour(0, 0, 0, 255)
    SetTextEntry("STRING")
    SetTextCentre(true)
    local totalLenght = string.len(data.text)
    local textMaxLenght = data.textMaxLenght or 99 -- max 99
    local text = totalLenght > textMaxLenght and data.text:sub(1, totalLenght - (totalLenght - textMaxLenght)) or data.text
    AddTextComponentString(text)
    SetDrawOrigin(data.coords.x, data.coords.y, data.coords.z, 0)
    DrawText(0.0, 0.0)
    local count, lenght = GetLineCountAndMaxLenght(text)

    local padding = 0.005
    local heightFactor = (count / 43) + padding
    local weightFactor = (lenght / 100) + padding

    local height = (heightFactor / 2) - padding / 2
    local width = (weightFactor / 2) - padding / 2

    DrawRect(0.0, height, width, heightFactor, 220, 221, 224, 235)
    ClearDrawOrigin()
end

Helper.tableCount = function(tbl)
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end