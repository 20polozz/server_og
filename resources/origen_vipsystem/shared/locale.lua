if lib and lib.locale then
    while not Config or not Config.Language do
        Wait(100)
    end
    lib.locale(Config and Config.Language or nil)
end
