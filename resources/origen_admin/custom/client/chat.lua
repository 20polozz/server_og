local recentSCMessages = {}
local SC_DEDUP_WINDOW = 1000 -- ms

RegisterNetEvent('origen_admin:client:chatMessage', function(message)
    -- Deduplicate SC messages to prevent showing the same message twice
    local msgKey = tostring(message.args and table.concat(message.args, '|') or '')
    local now = GetGameTimer()

    if recentSCMessages[msgKey] and (now - recentSCMessages[msgKey]) < SC_DEDUP_WINDOW then
        return -- Skip duplicate message received within the dedup window
    end

    recentSCMessages[msgKey] = now

    -- Cleanup old entries periodically
    for key, ts in pairs(recentSCMessages) do
        if (now - ts) > SC_DEDUP_WINDOW * 2 then
            recentSCMessages[key] = nil
        end
    end

    exports.origen_chat:addMessage(message)
end)
