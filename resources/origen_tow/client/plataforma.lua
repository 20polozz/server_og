-- Los coches aparcados del mapa y los del tráfico solo existen en este
-- cliente: pedirles el id de red da 0 y llena la consola de avisos «no net
-- object for entity». Se contesta 0 sin preguntar (vale para todo el recurso).
local IdDeRed = NetworkGetNetworkIdFromEntity
function NetworkGetNetworkIdFromEntity(ent)
    if not ent or ent == 0 or not DoesEntityExist(ent) or not NetworkGetEntityIsNetworked(ent) then return 0 end
    return IdDeRed(ent)
end

--[[ ── La plataforma ──────────────────────────────────────────────────────────

     Hay dos maneras de subir un coche a una plataforma, y el camion manda:

     · CAJA MOVIL (el flatbed de addon). La caja de verdad es un extra del
       modelo: se oculta y en su sitio se pone un prop identico que SI se
       puede mover. Entonces la maniobra es la de la calle entera: la caja
       se desliza hacia atras, se inclina hasta tocar el suelo, el
       cabrestante sube el coche por ella, y la caja vuelve a subir y a
       meterse. Es lo que hacen los sistemas que se ven por ahi.

     · PERFIL (el flatbed y el slamtruck de serie). Esos camiones no tienen
       ninguna pieza que se mueva —medido en el juego, hueso por hueso—, asi
       que lo que se hace es dibujar el perfil del camion y hacer trepar al
       coche por el, apoyandolo por sus dos ruedas. En el slamtruck queda
       bien porque lleva rampa hasta el suelo; en el flatbed de serie la
       caja acaba en seco y se nota.

     En las dos, la subida la pinta CADA cliente en su maquina a partir del
     mismo aviso del servidor, y el coche va SIEMPRE pegado al camion: la
     caja movil es un adorno local que solo dice por donde pasa. ]]

Plataforma = {}

local ocupadas = {}   -- [gruaNet] = true mientras sube o baja
local cajas = {}      -- [gruaNet] = { prop = objeto LOCAL, pose = {pos, rot}, tumbada }
local vistoEnObra = {} -- [gruaNet] = true si se le ha visto el freno de maniobra echado
local dobles = {}      -- [coche] = doble local que se mueve en su lugar mientras dura la maniobra

function Plataforma.Ocupada(gruaNet)
    return ocupadas[gruaNet] == true
end

--- La caja movil de una grua, si ese camion la lleva.
function Plataforma.Caja(gruaNet)
    local c = cajas[gruaNet]
    if c and DoesEntityExist(c.prop) then return c.prop end
    return nil
end

-- ── El cable ──────────────────────────────────────────────────────────────

--- El punto de donde tira el cable: de la caja movil si la hay, y si no del
--- propio camion.
local function PuntoDelCable(grua, gruaNet, ficha)
    local caja = Plataforma.Caja(gruaNet)
    if caja and ficha.caja.cable then
        local c = ficha.caja.cable
        return GetOffsetFromEntityInWorldCoords(caja, c.x, c.y, c.z)
    end
    local c = ficha.cable
    return GetOffsetFromEntityInWorldCoords(grua, c.x, c.y, c.z)
end

--- El morro del coche, donde muerde el cable.
local function Morro(coche)
    local minimo, maximo = GetModelDimensions(GetEntityModel(coche))
    return GetOffsetFromEntityInWorldCoords(coche, 0.0, maximo.y - 0.25, minimo.z + 0.45)
end

