--[[ ── El editor: la vitrina y la vista previa ──────────────────────────────

     Mientras el editor está abierto:

       · La cámara encuadra el coche en el hueco que la hoja deja a la vista
         —el tercio izquierdo en «dividido»— y se gira arrastrando en ese
         hueco. Es lo que permite pintar mirando el resultado.

       · Lo que se pinta se pone en el coche en directo, SOLO para quien
         edita: una DUI propia con la imagen que manda la NUI, enganchada a la
         textura del hueco de livery que usaría este coche. Nada sale del
         cliente hasta que se guarda; al cerrar se devuelve la textura que
         hubiera y la pieza que llevaba el coche. ]]

Editor = {}

local activo = false
local modo = 'dividido'
local vehiculo = 0
local cam = nil

-- La cámara va hacia estos valores y los de ahora se acercan poco a poco:
-- el ratón manda a saltos de 30 por segundo y así no se nota.
local objetivo = { yaw = 0.0, pitch = 12.0, zoom = 1.0 }
local actual = { yaw = 0.0, pitch = 12.0, zoom = 1.0 }
local radio = 5.0

local previa = {
    txd = nil,
    tex = nil,
    dui = nil,
    listo = false,
    pendiente = nil,
    slot = nil,
    modelo = nil,
    modAntes = nil,
    serie = 0,
}

local TXD_PREVIA = 'origen_livery_previa'

local function alVolante()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 or GetPedInVehicleSeat(veh, -1) ~= ped then return 0 end
    return veh
end

local function lerp(a, b, t) return a + (b - a) * t end

--- Ángulos por el camino corto: de 350 a 10 son 20 grados, no 340.
local function lerpAngulo(a, b, t)
    local d = ((b - a + 540) % 360) - 180
    return a + d * t
end

local function colocarCamara()
    if not cam or not DoesEntityExist(vehiculo) then return end

    local centro = GetEntityCoords(vehiculo)
    local min, max = GetModelDimensions(GetEntityModel(vehiculo))
    local alto = (max.z - min.z)
    centro = vector3(centro.x, centro.y, centro.z + (min.z + max.z) / 2 + alto * 0.08)

    local y = math.rad(actual.yaw)
    local p = math.rad(actual.pitch)
    -- En «dividido» el coche tiene que caber en un tercio de pantalla: más lejos.
    local dist = radio * actual.zoom * (modo == 'dividido' and 1.35 or 1.0)

    local haciaCam = vector3(-math.sin(y) * math.cos(p), math.cos(y) * math.cos(p), math.sin(p))
    local pos = centro + haciaCam * dist

    --[[ El desplazamiento lateral. Mover cámara y punto de mira a la vez hacia
         la derecha de la cámara deja el coche a la izquierda de la imagen sin
         torcer la perspectiva. El hueco del juego está centrado en el 17 % del
         ancho, o sea a un 66 % de medio ancho del centro. ]]
    if modo == 'dividido' then
        local adelante = centro - pos
        local derecha = vector3(adelante.y, -adelante.x, 0.0)
        local largo = #derecha
        if largo > 0.001 then
            derecha = derecha / largo
            local ancho, altoPx = GetActiveScreenResolution()
            local aspecto = (altoPx and altoPx > 0) and (ancho / altoPx) or (16 / 9)
            local medioAncho = math.tan(math.rad(GetCamFov(cam) / 2)) * aspecto * dist
            local desplazar = derecha * (medioAncho * 0.66)
            pos = pos + desplazar
            centro = centro + desplazar
        end
    end

    SetCamCoord(cam, pos.x, pos.y, pos.z)
    PointCamAtCoord(cam, centro.x, centro.y, centro.z)
end

