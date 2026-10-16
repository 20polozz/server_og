-- ─────────────────────────────────────────────────────────────────────────────
--  origen_weed · Bidón de agua — Cliente (08/10)
--  Se pone como el tendal (fantasma, flechas, E) y con E cerca se abre su menú:
--  llenar la regadera en el grifo, echarle botellas o recogerlo.
-- ─────────────────────────────────────────────────────────────────────────────
local Conocidos = {}   -- [id] = { coords, heading }
local Puestos   = {}   -- [id] = entidad
local cercaId   = nil
local pista     = false
local colocando = false

local function modelo()
    local h = joaat(Config.Weed.Bidon.prop)
    if HasModelLoaded(h) then return h end
    if not IsModelInCdimage(h) then return nil end
    RequestModel(h)
    local hasta = GetGameTimer() + 10000
    while not HasModelLoaded(h) do
        if GetGameTimer() > hasta then return nil end
        Wait(0)
    end
    return h
end

local function poner(id, d)
    if Puestos[id] then return end
    local h = modelo()
    if not h then return end
    local e = CreateObjectNoOffset(h, d.coords.x, d.coords.y, d.coords.z, false, false, false)
    if not e or e == 0 then return end
    SetEntityHeading(e, d.heading or 0.0)
    FreezeEntityPosition(e, true)
    SetEntityAsMissionEntity(e, true, true)
    Puestos[id] = e
end

local function quitar(id)
    local e = Puestos[id]
    Puestos[id] = nil
    if e and DoesEntityExist(e) then
        SetEntityAsMissionEntity(e, true, true)
        DeleteObject(e)
    end
end

RegisterNetEvent('origen_weed:client:SyncBidones', function(l)
    for id in pairs(Puestos) do quitar(id) end
    Conocidos = {}
    for _, b in ipairs(l or {}) do
        Conocidos[b.id] = { coords = vector3(b.coords.x, b.coords.y, b.coords.z), heading = b.heading }
    end
end)

RegisterNetEvent('origen_weed:client:AddBidon', function(b)
    Conocidos[b.id] = { coords = vector3(b.coords.x, b.coords.y, b.coords.z), heading = b.heading }
    if #(GetEntityCoords(PlayerPedId()) - Conocidos[b.id].coords) <= Config.Weed.World.streamDistance then
        poner(b.id, Conocidos[b.id])
    end
end)

RegisterNetEvent('origen_weed:client:RemoveBidon', function(id)
    Conocidos[id] = nil
    quitar(id)
end)

-- Aparecer y desaparecer por distancia
CreateThread(function()
    Wait(2500)
    TriggerServerEvent('origen_weed:server:RequestBidonSync')
    while true do
        Wait(Config.Weed.World.streamCheckInterval)
        local p = GetEntityCoords(PlayerPedId())
        for id, d in pairs(Conocidos) do
            if #(p - d.coords) <= Config.Weed.World.streamDistance then poner(id, d)
            elseif Puestos[id] then quitar(id) end
        end
    end
end)

-- ── El menú ───────────────────────────────────────────────────────────────────
local function llenarRegadera(id)
    local ped = PlayerPedId()
    local e = Puestos[id]
    if e then TaskTurnPedToFaceEntity(ped, e, 800) Wait(800) end
    local h = joaat('origen_weed_regadera')
    local obj
    if IsModelInCdimage(h) then
        RequestModel(h)
        local t = GetGameTimer() + 3000
        while not HasModelLoaded(h) and GetGameTimer() < t do Wait(0) end
        local p = GetEntityCoords(ped)
        obj = CreateObject(h, p.x, p.y, p.z, true, true, false)
        local hp = Config.Weed.HandProps.water
        AttachEntityToEntity(obj, ped, GetPedBoneIndex(ped, hp.bone), hp.pos.x, hp.pos.y, hp.pos.z, hp.rot.x, hp.rot.y, hp.rot.z, true, true, false, true, 1, true)
    end
    exports['origen_inventory']:progressBar({
        name = 'origen_weed_bidon', duration = 3500, label = 'Llenando la regadera en el grifo...',
        useWhileDead = false, canCancel = true,
        controlDisables = { disableMovement = true, disableCombat = true },
        animation = { animDict = 'amb@medic@standing@kneel@base', anim = 'base', flags = 1 },
    }, nil, nil, function(cancelado)
        ClearPedTasks(ped)
        if obj and DoesEntityExist(obj) then DeleteEntity(obj) end
        if not cancelado then TriggerServerEvent('origen_weed:server:BidonLlenar', id) end
    end)
end

