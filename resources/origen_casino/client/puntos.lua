--[[ ══════════════════════════════════════════════════════════════════════════
     LAS MESAS, LAS MÁQUINAS Y LOS MOSTRADORES EN EL MUNDO

     Todo lo que se ve sale de la lista que manda el servidor. Aquí no hay ni
     una coordenada escrita.

     Las entidades son LOCALES —cada cliente crea las suyas y solo cuando se
     acerca—: una mesa de blackjack no necesita estar sincronizada con nadie,
     y crear ochenta objetos en red al arrancar el servidor es la forma más
     rápida de llenar el pool de objetos y que empiece a fallar todo lo demás.
   ══════════════════════════════════════════════════════════════════════════ ]]

local entidades = {}     -- [puntoId] = entidad
local zonas = {}         -- [puntoId] = punto de ox_lib
local textoVisible = nil

local DISTANCIA_CARGA = 60.0

-- ── Crear y quitar ────────────────────────────────────────────────────────

local cambios = {}       -- [puntoId] = { x, y, z, radio, de, a } | { oculto = true, ... }

--[[ ── El mueble del mapa ─────────────────────────────────────────────────

     Un punto traído de un mapa (shared/mapas.lua) dice qué mueble del mapa
     hay ahí. Si es de otra variante o propio del mapa, se CAMBIA en el juego
     por el del catálogo, que es el que tiene los huesos de las sillas y las
     medidas; si hay que quitarlo (la rueda propia de un mapa), se esconde.
     Los dos se deshacen al quitar el punto. ]]
local function CambiarMueble(punto, tipo)
    local de = tonumber(punto.modeloMapa)
    if not de or not tipo.modelo then return end
    if punto.quitarMapa then
        CreateModelHide(punto.x, punto.y, punto.z, 3.0, de, true)
        local c = { x = punto.x, y = punto.y, z = punto.z, radio = 3.0, de = de, oculto = true }
        cambios[punto.id] = c
        --[[ Esconder por modelo no basta: cuando el mapa se recarga (al irse y
             volver, o al reiniciarlo) el mueble vuelve a salir. Mientras el
             punto esté puesto, se busca cada poco y se apaga. ]]
        CreateThread(function()
            while cambios[punto.id] == c do
                local e = GetClosestObjectOfType(c.x, c.y, c.z, c.radio, de, false, false, false)
                if e ~= 0 and IsEntityVisible(e) then
                    SetEntityVisible(e, false, false)
                    SetEntityCollision(e, false, false)
                end
                Wait(2000)
            end
            local e = GetClosestObjectOfType(c.x, c.y, c.z, c.radio, de, false, false, false)
            if e ~= 0 then SetEntityVisible(e, true, false) SetEntityCollision(e, true, true) end
        end)
        return
    end
    local a = joaat(tipo.modelo)
    if de == a then return end
    CreateModelSwap(punto.x, punto.y, punto.z, 1.5, de, a, true)
    cambios[punto.id] = { x = punto.x, y = punto.y, z = punto.z, radio = 1.5, de = de, a = a }
end

local function DeshacerMueble(id)
    local c = cambios[id]
    if not c then return end
    cambios[id] = nil
    if c.oculto then RemoveModelHide(c.x, c.y, c.z, c.radio, c.de, false)
    else RemoveModelSwap(c.x, c.y, c.z, c.radio, c.de, c.a, false) end
end

local function Quitar(id)
    Maquinas.Quitar(id)
    VideoMundo.Quitar(id)
    Mesas.Quitar(id)
    RuletaMundo.Quitar(id)
    RuedaMundo.Quitar(id)
    DeshacerMueble(id)
    local ent = entidades[id]
    if ent and DoesEntityExist(ent) then DeleteEntity(ent) end
    entidades[id] = nil
end

--- Monta el juego sobre un mueble que ya está en el mundo.
local function Montar(punto, tipo, ent)
    if tipo.juego == 'tragaperras' then Maquinas.Poner(punto, tipo, ent) end
    if tipo.video then VideoMundo.Poner(punto, tipo, ent) end
    if tipo.mesaCartas then Mesas.Poner(punto, tipo, ent) end
    if tipo.ruletaMundo and ent then RuletaMundo.Poner(punto, tipo, ent) end
    if tipo.juego == 'rueda' then
        --[[ Una base de rueda del mapa puede traer ya su rueda de premios
             puesta: se esconde, que la que gira es la nuestra. ]]
        if punto.sinProp and not cambios[punto.id] then
            local rueda = joaat('vw_prop_vw_luckywheel_02a')
            CreateModelHide(punto.x, punto.y, punto.z + 1.5, 2.0, rueda, true)
            cambios[punto.id] = { x = punto.x, y = punto.y, z = punto.z + 1.5, radio = 2.0, de = rueda, oculto = true }
        end
        RuedaMundo.Poner(punto, tipo, ent)
    end
