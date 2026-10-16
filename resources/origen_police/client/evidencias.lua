--[[ Las evidencias, vistas con la linterna.

     Como en una escena de verdad: alumbras el suelo y lo que cae dentro del
     haz queda marcado. Cada evidencia marcada lleva:

       · una diana plana en el suelo, en el punto exacto;
       · una placa amarilla de pie a su lado, con su número (el mismo para
         todos los agentes: lo pone el servidor por escena);
       · al acercarte, una ficha con qué es y cuándo pasó.

     Las placas y la diana son planos en el mundo (DrawTexturedPoly) sobre una
     textura de html/evidencias/atlas.png. La ficha es una página pequeña
     (html/evidencias/ficha.html) pintada como textura (DUI).

     Lo que hay y lo que no lo dice el servidor (server/evidences.lua); aquí no
     se decide nada: se pide la lista, se dibuja y se pide recoger. ]]

local TXD_NOMBRE = "origen_evidencias"
local txd = CreateRuntimeTxd(TXD_NOMBRE)
CreateRuntimeTextureFromImage(txd, "atlas", "html/evidencias/atlas.png")

local LINTERNA = `WEAPON_FLASHLIGHT`

-- El haz: hasta dónde llega y cómo de abierto es.
local HAZ_ALCANCE = 16.0
local HAZ_ANGULO = math.cos(math.rad(24.0))

-- Hasta dónde se siguen viendo las ya marcadas.
local VER_MARCADAS = 30.0

--- Las evidencias cerca, por id, tal como las manda el servidor, más lo que
--- se calcula aquí una vez (suelo, si está en una pared).
local lista = {}

--- Las que ya se han alumbrado.
local marcadas = {}

--- Para la cámara de fotos: mientras está abierta se ve todo lo cercano.
local modoFoto = false

-- ─── Qué es cada una ─────────────────────────────────────────────

local TIPOS = {
    Shoot = { titulo = "Casquillo", icono = "casquillo", plural = "casquillos" },
    Impact = { titulo = "Impacto de bala", icono = "impacto", plural = "impactos" },
    BloodRest = { titulo = "Mancha de sangre", icono = "sangre", plural = "manchas" },
    NpcBlood = { titulo = "Mancha de sangre", icono = "sangre", plural = "manchas" },
    VehCrash = { titulo = "Restos de vehículo", icono = "vehiculo", plural = "golpes" },
    Drug = { titulo = "Sustancia", icono = "sustancia", plural = "muestras" },
}

local function Hace(segundos)
    segundos = math.max(0, math.floor(segundos or 0))
    if segundos < 60 then return "hace un momento" end
    local m = math.floor(segundos / 60)
    if m < 60 then return ("hace %d min"):format(m) end
    return ("hace %d h %02d min"):format(math.floor(m / 60), m % 60)
end

