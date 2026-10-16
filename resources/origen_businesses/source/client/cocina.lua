--[[
    LA COCINA — cliente

    · El mueble del punto `kitchen`: un objeto local (cada cliente pone el
      suyo, como los NPC de los puntos) que aparece al acercarse.
    · Abrir: pide al servidor las recetas con lo que hay en la despensa y
      encima, y abre el menú de recetas en modo cocina.
    · Cocinar: el servidor da el visto bueno y enciende el humo; aquí se mira
      al fogón, se hace la animación con la espátula y, al acabar la barra, se
      le pide el plato. Ver source/server/cocina.lua.
]]

Cocina = {}

local C = Config.Cocina

--- [clave 'negocio:indice'] = handle del objeto
local muebles = {}
--- [clave] = lib.points del mueble
local puntosMueble = {}
--- [clave] = true mientras el jugador está en el radio del mueble
local cerca = {}

--- La cocina abierta en el menú: negocio y punto.
local abierta = nil
local cocinandoAhora = false

local function Aviso(texto, tipo)
    Custom.Notify({ title = 'Cocina', description = texto, type = tipo or 'error' })
end

-- ── El mueble ────────────────────────────────────────────────────────────

local function Quitar(clave)
    local obj = muebles[clave]
    muebles[clave] = nil
    if obj and DoesEntityExist(obj) then DeleteEntity(obj) end
end

local function Poner(clave, modelo, coords)
    Quitar(clave)
    -- Con pcall: lib.requestModel lanza un error si el modelo no carga.
    local ok, hash = pcall(lib.requestModel, modelo, 10000)
    if not ok or not hash then return end

    local obj = CreateObject(hash, coords.x, coords.y, coords.z, false, false, false)
    SetEntityHeading(obj, coords.w or 0.0)
    FreezeEntityPosition(obj, true)
    SetEntityInvincible(obj, true)
    SetModelAsNoLongerNeeded(hash)

    -- Se ha podido salir del radio (o quitar el punto) mientras cargaba el
    -- modelo, y dos entradas seguidas cargan dos veces: vale la última.
    if not cerca[clave] then
        DeleteEntity(obj)
        return
    end
    Quitar(clave)
    muebles[clave] = obj
end

--- Lo llama Business:SetPoints por cada punto de cocina.
function Cocina.RegistrarMueble(business, indice, punto, coords)
    local mueble = type(punto.prop) == 'table' and C.Mueble(punto.prop.model)
    if not mueble then return end

    local clave = tostring(business.id) .. ':' .. tostring(indice)
    local p = lib.points.new({ coords = vector3(coords.x, coords.y, coords.z), distance = C.DistanciaMueble })
    puntosMueble[clave] = p

    function p:onEnter()
        cerca[clave] = true
        CreateThread(function() Poner(clave, mueble.model, coords) end)
    end

    function p:onExit()
        cerca[clave] = nil
        Quitar(clave)
    end
end

--- Lo llama Business:ClearPoints: los puntos y los muebles de ese negocio fuera.
function Cocina.QuitarMueblesDe(businessId)
    local prefijo = tostring(businessId) .. ':'
    for clave, p in pairs(puntosMueble) do
        if clave:sub(1, #prefijo) == prefijo then
            p:remove()
            puntosMueble[clave] = nil
            cerca[clave] = nil
            Quitar(clave)
        end
    end
end

--- La lista de muebles para el panel de administración.
RegisterNUICallback('cocina:muebles', function(_, cb)
    cb(C.ParaInterfaz())
end)

-- ── Abrir la cocina ──────────────────────────────────────────────────────

function Cocina.Abrir(business, punto)
    if cocinandoAhora then return end

    local res = lib.callback.await('origen_businesses:cb:cocina:abrir', false, business.id)
    if type(res) ~= 'table' or not res.success then
        Aviso(type(res) == 'table' and res.message or 'No se pudo abrir la cocina.')
        return
    end

    abierta = { negocio = business.id, punto = punto }
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openCraftingPanel',
        data = {
            crafts = res.recetas or {},
            pointType = 'kitchen',
            businessName = res.negocio or business.label,
            businessId = business.id,
            cocina = true,
        }
    })
