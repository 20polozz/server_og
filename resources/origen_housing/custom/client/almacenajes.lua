-- Muebles con partes que se mueven de verdad (ver config/almacenajes.lua,
-- config/packs.lua y custom/server/almacenajes.lua). El mueble del catálogo es
-- el cuerpo; sus puertas, tapas, cajones y solapas son objetos LOCALES que cada
-- cliente pone pegados a él (así le siguen si se mueve con el gizmo) y gira o
-- desliza al abrirlo y al cerrarlo. Según su `uso`:
--   · 'almacen'  se abre al abrir el almacenamiento y se cierra al cerrar el inventario
--   · 'ropero'   se abre al abrir el menú de ropa y se cierra al salir de él
--   · 'E'        mueble normal: de cerca y de frente, la E lo abre y lo cierra
-- No toca cómo se abren el inventario ni el menú de ropa: se cuelga de
-- Internal.OpenStash e Internal.Wardrobe y, pase lo que pase aquí, la apertura
-- de siempre se hace igual.
local C = Config.Almacenajes

local muebles = {}      -- clave ('zona:id') → { clave, zona, id, modelo, entidad, def, uso, partes, puestas, u, servidor, yo, sinEstado }
local casaActual = nil  -- id (texto) de la casa a la que pertenecen
local mio = nil         -- el que tengo en uso yo (almacén o ropero): { clave, casa, uso, desde, visto }
local ultimaE = 0
local menuAjeno = false -- otro menú tiene la pantalla (la cinta de decorar, el radial, la ropa…)
local conTexto = false
local pedido = 0        -- GetGameTimer() de mi última E (para no pedir dos veces seguidas)

local function Suave(u)
    if u <= 0.0 then return 0.0 end
    if u >= 1.0 then return 1.0 end
    return u * u * (3.0 - 2.0 * u)
end

-- El cartel y la tecla los lleva el árbitro común (custom/client/tecla_e.lua):
-- aquí solo se ofrece la E, o se retira.
local function Texto(texto)
    if not texto then Tecla.Retirar('almacenajes') end
end

-- ── Las partes ──────────────────────────────────────────────────────────
-- Cada parte va pegada al cuerpo en su bisagra (`pos`); abrir es cambiar con
-- qué giro o con qué desplazamiento va pegada. s: de 0 (cerrado) a 1 (abierto).
local function Colocar(m)
    local cuerpo = m.entidad
    if not cuerpo or not DoesEntityExist(cuerpo) then return false end
    local s = Suave(m.u)
    for _, p in ipairs(m.partes) do
        if DoesEntityExist(p.ent) then
            local d = p.def
            local pos = type(d.pos) == 'table' and d.pos or {}
            local x, y, z = (tonumber(pos[1]) or 0.0) + 0.0, (tonumber(pos[2]) or 0.0) + 0.0, (tonumber(pos[3]) or 0.0) + 0.0
            local rx, ry, rz = 0.0, 0.0, 0.0
            if d.modo == 'corre' then
                local r = (tonumber(d.recorrido) or 0.0) * s
                if d.eje == 'x' then x = x + r elseif d.eje == 'z' then z = z + r else y = y + r end
            else
                local a = (tonumber(d.angulo) or 0.0) * s
                if d.eje == 'x' then rx = a elseif d.eje == 'y' then ry = a else rz = a end
            end
            AttachEntityToEntity(p.ent, cuerpo, 0, x, y, z, rx, ry, rz, false, false, false, false, 2, true)
        end
    end
    return true
end

local function Quitar(clave)
    local m = muebles[clave]
    if not m then return end
    muebles[clave] = nil
    for _, p in ipairs(m.partes) do
        if DoesEntityExist(p.ent) then
            DetachEntity(p.ent, false, false)
            DeleteEntity(p.ent)
        end
    end
    m.partes = {}
end

