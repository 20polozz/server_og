--[[ Punto de carga del móvil (30/09): abrir la estación, dejar y recoger.
     Lo que cuenta lo decide el servidor (source/server/carga.lua); la
     interfaz es ui/source/src/components/CargaMovil.vue. ]]
Carga = {}

local abierta               -- { bid, indice } del punto abierto

--[[ Cada apertura es una generacion: el desmontaje se manda 280 ms despues de
     cerrar (lo que dura la salida del menu, que se recoge hacia la derecha) y
     una apertura dentro de ese hueco no puede perderlo. ]]
local generacion = 0

local function Cerrar()
    if not abierta then return end
    abierta = nil
    SetNuiFocus(false, false)
    generacion = generacion + 1
    local mia = generacion
    SetTimeout(280, function()
        if generacion == mia then SendNUIMessage({ action = 'carga:cerrar' }) end
    end)
end

function Carga.Abrir(bid, indice)
    if abierta then return end
    local r = lib.callback.await('origen_businesses:carga:ver', false, bid, indice)
    if not r or not r.ok then
        return lib.notify({ title = 'Punto de carga', description = (r and r.mensaje) or 'No se puede usar ahora.', type = 'error' })
    end
    abierta = { bid = bid, indice = indice }
    generacion = generacion + 1
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'carga:abrir', data = r })
end

OrigenFoco.AlSoltar(function()
    if not abierta then return end
    abierta = nil
    generacion = generacion + 1
    SendNUIMessage({ action = 'carga:cerrar' })
end)

RegisterNUICallback('cargaCerrar', function(_, cb)
    Cerrar()
    cb('ok')
end)

RegisterNUICallback('cargaDejar', function(_, cb)
    if not abierta then return cb({ ok = false }) end
    -- Si lo tiene abierto en la mano, se guarda antes de soltarlo
    pcall(function() exports.origen_phone:Close() end)
    local r = lib.callback.await('origen_businesses:carga:dejar', false, abierta.bid, abierta.indice)
    if r and r.ok then PlaySoundFrontend(-1, 'CONFIRM_BEEP', 'HUD_MINI_GAME_SOUNDSET', true) end
    cb(r or { ok = false })
end)

RegisterNUICallback('cargaRecoger', function(_, cb)
    if not abierta then return cb({ ok = false }) end
    local r = lib.callback.await('origen_businesses:carga:recoger', false, abierta.bid, abierta.indice)
    cb(r or { ok = false })
end)

RegisterNUICallback('cargaVer', function(_, cb)
    if not abierta then return cb({ ok = false }) end
    cb(lib.callback.await('origen_businesses:carga:ver', false, abierta.bid, abierta.indice) or { ok = false })
end)

--[[ Que se vea (30/09, el usuario: «tiene que verlo cualquier persona para
     poder ir a recargar»). Desde el 04/10 el punto es un POSTE de carga
     (Config.Carga.Prop) y ya no lleva el marcador verde flotante («ya que
     tiene prop, quita el círculo del suelo y el blip ese volando, y usa ese
     prop»):
       · en el mundo, el poste: objeto local de cada cliente (no va por red),
         congelado y con colisión, de pie en el suelo y con el rumbo del punto
         (coords.w). Solo se pintan los cercanos;
       · en el mapa grande y en el minimapa, su chincheta con el rayo.
     La tecla y el aviso siguen en Business:SetPoints (classes/business.lua). ]]
local MODELO = Config.Carga.Prop or 'prop_phone_charger'
local HASH = joaat(MODELO)
local DIST = (Config.Carga.DistanciaProp or 60.0) + 0.0

local puntos = {}          -- [clave 'negocio:indice'] = { pos, h, firma }
local postes = {}          -- [clave] = { ent, firma }: los postes que hay pintados
local huella = ''
local releer = false       -- alguien ha cambiado los puntos: no esperar a la vuelta
local apartado             -- vec3 del punto que se está recolocando: su poste no se pinta
local sinModelo = false    -- el recurso del prop no está arrancado: marcador de reserva

