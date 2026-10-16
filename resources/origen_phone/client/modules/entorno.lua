--[[ Lo que el telefono nota del sitio donde estas: cobertura y carga.

     Las dos cosas dependen de donde este el jugador, y por eso se deciden aqui
     y no en el servidor. El servidor no sabe donde esta nadie sin preguntarlo,
     y preguntarlo cada vez que llega un mensaje seria una ida y vuelta por
     mensaje; el cliente lo sabe gratis en cada fotograma.

     Lo que se manda al servidor es solo el resultado —"tengo cobertura", "estoy
     cargando"— y solo cuando cambia. Un jugador quieto en mitad del desierto no
     manda nada en toda la noche.

     Nada de esto se fia del cliente para algo que importe: la cobertura decide
     si **tu propio** telefono te deja llamar, no si el de otro recibe. Mentir
     aqui solo sirve para poder usar tu movil donde no deberias, que es un
     problema de rol y no de seguridad.
]]

--- Cada cuanto se mira. Tres segundos: un coche cruza una zona en menos de eso
--- solo si va muy rapido, y mirar cada fotograma seria gastar por gastar.
local CADA = 3000

--- A que distancia de un punto de carga se considera que estas enchufado.
local ALCANCE_CARGA = 2.5

local ultimaCobertura = nil
local ultimaCarga = nil
local ultimoAbierto = nil

--[[ Si un punto esta dentro de un poligono.

     El metodo de siempre: se tira una raya hacia un lado desde el punto y se
     cuentan los lados que cruza. Impar, dentro; par, fuera. Vale para
     poligonos de cualquier forma, tambien los que tienen entrantes, que es lo
     que sale cuando alguien dibuja una zona a mano en un mapa. ]]
---@param x number
---@param y number
---@param puntos table
---@return boolean
local function Dentro(x, y, puntos)
    local dentro = false
    local j = #puntos

    for i = 1, #puntos do
        local a, b = puntos[i], puntos[j]

        if ((a.y > y) ~= (b.y > y))
            and (x < (b.x - a.x) * (y - a.y) / (b.y - a.y) + a.x) then
            dentro = not dentro
        end

        j = i
    end

    return dentro
end

--- Si hay cobertura donde esta el jugador.
---@param coords vector3
---@return boolean
local function HayCobertura(coords)
    local ajustes = AjustesDelServidor
    local cobertura = ajustes and ajustes.coverage

    if not cobertura or cobertura.mode == 'off' then return true end

    local zonas = cobertura.zones or {}
    if #zonas == 0 then return true end

    local enAlguna = false
    for i = 1, #zonas do
        if Dentro(coords.x, coords.y, zonas[i].points or {}) then
            enAlguna = true
            break
        end
    end

    -- 'none' marca los agujeros; 'only' marca lo unico que tiene señal.
    if cobertura.mode == 'none' then return not enAlguna end
    return enAlguna
end

local function GetChargerReach()
    return (Config.Battery and Config.Battery.ChargerReach) or ALCANCE_CARGA
end

local function GetPropDistance()
    return (Config.Battery and Config.Battery.PropDistance) or 60.0
end

local function BateriaActiva()
    local ajustes = AjustesDelServidor
    local bateria = ajustes and ajustes.battery
    if type(bateria) == 'table' and bateria.enabled ~= nil then return bateria.enabled == true end
    return (Config.Battery and Config.Battery.Enabled == true) or false
end

--- Si esta encima de un punto de carga.
---@param coords vector3
---@return boolean
local function EstaCargando(coords)
    -- La carga se gestiona ahora a través de las estaciones interactivas (cargaDejar / cargaRecoger)
    return false
end

CreateThread(function()
    while true do
        Wait(CADA)

        if not Phone.number and Framework and Framework.GetFirstNumber then
            Phone.number = Framework.GetFirstNumber()
        end

        -- Sin telefono estrenado no hay nada que mirar.
        if Phone.number then
            local coords = GetEntityCoords(PlayerPedId())

            local cobertura = HayCobertura(coords)
            local cargando = EstaCargando(coords)

            --[[ Solo cuando cambia.

                 Mandarlo cada tres segundos serian veinte eventos por minuto y
                 jugador para decir lo mismo. ]]
            if cobertura ~= ultimaCobertura then
                ultimaCobertura = cobertura
                TriggerServerEvent('origen_phone:sv:coverage', cobertura)
                Nui.Send('coverage', { hasSignal = cobertura })
            end

            if cargando ~= ultimaCarga then
                ultimaCarga = cargando
                TriggerServerEvent('origen_phone:sv:charging', cargando)
            end

            -- Abierto en la mano gasta mas bateria que guardado
            local abierto = Phone.open == true
            if abierto ~= ultimoAbierto then
                ultimoAbierto = abierto
                TriggerServerEvent('origen_phone:sv:abierto', abierto)
            end
        end
    end
end)