local function NuevaCuerda(grua, gruaNet, coche, ficha)
    RopeLoadTextures()
    local espera = 0
    while not RopeAreTexturesLoaded() and espera < 200 do
        Wait(5)
        espera = espera + 1
    end

    local visto = dobles[coche] or coche
    local a = PuntoDelCable(grua, gruaNet, ficha)
    local b = Morro(visto)
    local largo = math.max(#(a - b), 0.5)

    local cuerda = AddRope(a.x, a.y, a.z, 0.0, 0.0, 0.0, largo, 4, largo, 0.5, 1.0, false, false, false, 1.0, true)
    AttachEntitiesToRope(cuerda, grua, visto, a.x, a.y, a.z, b.x, b.y, b.z, largo, false, false, nil, nil)
    return cuerda
end

local function TensarCuerda(cuerda, grua, gruaNet, coche, ficha)
    if not cuerda then return end
    local a = PuntoDelCable(grua, gruaNet, ficha)
    local b = Morro(dobles[coche] or coche)
    RopeForceLength(cuerda, math.max(#(a - b), 0.5))
end

--- La animacion del muñeco: solo la hace el que tira de la palanca.
local function Palanca(duracion)
    local ped = PlayerPedId()
    if lib.requestAnimDict('mini@repair', 2000) then
        TaskPlayAnim(ped, 'mini@repair', 'fixing_a_player', 4.0, -4.0, duracion, 1, 0.0, false, false, false)
    end
end

-- ── La caja movil ─────────────────────────────────────────────────────────

--[[ POR QUE LA CAJA ES LOCAL Y EL COCHE VA PEGADO AL CAMION

     Antes la caja era una entidad de red y el coche iba pegado a ella. Eso
     tenia dos agujeros que no se tapan con parches, porque dependen de
     quien lleve la fisica de cada cosa en cada momento:

       · Una entidad de red tiene dueño, y el dueño cambia cuando maneja
         otro jugador. Bastaba con que una sola maquina viera la caja solida
         un instante para que el camion saliera por los aires.
       · El juego solo deja de hacer chocar a dos entidades que estan
         pegadas ENTRE SI. Con el coche pegado a la caja, coche y camion
         seguian chocando.

     Ahora la caja es un adorno que se hace cada cliente: no va por la red,
     no tiene dueño, nace sin colision y lejos del camion. No puede empujar
     nada. Y el coche va pegado DIRECTAMENTE al camion, en el sitio que sale
     de componer la pose de la caja con el hueco del coche: es un enganche
     de red de verdad, que el motor sincroniza solo y entre cuyas dos piezas
     no hay choque posible. ]]

local function Hueso(grua, ficha)
    local i = GetEntityBoneIndexByName(grua, ficha.caja.hueso or 'chassis')
    if not i or i < 0 then return 0 end
    return i
end

--[[ Poner una cosa en su sitio A MANO, a partir de la matriz del camion: donde
     mira, donde tiene la derecha y el techo, y donde esta. `morro` la
     inclina (morro arriba) y `giro` la tuerce sobre su propio techo.

     Por que no pegarla con AttachEntityToEntity: el juego recoloca lo pegado
     cuando procesa la fisica del padre, y eso solo va fino en la maquina que
     LLEVA esa fisica. En las demas el camion es una copia de red y lo pegado
     se actualiza a saltos —se veia a fotogramas cuando manejaba otro, y en
     marcha la caja iba desfasada del camion—. Puesta a mano cada fotograma
     va igual de fina en todas las pantallas. ]]
local function PonerEnMundo(ent, grua, pos, morro, giro)
    local adelante, derecha, arriba, sitio = GetEntityMatrix(grua)

    local g = math.rad(morro or 0.0)
    local ad = adelante * math.cos(g) + arriba * math.sin(g)
    local ar = arriba * math.cos(g) - adelante * math.sin(g)
    local de = derecha

    if giro and giro ~= 0.0 then
        local y = math.rad(giro)
        ad, de = ad * math.cos(y) - de * math.sin(y), de * math.cos(y) + ad * math.sin(y)
    end

    local en = sitio + derecha * pos.x + adelante * pos.y + arriba * pos.z
    SetEntityMatrix(ent, ad.x, ad.y, ad.z, de.x, de.y, de.z, ar.x, ar.y, ar.z, en.x, en.y, en.z)
end

local function PegarCaja(grua, prop, ficha, pos, rot)
    PonerEnMundo(prop, grua, pos, rot.x, 0.0)
end

--- Un punto dicho en medidas de la caja, pasado a medidas del camion.
local function DeCajaACamion(pose, p)
    local g = math.rad(pose.rot.x)
    return vec3(pose.pos.x + p.x,
                pose.pos.y + p.y * math.cos(g) - p.z * math.sin(g),
                pose.pos.z + p.y * math.sin(g) + p.z * math.cos(g))
end

--- Y al reves: un punto del camion, en medidas de la caja.
local function DeCamionACaja(pose, p)
    local g = math.rad(pose.rot.x)
    local dy, dz = p.y - pose.pos.y, p.z - pose.pos.z
    return vec3(p.x - pose.pos.x,
                dy * math.cos(g) + dz * math.sin(g),
                -dy * math.sin(g) + dz * math.cos(g))
end

--- Pega el coche AL CAMION, en el sitio de la caja que se le diga.
local function PegarCocheEn(grua, ficha, coche, pose, enCaja, giro)
    local sitio = DeCajaACamion(pose, enCaja)

    local doble = dobles[coche]
    if doble then
        if DoesEntityExist(doble) then PonerEnMundo(doble, grua, sitio, pose.rot.x, giro or 0.0) end
        return
    end

    AttachEntityToEntity(coche, grua, Hueso(grua, ficha),
        sitio.x, sitio.y, sitio.z,
        pose.rot.x, 0.0, giro or 0.0,
        false, false, false, false, 2, true)
end
Plataforma.PegarCocheEn = PegarCocheEn

--- El coche ya cargado: caja metida y coche en su hueco.
function Plataforma.PegarCocheFinal(grua, coche, ficha)
    PegarCocheEn(grua, ficha, coche, ficha.caja.puesta, ficha.caja.coche, 0.0)
end

--[[ La caja no baja a una altura fija: se POSA en el suelo que haya. Se
     calcula donde caeria el filo trasero con la pose del mod, se mira el
     suelo justo ahi, y se sube o baja la caja entera lo que haga falta. ]]
local function BajadaEnElSuelo(grua, prop, ficha)
    local b = ficha.caja.bajada
    local minimo = GetModelDimensions(GetEntityModel(prop))

    local filo = DeCajaACamion(b, vec3(0.0, minimo.y + 0.15, minimo.z + 0.05))
    local mundo = GetOffsetFromEntityInWorldCoords(grua, filo.x, filo.y, filo.z)
    local ok, suelo = GetGroundZFor_3dCoord(mundo.x, mundo.y, mundo.z + 4.0, false)
    if not ok then
        -- Sin suelo que mirar ahi: vale el que pisa el propio camion.
        local pg = GetEntityCoords(grua)
        local ok2, sg = GetGroundZFor_3dCoord(pg.x, pg.y, pg.z + 2.0, false)
        if not ok2 then return b end
        suelo = sg
    end

    local ajuste = (suelo + 0.03) - mundo.z
    if ajuste < -1.2 then ajuste = -1.2 end
    if ajuste > 1.2 then ajuste = 1.2 end

    return { pos = vec3(b.pos.x, b.pos.y, b.pos.z + ajuste), rot = b.rot }
end

--[[ Hace la caja de ESTE cliente para ese camion. El orden importa: nace
     treinta metros por debajo, se le quita la colision ahi abajo, y solo
     entonces se acerca al camion. En ningun momento hay nada solido cerca. ]]
local function AsegurarCaja(grua, gruaNet, ficha)
    if not ficha.caja then return nil end

    local ya = cajas[gruaNet]
    if ya and DoesEntityExist(ya.prop) then return ya.prop end

    local modelo = joaat(ficha.caja.prop)
    if not IsModelValid(modelo) then return nil end
    if not HasModelLoaded(modelo) then
        RequestModel(modelo)   -- sin esperar: el vigilante vuelve a pasar
        return nil
    end

    local pos = GetEntityCoords(grua)
    local prop = CreateObjectNoOffset(modelo, pos.x, pos.y, pos.z - 30.0, false, false, false)
    if not prop or prop == 0 then return nil end

    SetEntityCollision(prop, false, false)
    FreezeEntityPosition(prop, true)

    local tumbada = Entity(grua).state.origen_tow_tumbada == true
    local pose = tumbada and BajadaEnElSuelo(grua, prop, ficha) or ficha.caja.puesta

    PegarCaja(grua, prop, ficha, pose.pos, pose.rot)

    cajas[gruaNet] = { prop = prop, grua = grua, ficha = ficha, pose = pose, tumbada = tumbada or nil }
    return prop
end

--- Mueve la caja de una pose a otra; si lleva coche encima, va con ella.
local function MoverCaja(grua, gruaNet, ficha, desde, hasta, ms, coche, enCaja)
    local prop = Plataforma.Caja(gruaNet)
    if not prop then return end

    local arranque = GetGameTimer()
    while true do
        Wait(0)
        if not DoesEntityExist(grua) or not DoesEntityExist(prop) then return end

        local t = math.min((GetGameTimer() - arranque) / ms, 1.0)
        local s = Tow.Suave(t)
        local pose = {
            pos = Tow.EntreVec(desde.pos, hasta.pos, s),
            rot = Tow.EntreVec(desde.rot, hasta.rot, s),
        }

        PegarCaja(grua, prop, ficha, pose.pos, pose.rot)
        if coche and DoesEntityExist(coche) then
            PegarCocheEn(grua, ficha, coche, pose, enCaja, 0.0)
        end

        if t >= 1.0 then break end
    end

    if cajas[gruaNet] then cajas[gruaNet].pose = hasta end
end

--- ¿Esta tumbada la caja de esta grua?
function Plataforma.Tumbada(gruaNet)
    local c = cajas[gruaNet]
    return c ~= nil and c.tumbada == true
end

--[[ Bajar o subir la caja a mano, sin cargar nada: para meter un coche por
     su pie, o para dejarla lista antes de enganchar. Lo pinta cada cliente
     con las mismas cuentas, igual que la maniobra entera. ]]
function Plataforma.Palanca(gruaNet, abajo)
    local grua = Estado.Ent(gruaNet)
    if not grua then return end

    local ficha = Tow.Ficha(GetEntityModel(grua))
    if not ficha or not ficha.caja then return end

    local prop = AsegurarCaja(grua, gruaNet, ficha)
    if not prop or ocupadas[gruaNet] then return end

    local c = ficha.caja
    ocupadas[gruaNet] = true

    CreateThread(function()
        FreezeEntityPosition(grua, true)
        local bajada = BajadaEnElSuelo(grua, prop, ficha)

        if abajo then
            MoverCaja(grua, gruaNet, ficha, c.puesta, c.atras, Config.Caja.sacar)
            MoverCaja(grua, gruaNet, ficha, c.atras, bajada, Config.Caja.bajar)
        else
            MoverCaja(grua, gruaNet, ficha, bajada, c.atras, Config.Caja.bajar)
            MoverCaja(grua, gruaNet, ficha, c.atras, c.puesta, Config.Caja.sacar)
        end

        if cajas[gruaNet] then cajas[gruaNet].tumbada = abajo or nil end
        if DoesEntityExist(grua) then FreezeEntityPosition(grua, false) end
        ocupadas[gruaNet] = nil
    end)
end

RegisterNetEvent('origen_tow:cliente:plataforma', function(gruaNet, abajo)
    Plataforma.Palanca(gruaNet, abajo)
end)

--[[ ── El vigilante de las cajas ────────────────────────────────────────────

     Cada camion de caja movil que haya delante lleva la suya: se le hace si
     no la tiene, se le repone si se ha soltado, y se le esconde la caja de
     pega del modelo (el juego enciende los extras al azar al crear el
     coche). Quien llega tarde —o se perdio el aviso— la encuentra en la
     pose que diga el servidor, sin animacion. ]]
CreateThread(function()
    while true do
        Wait(400)
        local aqui = GetEntityCoords(PlayerPedId())

        for _, veh in ipairs(GetGamePool('CVehicle')) do
            local ficha = Tow.Ficha(GetEntityModel(veh))
            if ficha and ficha.caja then
                local net = NetworkGetNetworkIdFromEntity(veh)

                --[[ Un camion lejos no necesita caja, y ademas es donde falla:
                     visto en los partes del servidor, la caja constaba como
                     pegada y estaba a 200 y 300 metros de su camion —se queda
                     clavada donde estaba cuando el camion se aleja del
                     jugador—. Eso son plataformas flotando por la calle. Asi
                     que lejos se borra, y cerca se comprueba que de verdad
                     este donde el camion y no solo que «conste» pegada. ]]
                local lejos = #(GetEntityCoords(veh) - aqui) > 110.0
                if net and net ~= 0 and lejos and cajas[net] and not ocupadas[net] then
                    if DoesEntityExist(cajas[net].prop) then DeleteEntity(cajas[net].prop) end
                    cajas[net] = nil
                end

                if net and net ~= 0 and not lejos and not ocupadas[net] then
                    local prop = AsegurarCaja(veh, net, ficha)
                    local c = cajas[net]

                    if prop and c and #(GetEntityCoords(prop) - GetEntityCoords(veh)) > 25.0 then
                        DeleteEntity(prop)
                        cajas[net] = nil
                        prop, c = nil, nil
                    end

                    if prop and c then
                        -- La pose que manda es la del servidor.
                        -- Con un poco de paciencia: el aviso de la maniobra
                        -- llega casi a la vez que el estado, y si se coloca de
                        -- golpe antes de que llegue, la animacion pega un salto.
                        local tumbada = Entity(veh).state.origen_tow_tumbada == true
                        if tumbada ~= (c.tumbada == true) then
                            c.difiere = (c.difiere or 0) + 1
                        else
                            c.difiere = nil
                        end

                        if c.difiere and c.difiere >= 3 then
                            c.difiere = nil
                            c.tumbada = tumbada or nil
                            c.pose = tumbada and BajadaEnElSuelo(veh, prop, ficha) or ficha.caja.puesta
                        end
                        c.grua, c.ficha = veh, ficha

                        SetEntityCollision(prop, false, false)
                    end

                    --[[ El freno de una maniobra que ya acabo. Pasa si el que
                         llevaba la fisica del camion se fue a mitad, o si a
                         este cliente le toco heredarlo sin haber pintado la
                         maniobra. Solo se toca un camion que hayamos visto en
                         obra: los que congele otro recurso no son nuestros. ]]
                    local enObra = Entity(veh).state.origen_tow_obra == true
                    if enObra then
                        vistoEnObra[net] = true
                    elseif vistoEnObra[net] then
                        if IsEntityPositionFrozen(veh) and NetworkHasControlOfEntity(veh) then
                            FreezeEntityPosition(veh, false)
                        end
                        if not IsEntityPositionFrozen(veh) then vistoEnObra[net] = nil end
                    end

                    if ficha.caja.extra and IsVehicleExtraTurnedOn(veh, ficha.caja.extra) then
                        SetVehicleExtra(veh, ficha.caja.extra, 1)
                    end
                end
            end
        end

        -- La caja de un camion que ya no esta se borra: es nuestra.
        for net, c in pairs(cajas) do
            if not Estado.Ent(net) then
                if DoesEntityExist(c.prop) then DeleteEntity(c.prop) end
                cajas[net] = nil
            end
        end
    end
end)

--[[ Cada fotograma, cada caja a su sitio. Mientras hay maniobra la coloca
     la propia maniobra (que ademas la mueve); el resto del tiempo, este
     hilo. Sin cajas cerca duerme. ]]
CreateThread(function()
    while true do
        local hay = false
        for net, c in pairs(cajas) do
            hay = true
            if not ocupadas[net] and c.grua and DoesEntityExist(c.grua) and DoesEntityExist(c.prop) then
                PegarCaja(c.grua, c.prop, c.ficha, c.pose.pos, c.pose.rot)
            end
        end
        Wait(hay and 0 or 500)
    end
end)

-- ── El doble ──────────────────────────────────────────────────────────────

--[[ Para quien MIRA. El coche de otro jugador es, en esta pantalla, una copia
     de red: moverlo aqui pelea con las posiciones que llegan de su dueño, y
     dejarlo a la red es verlo a saltos. Asi que mientras dura la maniobra se
     esconde —solo en esta pantalla— y en su lugar se mueve un doble local,
     igual por fuera, que va fotograma a fotograma. Al acabar se borra el
     doble y el de verdad reaparece, que para entonces ya esta en su sitio. ]]
local function HacerDoble(coche)
    local modelo = GetEntityModel(coche)
    if not HasModelLoaded(modelo) then return nil end   -- lo tiene delante: esta cargado

    local p = GetEntityCoords(coche)
    local doble = CreateVehicle(modelo, p.x, p.y, p.z - 30.0, GetEntityHeading(coche), false, false)
    if not doble or doble == 0 then return nil end

    SetEntityCollision(doble, false, false)
    FreezeEntityPosition(doble, true)
    SetEntityInvincible(doble, true)
    SetVehicleDoorsLocked(doble, 2)

    -- Por fuera, igual: piezas, colores, matricula, vinilo, suciedad.
    SetVehicleModKit(doble, 0)
    for tipo = 0, 49 do
        local m = GetVehicleMod(coche, tipo)
        if m and m >= 0 then SetVehicleMod(doble, tipo, m, GetVehicleModVariation(coche, tipo)) end
    end
    local c1, c2 = GetVehicleColours(coche)
    SetVehicleColours(doble, c1, c2)
    local n1, n2 = GetVehicleExtraColours(coche)
    SetVehicleExtraColours(doble, n1, n2)
    if GetIsVehiclePrimaryColourCustom(coche) then
        local r, g, b = GetVehicleCustomPrimaryColour(coche)
        SetVehicleCustomPrimaryColour(doble, r, g, b)
    end
    if GetIsVehicleSecondaryColourCustom(coche) then
        local r, g, b = GetVehicleCustomSecondaryColour(coche)
        SetVehicleCustomSecondaryColour(doble, r, g, b)
    end
    SetVehicleWheelType(doble, GetVehicleWheelType(coche))
    SetVehicleWindowTint(doble, GetVehicleWindowTint(coche))
    SetVehicleLivery(doble, GetVehicleLivery(coche))
    SetVehicleNumberPlateText(doble, GetVehicleNumberPlateText(coche))
    SetVehicleNumberPlateTextIndex(doble, GetVehicleNumberPlateTextIndex(coche))
    SetVehicleDirtLevel(doble, GetVehicleDirtLevel(coche))
    for extra = 0, 14 do
        if DoesExtraExist(coche, extra) then
            SetVehicleExtra(doble, extra, IsVehicleExtraTurnedOn(coche, extra) and 0 or 1)
        end
    end

    -- A su sitio de salida, encima del de verdad.
    local ad, de, ar, en = GetEntityMatrix(coche)
    SetEntityMatrix(doble, ad.x, ad.y, ad.z, de.x, de.y, de.z, ar.x, ar.y, ar.z, en.x, en.y, en.z)
    return doble
end

-- ── El perfil (camiones de serie) ─────────────────────────────────────────

--[[ A que altura esta la superficie del camion a lo largo `y`. Todo va
     referido al centro del camion, y el suelo se mide en vivo porque cada
     camion se asienta distinto. ]]
local function Superficie(ficha, y, sueloRel)
    local pie = ficha.rampaDesde or (ficha.cajaDesde - 1.2)

    if y <= pie then return sueloRel end
    if y >= (ficha.rampaHasta or ficha.cajaDesde) then return ficha.alto end

    local hasta = ficha.rampaHasta or ficha.cajaDesde
    return Tow.Entre(sueloRel, ficha.alto, (y - pie) / math.max(hasta - pie, 0.01))
end

--- Lo que va de rueda a rueda, a ojo del modelo.
local function Batalla(coche)
    local minimo, maximo = GetModelDimensions(GetEntityModel(coche))
    return math.max((maximo.y - minimo.y) * 0.72, 1.2)
end

--[[ Cuanto levanta un vehiculo su centro sobre el suelo que pisa. Solo vale
     medirlo con el coche EN EL SUELO, asi que se apunta al engancharlo y se
     reusa despues, cuando ya esta subido y medir daria cualquier cosa. ]]
local alzadas = {}

local function Alzada(ent, recordar)
    local net = NetworkGetNetworkIdFromEntity(ent)
    if not recordar then return (net and alzadas[net]) or 0.35 end

    local p = GetEntityCoords(ent)
    local ok, gz = GetGroundZFor_3dCoord(p.x, p.y, p.z + 2.0, false)
    local alto = ok and (p.z - gz) or 0.35
    if alto < 0.0 or alto > 2.0 then alto = 0.35 end

    if recordar and net and net ~= 0 then alzadas[net] = alto end
    return alto
end

--[[ Donde acaba un coche puesto en un camion de perfil, con su inclinacion
     en `w`. Lo usa el vigilante para reponer el enganche sin animar. ]]
function Plataforma.SitioFinal(grua, coche, ficha)
    if not ficha.alto then return nil end

    local largo = Batalla(coche)
    local suelo = -Alzada(grua, true)
    local yMorro = ficha.tope
    local zMorro = Superficie(ficha, yMorro, suelo)
    local zCulo = Superficie(ficha, yMorro - largo, suelo)

    return vec4(0.0, yMorro - largo * 0.5, (zMorro + zCulo) * 0.5 + Alzada(coche, false),
                math.deg(math.atan(zMorro - zCulo, largo)))
end

-- ── Las maniobras ─────────────────────────────────────────────────────────

--- Donde esta el coche AHORA, en medidas del camion.
local function PoseActual(grua, coche)
    local off = GetOffsetFromEntityGivenWorldCoords(grua, GetEntityCoords(coche))
    return off, Tow.Corto(GetEntityHeading(coche) - GetEntityHeading(grua))
end

--- Arrastrar el coche por el suelo o por el perfil, pegado al camion.
local function Arrastrar(grua, gruaNet, coche, ficha, desdePos, desdeGiro, hastaPos, ms, perfil, porElSuelo)
    local cuerda = NuevaCuerda(grua, gruaNet, coche, ficha)
    local arranque = GetGameTimer()
    local largo = perfil and Batalla(coche) or nil
    local alzada = perfil and Alzada(coche, false) or nil

    SetEntityCollision(coche, false, true)

    while true do
        Wait(0)
        if not DoesEntityExist(grua) or not DoesEntityExist(coche) then break end

        local t = math.min((GetGameTimer() - arranque) / ms, 1.0)
        local s = Tow.Suave(t)

        if not dobles[coche] and Estado.SoyElCuidador(grua) then Estado.Fijar(coche) end

        local sitio, morro
        if perfil then
            -- Apoyado por las dos ruedas en el perfil del camion.
            local yMorro = Tow.Entre(desdePos.y, hastaPos.y, s) + largo * 0.5
            local zMorro = Superficie(ficha, yMorro, perfil.suelo)
            local zCulo = Superficie(ficha, yMorro - largo, perfil.suelo)
            sitio = vec3(Tow.Entre(desdePos.x, hastaPos.x, s), yMorro - largo * 0.5, (zMorro + zCulo) * 0.5 + alzada)
            morro = math.deg(math.atan(zMorro - zCulo, largo))
        else
            sitio = Tow.EntreVec(desdePos, hastaPos, s)
            morro = 0.0

            -- Por el suelo: la altura sale del suelo que hay debajo, no de
            -- suponer que detras del camion el terreno sigue igual.
            if porElSuelo then
                local m = GetOffsetFromEntityInWorldCoords(grua, sitio.x, sitio.y, 0.0)
                local ok, gz = GetGroundZFor_3dCoord(m.x, m.y, m.z + 5.0, false)
                if ok then
                    local real = GetOffsetFromEntityGivenWorldCoords(grua, m.x, m.y, gz + porElSuelo)
                    sitio = vec3(sitio.x, sitio.y, Tow.Entre(desdePos.z, real.z, math.min(s * 3.0, 1.0)))
                end
            end
        end

        local giroAhora = Tow.Entre(desdeGiro, 0.0, math.min(s * 2.0, 1.0))
        local doble = dobles[coche]
        if doble then
            if DoesEntityExist(doble) then PonerEnMundo(doble, grua, sitio, morro, giroAhora) end
        else
            AttachEntityToEntity(coche, grua, 0,
                sitio.x, sitio.y, sitio.z,
                morro, 0.0, giroAhora,
                false, false, false, false, 2, true)
        end

        TensarCuerda(cuerda, grua, gruaNet, coche, ficha)

        if t >= 1.0 then break end
    end

    if cuerda then DeleteRope(cuerda) end
    -- La colision no se enciende aqui: solo al soltarlo (SoltarLimpio).
end

--- Tirar del coche A LO LARGO DE LA CAJA, que esta quieta en `pose`.
local function TirarPorCaja(grua, gruaNet, coche, ficha, pose, desde, giro, hasta, ms)
    local cuerda = NuevaCuerda(grua, gruaNet, coche, ficha)
    local arranque = GetGameTimer()

    SetEntityCollision(coche, false, true)

    while true do
        Wait(0)
        if not DoesEntityExist(grua) or not DoesEntityExist(coche) then break end

        local t = math.min((GetGameTimer() - arranque) / ms, 1.0)
        local s = Tow.Suave(t)

        if not dobles[coche] and Estado.SoyElCuidador(grua) then Estado.Fijar(coche) end

        PegarCocheEn(grua, ficha, coche, pose, Tow.EntreVec(desde, hasta, s),
            Tow.Entre(giro, 0.0, math.min(s * 2.0, 1.0)))

        TensarCuerda(cuerda, grua, gruaNet, coche, ficha)

        if t >= 1.0 then break end
    end

    if cuerda then DeleteRope(cuerda) end
end

--- ¿Esta el coche metido en el hueco del camion (o pegado a el)?
local function EncimaDelCamion(coche, grua)
    if not grua or not DoesEntityExist(grua) then return false end
    local rel = GetOffsetFromEntityGivenWorldCoords(grua, GetEntityCoords(coche))
    local minG, maxG = GetModelDimensions(GetEntityModel(grua))
    local minC, maxC = GetModelDimensions(GetEntityModel(coche))
    local medio = (maxC.y - minC.y) * 0.5
    return math.abs(rel.x) < 2.4 and rel.y > (minG.y - medio - 0.6) and rel.y < (maxG.y + medio + 0.6)
end

--[[ Soltar un coche SIN que nada salga disparado.

     · La FISICA la toca una sola maquina: la dueña de red del coche. Antes
       lo soltaban y le encendian la colision TODOS los clientes, cada uno
       cuando acababa su propia animacion; con mas gente delante, alguno lo
       hacia con el coche todavia encima del camion en SU pantalla, y si esa
       maquina llevaba la fisica del camion, lo mandaba a volar.
     · Se suelta en seco (sin heredar la velocidad del cable), se saca del
       camion si aun esta encima, y se posa en el SUELO DE VERDAD —mirado
       con el juego, no calculado—: en una cuesta quedaba enterrado, y
       encender la colision enterrado es otro escopetazo.
     · La colision es lo ultimo, y solo con el coche libre del camion. ]]
local function SoltarLimpio(coche, grua)
    if not DoesEntityExist(coche) then return end

    DetachEntity(coche, false, false)

    if NetworkHasControlOfEntity(coche) then
        local rumbo = GetEntityHeading(coche)
        SetEntityVelocity(coche, 0.0, 0.0, 0.0)

        local pos = GetEntityCoords(coche)
        if EncimaDelCamion(coche, grua) then
            local minG = GetModelDimensions(GetEntityModel(grua))
            local minC, maxC = GetModelDimensions(GetEntityModel(coche))
            pos = GetOffsetFromEntityInWorldCoords(grua, 0.0, minG.y - (maxC.y - minC.y) * 0.5 - 2.0, 0.0)
            rumbo = GetEntityHeading(grua)
        end

        local ok, suelo = GetGroundZFor_3dCoord(pos.x, pos.y, pos.z + 5.0, false)
        SetEntityCoordsNoOffset(coche, pos.x, pos.y, (ok and suelo or pos.z) + 0.7, false, false, false)
        SetEntityRotation(coche, 0.0, 0.0, rumbo, 2, true)
        SetEntityVelocity(coche, 0.0, 0.0, 0.0)
        SetVehicleOnGroundProperly(coche)

        local net = NetworkGetNetworkIdFromEntity(coche)
        if net and net ~= 0 then SetNetworkIdCanMigrate(net, true) end
        SetEntityAsMissionEntity(coche, false, false)
    end

    -- La colision, al final y con el coche libre. Cada maquina la enciende
    -- en la suya cuando en la SUYA el coche ya no toca el camion.
    CreateThread(function()
        local limite = GetGameTimer() + 15000
        Wait(400)
        while DoesEntityExist(coche) and GetGameTimer() < limite do
            if not EncimaDelCamion(coche, grua) then
                SetEntityCollision(coche, true, true)
                return
            end
            Wait(250)
        end
    end)
end
Plataforma.SoltarLimpio = SoltarLimpio

local function Rematar(grua, coche, ficha, alReves)
    if not DoesEntityExist(coche) then return end

    if alReves then
        SoltarLimpio(coche, grua)
    elseif DoesEntityExist(grua) then
        Estado.Enganchar(grua, coche, ficha)
    end
end

--[[ La maniobra con caja movil, tal cual en la calle:
     la caja sale, se inclina, el cable sube el coche, y la caja vuelve.
     El coche va SIEMPRE pegado al camion; la caja solo dice por donde. ]]
local function ConCaja(grua, gruaNet, coche, ficha, alReves)
    local c = ficha.caja
    local prop = AsegurarCaja(grua, gruaNet, ficha)
    if not prop then return false end

    local reparto = Config.Caja
    local bajada = BajadaEnElSuelo(grua, prop, ficha)

    -- Si el operario ya la habia bajado a mano, no se baja dos veces.
    local yaAbajo = cajas[gruaNet] and cajas[gruaNet].tumbada == true

    if not alReves then
        -- Con el coche aun en el suelo: cuanto levanta su centro. Hace falta
        -- luego para dejarlo bien posado al bajarlo.
        Alzada(coche, true)

        if not yaAbajo then
            MoverCaja(grua, gruaNet, ficha, c.puesta, c.atras, reparto.sacar)
            MoverCaja(grua, gruaNet, ficha, c.atras, bajada, reparto.bajar)
        end

        -- Arranca desde donde esta de verdad, para que no pegue un salto.
        local enCamion, giro = PoseActual(grua, coche)
        local desde = DeCamionACaja(bajada, enCamion)
        TirarPorCaja(grua, gruaNet, coche, ficha, bajada,
            vec3(desde.x, desde.y, c.coche.z), giro, c.coche, reparto.tirar)

        MoverCaja(grua, gruaNet, ficha, bajada, c.atras, reparto.bajar, coche, c.coche)
        MoverCaja(grua, gruaNet, ficha, c.atras, c.puesta, reparto.sacar, coche, c.coche)
        if cajas[gruaNet] then cajas[gruaNet].tumbada = nil end
        return true
    end

    if not yaAbajo then
        MoverCaja(grua, gruaNet, ficha, c.puesta, c.atras, reparto.sacar, coche, c.coche)
        MoverCaja(grua, gruaNet, ficha, c.atras, bajada, reparto.bajar, coche, c.coche)
    end

    --[[ La bajada va en dos tramos: mientras el coche pisa la caja sigue su
         inclinacion, pero en cuanto pasa el filo ya no hay caja debajo. Si
         siguiera por la linea de la rampa acabaria bajo tierra. ]]

    -- Tramo 1: por la caja, hasta que el culo llega al filo de atras.
    local bordeCaja = GetModelDimensions(GetEntityModel(prop))
    local minimoCoche, maximoCoche = GetModelDimensions(GetEntityModel(coche))
    local medioCoche = (maximoCoche.y - minimoCoche.y) * 0.5

    local alFilo = vec3(c.coche.x, bordeCaja.y + medioCoche, c.coche.z)
    TirarPorCaja(grua, gruaNet, coche, ficha, bajada, c.coche, 0.0, alFilo,
        math.floor(reparto.tirar * 0.65))

    -- Tramo 2: ya en el suelo, sin inclinacion, hasta quedar detras.
    local ahora = DeCajaACamion(bajada, alFilo)
    Arrastrar(grua, gruaNet, coche, ficha,
        ahora, 0.0, vec3(ahora.x, ahora.y - 3.5, ahora.z),
        math.floor(reparto.tirar * 0.35), nil, Alzada(coche, false))

    Rematar(grua, coche, ficha, true)

    MoverCaja(grua, gruaNet, ficha, bajada, c.atras, reparto.bajar)
    MoverCaja(grua, gruaNet, ficha, c.atras, c.puesta, reparto.sacar)
    if cajas[gruaNet] then cajas[gruaNet].tumbada = nil end
    return true
end

--- La maniobra en camion de serie: encarar y trepar por el perfil.
local function ConPerfil(grua, gruaNet, coche, ficha, alReves)
    -- Sin perfil medido no hay nada que hacer: es un camion de caja movil
    -- al que le faltan los modelos.
    if not ficha.alto then return false end

    local desde, giro = PoseActual(grua, coche)
    -- Se mide con el coche todavia en el suelo, antes de moverlo.
    if not alReves then Alzada(coche, true) end
    local perfil = { suelo = -Alzada(grua, true) }

    local recoge = vec3(0.0, ficha.recoge, 0.0)
    local puesto = vec3(0.0, ficha.tope - Batalla(coche) * 0.5, 0.0)

    if not alReves then
        -- Primero encarar: el cable lo deja recto detras, en el suelo.
        Arrastrar(grua, gruaNet, coche, ficha, desde, giro,
            vec3(recoge.x, recoge.y, desde.z), math.floor(Config.Cabrestante * 0.3), nil)
        Arrastrar(grua, gruaNet, coche, ficha, recoge, 0.0, puesto,
            math.floor(Config.Cabrestante * 0.7), perfil)
    else
        Arrastrar(grua, gruaNet, coche, ficha, puesto, 0.0, recoge, Config.Cabrestante, perfil)
    end

    Rematar(grua, coche, ficha, alReves)
    return true
end

local function Maniobra(gruaNet, cocheNet, alReves, soyYo)
    local grua, coche = Estado.Ent(gruaNet), Estado.Ent(cocheNet)
    if not grua or not coche then return end

    local ficha = Tow.Ficha(GetEntityModel(grua))
    if not ficha or ficha.tipo ~= 'plataforma' then return end
    if ocupadas[gruaNet] then return end

    ocupadas[gruaNet] = true

    CreateThread(function()
        --[[ Freno echado: mientras dura la maniobra el camion esta congelado.
             Lo pide cada cliente y vale en el que lleve su fisica; a un
             camion congelado no lo mueve nada. El pcall es para que un fallo
             a mitad no lo deje clavado para siempre. ]]
        FreezeEntityPosition(grua, true)

        -- El que maneja mueve el coche de verdad. Los que miran, si el
        -- coche no es suyo, mueven un doble y esconden el de verdad.
        local doble = nil
        if not soyYo and not NetworkHasControlOfEntity(coche) then
            doble = HacerDoble(coche)
            if doble then
                dobles[coche] = doble
                CreateThread(function()
                    while dobles[coche] == doble and DoesEntityExist(coche) do
                        SetEntityLocallyInvisible(coche)
                        Wait(0)
                    end
                end)
            end
        end

        local bien, fallo = pcall(function()

        if soyYo then Palanca(Config.Cabrestante) end

        local hecho
        if ficha.caja then
            hecho = ConCaja(grua, gruaNet, coche, ficha, alReves)
        end
        if not hecho then
            hecho = ConPerfil(grua, gruaNet, coche, ficha, alReves)
        end

        -- Ni caja ni perfil: al cliente le faltan los modelos del camion.
        if not hecho and soyYo then
            lib.notify({
                description = 'A tu juego le faltan los modelos de la grua. Reconectate al servidor.',
                type = 'error',
            })
        end

        end)

        if not bien then print('[origen_tow] maniobra rota: ' .. tostring(fallo)) end

        -- Fuera el doble. Un instante de margen para que el de verdad, que
        -- viene por la red, ya este donde toca cuando reaparezca.
        if doble then
            Wait(350)
            dobles[coche] = nil
            if DoesEntityExist(doble) then DeleteEntity(doble) end
        end

        Wait(600)
        if DoesEntityExist(grua) then FreezeEntityPosition(grua, false) end
        ocupadas[gruaNet] = nil

        if soyYo then
            ClearPedTasks(PlayerPedId())
            if bien and not alReves then TriggerServerEvent('origen_tow:pedir:cargado', gruaNet) end
        end
    end)
end

--- Sube un coche. La llaman TODOS los clientes que tengan los dos vehiculos
--- delante; `soyYo` solo lo es el que tira de la palanca.
function Plataforma.Subir(gruaNet, cocheNet, soyYo)
    Maniobra(gruaNet, cocheNet, false, soyYo)
end

--- Y lo baja.
function Plataforma.Bajar(gruaNet, cocheNet, soyYo)
    Maniobra(gruaNet, cocheNet, true, soyYo)
end

--- Para la herramienta de ajuste: deja la caja en la pose que se le diga.
function Plataforma.FijarPose(gruaNet, pose)
    if cajas[gruaNet] then cajas[gruaNet].pose = pose end
end

--- Borra las cajas de este cliente; el vigilante las vuelve a hacer.
function Plataforma.Olvidar()
    for _, c in pairs(cajas) do
        if DoesEntityExist(c.prop) then DeleteEntity(c.prop) end
    end
    cajas = {}

    for coche, doble in pairs(dobles) do
        if DoesEntityExist(doble) then DeleteEntity(doble) end
        dobles[coche] = nil
    end
end

AddEventHandler('onResourceStop', function(recurso)
    if recurso ~= GetCurrentResourceName() then return end
    Plataforma.Olvidar()
end)
