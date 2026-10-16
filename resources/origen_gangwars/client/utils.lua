Utils = {}

Utils.capitalize = function(str)
    if not str or str == "" then
        return str
    end
    return str:sub(1, 1):upper() .. str:sub(2):lower()
end
