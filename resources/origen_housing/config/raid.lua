Config.Raid = {
    enabled = true, -- Enable or disable the raid option
    item = 'stormram', -- Item needed to raid the house
    allowedJobs = {
        ['police'] = true,
        ['sheriff'] = true,
        ['fib'] = true,
    },
    triggerAlarm = true, -- Trigger the alarm when the house is raided
    skillcheck = true,
    --[[ El minijuego de echar la puerta abajo: uno de origen_minijuegos
         (clave de Config.Nuevos de ese recurso), con su dificultad y el
         rotulo del panel. Si origen_minijuegos no esta arrancado se usa el
         skillcheck de ox_lib de antes (custom/client/raid.lua). ]]
    minijuego = { juego = 'pines', dificultad = 'easy', titulo = 'Echar la puerta abajo' },
    animation = {
        dict = 'melee@unarmed@streamed_core',
        anim = 'kick_close_a'
    }
}