local function empezarCamara()
    if cam then return end
    local min, max = GetModelDimensions(GetEntityModel(vehiculo))
    radio = math.max(max.x - min.x, max.y - min.y, max.z - min.z) * 1.15 + 2.0

    -- De tres cuartos por delante, que es donde una livery se lee entera.
    objetivo.yaw = GetEntityHeading(vehiculo) + 140.0
    objetivo.pitch = 14.0
    objetivo.zoom = 1.0
    actual.yaw, actual.pitch, actual.zoom = objetivo.yaw, objetivo.pitch, objetivo.zoom

    cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamFov(cam, 40.0)
    colocarCamara()
    RenderScriptCams(true, true, 450, true, true)

    CreateThread(function()
        while activo and cam do
            actual.yaw = lerpAngulo(actual.yaw, objetivo.yaw, 0.18)
            actual.pitch = lerp(actual.pitch, objetivo.pitch, 0.18)
            actual.zoom = lerp(actual.zoom, objetivo.zoom, 0.15)
            colocarCamara()
            HideHudAndRadarThisFrame()
            Wait(0)
        end
    end)
end

local function pararCamara()
    if not cam then return end
    RenderScriptCams(false, true, 450, true, true)
    local vieja = cam
    cam = nil
    SetTimeout(500, function() DestroyCam(vieja, false) end)
end

--[[ ── La vista previa ──────────────────────────────────────────────────── ]]

--- Qué hueco se usa para mirar: el que ya es de este coche, si no el primero
--- que no tenga nadie, y si están todos cogidos el primero. Es solo local: a
--- otro coche del mismo modelo que tengas delante también le cambiaría
--- mientras editas, pero nadie más lo ve.
local function elegirHueco(target, layout)
    if target.assignment and target.assignment.slotId then
        for _, h in ipairs(layout) do
            if h.id == target.assignment.slotId then return h end
        end
    end

    local cogidos = {}
    for _, s in ipairs(target.slots or {}) do cogidos[s.id] = true end
    for _, h in ipairs(layout) do
        if not cogidos[h.id] then return h end
    end

    return layout[1]
end

