--[[ ══ El retrato del personaje ═════════════════════════════════════════════

     Saca una foto de la CARA de cada personaje con la misma camara que usa la
     ficha (CAMARAS.cara, de peds.lua: altura 0.04, distancia 0.70, fov 27), la
     recorta la interfaz y se sube a fivemanage por origen_uploader. La
     direccion se guarda en la base de datos y vuelve en el `setup`, asi que a
     partir de ahi el menu enseña la cara en el slot sin sacar nada.

     Tres cosas que explican por que esto se puede hacer sin que se note:

     - La portada del menu tapa la pantalla entera y la captura de screencapture
       coge solo la capa del JUEGO, no la interfaz. Por eso el concesionario
       saca sus fotos con su propio menu abierto y salen limpias.
     - El escenario del menu esta bajo el mapa (Config.HiddenCoords), o sea que
       el fondo es negro para todo el mundo: no hace falta caja verde ni recorte
       por croma como con los coches.
     - La camara se crea aqui a proposito, en vez de usar la que se esta viendo:
       la de la ficha lleva un desplazamiento lateral para librar el panel y
       cambia segun lo que este abierto. Con la nuestra todos los retratos salen
       exactamente con el mismo plano.

     Cuando se saca: al abrir el menu, para los personajes que no tengan foto o
     la tengan vieja (Config.Retrato.refrescoHoras). Uno detras de otro y en
     segundo plano.                                                          ]]

local CAPTURA = 'screenshot-basic'   -- screencapture responde a este nombre
local CAPTURA_REAL = 'screencapture'

--- El retrato que esta esperando a que la interfaz lo recorte y lo suba.
local pendiente = nil
local sacando = false

local function arrancado(recurso)
    local estado = GetResourceState(recurso)
    return estado == 'started' or estado == 'starting'
end

local function hayCaptura()
    return arrancado(CAPTURA) or arrancado(CAPTURA_REAL)
end

--- Se puede sacar un retrato ahora mismo?
function RetratosDisponibles()
    return (Config.Retrato and Config.Retrato.activo and hayCaptura() and arrancado('origen_uploader')) or false
end

local function pedirCaptura()
    local imagen, listo = nil, false

    exports[CAPTURA]:requestScreenshot({
        encoding = Config.Retrato.formato or 'jpg',
        quality = Config.Retrato.calidad or 0.92,
    }, function(datos)
        imagen = datos
        listo = true
    end)

    local tope = GetGameTimer() + 10000
    while not listo and GetGameTimer() < tope do Wait(0) end

    return imagen
end

--[[ La camara del retrato: la misma cuenta que PuntosCamara (peds.lua) pero
     con el encuadre de Config.Retrato.camara (el de mejillas del creador de
     ropa, de tres cuartos) y sin el desplazamiento del panel, que se mueve
     segun lo que haya abierto en la ficha. ]]
local function ponerCamara(ped)
    local c = Config.Retrato.camara or CAMARAS.cara
    local base = GetWorldPositionOfEntityBone(ped, GetPedBoneIndex(ped, HUESO_CABEZA))

    local rad = math.rad(GetEntityHeading(ped) + c.angulo)
    local frente = vector3(-math.sin(rad), math.cos(rad), 0.0)
    local lado = vector3(frente.y, -frente.x, 0.0)

    local mira = vector3(
        base.x + lado.x * c.lateral,
        base.y + lado.y * c.lateral,
        base.z + c.altura)

    local pos = vector3(
        mira.x + frente.x * c.distancia,
        mira.y + frente.y * c.distancia,
        mira.z)

    local cam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', pos, 0.0, 0.0, 0.0, c.fov, false, 0)
    PointCamAtCoord(cam, mira.x, mira.y, mira.z)

    -- El mismo desenfoque de fondo que el retrato de la ficha.
    SetCamUseShallowDofMode(cam, true)
    SetCamNearDof(cam, 0.2)
    SetCamFarDof(cam, 1.0)
    SetCamDofStrength(cam, 1.0)

    return cam
end

--[[ Luz de estudio, pintada a mano.

     El escenario del menu esta bajo el mapa (z -31.8) y ahi abajo no llega ni
     el sol ni una farola: con la pantalla encendida y el ped visible la cara
     seguia saliendo casi negra. Estas tres luces solo existen mientras dura el
     disparo —se pintan por fotograma, como las de un foco— y no tocan nada del
     mundo ni del clima, al contrario que un timecycle.                      ]]
