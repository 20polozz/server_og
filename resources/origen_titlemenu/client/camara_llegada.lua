--[[ ORIGEN TITLEMENU — La camara de llegada

     Entrar en la ciudad era esto: negro, y de pronto ya estabas de pie en la
     acera. Aqui se devuelve lo que hace el propio juego al entrar en Online:
     la camara arranca muy alta sobre el sitio donde apareces, baja despacio
     mientras el mundo termina de cargar, se coloca detras de ti y suelta el
     control.

     No es solo decoracion. La bajada tapa exactamente el rato en el que
     origen_clothing todavia no ha aplicado tu aspecto. Ese rato ya existia: lo
     unico que se veia era el cambiazo de Michael a ti, y por eso se habia
     acabado dejando la pantalla en negro. Con la camara arriba, ese mismo rato
     es un plano del barrio.

     Se usa desde client/main.lua, en el spawn de tipo "lastplace":

         CamaraLlegadaEmpezar(coords, heading)   nada mas colocarte
         CamaraLlegadaTerminar()                 cuando el aspecto ya es el tuyo

     Las dos aguantan que las llamen de mas o en mal orden: si la camara no
     esta puesta, no hacen nada.
]]

local cam = nil
local vigilante = nil
local arranque = 0

--- Los ajustes, con valores de fabrica si el config no los trae.
local function Ajustes()
    local c = Config.CamaraLlegada or {}
    return {
        activa      = c.activa ~= false,
        altura      = tonumber(c.altura) or 260.0,
        retirada    = tonumber(c.retirada) or 9.0,
        alturaFinal = tonumber(c.alturaFinal) or 3.2,
        bajada      = math.floor(tonumber(c.bajada) or 5000),
        minimo      = math.floor(tonumber(c.minimo) or 3500),
        aterrizaje  = math.floor(tonumber(c.aterrizaje) or 2600),
        entrega     = math.floor(tonumber(c.entrega) or 1300),
        tope        = math.floor(tonumber(c.tope) or 20000),
    }
end

--[[ El punto que queda DETRAS del jugador.

     En GTA el rumbo 0 mira al norte, y el vector hacia donde miras es
     (-sin, cos). Detras es el mismo del reves. Se usa dos veces: muy lejos
     para el tramo de en medio, y a un par de zancadas para el plano final. ]]
local function PuntoDetras(coords, heading, distancia)
    local rad = math.rad(heading or 0.0)
    return coords.x + (math.sin(rad) * distancia),
           coords.y - (math.cos(rad) * distancia)
end

--[[ La inclinacion que hace falta para mirar al jugador desde donde esta la
     camara. Se calcula en vez de escribirse a mano para que el encuadre siga
     siendo bueno aunque en el config se cambien la altura o la retirada. ]]
local function PitchHacia(alturaSobreEl, distancia)
    if distancia <= 0.01 then return -89.0 end
    return -math.deg(math.atan(alturaSobreEl / distancia))
end

local function SoltarAlJugador()
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, false)
    SetEntityInvincible(ped, false)
    DisplayRadar(true)
end

--- ¿Hay una llegada en curso? Para que nadie mas toque la camara mientras.
function CamaraLlegadaActiva()
    return cam ~= nil
end

