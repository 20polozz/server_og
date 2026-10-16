--[[ Origen Lista Negra, lado cliente.

     · La lista: al usar el objeto Lista Negra se abre la pantalla con los
       trabajos (por dificultad); se elige uno y se acepta.
     · El trabajo en curso: el servidor dice cual y en que paso; aqui se pone lo
       que hace falta para ese paso (enemigos, objetivo con su escolta, convoy,
       coche, paquete, la ruta del GPS) y se le avisa cuando parece hecho. Si de
       verdad lo esta, lo decide el servidor.
     · El seguimiento va en el rastreador de origen_quests, como una mision mas.
     · El panel de admin (/misionesadmin, o la pestaña Scripts de origen_admin):
       dar o retirar la Lista Negra, quitar el trabajo, reiniciar la cuenta. ]]

local TITULO = 'Lista Negra'

local panel = false
local desdeElHub = false

local estado = nil         -- { mision, paso, quedan } o nil
local limite = 0           -- GetGameTimer() en que se acaba el tiempo
local pasoPuesto = nil     -- 'mision:paso' de lo ultimo que se monto
local ents = { peds = {}, veh = nil, prop = nil, mano = nil }
local apuntado = false     -- el servidor ya conoce los enemigos/el coche de este paso
local eleccion = nil       -- conversacion abierta: la promesa que espera respuesta (la usa `cerrar`)
local cuerpo = nil         -- donde cayo el ultimo objetivo (recoger lo que llevaba, la foto)
local charlando = false    -- hay una conversacion en pantalla
local pistaPendiente = nil -- (ya no se usa: ver colaPapeles)
local colaPapeles = {}     -- los papeles que esperan: se enseñan uno detras de otro
local leyendo = false      -- hay un papel abierto (con el raton): nada se le pone encima
local Voz, Labios          -- (las usa la tortura, que va antes; se definen con la conversacion)
local pidiendo = false
local fallado = false
local textoPuesto = nil
local deseo = nil          -- el rotulo que pide esta vuelta del bucle
local atacando = {}        -- [ped] = true: ya se le ha mandado a por el jugador
local muertoDesde = nil    -- GetGameTimer() desde que el jugador esta muerto

local PorId = {}
for _, m in ipairs(Config.Misiones) do PorId[m.id] = m end

local function Aviso(texto, tipo)
    exports.origen_notify:Notify({ title = TITULO, description = texto, type = tipo or 'info', duration = 5000 })
end

RegisterNetEvent('origen_mision:cl:aviso', Aviso)

--- El rotulo de tecla de abajo. Uno solo a la vez, y sin repetir la llamada
--- cada fotograma.
local function Texto(clave, texto)
    if textoPuesto == (clave and (clave .. texto) or nil) then return end
    textoPuesto = clave and (clave .. texto) or nil
    if clave then exports.origen_notify:DrawText(clave, texto) else exports.origen_notify:HideText() end
end

local function Cargar(modelo)
    local hash = type(modelo) == 'number' and modelo or joaat(modelo)
    if not IsModelInCdimage(hash) then return nil end
    if not pcall(lib.requestModel, hash, 8000) then return nil end
    return hash
end

--[[ El suelo de verdad debajo de un punto de la config.

     La z de la config es aproximada a proposito. Se busca primero un poco por
     encima de ella (lo normal: el punto es bueno y hay techo o arboles mas
     arriba que no interesan) y, si no hay nada, desde muy arriba. ]]
local function Suelo(x, y, z)
    RequestCollisionAtCoord(x, y, z)
    for _, desde in ipairs({ z + 3.0, z + 50.0, 1000.0 }) do
        local hay, suelo = GetGroundZFor_3dCoord(x + 0.0, y + 0.0, desde, false)
        if hay then return suelo end
    end
    return z + 0.0
end

--[[ Donde poner a una persona cerca de (x, y): el «sitio seguro para
     peatones» del juego (acera, suelo de verdad, fuera de paredes y tejados).
     Sin esto, un escolta podia salir encima de un contenedor del puerto o
     dentro de una caseta. ]]
local function SitioPeaton(x, y, z)
    local zz = Suelo(x, y, z)
    local ok, sitio = GetSafeCoordForPed(x + 0.0, y + 0.0, zz + 1.0, true, 16)
    if ok and #(vector3(sitio.x, sitio.y, 0.0) - vector3(x, y, 0.0)) < 12.0 then
        return sitio.x, sitio.y, sitio.z
    end
    return x + 0.0, y + 0.0, zz
end

local function HudFuera(fuera)
    TriggerEvent('qv2:suppressHud', fuera)
    pcall(function() exports.origen_hud:toggleHud(not fuera) end)
    if GetResourceState('origen_map') == 'started' then
        pcall(function() exports.origen_map:Apartar(fuera) end)
    end
end

-- ---------------------------------------------------------------------------
--  La pantalla
-- ---------------------------------------------------------------------------

local function AbrirPanel(modo, tarde)
    if panel then return end
    local datos
    if modo == 'admin' then
        datos = lib.callback.await('origen_mision:admin:datos', false)
    else
        datos = lib.callback.await('origen_mision:lista', false)
        if not datos then
            Aviso('No tienes la Lista Negra.', 'error')
            return
        end
    end
    if not datos then
        if desdeElHub and GetResourceState('origen_admin') == 'started' then exports['origen_admin']:ReturnToScripts() end
        desdeElHub = false
        return
    end
    panel = true
    Texto(nil)
    HudFuera(true)
    SendNUIMessage({ a = 'abrir', modo = modo, datos = datos })
    if tarde then
        -- Desde el panel de admin: si se coge el raton antes de que se aparte,
        -- su pantalla de carga se queda con el.
        CreateThread(function()
            Wait(2800)
            if panel then SetNuiFocus(true, true) end
        end)
    else
        SetNuiFocus(true, true)
    end
end

local function CerrarPanel()
    if not panel then return end
    panel = false
    SetNuiFocus(false, false)             -- primero, siempre
    HudFuera(false)
    SetTimeout(280, function()
        if not panel then SendNUIMessage({ a = 'cerrar' }) end
    end)
    if desdeElHub then
        desdeElHub = false
        if GetResourceState('origen_admin') == 'started' then exports['origen_admin']:ReturnToScripts() end
    end
end

OrigenFoco.AlSoltar(function()
    if panel then
        panel = false
        HudFuera(false)
        SendNUIMessage({ a = 'cerrar' })
    end
    -- Una charla a medias: se da por cortada (si no, se quedaba esperando).
    if eleccion then local pr = eleccion; eleccion = nil; pr:resolve(nil) end
end)

RegisterNUICallback('cerrar', function(_, cb)
    if eleccion then
        -- Una conversacion: la cierra Conversar.
        local pr = eleccion; eleccion = nil; pr:resolve(nil)
        cb(true)
        return
    end
    CerrarPanel()
    cb(true)
end)

RegisterNUICallback('aceptar', function(d, cb)
    cb(lib.callback.await('origen_mision:aceptar', false, d and d.id) or { ok = false })
end)

RegisterNUICallback('abandonar', function(_, cb)
    cb(lib.callback.await('origen_mision:abandonar', false) or { ok = false })
end)

-- En grupo: a quien se puede invitar (cerca, con Lista Negra) e invitarle.
RegisterNUICallback('invitables', function(_, cb)
    cb(lib.callback.await('origen_mision:invitables', false) or { ok = false })
end)

RegisterNUICallback('invitar', function(d, cb)
    cb(lib.callback.await('origen_mision:invitar', false, d and d.id) or { ok = false })
end)

--[[ Te invitan a un trabajo: una ventana para aceptar o no. Lo que se conteste
     lo vuelve a mirar el servidor (que sigas cerca, que no lleves otro...). ]]
RegisterNetEvent('origen_mision:cl:invitacion', function(d)
    if type(d) ~= 'table' then return end
    PlaySoundFrontend(-1, 'Text_Arrive_Tone', 'Phone_SoundSet_Default', true)
    local r = lib.alertDialog({
        header = 'Lista Negra',
        content = ('**%s** te invita a «%s». Si entras, el trabajo es de los dos: pistas, tiros y paga.'):format(d.de or '?', d.titulo or '?'),
        centered = true, cancel = true,
        labels = { confirm = 'Entrar', cancel = 'No' },
    })
    TriggerServerEvent('origen_mision:responder', r == 'confirm')
end)

RegisterNUICallback('admin', function(d, cb)
    cb(lib.callback.await('origen_mision:admin:hacer', false, d) or { ok = false })
end)

RegisterNUICallback('adminDatos', function(_, cb)
    cb(lib.callback.await('origen_mision:admin:datos', false))
end)

-- ---------------------------------------------------------------------------
--  El encargo en curso: montar y desmontar cada paso
-- ---------------------------------------------------------------------------

local rutaPendiente = nil   -- { x, y, z, nombre } mientras la ruta no tenga su carretera

local function QuitarPuntos()
    OrigenMapa.Quitar('objetivo')
    OrigenMapa.Quitar('objetivo_ruta')
    rutaPendiente = nil
    for i in ipairs(ents.peds) do OrigenMapa.Quitar('enemigo_' .. i) end
    OrigenMapa.Quitar('coche')
end

local function SoltarMano()
    if ents.mano and DoesEntityExist(ents.mano) then DeleteEntity(ents.mano) end
    ents.mano = nil
end

local QuitarObjetivo

local QuitarTestigo
local QuitarCocheParado
local QuitarRastros
local QuitarDecorados
local BorrarAtados   -- (los presos que se quedan en su silla; se define con ellos)
local CerrarMiraYa   -- (el borrado general la llama; se define con la mira)
--- El coche aparcado de un paso «investigar» con `coche`. Declarado aqui
--- arriba porque Investigar, que va antes que su bloque, lo usa: declarado
--- mas abajo, Investigar veia una global vacia y nunca abria el maletero.
local cocheParado = nil

local function BorrarTodo()
    if QuitarObjetivo then QuitarObjetivo(true) end
    if QuitarTestigo then QuitarTestigo() end
    if BorrarAtados then BorrarAtados() end
    if QuitarCocheParado then QuitarCocheParado() end
    if QuitarDecorados then QuitarDecorados(nil) end
    if CerrarMiraYa then CerrarMiraYa(true) end
    if QuitarRastros then QuitarRastros() end
    QuitarPuntos()
    for _, p in ipairs(ents.peds) do
        if DoesEntityExist(p) and NetworkHasControlOfEntity(p) then DeleteEntity(p) end
    end
    if ents.veh and DoesEntityExist(ents.veh) and NetworkHasControlOfEntity(ents.veh) then DeleteEntity(ents.veh) end
    if ents.prop and DoesEntityExist(ents.prop) then DeleteEntity(ents.prop) end
    SoltarMano()
    ents = { peds = {}, veh = nil, prop = nil, mano = nil }
end

--[[ El paso que toca. En un trabajo para dos, el paso `doble` tiene una
     parte por papel (estado.papel: 'habla', 'sombra' o 'apoyo'): aqui sale la
     MIA. Con la mia hecha, un paso de espera hasta que el otro acabe. ]]
local ESPERAS = {}
local function Paso()
    if not estado then return nil, nil end
    local m = PorId[estado.mision]
    local p = m and m.pasos[estado.paso]
    if p and p.tipo == 'doble' then
        local papel = estado.papel or 'habla'
        local hechas = estado.partes or {}
        local clave = papel
        if papel == 'apoyo' then clave = (p.partes.sombra and not hechas.sombra) and 'sombra' or 'habla' end
        local parte = p.partes[clave]
        if not parte or hechas[clave] then
            local k = estado.mision .. ':' .. estado.paso
            ESPERAS[k] = ESPERAS[k] or { tipo = 'esperar', texto = p.espera or 'Tu parte está hecha. Espera a tu compañero.' }
            return ESPERAS[k], m
        end
        return parte, m
    end
    return p, m
end

--- Pone (o corrige) el punto invisible de la ruta en la carretera mas cercana.
local function RutaACarretera()
    local r = rutaPendiente
    if not r or not r.x or not r.y then rutaPendiente = nil return end
    r.z = r.z or 0.0
    local hay, nodo = GetClosestVehicleNode(r.x, r.y, r.z, 1, 3.0, 0)
    local buena = hay and #(nodo - vector3(r.x, r.y, r.z)) < 150.0
    if buena or not r.puesta then
        local x, y, z = r.x, r.y, r.z
        if buena then x, y, z = nodo.x, nodo.y, nodo.z end
        OrigenMapa.Poner('objetivo_ruta', {
            x = x, y = y, z = z, cat = 'misiones', nombre = r.nombre,
            ruta = true, minimapa = false, mapa = false,
        })
        r.puesta = true
    end
    if buena then rutaPendiente = nil end
end

local function PonerObjetivo(p, sitio)
    sitio = sitio or p
    -- Una llamada no tiene sitio: nada que marcar en el mapa.
    if not sitio.x or not sitio.y then return end
    if p.tipo == 'alejarse' then
        OrigenMapa.Poner('objetivo', {
            x = p.x, y = p.y, z = p.z, cat = 'misiones', nombre = p.texto,
            radio = p.radio, color = '#ff0a5c',
        })
        return
    end
    --[[ La chincheta va en el sitio exacto; la RUTA, a la carretera mas
         cercana. El GPS de GTA solo traza caminos por carretera: con el punto
         en un patio, un desguace o la orilla del lago no encontraba camino y
         no se pintaba nada. Si el mapa de carreteras de esa zona aun no esta
         cargado (lejos), se recalcula al acercarse (ver RutaACarretera). ]]
    OrigenMapa.Poner('objetivo', {
        x = sitio.x, y = sitio.y, z = sitio.z, cat = 'misiones', nombre = p.texto,
        pulso = true, color = '#ff0a5c',
    })
    rutaPendiente = { x = sitio.x, y = sitio.y, z = sitio.z, nombre = p.texto, puesta = false }
    RutaACarretera()
end

--- Pide al servidor que mire el paso. Una a la vez.
local function Cumplir()
    if pidiendo or not estado then return end
    pidiendo = true
    local paso = estado.paso
    -- En un paso doble, cerrar mi parte tambien cuenta (si no, no salia su pista).
    local clave = estado.papel
    local yaHecha = estado.partes and clave and estado.partes[clave]
    local nuevo = lib.callback.await('origen_mision:cumplir', false, paso)
    pidiendo = false
    if nuevo == nil then return true end
    if nuevo.paso ~= paso then return true end
    return (not yaHecha and clave and nuevo.partes and nuevo.partes[clave]) and true or false
end

