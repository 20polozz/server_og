Config.UploadMethod = 'fivemanage' -- discord | fivemanage | custom

-- MAY BE YOU'RE LOOKING FOR THE config/logs/logs.lua FILE AND NOT THIS ONE
-- DON'T EDIT BELOW THIS LINE IF YOU DON'T KNOW WHAT YOU'RE DOING PLEASE

Config.Fields = {
    ['discord'] = 'files[]',
    ['fivemanage'] = 'image',
    ['custom'] = ''
}

function GetCustomUrlFromResponse(resp)
    local function ShowErrorPhoto(response)
        print("Error taking photo: " .. tostring(response and json.encode(response) or "nil") .. " - " .. "Probably you have to check your FiveManage API key or upload URL")
    end
    local retval = false
    if not resp or type(resp) ~= "table" then
        ShowErrorPhoto(resp)
        return false
    end

    -- Direct URL check (FiveManage, custom endpoints, or nested data)
    if resp.url and type(resp.url) == "string" and resp.url ~= "" then
        return resp.url
    elseif resp.data and type(resp.data) == "table" and resp.data.url then
        return resp.data.url
    elseif resp.data and type(resp.data) == "string" and string.match(resp.data, "^https?://") then
        return resp.data
    elseif resp.link and type(resp.link) == "string" and resp.link ~= "" then
        return resp.link
    elseif resp.imageUrl and type(resp.imageUrl) == "string" then
        return resp.imageUrl
    end

    -- Discord attachments fallback
    if resp['attachments'] and type(resp['attachments']) == "table" and resp.attachments[1] and resp.attachments[1].url then
        return resp.attachments[1].url
    end

    ShowErrorPhoto(resp)
    return retval
end