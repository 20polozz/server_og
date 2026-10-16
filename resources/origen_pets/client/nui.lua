--[[ ── Mascotas · el panel ──────────────────────────────────────────────────

     La columna del canto derecho, con el riel del inventario al lado para poder
     volver. Se abre desde ese riel, igual que el de banda y el de negocio.

     El riel NO se escribe aqui: se pide a origen_inventory, que es quien sabe
     que accesos le tocan a este jugador. Con una copia local, el dia que
     aparezca un acceso nuevo este panel se quedaria con la lista vieja. ]]

local abierto = false

--- Que la interfaz ha confirmado que su panel esta pintado de verdad. Ver el
--- comentario largo en AbrirPanel.
local nuiPintada = false

local function Riel()
    if GetResourceState('origen_inventory') ~= 'started' then return {} end

    local ok, riel = pcall(function()
        return exports.origen_inventory:GetRiel('mascotas')
    end)

    return (ok and type(riel) == 'table') and riel or {}
end

--[[ Cuantas tiene, guardado.

     El riel se pinta EN SECO desde los otros paneles —ahi no se puede esperar
     una respuesta del servidor— asi que la cuenta se guarda y se refresca
     cuando cambia: al cargar, al abrir el panel y cuando el servidor avisa de
     una mascota nueva. Preguntando en el momento, el riel se quedaba colgado
     esperando o devolvia siempre que no. ]]
local cuantasTengo = 0

local function Refrescar()
    Mascotas.lista = lib.callback.await('origen_pets:mias', false) or {}
    cuantasTengo = #Mascotas.lista

    --[[ La que el servidor cree que esta fuera manda sobre la que creemos
         nosotros: si el recurso se reinicio con el perro en la calle, aqui no
         hay ped y alli si hay fila marcada. ]]
    for _, m in ipairs(Mascotas.lista) do
        if Mascotas.fuera and m.id == Mascotas.fuera.id then
            m.fuera = true
            Mascotas.fuera = m
        else
            m.fuera = false
        end
    end
end

--[[ Con el panel abierto se anda, pero no se pega, no se apunta, no se mueve
     la camara con el raton (que esta en el panel) ni se abre el menu de pausa
     con el Escape que lo cierra. La lista es la del inventario
     (origen_inventory/client/function.lua, DisableKeys). ]]
local APAGADAS = { 1, 2, 18, 22, 24, 25, 26, 37, 45, 68, 69, 70, 80, 91, 92, 106,
    140, 141, 142, 143, 257, 263, 264, 286, 287, 177, 200, 202 }

function TeclasConElPanel()
    -- Y un momento despues de cerrar, hasta que se suelte el Escape: si no,
    -- la misma pulsacion que cierra el panel abre la pausa.
    while abierto or IsDisabledControlPressed(0, 200) do
        DisablePlayerFiring(cache.playerId, true)
        for i = 1, #APAGADAS do DisableControlAction(0, APAGADAS[i], true) end
        Wait(0)
    end
end

