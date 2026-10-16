Config.UploadMethod = 'discord' -- discord | fivemanage | custom
-- fivemanage only work for image logs, in this case the only image log is the TakeScreenshot
-- we don't give support for add custom upload methods, if you want to add a custom upload method you need to do it by yourself

-- SECURITY: Config.Logs has been moved to config/server/logs.lua (server-only)
-- DO NOT put webhook URLs in this file as it is shared with clients

-- DON'T EDIT BELOW THIS LINE IF YOU DON'T KNOW WHAT YOU'RE DOING!!!

Config.Fields = {
    ['discord'] = 'files[]',
    ['fivemanage'] = 'image',
    ['custom'] = ''
}

function GetCustomUrlFromResponse(resp)
    -- Thats the function that will return the URL of the image when the upload method is set to "custom"
end