-- Menú de org-menu (el del estilo del servidor), como el resto de menús.
-- No lib.showContext: sale el de ox_lib, oscuro y con otro estilo.
local function abrirMenu(id)
    local d = lib.callback.await('origen_weed:bidon:datos', false, id)
    if not d then return end
    local menu = {
        { header = 'Bidón de agua', isMenuHeader = true, icon = 'fa-solid fa-droplet' },
        {
            header = ('Agua: %d de %d regaderas'):format(d.agua, d.capacidad),
            txt = 'Cuando llueve se llena solo por el embudo',
            icon = 'fa-solid fa-cloud-rain',
            isMenuHeader = true,
        },
        {
            header = 'Llenar la regadera',
            txt = d.agua < 1 and 'El bidón está vacío'
                or (d.vacias > 0 and ('Tienes %d regadera(s) vacía(s)'):format(d.vacias) or 'No llevas ninguna regadera vacía'),
            icon = 'fa-solid fa-faucet-drip',
            disabled = d.vacias < 1 or d.agua < 1,
            params = { isAction = true, event = function() llenarRegadera(id) end },
        },
        {
            header = 'Echarle una botella de agua',
            txt = d.agua >= d.capacidad and 'El bidón ya está lleno'
                or (d.botellas > 0 and ('Vacías una de las %d que llevas: una botella, una regadera'):format(d.botellas) or 'No llevas botellas de agua'),
            icon = 'fa-solid fa-bottle-water',
            disabled = d.botellas < 1 or d.agua >= d.capacidad,
            params = { isAction = true, event = function() TriggerServerEvent('origen_weed:server:BidonRellenar', id) end },
        },
    }
    -- Recogerlo puede cualquiera (09/10); que sea de otro solo cambia el texto.
    menu[#menu + 1] = {
        header = 'Recoger el bidón',
        txt = d.esMio and 'Te lo llevas; el agua que tenga se pierde'
            or 'No es tuyo, pero te lo puedes llevar; el agua que tenga se pierde',
        icon = 'fa-solid fa-hand',
        params = { isAction = true, event = function() TriggerServerEvent('origen_weed:server:BidonRecoger', id) end },
    }
    exports['org-menu']:openMenu(menu)
end

-- Cerca de un bidón: aviso y E
CreateThread(function()
    while true do
        local espera = 600
        local p = GetEntityCoords(PlayerPedId())
        local antes = cercaId
        cercaId = nil
        for id, e in pairs(Puestos) do
            if DoesEntityExist(e) and #(p - GetEntityCoords(e)) <= 2.0 then cercaId = id break end
        end
        if cercaId and not colocando then
            espera = 0
            if not pista or antes ~= cercaId then
                pista = true
                exports['origen_notify']:DrawText('E', 'Usar el bidón')
            end
            if IsControlJustPressed(0, 38) then abrirMenu(cercaId) end
        elseif pista then
            pista = false
            exports['origen_notify']:HideText()
        end
        Wait(espera)
    end
end)

-- ── Colocar ───────────────────────────────────────────────────────────────────
local function rayo(dist)
    local rot, pos = GetGameplayCamRot(), GetGameplayCamCoord()
    local rz, cx = math.rad(rot.z), math.abs(math.cos(math.rad(rot.x)))
    local fin = pos + vector3(-math.sin(rz) * cx, math.cos(rz) * cx, math.sin(math.rad(rot.x))) * dist
    local _, hit, punto = GetShapeTestResult(StartShapeTestRay(pos.x, pos.y, pos.z, fin.x, fin.y, fin.z, 1, -1, 0))
    if hit == 1 then return true, punto end
    local ok, gz = GetGroundZFor_3dCoord(fin.x, fin.y, fin.z + 2.0, false)
    if ok then return true, vector3(fin.x, fin.y, gz) end
    return false, fin
end

local function enZona()
    local r = Config.Weed.Planting
    if not r or not r.enforceValidZones then return true end
    local p = GetEntityCoords(PlayerPedId())
    for _, z in ipairs(r.validZones or {}) do
        if #(p - z.coords) <= z.radius then return true end
    end
    return false
end

RegisterNetEvent('origen_weed:client:UseBidonItem', function()
    if colocando or GetVehiclePedIsIn(PlayerPedId(), false) ~= 0 then return end
    if not enZona() then
        exports['origen_notify']:Notify({ description = 'El bidón va junto a tu cultivo: busca una zona de cultivo', type = 'error', duration = 4000 })
        return
    end
    local h = modelo()
    if not h then return end
    colocando = true
    CreateThread(function()
        local _, punto = rayo(Config.Weed.World.raycastDistance or 7.0)
        local fantasma = CreateObject(h, punto.x, punto.y, punto.z, false, false, false)
        SetEntityCollision(fantasma, false, false)
        SetEntityAlpha(fantasma, 150, true)
        exports['origen_hud']:setupControls({
            { key = 'E', text = 'Colocar' }, { key = '←→', text = 'Rotar' },
        })
        local giro = 0.0
        local valido = false
        while colocando do
            Wait(0)
            DisableControlAction(0, 174, true)
            DisableControlAction(0, 175, true)
            valido, punto = rayo(Config.Weed.World.raycastDistance or 7.0)
            if IsDisabledControlJustPressed(0, 175) then giro = (giro + 15.0) % 360.0 end
            if IsDisabledControlJustPressed(0, 174) then giro = (giro - 15.0) % 360.0 end
            local rumbo = (GetGameplayCamRot().z + 180.0 + giro) % 360.0   -- el grifo mirando al jugador
            SetEntityCoords(fantasma, punto.x, punto.y, punto.z, false, false, false, false)
            SetEntityHeading(fantasma, rumbo)
            if IsControlJustPressed(0, 194) then
                colocando = false
            elseif IsControlJustPressed(0, 38) and valido then
                colocando = false
                TriggerServerEvent('origen_weed:server:CreateBidon', { x = punto.x, y = punto.y, z = punto.z }, rumbo)
            end
        end
        exports['origen_hud']:hideControls()
        DeleteEntity(fantasma)
    end)
end)

AddEventHandler('onResourceStop', function(r)
    if r ~= GetCurrentResourceName() then return end
    for id in pairs(Puestos) do quitar(id) end
end)
