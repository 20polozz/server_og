Camara = Camara or {}

local cam = nil

--- Arranque y final suaves, sin tirones en los extremos.
local function Suave(t)
    if t < 0.0 then t = 0.0 elseif t > 1.0 then t = 1.0 end
    return t * t * (3.0 - 2.0 * t)
end

--[[ Interpolacion en proporcion, no en linea recta. El ojo percibe las alturas
     como razones: bajar de 150 m a 2 m linealmente parece desplomarse al
     principio y arrastrarse al final. Asi, a mitad de camino la camara esta a
     unos 46 m y la caida se lee constante. ]]
local function Geom(a, b, t)
    return a * ((b / a) ^ t)
end

--- La diferencia mas corta entre dos rumbos, en [-180, 180].
local function DifAngulo(a, b)
    return (b - a + 180.0) % 360.0 - 180.0
end

--- Pitch y yaw para que una camara en `desde` mire a `hacia`.
local function RotHacia(desde, hacia)
    local dx, dy, dz = hacia.x - desde.x, hacia.y - desde.y, hacia.z - desde.z
    local plano = math.sqrt(dx * dx + dy * dy)
    if plano < 0.01 then plano = 0.01 end
    return math.deg(math.atan(dz, plano)), math.deg(math.atan(-dx, dy))
end

--[[ Donde va la camara para un progreso dado. `camH` es el rumbo suavizado que
     persigue al del coche, y `anclaZ` la altura del coche ya filtrada. ]]
local function Pose(pos, camH, anclaZ, pe)
    local C = Config.Camara

    local altura   = Geom(C.alturaInicial, C.alturaFinal, pe)
    local retirada = Geom(C.retiradaInicial, C.retiradaFinal, pe)
    local fov      = C.fovInicial + (C.fovFinal - C.fovInicial) * pe

    -- En GTA el rumbo 0 mira al norte y el vector hacia delante es (-sin, cos);
    -- detras es el mismo del reves.
    local rad = math.rad(camH)
    local cx  = pos.x + math.sin(rad) * retirada
    local cy  = pos.y - math.cos(rad) * retirada
    local cz  = anclaZ + altura

    local pitch, yaw = RotHacia(
        vector3(cx, cy, cz),
        vector3(pos.x, pos.y, anclaZ + C.alturaMira))

    return cx, cy, cz, pitch, yaw, fov
end

--- Deja la camara del juego ya centrada detras del coche, para que la entrega
--- final no de un tiron lateral.
local function CentrarCamaraJuego()
    SetGameplayCamRelativeHeading(0.0)
    SetGameplayCamRelativePitch(0.0, 1.0)
end

--- Coloca el plano alto inicial. Devuelve el handle de la camara.
function Camara.Preparar(veh)
    if cam then Camara.Cortar() end

    local pos  = GetEntityCoords(veh)
    local camH = GetEntityHeading(veh)
    local cx, cy, cz, pitch, yaw, fov = Pose(pos, camH, pos.z, 0.0)

    cam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA',
        cx, cy, cz, pitch, 0.0, yaw, fov, false, 2)
    SetCamActive(cam, true)
    Nativa('SetCamAffectsAiming', cam, false)
    RenderScriptCams(true, false, 0, true, false)

    -- Si el jugador venia en primera persona, la entrega fundiria a una camara
    -- de morro. Se le pasa a tercera persona media.
    if Nativa('GetFollowVehicleCamViewMode') == 4 then
        Nativa('SetFollowVehicleCamViewMode', 1)
    end

    return cam
end

--[[ El plano largo. La camara no se mueve por tiempo sino por PROGRESO del
     trayecto, para que acabe abajo justo cuando el coche llega, dure lo que
     dure el viaje.

     El progreso nunca retrocede: `resta` es distancia en linea recta y el coche
     va por calles, asi que en un desvio que se aleja del destino la camara
     SUBIRIA. Y nunca se queda a medias: si el coche se atasca, el suelo por
     tiempo termina el plano igual.

     Se escribe la pose frame a frame en vez de usar SetCamParams con duracion:
     con duracion el motor interpola por dentro y se pelea con nuestra escritura,
     que es de donde sale el micro-tartamudeo clasico. ]]