--[[ Los puntos de carga, marcados en el mapa.

     Se rehacen cuando el panel los cambia: quien los acaba de poner tiene que
     verlos aparecer sin reconectar, que es lo que hace que se puedan ajustar
     mirando el resultado. ]]
local marcas = {}
local blipsCargadores = {}

local function LimpiarBlipsJuego()
    for _, b in ipairs(blipsCargadores) do
        if DoesBlipExist(b) then
            RemoveBlip(b)
        end
    end
    blipsCargadores = {}
end

function PintarPuntosDeCarga()
    LimpiarBlipsJuego()
    marcas = {}

    local ajustes = AjustesDelServidor
    local bateria = ajustes and ajustes.battery
    local sitios = (bateria and bateria.chargers) or {}

    if not BateriaActiva() and #sitios == 0 then
        if OrigenMapa and OrigenMapa.PonerVarios then
            OrigenMapa.PonerVarios('carga', {})
        end
        return
    end

    local puntos = {}

    for i = 1, #sitios do
        local p = sitios[i]
        local x = tonumber(p.x) or 0.0
        local y = tonumber(p.y) or 0.0
        local z = tonumber(p.z) or 0.0
        local nombre = p.name or 'Punto de carga'

        -- 1. Blip nativo de GTA V (minimapa nativo, mapa de pausa ESC)
        local b = AddBlipForCoord(x + 0.0, y + 0.0, z + 0.0)
        if DoesBlipExist(b) then
            SetBlipSprite(b, 354) -- Icono de cargador / rayo eléctrico
            SetBlipDisplay(b, 4)  -- Visible en radar y mapa grande
            SetBlipScale(b, 0.7)
            SetBlipColour(b, 3)   -- Color 3 (Azul cielo / celeste eléctrico)
            SetBlipAsShortRange(b, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName(nombre)
            EndTextCommandSetBlipName(b)
            blipsCargadores[#blipsCargadores + 1] = b
        end

        -- 2. Puntos para OrigenMapa (minimapa Leaflet y mapa de Ciudad / Inventario)
        puntos[#puntos + 1] = {
            id = tostring(i),
            x = x + 0.0, y = y + 0.0, z = z + 0.0,
            cat = 'telefonos',
            icono = 'rayo',
            color = '#38bdf8',
            nombre = nombre,
        }
    end

    if OrigenMapa and OrigenMapa.PonerVarios then
        OrigenMapa.PonerVarios('carga', puntos)
    end
    marcas = puntos
end

-- ---------------------------------------------------------------------------
--  Objetos físicos (Props) en el mundo
-- ---------------------------------------------------------------------------

--[[ El prop de cada cargador (04/10, el usuario: «ya que tiene prop, quita el
     círculo del suelo y el blip ese volando, y usa ese prop»).

     Los cargadores públicos se pintan con el poste propio `prop_phone_charger`
     (recurso [assets]/[props]/prop_phone_charger; origen en la base). Los
     puntos guardados con el modelo que venía por defecto hasta ahora (la
     cabina) pasan al poste; un modelo distinto escrito a mano en el panel se
     respeta. Si el recurso del poste no está arrancado, la cabina de siempre. ]]
local PROP_CARGADOR = 'prop_phone_charger'
local PROP_RESERVA = 'prop_payphone_01a'
local PROPS_DE_ANTES = { [''] = true, prop_parking_pay_01 = true, prop_payphone_01a = true }

---@param modelo any  lo que hay guardado en el punto
---@return string modelo, number hash
function ModeloDeCargador(modelo)
    if type(modelo) ~= 'string' or PROPS_DE_ANTES[modelo] then modelo = PROP_CARGADOR end
    local hash = joaat(modelo)
    if not IsModelInCdimage(hash) then
        modelo = PROP_RESERVA
        hash = joaat(modelo)
    end
    return modelo, hash
end

--- La clave del cargador que se está recolocando, o nil (la pone colocar_cargador.lua).
CargadorApartado = nil

--- [clave] = { ent, firma }
local cargadoresSpawneados = {}
--- [clave] = true mientras se espera a que cargue su modelo
local creandoCargador = {}
local avisoPuesto = false

--- Sitio, rumbo y modelo: si cambia cualquiera, el prop se rehace.
local function FirmaCargador(p)
    return ('%.3f,%.3f,%.3f,%.1f,%s'):format(
        tonumber(p.x) or 0.0, tonumber(p.y) or 0.0, tonumber(p.z) or 0.0, tonumber(p.h) or 0.0, tostring(p.prop))
end

local function BorrarPropCargador(clave)
    local c = cargadoresSpawneados[clave]
    cargadoresSpawneados[clave] = nil
    if c and DoesEntityExist(c.ent) then
        SetEntityAsMissionEntity(c.ent, true, true)
        DeleteEntity(c.ent)
    end
end

local function BorrarTodosLosProps()
    for clave in pairs(cargadoresSpawneados) do
        BorrarPropCargador(clave)
    end
end

local function GetPlayerJobName()
    if LocalPlayer and LocalPlayer.state and LocalPlayer.state.job then
        local j = LocalPlayer.state.job
        return type(j) == 'table' and (j.name or j.id) or tostring(j)
    end
    local qb = GetResourceState('qb-core') == 'started' and exports['qb-core']:GetCoreObject()
    if qb then
        local p = qb.Functions.GetPlayerData()
        if p and p.job then return p.job.name end
    end
    local qbx = GetResourceState('qbx_core') == 'started' and exports.qbx_core:GetPlayerData()
    if qbx and qbx.job then return qbx.job.name end
    local esx = GetResourceState('es_extended') == 'started' and exports['es_extended']:getSharedObject()
    if esx then
        local p = esx.GetPlayerData()
        if p and p.job then return p.job.name end
    end
    return nil
end

local function EsTrabajoExentoClient(exemptJobs)
    if not exemptJobs or exemptJobs == '' then return false end
    local jName = GetPlayerJobName()
    if not jName then return false end
    jName = jName:lower()

    if type(exemptJobs) == 'string' then
        for j in exemptJobs:gmatch('[^,%s;]+') do
            if j:lower() == jName then return true end
        end
    elseif type(exemptJobs) == 'table' then
        for _, j in ipairs(exemptJobs) do
            if tostring(j):lower():gsub('%s+', '') == jName then return true end
        end
    end
    return false
end

local function CrearPropCargador(clave, p)
    local firma = FirmaCargador(p)
    local hay = cargadoresSpawneados[clave]
    if hay then
        if hay.firma == firma and DoesEntityExist(hay.ent) then return end
        -- Lo han girado, cambiado de modelo o movido un pelo: se rehace
        BorrarPropCargador(clave)
    end

    --[[ Uno solo creando cada prop. Esto se llama desde el hilo de cada
         segundo, al llegar ajustes y al guardar un punto, y la espera del
         modelo cede el turno: sin la guarda, dos llamadas a la vez creaban dos
         props en el mismo sitio y uno se quedaba para siempre. ]]
    if creandoCargador[clave] then return end
    creandoCargador[clave] = true

    local _, hash = ModeloDeCargador(p.prop)

    RequestModel(hash)
    local timer = GetGameTimer()
    while not HasModelLoaded(hash) and (GetGameTimer() - timer < 4000) do
        Wait(50)
    end

    creandoCargador[clave] = nil

    if not HasModelLoaded(hash) then
        return
    end

    -- Mientras cargaba han podido crearlo por otro lado
    if cargadoresSpawneados[clave] then
        SetModelAsNoLongerNeeded(hash)
        return
    end

    -- A decimal todo: lo que viene de la base llega entero y un native lo lee
    -- como 0 (un rumbo de 90 dejaba el prop mirando al norte)
    local x, y, z = (tonumber(p.x) or 0) + 0.0, (tonumber(p.y) or 0) + 0.0, (tonumber(p.z) or 0) + 0.0
    -- Sin rumbo guardado (puntos viejos): 0, y se recoloca desde el panel
    local rumbo = ((tonumber(p.h) or 0) + 0.0) % 360.0

    -- Local, sin red: cada cliente pinta el suyo
    local obj = CreateObject(hash, x, y, z, false, false, false)
    SetModelAsNoLongerNeeded(hash)
    if obj and obj ~= 0 and DoesEntityExist(obj) then
        SetEntityCoords(obj, x, y, z, false, false, false, false)
        SetEntityHeading(obj, rumbo)
        FreezeEntityPosition(obj, true)
        SetEntityInvincible(obj, true)
        SetEntityCollision(obj, true, true)
        SetEntityAsMissionEntity(obj, true, true)
        cargadoresSpawneados[clave] = { ent = obj, firma = firma }
    end
end

function ActualizarCargadoresEnMundo()
    local ajustes = AjustesDelServidor
    local bateria = ajustes and ajustes.battery
    local puntos = (bateria and bateria.chargers) or {}

    if #puntos == 0 then
        BorrarTodosLosProps()
        if avisoPuesto then
            lib.hideTextUI()
            avisoPuesto = false
        end
        return
    end

    local yo = GetEntityCoords(PlayerPedId())
    local vivos = {}
    local reachProp = GetPropDistance()

    for i = 1, #puntos do
        local p = puntos[i]
        local clave = ('%.1f:%.1f:%.1f'):format(p.x or 0.0, p.y or 0.0, p.z or 0.0)
        vivos[clave] = true

        -- Solo los cercanos: de lejos no se ven y ocupan sitio en el pool
        local dist = #(yo - vector3(p.x + 0.0, p.y + 0.0, (p.z or 0.0) + 0.0))
        if clave == CargadorApartado then
            -- Se está recolocando desde el panel (colocar_cargador.lua): su
            -- prop fuera mientras tanto, que el rayo chocaba con él
            BorrarPropCargador(clave)
        elseif dist <= reachProp then
            CrearPropCargador(clave, p)
        elseif dist > reachProp + 10.0 then
            BorrarPropCargador(clave)
        end
    end

    for clave in pairs(cargadoresSpawneados) do
        if not vivos[clave] then
            BorrarPropCargador(clave)
        end
    end
end

-- Hilo de streaming de props (cada segundo)
CreateThread(function()
    while true do
        Wait(1000)
        ActualizarCargadoresEnMundo()
    end
end)

-- ---------------------------------------------------------------------------
--  Estación de carga interactiva (estilo origen_businesses con tarifa fija)
-- ---------------------------------------------------------------------------

local estacionAbierta = nil
local puntoCercano = nil
local claveCercana = nil

local function CerrarEstacionCarga()
    if not estacionAbierta then return end
    estacionAbierta = nil
    Foco.Panel('carga', false)
    Nui.Send('cargaClose', {})
end

local function AbrirEstacionCarga(clave, punto)
    if estacionAbierta then return end

    local r = lib.callback.await('origen_phone:carga:ver', false, clave)
    if not r or not r.ok then
        return lib.notify({
            title = 'Punto de carga',
            description = (r and r.mensaje) or 'No se puede usar la estación ahora.',
            type = 'error',
        })
    end

    if Phone and Phone.open then Phone.Close() end
    if CerrarAdmin then CerrarAdmin() end
    if avisoPuesto then
        lib.hideTextUI()
        avisoPuesto = false
    end

    estacionAbierta = { clave = clave, punto = punto }
    Foco.Panel('carga', true)
    Nui.Send('cargaOpen', r)
end

Foco.AlCerrar('carga', function()
    CerrarEstacionCarga()
end)

if OrigenFoco and OrigenFoco.AlSoltar then
    OrigenFoco.AlSoltar(function()
        if not estacionAbierta then return end
        estacionAbierta = nil
        Foco.carga = false
        Nui.Send('cargaClose', {})
    end)
end

Nui.On('cargaCerrar', function()
    CerrarEstacionCarga()
    return true
end)

Nui.On('cargaDejar', function()
    if not estacionAbierta then return { ok = false } end
    local r = lib.callback.await('origen_phone:carga:dejar', false, estacionAbierta.clave)
    if r and r.ok then
        PlaySoundFrontend(-1, 'CONFIRM_BEEP', 'HUD_MINI_GAME_SOUNDSET', true)
    end
    return r or { ok = false }
end)

Nui.On('cargaRecoger', function()
    if not estacionAbierta then return { ok = false } end
    local r = lib.callback.await('origen_phone:carga:recoger', false, estacionAbierta.clave)
    if r and r.ok then
        PlaySoundFrontend(-1, 'CONFIRM_BEEP', 'HUD_MINI_GAME_SOUNDSET', true)
    end
    return r or { ok = false }
end)

Nui.On('cargaVer', function()
    if not estacionAbierta then return { ok = false } end
    local r = lib.callback.await('origen_phone:carga:ver', false, estacionAbierta.clave)
    return r or { ok = false }
end)

--[[ Detección de cercanía y apertura con [E].

     Hasta el 04/10 este hilo pintaba además, en cada cargador, un cilindro
     blanco en el suelo (DrawMarker 1) y un galón blanco flotando encima
     (DrawMarker 2). Fuera los dos: el cargador ya es un prop que se ve solo. ]]
CreateThread(function()
    while true do
        local sleep = 1000

        local ajustes = AjustesDelServidor
        local bateria = ajustes and ajustes.battery
        local chargers = bateria and bateria.chargers

        if chargers and #chargers > 0 then
            local yo = GetEntityCoords(PlayerPedId())
            local yo2D = vec2(yo.x, yo.y)
            local alcanceUso = 2.2
            local encontrado = nil
            local encontradoClave = nil

            for i = 1, #chargers do
                local p = chargers[i]
                local dist = #(yo - vector3(p.x + 0.0, p.y + 0.0, (p.z or yo.z) + 0.0))
                local dist2D = #(yo2D - vec2(p.x + 0.0, p.y + 0.0))
                local diffZ = math.abs(yo.z - (p.z or yo.z))

                -- Cerca de alguno se mira más a menudo, para que el aviso de
                -- la tecla no tarde un segundo en salir
                if dist <= 15.0 and sleep > 250 then sleep = 250 end

                if dist2D <= alcanceUso and diffZ <= 2.5 then
                    encontrado = p
                    encontradoClave = ('%.1f:%.1f:%.1f'):format(p.x or 0.0, p.y or 0.0, p.z or 0.0)
                end
            end

            puntoCercano = encontrado
            claveCercana = encontradoClave

            if puntoCercano and not estacionAbierta then
                sleep = 0
                if not avisoPuesto then
                    local precio = math.max(0, math.floor(tonumber(puntoCercano.price or puntoCercano.precio) or 0))
                    local exento = EsTrabajoExentoClient(puntoCercano.exemptJobs)
                    local tarifaTxt = ''
                    if exento then
                        tarifaTxt = ' · Gratis (Exención trabajo)'
                    elseif precio > 0 then
                        tarifaTxt = ' · $' .. precio
                    else
                        tarifaTxt = ' · Gratis'
                    end
                    lib.showTextUI('[E] Usar punto de carga' .. tarifaTxt, { position = 'left-center', icon = 'bolt' })
                    avisoPuesto = true
                end

                if IsControlJustPressed(0, 38) then -- Tecla E
                    AbrirEstacionCarga(claveCercana, puntoCercano)
                end
            elseif avisoPuesto then
                lib.hideTextUI()
                avisoPuesto = false
            end
        else
            if avisoPuesto then
                lib.hideTextUI()
                avisoPuesto = false
            end
        end

        Wait(sleep)
    end
end)

AddEventHandler('onResourceStop', function(nombre)
    if nombre ~= GetCurrentResourceName() then return end
    CerrarEstacionCarga()
    BorrarTodosLosProps()
    LimpiarBlipsJuego()
    if avisoPuesto then
        lib.hideTextUI()
        avisoPuesto = false
    end
end)

RegisterNetEvent('origen_phone:cl:settings', function(ajustes)
    if type(ajustes) == 'table' then
        AjustesDelServidor = ajustes
    end
    CreateThread(function()
        PintarPuntosDeCarga()
        ActualizarCargadoresEnMundo()
    end)

    ultimaCobertura = nil
    ultimaCarga = nil

    if not Phone.number and Framework and Framework.GetFirstNumber then
        Phone.number = Framework.GetFirstNumber()
    end
    if Phone.number then
        local coords = GetEntityCoords(PlayerPedId())
        local cargando = EstaCargando(coords)
        if cargando ~= ultimaCarga then
            ultimaCarga = cargando
            TriggerServerEvent('origen_phone:sv:charging', cargando)
        end
    end
end)

local function PedirAjustesIniciales()
    CreateThread(function()
        local ok, res = pcall(lib.callback.await, 'origen_phone:getSettings', false)
        if ok and type(res) == 'table' then
            AjustesDelServidor = res
            PintarPuntosDeCarga()
            ActualizarCargadoresEnMundo()
        end
    end)
end

CreateThread(function()
    Wait(1500)
    if not AjustesDelServidor then
        PedirAjustesIniciales()
    else
        PintarPuntosDeCarga()
        ActualizarCargadoresEnMundo()
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    CreateThread(function()
        Wait(1000)
        PedirAjustesIniciales()
    end)
end)

RegisterNetEvent('esx:playerLoaded', function()
    CreateThread(function()
        Wait(1000)
        PedirAjustesIniciales()
    end)
end)

RegisterNetEvent('qbx_core:client:playerLoaded', function()
    CreateThread(function()
        Wait(1000)
        PedirAjustesIniciales()
    end)
end)