local function texturasDe(slot)
    local lista = {}
    for _, t in ipairs(slot.textures or {}) do
        if type(t) == 'string' and t ~= '' then lista[#lista + 1] = t end
    end
    if #lista == 0 and slot.texture then lista[1] = slot.texture end
    return lista
end

local function engancharPrevia()
    local s = previa.slot
    if not s or not previa.listo then return end
    for _, t in ipairs(texturasDe(s)) do
        RemoveReplaceTexture(s.txd, t)
        AddReplaceTexture(s.txd, t, TXD_PREVIA, previa.tex)
    end
end

local function soltarPrevia()
    local s = previa.slot
    if s then
        for _, t in ipairs(texturasDe(s)) do
            RemoveReplaceTexture(s.txd, t)
        end
    end

    if previa.dui then
        DestroyDui(previa.dui)
        previa.dui = nil
    end

    previa.listo = false
    previa.pendiente = nil

    if s and previa.modelo then
        -- La livery de verdad que hubiera en ese hueco vuelve a su sitio.
        Livery.marcarPrevia(previa.modelo, s.id, false)
        Livery.rebind(previa.modelo, s.id)
    end

    if DoesEntityExist(vehiculo) then
        Livery.pausar(vehiculo, false)
        local target = Livery.target()
        local tieneAsignada = target and target.assignment ~= nil
        if not tieneAsignada and s and previa.modAntes ~= nil and NetworkHasControlOfEntity(vehiculo) then
            SetVehicleModKit(vehiculo, 0)
            SetVehicleMod(vehiculo, Config.LiveryModType, previa.modAntes, false)
        end
        Livery.enforce(vehiculo)
    end

    previa.slot = nil
    previa.modelo = nil
    previa.modAntes = nil
end

local function prepararPrevia()
    if previa.slot or not DoesEntityExist(vehiculo) then return end

    local target = Livery.target()
    if not target then return end

    local info = lib.callback.await('origen_livery:layout', false, target.model)
    local layout = type(info) == 'table' and info.layout or {}
    local slot = elegirHueco(target, layout)
    if not slot or not activo then return end

    previa.slot = slot
    previa.modelo = target.model
    Livery.marcarPrevia(target.model, slot.id, true)
    previa.modAntes = GetVehicleMod(vehiculo, Config.LiveryModType)

    Livery.pausar(vehiculo, true)
    SetVehicleModKit(vehiculo, 0)
    SetVehicleMod(vehiculo, Config.LiveryModType, slot.modIndex, false)

    if not previa.txd then previa.txd = CreateRuntimeTxd(TXD_PREVIA) end

    -- Un nombre de textura por sesión: una DUI destruida no se puede volver a
    -- colgar del mismo nombre.
    previa.serie = previa.serie + 1
    previa.tex = ('previa_%d'):format(previa.serie)

    local pagina = ('https://cfx-nui-%s/html/dui.html'):format(GetCurrentResourceName())
    local dui = CreateDui(pagina, Config.DuiSize, Config.DuiSize)
    previa.dui = dui

    local tope = GetGameTimer() + 10000
    while not IsDuiAvailable(dui) and GetGameTimer() < tope and previa.dui == dui do Wait(50) end
    if previa.dui ~= dui then return end

    CreateRuntimeTextureFromDuiHandle(previa.txd, previa.tex, GetDuiHandle(dui))
    previa.listo = true

    -- La textura de una pieza solo se puede sustituir cuando la pieza ya está
    -- cargada, y acabamos de ponerla: se engancha varias veces mientras llega.
    for _, espera in ipairs({ 0, 150, 350, 750, 1500 }) do
        if espera > 0 then Wait(espera) end
        if previa.dui ~= dui then return end
        if previa.pendiente then
            SendDuiMessage(dui, json.encode({ image = previa.pendiente }))
        end
        engancharPrevia()
    end
end

function Editor.vistaPrevia(imagen)
    if not activo then return end
    if type(imagen) ~= 'string' or #imagen > 6000000 or not imagen:find('^data:image/[%w]+;base64,') then return end

    previa.pendiente = imagen

    if previa.listo and previa.dui then
        SendDuiMessage(previa.dui, json.encode({ image = imagen }))
        return
    end

    if not previa.slot and not previa.preparando then
        previa.preparando = true
        CreateThread(function()
            prepararPrevia()
            previa.preparando = false
        end)
    end
end

--[[ ── Encender y apagar ─────────────────────────────────────────────────── ]]

function Editor.poner(abierto, nuevoModo)
    if nuevoModo == 'dividido' or nuevoModo == 'completo' then modo = nuevoModo end

    if not abierto then
        Editor.parar()
        return
    end

    if activo then return end

    local veh = alVolante()
    if veh == 0 then return end

    activo = true
    vehiculo = veh
    empezarCamara()

    -- Si bajas del coche o lo pierdes, se apaga todo y la pantalla se entera.
    CreateThread(function()
        while activo do
            Wait(500)
            if alVolante() ~= vehiculo then
                Editor.parar()
                AvisarNuiSinCoche()
            end
        end
    end)
end

function Editor.parar()
    if not activo then return end
    activo = false
    pararCamara()
    soltarPrevia()
end

function Editor.camara(dx, dy, zoom)
    if not activo then return end
    objetivo.yaw = objetivo.yaw - dx * 0.35
    objetivo.pitch = math.max(-8.0, math.min(65.0, objetivo.pitch + dy * 0.25))
    if zoom ~= 0 then
        objetivo.zoom = math.max(0.45, math.min(2.2, objetivo.zoom * (zoom > 0 and 1.1 or 0.9)))
    end
end

AddEventHandler('onResourceStop', function(nombre)
    if nombre ~= GetCurrentResourceName() then return end
    if cam then
        RenderScriptCams(false, false, 0, true, true)
        DestroyCam(cam, false)
        cam = nil
    end
    activo = false
    soltarPrevia()
end)