--- Arranca el plano alto y empieza la bajada larga.
---
--- Vuelve enseguida: la bajada corre sola mientras el spawn sigue haciendo lo
--- suyo (cargar la ficha, pedir el aspecto, quitar el telon). Devuelve true si
--- la camara se ha llegado a poner.
---
--- @param coords table|vector3 donde aparece el jugador
--- @param heading number|nil hacia donde mira
function CamaraLlegadaEmpezar(coords, heading)
    local a = Ajustes()

    if not a.activa then return false end
    if Config.SkySpawnCinematicDisable then return false end
    if cam then return false end
    if not coords or not coords.x then return false end

    local ped = PlayerPedId()
    heading = tonumber(heading) or GetEntityHeading(ped)

    --[[ Quieto y a salvo mientras dura el plano. Sin el freeze el jugador cae,
         se mueve o se muere debajo de una camara que esta a 260 metros. ]]
    FreezeEntityPosition(ped, true)
    SetEntityVisible(ped, true, false)
    SetEntityInvincible(ped, true)
    DisplayRadar(false)

    -- Arriba del todo, mirando casi a plomo sobre el punto de aparicion.
    arranque = GetGameTimer()
    cam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA',
        coords.x, coords.y, coords.z + a.altura,
        -87.0, 0.0, heading + 0.0,
        45.0, true, 2)
    SetCamActive(cam, true)
    RenderScriptCams(true, false, 0, true, false)

    --[[ El tramo largo: baja a media altura y se va inclinando. Es el que se ve
         mientras cargan el mundo y el aspecto, asi que va lento a proposito.

         No arranca aqui mismo: entre que se coloca la camara y se abre el telon
         pasa un rato en negro —la dimension, la ficha, el aspecto— y si la
         bajada corriese durante ese rato, el jugador abriria los ojos con el
         plano ya medio hecho. Se espera a que la pantalla este abierta de
         verdad, con tope por si el telon no llegara a levantarse. ]]
    local mdist = a.retirada * 4.0
    local mx, my = PuntoDetras(coords, heading, mdist)
    local msobre = a.altura * 0.28
    local mz, mrot = coords.z + msobre, heading + 0.0
    local mpitch = PitchHacia(msobre - 1.0, mdist)   -- apuntando a el, no a sus pies

    CreateThread(function()
        local espera = 0
        while not IsScreenFadedIn() and espera < 8000 do
            Wait(50)
            espera = espera + 50
            if not cam then return end
        end
        if not cam then return end

        SetCamParams(cam, mx, my, mz, mpitch, 0.0, mrot, 45.0, a.bajada, 0, 0, 2)
    end)

    --[[ Red de seguridad. Si por lo que sea nadie llama a Terminar —un fallo
         en mitad del spawn, un recurso caido— el jugador no se puede quedar
         mirando su propio tejado sin poder moverse. ]]
    vigilante = GetGameTimer() + a.tope
    CreateThread(function()
        while cam and GetGameTimer() < vigilante do
            Wait(250)
        end
        if cam then
            print('^3[origen_titlemenu] La camara de llegada se ha cerrado sola: nadie llamo a CamaraLlegadaTerminar.^0')
            CamaraLlegadaTerminar()
        end
    end)

    return true
end

--- Aterriza detras del jugador y devuelve el control.
---
--- Bloquea lo que dura el aterrizaje mas la entrega (por defecto unos cuatro
--- segundos). Si no habia camara puesta, vuelve en el acto.
function CamaraLlegadaTerminar()
    if not cam then
        -- Aun asi hay que asegurarse de no dejar al jugador congelado.
        SoltarAlJugador()
        return false
    end

    local a = Ajustes()

    --[[ Un suelo de tiempo en el aire. Si el aspecto llega enseguida, sin esto
         el plano duraria un parpadeo y quedaria como un tiron, no como una
         llegada. Se espera a completar el minimo antes de aterrizar. ]]
    while (GetGameTimer() - arranque) < a.minimo do
        Wait(50)
        if not cam then return false end
    end

    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    -- El plano final: a un par de zancadas por detras, a la altura de la cabeza.
    local fx, fy = PuntoDetras(pos, heading, a.retirada)
    SetCamParams(cam,
        fx, fy, pos.z + a.alturaFinal,
        PitchHacia(a.alturaFinal - 1.0, a.retirada), 0.0, heading + 0.0,
        50.0, a.aterrizaje, 0, 0, 2)
    Wait(a.aterrizaje)

    --[[ Dejar la camara del juego ya mirando hacia donde mira el jugador, para
         que la entrega no de un tiron lateral. ]]
    SetGameplayCamRelativeHeading(0.0)
    SetGameplayCamRelativePitch(0.0, 1.0)

    RenderScriptCams(false, true, a.entrega, true, false)
    Wait(a.entrega)

    DestroyCam(cam, false)
    cam = nil
    vigilante = nil

    SoltarAlJugador()
    return true
end

--[[ Si se reinicia el recurso en mitad de una llegada, el jugador se quedaria
     congelado y sin camara propia. ]]
AddEventHandler('onResourceStop', function(recurso)
    if recurso ~= GetCurrentResourceName() then return end
    if cam then
        RenderScriptCams(false, false, 0, true, false)
        DestroyCam(cam, false)
        cam = nil
    end
    SoltarAlJugador()
end)
