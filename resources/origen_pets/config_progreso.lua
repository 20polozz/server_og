--[[ ── Niveles, especialidades y lo que la mascota hace por su cuenta ───────

     Viene de murderface-pets, que era el sistema de mascotas de Nacion: se
     retiro el 13/10 y lo que tenia de mas se trajo aqui. Las cifras son las
     suyas a proposito, para que las mascotas que ya tenian nivel alli lo
     conserven tal cual. El codigo va en server/progreso.lua y client/vida.lua. ]]
Config.Progreso = {
    nivelMaximo = 50,

    --- La experiencia que da cada cosa. `pasivo` es por minuto con la mascota
    --- en la calle: sube de nivel solo con ir contigo.
    xp = {
        pasivo    = 210,
        comer     = 20,
        beber     = 15,
        acariciar = 25,
        truco     = 15,
        pelota    = 15,
        defender  = 35,
        rastrear  = 30,
    },

    --- Segundos entre dos premios por lo mismo, para que no se pueda farmear.
    esperas = {
        acariciar = 60,
        truco     = 15,
        pelota    = 30,
        defender  = 30,
        rastrear  = 30,
    },

    --- A partir de que nivel sabe hacer cada cosa. Lo que no esta aqui, desde
    --- el principio.
    desde = {
        tumbar       = 5,
        guardia      = 5,
        patita       = 10,
        especialidad = 20,
    },

    --- A que velocidad te sigue segun el nivel.
    velocidad = {
        { nivel = 0,  valor = 3.0 },
        { nivel = 10, valor = 4.0 },
        { nivel = 25, valor = 5.0 },
    },

    titulos = {
        { hasta = 5,  nombre = 'Cachorro' },
        { hasta = 15, nombre = 'Entrenado' },
        { hasta = 30, nombre = 'Veterano' },
        { hasta = 49, nombre = 'Élite' },
        { hasta = 50, nombre = 'Legendario' },
    },

    --[[ Las especialidades: se elige UNA al llegar al nivel de `desde` y no se
         cambia. `guardian` solo sirve a las razas que pelean. ]]
    especialidades = {
        guardian   = { nombre = 'Guardián',   texto = 'Pelea mejor y aguanta más.', vidaExtra = 50 },
        rastreador = { nombre = 'Rastreador', texto = 'Marca a las personas y animales que hay cerca.', radio = 50.0, dura = 10000 },
        companero  = { nombre = 'Compañero',  texto = 'Gana un 25 % más de experiencia y se recupera sola.', xp = 1.25 },
    },

    --- Las razas que pelean muerden a quien te pegue sin que se lo mandes.
    defensaAutomatica = true,

    --[[ Lo que hace sola mientras te sigue. `cada` son los segundos entre dos
         ocurrencias; no es un reloj fijo, lleva un tercio de azar. ]]
    ambiente = {
        cada = 25,
        ladrarAExtranos = 5.0,   -- metros; 0 lo apaga
        sustoDisparos = 30.0,    -- las pequeñas se encogen con tiros a esta distancia
    },

    --- La correa: lo que mide. Con ella puesta no se separa mas que eso.
    correa = { largo = 4.0 },
}

--- La experiencia TOTAL que hace falta para estar en un nivel.
function Config.Progreso.XpDeNivel(nivel)
    if nivel <= 0 then return 0 end
    return 75 + nivel * nivel * 15
end

--- El nivel que corresponde a una experiencia.
function Config.Progreso.NivelDe(xp)
    xp = tonumber(xp) or 0
    local nivel = 0
    while nivel < Config.Progreso.nivelMaximo and xp >= Config.Progreso.XpDeNivel(nivel + 1) do
        nivel = nivel + 1
    end
    return nivel
end

function Config.Progreso.Titulo(nivel)
    for _, t in ipairs(Config.Progreso.titulos) do
        if nivel <= t.hasta then return t.nombre end
    end
    return 'Legendario'
end

function Config.Progreso.Velocidad(nivel)
    local valor = Config.Progreso.velocidad[1].valor
    for _, t in ipairs(Config.Progreso.velocidad) do
        if nivel >= t.nivel then valor = t.valor end
    end
    return valor
end
