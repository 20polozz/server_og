--[[ Trabajos comunitarios, lado del condenado (ver config/comunitarios.lua).

     Aquí solo se pinta y se pulsa: el uniforme, el punto de la tarea, la
     animación y el contador. Si una tarea cuenta o no lo decide el servidor
     (server/comunitarios.lua). ]]

local Cfg = Config.Comunitarios

local activo = false
local tareas, iniciales = 0, 0
local punto, trabajo = nil, nil
local ocupado = false
local ultimoPunto = nil
local basura = nil

local PUNTO_MAPA = 'comunitarios_punto'

--- El «[E] Barrer» se pone una vez al llegar y se quita al irse, como los
--- puntos de la comisaría (client/civilians.lua): no cada fotograma.
local ayuda = false

local function MostrarAyuda(texto)
    if ayuda then return end
    ayuda = true
    if not Config.CustomNotify and Config.Framework == "qbcore" then
        exports['qb-core']:DrawText("[E] " .. texto, 'left')
    else
        ShowHelpNotification("E", texto)
    end
end

local function OcultarAyuda()
    if not ayuda then return end
    ayuda = false
    HideHelpNotification()
end

-- ─── Uniforme ──────────────────────────────────────────────────

local function Uniforme()
    local ped = PlayerPedId()
    return GetEntityModel(ped) == `mp_f_freemode_01` and Cfg.Uniforme.female or Cfg.Uniforme.male
end

local function PonerUniforme()
    local ped = PlayerPedId()
    for _, p in ipairs(Uniforme()) do
        SetPedComponentVariation(ped, p[1], p[2], p[3], 0)
    end
    for _, prop in ipairs(Cfg.QuitarAccesorios or {}) do
        ClearPedProp(ped, prop)
    end
end

