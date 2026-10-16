Utils = {}

function Utils.FormatBusinessName(label)
    return (label:lower():gsub('%s+', '_'))
end

function Utils.Debugger(...)
    if Config.Debug then print('[^6DEBUG^0]', ...) end
end