local function Ficha(ev)
    local t = TIPOS[ev.type] or { titulo = "Evidencia", icono = "otra", plural = "unidades" }
    local detalle = {}
    if ev.ammo and ev.ammo ~= "Sin Clasificar" then
        detalle[#detalle + 1] = ev.ammo:gsub("%s*%[.-%]", "")
    end
    if ev.model then detalle[#detalle + 1] = ev.model end
    if ev.type == "BloodRest" or ev.type == "NpcBlood" then detalle[#detalle + 1] = "Muestra de ADN" end
    if (ev.count or 1) > 1 then detalle[#detalle + 1] = ("%d %s"):format(ev.count, t.plural) end
    detalle[#detalle + 1] = Hace(ev.edadLocal())
    return {
        n = ev.n,
        kicker = ("Evidencia %02d"):format(ev.n or 0),
        icono = t.icono,
        titulo = t.titulo,
        detalle = detalle,
    }
end

-- ─── La lista ────────────────────────────────────────────────────

--- El suelo bajo la evidencia, una vez. Si la evidencia está alta (un impacto
--- en una pared), la diana va de cara en la pared y la placa en el suelo.
local function Preparar(ev)
    ev.coords = vector3(ev.x, ev.y, ev.z)
    local ok, suelo = GetGroundZFor_3dCoord(ev.x, ev.y, ev.z + 1.0, false)
    ev.suelo = ok and suelo or ev.z - 1.0
    ev.enPared = ev.type == "Impact" and ev.z - ev.suelo > 0.6
    if not ev.enPared then ev.coords = vector3(ev.x, ev.y, ev.suelo) end
    local recibida = GetGameTimer()
    local edad = ev.edad or 0
    ev.edadLocal = function() return edad + (GetGameTimer() - recibida) / 1000 end
end

local function Actualizar(nueva)
    local vistas = {}
    for _, ev in ipairs(nueva or {}) do
        vistas[ev.id] = true
        local vieja = lista[ev.id]
        if vieja then
            vieja.count = ev.count
        else
            Preparar(ev)
            lista[ev.id] = ev
        end
    end
    for id in pairs(lista) do
        if not vistas[id] then
            lista[id] = nil
            marcadas[id] = nil
        end
    end
end

local function Pedir()
    local listo = false
    FW_TriggerCallback("origen_police:callback:GetEvidences", function(r)
        if type(r) == "table" then Actualizar(r) end
        listo = true
    end)
    local limite = GetGameTimer() + 5000
    while not listo and GetGameTimer() < limite do Wait(50) end
end

RegisterNetEvent("origen_police:client:rmevidence", function(id)
    lista[id] = nil
    marcadas[id] = nil
end)

--- La cámara de fotos (client/evidences.lua) enseña todo lo cercano.
function EvidenciasModoFoto(activo, datos)
    modoFoto = activo
    if activo and datos then Actualizar(datos) end
end

-- ─── Dibujo ──────────────────────────────────────────────────────

--- Una celda del atlas (8 x 6 de 128 px sobre 1024 x 768).
local function Celda(col, fila)
    return col / 8, fila / 6, (col + 1) / 8, (fila + 1) / 6
end

local function CeldaPlaca(n)
    n = math.max(1, math.min(40, n or 1))
    return Celda((n - 1) % 8, math.floor((n - 1) / 8))
end

--- Un rectángulo en el mundo, visible por las dos caras.
local function Plano(c, derecha, arriba, u0, v0, u1, v1, alfa)
    local bl, br = c - derecha - arriba, c + derecha - arriba
    local tl, tr = c - derecha + arriba, c + derecha + arriba
    alfa = alfa or 255
    DrawTexturedPoly(bl.x, bl.y, bl.z, br.x, br.y, br.z, tr.x, tr.y, tr.z, 255, 255, 255, alfa, TXD_NOMBRE, "atlas", u0, v1, 0.0, u1, v1, 0.0, u1, v0, 0.0)
    DrawTexturedPoly(bl.x, bl.y, bl.z, tr.x, tr.y, tr.z, tl.x, tl.y, tl.z, 255, 255, 255, alfa, TXD_NOMBRE, "atlas", u0, v1, 0.0, u1, v0, 0.0, u0, v0, 0.0)
    DrawTexturedPoly(bl.x, bl.y, bl.z, tr.x, tr.y, tr.z, br.x, br.y, br.z, 255, 255, 255, alfa, TXD_NOMBRE, "atlas", u0, v1, 0.0, u1, v0, 0.0, u1, v1, 0.0)
    DrawTexturedPoly(bl.x, bl.y, bl.z, tl.x, tl.y, tl.z, tr.x, tr.y, tr.z, 255, 255, 255, alfa, TXD_NOMBRE, "atlas", u0, v1, 0.0, u0, v0, 0.0, u1, v0, 0.0)
end

local function Dibujar(ev, cam, cerca)
    local c = ev.coords
    local hacia = vector3(cam.x - c.x, cam.y - c.y, 0.0)
    local largo = #hacia
    if largo < 0.01 then hacia = vector3(0.0, 1.0, 0.0) else hacia = hacia / largo end
    local lado = vector3(-hacia.y, hacia.x, 0.0)

    -- La diana: plana en el suelo, o de cara si está en una pared.
    local u0, v0, u1, v1 = Celda(cerca and 1 or 0, 5)
    local r = 0.26
    if ev.enPared then
        Plano(c + hacia * 0.02, lado * r, vector3(0.0, 0.0, r), u0, v0, u1, v1, 255)
    else
        -- 3,5 cm por encima: GetGroundZ no es exacto en cuesta y la diana se
        -- quedaba medio enterrada.
        Plano(c + vector3(0.0, 0.0, 0.035), vector3(r, 0.0, 0.0), vector3(0.0, r, 0.0), u0, v0, u1, v1, 255)
    end

    -- La placa: de pie en el suelo, al lado, mirando hacia ti.
    local pie = vector3(ev.x, ev.y, ev.suelo) + lado * 0.42
    local an, al = 0.12, 0.12
    u0, v0, u1, v1 = CeldaPlaca(ev.n)
    Plano(pie + vector3(0.0, 0.0, al) + hacia * 0.01, lado * an, vector3(0.0, 0.0, al), u0, v0, u1, v1, 255)
end

-- ─── La ficha (DUI) ──────────────────────────────────────────────

local dui, duiListo, fichaDe, fichaTexto = nil, false, nil, nil
local duiUsada = 0

local function AsegurarDui()
    if dui then return true end
    local url = ("https://cfx-nui-%s/html/evidencias/ficha.html"):format(GetCurrentResourceName())
    dui = CreateDui(url, 600, 168)
    CreateRuntimeTextureFromDuiHandle(txd, "ficha", GetDuiHandle(dui))
    duiListo = false
    CreateThread(function()
        local limite = GetGameTimer() + 5000
        while dui and not IsDuiAvailable(dui) and GetGameTimer() < limite do Wait(100) end
        Wait(300)
        duiListo = dui ~= nil
    end)
    return true
end

local function SoltarDui()
    if dui then DestroyDui(dui) end
    dui, duiListo, fichaDe, fichaTexto = nil, false, nil, nil
end

local function PintarFicha(ev)
    AsegurarDui()
    duiUsada = GetGameTimer()
    if not duiListo then return end
    local datos = json.encode(Ficha(ev))
    if fichaDe ~= ev.id or fichaTexto ~= datos then
        SendDuiMessage(dui, datos)
        fichaDe, fichaTexto = ev.id, datos
        return
    end
    local ancho, alto = GetActiveScreenResolution()
    -- Al lado de la placa y por encima, sin tapar ni la evidencia ni al que
    -- la mira.
    local w = 0.15
    local h = w * (168 / 600) * (ancho / alto)
    local cam = GetFinalRenderedCamCoord()
    local hacia = vector3(cam.x - ev.x, cam.y - ev.y, 0.0)
    hacia = #hacia > 0.01 and hacia / #hacia or vector3(0.0, 1.0, 0.0)
    local pie = vector3(ev.x, ev.y, ev.suelo) + vector3(-hacia.y, hacia.x, 0.0) * 0.42
    SetDrawOrigin(pie.x, pie.y, pie.z + 0.3, false)
    DrawSprite(TXD_NOMBRE, "ficha", w / 2 + 0.012, -h / 2, w, h, 0.0, 255, 255, 255, 255)
    ClearDrawOrigin()
end

CreateThread(function()
    while true do
        Wait(10000)
        if dui and GetGameTimer() - duiUsada > 60000 then SoltarDui() end
    end
end)

-- ─── Recoger / limpiar ───────────────────────────────────────────

local ayuda = false
local function MostrarAyuda(texto)
    if ayuda == texto then return end
    ayuda = texto
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

local ocupado = false
local function Recoger(ev, esPolicia)
    if ocupado then return end
    ocupado = true
    OcultarAyuda()
    local def = Config.Evidences[ev.type] or {}
    local hecho = lib.progressBar({
        duration = 1600,
        label = esPolicia and "Recogiendo evidencia" or "Limpiando",
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = def.anim ~= false and { dict = "pickup_object", clip = "pickup_low", flag = 1 } or nil,
    })
    ClearPedTasks(PlayerPedId())
    if hecho and lista[ev.id] then
        if esPolicia then
            TriggerServerEvent("origen_police:server:GetEvidence", ev.id)
        else
            TriggerServerEvent("origen_police:server:RemoveEvidence", ev.id)
        end
    end
    ocupado = false
end

-- ─── Bucles ──────────────────────────────────────────────────────

local function ConLinterna()
    return GetSelectedPedWeapon(PlayerPedId()) == LINTERNA
end

local function Alumbrando()
    local ped = PlayerPedId()
    return ConLinterna() and (IsPlayerFreeAiming(PlayerId()) or GetPedConfigFlag(ped, 78, true))
end

--- Pide la lista mientras hay linterna en la mano (o cámara, o placas a la
--- vista), cada 2 s. Sin nada de eso no pide nada.
CreateThread(function()
    while true do
        local espera = 1500
        if Config.EvidenceSystem and (ConLinterna() or modoFoto or next(marcadas)) then
            Pedir()
            espera = 2000
        elseif next(lista) then
            lista, marcadas = {}, {}
        end
        Wait(espera)
    end
end)

--- Cada fotograma, solo cuando hay algo que hacer.
CreateThread(function()
    while true do
        if not next(lista) then
            OcultarAyuda()
            Wait(500)
        elseif not next(marcadas) and not modoFoto and not Alumbrando() then
            Wait(150)
        else
            local ped = PlayerPedId()
            local pos = GetEntityCoords(ped)
            local cam = GetFinalRenderedCamCoord()

            -- El haz: lo que cae dentro del cono de la cámara al apuntar.
            if Alumbrando() or modoFoto then
                local rot = GetFinalRenderedCamRot(2)
                local rx, rz = math.rad(rot.x), math.rad(rot.z)
                local dir = vector3(-math.sin(rz) * math.cos(rx), math.cos(rz) * math.cos(rx), math.sin(rx))
                for id, ev in pairs(lista) do
                    if not marcadas[id] then
                        local v = ev.coords - cam
                        local d = #v
                        if modoFoto and d < 60.0 or d < HAZ_ALCANCE and (v / d).x * dir.x + (v / d).y * dir.y + (v / d).z * dir.z > HAZ_ANGULO then
                            marcadas[id] = true
                        end
                    end
                end
            end

            -- Dibujar las marcadas y buscar la más cercana.
            local cercana, dCercana = nil, 99.0
            for id in pairs(marcadas) do
                local ev = lista[id]
                if ev then
                    local d = #(pos - ev.coords)
                    if d < VER_MARCADAS then
                        if d < dCercana then cercana, dCercana = ev, d end
                    end
                end
            end
            for id in pairs(marcadas) do
                local ev = lista[id]
                if ev and #(pos - ev.coords) < VER_MARCADAS then
                    Dibujar(ev, cam, ev == cercana and dCercana < 1.6)
                end
            end

            -- La ficha de la más cercana y la tecla para recogerla.
            if cercana and dCercana < 3.0 and not ocupado then
                PintarFicha(cercana)
            end
            if cercana and dCercana < 1.6 and ConLinterna() and not ocupado and not modoFoto then
                local PlayerData = FW_GetPlayerData(false)
                local esPolicia = PlayerData and PlayerData.job and CanOpenTablet(PlayerData.job.name)[1]
                MostrarAyuda(esPolicia and Config.Translations.CollectEvidence or Config.Translations.ClearEvidence)
                if IsControlJustPressed(0, 38) then
                    CreateThread(function() Recoger(cercana, esPolicia) end)
                end
            else
                OcultarAyuda()
            end
            Wait(0)
        end
    end
end)

AddEventHandler("onResourceStop", function(res)
    if res == GetCurrentResourceName() then SoltarDui() end
end)