end

local function Crear(punto)
    if entidades[punto.id] then return end
    local tipo = Catalogo.Tipo(punto.tipo)
    if not tipo then return end

    CambiarMueble(punto, tipo)

    --[[ Un mueble que ya estaba en el interior («sin poner el mueble») no se
         crea: se busca el que hay ahí y se le monta encima el juego —los
         asientos, el crupier, los rodillos—. Se busca un rato, porque un
         mueble recién cambiado de modelo tarda unos fotogramas en estar. ]]
    if (punto.sinProp or tipo.sinProp) and tipo.modelo and not tipo.ped then
        entidades[punto.id] = false
        CreateThread(function()
            local hash = joaat(tipo.modelo)
            local ya, hasta = 0, GetGameTimer() + 4000
            while ya == 0 and GetGameTimer() < hasta do
                ya = GetClosestObjectOfType(punto.x, punto.y, punto.z, 1.5, hash, false, false, false)
                if ya == 0 then Wait(200) end
            end
            if entidades[punto.id] ~= false then return end      -- se quitó entretanto
            if ya == 0 and tipo.juego ~= 'tragaperras' and tipo.juego ~= 'rueda' then ya = nil end
            if ya ~= 0 then Montar(punto, tipo, ya) end
        end)
        return
    end
    if not tipo.modelo or punto.sinProp or tipo.sinProp then return end

    local hash = joaat(tipo.modelo)
    if not pcall(lib.requestModel, hash, 8000) then
        print(('[casino] no se ha podido cargar el modelo %s'):format(tipo.modelo))
        return
    end

    --[[ ── La altura ────────────────────────────────────────────────────────

         Los puntos se guardan a ras de SUELO: el modo de colocar los pega con
         `GetGroundZFor_3dCoord`. Pero ni los props ni los peds se crean
         poniendo ahí su z, y cada uno por un motivo distinto.

         Un PED se crea por sus PIES, igual que se guarda el punto: su z va
         tal cual.

         Un PROP se crea por el ORIGEN DE SU MODELO, y cada modelo lo tiene
         donde al artista le vino bien: la mesa de blackjack lo tiene en la
         base y se apoya sola, pero la rueda de la suerte lo tiene en el centro
         y se hunde medio metro. En vez de apuntarse una corrección por modelo
         —que hay que repetir cada vez que se añade uno—, se le pregunta al
         propio modelo dónde tiene el suelo con `GetModelDimensions` y se sube
         esa diferencia. Así sirve para cualquier prop que se meta mañana. ]]
    local ent
    if tipo.ped then
        ent = CreatePed(4, hash, punto.x, punto.y, punto.z, punto.h, false, false)
        SetEntityInvincible(ent, true)
        SetBlockingOfNonTemporaryEvents(ent, true)
        FreezeEntityPosition(ent, true)
        if tipo.escenario then TaskStartScenarioInPlace(ent, tipo.escenario, 0, true) end
    else
        local bajo = GetModelDimensions(hash)
        local suelo = punto.z - ((bajo and bajo.z) or 0.0)
        ent = CreateObject(hash, punto.x, punto.y, suelo, false, false, false)
        SetEntityRotation(ent, 0.0, 0.0, punto.h + 0.0, 2, true)
        FreezeEntityPosition(ent, true)
        SetEntityCollision(ent, true, true)
    end
    SetModelAsNoLongerNeeded(hash)
    entidades[punto.id] = ent

    -- Las tragaperras llevan los rodillos aparte (client/maquinas.lua), las
    -- mesas de cartas su crupier (client/mesas.lua), la ruleta su bombo y la
    -- rueda su rueda de premios.
    Montar(punto, tipo, ent)
end

-- ── El aviso de la tecla ──────────────────────────────────────────────────

local function Texto(punto, tipo)
    if not C.abierto then return '[E] El casino está cerrado' end
    if not punto.activo then return '[E] Fuera de servicio' end

    if punto.juego == 'caja' then return '[E] Caja de fichas' end
    if punto.juego == 'membresia' then return '[E] Tarjeta de socio' end
    if punto.juego == 'rueda' then return '[E] Girar la rueda' end

    local juego = Config.Juegos[punto.juego]
    local nombre = punto.nombre ~= '' and punto.nombre or (juego and juego.nombre) or tipo.nombre
    if juego and not juego.activo then return '[E] ' .. nombre .. ' · cerrado' end
    if punto.min and punto.min > 0 then
        return ('[E] %s · desde %s fichas'):format(nombre, Casino.Miles(punto.min))
    end
    return '[E] ' .. nombre