local function QuitarTodos()
    local claves = {}
    for clave in pairs(muebles) do claves[#claves + 1] = clave end
    for _, clave in ipairs(claves) do Quitar(clave) end
end

local function CargarModelo(nombre)
    if type(nombre) ~= 'string' then return nil end
    local modelo = joaat(nombre)
    if not IsModelInCdimage(modelo) then return nil end
    RequestModel(modelo)
    local t = GetGameTimer()
    while not HasModelLoaded(modelo) and GetGameTimer() - t < 4000 do Wait(20) end
    return HasModelLoaded(modelo) and modelo or nil
end

-- Crea las partes que falten. Si algún modelo no está todavía en el cliente no
-- pasa nada: se vuelve a intentar en el siguiente repaso.
local function Crear(m)
    if m.completo then return end
    local falta = false
    for n, d in ipairs(m.def.partes) do
        if not m.puestas[n] then
            local modelo = type(d) == 'table' and CargarModelo(d.modelo) or nil
            -- mientras se cargaba se ha podido quitar el mueble, o salir de la casa
            if muebles[m.clave] ~= m or not DoesEntityExist(m.entidad) then
                if modelo then SetModelAsNoLongerNeeded(modelo) end
                return
            end
            if modelo then
                local c = GetEntityCoords(m.entidad)
                local e = CreateObjectNoOffset(modelo, c.x, c.y, c.z, false, false, false)
                SetModelAsNoLongerNeeded(modelo)
                if e and e ~= 0 then
                    SetEntityCollision(e, false, false)
                    FreezeEntityPosition(e, true)
                    local interior = GetInteriorFromEntity(m.entidad)
                    if interior ~= 0 then ForceRoomForEntity(e, interior, GetRoomKeyFromEntity(m.entidad)) end
                    m.partes[#m.partes + 1] = { ent = e, def = d }
                    m.puestas[n] = true
                else
                    falta = true
                end
            else
                falta = true
            end
        end
    end
    m.completo = not falta
    Colocar(m)
end

-- ── Los muebles de la casa ──────────────────────────────────────────────
local function Casa()
    local id = currentInteriorHouseID or currentExteriorHouseID
    if not id then return nil end
    return House.get(id) or nil
end

local function CerrarMio()
    if not mio then return end
    local m = muebles[mio.clave]
    mio = nil
    if m then m.yo = false end
    TriggerServerEvent('origen_housing:almacenajes:cerrar')
end

local function Nuevo(clave, zona, idMueble, f, def, era)
    return { clave = clave, zona = zona, id = tostring(idMueble), modelo = f.model, entidad = f.entity, def = def, uso = C.Uso(def),
        partes = {}, puestas = {}, u = era and era.modelo == f.model and era.u or 0.0, servidor = era and era.servidor or false,
        yo = era and era.yo or false, sinEstado = true }
end

local function Repasar()
    local house = Casa()
    local id = house and tostring(house.id) or nil
    if casaActual ~= id then
        if mio then CerrarMio() end
        QuitarTodos()
        casaActual = id
    end
    if not house then return end

    local vistos, nuevos = {}, false
    for zona, lista in pairs({ interior = house.interiorFurniture, exterior = house.exteriorFurniture }) do
        for idMueble, f in pairs(lista or {}) do
            -- en tiempo de ejecución: los packs se registran después de cargar este módulo
            local def = type(f) == 'table' and C.Def(f.model)
            if def and f.entity and DoesEntityExist(f.entity) then
                local clave = C.Clave(zona, idMueble)
                vistos[clave] = true
                local m = muebles[clave]
                -- el mueble se ha vuelto a crear (otra entidad) o es otro modelo: sus partes, de nuevo
                if m and (m.entidad ~= f.entity or m.modelo ~= f.model) then
                    Quitar(clave)
                    muebles[clave] = Nuevo(clave, zona, idMueble, f, def, m)
                    nuevos = true
                elseif not m then
                    muebles[clave] = Nuevo(clave, zona, idMueble, f, def, nil)
                    nuevos = true
                end
            end
        end
    end
    local sobran = {}
    for clave in pairs(muebles) do
        if not vistos[clave] then sobran[#sobran + 1] = clave end
    end
    for _, clave in ipairs(sobran) do
        if mio and mio.clave == clave then CerrarMio() end
        Quitar(clave)
    end

    local lista = {}
    for _, m in pairs(muebles) do lista[#lista + 1] = m end
    for _, m in ipairs(lista) do
        if muebles[m.clave] == m then
            Crear(m)
            -- escondido el cuerpo (al recolocarlo, por ejemplo), escondidas sus partes
            if muebles[m.clave] == m and DoesEntityExist(m.entidad) then
                local seVe = IsEntityVisible(m.entidad)
                if m.seVe ~= seVe then
                    m.seVe = seVe
                    for _, p in ipairs(m.partes) do
                        if DoesEntityExist(p.ent) then SetEntityVisible(p.ent, seVe, false) end
                    end
                end
            end
        end
    end

    if not nuevos or casaActual ~= id then return end
    -- los recién puestos: ¿cuáles están abiertos ahora mismo?
    local estado = lib.callback.await('origen_housing:almacenajes:estado', false, id)
    if casaActual ~= id then return end
    local abiertos = {}
    for _, clave in ipairs(type(estado) == 'table' and estado or {}) do abiertos[clave] = true end
    for clave, m in pairs(muebles) do
        if m.sinEstado then
            m.sinEstado = nil
            if type(estado) == 'table' then
                m.servidor = abiertos[clave] == true
                -- quien entra lo ve ya abierto, sin animación
                if m.servidor and m.u < 1.0 and not m.yo then
                    m.u = 1.0
                    Colocar(m)
                end
            end
        end
    end
end

-- El servidor avisa a los de la casa de que un mueble se abre o se cierra
RegisterNetEvent('origen_housing:almacenajes:mover', function(casa, clave, abierto)
    if not casaActual or tostring(casa) ~= casaActual or type(clave) ~= 'string' then return end
    local m = muebles[clave]
    if not m then return end        -- todavía no está puesto aquí: se preguntará al crearlo
    m.servidor = abierto == true
end)

-- ── Abrir y cerrar el mío (almacén y ropero) ────────────────────────────
-- Al usar uno de estos muebles: se abre ya en esta pantalla y se avisa al
-- servidor, que lo cuenta a los demás.
local function AlUsar(uso, idPunto)
    if type(idPunto) ~= 'string' or not casaActual then return end
    local patron = uso == 'ropero' and '^wardrobe_([%w_%-]+)_(%a+)$' or '^stashHousing_([%w_%-]+)_(%a+)$'
    local idMueble, zona = idPunto:match(patron)
    if not idMueble then return end
    local m = muebles[C.Clave(zona, idMueble)]
    if not m or m.uso ~= uso then return end
    if mio and mio.clave == m.clave then
        mio.desde = GetGameTimer()
        return
    end
    if mio then CerrarMio() end
    m.yo = true
    mio = { clave = m.clave, casa = casaActual, uso = uso, desde = GetGameTimer(), visto = false }
    TriggerServerEvent('origen_housing:almacenajes:abrir', casaActual, m.zona, m.id)
end

local function Intentar(uso, id)
    local ok, err = pcall(AlUsar, uso, id)
    if not ok then print('^3[origen_housing]^0 almacenajes: ' .. tostring(err)) end
end

CreateThread(function()
    local t = GetGameTimer()
    while not (Internal and Internal.OpenStash and Internal.Wardrobe) and GetGameTimer() - t < 30000 do Wait(200) end
    if Internal and Internal.OpenStash then
        local abrir = Internal.OpenStash
        Internal.OpenStash = function(id, data)
            -- el mismo antirrebote que lleva dentro Internal.OpenStash: si él va a
            -- descartar la pulsación, aquí tampoco se abre nada
            local ahora = GetGameTimer()
            if ahora - ultimaE >= 1000 then
                ultimaE = ahora
                Intentar('almacen', id)
            end
            return abrir(id, data)
        end
    end
    if Internal and Internal.Wardrobe then
        local ropa = Internal.Wardrobe
        Internal.Wardrobe = function(id, ...)
            Intentar('ropero', id)
            return ropa(id, ...)
        end
    end
end)

-- origen_inventory avisa de cuándo su panel se pone y se quita
AddEventHandler('origen_inventory:abierto', function(abierto)
    if not mio or mio.uso ~= 'almacen' then return end
    if abierto then
        mio.visto = true
    elseif mio.visto then
        CerrarMio()
    end
end)

-- Todos los menús del servidor (el de ropa también) avisan de que apartan el
-- HUD y de que lo devuelven: con eso se sabe que el menú de ropa se ha cerrado
-- y que con un menú delante no se ofrece la E.
-- (el árbitro lo suelta si se queda enganchado: custom/client/tecla_e.lua)
AddEventHandler('origen_housing:sinMenuAjeno', function() menuAjeno = false end)

AddEventHandler('qv2:suppressHud', function(fuera)
    menuAjeno = fuera == true
    if not mio or mio.uso ~= 'ropero' then return end
    if fuera then
        mio.visto = true
    elseif mio.visto then
        CerrarMio()
    end
end)

-- Por si esos avisos no llegan (otro inventario, otro menú de ropa, o el panel
-- no llegó a salir): se mira si hay algo delante.
local function EnUso()
    if mio.uso == 'almacen' and GetResourceState('origen_inventory') == 'started' then
        local ok, abierto = pcall(function() return exports.origen_inventory:IsInventoryOpen() end)
        if ok then return abierto == true end
    end
    return IsNuiFocused()
end

-- ── La E de los muebles normales (uso 'E') ──────────────────────────────
local function Decorando()
    if Furniture and Furniture.active then return true end
    return Obra ~= nil and Obra.CintaAbierta ~= nil and Obra.CintaAbierta() == true
end

-- ¿Tiene ese mueble otra E (almacén, ropero, tele, ascensor…)? Entonces esta no se ofrece.
local function ConOtraE(modelo)
    local item = __indexFurniture and __indexFurniture[modelo]
    return item ~= nil and item.type ~= nil and item.type ~= 'object'
end

-- El mueble de los de la E que el jugador tiene cerca y delante
local function Cercano(ped)
    local yo = GetEntityCoords(ped)
    local frente = GetEntityForwardVector(ped)
    local mejor, cuanto = nil, nil
    for _, m in pairs(muebles) do
        if m.uso == 'E' and m.completo and DoesEntityExist(m.entidad) and IsEntityVisible(m.entidad) and not ConOtraE(m.modelo) then
            local c = GetEntityCoords(m.entidad)
            if #(yo - c) < 6.0 then
                local min, max = GetModelDimensions(GetEntityModel(m.entidad))
                local p = GetOffsetFromEntityGivenWorldCoords(m.entidad, yo.x, yo.y, yo.z)
                local dx = math.max(min.x - p.x, 0.0, p.x - max.x)
                local dy = math.max(min.y - p.y, 0.0, p.y - max.y)
                local d = math.sqrt(dx * dx + dy * dy)
                if d <= C.radioE and p.z > min.z - 1.2 and p.z < max.z + 1.5 then
                    -- de frente: mirando hacia el mueble (o pegado a él)
                    local centro = GetOffsetFromEntityInWorldCoords(m.entidad, (min.x + max.x) / 2, (min.y + max.y) / 2, 0.0)
                    local vx, vy = centro.x - yo.x, centro.y - yo.y
                    local l = math.sqrt(vx * vx + vy * vy)
                    if (l < 0.5 or (vx * frente.x + vy * frente.y) / l > 0.35) and (not cuanto or d < cuanto) then
                        mejor, cuanto = m, d
                    end
                end
            end
        end
    end
    return mejor, cuanto
end

local function TextoDe(m)
    local t = type(m.def.texto) == 'table' and m.def.texto or {}
    local abierto = m.servidor == true
    return tostring(abierto and (t[2] or 'Cerrar') or (t[1] or 'Abrir'))
end

CreateThread(function()
    local hayE = false
    local mirado = 0
    while true do
        local espera = 1000
        local ahora = GetGameTimer()
        if ahora - mirado > 1000 then
            mirado, hayE = ahora, false
            for _, m in pairs(muebles) do
                if m.uso == 'E' then hayE = true break end
            end
        end
        local cerca, lejos = nil, nil
        if hayE then
            espera = 300
            local ped = PlayerPedId()
            if not menuAjeno and not Decorando() and not currentDoorID and not IsNuiFocused() and not IsPauseMenuActive()
                and not IsPedInAnyVehicle(ped, false) and not IsEntityDead(ped) and not IsPedRagdoll(ped) then
                cerca, lejos = Cercano(ped)
            end
        end
        if cerca then
            -- (la tecla se mira en el árbitro: aquí se renueva la oferta unas veces por segundo)
            espera = 150
            local m, casa = cerca, casaActual
            Tecla.Ofrecer('almacenajes', {
                texto = TextoDe(m), prioridad = 50, dist = lejos,
                hacer = function()
                    local t = GetGameTimer()
                    if casaActual ~= casa or t - pedido < C.ritmo then return end
                    pedido = t
                    TriggerServerEvent('origen_housing:almacenajes:alternar', casa, m.zona, m.id)
                end,
            })
        else
            Texto(nil)
        end
        Wait(espera)
    end
end)

-- ── Los bucles ──────────────────────────────────────────────────────────
CreateThread(function()
    while true do
        local ok, err = pcall(Repasar)
        if not ok then print('^3[origen_housing]^0 almacenajes: ' .. tostring(err)) end
        Wait(1000)
    end
end)

CreateThread(function()
    local antes = GetGameTimer()
    while true do
        local ahora = GetGameTimer()
        local dt = ahora - antes
        antes = ahora
        local espera = 250

        if mio then
            if EnUso() then
                mio.visto = true
            elseif mio.visto or ahora - mio.desde > C.sinAbrir then
                CerrarMio()
            end
        end

        local huerfanos = nil
        for clave, m in pairs(muebles) do
            if not DoesEntityExist(m.entidad) then
                huerfanos = huerfanos or {}
                huerfanos[#huerfanos + 1] = clave
            else
                local hacia = (m.servidor or m.yo) and 1.0 or 0.0
                if m.u ~= hacia then
                    espera = 0
                    local ms = 300
                    for _, d in ipairs(m.def.partes) do ms = math.max(ms, tonumber(type(d) == 'table' and d.ms) or 600) end
                    local paso = dt / ms
                    if m.u < hacia then m.u = math.min(hacia, m.u + paso) else m.u = math.max(hacia, m.u - paso) end
                    Colocar(m)
                end
            end
        end
        -- quitado el mueble, sus partes no se quedan en el aire hasta el repaso
        for _, clave in ipairs(huerfanos or {}) do Quitar(clave) end
        Wait(espera)
    end
end)

AddEventHandler('onResourceStop', function(r)
    if r ~= GetCurrentResourceName() then return end
    QuitarTodos()
end)

-- TEMPORAL (sonda): estado de los muebles animados de la casa
RegisterNetEvent('zz_puerta:diagAnim', function()
    local r, n = {}, 0
    for clave, m in pairs(muebles) do
        n = n + 1
        if n <= 40 then
            local enCd = {}
            for i, d in ipairs(m.def.partes) do enCd[i] = IsModelInCdimage(joaat(d.modelo)) end
            r[#r + 1] = { clave = clave, modelo = m.modelo, partes = #m.partes, deben = #m.def.partes, completo = m.completo, u = m.u, servidor = m.servidor, enCd = enCd, uso = m.uso }
        end
    end
    TriggerServerEvent('zz_puerta:nada', 'anim', { casa = casaActual, total = n, lista = r })
end)