local function encenderLuces(ped, activo, fuerza)
    Citizen.CreateThread(function()
        while activo.si do
            local c = Config.Retrato.camara or CAMARAS.cara
            local base = GetWorldPositionOfEntityBone(ped, GetPedBoneIndex(ped, HUESO_CABEZA))
            local rad = math.rad(GetEntityHeading(ped) + c.angulo)
            local frente = vector3(-math.sin(rad), math.cos(rad), 0.0)
            local lado = vector3(frente.y, -frente.x, 0.0)

            -- Principal: delante, arriba y a un lado, como un retrato de verdad
            DrawLightWithRange(
                base.x + frente.x * 0.85 + lado.x * 0.45,
                base.y + frente.y * 0.85 + lado.y * 0.45,
                base.z + 0.35,
                255, 246, 232, 2.4, 22.0 * (fuerza or 1.0))

            -- Relleno frio por el otro lado: que la sombra no sea un boquete
            DrawLightWithRange(
                base.x + frente.x * 0.70 - lado.x * 0.60,
                base.y + frente.y * 0.70 - lado.y * 0.60,
                base.z + 0.10,
                150, 170, 210, 2.2, 9.0 * (fuerza or 1.0))

            -- Contraluz: separa la cabeza del fondo negro
            DrawLightWithRange(
                base.x - frente.x * 0.80,
                base.y - frente.y * 0.80,
                base.z + 0.55,
                255, 236, 236, 2.0, 10.0 * (fuerza or 1.0))

            Wait(0)
        end
    end)
end

--[[ Una foto. Devuelve la direccion de fivemanage, o nil.

     Tres cosas hay que encender antes de disparar, y devolverlas como estaban
     despues. Nada de esto se ve: la portada tapa la pantalla entera.

     - La PANTALLA. El menu vive con el fundido a negro echado (main.lua hace
       DoScreenFadeOut(0) al entrar), asi que la captura salia negra entera.
     - El PED. Los personajes se crean invisibles (peds.lua) y solo se hacen
       visibles al elegirlos, asi que el que no estuviera elegido tampoco salia.
     - La camara, que se guarda y se devuelve al acabar.                     ]]
local function retratar(ped, citizenid, espera, fuerza)
    if not ped or not DoesEntityExist(ped) then return nil end

    local fundido = IsScreenFadedOut()
    local visible = IsEntityVisible(ped)

    if fundido then DoScreenFadeIn(0) end
    SetEntityVisible(ped, true, false)
    SetEntityAlpha(ped, 255, false)
    ResetEntityAlpha(ped)

    local luces = { si = true }
    encenderLuces(ped, luces, fuerza)

    local antes = GetRenderingCam()
    local cam = ponerCamara(ped)

    SetCamActive(cam, true)
    RenderScriptCams(true, false, 0, true, false)
    SetFocusEntity(ped)

    if Config.Retrato.esconderNui then
        SendNUIMessage({ action = 'retratoEscondeMenu', valor = true })
    end

    Wait(espera or Config.Retrato.esperaMs or 350)

    local imagen = pedirCaptura()

    if Config.Retrato.esconderNui then
        SendNUIMessage({ action = 'retratoEscondeMenu', valor = false })
    end

    luces.si = false

    SetCamActive(cam, false)
    DestroyCam(cam, false)
    ClearFocus()

    if not visible then SetEntityVisible(ped, false, false) end
    if fundido then DoScreenFadeOut(0) end

    if antes and antes ~= -1 and DoesCamExist(antes) then
        SetCamActive(antes, true)
        RenderScriptCams(true, false, 0, true, false)
    else
        RenderScriptCams(false, false, 0, true, false)
    end

    if type(imagen) ~= 'string' or #imagen < 100 then
        print('^3[origen_titlemenu]^0 La captura del retrato de ' .. tostring(citizenid) .. ' vino vacia')
        return nil
    end

    -- A partir de aqui manda la interfaz: recorta el cuadro de la cara, lo deja
    -- en 512x512 y lo devuelve por el callback RetratoListo.
    pendiente = { citizenid = citizenid, hecho = false, url = nil, negro = false }

    SendNUIMessage({
        action = 'procesarRetrato',
        citizenid = citizenid,
        image = imagen,
        salida = Config.Retrato.salida,
    })

    local tope = GetGameTimer() + 60000
    while pendiente and not pendiente.hecho and GetGameTimer() < tope do Wait(10) end

    local url = pendiente and pendiente.url or nil
    local negro = pendiente and pendiente.negro or false
    pendiente = nil

    if negro then
        print('^3[origen_titlemenu]^0 El retrato de ' .. tostring(citizenid) .. ' salio negro')
        return nil, true
    end

    return url
end