end

local function Mostrar(texto, icono)
    if textoVisible == texto then return end
    textoVisible = texto
    lib.showTextUI(texto, { position = 'left-center', icon = icono or 'dice' })
end

local function Esconder()
    if not textoVisible then return end
    textoVisible = nil
    lib.hideTextUI()
end

-- ── Pulsar E ──────────────────────────────────────────────────────────────

local function Entrar(punto)
    if C.pantalla then return end

    if punto.juego == 'caja' or punto.juego == 'membresia' then
        AbrirCaja(punto)
        return
    end

    local res = lib.callback.await('origen_casino:sentarse', false, punto.id)
    if not res or not res.ok then
        C.Aviso(Config.General.nombre, (res and res.mensaje) or 'No se ha podido.', 'error')
        -- Cuando lo que falta es la tarjeta, se abre la ventana de sacarla ahí
        -- mismo: el que se entera es justo el que iba a jugar.
        if res and res.mensaje and res.mensaje:find('socio') then
            AbrirCaja(punto, 'membresia')
        end
    end
end

-- ── Las zonas ─────────────────────────────────────────────────────────────

local function QuitarZona(id)
    local z = zonas[id]
    if z and z.remove then z:remove() end
    zonas[id] = nil
end

local function PonerZona(punto)
    QuitarZona(punto.id)
    local tipo = Catalogo.Tipo(punto.tipo)
    if not tipo then return end

    local z = lib.points.new({ coords = vec3(punto.x, punto.y, punto.z), distance = DISTANCIA_CARGA })
    zonas[punto.id] = z

    function z:onEnter()
        Crear(punto)
    end

    function z:onExit()
        Quitar(punto.id)
        if textoVisible then Esconder() end
    end

    --[[ Lo que no tiene prop necesita algo que se vea: una ventanilla de
         apuestas sin marca es un trozo de suelo donde a veces sale una tecla,
         y nadie la encuentra dos veces. ]]
    local marca = tipo.marcador or ((punto.sinProp or tipo.sinProp or not tipo.modelo) and { r = 216, g = 27, b = 85 })

    function z:nearby()
        if C.colocando then return end

        if marca and self.currentDistance <= 12.0 then
            DrawMarker(23, punto.x, punto.y, punto.z - 0.95, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                0.55, 0.55, 0.55, marca.r, marca.g, marca.b, 110, false, false, 2, false, nil, nil, false)
        end

        local cerca = self.currentDistance <= (tipo.radio or 2.0)
        if cerca and not C.pantalla then
            Mostrar(Texto(punto, tipo), tipo.icono)
            if IsControlJustReleased(0, 38) then
                Esconder()
                Entrar(punto)
            end
        elseif textoVisible and not cerca then
            Esconder()
        end
    end
end

-- ── Rehacerlo todo cuando cambia la lista ─────────────────────────────────

local function Rehacer(puntos)
    for id in pairs(zonas) do
        if not puntos[id] then
            QuitarZona(id)
            Quitar(id)
        end
    end
    for id, punto in pairs(puntos) do
        QuitarZona(id)
        Quitar(id)
        PonerZona(punto)
    end
    PintarEnElMapa(puntos)
end

--[[ Los puntos en el mapa de la casa. Solo los que valen para llegar a algún
     sitio: una sala con veinte tragaperras no necesita veinte chinchetas
     encima, y con ellas el mapa del casino no se lee. ]]
function PintarEnElMapa(puntos)
    local lista = {}
    for id, p in pairs(puntos) do
        local interesa = p.juego == 'caja' or p.juego == 'membresia' or p.juego == 'rueda'
            or p.juego == 'caballos'
        if interesa and p.activo and not p.sinBlip then
            lista[#lista + 1] = {
                id = 'punto' .. id,
                x = p.x, y = p.y, z = p.z,
                cat = 'activities',
                icono = 'casino',
                nombre = p.nombre ~= '' and p.nombre or Config.General.nombre,
            }
        end
    end
    OrigenMapa.PonerVarios('puntos', lista)
end

C.AlCambiarPuntos(Rehacer)

AddEventHandler('onResourceStop', function(recurso)
    if recurso ~= GetCurrentResourceName() then return end
    for id in pairs(entidades) do Quitar(id) end
    Esconder()
end)