end

RegisterNUICallback('cocina:despensa', function(_, cb)
    SetNuiFocus(false, false)
    cb('ok')
    if not abierta then return end

    local res = lib.callback.await('origen_businesses:cb:cocina:despensa', false, abierta.negocio)
    if type(res) ~= 'table' or not res.success then
        Aviso(type(res) == 'table' and res.message or 'No se pudo abrir la despensa.')
    end
end)

-- ── Cocinar ──────────────────────────────────────────────────────────────

local function MirarA(coords)
    local ped = cache.ped
    TaskTurnPedToFaceCoord(ped, coords.x, coords.y, coords.z, 700)
    Wait(700)
    ClearPedTasks(ped)
end

--[[ La animación con la espátula en la mano, mientras dure la cocción. A mano y
     no con lib.progressBar: la barra la pone el minijuego. La espátula es un
     objeto de red para que la vean los demás, como la de ox_lib. ]]
local function EmpezarAnimacion()
    local a = C.Animacion
    local ped = cache.ped
    local estado = { activa = true }

    pcall(lib.requestAnimDict, a.dict, 5000)
    TaskPlayAnim(ped, a.dict, a.clip, 3.0, 3.0, -1, 1, 0, false, false, false)

    if a.prop then
        local ok, hash = pcall(lib.requestModel, a.prop.model, 5000)
        if ok and hash then
            local p = GetEntityCoords(ped)
            estado.espatula = CreateObject(hash, p.x, p.y, p.z + 0.2, true, true, false)
            AttachEntityToEntity(estado.espatula, ped, GetPedBoneIndex(ped, a.prop.bone),
                a.prop.pos.x, a.prop.pos.y, a.prop.pos.z, a.prop.rot.x, a.prop.rot.y, a.prop.rot.z,
                true, true, false, true, 1, true)
            SetModelAsNoLongerNeeded(hash)
        end
    end

    -- Si algo la corta (un empujón, otra animación), se vuelve a poner.
    CreateThread(function()
        while estado.activa do
            if not IsEntityPlayingAnim(ped, a.dict, a.clip, 3) then
                TaskPlayAnim(ped, a.dict, a.clip, 3.0, 3.0, -1, 1, 0, false, false, false)
            end
            Wait(500)
        end
    end)

    return estado
end

local function PararAnimacion(estado)
    estado.activa = false
    if estado.espatula and DoesEntityExist(estado.espatula) then DeleteEntity(estado.espatula) end
    ClearPedTasks(cache.ped)
end

--- Lo que contesta la interfaz al acabar el minijuego.
local finMinijuego = nil

RegisterNUICallback('cocina:minijuegoFin', function(data, cb)
    cb('ok')
    if finMinijuego then finMinijuego:resolve(type(data) == 'table' and data or { cancelado = true }) end
end)

local function JugarMinijuego(res)
    if type(res.coords) == 'table' and res.coords.x then MirarA(res.coords) end
    local anim = EmpezarAnimacion()
    local dura = tonumber(res.dura) or 5000
    finMinijuego = promise.new()
    local esta = finMinijuego

    SendNUIMessage({
        action = 'cocina:minijuego',
        data = { receta = res.label, dura = dura, vueltas = res.vueltas or {}, notas = res.notas or {} },
    })

    -- Las teclas las lee Lua: la cámara sigue libre y el personaje no anda ni pega.
    CreateThread(function()
        while finMinijuego == esta do
            for _, control in ipairs({ 21, 22, 23, 24, 25, 30, 31, 32, 33, 34, 35, 36, 37, 38, 44, 45, 73, 140, 141, 142, 143, 257, 263, 264 }) do
                DisableControlAction(0, control, true)
            end
            if IsDisabledControlJustPressed(0, 22) or IsDisabledControlJustPressed(0, 38) then
                SendNUIMessage({ action = 'cocina:golpe' })
            elseif IsDisabledControlJustPressed(0, 73) then
                SendNUIMessage({ action = 'cocina:dejar' })
            end
            Wait(0)
        end
    end)

    SetTimeout(dura + 15000, function()
        if finMinijuego == esta then esta:resolve({ cancelado = true }) end
    end)

    local fin = Citizen.Await(esta)
    finMinijuego = nil
    return fin, anim