--- Con reintentos: la primera foto puede pillar al ped a medio cargar.
local function retratarConIntentos(ped, citizenid)
    local intentos = Config.Retrato.intentos or 3
    local espera = Config.Retrato.esperaMs or 350
    local fuerza = 1.0

    for i = 1, intentos do
        local url, negro = retratar(ped, citizenid, espera, fuerza)
        if url then return url end
        if not negro then return nil end

        -- Negra: o al ped le faltaba un momento por pintarse, o falta foco.
        espera = espera + 400
        fuerza = fuerza * 2.0
        Wait(300)
    end

    return nil
end

--[[ La pasada de todos: los que no tienen foto o la tienen vieja.
     `lista` son los CachedCharacters del menu. ]]
function SacarRetratosPendientes(lista)
    if sacando or not RetratosDisponibles() then return end
    if type(lista) ~= 'table' then return end

    sacando = true

    Citizen.CreateThread(function()
        for i = 1, #lista do
            local personaje = lista[i]

            if personaje and personaje.citizenid and personaje.retratoCaduco then
                -- El ped se carga en segundo plano nada mas abrir el menu.
                local tope = GetGameTimer() + 15000
                while (not personaje.npc or not DoesEntityExist(personaje.npc)) and GetGameTimer() < tope do
                    Wait(100)
                end

                if personaje.npc and DoesEntityExist(personaje.npc) then
                    local url = retratarConIntentos(personaje.npc, personaje.citizenid)
                    if url then
                        personaje.retrato = url
                        personaje.retratoCaduco = false
                        SendNUIMessage({ action = 'retratoListo', citizenid = personaje.citizenid, url = url })
                    end
                end

                -- Sin prisa: el servidor limita el ritmo de subidas.
                Wait(1500)
            end
        end

        sacando = false
    end)
end

--[[ La interfaz ya ha recortado la foto. De la NUI a aqui no hay red, asi que
     el tamaño da igual; el salto al servidor va por el envio latente de
     origen_uploader, que es por donde caben las imagenes. ]]
RegisterNUICallback('RetratoListo', function(data, cb)
    local citizenid = data and data.citizenid
    local base64 = data and type(data.image) == 'string' and data.image:match('^data:image/png;base64,(.+)$')

    if not pendiente or pendiente.citizenid ~= citizenid then
        return cb({ success = false })
    end

    if data and data.negro then
        pendiente.negro = true
        pendiente.hecho = true
        return cb({ success = false })
    end

    if not base64 then
        pendiente.hecho = true
        return cb({ success = false })
    end

    local resguardo, motivo = exports['origen_uploader']:PrepararSubida(('retrato_%s.png'):format(citizenid), base64)
    if not resguardo then
        print('^3[origen_titlemenu]^0 No se pudo enviar el retrato de ' .. tostring(citizenid) .. ': ' .. tostring(motivo))
        pendiente.hecho = true
        return cb({ success = false })
    end

    local resultado = lib.callback.await('origen_titlemenu:sv:retrato:subir', false, {
        citizenid = citizenid,
        ticket = resguardo,
    })

    local ok = type(resultado) == 'table' and resultado.success or false
    if not ok then
        print('^3[origen_titlemenu]^0 El servidor no guardo el retrato de ' .. tostring(citizenid)
            .. ': ' .. tostring(type(resultado) == 'table' and resultado.error or resultado))
    end

    pendiente.url = ok and resultado.url or nil
    pendiente.hecho = true

    cb({ success = ok, url = pendiente.url })
end)

--- Para probar en el juego: /retrato saca el del personaje que tengas elegido.
RegisterCommand('retrato', function()
    if not RetratosDisponibles() then
        print('^1[origen_titlemenu]^0 Retratos apagados o sin screencapture/origen_uploader')
        return
    end

    local ped = PedRetratado()
    if not ped or not DoesEntityExist(ped) then
        print('^1[origen_titlemenu]^0 No hay ningun personaje elegido')
        return
    end

    Citizen.CreateThread(function()
        for i = 1, #(CachedCharacters or {}) do
            if CachedCharacters[i].npc == ped then
                local url = retratarConIntentos(ped, CachedCharacters[i].citizenid)
                print('^2[origen_titlemenu]^0 Retrato: ' .. tostring(url))
                if url then
                    CachedCharacters[i].retrato = url
                    SendNUIMessage({ action = 'retratoListo', citizenid = CachedCharacters[i].citizenid, url = url })
                end
                return
            end
        end
        print('^1[origen_titlemenu]^0 Ese ped no es de ningun personaje de la lista')
    end)
end, false)

--[[ Disparar la tanda desde fuera, sin tener que reconectar: el servidor manda
     este evento con el comando de consola `retrato_ahora`. ]]
RegisterNetEvent('origen_titlemenu:client:RetratosAhora', function()
    local lista = CachedCharacters or {}

    for i = 1, #lista do
        lista[i].retratoCaduco = true
    end

    sacando = false
    SacarRetratosPendientes(lista)
end)
