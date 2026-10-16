Custom.Notify = function(text, type, length)
    if Config.Framework == 'qb-core' then
        Framework.Functions.Notify(text, type, length)
    elseif Config.Framework == 'esx' then
        Framework.ShowNotification(text, type, length)
    else
        -- Add your custom notification here
    end
end

Custom.DrawText = function(text, key)
    if Config.Drawtext == 'qb-core' then
        exports['qb-core']:DrawText('['..key..'] - '..text)
    elseif Config.Drawtext == 'esx_textui' then
        Framework.TextUI('['..key..'] - '..text)
    elseif Config.Drawtext == 'ox_lib' then
        lib.showTextUI('['..key..'] - '..text)
    else
        -- Add your custom draw text here
    end
end

Custom.HideText = function()
    if Config.Drawtext == 'qb-core' then
        exports['qb-core']:HideText()
    elseif Config.Drawtext == 'esx_textui' then
        Framework.HideUI()
    elseif Config.Drawtext == 'ox_lib' then
        lib.hideTextUI()
    else
        -- Add your custom hide text here
    end
end