end

function Cocina.Cocinar(negocioId, recetaId, cantidad)
    if cocinandoAhora or not negocioId then return end
    cocinandoAhora = true

    local res = lib.callback.await('origen_businesses:cb:cocina:empezar', false, negocioId, recetaId, cantidad)
    if type(res) ~= 'table' or not res.success then
        cocinandoAhora = false
        Aviso(type(res) == 'table' and res.message or 'No se pudo empezar a cocinar.')
        return
    end

    local fin, anim = JugarMinijuego(res)

    if fin.cancelado then
        SendNUIMessage({ action = 'cocina:minijuegoCerrar' })
        TriggerServerEvent('origen_businesses:server:cocina:cancelar')
        Aviso('Has dejado de cocinar.', 'inform')
    else
        local r = lib.callback.await('origen_businesses:cb:cocina:terminar', false, fin.golpes or {})
        if type(r) == 'table' and r.success then
            Aviso(r.message or 'Listo.', r.nota == 'quemado' and 'error' or 'success')
        else
            Aviso(type(r) == 'table' and r.message or 'No se pudo terminar.')
        end
    end

    PararAnimacion(anim)
    cocinandoAhora = false
end

function Cocina.CocinarReceta(data)
    if cocinandoAhora or type(data) ~= 'table' then return { ok = false, error = 'Ya estás cocinando.' } end
    cocinandoAhora = true
    local token, anim
    local ok, resultado = pcall(function()
        local res = lib.callback.await('origen_businesses:server:startRecipeCooking', false, data)
        if type(res) ~= 'table' or not res.ok then
            return type(res) == 'table' and res or { ok = false, error = 'No se pudo empezar a cocinar.' }
        end
        token = res.token

        local fin
        fin, anim = JugarMinijuego({
            coords = res.coords, label = res.label, dura = res.duration,
            vueltas = res.waves, notas = res.notes,
        })

        if fin.cancelado then
            SendNUIMessage({ action = 'cocina:minijuegoCerrar' })
            TriggerServerEvent('origen_businesses:server:cancelRecipeCooking', token)
            token = nil
            return { ok = false, error = 'Preparación cancelada. No se gastaron ingredientes.' }
        end

        return lib.callback.await('origen_businesses:server:finishRecipeCooking', false, {
            token = token,
            golpes = fin.golpes or {},
        })
    end)
    if anim then PararAnimacion(anim) end
    if not ok and token then TriggerServerEvent('origen_businesses:server:cancelRecipeCooking', token) end
    cocinandoAhora = false
    if not ok then return { ok = false, error = 'No se pudo terminar de cocinar.' } end
    return type(resultado) == 'table' and resultado or { ok = false, error = 'No se pudo terminar de cocinar.' }
end

RegisterNUICallback('cocina:cocinar', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
    if type(data) ~= 'table' then return end
    local id = tonumber(data.id)
    local cantidad = math.max(1, math.floor(tonumber(data.quantity) or 1))
    if not id or not abierta then return end
    local negocio = abierta.negocio
    CreateThread(function() Cocina.Cocinar(negocio, id, cantidad) end)
end)

-- ── El fuego: utensilios y humo ─────────────────────────────────────────

--[[ Mientras alguien cocina, encima de su mueble aparecen los utensilios de
     config/cocina.lua (la sartén, la olla, los filetes) y sale humo. Cada
     cliente cercano los pone por su cuenta, igual que el mueble; el servidor
     solo avisa de dónde y cuánto dura. ]]