--- `relevo` es que se llega desde otro panel del riel y su barra sigue en
--- pantalla: la de aqui tiene que aparecer ya puesta encima en vez de
--- deslizarse, o durante el cruce se verian dos barras moviendose a la vez.
--- Lo que el panel necesita saber de niveles: desde cuando sabe cada cosa,
--- y las especialidades que hay.
function DatosDeProgreso()
    local lista = {}
    for id, e in pairs(Config.Progreso.especialidades) do
        lista[#lista + 1] = { id = id, nombre = e.nombre, texto = e.texto }
    end
    table.sort(lista, function(a, b) return a.nombre < b.nombre end)

    return {
        desde = Config.Progreso.desde,
        especialidades = lista,
    }
end

function AbrirPanel(relevo)
    if abierto then return end

    Refrescar()
    abierto = true

    SetNuiFocus(true, true)
    -- Como el inventario: el juego sigue recibiendo teclas y puedes andar con
    -- el panel abierto. El precio es apagar a mano lo que no toca (abajo).
    SetNuiFocusKeepInput(true)
    CreateThread(TeclasConElPanel)
    SendNUIMessage({
        accion = 'abrir',
        datos = {
            lista = Mascotas.lista,
            fueraId = Mascotas.fuera and Mascotas.fuera.id or nil,
            orden = Mascotas.orden,
            salud = Mascotas.EnLaCalle() and Mascotas.SaludEnCien() or nil,
            comida = Mascotas.fuera and Mascotas.comida or nil,
            bebida = Mascotas.fuera and Mascotas.bebida or nil,
            precioVeterinario = Config.Veterinario.precio,
            progreso = DatosDeProgreso(),
            correa = Mascotas.correa,
            consumibles = {
                comida = Config.Necesidades.comida.nombre,
                bebida = Config.Necesidades.bebida.nombre,
            },
            riel = Riel(),
            relevo = relevo == true,
        }
    })

    --[[ ── Y SE COMPRUEBA QUE LA PANTALLA LLEGO A PINTARSE ──────────────────

         Mandar el mensaje no prueba nada. Si la interfaz revienta al montarse
         --un dato que llega mal, una lista que no era lista-- Vue desmonta el
         trozo roto sin decir nada: queda la pantalla en blanco con el foco de
         la NUI cogido, el raton en medio y nada que pulsar. Y desde aqui todo
         parece correcto, porque `abierto` sigue en true.

         Asi que la interfaz contesta cuando se ha pintado de verdad --mirando
         que su columna este en el DOM, no solo que le hayan llamado-- y si en
         un segundo y medio no ha contestado, se cierra y se suelta el foco.

         Segundo y medio: la NUI contesta en el primer fotograma; el margen es
         para un arranque lento, no para esperar a nadie. ]]
    nuiPintada = false

    SetTimeout(1500, function()
        if not abierto or nuiPintada then return end

        print('^1[origen_pets]^0 El panel no llego a pintarse. Se cierra y se suelta el foco para no dejar el raton preso.')
        CerrarPanel(false)
    end)
end

function CerrarPanel(mantenerFoco)
    --[[ EL FOCO SE SUELTA ANTES QUE NADA, y por fuera del guardia de abajo.

         Ese `if not abierto` descartaba la llamada entera, y con ella el
         SetNuiFocus: con la marca ya en false, la pantalla se iba y el raton
         se quedaba en medio. Quedarse sin panel se arregla volviendo a abrir;
         quedarse sin camara, no.

         Con `mantenerFoco` sigue sin tocarse: ahi el foco es del panel que
         coge el relevo y quitarselo seria peor. ]]
    if not mantenerFoco then
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
    end

    if not abierto then return end
    abierto = false

    SendNUIMessage({ accion = 'cerrar' })
end

RegisterCommand('mascotas', function() AbrirPanel() end, false)

--[[ Si el vigilante comun (@origen_map/shared/foco.lua) suelta el raton a la
     fuerza, el panel se cierra de verdad: `abierto` a false para poder volver
     a abrirlo y la columna fuera de la pantalla. ]]
if OrigenFoco then
    OrigenFoco.AlSoltar(function()
        if abierto then CerrarPanel() end
    end)
end

--- Lo llama el servidor cuando te dan una mascota nueva.
RegisterNetEvent('origen_pets:client:refrescar', function()
    Refrescar()
    if abierto then Mascotas.Avisar() end
end)

--[[ Un admin ha tocado una mascota tuya desde su panel.

     Lo que cambia en la base de datos ya esta cambiado; aqui se pone al dia lo
     que solo sabe este cliente, que es el ped. Curada, se le devuelve la vida
     al que esta en la calle. Quitada o cambiada de raza, se guarda: el ped que
     hay es de una mascota que ya no existe o de la raza de antes, y al volver
     a sacarla sale la buena. ]]
RegisterNetEvent('origen_pets:client:adminCambio', function(cambio)
    if type(cambio) ~= 'table' then return end

    if Mascotas.fuera and Mascotas.fuera.id == tonumber(cambio.id) then
        -- Tambien al cambiarla: la nueva llega sana, y al guardar se apunta la
        -- vida del ped, que es el de antes.
        if cambio.que ~= 'quitar' then
            if Mascotas.EnLaCalle() then
                SetEntityHealth(Mascotas.ped, Mascotas.Raza(Mascotas.fuera.raza).salud)
            end
            Mascotas.comida = 100
            Mascotas.bebida = 100
        end

        if cambio.que ~= 'curar' then Mascotas.Guardar(true) end
    end

    Refrescar()
    if abierto then Mascotas.Avisar() end
end)

--[[ Al entrar se pregunta una vez, para que el boton del riel ya sepa si le
     toca aunque todavia no se haya abierto el panel ni una sola vez. Es lo
     mismo que hace el riel con los negocios. ]]
CreateThread(function()
    Wait(8000)
    Refrescar()
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    SetTimeout(2000, Refrescar)
end)

--- Y el riel del inventario, para saber si te toca el boton.
exports('TieneMascotas', function()
    return cuantasTengo > 0
end)

exports('AbrirPanel', AbrirPanel)
exports('CerrarPanel', function() CerrarPanel() end)

--[[ Para que el inventario pueda comprobar, tras pasarle el relevo, que este
     panel llego a abrirse de verdad. Si no, se quedaria con el foco de la NUI
     puesto y ninguna pantalla delante: el raton en medio y la camara sin
     responder. Ver VigilarRelevo en origen_inventory. ]]
exports('EstaAbierto', function()
    return abierto == true
end)

-- ── Lo que pulsa el jugador ───────────────────────────────────────────────

--- La interfaz avisa de que su panel esta en el DOM. Sin esto, el cliente no
--- tiene forma de saber si lo que mando llego a pintarse.
RegisterNUICallback('pintado', function(_, cb)
    cb({})
    nuiPintada = true
end)

RegisterNUICallback('cerrar', function(_, cb)
    cb({})
    CerrarPanel()
end)

--- Saltar a otra cosa del riel. El foco se lo queda el que entra.
RegisterNUICallback('riel', function(datos, cb)
    cb({})

    local destino = datos and datos.id
    if not destino then return end

    --[[ EL FOCO SE SUELTA, aunque el que entra vaya a pedirlo enseguida.

         Iba con `mantenerFoco` para que no parpadease el cursor, dando por
         hecho que el destino lo cogeria. Pero el destino puede negarse a
         abrir --el inventario lo hace si estas ocupado, herido o esposado-- y
         entonces no lo coge nadie: este panel ya se ha ido y el foco se queda
         puesto, con el raton en pantalla y nada que pulsar.

         200 ms de cursor parpadeando contra quedarse sin camara: no hay
         discusion. ]]
    CerrarPanel(false)

    if GetResourceState('origen_inventory') ~= 'started' then
        SetNuiFocus(false, false)
        return
    end

    --[[ A mitad del recorrido, no al final. La columna tarda 260 ms en
         recogerse; abriendo a los 200 el panel que entra empieza a deslizarse
         mientras este acaba de salir, y no queda ni un fotograma de pantalla
         vacia. La barra del canto no se mueve en ningun momento.

         El `true` es el aviso de RELEVO: el que entra pinta su riel ya puesto
         en vez de deslizarlo, porque el de aqui sigue ahi hasta desmontarse. ]]
    SetTimeout(200, function()
        if destino == 'inventory' or destino == 'personal' or destino == 'vehicle' or destino == 'keys'
            or destino == 'city' or destino == 'quests' or destino == 'settings' then
            exports.origen_inventory:AbrirEnPestana(destino, true)
        else
            exports.origen_inventory:AbrirAcceso(destino, true)
        end
    end)
end)

RegisterNUICallback('sacar', function(datos, cb)
    if Mascotas.Sacar(datos and datos.id) then
        Refrescar()
    end
    cb({ lista = Mascotas.lista, fueraId = Mascotas.fuera and Mascotas.fuera.id or nil, orden = Mascotas.orden })
end)

RegisterNUICallback('guardar', function(_, cb)
    Mascotas.Guardar()
    Refrescar()
    cb({ lista = Mascotas.lista, fueraId = nil, orden = Mascotas.orden })
end)

RegisterNUICallback('orden', function(datos, cb)
    cb({})

    local orden = datos and datos.orden
    if not orden then return end

    -- Lo que aun no sabe por nivel: se dice y no se manda.
    if Mascotas.EnLaCalle() and not Mascotas.Sabe(orden) then
        Mascotas.Avisar()
        return
    end

    if orden == 'guardia' then
        if not Mascotas.EnLaCalle() then return end
        if not Mascotas.Raza(Mascotas.fuera.raza).pelea then
            TriggerEvent('QBCore:Notify', ('%s no es un perro de pelea.'):format(Mascotas.fuera.nombre), 'error')
            return
        end
        -- En guardia va suelta detras de ti: plantada no te sirve de nada.
        Mascotas.orden = 'guardia'
        Mascotas.Aplicar('guardia')
        return
    end

    Mascotas.Aplicar(orden)
end)

--[[ Lo que se hace CON ella y no es una orden que se quede puesta: acariciar,
     la pelota, rastrear. Se cierra el panel porque todo pasa en la
     calle. La correa no: se pone y se sigue en el panel. ]]
local ACCIONES = {
    acariciar = function() Mascotas.Acariciar() end,
    pelota = function() Mascotas.Pelota() end,
    rastrear = function() Mascotas.Rastrear() end,
}

RegisterNUICallback('accion', function(datos, cb)
    cb({})
    local cual = datos and datos.cual

    if cual == 'correa' then return Mascotas.Correa() end

    local accion = ACCIONES[cual or '']
    if not accion then return end

    CerrarPanel()
    SetTimeout(150, function() CreateThread(accion) end)
end)

RegisterNUICallback('especializar', function(datos, cb)
    local r = lib.callback.await('origen_pets:especializar', false, { id = datos and datos.id, cual = datos and datos.cual })
    TriggerEvent('QBCore:Notify', (r and r.mensaje) or 'No se pudo.', (r and r.ok) and 'success' or 'error')
    Refrescar()
    cb({ lista = Mascotas.lista })
end)

--[[ Señalar a quien morder. Se cierra el panel a proposito: hay que ver la
     calle para apuntar, y con la columna delante no se ve media pantalla. ]]
RegisterNUICallback('apuntar', function(_, cb)
    cb({})
    CerrarPanel()
    SetTimeout(150, function() Mascotas.Apuntar() end)
end)

--[[ La mochila. Se cierra el panel: el inventario es otra NUI y con las dos
     abiertas se pelean por el raton.

     Soltando el foco, como en el riel: el inventario coge el suyo al abrir.
     Quedandoselo, si la mochila no llega a abrirse --la mascota ya no esta
     fuera, estas ocupado, el servidor ya te tenia en otro inventario-- nadie
     lo suelta y el raton se queda en medio sin pantalla. ]]
RegisterNUICallback('mochila', function(_, cb)
    cb({})
    CerrarPanel(false)
    SetTimeout(120, function() Mascotas.AbrirMochila() end)
end)

--- Darle de comer o de beber. El item lo descuenta el servidor.
RegisterNUICallback('alimentar', function(datos, cb)
    local r = lib.callback.await('origen_pets:alimentar', false, {
        id = Mascotas.fuera and Mascotas.fuera.id or (datos and datos.id),
        que = datos and datos.que,
    })

    TriggerEvent('QBCore:Notify', (r and r.mensaje) or 'No se pudo.', (r and r.ok) and 'success' or 'error')

    -- El valor nuevo viene del servidor, que es quien lo ha escrito.
    if r and r.ok and Mascotas.fuera then
        if r.que == 'comida' then Mascotas.comida = r.valor else Mascotas.bebida = r.valor end
    end

    if r and r.ok then Refrescar() end

    cb({
        lista = Mascotas.lista,
        comida = Mascotas.comida,
        bebida = Mascotas.bebida,
    })
end)

RegisterNUICallback('renombrar', function(datos, cb)
    local r = lib.callback.await('origen_pets:renombrar', false, datos)

    if r and r.ok then
        Refrescar()
    elseif r then
        TriggerEvent('QBCore:Notify', r.mensaje or 'No se pudo.', 'error')
    end

    cb({ lista = Mascotas.lista })
end)

--[[ El veterinario.

     Con la mascota en la calle, la vida de la base de datos es la de cuando
     salio: la de verdad es la del ped y solo se escribe al guardarla. Antes de
     curar se apunta la de ahora --si no, el servidor veia 100 y contestaba "esta
     perfectamente" a un perro medio muerto-- y, curada, se le devuelve la vida
     al ped, que si no seguia herido hasta guardarlo y volverlo a sacar. ]]
local curando = false

RegisterNUICallback('curar', function(datos, cb)
    if curando then return cb({ lista = Mascotas.lista }) end
    curando = true

    local id = datos and tonumber(datos.id)
    local esLaDeFuera = id and Mascotas.fuera and Mascotas.fuera.id == id and Mascotas.EnLaCalle()

    if esLaDeFuera then
        lib.callback.await('origen_pets:guardarSalud', false, {
            id = id,
            salud = Mascotas.SaludEnCien(),
            comida = Mascotas.comida,
            bebida = Mascotas.bebida,
            fuera = true,
        })
    end

    local r = lib.callback.await('origen_pets:curar', false, { id = id })

    TriggerEvent('QBCore:Notify', (r and r.mensaje) or 'No se pudo.', (r and r.ok) and 'success' or 'error')

    if r and r.ok then
        if esLaDeFuera and Mascotas.EnLaCalle() then
            local raza = Mascotas.Raza(Mascotas.fuera.raza)
            SetEntityHealth(Mascotas.ped, raza.salud)
            Mascotas.comida = 100
            Mascotas.bebida = 100
        end
        Refrescar()
        Mascotas.Avisar()
    end

    curando = false
    cb({ lista = Mascotas.lista })
end)

-- Sacar y guardar desde otro recurso (un item, una tecla, una cuadra). El
-- servidor comprueba igual que la mascota sea de quien la pide.
exports('Sacar', function(id) return Mascotas.Sacar(id) end)
exports('Guardar', function() Mascotas.Guardar() end)
exports('Lista', function() return Mascotas.lista end)

-- Lo mismo que los botones del panel, para un atajo o el menu radial:
-- 'acariciar', 'pelota', 'correa', 'rastrear'.
exports('Accion', function(cual)
    if cual == 'correa' then return Mascotas.Correa() end
    if ACCIONES[cual or ''] then CreateThread(ACCIONES[cual]) end
end)

--- Sacarla si esta en casa y guardarla si esta fuera. Lo pide el F3 de Nacion.
RegisterNetEvent('origen_pets:client:alternar', function(id)
    Refrescar()
    if Mascotas.fuera and Mascotas.fuera.id == id then
        Mascotas.Guardar()
    else
        if Mascotas.fuera then Mascotas.Guardar(true) end
        Mascotas.Sacar(id)
    end
    Refrescar()
end)
