--[[
    LAS CÁMARAS DE SEGURIDAD — cliente

    · El objeto: cada punto `camera` cuelga su modelo en la pared, como el
      mueble de la cocina (un objeto local que aparece al acercarse).
    · Mirar: desde la pestaña Cámaras del panel. El servidor dice qué cámaras
      te deja ver; aquí se pone una cámara de script en el objetivo de la que
      elijas, con el efecto de vigilancia, y se gira con el ratón.

    Teclas mientras miras:
      ratón         girar (con tope a cada lado, ver Config.Camaras.Giro)
      rueda         acercar y alejar
      ← → / A D     cámara anterior y siguiente
      ESC / ⌫       dejar de mirar y volver a la lista

    Se deja de mirar solo si te hieren o mueres: estás plantado en otro sitio
    y no puedes quedarte ciego a lo que te pasa. Ver config/camaras.lua.
]]

Camaras = {}

local C = Config.Camaras

-- ── El objeto colgado ─────────────────────────────────────────────────────

--- [clave 'negocio:indice'] = handle del objeto
local objetos = {}
--- [clave] = lib.points del objeto
local puntosObjeto = {}
--- [clave] = true mientras el jugador está en el radio
local cerca = {}

local function Quitar(clave)
    local obj = objetos[clave]
    objetos[clave] = nil
    if obj and DoesEntityExist(obj) then DeleteEntity(obj) end
end

local function Poner(clave, modelo, coords)
    Quitar(clave)
    local ok, hash = pcall(lib.requestModel, modelo, 10000)
    if not ok or not hash then return end

    local obj = CreateObject(hash, coords.x, coords.y, coords.z, false, false, false)
    SetEntityHeading(obj, coords.w or 0.0)
    FreezeEntityPosition(obj, true)
    SetEntityInvincible(obj, true)
    SetModelAsNoLongerNeeded(hash)

    -- Se pudo salir del radio mientras cargaba el modelo, y dos entradas
    -- seguidas cargan dos veces: vale la última.
    if not cerca[clave] then
        DeleteEntity(obj)
        return
    end
    Quitar(clave)
    objetos[clave] = obj
end

--- Lo llama Business:SetPoints por cada punto de cámara.
function Camaras.RegistrarObjeto(business, indice, punto, coords)
    local modelo = type(punto.prop) == 'table' and C.Modelo(punto.prop.model)
    if not modelo then return end

    local clave = tostring(business.id) .. ':' .. tostring(indice)
    local p = lib.points.new({ coords = vector3(coords.x, coords.y, coords.z), distance = C.DistanciaObjeto })
    puntosObjeto[clave] = p

    function p:onEnter()
        cerca[clave] = true
        CreateThread(function() Poner(clave, modelo.model, coords) end)
    end

    function p:onExit()
        cerca[clave] = nil
        Quitar(clave)
    end
end