--- [id del cocinero] = { fx = efecto, objetos = { ... } }
local fuegos = {}

--- Un punto en los ejes del mueble (x ancho, y fondo, z alto) llevado al mundo.
local function AlMundo(c, local_)
    local h = math.rad(c.w or 0.0)
    local cs, sn = math.cos(h), math.sin(h)
    return vector3(
        c.x + local_.x * cs - local_.y * sn,
        c.y + local_.x * sn + local_.y * cs,
        c.z + local_.z
    )
end

function Cocina.ApagarFuego(quien)
    local fuego = fuegos[quien]
    fuegos[quien] = nil
    if not fuego then return end
    for _, fx in ipairs(fuego.efectos) do
        StopParticleFxLooped(fx, false)
        RemoveParticleFx(fx, false)
    end
    for _, obj in ipairs(fuego.objetos) do
        if DoesEntityExist(obj) then DeleteEntity(obj) end
    end
end

--- `c` = { x, y, z, w, prop }: el punto de la cocina, con su giro y su mueble.
function Cocina.EncenderFuego(quien, c, dura)
    Cocina.ApagarFuego(quien)

    local mueble = C.Mueble(c.prop) or C.SinMueble
    local fuego = { objetos = {}, efectos = {} }
    fuegos[quien] = fuego

    for _, u in ipairs(mueble.utensilios or {}) do
        local ok, hash = pcall(lib.requestModel, u.model, 5000)
        if fuegos[quien] ~= fuego then return end -- se apagó mientras cargaba
        if ok and hash then
            local p = AlMundo(c, u.pos)
            local obj = CreateObject(hash, p.x, p.y, p.z, false, false, false)
            local r = u.rot or vec3(0.0, 0.0, 0.0)
            SetEntityRotation(obj, r.x, r.y, (c.w or 0.0) + r.z, 2, true)
            FreezeEntityPosition(obj, true)
            SetEntityCollision(obj, false, false)
            SetModelAsNoLongerNeeded(hash)
            fuego.objetos[#fuego.objetos + 1] = obj
        end
    end

    local h = C.Humo
    if pcall(lib.requestNamedPtfxAsset, h.asset, 5000) and fuegos[quien] == fuego then
        local p = AlMundo(c, mueble.humo or vec3(0.0, 0.0, 1.0))
        for _, e in ipairs(h.efectos) do
            UseParticleFxAsset(h.asset)
            local fx = StartParticleFxLoopedAtCoord(e.nombre, p.x, p.y, p.z, 0.0, 0.0, 0.0, e.escala or 1.0, false, false, false, false)
            if fx and fx ~= 0 then fuego.efectos[#fuego.efectos + 1] = fx end
        end
    end

    -- Por si el aviso de apagarlo no llega: se apaga solo un poco después.
    SetTimeout(math.min(dura, 3600000) + 3000, function()
        if fuegos[quien] == fuego then Cocina.ApagarFuego(quien) end
    end)
end

RegisterNetEvent('origen_businesses:client:cocina:humo', function(quien, c, dura)
    if type(c) ~= 'table' then return end
    local x, y, z = tonumber(c.x), tonumber(c.y), tonumber(c.z)
    dura = tonumber(dura)
    if not x or not y or not z or not dura then return end
    Cocina.EncenderFuego(quien, { x = x, y = y, z = z, w = tonumber(c.w) or 0.0, prop = c.prop }, dura)
end)

RegisterNetEvent('origen_businesses:client:cocina:humoFuera', function(quien)
    Cocina.ApagarFuego(quien)
end)

AddEventHandler('onResourceStop', function(recurso)
    if recurso ~= cache.resource then return end
    for clave in pairs(muebles) do Quitar(clave) end
    for quien in pairs(fuegos) do Cocina.ApagarFuego(quien) end
    if cocinandoAhora then ClearPedTasks(cache.ped) end
end)
