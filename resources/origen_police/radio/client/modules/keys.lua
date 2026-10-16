RegisterKeyMapping('+radiotalk_police_org', Config.Commands.TalkRadio.description, 'keyboard', Config.Commands.TalkRadio.key)

RegisterCommand("+radiotalk_police_org", function()
    StartTalkRadio()
end, false)

RegisterCommand("-radiotalk_police_org", function()
    StopTalkRadio()
end, false)

RegisterCommand("+r_police_keybind", function(_, args)
    local key = args[1] and tostring(args[1]):upper()
    if key and (Radio.Binds[key] or Radio.Binds[args[1]]) then
        local action = Radio.Binds[key] or Radio.Binds[args[1]]
        if Config.BindFreqs and Config.BindFreqs[action] then
            StartTalkRadio(Config.BindFreqs[action])
        else
            DoAction(action)
        end
    end
end, false)

RegisterCommand("-r_police_keybind", function(_, args)
    local key = args[1] and tostring(args[1]):upper()
    if key and (Radio.Binds[key] or Radio.Binds[args[1]]) then
        local action = Radio.Binds[key] or Radio.Binds[args[1]]
        if Config.BindFreqs and Config.BindFreqs[action] then
            StopTalkRadio()
        end
    end
end, false)