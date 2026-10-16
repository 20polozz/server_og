--[[ ── Mascotas · el estado ─────────────────────────────────────────────────

     Un solo sitio donde vive lo que sabe el cliente: que mascotas tienes, cual
     esta fuera, que le has mandado hacer y que ped es en el juego.

     Va aparte de mascota.lua porque lo leen tres ficheros —el ped, el laser y
     el panel— y con el estado repartido entre ellos acaba habiendo tres
     versiones de "cual esta fuera" que se separan a la primera. ]]

Mascotas = {
    --- Todas las tuyas, tal y como las manda el servidor. Se refresca al abrir
    --- el panel y cada vez que algo cambia.
    lista = {},

    --- La que esta en la calle ahora mismo, con su ped. nil si no hay ninguna.
    fuera = nil,

    --[[ Comida y bebida de la que esta fuera, mientras esta fuera.

         Se llevan aqui y no en la fila de la mascota porque bajan solas cada
         pocos segundos: escribir eso en la base de datos cada vez seria una
         escritura en disco por punto. Se guarda al recogerla y al morir. ]]
    comida = 100,
    bebida = 100,

    --- Que le has mandado: 'seguir', 'sentar', 'quieto', 'guardia'.
    --- Atacar no es un modo: es una orden que acaba, y al acabar vuelve a
    --- guardia si estaba en guardia, o a seguir.
    orden = 'seguir',

    --- El ped, cuando lo hay.
    ped = nil,
}

--[[ La raza de una mascota, con su respaldo. Igual que en el servidor: manda el
     catalogo de la base de datos --que es lo que edita un admin desde el panel--
     y solo si ahi no esta se cae al config y, en ultimo termino, a la raza por
     defecto.

     Mirar primero el catalogo no es un adorno: una raza creada desde el panel no
     esta en config.lua, asi que con solo el config se caia siempre en la raza por
     defecto y la mascota salia siendo otro perro --el modelo, la vida y el alijo
     del respaldo-- por mucho que en la tienda pusiera otra cosa.

     CatalogoRazas lo rellena client/tienda.lua con lo que manda el servidor al
     entrar y cada vez que un admin lo cambia; hasta que llega esta vacio y aqui
     se sigue tirando del config, que es lo que habia. ]]
function Mascotas.Raza(clave)
    return (CatalogoRazas and CatalogoRazas[clave])
        or Config.Razas[clave]
        or Config.Razas[Config.RazaPorDefecto]
end

--[[ Traer un modelo de ped a memoria. Devuelve el hash, o nil si no se pudo.

     Esto es lo que hace origen_quests --client/client.lua y quests2.lua-- y esta
     copiado de ahi a proposito, porque el problema es el mismo: los modelos los
     escribe un admin en un panel, asi que "ese modelo no existe" es un caso
     corriente y no un fallo de programacion.

     Por eso no se usa lib.requestModel: esa revienta con un error de Lua tanto
     si el modelo no existe como si expira el plazo, y se llevaba por delante la
     funcion entera desde la que se llamaba.

     `IsModelInCdimage` vale para los modelos del juego y tambien para los de un
     stream ya cargado, que es como estan los animales añadidos. Se queda en la
     comprobacion tolerante, igual que quests al crear sus NPC; `IsModelAPed` es
     mas estricto y quests solo lo usa en la vista previa del panel, para poder
     decirle al admin que lo que ha escrito no es un ped. ]]
function Mascotas.CargarModelo(nombre)
    local hash = joaat(nombre or '')

    if not IsModelInCdimage(hash) then return nil end
    if HasModelLoaded(hash) then return hash end

    RequestModel(hash)

    local limite = GetGameTimer() + 5000
    while not HasModelLoaded(hash) and GetGameTimer() < limite do Wait(0) end

    return HasModelLoaded(hash) and hash or nil
end

--- ¿Hay una mascota en la calle y su ped sigue vivo y existiendo?
function Mascotas.EnLaCalle()
    return Mascotas.fuera ~= nil
        and Mascotas.ped ~= nil
        and DoesEntityExist(Mascotas.ped)
        and not IsEntityDead(Mascotas.ped)
end

--[[ La vida del ped en la escala del panel, de 0 a 100.

     Cada raza tiene su maximo —un rottweiler aguanta el doble que un carlino—,
     asi que el porcentaje se saca contra el maximo de SU raza. Con un maximo
     unico, al carlino le sobraba vida y al rottweiler le faltaba. ]]
function Mascotas.SaludEnCien()
    if not Mascotas.EnLaCalle() then return Mascotas.fuera and Mascotas.fuera.salud or 0 end

    local raza = Mascotas.Raza(Mascotas.fuera.raza)
    local vida = GetEntityHealth(Mascotas.ped) - 100 -- en GTA, 100 es "muerto"
    local techo = raza.salud - 100

    if techo <= 0 then return 0 end
    return math.max(0, math.min(100, math.floor((vida / techo) * 100)))
end

--- Avisa al panel de como esta todo. Lo llaman el ped y el laser cuando algo
--- cambia, para no tener que refrescar la lista entera desde el servidor.
function Mascotas.Avisar()
    SendNUIMessage({
        accion = 'estado',
        datos = {
            lista = Mascotas.lista,
            fueraId = Mascotas.fuera and Mascotas.fuera.id or nil,
            orden = Mascotas.orden,
            salud = Mascotas.EnLaCalle() and Mascotas.SaludEnCien() or nil,
            comida = Mascotas.fuera and Mascotas.comida or nil,
            bebida = Mascotas.fuera and Mascotas.bebida or nil,
            correa = Mascotas.correa == true,
        }
    })
end
