--[[
    La parte de cliente de las tres acciones de banda que no van contra otro
    jugador: marcar un punto, avisar y pedir ayuda.

    Aqui vive lo que se ve: la chincheta en el mapa, el aviso en pantalla y el
    punto rojo del S.O.S.
]]

local dbgAcc = Debug:new({ enabled = Config.Debug })

--- Cuanto dura cada marca en el mapa, en segundos. La del S.O.S. dura menos
--- porque es una urgencia: si sigue ahi diez minutos despues, ya no informa
--- de nada y solo estorba.
local DURACION = { marca = 300, sos = 120 }

--- Las marcas puestas, para poder quitarlas cuando toque y de una vez si el
--- recurso se para.
local marcas = {}

local function QuitarMarca(clave)
    for i, b in ipairs(marcas) do
        if b == clave then table.remove(marcas, i) break end
    end
    OrigenMapa.Quitar(clave)
end

--- Un numero por marca, para que dos que se pongan a la vez no compartan clave.
local siguienteMarca = 0

--[[ Pone un punto en el mapa y lo retira solo.

     Ya no es un blip del juego: es un punto de origen_map, que es de donde
     leen los tres mapas del servidor.

     Va con color explicito y no con el de su categoria: una marca de banda es
     un aviso, no un sitio, y tiene que distinguirse de las veinte chinchetas
     que ya hay alrededor. Y con prioridad alta, que es lo que antes decia
     SetBlipAsShortRange(false): una marca al otro lado de la ciudad es
     justamente la que hay que ver.

     El parpadeo se pierde por el camino: en un mapa de Leaflet un punto que
     parpadea es ruido, y el color ya dice lo mismo sin moverse. ]]
local function PonerMarca(coords, texto, opciones)
    siguienteMarca = siguienteMarca + 1
    local clave = 'marca_' .. siguienteMarca

    OrigenMapa.Poner(clave, {
        x = coords.x, y = coords.y, z = coords.z,
        cat = 'illegal',
        nombre = texto,
        color = opciones.tinte or '#ff3355',
        prioridad = 10,
        --- La marca del S.O.S. ademas pone la ruta: quien pide ayuda necesita
        --- que se sepa ir, no que se busque.
        ruta = opciones.ruta and true or false,
    })

    marcas[#marcas + 1] = clave

    SetTimeout((opciones.duracion or 300) * 1000, function()
        QuitarMarca(clave)
    end)

    return clave
end

-- ── Marcar un punto ─────────────────────────────────────────────────────────

--- Lo llama el menu rapido. Manda donde estas; el servidor reparte.
function MarcarPuntoDeBanda()
    local coords = GetEntityCoords(PlayerPedId())
    TriggerServerEvent('origen_gang:server:marcar', {
        x = coords.x, y = coords.y, z = coords.z,
    })
end

RegisterNetEvent('origen_gang:client:marcaPuesta', function(datos)
    if not datos or not datos.x then return end

    PonerMarca(datos, locale:t('ui.quick_menu.mark_of', datos.autor or '?'), {
        tinte    = '#ff3355',
        duracion = DURACION.marca,
    })

    Notify.SendNotify(locale:t('notify.mark_from', datos.autor or '?'), 'info')
end)

-- ── Aviso ───────────────────────────────────────────────────────────────────

--[[ El texto lo pide el PANEL, no un cuadro de ox_lib.

     Esta funcion se queda para cuando el aviso se dispare desde fuera del
     panel —un comando, otro menu—; desde el panel se manda directo con
     gang:avisoBanda y el texto ya escrito. ]]
function EnviarAvisoDeBanda(texto)
    if type(texto) ~= "string" or texto:gsub("%s", "") == "" then return end
    TriggerServerEvent("origen_gang:server:aviso", texto)
end

RegisterNetEvent('origen_gang:client:avisoRecibido', function(datos)
    if not datos or not datos.texto then return end
    Notify.SendNotify(('%s: %s'):format(datos.autor or '?', datos.texto), 'info')
end)

-- ── S.O.S. ──────────────────────────────────────────────────────────────────

function PedirSOSDeBanda()
    local coords = GetEntityCoords(PlayerPedId())
    TriggerServerEvent('origen_gang:server:sos', {
        x = coords.x, y = coords.y, z = coords.z,
    })
end

RegisterNetEvent('origen_gang:client:sosRecibido', function(datos)
    if not datos or not datos.x then return end

    -- Se pone ruta directamente: si alguien pide ayuda, lo que hace falta es
    -- saber ir, no tener que buscarlo en el mapa.
    PonerMarca(datos, locale:t('ui.quick_menu.sos_of', datos.autor or '?'), {
        tinte    = '#ff3355',
        ruta     = true,
        duracion = DURACION.sos,
    })

    Notify.SendNotify(locale:t('notify.sos_from', datos.autor or '?'), 'error')
    dbgAcc:info('[Banda] S.O.S. recibido de', datos.autor)
end)

-- ── Alijo ───────────────────────────────────────────────────────────────────

--[[ El boton de Alijo del menu.

     Si estas encima, lo abre. Si no, te lo marca y te lo dice. NO se abre a
     distancia a proposito: el alijo de la banda es un sitio al que hay que
     ir, y abrirlo desde cualquier punto del mapa se cargaria de un golpe todo
     el riesgo de tener que pasarse por alli. ]]
function AbrirOMarcarAlijo()
    local sitio = playerGang and playerGang.locations and playerGang.locations.stash
    if not sitio then
        Notify.SendNotify(locale:t('notify.no_stash_location'), 'error')
        return
    end

    local aqui = GetEntityCoords(PlayerPedId())
    local alli = vector3(sitio.x + 0.0, sitio.y + 0.0, sitio.z + 0.0)

    if #(aqui - alli) <= 3.0 then
        TriggerServerEvent('origen_gang:server:openStash')
        return
    end

    SetNewWaypoint(alli.x, alli.y)
    Notify.SendNotify(locale:t('notify.stash_marked'), 'info')
end

AddEventHandler('onResourceStop', function(recurso)
    if GetCurrentResourceName() ~= recurso then return end
    for _, clave in ipairs(marcas) do
        OrigenMapa.Quitar(clave)
    end
end)

-- ── Bolsa en la cabeza ──────────────────────────────────────────────────────

--[[ El boton de Bolsa del menu (16/09/2026, en el hueco que era del Alijo).

     No manda a quien: el de al lado lo busca el servidor, igual que en
     cachear o esposar, y alli se decide si se pone o se quita. La bolsa en si
     —el objeto en la cabeza y la pantalla negra— es del recurso `headbag`. ]]
function BolsaEnLaCabeza()
    TriggerServerEvent('origen_gang:server:bolsaCabeza')
end

--[[ Los botones de la rejilla que no van contra nadie (y la bolsa, que busca
     al de al lado en el servidor). El menu solo conoce nombres de evento, asi
     que aqui se atan a lo que hacen. El del alijo ya no sale en el panel,
     pero el evento se queda por si otro sitio lo usa. ]]
RegisterNetEvent('origen_gang:client:accionAlijo',  AbrirOMarcarAlijo)
RegisterNetEvent('origen_gang:client:accionBolsa',  BolsaEnLaCabeza)
RegisterNetEvent('origen_gang:client:accionMarcar', MarcarPuntoDeBanda)
RegisterNetEvent('origen_gang:client:accionAviso',  EnviarAvisoDeBanda)
RegisterNetEvent('origen_gang:client:accionSOS',    PedirSOSDeBanda)