local function Enemigos(p)
    local e = p.enemigos
    local lista = {}
    for i = 1, e.n do lista[i] = { modelo = ModeloN(e.modelo, i), arma = e.arma, vida = e.vida, blindaje = e.blindaje, precision = e.precision } end
    if e.jefe then
        local j = e.jefe
        table.insert(lista, 1, { modelo = j.modelo, arma = j.arma, vida = j.vida, blindaje = j.blindaje, precision = e.precision, jefe = j.nombre })
    end

    local relacion = joaat('HATES_PLAYER')
    local nets = {}
    local radio = e.radio or 8.0
    for i, d in ipairs(lista) do
        local hash = Cargar(d.modelo)
        if not hash then return false end
        local x, y = p.x, p.y
        if not d.jefe then
            local ang = (i / #lista) * math.pi * 2 + math.random() * 0.6
            local r = radio * (0.45 + math.random() * 0.55)
            x, y = p.x + math.cos(ang) * r, p.y + math.sin(ang) * r
        end
        local z
        x, y, z = SitioPeaton(x, y, p.z)
        local ped = CreatePed(4, hash, x, y, z, math.random(0, 359) + 0.0, true, true)
        SetModelAsNoLongerNeeded(hash)
        if not ped or ped == 0 then return false end
        SetEntityAsMissionEntity(ped, true, true)
        if (d.vida or 200) > 200 then SetEntityMaxHealth(ped, d.vida) end
        SetEntityHealth(ped, d.vida or 200)
        SetPedArmour(ped, d.blindaje or 0)
        SetPedAccuracy(ped, d.precision or 30)
        SetPedRelationshipGroupHash(ped, relacion)
        SetPedCombatAttributes(ped, 46, true)    -- pelea hasta el final
        SetPedCombatAttributes(ped, 5, true)     -- aunque vaya en desventaja
        SetPedFleeAttributes(ped, 0, false)
        SetPedConfigFlag(ped, 281, true)         -- sin retorcerse en el suelo: o en pie o fuera
        SetPedDropsWeaponsWhenDead(ped, false)
        if d.arma then GiveWeaponToPed(ped, joaat(d.arma), 250, false, true) end
        TaskGuardCurrentPosition(ped, 10.0, 10.0, true)
        ents.peds[#ents.peds + 1] = ped
        local hasta = GetGameTimer() + 2000
        while not NetworkGetEntityIsNetworked(ped) and GetGameTimer() < hasta do Wait(0) end
        nets[#nets + 1] = NetworkGetNetworkIdFromEntity(ped)
        OrigenMapa.Poner('enemigo_' .. #ents.peds, {
            entidad = ped, cat = 'illegal', nombre = d.jefe or 'Enemigo', color = d.jefe and '#ff0a5c' or '#e03232',
        })
    end
    -- Que el servidor los vea antes de preguntarle por ellos.
    Wait(500)
    return lib.callback.await('origen_mision:apuntar', false, estado.paso, { peds = nets })
end

local function Coche(p)
    local hash = Cargar(p.vehiculo)
    if not hash then return false end
    local z = Suelo(p.x, p.y, p.z)
    local veh = CreateVehicle(hash, p.x, p.y, z + 0.3, (p.h or 0.0) + 0.0, true, true)
    SetModelAsNoLongerNeeded(hash)
    if not veh or veh == 0 then return false end
    SetEntityAsMissionEntity(veh, true, true)
    SetVehicleOnGroundProperly(veh)
    SetVehicleDoorsLocked(veh, 1)
    SetVehicleNeedsToBeHotwired(veh, false)
    SetVehicleNumberPlateText(veh, ('NT%06d'):format(math.random(0, 999999)))
    ents.veh = veh
    OrigenMapa.Poner('coche', { entidad = veh, cat = 'misiones', nombre = 'El coche', color = '#ff0a5c', pulso = true })
    Wait(500)
    return lib.callback.await('origen_mision:apuntar', false, estado.paso, { veh = NetworkGetNetworkIdFromEntity(veh) })
end

local function Prop(p)
    -- Si el modelo de la config no existe, un maletin: sin objeto no hay paso.
    local hash = Cargar(p.prop or 'prop_ld_case_01') or Cargar('prop_ld_case_01')
    if not hash then return end
    local z = Suelo(p.x, p.y, p.z)
    local o = CreateObject(hash, p.x, p.y, z, false, false, false)
    SetModelAsNoLongerNeeded(hash)
    PlaceObjectOnGroundProperly(o)
    FreezeEntityPosition(o, true)
    ents.prop = o
end

local function ALaMano(modelo)
    SoltarMano()
    local hash = Cargar(modelo)
    if not hash then return end
    local ped = PlayerPedId()
    local o = CreateObject(hash, 0.0, 0.0, 0.0, true, true, false)
    SetModelAsNoLongerNeeded(hash)
    AttachEntityToEntity(o, ped, GetPedBoneIndex(ped, 57005), 0.12, 0.0, -0.02, -90.0, 0.0, 90.0, true, true, false, true, 1, true)
    ents.mano = o
    -- Se ve que lo coge y al rato se lo guarda: llevarlo en la mano todo el
    -- trabajo (con el movil, con el arma) quedaba feo. Ya esta en el inventario.
    SetTimeout(2500, function()
        if ents.mano == o then SoltarMano() end
    end)
end

local function Agacharse()
    local ped = PlayerPedId()
    if pcall(lib.requestAnimDict, 'pickup_object', 3000) then
        TaskPlayAnim(ped, 'pickup_object', 'pickup_low', 8.0, -8.0, 1100, 0, 0, false, false, false)
        Wait(900)
    end
end

-- ---------------------------------------------------------------------------
--  Asesinar e interceptar: un objetivo con nombre y su escolta
-- ---------------------------------------------------------------------------

--[[ Lo del paso en curso: el objetivo, sus escoltas, su coche y el estado del
     sigilo. Los escoltas van en un grupo propio, NEUTRAL con el jugador hasta
     que salta la alarma: hasta entonces montan guardia y no le atacan, que es
     lo que deja acercarse sin que salten todos encima.

       sospecha   0..100. Sube mientras un escolta (o el objetivo) le ve de
                  cerca; a 100, alarma. Baja sola si nadie le ve.
       alarma     ya le han descubierto: los escoltas atacan y el objetivo huye. ]]
local obj = nil
local blipHuida = nil   -- la ruta del GPS que sigue al objetivo cuando huye en coche
local GRUPO = nil
local GRUPO_JUGADOR = joaat('PLAYER')

local function Grupo()
    if not GRUPO then
        local _, g = AddRelationshipGroup('OM_ESCOLTA')
        GRUPO = g
    end
    return GRUPO
end

--- 3 neutral, 5 odio. En los dos sentidos.
local function Relacion(valor)
    local g = Grupo()
    SetRelationshipBetweenGroups(valor, g, GRUPO_JUGADOR)
    SetRelationshipBetweenGroups(valor, GRUPO_JUGADOR, g)
end

--- Vida, blindaje, puntería, arma. Igual para el objetivo y los escoltas.
--[[ Los que vienen a por el jugador en coche: si el coche no llega hasta el
     (un muelle, un callejon) se bajan lejos, le pierden de vista y se ponen a
     pasear. Durante tres minutos, el que no este peleando vuelve a por el. ]]
local function Acosar(gente)
    local fin = GetGameTimer() + 180000
    while GetGameTimer() < fin do
        Wait(2000)
        local yo = PlayerPedId()
        local vivos = 0
        for _, q in ipairs(gente) do
            if DoesEntityExist(q) and not IsPedDeadOrDying(q, true) then
                vivos = vivos + 1
                if not IsPedInCombat(q, yo) and #(GetEntityCoords(q) - GetEntityCoords(yo)) < 250.0 then
                    if IsPedInAnyVehicle(q, false) then TaskLeaveVehicle(q, GetVehiclePedIsIn(q, false), 256) end
                    TaskCombatPed(q, yo, 0, 16)
                end
            end
        end
        if vivos == 0 then return end
    end
end

local function Armar(ped, d)
    SetEntityAsMissionEntity(ped, true, true)
    -- Ropa, cara y accesorios al azar: dos del mismo modelo no salen iguales.
    SetPedRandomComponentVariation(ped, 0)
    SetPedRandomProps(ped)
    if (d.vida or 200) > 200 then SetEntityMaxHealth(ped, d.vida) end
    SetEntityHealth(ped, d.vida or 200)
    SetPedArmour(ped, d.blindaje or 0)
    SetPedAccuracy(ped, d.precision or 30)
    SetPedRelationshipGroupHash(ped, Grupo())
    SetPedCombatAttributes(ped, 46, true)
    SetPedCombatAttributes(ped, 5, true)
    SetPedConfigFlag(ped, 281, true)
    SetPedDropsWeaponsWhenDead(ped, false)
    -- Hasta la alarma no reaccionan solos a nada: lo decide el sigilo.
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedSeeingRange(ped, 40.0)
    if d.arma then GiveWeaponToPed(ped, joaat(d.arma), 250, false, true) end
end

local function NetDe(ent)
    local hasta = GetGameTimer() + 2000
    while not NetworkGetEntityIsNetworked(ent) and GetGameTimer() < hasta do Wait(0) end
    return NetworkGetNetworkIdFromEntity(ent)
end

local function Nodo(x, y, z)
    local ok, nodo, rumbo = GetClosestVehicleNodeWithHeading(x, y, z, 1, 3.0, 0)
    if ok then return nodo, rumbo end
    return vector3(x, y, z), 0.0
end

local function TodosLosPeds()
    if not obj then return {} end
    local t = { obj.ped }
    for _, e in ipairs(obj.escoltas) do t[#t + 1] = e end
    return t
end

QuitarObjetivo = function(borrar)
    if not obj then return end
    OrigenMapa.Quitar('objetivo_ped')
    if blipHuida then
        if DoesBlipExist(blipHuida) then RemoveBlip(blipHuida) end
        blipHuida = nil
    end
    if borrar then
        for _, e in ipairs(TodosLosPeds()) do
            if DoesEntityExist(e) and NetworkHasControlOfEntity(e) then DeleteEntity(e) end
        end
        if obj.veh and DoesEntityExist(obj.veh) and NetworkHasControlOfEntity(obj.veh) then DeleteEntity(obj.veh) end
        if obj.veh2 and DoesEntityExist(obj.veh2) and NetworkHasControlOfEntity(obj.veh2) then DeleteEntity(obj.veh2) end
        local r = obj.refuerzos
        if r then
            for _, q in ipairs(r.peds or {}) do
                if DoesEntityExist(q) and NetworkHasControlOfEntity(q) then DeleteEntity(q) end
            end
            if r.veh and DoesEntityExist(r.veh) and NetworkHasControlOfEntity(r.veh) then DeleteEntity(r.veh) end
        end
    end
    obj = nil
    Relacion(3)
end

--- El objetivo en el sitio, sus escoltas de guardia alrededor y su coche de huida.
local function PonerAsesinar(p)
    local o, e = p.objetivo, p.escoltas
    Relacion(3)
    local hash = Cargar(o.modelo)
    if not hash then return false end
    local ox, oy, z = SitioPeaton(p.x, p.y, p.z)
    local ped = CreatePed(4, hash, ox, oy, z, (o.h or 0.0) + 0.0, true, true)
    SetModelAsNoLongerNeeded(hash)
    if not ped or ped == 0 then return false end
    Armar(ped, o)
    if o.escena then TaskStartScenarioInPlace(ped, o.escena, 0, true) end
    obj = { ped = ped, escoltas = {}, alarma = false, sospecha = 0.0, vistos = {}, tipo = 'asesinar', p = p, gracia = GetGameTimer() + 8000 }
    --[[ Le han avisado (una conversacion mal llevada): los escoltas esperan
         con el arma en la mano y la sospecha empieza alta. ]]
    local avisado = p.avisado and estado and estado.marcas and estado.marcas[p.avisado]
    if avisado then
        obj.avisado = true
        obj.sospecha = 60.0
        obj.gracia = 0
    end

    local nets = {}
    local radio = e and e.radio or 6.0
    for i = 1, (e and e.n or 0) do
        local h2 = Cargar(ModeloN(e.modelo, i))
        if not h2 then return false end
        local ang = (i / e.n) * math.pi * 2 + math.random() * 0.5
        local r = radio * (0.6 + math.random() * 0.4)
        local x, y, zz = SitioPeaton(p.x + math.cos(ang) * r, p.y + math.sin(ang) * r, p.z)
        local esc = CreatePed(4, h2, x, y, zz, math.deg(ang) - 90.0, true, true)
        SetModelAsNoLongerNeeded(h2)
        if not esc or esc == 0 then return false end
        Armar(esc, e)
        --[[ La mitad de guardia mirando hacia fuera y la otra mitad dando
             vueltas cerca: asi hay huecos para colarse, pero se mueven. ]]
        if obj.avisado then
            if e.arma then SetCurrentPedWeapon(esc, joaat(e.arma), true) end
            TaskGuardCurrentPosition(esc, 6.0, 6.0, true)
        elseif i % 2 == 1 then
            TaskStartScenarioInPlace(esc, 'WORLD_HUMAN_GUARD_STAND', 0, true)
        else
            TaskWanderInArea(esc, p.x, p.y, p.z, radio, 2.0, 4.0)
        end
        obj.escoltas[#obj.escoltas + 1] = esc
        nets[#nets + 1] = NetDe(esc)
    end

    local datos = { objetivo = NetDe(ped), escoltas = nets }
    if p.huida and p.huida.vehiculo then
        local hv = Cargar(p.huida.vehiculo)
        if not hv then return false end
        local nodo, rumbo = Nodo(p.x, p.y, p.z)
        if #(nodo - vector3(p.x, p.y, p.z)) > 45.0 then
            local hx, hy, hz = SitioPeaton(p.x + 6.0, p.y + 6.0, p.z)
            nodo, rumbo = vector3(hx, hy, hz), 0.0
        end
        local veh = CreateVehicle(hv, nodo.x, nodo.y, nodo.z + 0.5, rumbo, true, true)
        SetModelAsNoLongerNeeded(hv)
        SetEntityAsMissionEntity(veh, true, true)
        SetVehicleOnGroundProperly(veh)
        SetVehicleDoorsLocked(veh, 1)
        obj.veh = veh
        datos.veh = NetDe(veh)
    end
    OrigenMapa.Poner('objetivo_ped', { entidad = ped, cat = 'illegal', nombre = o.nombre or 'Objetivo', color = '#ff0a5c', pulso = true })
    Wait(500)
    return lib.callback.await('origen_mision:apuntar', false, estado.paso, datos)
end

--- El convoy: el objetivo al volante, los escoltas dentro, parado hasta que
--- el jugador se acerca.
local function PonerInterceptar(p)
    local o, e = p.objetivo, p.escoltas
    Relacion(3)
    local hv, hp = Cargar(p.vehiculo), Cargar(o.modelo)
    if not hv or not hp then return false end
    local nodo, rumbo = Nodo(p.x, p.y, p.z)
    local veh = CreateVehicle(hv, nodo.x, nodo.y, nodo.z + 0.5, rumbo, true, true)
    SetModelAsNoLongerNeeded(hv)
    if not veh or veh == 0 then return false end
    SetEntityAsMissionEntity(veh, true, true)
    SetVehicleOnGroundProperly(veh)
    SetVehicleDoorsLocked(veh, 4)               -- nadie le saca del coche a mano
    local ped = CreatePedInsideVehicle(veh, 4, hp, -1, true, true)
    SetModelAsNoLongerNeeded(hp)
    Armar(ped, o)
    SetPedKeepTask(ped, true)
    obj = { ped = ped, escoltas = {}, alarma = false, sospecha = 0.0, vistos = {}, tipo = 'interceptar', p = p, veh = veh, arrancado = false }

    --[[ Los escoltas: los que caben, en su coche; el resto, en el coche
         escolta (`escoltas.vehiculo`), diez metros detras en la misma
         carretera, que le sigue a donde vaya. ]]
    local nets = {}
    local asientos = math.min(e and e.n or 0, GetVehicleModelNumberOfSeats(hv) - 1)
    local veh2, net2 = nil, nil
    if e and e.vehiculo and (e.n or 0) > asientos then
        local hv2 = Cargar(e.vehiculo)
        if not hv2 then return false end
        local atras = GetOffsetFromEntityInWorldCoords(veh, 0.0, -11.0, 0.0)
        veh2 = CreateVehicle(hv2, atras.x, atras.y, atras.z + 0.5, rumbo, true, true)
        SetModelAsNoLongerNeeded(hv2)
        SetEntityAsMissionEntity(veh2, true, true)
        SetVehicleOnGroundProperly(veh2)
        SetVehicleDoorsLocked(veh2, 4)
        obj.veh2 = veh2
        net2 = NetDe(veh2)
    end
    for i = 1, (e and e.n or 0) do
        local h2 = Cargar(ModeloN(e.modelo, i))
        if not h2 then return false end
        local esc
        if i <= asientos then
            esc = CreatePedInsideVehicle(veh, 4, h2, i - 1, true, true)
        elseif veh2 then
            -- El primero del coche escolta conduce.
            esc = CreatePedInsideVehicle(veh2, 4, h2, i - asientos - 2, true, true)
        else
            esc = CreatePed(4, h2, nodo.x + 2.0, nodo.y, nodo.z, rumbo, true, true)
        end
        SetModelAsNoLongerNeeded(h2)
        Armar(esc, e)
        SetPedKeepTask(esc, true)
        obj.escoltas[#obj.escoltas + 1] = esc
        nets[#nets + 1] = NetDe(esc)
    end
    OrigenMapa.Poner('objetivo_ped', { entidad = ped, cat = 'illegal', nombre = o.nombre or 'Objetivo', color = '#ff0a5c', pulso = true })
    Wait(500)
    return lib.callback.await('origen_mision:apuntar', false, estado.paso,
        { objetivo = NetDe(ped), escoltas = nets, veh = NetDe(veh), veh2 = net2 })
end

--- Que el coche escolta siga al del objetivo (al arrancar y con la alarma).
local function Escoltar(rapido)
    if not obj or not obj.veh2 or not DoesEntityExist(obj.veh2) then return end
    local conductor = GetPedInVehicleSeat(obj.veh2, -1)
    if conductor ~= 0 and not IsPedDeadOrDying(conductor, true) and DoesEntityExist(obj.veh) then
        TaskVehicleEscort(conductor, obj.veh2, obj.veh, -1, rapido and 45.0 or 22.0, rapido and 786468 or 786603, 8.0, 0, 5.0)
    end
end

--[[ Los refuerzos: un coche con mas gente que sale a unos 120 m por
     carretera y va derecho a por el jugador. Al llegar se bajan y pelean. ]]
local function Refuerzos(p)
    local r = p.refuerzos
    if not r or not obj or obj.refuerzos then return end
    obj.refuerzos = {}
    CreateThread(function()
        local hv, hp = Cargar(r.vehiculo), Cargar(ModeloN(r.modelo, 1))
        if not hv or not hp then return end
        local ang = math.random() * math.pi * 2
        local nodo, rumbo = Nodo(p.x + math.cos(ang) * 120.0, p.y + math.sin(ang) * 120.0, p.z)
        local veh = CreateVehicle(hv, nodo.x, nodo.y, nodo.z + 0.5, rumbo, true, true)
        SetModelAsNoLongerNeeded(hv)
        if not veh or veh == 0 then return end
        SetEntityAsMissionEntity(veh, true, true)
        SetVehicleOnGroundProperly(veh)
        obj.refuerzos.veh = veh
        local plazas = GetVehicleModelNumberOfSeats(hv)
        local nets, gente = {}, {}
        for i = 1, math.min(r.n, plazas) do
            local q = CreatePedInsideVehicle(veh, 4, Cargar(ModeloN(r.modelo, i)) or hp, i - 2, true, true)
            Armar(q, r)
            SetBlockingOfNonTemporaryEvents(q, false)
            gente[#gente + 1] = q
            nets[#nets + 1] = NetDe(q)
        end
        SetModelAsNoLongerNeeded(hp)
        obj.refuerzos.peds = gente
        lib.callback.await('origen_mision:refuerzos', false, estado and estado.paso, { peds = nets, veh = NetDe(veh) })
        Aviso('¡Vienen refuerzos!', 'error')
        local yo = PlayerPedId()
        local conductor = gente[1]
        if conductor then
            local c = GetEntityCoords(yo)
            TaskVehicleDriveToCoordLongrange(conductor, veh, c.x, c.y, c.z, 40.0, 786468, 20.0)
        end
        -- Al llegar (o si se quedan parados), abajo y a pelear.
        local hasta = GetGameTimer() + 60000
        while GetGameTimer() < hasta and DoesEntityExist(veh) do
            Wait(500)
            if #(GetEntityCoords(veh) - GetEntityCoords(yo)) < 30.0 or GetEntitySpeed(veh) < 0.5 and GetGameTimer() > hasta - 50000 then break end
        end
        for _, q in ipairs(gente) do
            if DoesEntityExist(q) and not IsPedDeadOrDying(q, true) then
                TaskLeaveVehicle(q, veh, 256)
                TaskCombatPed(q, yo, 0, 16)
            end
        end
        Acosar(gente)
    end)
end

--- Le han descubierto: los escoltas atacan, el objetivo huye y, si los hay,
--- llegan refuerzos.
local function Alarma(porque)
    if not obj or obj.alarma then return end
    obj.alarma = true
    Refuerzos(obj.p)
    obj.sospecha = 100.0
    local yo = PlayerPedId()
    local nombre = obj.p.objetivo.nombre or 'El objetivo'
    Relacion(5)
    for _, e in ipairs(obj.escoltas) do
        if DoesEntityExist(e) and not IsPedDeadOrDying(e, true) then
            SetBlockingOfNonTemporaryEvents(e, false)
            local enCoche = IsPedInAnyVehicle(e, false)
            local conduce = enCoche and GetPedInVehicleSeat(GetVehiclePedIsIn(e, false), -1) == e
            if not enCoche then ClearPedTasks(e) end
            -- El conductor del coche escolta sigue conduciendo; los demas, a por el.
            if not conduce then TaskCombatPed(e, yo, 0, 16) end
        end
    end
    local o = obj.ped
    if DoesEntityExist(o) and not IsPedDeadOrDying(o, true) then
        --[[ El objetivo NO se suelta a sus reacciones: el «huir de los tiros»
             del propio GTA le pisaba la orden de subir al vehiculo y salia
             corriendo a pie (probado con el camello, 05/10). ]]
        SetBlockingOfNonTemporaryEvents(o, true)
        SetPedKeepTask(o, true)
        if obj.tipo == 'interceptar' then
            -- A todo lo que da hasta el destino, saltandose lo que haga falta.
            local d = obj.p.destino
            TaskVehicleDriveToCoordLongrange(o, obj.veh, d.x, d.y, d.z, 45.0, 786468, 30.0)
            Escoltar(true)
            Aviso(('¡%s se ha dado cuenta! Acelera hacia %s.'):format(nombre, d.nombre or 'su destino'), 'error')
        elseif obj.veh and DoesEntityExist(obj.veh) then
            ClearPedTasksImmediately(o)
            TaskEnterVehicle(o, obj.veh, 20000, -1, 2.0, 1, 0)
            local veh = obj.veh
            CreateThread(function()
                local hasta = GetGameTimer() + 20000
                while DoesEntityExist(o) and not IsPedInVehicle(o, veh, false) and GetGameTimer() < hasta do Wait(250) end
                if DoesEntityExist(o) and IsPedInVehicle(o, veh, false) and not IsPedDeadOrDying(o, true) then
                    TaskVehicleMissionPedTarget(o, veh, yo, 8, 60.0, 786468, 2000.0, 10.0, true)   -- 8 = huir
                elseif DoesEntityExist(o) and not IsPedDeadOrDying(o, true) then
                    TaskSmartFleePed(o, yo, 2000.0, -1, false, false)
                end
            end)
            --[[ La persecucion: la ruta del GPS le sigue. El punto del mapa
                 ya va pegado a el (objetivo_ped); esto añade el camino por
                 carretera, con un blip invisible como hace origen_map (un
                 punto que se mueve no tiene coordenadas para su ruta). ]]
            if blipHuida and DoesBlipExist(blipHuida) then RemoveBlip(blipHuida) end
            blipHuida = AddBlipForEntity(o)
            SetBlipAlpha(blipHuida, 0)
            SetBlipRoute(blipHuida, true)
            SetBlipRouteColour(blipHuida, 1)
            Aviso(('¡Te han descubierto! %s corre a su coche y huye. Le tienes marcado en el mapa: persíguele y acaba con él.'):format(nombre), 'error')
        else
            ClearPedTasksImmediately(o)
            TaskSmartFleePed(o, yo, 2000.0, -1, false, false)
            Aviso(('¡Te han descubierto! %s sale corriendo.'):format(nombre), 'error')
        end
    end
end

--[[ El sigilo, unas diez veces por segundo mientras el paso esta montado.

     La alarma salta por cuatro cosas:
       · un disparo SIN silenciador a menos de 120 m;
       · alguien del grupo herido que sigue vivo (un tiro que no mata, un
         golpe que no derriba);
       · un escolta que ve caer a otro (o al objetivo) a menos de 20 m;
       · la sospecha a 100: mientras un escolta le ve de frente, sube; mas
         rapido cuanto mas cerca, el doble si va armado, la mitad si va
         agachado (y agachado le ven a menos distancia). ]]
local function Sigilo(yo, pos, dt)
    if not obj or obj.alarma then return end

    if IsPedShooting(yo) and not IsPedCurrentWeaponSilenced(yo) and #(pos - GetEntityCoords(obj.ped)) < 120.0 then
        return Alarma('disparo')
    end

    local todos = TodosLosPeds()
    for _, e in ipairs(todos) do
        if DoesEntityExist(e) then
            local caido = IsPedDeadOrDying(e, true)
            if not caido and HasEntityBeenDamagedByEntity(e, yo, true) then return Alarma('herido') end
            if caido and not obj.vistos[e] then
                obj.vistos[e] = true
                local donde = GetEntityCoords(e)
                for _, otro in ipairs(todos) do
                    if otro ~= e and DoesEntityExist(otro) and not IsPedDeadOrDying(otro, true)
                        and #(GetEntityCoords(otro) - donde) < 20.0 and HasEntityClearLosToEntityInFront(otro, e) then
                        return Alarma('cuerpo')
                    end
                end
            end
        end
    end

    -- En el convoy no hay medidor: le descubre el que se le pega demasiado rato.
    if obj.tipo == 'interceptar' then
        if obj.veh and HasEntityBeenDamagedByEntity(obj.veh, yo, true) then return Alarma('coche') end
        if #(pos - GetEntityCoords(obj.ped)) < 25.0 then
            obj.sospecha = obj.sospecha + dt * 15.0
        else
            obj.sospecha = math.max(0.0, obj.sospecha - dt * 10.0)
        end
        if obj.sospecha >= 100.0 then Alarma('seguido') end
        return
    end

    --[[ Lo que levanta sospechas, segun como vaya el jugador (y solo si un
         escolta le ve de frente):
           · desarmado y andando normal: un transeunte mas. Solo si se le pega
             a menos de 4 m.
           · agachado: alguien que se esconde. A menos de 10 m.
           · con un arma en la mano: a menos de 25 m, y sube rapido.
         Los primeros segundos despues de aparecer no cuentan: si el jugador
         ya estaba alli, no puede saltar la alarma solo por llegar. ]]
    if GetGameTimer() < (obj.gracia or 0) then return end
    local agachado = GetPedStealthMovement(yo)
    local armado = IsPedArmed(yo, 4) and GetSelectedPedWeapon(yo) ~= joaat('WEAPON_UNARMED')
    local alcance, ritmo = 4.0, 25.0
    if armado then alcance, ritmo = 25.0, 60.0
    elseif agachado then alcance, ritmo = 10.0, 35.0 end
    -- Avisados: te esperan. Te reconocen de mas lejos aunque vayas desarmado.
    if obj.avisado then alcance, ritmo = math.max(alcance + 5.0, armado and 30.0 or 15.0), ritmo * 1.5 end
    local sube = 0.0
    for _, e in ipairs(todos) do
        if DoesEntityExist(e) and not IsPedDeadOrDying(e, true) then
            local d = #(GetEntityCoords(e) - pos)
            if d < alcance and HasEntityClearLosToEntityInFront(e, yo) then
                local v = ritmo * (0.5 + (1.0 - d / alcance))
                if v > sube then sube = v end
            end
        end
    end
    if sube > 0 then
        obj.sospecha = math.min(100.0, obj.sospecha + sube * dt)
    else
        -- Si le avisaron, no se relajan: nunca por debajo del 50 %.
        obj.sospecha = math.max(obj.avisado and 50.0 or 0.0, obj.sospecha - 8.0 * dt)
    end
    if obj.sospecha >= 100.0 then Alarma('visto') end
end

-- ---------------------------------------------------------------------------
--  Investigar: hablar con alguien o registrar algo, y la pista
-- ---------------------------------------------------------------------------

local testigo = nil        -- el PNJ local del paso de investigar
local investigando = false
--[[ Un preso atado (npc con `silla`): la silla va con el y, al acabar, no se
     va andando: se queda en su silla y se borra cuando el jugador se aleja. ]]
local sillaDe = {}         -- [ped] = silla
local atados = {}          -- { { ped, silla, pos } } los que se quedan
local function BorrarAtado(t)
    for _, e in ipairs({ t.ped, t.silla }) do if e and DoesEntityExist(e) then DeleteEntity(e) end end
end
BorrarAtados = function()
    for _, t in ipairs(atados) do BorrarAtado(t) end
    atados = {}
end

--[[ `irse`: al pasar al paso siguiente no desaparece delante del jugador:
     se va andando (o se mete en su coche, si tiene uno al lado) y el juego
     lo borra solo cuando ya no se le ve. Al acabar el trabajo, fuera sin mas. ]]
local function Irse(ped)
    if not DoesEntityExist(ped) then return end
    FreezeEntityPosition(ped, false)
    SetEntityInvincible(ped, false)
    ClearPedTasks(ped)
    if cocheParado and DoesEntityExist(cocheParado) and #(GetEntityCoords(ped) - GetEntityCoords(cocheParado)) < 15.0 then
        SetVehicleDoorsLocked(cocheParado, 1)
        TaskEnterVehicle(ped, cocheParado, 20000, -1, 1.0, 1, 0)
    else
        TaskWanderStandard(ped, 10.0, 10)
    end
    SetPedKeepTask(ped, true)
    SetEntityAsNoLongerNeeded(ped)
end

QuitarTestigo = function(irse)
    local ped = testigo
    testigo = nil
    if not ped or not DoesEntityExist(ped) then return end
    local silla = sillaDe[ped]
    sillaDe[ped] = nil
    if silla then
        local t = { ped = ped, silla = silla, pos = GetEntityCoords(ped) }
        if irse then atados[#atados + 1] = t else BorrarAtado(t) end
        return
    end
    if not irse then DeleteEntity(ped) return end
    --[[ El servidor cierra el paso al acabar el dialogo, pero su ultima frase
         sigue en pantalla: se queda delante hasta que se cierra la charla. ]]
    if charlando then
        CreateThread(function()
            while charlando and DoesEntityExist(ped) do Wait(200) end
            Irse(ped)
        end)
        return
    end
    Irse(ped)
end

--- (dx, dy) girado `h` grados: lo que esta a la derecha/delante de algo.
local function RotarXY(dx, dy, h)
    local r = math.rad(h)
    return vector3(dx * math.cos(r) - dy * math.sin(r), dx * math.sin(r) + dy * math.cos(r), 0.0)
end

--- Una animacion de la escena del preso, en el origen del paso.
local function Preso(ped, p, anim, bucle)
    if not anim or not DoesEntityExist(ped) or not pcall(lib.requestAnimDict, anim[1], 3000) then return end
    local z = Suelo(p.x, p.y, p.z)
    -- 512 sin colision, 1024 la animacion manda sobre la fisica, 2048 sin
    -- gravedad: la escena va bajada (`oz`) y si no, se caia por el suelo.
    TaskPlayAnimAdvanced(ped, anim[1], anim[2], p.x + 0.0, p.y + 0.0, z + (p.oz or 0.0), 0.0, 0.0, (p.npc and p.npc.h or p.h or 0.0) + 0.0,
        8.0, 8.0, -1, (bucle and 1 or 0) + 512 + 1024 + 2048, 0.0, 2, 0)
end

local function PonerTestigo(p)
    local hash = Cargar(p.npc.modelo)
    if not hash then return end
    -- Los puntos de los testigos estan medidos a pie uno a uno: se respeta el
    -- punto (solo se baja al suelo). El «sitio seguro» lo movia hasta 10 m y
    -- Nando salia lejos de su furgoneta.
    local x, y, z = p.x + 0.0, p.y + 0.0, Suelo(p.x, p.y, p.z)
    local ped = CreatePed(4, hash, x, y, z, (p.npc.h or 0.0) + 0.0, false, false)
    SetModelAsNoLongerNeeded(hash)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    FreezeEntityPosition(ped, true)
    if p.npc.escena then TaskStartScenarioInPlace(ped, p.npc.escena, 0, true) end
    --[[ `silla = { modelo, dx, dy, dz, dh }` y `anim = { dict, anim }`: el
         preso atado. Las animaciones de la tortura son de escena (las dos
         partes, la del que aprieta y la del preso, comparten origen): el
         origen es el punto de la config; la silla, desplazada de el. ]]
    if p.npc.silla then
        local si = p.npc.silla
        local h = (p.npc.h or 0.0) + 0.0
        local hs = Cargar(si[1])
        if hs then
            local o = vector3(x, y, z) + RotarXY(si[2] or 0.0, si[3] or 0.0, h)
            local obj = CreateObjectNoOffset(hs, o.x, o.y, o.z + (si[4] or 0.0), false, false, false)
            SetEntityHeading(obj, h + (si[5] or 0.0))
            FreezeEntityPosition(obj, true)
            SetEntityCollision(obj, false, false)
            SetModelAsNoLongerNeeded(hs)
            sillaDe[ped] = obj
        end
        -- Congelado no se coloca en la animacion de escena: se suelta, se pone en
        -- su sitio y se vuelve a congelar (sin colision: si no, al estar la
        -- escena bajada `oz`, se caia por debajo del suelo).
        FreezeEntityPosition(ped, false)
        SetPedCanRagdoll(ped, false)
        Preso(ped, p, p.npc.anim, true)
        CreateThread(function()
            Wait(400)
            if DoesEntityExist(ped) then FreezeEntityPosition(ped, true) end
        end)
    end
    testigo = ped
end

--[[ Interrogar entre dos: la parte `torturar` (la que aprieta) de un paso
     doble. Cada E, la accion siguiente; el servidor la apunta y avisa al
     grupo (origen_mision:cl:tortura) para que el preso reaccione en todos. ]]
local apretando = false
local function ParteTortura(paso)
    local m = estado and PorId[estado.mision]
    local e = m and m.pasos[paso]
    for _, pp in pairs(e and e.partes or {}) do if pp.tipo == 'torturar' then return pp end end
    return nil
end
local function AccionSiguiente(pt)
    return pt and pt.acciones[(estado and estado.presion or 0) + 1] or nil
end
local function Apretar()
    if apretando or not estado then return end
    apretando = true
    local r = lib.callback.await('origen_mision:torturar', false, estado.paso)
    if not (r and r.ok) then
        if r and r.motivo then Aviso(r.motivo, 'error') end
        apretando = false
    end
end

RegisterNetEvent('origen_mision:cl:tortura', function(paso, i, yo)
    local pt = ParteTortura(paso)
    local acc = pt and pt.acciones[i]
    if not acc then apretando = false return end
    local preso = testigo
    if preso and DoesEntityExist(preso) and acc.victima then Preso(preso, pt, acc.victima, true) end
    local props, cuerdas = {}, {}
    --[[ La voz del preso (`grita`, grabada con voces.py) a quien este cerca, y
         sus gritos de dolor del juego mientras dura (`dolor`). ]]
    if preso and DoesEntityExist(preso) and #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(preso)) < 20.0 then
        local voz, dura = Voz(acc.grita)
        if voz then
            SetTimeout(acc.dolor and 900 or 300, function() SendNUIMessage({ a = 'voz', voz = voz }) end)
            Labios(preso, dura)
        end
        if acc.dolor then
            CreateThread(function()
                local fin = GetGameTimer() + math.floor((acc.t or 6) * 1000) - 500
                Wait(300)
                while GetGameTimer() < fin and DoesEntityExist(preso) do
                    PlayPain(preso, math.random(6, 8), 0)
                    Wait(math.random(1300, 2200))
                end
            end)
        end
    end
    --[[ `chispas`: chispazos en el preso mientras dura (en todos los clientes). ]]
    if acc.chispas and preso and DoesEntityExist(preso) then
        CreateThread(function()
            RequestNamedPtfxAsset('core')
            local hasta = GetGameTimer() + 2000
            while not HasNamedPtfxAssetLoaded('core') and GetGameTimer() < hasta do Wait(0) end
            local fin = GetGameTimer() + math.floor((acc.t or 6) * 1000) - 300
            while GetGameTimer() < fin and DoesEntityExist(preso) do
                UseParticleFxAssetNextCall('core')
                StartParticleFxNonLoopedOnPedBone('ent_brk_sparking_wires', preso, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 24818, 0.6, false, false, false)
                Wait(math.random(350, 800))
            end
        end)
    end
    if yo then
        local ped = PlayerPedId()
        SetCurrentPedWeapon(ped, joaat('WEAPON_UNARMED'), true)
        if acc.jugador and pcall(lib.requestAnimDict, acc.jugador[1], 3000) then
            if acc.escena then
                --[[ De escena: las dos partes comparten origen (la silla), pero la
                     del que aprieta empieza en SU sitio de la escena (a un lado y
                     delante del preso). Se le pone ahi, con su rumbo, y se
                     reproduce en el sitio: con TaskPlayAnimAdvanced se quedaba
                     en el origen, metido en la silla con el preso. ]]
                local z = Suelo(pt.x, pt.y, pt.z) + (pt.oz or 0.0)
                local h = (pt.npc and pt.npc.h or 0.0) + 0.0
                local ini = GetAnimInitialOffsetPosition(acc.jugador[1], acc.jugador[2], pt.x + 0.0, pt.y + 0.0, z, 0.0, 0.0, h, 0.0, 2)
                local rot = GetAnimInitialOffsetRotation(acc.jugador[1], acc.jugador[2], pt.x + 0.0, pt.y + 0.0, z, 0.0, 0.0, h, 0.0, 2)
                SetEntityCoordsNoOffset(ped, ini.x, ini.y, ini.z, false, false, false)
                SetEntityHeading(ped, rot.z)
                TaskPlayAnim(ped, acc.jugador[1], acc.jugador[2], 8.0, -8.0, -1, 1, 0.0, false, false, false)
            else
                if preso and DoesEntityExist(preso) then TaskTurnPedToFaceEntity(ped, preso, 600) Wait(600) end
                TaskPlayAnim(ped, acc.jugador[1], acc.jugador[2], 4.0, -4.0, -1, 1, 0.0, false, false, false)
            end
        end
        -- `mano = { modelo, x, y, z, rx, ry, rz }`: lo que lleva en la mano derecha;
        -- `mano2`, en la izquierda (las pinzas de la bateria, una en cada mano).
        local enMano = {}
        for _, def in ipairs({ { acc.mano, 57005 }, { acc.mano2, 18905 } }) do
            local m = def[1]
            local h = m and Cargar(m[1])
            if h then
                local o = CreateObject(h, 0.0, 0.0, 0.0, true, true, false)
                AttachEntityToEntity(o, ped, GetPedBoneIndex(ped, def[2]), m[2] or 0.0, m[3] or 0.0, m[4] or 0.0,
                    m[5] or 0.0, m[6] or 0.0, m[7] or 0.0, true, true, false, true, 1, true)
                props[#props + 1] = o
                enMano[#enMano + 1] = o
            end
        end
        -- `suelo = { modelo, dx, dy }`: lo que se deja al lado de la silla (la bateria).
        local bateria = nil
        if acc.suelo then
            local h = Cargar(acc.suelo[1])
            if h then
                local o = vector3(pt.x, pt.y, 0.0) + RotarXY(acc.suelo[2] or 0.0, acc.suelo[3] or 0.0, (pt.npc and pt.npc.h or 0.0) + 0.0)
                local obj = CreateObject(h, o.x, o.y, Suelo(pt.x, pt.y, pt.z), true, true, false)
                PlaceObjectOnGroundProperly(obj)
                FreezeEntityPosition(obj, true)
                props[#props + 1] = obj
                bateria = obj
            end
        end
        --[[ `cables`: un cable de cada borne de la bateria a cada pinza (cuerdas
             del juego). Se ven en este cliente; las pinzas y la bateria, en todos. ]]
        if acc.cables and bateria then
            RopeLoadTextures()
            local hasta = GetGameTimer() + 2000
            while not RopeAreTexturesLoaded() and GetGameTimer() < hasta do Wait(0) end
            for i, pinza in ipairs(enMano) do
                local borne = GetOffsetFromEntityInWorldCoords(bateria, i == 1 and 0.08 or -0.08, 0.0, 0.2)
                local cp = GetEntityCoords(pinza)
                local largo = #(cp - borne) + 0.6
                local cuerda = AddRope(borne.x, borne.y, borne.z, 0.0, 0.0, 0.0, largo, 4, largo + 0.5, 0.5, 1.0, false, false, false, 1.0, false, 0)
                if cuerda then
                    AttachEntitiesToRope(cuerda, bateria, pinza, borne.x, borne.y, borne.z, cp.x, cp.y, cp.z, largo, false, false, nil, nil)
                    cuerdas[#cuerdas + 1] = cuerda
                end
            end
        end
        if acc.texto then Aviso(acc.texto, 'info') end
    end
    SetTimeout(math.floor((acc.t or 6) * 1000), function()
        if yo then
            ClearPedTasks(PlayerPedId())
            for _, c in ipairs(cuerdas) do DeleteRope(c) end
            for _, o in ipairs(props) do if DoesEntityExist(o) then DeleteEntity(o) end end
            apretando = false
        end
        if preso and DoesEntityExist(preso) and pt.npc then Preso(preso, pt, pt.npc.anim, true) end
    end)
end)


--[[ Una conversacion con respuestas (paso investigar con `dialogo`).

     El arbol esta en la config (compartida): aqui se va pintando nodo a nodo
     en la pantalla y se apunta el camino de respuestas. Al llegar a un final
     se manda el camino al servidor, que lo recorre otra vez, cobra lo que
     haya que pagar y decide. Cerrar la ventana a medias no cuenta: se puede
     volver a hablar. (`eleccion` se declara arriba: la usa el callback `cerrar`.) ]]

local function TengoPista(id)
    for _, x in ipairs(estado and estado.pistas or {}) do if x == id then return true end end
    return false
end

RegisterNUICallback('elegir', function(d, cb)
    cb(true)
    if eleccion then local p = eleccion; eleccion = nil; p:resolve(tonumber(d and d.i)) end
end)

local function Opciones(nodo)
    local t = {}
    for i, op in ipairs(nodo.opciones or {}) do
        local objeto = type(op.requiere) == 'string' and op.requiere:match('^objeto:(.+)$')
        local presion = type(op.requiere) == 'string' and tonumber(op.requiere:match('^presion:(%d+)$'))
        t[i] = { texto = op.texto, paga = op.paga, arma = op.requiere == 'arma',
                 objeto = objeto and Config.Pistas[objeto] and Config.Pistas[objeto].titulo or nil,
                 presion = presion, falta = presion and ((estado and estado.presion or 0) < presion) or nil }
    end
    return t
end

--[[ Las voces: lo que dicen los demas personajes esta grabado (voces.lua,
     generado por herramientas/voces.py). Lo del jugador no lleva voz. ]]
Voz = function(texto)
    local v = Voces and Voces[texto]
    if v then return v[1], v[2] end
end

--- Mueve los labios del personaje mientras suena su voz.
Labios = function(ped, segundos)
    if not ped or not DoesEntityExist(ped) or not segundos then return end
    if not pcall(lib.requestAnimDict, 'mp_facial', 2000) then return end
    SetFacialIdleAnimOverride(ped, 'mic_chatter', 0)
    SetTimeout(math.floor(segundos * 1000), function()
        if DoesEntityExist(ped) then ClearFacialIdleAnimOverride(ped) end
    end)
end

--[[ El plano de la conversacion, como en GTA: los dos se miran y la camara se
     pone sobre el hombro del jugador encuadrando la cara del otro. Si entre la
     cabeza del jugador y la camara hay una pared, la camara se acerca. ]]
local function PlanoCharla(yo)
    if not testigo or not DoesEntityExist(testigo) then return nil end
    local a, b = GetEntityCoords(yo), GetEntityCoords(testigo)
    SetEntityHeading(yo, GetHeadingFromVector_2d(b.x - a.x, b.y - a.y))
    if not sillaDe[testigo] then SetEntityHeading(testigo, GetHeadingFromVector_2d(a.x - b.x, a.y - b.y)) end
    Wait(50)
    local cabeza = GetPedBoneCoords(yo, 31086, 0.0, 0.0, 0.0)
    local sitio = GetOffsetFromEntityInWorldCoords(yo, 0.45, -0.85, 0.7)
    local h = StartExpensiveSynchronousShapeTestLosProbe(cabeza.x, cabeza.y, cabeza.z, sitio.x, sitio.y, sitio.z, 1 + 16, yo, 0)
    local _, choca, donde = GetShapeTestResult(h)
    if choca == 1 then sitio = cabeza + (donde - cabeza) * 0.75 end
    local cara = GetPedBoneCoords(testigo, 31086, 0.0, 0.0, 0.0)
    local cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamCoord(cam, sitio.x, sitio.y, sitio.z)
    PointCamAtCoord(cam, cara.x, cara.y, cara.z - 0.05)
    SetCamFov(cam, 42.0)
    RenderScriptCams(true, true, 700, true, true)
    return cam
end

local function Conversar(p)
    local d = p.dialogo
    local yo = PlayerPedId()
    local nombre = p.npc and p.npc.nombre or 'Testigo'
    local id, ruta = d.inicio, {}
    HudFuera(true)
    panel = true
    charlando = true
    SetNuiFocus(true, true)
    local cam = PlanoCharla(yo)
    local conArma = false
    for _, n in pairs(d.nodos) do for _, op in ipairs(n.opciones or {}) do if op.requiere == 'arma' then conArma = true end end end
    if p.escena_jugador and not conArma then TaskStartScenarioInPlace(yo, p.escena_jugador, 0, true) end
    local aviso = nil
    while true do
        local nodo = d.nodos[id]
        -- La voz solo la primera vez que sale el nodo, no al repetirlo por un aviso.
        local voz, dura = nil, nil
        if not aviso then voz, dura = Voz(nodo.dice) end
        SendNUIMessage({ a = 'dialogo', nombre = nombre, dice = nodo.dice, opciones = Opciones(nodo), aviso = aviso, voz = voz })
        if voz then Labios(testigo, dura) end
        aviso = nil
        if nodo.fin then break end
        local pr = promise.new()
        eleccion = pr
        -- Si el compañero aprieta mientras se lee, el sello «Presión» se pone al dia.
        if testigo and sillaDe[testigo] then
            local presion0 = estado and estado.presion
            CreateThread(function()
                while eleccion == pr do
                    Wait(300)
                    if eleccion == pr and estado and estado.presion ~= presion0 then
                        presion0 = estado.presion
                        SendNUIMessage({ a = 'dialogo', nombre = nombre, dice = nodo.dice, opciones = Opciones(nodo) })
                    end
                end
            end)
        end
        local i = Citizen.Await(pr)
        if not i then id = nil break end
        local op = nodo.opciones[i]
        local objeto = op and type(op.requiere) == 'string' and op.requiere:match('^objeto:(.+)$')
        local presion = op and type(op.requiere) == 'string' and tonumber(op.requiere:match('^presion:(%d+)$'))
        if presion and (estado and estado.presion or 0) < presion then
            aviso = (estado and estado.solo) and 'Todavía no está lo bastante asustado. Sal de la charla y apriétale (G).'
                or 'Todavía no está lo bastante asustado. Que tu compañero apriete más.'
        elseif op and op.requiere == 'arma' and GetSelectedPedWeapon(yo) == joaat('WEAPON_UNARMED') then
            aviso = 'Para eso tienes que sacar el arma.'
        elseif objeto and not TengoPista(objeto) then
            aviso = ('No tienes: %s.'):format(Config.Pistas[objeto] and Config.Pistas[objeto].titulo or objeto)
        elseif op then
            -- Volver al principio no cuenta: el servidor recorre el camino desde ahi.
            if op.va == d.inicio and not op.paga then ruta = {} else ruta[#ruta + 1] = i end
            id = op.va
        end
    end

    local r = nil
    if id then
        r = lib.callback.await('origen_mision:hablar', false, estado and estado.paso, ruta)
        if r and r.ok then
            -- El final se queda en pantalla un momento para leerlo.
            local pr = promise.new()
            eleccion = pr
            -- Lo que dure su voz, si es mas larga.
            local _, dura = Voz(d.nodos[id] and d.nodos[id].dice)
            local ms = math.max(9000, math.floor(((dura or 0) + 1.5) * 1000))
            SetTimeout(ms, function() if eleccion == pr then eleccion = nil; pr:resolve(nil) end end)
            Citizen.Await(pr)
        elseif r and r.motivo then
            Aviso(r.motivo, 'error')
        end
    end
    SendNUIMessage({ a = 'cerrar' })
    SetNuiFocus(false, false)
    if cam then
        RenderScriptCams(false, true, 700, true, true)
        DestroyCam(cam, false)
    end
    panel = false
    charlando = false
    HudFuera(false)
    ClearPedTasks(yo)
    -- Los papeles que han llegado hablando (por el evento: Leer va mas abajo).
    if #colaPapeles > 0 then
        SetTimeout(400, function() TriggerEvent('origen_mision:cl:siguientePapel') end)
    end
    if r and r.ok then
        if (r.pagado or 0) > 0 then Aviso(('Has pagado %d $.'):format(r.pagado), 'info') end
        if r.pista then
            exports.origen_notify:Notify({ title = 'Pista', description = r.pista, type = 'info', duration = 15000 })
        end
        if r.fin ~= 'habla' then
            exports.origen_notify:Notify({ title = 'Mala señal', description = 'Esa conversación no ha ido bien. Alguien se va a enterar de que le buscas.', type = 'error', duration = 9000 })
        end
    end
    return r and r.ok
end

--[[ Hacer la investigacion: la animacion que toca (rebuscar en la basura,
     hablar con alguien...) durante `tiempo` segundos con la barra del HUD.
     Si se aleja, se corta. Despues el servidor lo da por bueno (mira que este
     ahi y que haya pasado el tiempo) y sale la pista. ]]
local function Investigar(p)
    -- Con un papel abierto no: un minijuego encima se llevaba el raton y el
    -- papel se quedaba en pantalla sin poder cerrarlo.
    if investigando or leyendo then return end
    if p.necesita and not TengoPista(p.necesita) then
        Aviso(p.sinNecesita or 'Te falta algo para esto.', 'error')
        return
    end
    if p.ventana then
        local v = estado and estado.ventana
        local abierta = v and v.nombre == p.ventana and v.hasta and v.hasta > GetGameTimer()
        if not abierta then
            Aviso(p.sinVentana or 'Ahora no: espera a que tu compañero te dé la señal.', 'error')
            return
        end
    end
    investigando = true
    if p.dialogo then
        Conversar(p)
        investigando = false
        return
    end
    local yo = PlayerPedId()
    local donde = testigo and GetEntityCoords(testigo) or vector3(p.x, p.y, p.z)
    --[[ Antes, el minijuego (`minijuego = { juego, dificultad, titulo }`), si
         origen_minijuegos esta en marcha: la ganzua para el maletero. Si se
         pierde, no pasa nada mas: se puede volver a intentar. ]]
    if p.minijuego and GetResourceState('origen_minijuegos') == 'started' then
        local pr = promise.new()
        -- El rastreador de misiones y el HUD fuera: si no, se pisan con el minijuego.
        HudFuera(true)
        local ok = pcall(function()
            exports.origen_minijuegos:StartMinijuego(p.minijuego[1], p.minijuego[2] or 'medium',
                { titulo = p.minijuego.titulo }, function(exito) pr:resolve(exito == true) end)
        end)
        local gana = ok and Citizen.Await(pr)
        HudFuera(false)
        if ok and not gana then
            Aviso(p.minijuego.fallo or 'No ha salido. Prueba otra vez.', 'error')
            investigando = false
            return
        end
    end
    if p.coche and cocheParado and DoesEntityExist(cocheParado) then
        donde = GetEntityCoords(cocheParado)
        SetVehicleDoorOpen(cocheParado, 5, false, false)
    end
    -- Con rumbo en la config (la puerta de la trastienda), mirando hacia alli.
    if p.h and not testigo and not p.coche then
        TaskAchieveHeading(yo, p.h + 0.0, 800)
    else
        TaskTurnPedToFaceCoord(yo, donde.x, donde.y, donde.z, 800)
    end
    Wait(800)
    --[[ `anim` antes que `escena_jugador`: los escenarios PROP_* llevan al
         personaje andando hasta el objeto de ese tipo mas cercano (una
         papelera), y al alejarse se cortaba la investigacion. ]]
    if p.anim and pcall(lib.requestAnimDict, p.anim[1], 3000) then
        TaskPlayAnim(yo, p.anim[1], p.anim[2], 4.0, -4.0, -1, 1, 0.0, false, false, false)
    elseif p.escena_jugador then
        TaskStartScenarioInPlace(yo, p.escena_jugador, 0, true)
    end
    if testigo then TaskTurnPedToFaceEntity(testigo, yo, 1000) end
    local ms = (p.tiempo or 5) * 1000
    pcall(function() exports.origen_hud:ShowProgress(ms, p.accion or 'Investigando') end)
    local hasta, inicio = GetGameTimer() + ms, GetEntityCoords(yo)
    local cortado = false
    while GetGameTimer() < hasta do
        Wait(200)
        if #(GetEntityCoords(yo) - inicio) > 3.0 or IsPedRagdoll(yo) then cortado = true break end
        -- Rebuscando pegado al coche se empuja el porton: que siga abierto.
        if p.coche and cocheParado and DoesEntityExist(cocheParado) and GetVehicleDoorAngleRatio(cocheParado, 5) < 0.8 then
            SetVehicleDoorOpen(cocheParado, 5, false, false)
        end
        -- Al cerrarse el minijuego se limpian las tareas del personaje: la
        -- animacion se cortaba y rebuscaba de pie. Se vuelve a poner.
        if p.anim and not IsEntityPlayingAnim(yo, p.anim[1], p.anim[2], 3) then
            TaskPlayAnim(yo, p.anim[1], p.anim[2], 4.0, -4.0, -1, 1, 0.0, false, false, false)
        end
    end
    pcall(function() exports.origen_hud:HideProgress() end)
    ClearPedTasks(yo)
    if cortado and p.coche and cocheParado and DoesEntityExist(cocheParado) then SetVehicleDoorShut(cocheParado, 5, false) end
    if not cortado then
        if Cumplir() then
            if p.pista then exports.origen_notify:Notify({ title = 'Pista', description = p.pista, type = 'info', duration = 15000 }) end
        elseif p.ventana and not (estado and estado.ventana and estado.ventana.nombre == p.ventana) then
            -- Se acabo el tiempo mientras se abria: que se sepa por que no vale.
            Aviso(p.sinVentana or 'Se ha acabado el tiempo.', 'error')
        end
    end
    investigando = false
end

-- ---------------------------------------------------------------------------
--  Los papeles (pistas), la llamada, la linterna y el coche aparcado
-- ---------------------------------------------------------------------------

--[[ Leer un papel: la pantalla lo pinta segun su tipo (nota a mano, informe a
     maquina, cartera, objeto). Coge el raton para poder cerrarlo; si la Lista
     Negra ya esta abierta, se pinta encima y no se toca el foco. ]]
local function Leer(id, nueva)
    local P = Config.Pistas[id]
    if not P then return end
    if nueva then PlaySoundFrontend(-1, 'PICK_UP', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true) end
    SendNUIMessage({ a = 'documento', id = id, pista = P, nueva = nueva })
    if not panel then
        leyendo = true
        HudFuera(true)
        SetNuiFocus(true, true)
    end
end

--[[ La camara de la policia acaba de hacer una foto (evento local de
     origen_police). Si el paso es una foto, se mira aqui si lo que hay que
     fotografiar se ve (nada en medio) y se manda al servidor, que rehace la
     cuenta del encuadre. ]]
AddEventHandler('origen_police:camara:foto', function(cam, rot, fov)
    local p = Paso()
    if not estado or not p or p.tipo ~= 'foto' then return end
    local que = (p.cuerpo and cuerpo) or vector3(p.x, p.y, p.z)
    local h = StartExpensiveSynchronousShapeTestLosProbe(cam.x, cam.y, cam.z, que.x, que.y, que.z + 0.3, 1 + 16, PlayerPedId(), 0)
    local _, choca = GetShapeTestResult(h)
    if choca == 1 then
        Aviso('Hay algo en medio: no se ve en la foto.', 'error')
        return
    end
    CreateThread(function()
        local r = lib.callback.await('origen_mision:foto', false, estado.paso,
            { x = cam.x, y = cam.y, z = cam.z }, { x = rot.x, y = rot.y, z = rot.z }, fov)
        if r and r.ok then
            Aviso('Foto hecha. Bastida tendrá su prueba.', 'success')
        else
            Aviso(r and r.motivo or 'No vale: tiene que verse bien en la foto.', 'error')
        end
    end)
end)

RegisterNetEvent('origen_mision:cl:pista', function(id)
    -- Hablando, o con otro papel delante, espera su turno: se enseñan de uno en uno.
    if charlando or leyendo then colaPapeles[#colaPapeles + 1] = id return end
    Leer(id, true)
end)
AddEventHandler('origen_mision:cl:siguientePapel', function()
    if charlando or leyendo or #colaPapeles == 0 then return end
    Leer(table.remove(colaPapeles, 1), true)
end)
RegisterNetEvent('origen_mision:cl:leer', function(id) Leer(id, false) end)

RegisterNUICallback('cerrarDoc', function(_, cb)
    cb(true)
    -- El siguiente papel de la cola, sin soltar el raton entre uno y otro.
    if leyendo and #colaPapeles > 0 then
        Leer(table.remove(colaPapeles, 1), true)
        return
    end
    if leyendo then
        leyendo = false
        SetNuiFocus(false, false)
        HudFuera(false)
    end
end)

RegisterNUICallback('leerPista', function(d, cb)
    cb(true)
    if d and TengoPista(d.id) then Leer(d.id, false) end
end)

--[[ La llamada: tarjeta y subtitulos en la pantalla, linea a linea, sin
     quitar el control (se puede ir conduciendo). Al acabar, el paso. ]]
local llamando = false

--[[ Nadie llama a quien esta en un tiroteo: la llamada espera a que no haya
     nadie peleando con el jugador cerca y a que lleve 10 s sin recibir ni
     disparar. Con el movil en la oreja no se puede defender. ]]
local sustoEn = 0
local function Tranquilo()
    local yo = PlayerPedId()
    --[[ Solo cuenta el daño que hace OTRO (un tiro, un golpe): con hambre o
         sed la vida baja sola y la llamada no llegaba nunca. ]]
    if HasEntityBeenDamagedByAnyPed(yo) or HasEntityBeenDamagedByAnyVehicle(yo) then
        sustoEn = GetGameTimer()
        ClearEntityLastDamageEntity(yo)
    end
    if IsPedShooting(yo) then sustoEn = GetGameTimer() end
    if GetGameTimer() - sustoEn < 10000 then return false end
    local c = GetEntityCoords(yo)
    for _, q in ipairs(GetGamePool('CPed')) do
        if q ~= yo and not IsPedAPlayer(q) and not IsPedDeadOrDying(q, true) and IsPedInCombat(q, yo)
            and #(GetEntityCoords(q) - c) < 120.0 then
            return false
        end
    end
    return true
end

local function Llamar(p)
    if llamando then return end
    llamando = true
    CreateThread(function()
        local pasoLlamada = estado and estado.paso
        if not Tranquilo() then
            Aviso(p.escucha and 'El micro está emitiendo. Lo escucharás cuando estés a salvo.'
                or 'Bastida te está llamando. Lo cogerás cuando estés a salvo.', 'info')
            while estado and not Tranquilo() do Wait(1000) end
            -- Mientras tanto la ha cerrado el compañero: ya no suena.
            if not estado or estado.paso ~= pasoLlamada then llamando = false return end
        end
        --[[ El tono de GTA se repite solo hasta que se para: dos tonos, se
             corta y suena descolgar. Sin el StopSound sonaba toda la llamada. ]]
        if p.escucha then
            -- La escucha del micro: un chasquido de radio y a oir.
            PlaySoundFrontend(-1, 'Start_Squelch', 'CB_RADIO_SFX', true)
        else
            local tono = GetSoundId()
            PlaySoundFrontend(tono, 'Remote_Ring', 'Phone_SoundSet_Michael', true)
            Wait(2600)
            StopSound(tono)
            ReleaseSoundId(tono)
            PlaySoundFrontend(-1, 'Pick_Up', 'Phone_SoundSet_Michael', true)
        end
        -- El movil a la oreja: solo la parte de arriba del cuerpo (se puede andar y conducir).
        local yo = PlayerPedId()
        -- El arma (o la linterna) y lo que lleve en la mano, guardados mientras habla.
        local arma = GetSelectedPedWeapon(yo)
        if arma ~= joaat('WEAPON_UNARMED') then SetCurrentPedWeapon(yo, joaat('WEAPON_UNARMED'), true) end
        SoltarMano()
        local dict = IsPedInAnyVehicle(yo, false) and 'cellphone@in_car@ds' or 'cellphone@'
        local movil = nil
        -- La escucha del micro tambien: el micro emite al movil.
        if pcall(lib.requestAnimDict, dict, 3000) then
            TaskPlayAnim(yo, dict, 'cellphone_call_listen_base', 3.0, -3.0, -1, 49, 0.0, false, false, false)
            local hm = Cargar('prop_npc_phone_02')
            if hm then
                movil = CreateObject(hm, 0.0, 0.0, 0.0, true, true, false)
                SetModelAsNoLongerNeeded(hm)
                AttachEntityToEntity(movil, yo, GetPedBoneIndex(yo, 28422), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
            end
        end
        Wait(400)
        -- Cada linea con su voz (si la tiene) y el tiempo que dure la voz.
        local lineas = {}
        for _, l in ipairs(p.lineas or {}) do
            local voz, seg = Voz(l.dice)
            lineas[#lineas + 1] = { quien = l.quien, dice = l.dice, voz = voz,
                t = math.max(l.t or 4, seg and math.ceil(seg + 0.6) or 0) }
        end
        SendNUIMessage({ a = 'llamada', nombre = p.nombre, lineas = lineas, etiqueta = p.escucha and 'Escucha' or 'Llamada' })
        local dura = 0
        for _, l in ipairs(lineas) do dura = dura + l.t end
        local hasta = GetGameTimer() + dura * 1000 + 500
        while GetGameTimer() < hasta do
            -- Si se sube o se baja de un coche a media llamada, se vuelve a poner (con el de dentro o fuera).
            local ahora = IsPedInAnyVehicle(yo, false) and 'cellphone@in_car@ds' or 'cellphone@'
            if ahora ~= dict then
                StopAnimTask(yo, dict, 'cellphone_call_listen_base', 2.0)
                dict = ahora
                pcall(lib.requestAnimDict, dict, 3000)
            end
            if not IsEntityPlayingAnim(yo, dict, 'cellphone_call_listen_base', 3) and not IsPedRagdoll(yo) then
                TaskPlayAnim(yo, dict, 'cellphone_call_listen_base', 3.0, -3.0, -1, 49, 0.0, false, false, false)
            end
            Wait(500)
        end
        SendNUIMessage({ a = 'llamada' })
        PlaySoundFrontend(-1, 'Hang_Up', 'Phone_SoundSet_Michael', true)
        StopAnimTask(yo, dict, 'cellphone_call_listen_base', 2.0)
        if movil and DoesEntityExist(movil) then DeleteEntity(movil) end
        if arma ~= joaat('WEAPON_UNARMED') and HasPedGotWeapon(yo, arma, false) then SetCurrentPedWeapon(yo, arma, true) end
        for _ = 1, 10 do
            if Cumplir() or not estado then break end
            Wait(1000)
        end
        llamando = false
    end)
end

--[[ La linterna: la de mano, o la que va montada en el arma (las pistolas de
     policia la llevan), apuntando. Lo que cae en el cono de la camara se
     revela, como las evidencias de origen_police. ]]
local LINTERNAS_ARMA = { joaat('COMPONENT_AT_PI_FLSH'), joaat('COMPONENT_AT_PI_FLSH_02'), joaat('COMPONENT_AT_PI_FLSH_03'), joaat('COMPONENT_AT_AR_FLSH') }
local function Alumbrando(yo)
    local arma = GetSelectedPedWeapon(yo)
    if arma == joaat('WEAPON_UNARMED') then return false end
    local con = arma == joaat('WEAPON_FLASHLIGHT')
    if not con then
        for _, c in ipairs(LINTERNAS_ARMA) do
            if HasPedGotWeaponComponent(yo, arma, c) then con = true break end
        end
    end
    return con and (IsPlayerFreeAiming(PlayerId()) or GetPedConfigFlag(yo, 78, true))
end

local revelados = {}       -- [punto] = true: visto con la linterna en este paso
local examinando = false

--[[ Los rastros son cosas de verdad en el suelo: objetos (`props`: casquillos,
     un cargador, la cartera) y manchas (`sangre`). Locales: solo los ve quien
     investiga. Se ven siempre; la linterna hace falta para examinarlos. ]]
local rastrosPuestos = nil   -- { objetos = {}, manchas = {} }
--[[ Al pasar al paso siguiente, lo de este (el cuerpo, el zapato, los conos,
     la sangre) se queda donde esta: desaparecer delante del jugador no tiene
     sentido. Se borra al alejarse 200 m o al acabar el trabajo. ]]
local rastrosDejados = {}
local function BorrarRastros(r)
    for _, o in ipairs(r.objetos) do if DoesEntityExist(o) then DeleteEntity(o) end end
    for _, c in ipairs(r.cuerpos or {}) do if DoesEntityExist(c) then DeleteEntity(c) end end
    for _, d in ipairs(r.manchas) do RemoveDecal(d) end
end
--[[ `decorado` (cualquier paso) = { { modelo, x, y, z, h } }: vehiculos
     aparcados que cuentan la historia (la avioneta que espera a Medrano).
     Locales, se ponen al acercarse y se quitan a 300 m o al acabar. ]]
local decorados = {}   -- { clave, centro, ents }
QuitarDecorados = function(pos)
    for i = #decorados, 1, -1 do
        local d = decorados[i]
        if not pos or #(pos - d.centro) > 300.0 then
            for _, e in ipairs(d.ents) do if DoesEntityExist(e) then DeleteEntity(e) end end
            table.remove(decorados, i)
        end
    end
end
local function PonerDecorado(clave, p)
    for _, d in ipairs(decorados) do if d.clave == clave then return end end
    local d = { clave = clave, centro = vector3(p.x, p.y, p.z), ents = {} }
    decorados[#decorados + 1] = d
    for _, v in ipairs(p.decorado) do
        local hash = Cargar(v[1])
        if hash and IsModelAVehicle(hash) then
            local veh = CreateVehicle(hash, v[2], v[3], v[4] + 0.5, (v[5] or 0.0) + 0.0, false, false)
            SetModelAsNoLongerNeeded(hash)
            SetVehicleOnGroundProperly(veh)
            SetVehicleDoorsLocked(veh, 2)
            FreezeEntityPosition(veh, true)
            d.ents[#d.ents + 1] = veh
        elseif hash then
            -- Un objeto (la caja fuerte junto a la caseta), en el suelo de verdad.
            local o = CreateObject(hash, v[2], v[3], Suelo(v[2], v[3], v[4]), false, false, false)
            SetModelAsNoLongerNeeded(hash)
            SetEntityHeading(o, (v[5] or 0.0) + 0.0)
            PlaceObjectOnGroundProperly(o)
            FreezeEntityPosition(o, true)
            d.ents[#d.ents + 1] = o
        end
    end
end

local function LimpiarRastrosDejados(pos)
    for i = #rastrosDejados, 1, -1 do
        if #(pos - rastrosDejados[i].centro) > 200.0 then
            BorrarRastros(rastrosDejados[i])
            table.remove(rastrosDejados, i)
        end
    end
end
QuitarRastros = function(dejar)
    if dejar then
        if rastrosPuestos then rastrosDejados[#rastrosDejados + 1] = rastrosPuestos end
        rastrosPuestos = nil
        return
    end
    if rastrosPuestos then BorrarRastros(rastrosPuestos) end
    for _, r in ipairs(rastrosDejados) do BorrarRastros(r) end
    rastrosPuestos, rastrosDejados = nil, {}
end
--- Modelos que el juego deja de pie y tienen que ir tumbados en el suelo.
local TUMBADOS = { [joaat('w_pi_singleshot_shell')] = true, [joaat('w_pi_pistol_mag1')] = true, [joaat('p_bloodsplat_s')] = true }
local function Tumbar(o, h)
    local c = GetEntityCoords(o)
    -- -90: la cara buena hacia arriba (a 90 queda boca abajo y no se ve).
    SetEntityRotation(o, -90.0, 0.0, h + 0.0, 2, true)
    SetEntityCoordsNoOffset(o, c.x, c.y, Suelo(c.x, c.y, c.z) + 0.02, false, false, false)
end

local function PonerRastros(p)
    rastrosPuestos = { objetos = {}, manchas = {}, porPunto = {}, cuerpos = {}, centro = vector3(p.x, p.y, p.z) }
    for i, punto in ipairs(p.puntos) do
        rastrosPuestos.porPunto[i] = {}
        --[[ `cuerpo = { modelo, h }`: alguien muerto en el suelo (local: solo
             lo ve quien investiga). Se le deja caer y se congela ya tumbado. ]]
        if punto.cuerpo then
            local hash = Cargar(punto.cuerpo[1])
            if hash then
                local zc = Suelo(punto.x, punto.y, punto.z)
                local ped = CreatePed(4, hash, punto.x, punto.y, zc + 0.3, (punto.cuerpo.h or 0.0) + 0.0, false, false)
                SetModelAsNoLongerNeeded(hash)
                SetBlockingOfNonTemporaryEvents(ped, true)
                SetEntityHealth(ped, 0)
                rastrosPuestos.cuerpos[#rastrosPuestos.cuerpos + 1] = ped
                SetTimeout(2500, function()
                    if DoesEntityExist(ped) then FreezeEntityPosition(ped, true) end
                end)
            end
        end
        local z = Suelo(punto.x, punto.y, punto.z)
        for _, pr in ipairs(punto.props or {}) do
            local hash = Cargar(pr[1])
            if hash then
                local x, y = punto.x + (pr[2] or 0.0), punto.y + (pr[3] or 0.0)
                local o = CreateObject(hash, x, y, Suelo(x, y, punto.z), false, false, false)
                SetModelAsNoLongerNeeded(hash)
                local h = (pr[4] or math.random(0, 359)) + 0.0
                SetEntityHeading(o, h)
                PlaceObjectOnGroundProperly(o)
                if TUMBADOS[hash] then Tumbar(o, h) end
                FreezeEntityPosition(o, true)
                -- `ocultos`: no se ve hasta que le da la linterna (ver el rastreo).
                if p.ocultos then SetEntityVisible(o, false, false) end
                rastrosPuestos.objetos[#rastrosPuestos.objetos + 1] = o
                rastrosPuestos.porPunto[i][#rastrosPuestos.porPunto[i] + 1] = o
            end
        end
        if punto.sangre then
            --[[ Charcos de sangre de verdad (objeto), en reguero: las manchas
                 pintadas (decal) apenas se ven en el asfalto de dia. ]]
            local hs = Cargar('p_bloodsplat_s')
            if hs then
                for k = 0, 2 do
                    local bx, by = punto.x + k * 0.55, punto.y + k * 0.35
                    local o = CreateObject(hs, bx, by, Suelo(bx, by, punto.z), false, false, false)
                    Tumbar(o, math.random(0, 359))
                    FreezeEntityPosition(o, true)
                    rastrosPuestos.objetos[#rastrosPuestos.objetos + 1] = o
                end
                SetModelAsNoLongerNeeded(hs)
            end
            -- 1010: salpicadura de sangre. Dos, una mayor y otra al lado.
            for k, tam in ipairs({ 0.9, 0.5 }) do
                local d = AddDecal(1010, punto.x + (k - 1) * 0.7, punto.y + (k - 1) * 0.4, z + 0.2, 0.0, 0.0, -1.0, 0.0, 1.0, 0.0,
                    tam, tam, 0.3, 0.0, 0.0, 1.0, -1.0, true, false, false)
                rastrosPuestos.manchas[#rastrosPuestos.manchas + 1] = d
            end
        end
    end
end

local function EnElHaz(c)
    local cam = GetFinalRenderedCamCoord()
    local rot = GetFinalRenderedCamRot(2)
    local rx, rz = math.rad(rot.x), math.rad(rot.z)
    local dir = vector3(-math.sin(rz) * math.cos(rx), math.cos(rz) * math.cos(rx), math.sin(rx))
    local v = c - cam
    local d = #v
    return d < 16.0 and (v.x * dir.x + v.y * dir.y + v.z * dir.z) / d > 0.91   -- ~24 grados
end

local function Examinar(i, punto)
    if examinando or leyendo then return end
    examinando = true
    CreateThread(function()
        local yo = PlayerPedId()
        TaskTurnPedToFaceCoord(yo, punto.x, punto.y, punto.z, 600)
        Wait(600)
        --[[ Agachado mirando el suelo. Con animacion y no con el escenario
             CODE_HUMAN_MEDIC_KNEEL: el escenario no arranca con la linterna
             (o cualquier arma) en la mano y se quedaba de pie. ]]
        local agachar = { 'amb@medic@standing@kneel@base', 'base' }
        if pcall(lib.requestAnimDict, agachar[1], 3000) then
            TaskPlayAnim(yo, agachar[1], agachar[2], 4.0, -4.0, -1, 1, 0.0, false, false, false)
        end
        pcall(function() exports.origen_hud:ShowProgress(3500, 'Examinando: ' .. (punto.nombre or 'rastro')) end)
        Wait(3600)
        local objs = rastrosPuestos and rastrosPuestos.porPunto[i] or {}
        local r = lib.callback.await('origen_mision:examinar', false, estado and estado.paso, i)
        -- Lo que hay tirado (cartera, cargador, casquillos, zapato) se recoge
        -- como prueba: se coge del suelo y desaparece. La sangre y el cuerpo, no.
        local hayObjetos = #objs > 0
        if r and r.ok and hayObjetos and pcall(lib.requestAnimDict, 'pickup_object', 3000) then
            TaskPlayAnim(yo, 'pickup_object', 'pickup_low', 8.0, -8.0, 1200, 0, 0.0, false, false, false)
            Wait(700)
            for _, o in ipairs(objs) do
                if DoesEntityExist(o) then DeleteEntity(o) end
            end
            Wait(500)
        end
        ClearPedTasks(yo)
        if r and r.ok and punto.pista then
            exports.origen_notify:Notify({ title = punto.nombre or 'Rastro', description = punto.pista, type = 'info', duration = 12000 })
        end
        examinando = false
    end)
end

--- El coche aparcado del paso (local: solo para registrarlo).
QuitarCocheParado = function()
    if cocheParado and DoesEntityExist(cocheParado) then DeleteEntity(cocheParado) end
    cocheParado = nil
end
local function PonerCocheParado(p)
    local hash = Cargar(p.coche.modelo)
    if not hash then return end
    -- `dx`/`dy`: aparcado a un lado del sitio (la autocaravana junto a quien vive en ella).
    local x, y = p.x + (p.coche.dx or 0.0), p.y + (p.coche.dy or 0.0)
    local z = Suelo(x, y, p.z)
    local v = CreateVehicle(hash, x, y, z + 0.4, (p.coche.h or 0.0) + 0.0, false, false)
    SetModelAsNoLongerNeeded(hash)
    SetVehicleOnGroundProperly(v)
    SetVehicleDoorsLocked(v, 2)
    if p.coche.matricula then SetVehicleNumberPlateText(v, p.coche.matricula) end
    SetEntityInvincible(v, true)
    SetVehicleHandbrake(v, true)
    cocheParado = v
end

--[[ Emboscadas: un coche con gente armada que llega a por el jugador cuando
     se acerca al sitio de un paso (`emboscada` en la config). Van en un
     grupo propio que odia al jugador desde el principio. No hace falta
     matarlos para seguir, pero no se van. ]]
local emboscadaHecha = {}  -- [mision:paso] = true
local GRUPO_EMB = nil

local function Emboscada(paso, r, centro)
    local clave = estado.mision .. ':' .. paso
    if emboscadaHecha[clave] then return end
    emboscadaHecha[clave] = true
    CreateThread(function()
        if not GRUPO_EMB then
            local _, g = AddRelationshipGroup('OM_EMBOSCADA')
            GRUPO_EMB = g
        end
        SetRelationshipBetweenGroups(5, GRUPO_EMB, joaat('PLAYER'))
        SetRelationshipBetweenGroups(5, joaat('PLAYER'), GRUPO_EMB)
        local hv, hp = Cargar(r.vehiculo), Cargar(ModeloN(r.modelo, 1))
        if not hv or not hp then return end
        local ang = math.random() * math.pi * 2
        local nodo, rumbo = Nodo(centro.x + math.cos(ang) * (r.desde or 110.0), centro.y + math.sin(ang) * (r.desde or 110.0), centro.z)
        local veh = CreateVehicle(hv, nodo.x, nodo.y, nodo.z + 0.5, rumbo, true, true)
        SetModelAsNoLongerNeeded(hv)
        if not veh or veh == 0 then return end
        SetEntityAsMissionEntity(veh, true, true)
        SetVehicleOnGroundProperly(veh)
        local gente, nets = {}, {}
        for i = 1, math.min(r.n, GetVehicleModelNumberOfSeats(hv)) do
            local q = CreatePedInsideVehicle(veh, 4, Cargar(ModeloN(r.modelo, i)) or hp, i - 2, true, true)
            Armar(q, r)
            SetPedRelationshipGroupHash(q, GRUPO_EMB)
            SetBlockingOfNonTemporaryEvents(q, false)
            gente[#gente + 1] = q
            nets[#nets + 1] = NetDe(q)
        end
        SetModelAsNoLongerNeeded(hp)
        lib.callback.await('origen_mision:emboscada', false, paso, { peds = nets, veh = NetDe(veh) })
        if r.aviso then Aviso(r.aviso, 'error') end
        local yo = PlayerPedId()
        if gente[1] then
            local c = GetEntityCoords(yo)
            TaskVehicleDriveToCoordLongrange(gente[1], veh, c.x, c.y, c.z, 35.0, 786468, 15.0)
        end
        local hasta = GetGameTimer() + 45000
        while GetGameTimer() < hasta and DoesEntityExist(veh) do
            Wait(500)
            if #(GetEntityCoords(veh) - GetEntityCoords(yo)) < 25.0 then break end
        end
        for _, q in ipairs(gente) do
            if DoesEntityExist(q) and not IsPedDeadOrDying(q, true) then
                TaskLeaveVehicle(q, veh, 256)
                TaskCombatPed(q, yo, 0, 16)
            end
        end
        Acosar(gente)
    end)
end


--- Lo pide el bucle; al final de la vuelta se pone el ultimo que se pidio.
local function Pedir(clave, texto)
    deseo = { clave, texto }
end

--[[ El rastreador es el de origen_quests (04/10/2026): el encargo sale como
     una mision mas, en la misma caja que las otras y en la pestaña Misiones
     del inventario. Antes esta pantalla tenia su propia pegatina y salian dos
     cajas una encima de otra.

     Cada paso es un objetivo: el de matar con su contador, los demas con su
     punto. El que toca lleva debajo el tiempo que queda. Solo se manda cuando
     algo cambia (el contador, el paso o el minuto). ]]
local ID_QUESTS = 'origen_mision'
local ultimoEnvio = nil

local function Quests()
    return GetResourceState('origen_quests') == 'started'
end

local function Rastreador()
    local p, m = Paso()
    if not p then
        if ultimoEnvio and Quests() then pcall(function() exports.origen_quests:MisionExterna(ID_QUESTS, nil) end) end
        ultimoEnvio = nil
        return
    end
    local quedan = math.max(0, math.floor((limite - GetGameTimer()) / 1000))
    local objetivos = {}
    for i, x in ipairs(m.pasos) do
        local etiqueta = x.texto
        if x.tipo == 'doble' then
            local mia = (i == estado.paso) and Paso() or (x.partes[estado.papel or 'habla'] or x.partes.sombra or x.partes.habla)
            etiqueta = mia and mia.texto or x.texto
            -- Lo de abajo (contador, sospecha) es de lo que hace cada uno.
            if mia and mia.tipo ~= 'esperar' then x = mia end
        end
        local o = { idx = i, type = 'goto', label = etiqueta, complete = i < estado.paso }
        if x.tipo == 'matar' then
            local n = x.enemigos.n + (x.enemigos.jefe and 1 or 0)
            o.type, o.amount, o.done = 'kill', n, (i < estado.paso) and n or 0
            if i == estado.paso and #ents.peds > 0 then
                for _, e in ipairs(ents.peds) do
                    if not DoesEntityExist(e) or IsPedDeadOrDying(e, true) then o.done = o.done + 1 end
                end
            end
        end
        if i == estado.paso then
            local tiempo = quedan >= 60 and ('Quedan %d min'):format(math.ceil(quedan / 60)) or ('Quedan %d s'):format(quedan)
            o.donde = tiempo
            if x.tipo == 'asesinar' and obj then
                if obj.alarma then
                    o.donde = '¡Alarma! Que no escape · ' .. tiempo
                elseif obj.avisado then
                    o.donde = ('Te esperan · sospecha %d %% · %s'):format(math.floor(obj.sospecha / 10) * 10, tiempo)
                else
                    o.donde = ('Sospecha %d %% · %s'):format(math.floor(obj.sospecha / 10) * 10, tiempo)
                end
            elseif x.tipo == 'llamada' then
                o.donde = 'Llamada en curso · ' .. tiempo
            elseif x.tipo == 'rastrear' then
                local n = 0
                for _ in pairs(estado.examinados or {}) do n = n + 1 end
                o.type, o.amount, o.done = 'kill', #x.puntos, n
                o.donde = 'Saca la linterna y apunta · ' .. tiempo
            elseif x.tipo == 'alejarse' then
                local d = #(GetEntityCoords(PlayerPedId()) - vector3(x.x, x.y, x.z))
                o.donde = ('Te faltan %d m · %s'):format(math.max(0, math.ceil((x.radio - d) / 10) * 10), tiempo)
            elseif x.tipo == 'interceptar' and obj and DoesEntityExist(obj.ped) then
                local d = #(GetEntityCoords(obj.ped) - vector3(x.destino.x, x.destino.y, x.destino.z))
                o.donde = ('A %s m de %s · %s'):format(math.floor(d / 50) * 50, x.destino.nombre or 'su destino', tiempo)
            end
        end
        objetivos[i] = o
    end
    local datos = {
        name = m.titulo,
        location_name = ('Lista Negra · Nivel %d'):format(m.nivel),
        objectives = objetivos,
    }
    local envio = json.encode(datos)
    if envio == ultimoEnvio or not Quests() then return end
    ultimoEnvio = envio
    pcall(function() exports.origen_quests:MisionExterna(ID_QUESTS, datos) end)
end

--- Abandonarlo desde la pestaña Misiones del inventario.
AddEventHandler('origen_quests:externa:abandonar', function(id)
    if id ~= ID_QUESTS or not estado then return end
    lib.callback.await('origen_mision:abandonar', false)
end)

--- Si origen_quests se reinicia, pierde la lista: se le vuelve a mandar.
AddEventHandler('onClientResourceStart', function(recurso)
    if recurso == 'origen_quests' then ultimoEnvio = nil end
end)

--- Monta lo del paso nuevo. Se llama cada vez que cambia el paso.

local function MontarPaso()
    local p = Paso()
    if obj and obj.ped and DoesEntityExist(obj.ped) then cuerpo = GetEntityCoords(obj.ped) end
    -- En grupo, quien no puso al objetivo sabe donde cayo por el servidor.
    if estado and estado.cuerpo then cuerpo = vector3(estado.cuerpo.x, estado.cuerpo.y, estado.cuerpo.z) end
    QuitarPuntos()
    apuntado = false
    if ents.prop and DoesEntityExist(ents.prop) then DeleteEntity(ents.prop) end
    ents.prop = nil
    -- Los enemigos del paso anterior se quedan donde cayeron, pero ya no se siguen.
    ents.peds = {}
    QuitarObjetivo(false)
    QuitarTestigo(true)
    QuitarRastros(true)
    if CerrarMiraYa then CerrarMiraYa() end
    -- Un paso con coche propio: el del paso anterior ya no pinta nada ahi.
    if p and p.coche then QuitarCocheParado() end
    revelados = {}
    atacando = {}
    if not p then return end
    -- En la entrega el coche es el del paso anterior: no se suelta. En
    -- cualquier otro paso ya no es asunto del encargo (lo borra el servidor).
    if p.tipo ~= 'entregar' then
        ents.veh = nil
    elseif ents.veh then
        OrigenMapa.Poner('coche', { entidad = ents.veh, cat = 'misiones', nombre = 'El coche', color = '#ff0a5c' })
    end
    PonerObjetivo(p, ((p.tipo == 'recoger' or p.tipo == 'foto') and p.cuerpo and cuerpo) and cuerpo or nil)
    if p.tipo == 'foto' then
        Aviso('Saca la cámara (instant_camera del inventario) y haz la foto. Bastida quiere verlo.', 'info')
    end
    --[[ Si en este paso hay emboscada, Bastida avisa por mensaje al empezarlo:
         da tiempo a prepararse por el camino (`emboscada.previo`). ]]
    if p.emboscada then
        local clave = estado.mision .. ':' .. estado.paso
        SetTimeout(3500, function()
            if not estado or emboscadaHecha[clave] or estado.mision .. ':' .. estado.paso ~= clave then return end
            PlaySoundFrontend(-1, 'Text_Arrive_Tone', 'Phone_SoundSet_Default', true)
            exports.origen_notify:Notify({ title = 'Mensaje de Bastida', type = 'error', duration = 12000,
                description = p.emboscada.previo or 'Ojo: hay gente armada moviéndose por donde vas. Ve preparado.' })
        end)
    end
end

RegisterNetEvent('origen_mision:cl:estado', function(e)
    local antes = estado
    estado = e
    fallado = false
    if not e then
        BorrarTodo()
        emboscadaHecha = {}
        cuerpo = nil
        pasoPuesto = nil
        Texto(nil)
        Rastreador()
        return
    end
    limite = GetGameTimer() + (e.quedan or 0) * 1000
    if e.ventana then e.ventana.total = e.ventana.quedan end
    local clave = e.mision .. ':' .. e.paso .. ':' .. (e.papel or '') .. ':' .. tostring(e.partes and e.partes[e.papel or ''] or false)
    if pasoPuesto ~= clave then
        if antes and antes.mision ~= e.mision then BorrarTodo() end
        pasoPuesto = clave
        MontarPaso()
        local p = Paso()
        if p then Aviso(p.texto, 'info') end
    end
    Rastreador()
end)

RegisterNetEvent('origen_mision:cl:hecho', function(d)
    PlaySoundFrontend(-1, 'CHECKPOINT_PERFECT', 'HUD_MINI_GAME_SOUNDSET', true)
    -- Por las notificaciones de la casa (origen_notify), no por el cartel de origen_quests.
    local extra = ''
    if (d.plus or 0) > 0 then extra = (' Limpio, sin tocar a su escolta: +%s $.'):format(lib.math.groupdigits(d.plus, '.')) end
    if d.pago > 0 then
        Aviso(('«%s» cerrado. %s $ en mano.%s'):format(d.titulo, lib.math.groupdigits(d.pago, '.'), extra), 'success')
    else
        Aviso(('«%s» cerrado.'):format(d.titulo), 'success')
    end
end)

-- ---------------------------------------------------------------------------
--  El bucle
-- ---------------------------------------------------------------------------

local function Cerca(a, b, metros)
    return #(a - vector3(b.x, b.y, b.z)) <= metros
end

local function DibujarCilindro(d, radio)
    -- Sobre el suelo de verdad: con la z de la config a ras de suelo, el
    -- circulo quedaba enterrado (no se veia el puesto del rifle).
    d.suelo = d.suelo or Suelo(d.x, d.y, d.z + 1.0)
    DrawMarker(1, d.x, d.y, d.suelo - 0.02, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, radio * 2.0, radio * 2.0, 1.2, 216, 27, 85, 110, false, false, 2, false, nil, nil, false)
end

--- Un paso: lo que se mira cada fotograma cerca y cada medio segundo lejos.
--- Devuelve cuanto esperar.
-- ---------------------------------------------------------------------------
--  Trabajos para dos: seguir, cubrir con la mira, guardias, apagon
-- ---------------------------------------------------------------------------

--- Las barras de la pantalla (sospecha, apagon): una por id.
local barras = {}
local function Barra(id, titulo, valor, texto)
    if valor == nil then
        if barras[id] then barras[id] = nil SendNUIMessage({ a = 'barra', id = id, quitar = true }) end
        return
    end
    local v = math.floor(math.max(0.0, math.min(1.0, valor)) * 100 + 0.5)
    local b = barras[id]
    if b and b.v == v and b.t == texto then return end
    barras[id] = { v = v, t = texto }
    SendNUIMessage({ a = 'barra', id = id, titulo = titulo, valor = v / 100, texto = texto })
end

--[[ Seguir: el coche sale de su sitio cuando el que sigue llega cerca y va a
     su destino conduciendo normal. Pegarse (menos de `cerca` m) sube la
     sospecha; a distancia, baja. A tope, te ha visto: se avisa al servidor
     (marca del paso) y el coche acelera. Lejos mucho rato: le has perdido. ]]
local seguido = nil   -- { veh, ped, sospecha, lejos, visto, arrancado }
local function QuitarSeguido(borrar)
    if seguido and borrar then
        for _, e in ipairs({ seguido.ped, seguido.veh }) do if e and DoesEntityExist(e) then DeleteEntity(e) end end
    end
    seguido = nil
    Barra('sospecha', nil)
    OrigenMapa.Quitar('seguido')
end
local function PonerSeguido(p)
    local hv, hp = Cargar(p.vehiculo), Cargar(p.conductor or 'g_m_y_salvagoon_01')
    if not hv or not hp then return false end
    local veh = CreateVehicle(hv, p.x, p.y, p.z + 0.5, (p.h or 0.0) + 0.0, true, true)
    SetModelAsNoLongerNeeded(hv)
    if not veh or veh == 0 then return false end
    SetEntityAsMissionEntity(veh, true, true)
    SetVehicleOnGroundProperly(veh)
    if p.matricula then SetVehicleNumberPlateText(veh, p.matricula) end
    if p.color then SetVehicleColours(veh, p.color, p.color) end
    local ped = CreatePedInsideVehicle(veh, 4, hp, -1, true, true)
    SetModelAsNoLongerNeeded(hp)
    SetEntityAsMissionEntity(ped, true, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetDriverAbility(ped, 1.0)
    local ok = lib.callback.await('origen_mision:apuntar', false, estado.paso, { veh = NetDe(veh) })
    if not ok then DeleteEntity(ped) DeleteEntity(veh) return false end
    seguido = { veh = veh, ped = ped, sospecha = 0.0, lejos = 0.0 }
    OrigenMapa.Poner('seguido', { entidad = veh, cat = 'misiones', nombre = p.nombre or 'A quien sigues', color = '#ff0a5c', pulso = true, prioridad = 10 })
    return true
end
local function LlevarSeguir(p, ped, pos, dt)
    if not seguido then
        if Cerca(pos, p, 150.0) and not PonerSeguido(p) then return 3000 end
        return 500
    end
    local veh = seguido.veh
    -- Sin furgoneta o sin conductor (antes de llegar) no hay a quien seguir: perdido.
    if not seguido.llegado and not seguido.perdido and (not DoesEntityExist(veh) or not DoesEntityExist(seguido.ped) or IsPedDeadOrDying(seguido.ped, true)) then
        seguido.perdido = true
        Barra('sospecha', nil)
        OrigenMapa.Quitar('seguido')
        TriggerServerEvent('origen_mision:fallo', 'perdido')
        return 1000
    end
    if not DoesEntityExist(veh) then return 500 end
    local vc = GetEntityCoords(veh)
    local d = #(pos - vc)
    if not seguido.arrancado and d < 90.0 then
        seguido.arrancado = true
        local de = p.destino
        TaskVehicleDriveToCoordLongrange(seguido.ped, veh, de.x, de.y, de.z, p.velocidad or 13.0, 786603, 8.0)
        Aviso(p.alSalir or 'Se pone en marcha. Síguele sin que te vea.', 'info')
        -- Ya no hay sitio al que ir: fuera la ruta y la chincheta del punto de
        -- salida. Solo queda la marca de la furgoneta, que va con ella por el mapa.
        rutaPendiente = nil
        OrigenMapa.Quitar('objetivo_ruta')
        OrigenMapa.Quitar('objetivo')
    end
    if not seguido.arrancado then return 0 end
    if seguido.perdido then return 1000 end
    --[[ La sospecha: pegado (menos de `cerca`) sube deprisa; a media distancia
         (hasta `media`) tambien, mas despacio; delante de el (le has
         adelantado) sube el doble. Solo baja guardando la distancia. ]]
    local muyCerca, media, lejos = p.cerca or 15.0, p.media or 35.0, p.lejos or 140.0
    local fw, rel = GetEntityForwardVector(veh), pos - vc
    local delante = d < 60.0 and (fw.x * rel.x + fw.y * rel.y) > 0.0
    if d < muyCerca then
        seguido.sospecha = seguido.sospecha + dt * 0.35
    elseif d < media then
        seguido.sospecha = seguido.sospecha + dt * 0.07
    elseif d < lejos then
        seguido.sospecha = math.max(0.0, seguido.sospecha - dt * 0.04)
    end
    if delante then seguido.sospecha = seguido.sospecha + dt * 0.25 end
    --[[ Lejos: cuenta atras. Pasado `perder` s lejos, o a mas de `pierde` m,
         le has perdido y el trabajo se cae (para todo el grupo). ]]
    local perder, pierde = p.perder or 15.0, p.pierde or 260.0
    if d > lejos then seguido.lejos = seguido.lejos + dt else seguido.lejos = 0.0; seguido.avisoLejos = nil end
    if seguido.lejos > 3.0 and not seguido.avisoLejos then
        seguido.avisoLejos = true
        Aviso('Le estás perdiendo. Acércate o se te escapa.', 'error')
    end
    if seguido.lejos > perder or d > pierde then
        seguido.perdido = true
        Barra('sospecha', nil)
        OrigenMapa.Quitar('seguido')
        TriggerServerEvent('origen_mision:fallo', 'perdido')
        return 1000
    end
    if seguido.sospecha >= 1.0 and not seguido.visto then
        seguido.visto = true
        TriggerServerEvent('origen_mision:visto')
        local de = p.destino
        TaskVehicleDriveToCoordLongrange(seguido.ped, veh, de.x, de.y, de.z, (p.velocidad or 13.0) * 1.8, 786468, 8.0)
    end
    local texto
    if seguido.lejos > 0.0 then
        texto = ('¡Le pierdes! %d s'):format(math.max(0, math.ceil(perder - seguido.lejos)))
    elseif seguido.visto then
        texto = 'Te ha visto'
    elseif delante then
        texto = 'Te tiene delante'
    elseif d < muyCerca then
        texto = 'Demasiado cerca'
    elseif d < media then
        texto = 'Muy pegado'
    else
        texto = 'Guarda la distancia'
    end
    Barra('sospecha', 'Sospecha', seguido.visto and 1.0 or math.min(1.0, seguido.sospecha), texto)
    -- Ha llegado: se baja y entra; el paso lo cierra el servidor.
    local de = p.destino
    if #(vc - vector3(de.x, de.y, de.z)) < (de.radio or 25.0) then
        if not seguido.llegado then
            seguido.llegado = true
            --[[ Aparca de verdad (antes se paraba en mitad de la calle y el
                 conductor se quedaba al lado sin hacer nada): se arrima al
                 bordillo, se baja y entra andando por la puerta (`puerta`). ]]
            local conductor, puerta = seguido.ped, de.puerta
            CreateThread(function()
                local hay, lado = GetPointOnRoadSide(vc.x, vc.y, vc.z, 1)
                if hay then
                    TaskVehiclePark(conductor, veh, lado.x, lado.y, lado.z, GetEntityHeading(veh), 0, 20.0, false)
                    local hasta = GetGameTimer() + 12000
                    while GetGameTimer() < hasta and DoesEntityExist(veh) and (#(GetEntityCoords(veh) - lado) > 3.0 or GetEntitySpeed(veh) > 0.5) do Wait(250) end
                end
                if not DoesEntityExist(conductor) then return end
                TaskLeaveVehicle(conductor, veh, 0)
                Wait(2000)
                SetVehicleEngineOn(veh, false, true, true)
                if puerta then
                    TaskGoStraightToCoord(conductor, puerta.x, puerta.y, puerta.z, 1.0, 25000, puerta.h or 0.0, 0.4)
                    local hasta = GetGameTimer() + 25000
                    while GetGameTimer() < hasta and DoesEntityExist(conductor) and #(GetEntityCoords(conductor) - vector3(puerta.x, puerta.y, puerta.z)) > 1.2 do Wait(250) end
                    -- Entra: se desvanece en la puerta.
                    for a = 255, 0, -51 do if DoesEntityExist(conductor) then SetEntityAlpha(conductor, a, false) end Wait(60) end
                    if DoesEntityExist(conductor) then DeleteEntity(conductor) end
                else
                    TaskWanderStandard(conductor, 10.0, 10)
                    SetPedKeepTask(conductor, true)
                end
                -- La furgoneta se queda aparcada (el servidor la mira para cerrar el
                -- paso y la recoge con los restos al acabar): soltarla la borraba.
            end)
        end
        Cumplir()
    end
    return 0
end

--[[ Cubrir: un puesto de tirador. Se monta con E y sale una mira propia (la
     camara del trabajo, no un arma del inventario): rueda = zoom, raton =
     apuntar, clic = disparar, clic derecho = marcar a alguien para el
     compañero, E o retroceso = levantarse. ]]
local mira = nil
local miraCerrada = 0   -- para que la E que la cierra no la vuelva a abrir al soltarla
--[[ Marcar a alguien (desde la mira, o lo que marca el compañero): una flecha
     roja encima y un punto en el minimapa que le sigue, un minuto. Para eso
     sirve: el que entra no ve lo que hay detras de cada contenedor; el del
     rifle, desde arriba, si. ]]
local marcados = {}   -- [ped] = hasta (GetGameTimer)
local function Marcar(e)
    marcados[e] = GetGameTimer() + 60000
    OrigenMapa.Poner('marcado_' .. tostring(e), { entidad = e, cat = 'illegal', nombre = 'Guardia marcado', color = '#ff4438', pulso = true, prioridad = 9 })
end
local function CerrarMira()
    if not mira then return end
    RenderScriptCams(false, true, 400, true, true)
    DestroyCam(mira.cam, false)
    ClearTimecycleModifier()
    SendNUIMessage({ a = 'mira', on = false })
    FreezeEntityPosition(PlayerPedId(), false)
    ClearPedTasks(PlayerPedId())
    mira = nil
    miraCerrada = GetGameTimer()
end
local function AbrirMira(p)
    local yo = PlayerPedId()
    local o = GetPedBoneCoords(yo, 31086, 0.0, 0.0, 0.0) + vector3(0.0, 0.0, 0.1)
    local cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamCoord(cam, o.x, o.y, o.z)
    local hacia = p.mira and vector3(p.mira.x, p.mira.y, p.mira.z) or (o + GetEntityForwardVector(yo) * 50.0)
    PointCamAtCoord(cam, hacia.x, hacia.y, hacia.z)
    Wait(0)
    local r = GetCamRot(cam, 2)
    StopCamPointing(cam)
    SetCamRot(cam, r.x, 0.0, r.z, 2)
    SetCamFov(cam, 30.0)
    RenderScriptCams(true, true, 500, true, true)
    SetTimecycleModifier('scanline_cam_cheap')
    SetTimecycleModifierStrength(0.4)
    FreezeEntityPosition(yo, true)
    TaskStartScenarioInPlace(yo, 'WORLD_HUMAN_BINOCULARS', 0, true)
    SendNUIMessage({ a = 'mira', on = true })
    mira = { cam = cam, fov = 30.0, ultimo = 0 }
end
local function LlevarMira()
    if not mira then return end
    local cam = mira.cam
    DisableAllControlActions(0)
    EnableControlAction(0, 249, true)   -- hablar por radio/voz
    local r = GetCamRot(cam, 2)
    local sens = mira.fov / 60.0
    local rx = math.max(-60.0, math.min(40.0, r.x - GetDisabledControlNormal(0, 2) * 8.0 * sens))
    local rz = r.z - GetDisabledControlNormal(0, 1) * 8.0 * sens
    SetCamRot(cam, rx, 0.0, rz, 2)
    if IsDisabledControlJustPressed(0, 241) then mira.fov = math.max(5.0, mira.fov - 4.0) end
    if IsDisabledControlJustPressed(0, 242) then mira.fov = math.min(50.0, mira.fov + 4.0) end
    SetCamFov(cam, mira.fov)
    -- Lo que hay en el centro de la mira.
    local o = GetCamCoord(cam)
    local pr, yr = math.rad(rx), math.rad(rz)
    local dir = vector3(-math.sin(yr) * math.cos(pr), math.cos(yr) * math.cos(pr), math.sin(pr))
    local fin = o + dir * 600.0
    local h = StartExpensiveSynchronousShapeTestLosProbe(o.x, o.y, o.z, fin.x, fin.y, fin.z, -1, PlayerPedId(), 0)
    local _, choca, donde, _, ent = GetShapeTestResult(h)
    local apunta = (choca == 1 and ent ~= 0 and IsEntityAPed(ent) and not IsPedAPlayer(ent)) and ent or nil
    SendNUIMessage({ a = 'mira', on = true, zoom = math.floor(60.0 / mira.fov * 10 + 0.5) / 10, blanco = apunta ~= nil })
    --[[ Son unos prismaticos: no se dispara. Clic izquierdo: marcar al que hay
         en el centro. Clic derecho: distraer, como tirar una piedra al punto
         del suelo que se mira (el guardia mas cercano va a ver que ha sido). ]]
    if IsDisabledControlJustPressed(0, 25) and choca == 1 then
        if GetGameTimer() < (mira.distraer or 0) then
            Aviso(('Espera %d s para volver a distraer.'):format(math.ceil((mira.distraer - GetGameTimer()) / 1000)), 'error')
        else
            mira.distraer = GetGameTimer() + 15000
            TriggerServerEvent('origen_mision:distraer', { x = donde.x, y = donde.y, z = donde.z })
            PlaySoundFrontend(-1, 'SELECT', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
        end
    end
    if IsDisabledControlJustPressed(0, 24) and apunta and NetworkGetEntityIsNetworked(apunta) then
        Marcar(apunta)
        TriggerServerEvent('origen_mision:marcar', NetworkGetNetworkIdFromEntity(apunta))
        PlaySoundFrontend(-1, 'SELECT', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
    end
    -- E o Retroceso. No el 177: tambien es el clic derecho, el de marcar.
    if IsDisabledControlJustPressed(0, 38) or IsDisabledControlJustPressed(0, 194) then CerrarMira() end
end
local function LlevarCubrir(p, ped, pos)
    if mira then LlevarMira() return 0 end
    --[[ `libre = { min, max }`: los prismaticos se sacan donde se quiera (un
         tejado, detras de algo) a esa distancia del objetivo (`mira`). Sin
         `libre`, en el puesto fijo de la config. ]]
    local centro = p.mira and vector3(p.mira.x, p.mira.y, p.mira.z) or vector3(p.x, p.y, p.z)
    local d = #(pos - centro)
    local vale
    if p.libre then
        vale = d >= (p.libre.min or 20.0) and d <= (p.libre.max or 120.0)
    else
        if Cerca(pos, p, 60.0) then DibujarCilindro(p, 0.8) end
        vale = Cerca(pos, p, 1.4)
    end
    if vale and not IsPedInAnyVehicle(ped, false) and GetEntitySpeed(ped) < 0.6 then
        Pedir('E', p.accion or 'Sacar los prismáticos')
        if IsControlJustReleased(0, 38) and GetGameTimer() - miraCerrada > 600 then AbrirMira(p) end
        return 0
    end
    return d < ((p.libre and p.libre.max or 0.0) + 60.0) and 0 or 500
end

--- Lo que marca el compañero desde la mira: una flecha roja encima, un minuto.
RegisterNetEvent('origen_mision:cl:marcado', function(net, quien)
    local e = NetworkGetEntityFromNetworkId(net)
    if e and e ~= 0 and DoesEntityExist(e) then
        Marcar(e)
        PlaySoundFrontend(-1, 'Beep_Red', 'DLC_HEIST_HACKING_SNAKE_SOUNDS', true)
        Aviso(('%s ha marcado a un guardia: lo tienes en el minimapa un minuto.'):format(quien or 'Tu compañero'), 'error')
    end
end)
local function DibujarMarcados()
    local ahora = GetGameTimer()
    for e, hasta in pairs(marcados) do
        if ahora > hasta or not DoesEntityExist(e) or IsPedDeadOrDying(e, true) then
            marcados[e] = nil
            OrigenMapa.Quitar('marcado_' .. tostring(e))
        else
            local c = GetEntityCoords(e)
            DrawMarker(0, c.x, c.y, c.z + 1.2, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.18, 0.18, 0.25, 230, 40, 40, 220, true, true, 2, false, nil, nil, false)
        end
    end
end

--[[ Guardias que patrullan (`guardias` en un paso o en una parte de un paso
     doble). Los pone el PRIMERO del grupo que llega (el servidor da paso a uno
     solo, para que no salgan repetidos) y a los demas les llegan sus netId
     (origen_mision:cl:guardias). La mitad patrulla el sitio y la otra mitad
     monta guardia quieta. No reaccionan solos: lo decide el medidor de
     Atencion, que cada uno lleva sobre SU personaje (ver SigiloGuardias). Si
     salta la alarma por uno, se entera todo el grupo y los guardias van a por
     el que han visto. ]]
local guardiasHechos = {}
local guardia = nil   -- { clave, peds (los mios) | nets (los de otro), r, atencion, alarma, gracia }

--- Los guardias del paso de ahora y su centro, sean de la parte que sean.
local function GuardiasDelPaso(p)
    if p and p.guardias then return p.guardias, vector3(p.x, p.y, p.z) end
    local m = estado and PorId[estado.mision]
    local e = m and m.pasos[estado.paso]
    for _, pp in pairs(e and e.partes or {}) do
        if pp.guardias then return pp.guardias, vector3(pp.x, pp.y, pp.z) end
    end
    return nil
end

--- Los guardias vivos o muertos que se ven desde aqui (los de otro, por netId).
local function PedsGuardia()
    if not guardia then return {} end
    if guardia.peds then return guardia.peds end
    local t = {}
    for _, net in ipairs(guardia.nets or {}) do
        if NetworkDoesNetworkIdExist(net) then
            local e = NetworkGetEntityFromNetworkId(net)
            if e and e ~= 0 and DoesEntityExist(e) then t[#t + 1] = e end
        end
    end
    return t
end

local function PonerGuardias(clave, r, centro)
    if guardiasHechos[clave] then return end
    guardiasHechos[clave] = true
    CreateThread(function()
        -- Si ya los ha puesto otro del grupo, el servidor manda sus netId.
        if not lib.callback.await('origen_mision:guardias:pedir', false, estado.paso) then return end
        if not GRUPO_EMB then
            local _, g = AddRelationshipGroup('OM_EMBOSCADA')
            GRUPO_EMB = g
        end
        SetRelationshipBetweenGroups(5, GRUPO_EMB, joaat('PLAYER'))
        SetRelationshipBetweenGroups(5, joaat('PLAYER'), GRUPO_EMB)
        local nets, gente = {}, {}
        for i = 1, r.n do
            local hp = Cargar(ModeloN(r.modelo, i))
            if hp then
                local ang = (i / r.n) * math.pi * 2
                local x, y, z = SitioPeaton(centro.x + math.cos(ang) * (r.radio or 10.0) * 0.6, centro.y + math.sin(ang) * (r.radio or 10.0) * 0.6, centro.z)
                local q = CreatePed(4, hp, x, y, z, math.deg(ang), true, true)
                SetModelAsNoLongerNeeded(hp)
                Armar(q, r)
                SetPedRelationshipGroupHash(q, GRUPO_EMB)
                SetPedSeeingRange(q, r.vista or 22.0)
                SetPedHearingRange(q, r.oido or 14.0)
                if i % 2 == 0 then
                    TaskWanderInArea(q, centro.x, centro.y, centro.z, r.radio or 10.0, 2.0, 3.0)
                else
                    -- De guardia, mirando hacia fuera del patio.
                    SetEntityHeading(q, math.deg(ang) - 90.0)
                    TaskStartScenarioInPlace(q, (i % 4 == 1) and 'WORLD_HUMAN_GUARD_STAND' or 'WORLD_HUMAN_SMOKING', 0, true)
                end
                gente[#gente + 1] = q
                nets[#nets + 1] = NetDe(q)
            end
        end
        guardia = { clave = clave, peds = gente, r = r, centro = centro, atencion = 0.0, alarma = false, gracia = GetGameTimer() + 5000 }
        lib.callback.await('origen_mision:emboscada', false, estado.paso, { peds = nets, guardias = true })
    end)
end

--- Los ha puesto otro del grupo: se siguen por netId.
RegisterNetEvent('origen_mision:cl:guardias', function(paso, nets)
    if not estado or estado.paso ~= paso or type(nets) ~= 'table' then return end
    local clave = estado.mision .. ':' .. paso
    if guardia and guardia.clave == clave then return end
    guardiasHechos[clave] = true
    guardia = { clave = clave, nets = nets, r = GuardiasDelPaso(nil) or {}, atencion = 0.0, alarma = false, gracia = GetGameTimer() + 5000 }
end)

local function QuitarGuardia()
    guardia = nil
    Barra('atencion', nil)
end

--- Se avisa al servidor; la alarma la monta el evento de vuelta, en todos.
local function AlarmaGuardias(porque)
    if not guardia or guardia.alarma then return end
    guardia.alarma, guardia.atencion = true, 100.0
    TriggerServerEvent('origen_mision:guardias:alarma', estado.paso, porque)
end

--[[ La alarma, para todo el grupo. Los guardias solo obedecen a quien los
     controla en red: cada uno da la orden a los suyos (los que tenga) contra
     el jugador al que han descubierto. ]]
RegisterNetEvent('origen_mision:cl:alarma', function(paso, quien, porque)
    if not guardia or not estado or estado.paso ~= paso then return end
    guardia.alarma, guardia.atencion = true, 100.0
    local soyYo = quien == GetPlayerServerId(PlayerId())
    local idx = GetPlayerFromServerId(quien)
    local objetivo = (idx ~= -1) and GetPlayerPed(idx) or PlayerPedId()
    for _, e in ipairs(PedsGuardia()) do
        if DoesEntityExist(e) and not IsPedDeadOrDying(e, true) and NetworkHasControlOfEntity(e) then
            SetBlockingOfNonTemporaryEvents(e, false)
            ClearPedTasks(e)
            TaskCombatPed(e, objetivo, 0, 16)
        end
    end
    PlaySoundFrontend(-1, 'Lose_1st', 'GTAO_FM_Events_Soundset', true)
    if soyYo then
        Aviso(porque == 'disparo' and '¡Han oído el disparo! Todo el patio va a por ti.'
            or porque == 'cuerpo' and '¡Han encontrado el cuerpo! Todo el patio va a por ti.'
            or '¡Te han descubierto! Todo el patio va a por ti.', 'error')
    else
        Aviso('¡Han descubierto a tu compañero! Todo el patio va a por él: cúbrele.', 'error')
    end
    Barra('atencion', 'Atención', 1.0, '¡Alarma!')
end)

--[[ El medidor de Atencion de los guardias (zona prohibida: que te vean ya es
     raro). Cada uno del grupo lleva el suyo, sobre su propio personaje. Sube
     mientras alguno te ve de frente: mas rapido cuanto mas cerca, el doble con
     un arma en la mano, mas con la linterna encendida, la mitad agachado (y
     agachado te ven de menos lejos). Tambien si te oyen correr. Baja si nadie
     te ve ni te oye. A 100, alarma: todos a por ti. Un disparo sin silenciador
     cerca, o herir a uno, es alarma directa. ]]
local function SigiloGuardias(yo, pos, dt)
    if not guardia or guardia.alarma then return end
    local peds = PedsGuardia()
    if IsPedShooting(yo) and not IsPedCurrentWeaponSilenced(yo) then
        for _, e in ipairs(peds) do
            if DoesEntityExist(e) and #(GetEntityCoords(e) - pos) < 120.0 then return AlarmaGuardias('disparo') end
        end
    end
    local vivos, cerca = 0, false
    guardia.vistos = guardia.vistos or {}
    for _, e in ipairs(peds) do
        if DoesEntityExist(e) then
            local caido = IsPedDeadOrDying(e, true)
            -- Herido y vivo: grita. Muerto en silencio (el rifle de lejos): solo
            -- si otro guardia ve el cuerpo.
            if not caido and HasEntityBeenDamagedByEntity(e, yo, true) then return AlarmaGuardias('herido') end
            if caido and not guardia.vistos[e] then
                guardia.vistos[e] = true
                local donde = GetEntityCoords(e)
                for _, otro in ipairs(peds) do
                    if otro ~= e and DoesEntityExist(otro) and not IsPedDeadOrDying(otro, true)
                        and #(GetEntityCoords(otro) - donde) < 20.0 and HasEntityClearLosToEntityInFront(otro, e) then
                        return AlarmaGuardias('cuerpo')
                    end
                end
            end
            if not caido then vivos = vivos + 1 end
            if #(GetEntityCoords(e) - pos) < 60.0 then cerca = true end
        end
    end
    -- Con los prismaticos puestos se esta quieto y a cubierto: no se mide.
    if mira then Barra('atencion', nil) return end
    if vivos == 0 or not cerca then Barra('atencion', nil) return end
    if GetGameTimer() < guardia.gracia then return end
    local r = guardia.r or {}
    local agachado = GetPedStealthMovement(yo)
    local armado = GetSelectedPedWeapon(yo) ~= joaat('WEAPON_UNARMED') and GetSelectedPedWeapon(yo) ~= joaat('WEAPON_FLASHLIGHT')
    local luz = Alumbrando(yo)
    local vista = (r.vista or 22.0) * (agachado and 0.6 or 1.0) + (luz and 8.0 or 0.0)
    local oido = r.oido or 14.0
    local sube, porQue = 0.0, nil
    for _, e in ipairs(peds) do
        if DoesEntityExist(e) and not IsPedDeadOrDying(e, true) then
            local d = #(GetEntityCoords(e) - pos)
            if d < vista and HasEntityClearLosToEntityInFront(e, yo) then
                local v = 15.0 * (0.4 + (1.0 - d / vista) * 1.6)   -- a 10 m, de frente y desarmado: unos 5 s
                if armado then v = v * 2.0 end
                if luz then v = v * 1.4 end
                if agachado then v = v * 0.5 end
                if v > sube then sube, porQue = v, 'Te están viendo' end
            elseif d < oido and not agachado and (IsPedSprinting(yo) or IsPedRunning(yo)) then
                local v = IsPedSprinting(yo) and 18.0 or 9.0
                if v > sube then sube, porQue = v, 'Te han oído' end
            end
        end
    end
    if sube > 0 then
        guardia.atencion = math.min(100.0, guardia.atencion + sube * dt)
    else
        guardia.atencion = math.max(0.0, guardia.atencion - 6.0 * dt)
    end
    if guardia.atencion >= 100.0 then return AlarmaGuardias('visto') end
    Barra('atencion', 'Atención', guardia.atencion / 100.0, porQue or (agachado and 'Agachado · nadie te ve' or 'Nadie te ve'))
end

--[[ Distraer (desde los prismaticos): el guardia o escolta mas cercano al
     punto (a menos de 25 m) va a mirar, se queda unos segundos y vuelve a lo
     suyo (su ronda o su puesto). Lo hace quien le controla en red; los demas
     solo oyen el golpe. ]]
local distraidos = {}   -- [ped] = true mientras va a mirar
RegisterNetEvent('origen_mision:cl:distraer', function(punto, quien)
    if type(punto) ~= 'table' or not tonumber(punto.x) then return end
    local p = vector3(punto.x + 0.0, punto.y + 0.0, punto.z + 0.0)
    local yo = PlayerPedId()
    if #(GetEntityCoords(yo) - p) < 60.0 then
        PlaySoundFromCoord(-1, 'Drill_Pin_Break', p.x, p.y, p.z, 'DLC_HEIST_FLEECA_SOUNDSET', false, 30, false)
    end
    local candidatos = {}
    for _, e in ipairs(PedsGuardia()) do candidatos[#candidatos + 1] = e end
    for _, e in ipairs(obj and obj.escoltas or {}) do candidatos[#candidatos + 1] = e end
    local cual, dMin = nil, 25.0
    for _, e in ipairs(candidatos) do
        if DoesEntityExist(e) and not IsPedDeadOrDying(e, true) and not distraidos[e] then
            local d = #(GetEntityCoords(e) - p)
            if d < dMin then cual, dMin = e, d end
        end
    end
    if not cual or not NetworkHasControlOfEntity(cual) then return end
    -- Con la alarma dada ya no se distrae a nadie.
    if (guardia and guardia.alarma) or (obj and obj.alarma) then return end
    distraidos[cual] = true
    local antes, rumbo = GetEntityCoords(cual), GetEntityHeading(cual)
    local patrulla = guardia and guardia.peds and IsPedActiveInScenario(cual) == false
    CreateThread(function()
        ClearPedTasks(cual)
        TaskGoToCoordAnyMeans(cual, p.x, p.y, p.z, 1.0, 0, false, 786603, 0.0)
        local hasta = GetGameTimer() + 20000
        while GetGameTimer() < hasta and DoesEntityExist(cual) and not IsPedDeadOrDying(cual, true)
            and #(GetEntityCoords(cual) - p) > 2.5 do Wait(400) end
        if not DoesEntityExist(cual) or IsPedDeadOrDying(cual, true) then distraidos[cual] = nil return end
        -- Mira alrededor un rato.
        TaskStartScenarioInPlace(cual, 'WORLD_HUMAN_GUARD_STAND', 0, true)
        Wait(6000)
        if not DoesEntityExist(cual) or IsPedDeadOrDying(cual, true) then distraidos[cual] = nil return end
        ClearPedTasks(cual)
        if patrulla and guardia and guardia.centro then
            TaskWanderInArea(cual, guardia.centro.x, guardia.centro.y, guardia.centro.z, (guardia.r and guardia.r.radio) or 10.0, 2.0, 3.0)
        else
            TaskGoStraightToCoord(cual, antes.x, antes.y, antes.z, 1.0, 20000, rumbo, 0.5)
            local vuelta = GetGameTimer() + 20000
            while GetGameTimer() < vuelta and DoesEntityExist(cual) and #(GetEntityCoords(cual) - antes) > 1.5 do Wait(400) end
            if DoesEntityExist(cual) then TaskStartScenarioInPlace(cual, 'WORLD_HUMAN_GUARD_STAND', 0, true) end
        end
        distraidos[cual] = nil
    end)
end)

--[[ El apagon (una ventana que abre una parte del trabajo): todo a oscuras
     para los del grupo y la cuenta atras en pantalla. Al acabar vuelve la luz. ]]
local apagado = false
local function LlevarVentana()
    local v = estado and estado.ventana
    local queda = v and (v.hasta and (v.hasta - GetGameTimer()) / 1000) or nil
    if v and not v.hasta then
        v.hasta = GetGameTimer() + (v.quedan or 0) * 1000
        queda = v.quedan
    end
    if v and queda and queda > 0 then
        if v.nombre == 'apagon' and not apagado then
            apagado = true
            SetArtificialLightsState(true)
            SetArtificialLightsStateAffectsVehicles(false)
            PlaySoundFrontend(-1, 'Power_Down', 'DLC_HEIST_HACKING_SNAKE_SOUNDS', true)
        end
        Barra('ventana', v.nombre == 'apagon' and 'Apagón' or 'Tiempo', queda / (v.total or v.quedan or 60), ('%d s'):format(math.ceil(queda)))
    else
        if apagado then
            apagado = false
            SetArtificialLightsState(false)
        end
        Barra('ventana', nil)
    end
end

--- `fin`: se acaba el trabajo (no solo el paso): fuera la furgoneta seguida y los guardias, de cero.
CerrarMiraYa = function(fin)
    CerrarMira()
    QuitarGuardia()
    QuitarSeguido(fin == true)
    if fin then guardiasHechos = {} end
    if apagado then SetArtificialLightsState(false) end
    apagado = false
    Barra('ventana', nil)
end


local avisoGrupo = 0   -- en grupo, cada cuanto avisa al servidor el que no pone los enemigos
local seguidoUltimo = nil
--- `ayuda` en un paso: un aviso que explica que hay que hacer, una vez al
--- empezarlo (rastrear tiene el suyo, mas abajo).
local ayudaDicha = nil

local function Llevar(ped, pos)
    local p = Paso()
    if p and p ~= ayudaDicha then
        ayudaDicha = p
        if p.ayuda and p.tipo ~= 'rastrear' then Aviso(p.ayuda, 'info') end
    end
    if not p then return 500 end

    LimpiarRastrosDejados(pos)
    QuitarDecorados(pos)
    for i = #atados, 1, -1 do
        -- Lejos y sin mirarle: ya se lo han llevado.
        local t = atados[i]
        local d = #(pos - t.pos)
        if d > 150.0 or (d > 60.0 and not (DoesEntityExist(t.ped) and IsEntityOnScreen(t.ped))) then BorrarAtado(t) table.remove(atados, i) end
    end
    if rutaPendiente and GetGameTimer() > (rutaPendiente.otra or 0) then
        rutaPendiente.otra = GetGameTimer() + 3000
        RutaACarretera()
    end
    if estado then
        local entero = PorId[estado.mision] and PorId[estado.mision].pasos[estado.paso]
        if entero and entero.tipo == 'doble' then
            for k, pp in pairs(entero.partes) do
                if pp.decorado and Cerca(pos, pp, 250.0) then PonerDecorado(estado.mision .. ':' .. estado.paso .. ':' .. k, pp) end
            end
        elseif p.decorado and Cerca(pos, p, 250.0) then
            PonerDecorado(estado.mision .. ':' .. estado.paso, p)
        end
    end
    if cocheParado and DoesEntityExist(cocheParado) and #(pos - GetEntityCoords(cocheParado)) > 250.0 then
        QuitarCocheParado()
    end

    -- En un paso doble cada uno pone lo de red de SU parte (aunque no sea el lider).
    local m0 = PorId[estado and estado.mision or '']
    local esDoble = m0 and m0.pasos[estado.paso] and m0.pasos[estado.paso].tipo == 'doble'
    if p.emboscada and estado and (estado.dueno ~= false or esDoble) and not llamando and Cerca(pos, p, p.emboscada.distancia or 60.0) then
        Emboscada(estado.paso, p.emboscada, vector3(p.x, p.y, p.z))
    end

    --[[ En grupo, los enemigos, el objetivo y sus escoltas, el coche a robar y
         las emboscadas los pone SOLO el que invito (si cada uno pusiera los
         suyos saldrian repetidos). Los demas los ven, los matan o se suben
         al coche, y avisan al servidor, que es quien mira si el paso esta hecho. ]]
    if estado and estado.dueno == false and not esDoble and (p.tipo == 'matar' or p.tipo == 'asesinar' or p.tipo == 'interceptar'
        or p.tipo == 'robar' or p.tipo == 'entregar') then
        if p.tipo == 'entregar' and Cerca(pos, p, 80.0) then DibujarCilindro(p, p.radio or 8.0) end
        if (p.tipo == 'entregar' or Cerca(pos, p, 400.0)) and GetGameTimer() > (avisoGrupo or 0) then
            avisoGrupo = GetGameTimer() + 2000
            Cumplir()
        end
        return p.tipo == 'entregar' and Cerca(pos, p, 80.0) and 0 or 500
    end

    DibujarMarcados()
    LlevarVentana()
    -- Los guardias son del paso, no de una parte: los pone el primero que llega.
    local claveGuardias = estado and (estado.mision .. ':' .. estado.paso)
    local gDef, gCentro = GuardiasDelPaso(p)
    if gDef and estado and #(pos - gCentro) < (gDef.distancia or 120.0) then
        PonerGuardias(claveGuardias, gDef, gCentro)
    end
    if guardia then
        if guardia.clave ~= claveGuardias then
            QuitarGuardia()
        else
            local ahora = GetGameTimer()
            SigiloGuardias(ped, pos, math.min(0.5, (ahora - (guardia.ultimo or ahora)) / 1000.0))
            guardia.ultimo = ahora
        end
    end

    if p.tipo == 'esperar' then
        return next(marcados) and 0 or 1000
    end

    if p.tipo == 'seguir' then
        local ahora = GetGameTimer()
        local dt = math.min(0.5, (ahora - (seguidoUltimo or ahora)) / 1000.0)
        seguidoUltimo = ahora
        return LlevarSeguir(p, ped, pos, dt)
    end

    if p.tipo == 'cubrir' then
        return LlevarCubrir(p, ped, pos)
    end

    if p.tipo == 'ir' then
        if Cerca(pos, p, 60.0) then DibujarCilindro(p, p.radio or 6.0) end
        if Cerca(pos, p, p.radio or 6.0) then Cumplir() end
        return Cerca(pos, p, 60.0) and 0 or 500

    elseif p.tipo == 'llamada' then
        Llamar(p)
        return 1000

    elseif p.tipo == 'rastrear' then
        if not Cerca(pos, p, p.alcance or 70.0) then return 500 end
        if not rastrosPuestos then
            PonerRastros(p)
            -- Lo que hay que mirar solo se ve al alumbrarlo: que se sepa.
            Aviso(p.ayuda or ('Saca la linterna y alumbra el suelo: lo que haya que mirar brillará (%d cosas).'):format(#p.puntos), 'info')
        end
        local hechos = estado and estado.examinados or {}
        local alumbra = Alumbrando(ped)
        local cerca, dCerca = nil, 99.0
        for i, punto in ipairs(p.puntos) do
            if not hechos[i] and not hechos[tostring(i)] then
                local c = vector3(punto.x, punto.y, Suelo(punto.x, punto.y, punto.z) + 0.05)
                local enLuz = alumbra and EnElHaz(c)
                -- `ocultos`: lo que hay solo se ve mientras la linterna le da encima.
                -- (y de cerca, ya descubierto: al examinarlo no se le alumbra).
                if p.ocultos and rastrosPuestos and rastrosPuestos.porPunto[i] then
                    local ver = enLuz or (revelados[i] and #(pos - c) < 2.5) or false
                    rastrosPuestos.vistos = rastrosPuestos.vistos or {}
                    if rastrosPuestos.vistos[i] ~= ver then
                        rastrosPuestos.vistos[i] = ver
                        for _, o in ipairs(rastrosPuestos.porPunto[i]) do
                            if DoesEntityExist(o) then SetEntityVisible(o, ver, false) end
                        end
                    end
                end
                if enLuz and not revelados[i] then
                    revelados[i] = true
                    PlaySoundFrontend(-1, 'FocusIn', 'HintCamSounds', true)
                end
                if revelados[i] then
                    -- Ya alumbrado: una flecha pequeña encima, nada en el suelo (lo que se ve es el rastro).
                    DrawMarker(2, c.x, c.y, c.z + 0.55, 0.0, 0.0, 0.0, 180.0, 0.0, 0.0, 0.16, 0.16, 0.16, 216, 27, 85, 220, true, true, 2, false, nil, nil, false)
                    local d = #(pos - c)
                    if d < dCerca then cerca, dCerca = i, d end
                end
            end
        end
        if cerca and dCerca < 1.7 and not examinando and not IsPedInAnyVehicle(ped, false) then
            Pedir('E', 'Examinar: ' .. (p.puntos[cerca].nombre or 'rastro'))
            if IsControlJustReleased(0, 38) then Examinar(cerca, p.puntos[cerca]) end
        end
        return 0

    elseif p.tipo == 'investigar' then
        if p.npc and not testigo and Cerca(pos, p, 80.0) then PonerTestigo(p) end
        if p.coche and not cocheParado and Cerca(pos, p, 90.0) then PonerCocheParado(p) end
        local donde = (testigo and DoesEntityExist(testigo)) and GetEntityCoords(testigo) or vector3(p.x, p.y, p.z)
        -- Del coche se registra el maletero: detras.
        -- Del coche se registra el maletero: detras. Si hay alguien con quien
        -- hablar, se le habla a el (el coche puede ser suyo, o del paso de antes).
        if not testigo and p.coche and cocheParado and DoesEntityExist(cocheParado) then donde = GetOffsetFromEntityInWorldCoords(cocheParado, 0.0, -2.7, 0.0) end
        if #(pos - donde) < 40.0 then
            local esc = testigo and 0.16 or 0.25
            DrawMarker(2, donde.x, donde.y, donde.z + (testigo and 1.15 or 1.7), 0.0, 0.0, 0.0, 180.0, 0.0, 0.0, esc, esc, esc, 216, 27, 85, 210, true, true, 2, false, nil, nil, false)
        end
        if #(pos - donde) < 2.6 and not IsPedInAnyVehicle(ped, false) and not investigando then
            -- A solas (misionsolo) el que pregunta tambien aprieta: con la G.
            local pt = estado and estado.solo and p.npc and p.npc.silla and ParteTortura(estado.paso)
            local acc = pt and AccionSiguiente(pt)
            if acc and not apretando then
                Pedir('E', (p.accion or 'Investigar') .. '   ·   G  ' .. acc.nombre)
                if IsControlJustReleased(0, 47) then
                    Texto(nil)
                    CreateThread(Apretar)
                    return 0
                end
            elseif not apretando then
                Pedir('E', p.accion or 'Investigar')
            end
            if not apretando and IsControlJustReleased(0, 38) then
                Texto(nil)
                CreateThread(function() Investigar(p) end)
            end
            return 0
        end
        return #(pos - donde) < 40.0 and 0 or 500

    elseif p.tipo == 'torturar' then
        -- El que aprieta: el mismo preso (local) y, con E, la accion siguiente.
        if p.npc and not testigo and Cerca(pos, p, 80.0) then PonerTestigo(p) end
        local donde = (testigo and DoesEntityExist(testigo)) and GetEntityCoords(testigo) or vector3(p.x, p.y, p.z)
        if #(pos - donde) < 40.0 then
            DrawMarker(2, donde.x, donde.y, donde.z + 1.15, 0.0, 0.0, 0.0, 180.0, 0.0, 0.0, 0.16, 0.16, 0.16, 216, 27, 85, 210, true, true, 2, false, nil, nil, false)
        end
        if #(pos - donde) < 2.6 and not IsPedInAnyVehicle(ped, false) and not apretando then
            local acc = AccionSiguiente(p)
            if acc then
                Pedir('E', acc.nombre)
                if IsControlJustReleased(0, 38) then
                    Texto(nil)
                    CreateThread(Apretar)
                end
            else
                Pedir('E', p.tope or 'Ya no aguanta más: que pregunte tu compañero')
            end
            return 0
        end
        return #(pos - donde) < 40.0 and 0 or 500

    elseif p.tipo == 'alejarse' then
        if not Cerca(pos, p, p.radio) then Cumplir() end
        return 1000

    elseif p.tipo == 'foto' then
        -- Lo que hay que fotografiar: una flecha encima, de cerca.
        local que = (p.cuerpo and cuerpo) or vector3(p.x, p.y, p.z)
        if #(pos - que) < 60.0 then
            DrawMarker(2, que.x, que.y, que.z + 0.9, 0.0, 0.0, 0.0, 180.0, 0.0, 0.0, 0.16, 0.16, 0.16, 216, 27, 85, 210, true, true, 2, false, nil, nil, false)
            return 0
        end
        return 500

    elseif p.tipo == 'recoger' then
        -- Lo que llevaba el objetivo esta donde cayo, no en el punto de la config.
        if p.cuerpo and cuerpo then p = { x = cuerpo.x, y = cuerpo.y, z = cuerpo.z, prop = p.prop, texto = p.texto } end
        if not ents.prop and Cerca(pos, p, 120.0) then Prop(p) end
        if Cerca(pos, p, 2.0) and not IsPedInAnyVehicle(ped, false) then
            Pedir('E', 'Coger')
            if IsControlJustReleased(0, 38) then
                Texto(nil)
                Agacharse()
                if Cumplir() then ALaMano(IsModelInCdimage(joaat(p.prop or '')) and p.prop or 'prop_ld_case_01') end
            end
            return 0
        end
        return Cerca(pos, p, 30.0) and 0 or 500

    elseif p.tipo == 'dejar' then
        -- En un objeto que esta ahi (contenedor, buzon): flecha encima. Si no, el circulo en el suelo.
        if Cerca(pos, p, 40.0) then
            if p.objeto then
                DrawMarker(2, p.x, p.y, p.z + 1.8, 0.0, 0.0, 0.0, 180.0, 0.0, 0.0, 0.25, 0.25, 0.25, 216, 27, 85, 210, true, true, 2, false, nil, nil, false)
            else
                DibujarCilindro(p, 1.0)
            end
        end
        if Cerca(pos, p, p.objeto and 2.8 or 2.0) and not IsPedInAnyVehicle(ped, false) then
            Pedir('E', 'Dejar')
            if IsControlJustReleased(0, 38) then
                Texto(nil)
                Agacharse()
                if Cumplir() then SoltarMano() end
            end
            return 0
        end
        return Cerca(pos, p, 40.0) and 0 or 500

    elseif p.tipo == 'matar' then
        if not apuntado then
            if Cerca(pos, p, 120.0) then
                apuntado = Enemigos(p)
                if not apuntado then
                    -- No ha cuadrado: se quita y se vuelve a intentar.
                    for i, e in ipairs(ents.peds) do
                        OrigenMapa.Quitar('enemigo_' .. i)
                        if DoesEntityExist(e) then DeleteEntity(e) end
                    end
                    ents.peds = {}
                    return 3000
                end
            end
            return 500
        end
        local vivos = 0
        for _, e in ipairs(ents.peds) do
            if DoesEntityExist(e) and not IsPedDeadOrDying(e, true) then
                vivos = vivos + 1
                -- Se lanzan a por el jugador en cuanto se acerca o les dispara.
                if not atacando[e] and (#(GetEntityCoords(e) - pos) < 60.0 or HasEntityBeenDamagedByEntity(e, ped, true)) then
                    atacando[e] = true
                    TaskCombatPed(e, ped, 0, 16)
                end
            end
        end
        if vivos == 0 then Cumplir() end
        return 1000

    elseif p.tipo == 'asesinar' or p.tipo == 'interceptar' then
        if not apuntado then
            local montar = p.tipo == 'asesinar' and 150.0 or 300.0
            if Cerca(pos, p, montar) then
                apuntado = (p.tipo == 'asesinar' and PonerAsesinar or PonerInterceptar)(p)
                if not apuntado then
                    QuitarObjetivo(true)
                    return 3000
                end
                obj.ultimo = GetGameTimer()
            end
            return 500
        end
        if not obj then return 500 end
        local ahora = GetGameTimer()
        local dt = math.min(0.5, (ahora - (obj.ultimo or ahora)) / 1000.0)
        obj.ultimo = ahora
        -- El convoy arranca cuando el jugador lo tiene a la vista.
        if p.tipo == 'interceptar' and not obj.arrancado and DoesEntityExist(obj.ped) and #(pos - GetEntityCoords(obj.ped)) < 150.0 then
            obj.arrancado = true
            local d = p.destino
            TaskVehicleDriveToCoordLongrange(obj.ped, obj.veh, d.x, d.y, d.z, 20.0, 786603, 30.0)
            Escoltar(false)
            Aviso(('%s se pone en marcha hacia %s.'):format(p.objetivo.nombre or 'El objetivo', d.nombre or 'su destino'), 'info')
        end
        Sigilo(ped, pos, dt)
        -- La flecha sobre la cabeza del objetivo, de cerca.
        if DoesEntityExist(obj.ped) and not IsPedDeadOrDying(obj.ped, true) then
            local c = GetEntityCoords(obj.ped)
            if #(c - pos) < 80.0 then
                DrawMarker(2, c.x, c.y, c.z + 1.15, 0.0, 0.0, 0.0, 180.0, 0.0, 0.0, 0.16, 0.16, 0.16, 216, 27, 85, 200, true, true, 2, false, nil, nil, false)
            end
        else
            Cumplir()
            return 1000
        end
        return 0

    elseif p.tipo == 'robar' then
        if not apuntado then
            if Cerca(pos, p, 150.0) then
                apuntado = Coche(p)
                if not apuntado then
                    OrigenMapa.Quitar('coche')
                    if ents.veh and DoesEntityExist(ents.veh) then DeleteEntity(ents.veh) end
                    ents.veh = nil
                    return 3000
                end
            end
            return 500
        end
        if ents.veh and GetPedInVehicleSeat(ents.veh, -1) == ped then Cumplir() end
        return 500

    elseif p.tipo == 'entregar' then
        if Cerca(pos, p, 80.0) then DibujarCilindro(p, p.radio or 8.0) end
        local veh = ents.veh
        if veh and DoesEntityExist(veh) and Cerca(GetEntityCoords(veh), p, p.radio or 8.0) then
            if GetPedInVehicleSeat(veh, -1) == ped then
                if GetEntitySpeed(veh) < 2.0 then
                    TaskLeaveVehicle(ped, veh, 0)
                    local hasta = GetGameTimer() + 3000
                    while IsPedInVehicle(ped, veh, false) and GetGameTimer() < hasta do Wait(100) end
                    Cumplir()
                end
            elseif not IsPedInAnyVehicle(ped, false) then
                Cumplir()
            end
        end
        return Cerca(pos, p, 80.0) and 0 or 500
    end
    return 500
end

CreateThread(function()
    -- Si el recurso se reinicia a media mision, el servidor la ha perdido: nada que recoger.
    local e = lib.callback.await('origen_mision:estado', false)
    if e then TriggerEvent('origen_mision:cl:estado', e) end

    local ultimoRastreo = 0
    while true do
        local espera = 1000
        deseo = nil
        local ped = PlayerPedId()
        local pos = GetEntityCoords(ped)

        -- La investigacion
        if estado and not panel then
            --[[ Muerto de verdad: el ped muerto o la marca de la ambulancia
                 (origen_ambulancejob pone state.dead). Tiene que durar 3 s
                 seguidos: un instante raro (un ragdoll, un cambio de modelo)
                 no puede tirar el trabajo. ]]
            local muerto = IsEntityDead(ped) or LocalPlayer.state.dead == true
            if muerto then
                muertoDesde = muertoDesde or GetGameTimer()
                if mira then CerrarMira() end
            else
                muertoDesde = nil
            end
            if not fallado and muertoDesde and GetGameTimer() - muertoDesde > 3000 then
                fallado = true
                TriggerServerEvent('origen_mision:fallo', 'muerto')
            elseif not muerto then
                espera = math.min(espera, Llevar(ped, pos))
            end
            local ahora = GetGameTimer()
            if ahora - ultimoRastreo > 1000 then
                ultimoRastreo = ahora
                Rastreador()
            end
        end

        if panel then
            -- La pantalla ya lo quito; no volver a ponerlo por debajo.
        elseif deseo then Texto(deseo[1], deseo[2]) else Texto(nil) end

        Wait(espera)
    end
end)

-- ---------------------------------------------------------------------------
--  Comandos y el panel de admin
-- ---------------------------------------------------------------------------

RegisterCommand(Config.ComandoAbandonar, function()
    if not estado then return Aviso('No llevas ningún trabajo.', 'info') end
    lib.callback.await('origen_mision:abandonar', false)
end, false)

--- /listanegra: lo mismo que usar el objeto. El servidor mira que lo lleve.
RegisterCommand(Config.ComandoAbrir, function()
    if panel or IsNuiFocused() then return end
    AbrirPanel('lista')
end, false)

--- Usar la Lista Negra (lo manda el servidor al usar el objeto).
RegisterNetEvent('origen_mision:cl:abrir', function()
    if panel then return end
    -- El inventario se esta cerrando: se espera a que suelte el raton.
    local hasta = GetGameTimer() + 1500
    while IsNuiFocused() and GetGameTimer() < hasta do Wait(50) end
    AbrirPanel('lista')
end)

RegisterCommand(Config.ComandoAdmin, function()
    if panel then return end
    if not lib.callback.await('origen_mision:admin:puede', false) then return end
    desdeElHub = false
    AbrirPanel('admin')
end, false)

--- La pestaña Scripts del panel de administracion. Si no se puede abrir, el
--- panel de admin ya se aparto: que vuelva, o el jugador se queda sin nada.
exports('openManagement', function()
    CreateThread(function()
        if panel or not lib.callback.await('origen_mision:admin:puede', false) then
            if GetResourceState('origen_admin') == 'started' then exports['origen_admin']:ReturnToScripts() end
            return
        end
        desdeElHub = true
        AbrirPanel('admin', true)
    end)
end)

AddEventHandler('onResourceStop', function(recurso)
    if recurso ~= GetCurrentResourceName() then return end
    BorrarTodo()
    if textoPuesto then exports.origen_notify:HideText() end
    if panel then
        SetNuiFocus(false, false)
        HudFuera(false)
    end
end)
