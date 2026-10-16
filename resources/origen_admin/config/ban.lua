Config.Ban = {}
Config.Ban.RequireLicenseToJoin = false
Config.Ban.RequiredIdentifiers = {
    license2 = true,
    steam = false,
    fivem = false,
    discord = true,
}

Config.Whitelist = {
    --[[ Con esto en true solo entra quien tenga su Discord ID en la tabla
         discord_whitelist; al resto se le enseña "No tienes whitelist para
         entrar".

         Para dar acceso: comando `wl` desde la consola o siendo admin
         (server/whitelist_comandos.lua). Lo normal es "wl <idJugador>" con la
         persona conectada, que coge su Discord de la propia conexion. ]]
    enable = false,
    roleID = "1109923864458309703", -- Whitelist Aceptada
}