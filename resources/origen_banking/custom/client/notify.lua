--@param text Text to show
--@param key Key to show
Custom.DrawText = function(text, key)
    lib.showTextUI('['..key..'] - '..text)
end

Custom.HideText = function()
    lib.hideTextUI()
end