function Camara.Volar(handle)
    local C = Config.Camara
    local veh = Intro.Coche()
    if veh == 0 then return end

    local meta    = Intro.ruta.destino
    local spawn   = Intro.ruta.spawn
    local entrega = Config.Conduccion.radioEntrega

    --[[ El recorrido util acaba en el radio de entrega, no en el destino: es
         ahi donde el jugador coge el volante y donde la camara tiene que estar
         ya abajo. Si se midiera contra el destino, el plano se quedaria a un
         3 % de terminar justo cuando hace falta que este terminado. ]]
    local total = #(vector2(meta.x, meta.y) - vector2(spawn.x, spawn.y)) - entrega
    if total < 1.0 then total = 1.0 end

    local ritmo  = Ritmo.De(Intro.ruta)
    local p      = 0.0
    local camH   = GetEntityHeading(veh)
    local anclaZ = GetEntityCoords(veh).z
    local t0     = GetGameTimer()
    local ultimo = t0

    while Intro.activo do
        local ahora = GetGameTimer()
        local dt    = math.min((ahora - ultimo) / 1000.0, 0.1)
        ultimo = ahora

        veh = Intro.Coche()
        if veh == 0 then break end

        local pos   = GetEntityCoords(veh)
        local resta = #(vector2(meta.x, meta.y) - vector2(pos.x, pos.y))

        local pDist   = 1.0 - math.min(math.max(resta - entrega, 0.0) / total, 1.0)
        local pTiempo = (ahora - t0) / ritmo.camara
        p = math.min(math.max(p, pDist, pTiempo), 1.0)
        Intro.progreso = p

        local pe = Suave(p)

        --[[ El rumbo de la camara no es el del coche al instante: seguirlo sin
             filtrar da un latigazo en cada curva. La constante aprieta segun
             baja -- suelta arriba, pegada detras abajo -- para que el ultimo
             tramo ya cuadre con la camara del juego. ]]
        local k = C.kMin + (C.kMax - C.kMin) * pe
        camH = camH + DifAngulo(camH, GetEntityHeading(veh)) * (1.0 - math.exp(-k * dt))

        -- XY crudo: el jugador conduce, asi que el coche es suyo y no hay
        -- interpolacion de red. La Z si se filtra: la suspension oscila y a
        -- seis metros con FOV 50 eso se ve.
        anclaZ = anclaZ + (pos.z - anclaZ) * (1.0 - math.exp(-6.0 * dt))

        local cx, cy, cz, pitch, yaw, fov = Pose(pos, camH, anclaZ, pe)
        SetCamCoord(handle, cx, cy, cz)
        SetCamRot(handle, pitch, 0.0, yaw, 2)
        SetCamFov(handle, fov)

        CentrarCamaraJuego()

        local falta = resta - entrega
        if falta <= Config.Aviso.anticipacion then
            Aviso.Mostrar()
            Aviso.Progreso(1.0 - math.max(falta, 0.0) / Config.Aviso.anticipacion)
        end

        if resta <= entrega then break end

        Wait(0)
    end
end

--- Respaldo por si la camara del juego devolviera algo absurdo: el mismo plano
--- de persecucion calculado a mano.
local function PoseManual(veh)
    local pos  = GetEntityCoords(veh)
    local camH = GetEntityHeading(veh)
    local cx, cy, cz, pitch, yaw, fov = Pose(pos, camH, pos.z, 1.0)
    return vector3(cx, cy, cz), vector3(pitch, 0.0, yaw), fov
end

--[[ La pose viva de la camara del juego, con respaldo por si devolviera algo
     absurdo mientras hay una camara de script renderizando.

     Se lee en vez de calcularse porque la gameplay cam se sigue simulando por
     detras aunque no se este mostrando: es el unico sitio donde esta la
     respuesta exacta a "donde va a quedar la vista del jugador". ]]
local function PoseJuego(veh)
    local g  = GetGameplayCamCoord()
    local gr = GetGameplayCamRot(2)
    local gf = GetGameplayCamFov()

    if veh ~= 0 and #(g - GetEntityCoords(veh)) > 40.0 then
        return PoseManual(veh)
    end

    return g, gr, gf
end

--[[ El relevo de la imagen. Cuando esto corre, el jugador YA lleva el volante y
     el coche sigue rodando: solo queda devolverle la vista.

     Todo pasa en UN bucle que sigue vivo durante el fundido, y esa es la clave.
     Antes el bucle terminaba y solo despues se soltaba RenderScriptCams: la
     camara de script se quedaba clavada en el mundo mientras el coche seguia a
     velocidad de crucero, y el fundido tenia que tragarse esa separacion -- a
     16 m/s son once metros en los 700 ms de entrega. Ese era el salto. Con el
     coche parado no se notaba; en marcha, si.

     Ahora la camara persigue la del juego frame a frame hasta pisarla, y para
     cuando el fundido corre las dos estan en el mismo sitio, con la misma
     rotacion y el mismo FOV: no queda nada que fundir. ]]
function Camara.Aterrizar(handle)
    if not handle or not DoesCamExist(handle) then return end

    local C  = Config.Camara
    local c0 = GetCamCoord(handle)
    local r0 = GetCamRot(handle, 2)
    local f0 = GetCamFov(handle)
    local t0 = GetGameTimer()
    local fin = t0 + C.aterrizaje + C.entrega

    local soltada = false

    while GetGameTimer() < fin do
        local t  = GetGameTimer() - t0
        local te = Suave(math.min(t / C.aterrizaje, 1.0))

        --[[ Solo mientras se converge. En cuanto la imagen es suya, mandan sus
             manos: seguir centrandole la camara seria pelearse con el. ]]
        if not soltada then CentrarCamaraJuego() end

        local g, gr, gf = PoseJuego(Intro.Coche())

        SetCamCoord(handle,
            c0.x + (g.x - c0.x) * te,
            c0.y + (g.y - c0.y) * te,
            c0.z + (g.z - c0.z) * te)
        SetCamRot(handle,
            r0.x + DifAngulo(r0.x, gr.x) * te, 0.0,
            r0.z + DifAngulo(r0.z, gr.z) * te, 2)
        SetCamFov(handle, f0 + (gf - f0) * te)

        if not soltada and t >= C.aterrizaje then
            soltada = true
            RenderScriptCams(false, true, C.entrega, true, false)
        end

        Wait(0)
    end

    if DoesCamExist(handle) then DestroyCam(handle, false) end
    if handle == cam then cam = nil end
    DisplayRadar(true)
end

--- Corte seco. Para los abortos y el reinicio del resource.
function Camara.Cortar()
    RenderScriptCams(false, false, 0, true, false)
    if cam and DoesCamExist(cam) then DestroyCam(cam, false) end
    cam = nil
end