local function Leer()
    local lista, mapa, h = {}, {}, {}
    for bid, negocio in pairs(Business.Get() or {}) do
        for i, p in ipairs(negocio.points or {}) do
            if type(p) == 'table' and p.type == 'carga' and p.coords then
                local c = p.coords
                -- A decimal: lo que viene de la base llega entero y un native
                -- lo lee como 0 (un rumbo de 90 dejaba el poste mirando al norte)
                local x = (tonumber(c.x) or 0) + 0.0
                local y = (tonumber(c.y) or 0) + 0.0
                local z = (tonumber(c.z) or 0) + 0.0
                -- Los puntos de antes del poste no traen rumbo: 0, y se recoloca
                local rumbo = ((tonumber(c.w) or 0) + 0.0) % 360.0
                local clave = ('%s:%d'):format(bid, i)
                lista[clave] = {
                    pos = vec3(x, y, z), h = rumbo,
                    firma = ('%.2f,%.2f,%.2f,%.1f'):format(x, y, z, rumbo),
                }
                mapa[#mapa + 1] = {
                    id = ('%s_%d'):format(bid, i), x = x, y = y, z = z,
                    cat = 'public', icono = 'rayo',
                    nombre = ('Punto de carga · %s'):format(negocio.label or 'Negocio'),
                }
                h[#h + 1] = mapa[#mapa].id .. ('%.1f,%.1f'):format(x, y)
            end
        end
    end
    puntos = lista
    h = table.concat(h, ';')
    if h ~= huella then
        huella = h
        OrigenMapa.PonerVarios('carga_negocio', mapa)
    end
end

--- Lo llama Business:SetPoints/ClearPoints: crear, mover o borrar un punto se
--- ve enseguida, sin esperar a la vuelta de 5 s.
function Carga.Releer()
    releer = true
end

CreateThread(function()
    while true do
        releer = false
        Leer()
        for _ = 1, 20 do
            Wait(250)
            if releer then break end
        end
    end
end)

local function Quitar(clave)
    local poste = postes[clave]
    postes[clave] = nil
    if poste and DoesEntityExist(poste.ent) then
        SetEntityAsMissionEntity(poste.ent, true, true)
        DeleteEntity(poste.ent)
    end
end

local function QuitarTodos()
    for clave in pairs(postes) do Quitar(clave) end
end

local function Apartado(d)
    return apartado ~= nil and #(d.pos - apartado) < 0.3
end

--- Solo desde el hilo de abajo: espera al modelo, y así nunca hay dos a la vez
--- creando el mismo poste.
local function Poner(clave, d)
    if not IsModelInCdimage(HASH) then
        sinModelo = true
        return
    end
    sinModelo = false

    RequestModel(HASH)
    local tope = GetGameTimer() + 5000
    while not HasModelLoaded(HASH) and GetGameTimer() < tope do Wait(50) end
    if not HasModelLoaded(HASH) then return end

    -- Mientras cargaba se ha podido mover, borrar o apartar el punto
    local ahora = puntos[clave]
    if postes[clave] or not ahora or ahora.firma ~= d.firma or Apartado(d) then
        SetModelAsNoLongerNeeded(HASH)
        return
    end

    -- Local (sin red) y por su origen, que este modelo tiene en la base
    local ent = CreateObjectNoOffset(HASH, d.pos.x, d.pos.y, d.pos.z, false, false, false)
    SetModelAsNoLongerNeeded(HASH)
    if not ent or ent == 0 or not DoesEntityExist(ent) then return end

    SetEntityHeading(ent, d.h)
    FreezeEntityPosition(ent, true)
    SetEntityInvincible(ent, true)
    SetEntityCollision(ent, true, true)
    postes[clave] = { ent = ent, firma = d.firma }
end

CreateThread(function()
    while true do
        local yo = GetEntityCoords(PlayerPedId())

        -- Fuera los que sobran: punto borrado o movido, lejos, o el objeto se fue
        for clave, poste in pairs(postes) do
            local d = puntos[clave]
            if not d or d.firma ~= poste.firma or Apartado(d)
                or not DoesEntityExist(poste.ent) or #(yo - d.pos) > DIST + 10.0 then
                Quitar(clave)
            end
        end

        -- `puntos` no se toca por dentro (Leer pone una tabla nueva), así que
        -- se puede recorrer aunque Poner espere por el modelo
        for clave, d in pairs(puntos) do
            if not postes[clave] and not Apartado(d) and #(yo - d.pos) < DIST then
                Poner(clave, d)
            end
        end

        Wait(1000)
    end
end)

--[[ Recolocar un punto desde el panel (useRaycast de nui.lua): el poste del
     punto que se mueve se quita mientras dura la previsualización, o el rayo
     chocaba con él y el fantasma se subía encima. `coords` es donde está el
     punto ahora; nil vuelve a pintarlo. ]]
function Carga.Apartar(coords)
    local x, y, z
    if type(coords) == 'table' then
        x, y, z = tonumber(coords.x), tonumber(coords.y), tonumber(coords.z)
    end
    if x and y and z and (x ~= 0 or y ~= 0) then
        apartado = vec3(x + 0.0, y + 0.0, z + 0.0)
        for clave, d in pairs(puntos) do
            if Apartado(d) then Quitar(clave) end
        end
    else
        apartado = nil
    end
end

--- El modelo del poste para la previsualización, o nil si su recurso no está.
function Carga.ModeloPrevia()
    if IsModelInCdimage(HASH) then return MODELO end
    return nil
end

--[[ Reserva: si el recurso del prop no está arrancado no hay poste que pintar,
     y un punto público sin nada a la vista no lo encuentra nadie. Solo
     entonces vuelve el marcador verde de antes. ]]
CreateThread(function()
    while true do
        local espera = 2000
        if sinModelo then
            local yo = GetEntityCoords(PlayerPedId())
            for _, d in pairs(puntos) do
                if #(yo - d.pos) < 25.0 then
                    espera = 0
                    DrawMarker(21, d.pos.x, d.pos.y, d.pos.z + 1.05, 0.0, 0.0, 0.0, 180.0, 0.0, 0.0, 0.28, 0.28, 0.28,
                        216, 27, 85, 210, true, true, 2, false, nil, nil, false)
                end
            end
        end
        Wait(espera)
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    if abierta then SetNuiFocus(false, false) end
    -- Los objetos locales no se van solos al parar el recurso: sin esto, cada
    -- reinicio dejaba un poste encima de otro
    QuitarTodos()
end)