--- Lo llama Business:ClearPoints: los puntos y los objetos de ese negocio fuera.
function Camaras.QuitarObjetosDe(businessId)
    local prefijo = tostring(businessId) .. ':'
    for clave, p in pairs(puntosObjeto) do
        if clave:sub(1, #prefijo) == prefijo then
            p:remove()
            puntosObjeto[clave] = nil
            cerca[clave] = nil
            Quitar(clave)
        end
    end
end

-- ── Mirar ─────────────────────────────────────────────────────────────────

--[[ Lo que se está mirando, o nil.
     { negocioId, negocio, lista, actual, cam, rumbo, inclinacion, fov, base } ]]
local viendo = nil

--- Dónde queda el objetivo: el objeto mira hacia su -Y, un poco por delante
--- y por debajo del punto donde se colgó.
local function Objetivo(c)
    local h = math.rad(c.w or 0.0)
    local d = C.Desfase
    return vector3(c.x + math.sin(h) * d.adelante, c.y - math.cos(h) * d.adelante, c.z - d.abajo)
end

--- El rumbo hacia el que mira de frente la cámara colgada.
local function RumboBase(c)
    return ((c.w or 0.0) + 180.0) % 360.0
end

local function Limitar(v, min, max)
    if v < min then return min end
    if v > max then return max end
    return v
end

--- La diferencia de rumbo con signo, de -180 a 180.
local function Diferencia(a, b)
    return (a - b + 540.0) % 360.0 - 180.0
end

local function Aviso(texto, tipo)
    Custom.Notify({ title = 'Cámaras', description = texto, type = tipo or 'error' })
end

--- Pone la cámara de script en la cámara `n` de la lista.
local function Enfocar(n)
    local cam = viendo.lista[n]
    if not cam then return end
    viendo.actual = n

    local pos = Objetivo(cam.coords)
    viendo.base = RumboBase(cam.coords)
    viendo.rumbo = viendo.base
    viendo.inclinacion = C.Inclinacion.inicial
    viendo.fov = C.Fov.inicial

    --[[ Lo lejano no está cargado: se le dice al juego que cargue alrededor
         del objetivo, y se le da un momento. Es el patrón de la policía y del
         concesionario. ]]
    SetFocusPosAndVel(pos.x, pos.y, pos.z, 0.0, 0.0, 0.0)

    SetCamCoord(viendo.cam, pos.x, pos.y, pos.z)
    SetCamRot(viendo.cam, viendo.inclinacion, 0.0, viendo.rumbo, 2)
    SetCamFov(viendo.cam, viendo.fov)

    SendNUIMessage({
        action = 'camara:ver',
        data = {
            negocio = viendo.negocio,
            label = cam.label,
            indice = n,
            total = #viendo.lista,
        },
    })
end

local function Salir(volverAlPanel)
    if not viendo then return end
    local negocioId = viendo.negocioId

    RenderScriptCams(false, false, 0, true, false)
    if viendo.cam and DoesCamExist(viendo.cam) then DestroyCam(viendo.cam, false) end
    ClearTimecycleModifier()
    ClearFocus()
    viendo = nil

    SendNUIMessage({ action = 'camara:salir' })

    if volverAlPanel then
        PanelNegocio.Abrir(negocioId, 'camaras')
    end

    --[[ El ESC con el que se sale también le llega al radial del HUD. Mientras
         el aviso siga puesto el radial no se abre; se quita un poco después
         para que el mismo toque no lo abra al soltar. ]]
    SetTimeout(400, function()
        if not viendo then LocalPlayer.state:set('mirandoCamara', false, false) end
    end)
end

local function Bucle()
    local ped = PlayerPedId()
    local vida = GetEntityHealth(ped)

    while viendo do
        -- Nada del juego mientras miras: las teclas de aquí se leen desactivadas.
        DisableAllControlActions(0)
        HideHudAndRadarThisFrame()

        local dx = GetDisabledControlNormal(0, 1)
        local dy = GetDisabledControlNormal(0, 2)
        local zoom = viendo.fov / C.Fov.inicial
        if dx ~= 0.0 or dy ~= 0.0 then
            local rumbo = viendo.rumbo - dx * C.Sensibilidad * zoom
            -- El giro tiene tope a cada lado del frente de la cámara.
            local desvio = Limitar(Diferencia(rumbo, viendo.base), -C.Giro, C.Giro)
            viendo.rumbo = (viendo.base + desvio) % 360.0
            viendo.inclinacion = Limitar(viendo.inclinacion - dy * C.Sensibilidad * zoom, C.Inclinacion.min, C.Inclinacion.max)
            SetCamRot(viendo.cam, viendo.inclinacion, 0.0, viendo.rumbo, 2)
        end

        if IsDisabledControlJustPressed(0, 241) then
            viendo.fov = Limitar(viendo.fov - 4.0, C.Fov.min, C.Fov.max)
            SetCamFov(viendo.cam, viendo.fov)
        elseif IsDisabledControlJustPressed(0, 242) then
            viendo.fov = Limitar(viendo.fov + 4.0, C.Fov.min, C.Fov.max)
            SetCamFov(viendo.cam, viendo.fov)
        end

        local total = #viendo.lista
        if total > 1 then
            if IsDisabledControlJustPressed(0, 174) or IsDisabledControlJustPressed(0, 34) then
                Enfocar(((viendo.actual - 2) % total) + 1)
            elseif IsDisabledControlJustPressed(0, 175) or IsDisabledControlJustPressed(0, 35) then
                Enfocar((viendo.actual % total) + 1)
            end
        end

        if IsDisabledControlJustPressed(0, 200) or IsDisabledControlJustPressed(0, 177)
            or IsDisabledControlJustPressed(0, 202) then
            Salir(true)
            break
        end

        -- Herido o muerto: fuera, sin volver al panel.
        if IsEntityDead(ped) or GetEntityHealth(ped) < vida then
            Salir(false)
            Aviso('Has dejado de mirar las cámaras.', 'inform')
            break
        end

        Wait(0)
    end
end

--- Empezar a mirar las cámaras de un negocio, por la de índice `indice`.
local function Ver(negocioId, negocio, lista, indice)
    if viendo then return false, 'Ya estás mirando una cámara.' end
    if #lista == 0 then return false, 'Este negocio no tiene cámaras.' end

    local ped = PlayerPedId()
    if IsEntityDead(ped) then return false, 'Ahora no puedes.' end
    local veh = GetVehiclePedIsIn(ped, false)
    if veh ~= 0 and GetEntitySpeed(veh) > 1.0 then
        return false, 'Para el vehículo antes de mirar las cámaras.'
    end

    local n = 1
    for i, cam in ipairs(lista) do
        if cam.indice == indice then n = i break end
    end

    LocalPlayer.state:set('mirandoCamara', true, false)
    PanelNegocio.Cerrar(true)

    viendo = {
        negocioId = negocioId,
        negocio = negocio,
        lista = lista,
        actual = n,
        cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true),
    }

    SetTimecycleModifier('scanline_cam_cheap')
    SetTimecycleModifierStrength(1.0)
    Enfocar(n)
    RenderScriptCams(true, false, 0, true, false)

    CreateThread(Bucle)
    return true
end

-- ── Lo que pide el panel ──────────────────────────────────────────────────

local function PedirLista(businessId)
    local ok, res = pcall(function()
        return lib.callback.await('origen_businesses:cb:camaras:lista', false, businessId)
    end)
    if not ok or type(res) ~= 'table' then
        return { success = false, message = 'No se pudieron cargar las cámaras.' }
    end
    return res
end

RegisterNUICallback('camaras:lista', function(data, cb)
    local id = data and data.businessId
    if not id then cb({ success = false, message = 'No hay negocio.' }) return end
    cb(PedirLista(id))
end)

--[[ La lista se vuelve a pedir al servidor en vez de fiarse de la que tiene la
     interfaz: así manda el permiso de ahora, no el de cuando se abrió. ]]
RegisterNUICallback('camaras:ver', function(data, cb)
    local id = data and data.businessId
    if not id then cb({ success = false, message = 'No hay negocio.' }) return end

    local res = PedirLista(id)
    if not res.success then cb(res) return end

    local ok, motivo = Ver(id, res.negocio, res.camaras or {}, tonumber(data.indice))
    cb({ success = ok, message = motivo })
end)

AddEventHandler('onResourceStop', function(recurso)
    if recurso ~= GetCurrentResourceName() then return end
    if viendo then Salir(false) end
    LocalPlayer.state:set('mirandoCamara', false, false)
    for clave in pairs(objetos) do Quitar(clave) end
end)