--- Lo lleva puesto si lo último de la lista (el chaleco) coincide.
local function LlevaUniforme()
    local lista = Uniforme()
    local ref = lista[#lista]
    return GetPedDrawableVariation(PlayerPedId(), ref[1]) == ref[2]
end

--- Lo que lleva puesto, prenda por prenda: se guarda en el servidor antes del
--- uniforme y se le vuelve a poner tal cual al terminar.
local ACCESORIOS = { 0, 1, 2, 6, 7 }

local function FotoRopa()
    local ped = PlayerPedId()
    local r = { c = {}, p = {} }
    for c = 1, 11 do
        if c ~= 2 then
            r.c[tostring(c)] = { GetPedDrawableVariation(ped, c), GetPedTextureVariation(ped, c) }
        end
    end
    for _, p in ipairs(ACCESORIOS) do
        r.p[tostring(p)] = { GetPedPropIndex(ped, p), GetPedPropTextureIndex(ped, p) }
    end
    return r
end

--[[ Le devuelve su ropa.

     Con la que se apuntó al empezar, si la hay. Si no (condenas de antes de
     guardarla), la que tiene guardada origen_clothing en la base. Nunca con
     ReApplyAppearance: tira de lo que origen_clothing tiene en memoria, y al
     acabar dejaba puesta media ropa del uniforme. ]]
local function QuitarUniforme(ropa)
    local ped = PlayerPedId()
    if type(ropa) == "table" and type(ropa.c) == "table" then
        for k, v in pairs(ropa.c) do
            SetPedComponentVariation(ped, tonumber(k), v[1], v[2], 0)
        end
        for k, v in pairs(ropa.p or {}) do
            if v[1] < 0 then
                ClearPedProp(ped, tonumber(k))
            else
                SetPedPropIndex(ped, tonumber(k), v[1], v[2], true)
            end
        end
        return
    end
    if GetResourceState("origen_clothing") == "started" then
        exports["origen_clothing"]:ReloadAppearanceData()
    elseif GetResourceState("illenium-appearance") == "started" then
        TriggerEvent("illenium-appearance:client:reloadSkin")
    elseif GetResourceState("qb-clothing") == "started" then
        TriggerServerEvent("qb-clothes:loadPlayerSkin")
    end
end

-- ─── Interfaz ──────────────────────────────────────────────────

local function Contador()
    SendNUIMessage({ action = "Comunitarios", tareas = activo and tareas or nil, iniciales = iniciales })
end

local function QuitarBasura()
    if basura and DoesEntityExist(basura) then DeleteEntity(basura) end
    basura = nil
end

--- La basura del punto: un objeto LOCAL (solo lo ve él), congelado, no pegado.
local function PonerBasura(p)
    QuitarBasura()
    local lista = trabajo.basura
    if not lista or #lista == 0 then return end
    local modelo = joaat(lista[math.random(#lista)])
    if not lib.requestModel(modelo, 5000) then return end
    basura = CreateObject(modelo, p.x, p.y, p.z, false, false, false)
    SetEntityHeading(basura, math.random() * 360.0)
    PlaceObjectOnGroundProperly(basura)
    FreezeEntityPosition(basura, true)
    SetEntityCollision(basura, false, false)
    SetModelAsNoLongerNeeded(modelo)
end

local function QuitarPunto()
    OcultarAyuda()
    QuitarBasura()
    punto, trabajo = nil, nil
    OrigenMapa.Quitar(PUNTO_MAPA)
end

-- ─── Puntos ────────────────────────────────────────────────────

local function EnZona(pos, margen)
    local c = Cfg.Zona.centro
    return #(vector2(pos.x, pos.y) - vector2(c.x, c.y)) <= Cfg.Zona.radio + (margen or 0.0)
end

--- El siguiente sitio: uno de la lista, lejos del anterior. El servidor lo
--- vuelve a mirar.
local function ElegirPunto()
    local candidatos = {}
    for i, p in ipairs(Cfg.Puntos) do
        local v = vector3(p[1], p[2], p[3])
        if not ultimoPunto or #(v.xy - ultimoPunto.xy) >= Cfg.DistanciaEntrePuntos then
            candidatos[#candidatos + 1] = i
        end
    end
    if #candidatos == 0 then return nil end
    return candidatos[math.random(#candidatos)]
end

local function TrabajoPara(suelo)
    local vale = {}
    for _, t in ipairs(Cfg.Trabajos) do
        if not t.suelos or t.suelos[suelo] then vale[#vale + 1] = t end
    end
    return vale[math.random(#vale)] or Cfg.Trabajos[1]
end

local function SiguientePunto()
    while activo and not punto do
        local i = ElegirPunto()
        if i then
            local ok, listo = false, false
            FW_TriggerCallback("origen_police:server:comunitariosPunto", function(r) ok = r; listo = true end, i)
            while not listo do Wait(50) end
            if ok and activo then
                local d = Cfg.Puntos[i]
                punto = vector3(d[1], d[2], d[3])
                trabajo = TrabajoPara(d[4])
                PonerBasura(punto)
                OrigenMapa.Poner(PUNTO_MAPA, {
                    x = punto.x, y = punto.y, z = punto.z,
                    cat = 'trabajos',
                    icono = 'exclamacion',
                    nombre = 'Trabajo comunitario: ' .. trabajo.etiqueta,
                    color = '#f5a623',
                    prioridad = 10,
                })
                return
            end
        end
        Wait(1000)
    end
end

local function Esperar(nombre, ...)
    local r, listo = nil, false
    FW_TriggerCallback(nombre, function(v) r = v; listo = true end, ...)
    local limite = GetGameTimer() + 10000
    while not listo and GetGameTimer() < limite do Wait(50) end
    return r
end

local function HacerTarea()
    if ocupado or not punto then return end
    ocupado = true

    if not Esperar("origen_police:server:comunitariosEmpiezo") then
        ShowNotification("Acércate un poco más al punto", "error")
        ocupado = false
        return
    end

    -- De cara a la basura.
    local ped = PlayerPedId()
    local yo = GetEntityCoords(ped)
    SetEntityHeading(ped, GetHeadingFromVector_2d(punto.x - yo.x, punto.y - yo.y))

    local hecha = lib.progressBar({
        duration = Cfg.DuracionTarea * 1000,
        label = trabajo.etiqueta,
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = { dict = trabajo.anim.dict, clip = trabajo.anim.clip, flag = 1 },
        prop = trabajo.prop,
    })
    ClearPedTasks(PlayerPedId())

    if hecha and activo then
        local r = Esperar("origen_police:server:comunitariosHecho")
        if type(r) == "table" then
            ultimoPunto = punto
            QuitarPunto()
            if (r.tareas or 0) > 0 then
                tareas = r.tareas
                iniciales = r.iniciales or iniciales
                Contador()
                ShowNotification(("Tarea hecha. Te quedan %d"):format(tareas), "success")
            end
        else
            ShowNotification("Esa tarea no ha contado: quédate en el punto hasta el final", "error")
        end
    end
    ocupado = false
end

-- ─── Bucle ─────────────────────────────────────────────────────

local function Llevar()
    local l = Cfg.Llegada
    DoScreenFadeOut(500)
    Wait(600)
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then
        TaskLeaveVehicle(ped, GetVehiclePedIsIn(ped, false), 16)
        Wait(300)
    end
    SetEntityCoords(ped, l.x, l.y, l.z, false, false, false, false)
    SetEntityHeading(ped, l.w or 0.0)
    Wait(500)
    DoScreenFadeIn(500)
end

--- Espera a que el personaje esté de verdad en el mundo (no en el menú de
--- inicio ni con la pantalla en negro).
local function EsperarMundo()
    while activo do
        local ped = PlayerPedId()
        if NetworkIsPlayerActive(PlayerId()) and not IsPlayerSwitchInProgress()
            and IsScreenFadedIn() and IsEntityVisible(ped) and not IsEntityDead(ped) then
            return true
        end
        Wait(1000)
    end
end

local function Empezar(n, ini)
    tareas, iniciales = n, ini or n
    local yaEstaba = activo
    activo = true
    Contador()
    if yaEstaba then
        -- Le han vuelto a condenar mientras cumplía: el servidor empieza de
        -- cero con él, así que hay que volver a decirle que está listo.
        QuitarPunto()
        TriggerServerEvent("origen_police:server:comunitariosListo")
        return
    end
    ultimoPunto = nil

    CreateThread(function()
        EsperarMundo()
        if not activo then return end
        -- Antes del uniforme: lo que lleva, para devolvérselo. El servidor
        -- se queda con la primera y no la pisa si reconecta ya uniformado.
        Esperar("origen_police:server:comunitariosRopa", FotoRopa())
        PonerUniforme()
        if not EnZona(GetEntityCoords(PlayerPedId())) then Llevar() end
        TriggerServerEvent("origen_police:server:comunitariosListo")
        ShowNotification(("Trabajos comunitarios: %d tareas en %s"):format(tareas, Cfg.Zona.nombre), "primary")

        -- Uniforme y punto, sin prisa.
        CreateThread(function()
            while activo do
                if not LlevaUniforme() then PonerUniforme() end
                if not punto and not ocupado then SiguientePunto() end
                Wait(2000)
            end
        end)

        -- Cada fotograma: el marcador, la tecla y lo que no se puede hacer.
        while activo do
            local ped = PlayerPedId()

            DisableControlAction(0, 23, true) -- subir a un vehículo
            for _, c in ipairs({ 24, 25, 37, 140, 141, 142, 257, 263 }) do
                DisableControlAction(0, c, true)
            end
            if IsPedInAnyVehicle(ped, false) then
                TaskLeaveVehicle(ped, GetVehiclePedIsIn(ped, false), 16)
            end

            if punto and not ocupado then
                DrawMarker(2, punto.x, punto.y, punto.z + 0.9, 0.0, 0.0, 0.0, 180.0, 0.0, 0.0,
                    0.35, 0.35, 0.35, 245, 166, 35, 200, true, true, 2, false, nil, nil, false)
                if #(GetEntityCoords(ped) - punto) < 1.8 then
                    MostrarAyuda(trabajo.etiqueta)
                    if IsControlJustReleased(0, 38) then
                        OcultarAyuda()
                        CreateThread(HacerTarea)
                    end
                else
                    OcultarAyuda()
                end
            else
                OcultarAyuda()
            end
            Wait(0)
        end
    end)
end

local function Parar()
    activo = false
    ocupado = false
    tareas, iniciales = 0, 0
    QuitarPunto()
    Contador()
end

-- ─── Eventos del servidor ──────────────────────────────────────

RegisterNetEvent("origen_police:client:comunitariosEmpezar", function(n, ini)
    Empezar(tonumber(n) or 0, tonumber(ini))
end)

RegisterNetEvent("origen_police:client:comunitariosTareas", function(n, ini)
    tareas, iniciales = tonumber(n) or tareas, tonumber(ini) or iniciales
    Contador()
end)

RegisterNetEvent("origen_police:client:comunitariosVolver", function(n, ini)
    if not activo then return end
    tareas, iniciales = tonumber(n) or tareas, tonumber(ini) or iniciales
    Contador()
    QuitarPunto()
    Llevar()
    TriggerServerEvent("origen_police:server:comunitariosListo")
end)

RegisterNetEvent("origen_police:client:comunitariosTerminar", function(cumplida, ropa)
    if not activo then return end
    Parar()
    DoScreenFadeOut(400)
    Wait(500)
    QuitarUniforme(ropa)
    -- De vuelta a la comisaría, a salir por la puerta.
    local ped, sal = PlayerPedId(), Cfg.Salida
    if sal then
        SetEntityCoords(ped, sal.x, sal.y, sal.z, false, false, false, false)
        SetEntityHeading(ped, sal.w or 0.0)
    end
    Wait(500)
    DoScreenFadeIn(400)
    ShowNotification(cumplida and "Has cumplido tus trabajos comunitarios. Eres libre"
        or "Te han levantado los trabajos comunitarios", "success")
end)

-- Al cargar el personaje (y al reiniciar el recurso con él ya dentro).
AddEventHandler("origen_police:client:OnPlayerLoaded", function()
    Wait(3000)
    local r = Esperar("origen_police:server:misComunitarios")
    if type(r) == "table" and (tonumber(r.tareas) or 0) > 0 then
        Empezar(tonumber(r.tareas), tonumber(r.iniciales))
    end
end)

AddEventHandler("origen_police:client:OnPlayerUnload", Parar)

AddEventHandler("onResourceStop", function(res)
    if res == GetCurrentResourceName() and activo then
        OrigenMapa.Quitar(PUNTO_MAPA)
        QuitarBasura()
    end
end)

exports("EnComunitarios", function() return activo end)
