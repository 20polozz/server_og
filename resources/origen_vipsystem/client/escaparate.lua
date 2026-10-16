--[[ ═══════════════════════════════════════════════════════════════════════
     EL ESCAPARATE · ver en 3D un coche, una mascota, una prenda o un tatuaje de la tienda

     Lo mismo que la vista previa del concesionario: el vehículo (o el animal)
     se monta en el estudio fijo, con una cámara delante, y se gira arrastrando
     con el ratón; la rueda acerca y aleja. Aquí no se compra nada: se mira, y
     se vuelve a la ficha.

     Lo que se monta es LOCAL (no está en red: solo lo ve quien mira) y está
     congelado y sin colisión, así que no hace falta dimensión aparte. Qué
     modelo es lo dice el servidor a partir del producto
     (origen_vipsystem:server:tienda:escaparate); la interfaz solo manda el id.
   ═══════════════════════════════════════════════════════════════════════ ]]

Escaparate = {}

-- El mismo estudio de origen_dealership (client/threads.lua: FIXED_PREVIEW_*)
local SITIO = vec4(1047.18, 4887.14, -31.8, 186.92)
local CAMARA = vector3(1047.45, 4881.61, -30.9)
local MIRA = vector3(1047.18, 4887.14, -31.35)

local ZOOM_MIN, ZOOM_MAX = 0.8, 3.0
-- Cómo se ve al entrar: de tres cuartos y algo cerca (de frente y de lejos no luce).
-- Los mismos números están en la interfaz (StoreEscaparate.vue: DE_ENTRADA).
local GIRO_ENTRADA, ZOOM_ENTRADA = 40.0, 2.3

local turno = 0          -- cada montaje se apunta el suyo: el que llega tarde se retira
local entidad, camara = nil, nil
local tipo = nil
local suelo = SITIO.z - 0.5
local quiero = { giro = 0.0, zoom = 1.0, alto = 0.0 }
local tengo = { giro = 0.0, zoom = 1.0, alto = 0.0 }

--[[ Un TATUAJE se enseña sobre un doble local del personaje, en ropa interior y
     sin los tatuajes que lleve (se ve el producto, limpio). Qué decoraciones son y
     desde dónde se mira lo manda el servidor: { decoraciones = { { c, b, n } },
     vista = { giro, zoom, alto } }. La ropa interior es la del tatuador
     (origen_tattoos: Config.Clothes), copiada: componente → { drawable, textura }. ]]
local SIN_ROPA = {
    -- Piernas y calzado: los que se comprobaron en las fotos del pack (pantalón corto 14 / braga 15, chanclas 5).
    -- El 0 de piernas es un vaquero y el 34/35 de calzado, en este servidor, unas zapatillas: tapaban piernas y pies.
    hombre = { [1] = { 0, 0 }, [3] = { 15, 0 }, [4] = { 14, 0 }, [5] = { 0, 0 }, [6] = { 5, 0 }, [7] = { 0, 0 }, [8] = { 15, 0 }, [9] = { 0, 0 }, [10] = { 0, 0 }, [11] = { 15, 0 } },
    mujer = { [1] = { 0, 0 }, [3] = { 15, 0 }, [4] = { 15, 0 }, [5] = { 0, 0 }, [6] = { 5, 0 }, [7] = { 0, 0 }, [8] = { 14, 0 }, [9] = { 0, 0 }, [10] = { 0, 0 }, [11] = { 15, 0 } },
}
local MUJER = joaat('mp_f_freemode_01')
local tatuajeVisto = nil   -- la figura que hay montada (para cambiar de acabado sin mover la cámara)

local function Desvestir(ped)
    local modelo = GetEntityModel(ped)
    -- solo los modelos de personaje: a un ped de otro tipo estos números le pondrían cualquier cosa
    if modelo ~= MUJER and modelo ~= joaat('mp_m_freemode_01') then return end
    for componente, v in pairs(SIN_ROPA[modelo == MUJER and 'mujer' or 'hombre']) do
        SetPedComponentVariation(ped, componente, v[1], v[2], 0)
    end
    for _, prop in ipairs({ 0, 1, 2, 6, 7 }) do ClearPedProp(ped, prop) end
end

local function Tatuar(ped, tatu)
    ClearPedDecorations(ped)
    local sufijo = GetEntityModel(ped) == MUJER and '_f' or '_m'
    for _, d in ipairs(type(tatu.decoraciones) == 'table' and tatu.decoraciones or {}) do
        if type(d) == 'table' and type(d.c) == 'string' and type(d.b) == 'string' then
            local coleccion, nombre = joaat(d.c), joaat(d.b .. sufijo)
            for _ = 1, math.max(1, math.min(4, math.floor(tonumber(d.n) or 1))) do
                AddPedDecorationFromHashes(ped, coleccion, nombre)
            end
        end
    end
end

local function Limitar(v, minimo, maximo)
    return math.max(minimo, math.min(maximo, v))
end

local function Borrar()
    if entidad and DoesEntityExist(entidad) then
        SetEntityAsMissionEntity(entidad, true, true)
        if tipo == 'mascota' or tipo == 'ropa' or tipo == 'tatuaje' then DeletePed(entidad) else DeleteVehicle(entidad) end
        if DoesEntityExist(entidad) then DeleteEntity(entidad) end
    end
    entidad = nil
end

--- Cierra el escaparate: sin cámara, sin coche y con el mundo otra vez donde está el jugador.
function Escaparate.Cerrar()
    turno = turno + 1
    Borrar()
    tipo = nil
    tatuajeVisto = nil
    if camara then
        SetCamActive(camara, false)
        RenderScriptCams(false, false, 0, true, true)
        DestroyCam(camara, false)
        camara = nil
        ClearFocus()
    end
end

function Escaparate.Abierto()
    return camara ~= nil
end

local function Cargar(hash)
    RequestModel(hash)
    local intentos = 0
    while not HasModelLoaded(hash) and intentos < 80 do
        Wait(100)
        intentos = intentos + 1
    end
    return HasModelLoaded(hash)
end

--- Dónde va la cámara y a dónde mira. Un coche se ve como en el concesionario;
--- una mascota es mucho más pequeña: la cámara se acerca y baja a su altura.
local function Encuadre()
    if tipo == 'mascota' then
        local dx, dy = CAMARA.x - SITIO.x, CAMARA.y - SITIO.y
        local largo = math.sqrt(dx * dx + dy * dy)
        local lejos = 2.6
        return vector3(SITIO.x + dx / largo * lejos, SITIO.y + dy / largo * lejos, suelo + 0.75 + tengo.alto),
            vector3(SITIO.x, SITIO.y, suelo + 0.38), 42.0
    end
    if tipo == 'ropa' then
        -- Una persona: la cámara a media altura, y sube y baja ENTERA con el ratón (para mirar
        -- de cerca un sombrero o unas zapatillas), no solo se inclina
        local dx, dy = CAMARA.x - SITIO.x, CAMARA.y - SITIO.y
        local largo = math.sqrt(dx * dx + dy * dy)
        local lejos = 3.4
        local z = suelo + 1.0 + tengo.alto
        return vector3(SITIO.x + dx / largo * lejos, SITIO.y + dy / largo * lejos, z + 0.12),
            vector3(SITIO.x, SITIO.y, z), 52.0
    end
    if tipo == 'tatuaje' then
        -- Más cerca que la ropa: se mira un trozo del cuerpo, no el conjunto. La cámara sube y baja entera.
        local dx, dy = CAMARA.x - SITIO.x, CAMARA.y - SITIO.y
        local largo = math.sqrt(dx * dx + dy * dy)
        local lejos = 2.3
        local z = suelo + 1.0 + tengo.alto
        return vector3(SITIO.x + dx / largo * lejos, SITIO.y + dy / largo * lejos, z + 0.05),
            vector3(SITIO.x, SITIO.y, z), 45.0
    end
    return vector3(CAMARA.x, CAMARA.y, CAMARA.z + tengo.alto), MIRA, 68.0
end

local function Pintar()
    if not camara or not entidad or not DoesEntityExist(entidad) then return end
    local pos, mira, fov = Encuadre()
    SetCamCoord(camara, pos.x, pos.y, pos.z)
    PointCamAtCoord(camara, mira.x, mira.y, mira.z)
    SetCamFov(camara, Limitar(fov - (tengo.zoom - 1.0) * ((tipo == 'mascota' and 11.0) or ((tipo == 'ropa' or tipo == 'tatuaje') and 16.0) or 18.0), 12.0, 75.0))
    SetEntityHeading(entidad, (SITIO.w + tengo.giro) % 360.0)
end

--- Monta el producto en el estudio. Devuelve true, o false y el motivo.
function Escaparate.Abrir(que, modelo, extra)
    if type(modelo) ~= 'string' or modelo == '' then return false, 'Ese modelo no existe.' end
    -- La ropa no trae modelo sino el código de la prenda: se la pone un doble del personaje
    local prenda = que == 'ropa' and modelo or nil
    -- Un tatuaje tampoco: trae sus decoraciones y su vista, y va sobre el mismo doble
    local tatu = que == 'tatuaje' and type(extra) == 'table' and extra or nil
    if que == 'tatuaje' then
        if not tatu then return false, 'Ese tatuaje no existe.' end
        -- el pack es otro recurso y puede no estar: sin él no hay nada que pintar
        if GetResourceState('origen_tatuajes') ~= 'started' then return false, 'Los tatuajes no están cargados en este servidor ahora mismo.' end
        -- Ya hay un doble con esa misma figura: solo cambia el acabado, la cámara se queda donde esté
        if tipo == 'tatuaje' and camara and entidad and DoesEntityExist(entidad) and tatuajeVisto == tatu.figura then
            Tatuar(entidad, tatu)
            return true
        end
    end
    local hash = (prenda or tatu) and GetEntityModel(cache.ped) or joaat(modelo)
    if not IsModelInCdimage(hash) then return false, 'Este modelo no está cargado en este servidor: no se puede enseñar en 3D.' end
    if que == 'vehiculo' and not IsModelAVehicle(hash) then return false, 'Ese modelo no es un vehículo.' end
    if que == 'mascota' and not IsModelAPed(hash) then return false, 'Ese modelo no es un animal.' end

    turno = turno + 1
    local mio = turno

    -- El estudio está lejos del jugador: hay que traerlo a memoria antes de montar nada
    SetFocusPosAndVel(SITIO.x, SITIO.y, SITIO.z, 0.0, 0.0, 0.0)
    RequestCollisionAtCoord(SITIO.x, SITIO.y, SITIO.z)

    if not Cargar(hash) or mio ~= turno then
        SetModelAsNoLongerNeeded(hash)
        if mio == turno and not camara then ClearFocus() end
        return false, mio == turno and 'No se ha podido cargar el modelo.' or nil
    end

    Borrar()
    tipo = que

    if que == 'vehiculo' then
        entidad = CreateVehicle(hash, SITIO.x, SITIO.y, SITIO.z, SITIO.w, false, false)
    elseif que == 'tatuaje' then
        local hay, z = GetGroundZFor_3dCoord(SITIO.x, SITIO.y, SITIO.z + 1.0, false)
        suelo = hay and (z + 0.0) or (SITIO.z - 0.5)
        -- Un doble LOCAL del personaje (su cuerpo, su cara, su pelo), en ropa interior y con el tatuaje.
        -- Al personaje de verdad no se le toca nada: al cerrar se borra el doble y ya.
        entidad = ClonePed(cache.ped, false, false, true)
        if entidad and entidad ~= 0 then
            SetEntityCoords(entidad, SITIO.x, SITIO.y, suelo, false, false, false, false)
            SetEntityHeading(entidad, SITIO.w)
            Desvestir(entidad)
            Tatuar(entidad, tatu)
            tatuajeVisto = tatu.figura
        end
    elseif que == 'ropa' then
        local hay, z = GetGroundZFor_3dCoord(SITIO.x, SITIO.y, SITIO.z + 1.0, false)
        suelo = hay and (z + 0.0) or (SITIO.z - 0.5)
        -- Un doble LOCAL del personaje, con su cara y lo que lleva puesto, y encima la prenda
        entidad = ClonePed(cache.ped, false, false, true)
        if entidad and entidad ~= 0 then
            SetEntityCoords(entidad, SITIO.x, SITIO.y, suelo, false, false, false, false)
            SetEntityHeading(entidad, SITIO.w)
            local hueco = tonumber(prenda:match('^.-%-%-(%d+)%-%-'))
            if hueco and hueco >= 1000 then
                exports.origen_clothing:SetPedPropByHash(entidad, prenda)
            else
                exports.origen_clothing:SetPedDrawableByHash(entidad, prenda)
            end
        end
    else
        local hay, z = GetGroundZFor_3dCoord(SITIO.x, SITIO.y, SITIO.z + 1.0, false)
        suelo = hay and (z + 0.0) or (SITIO.z - 0.5)
        entidad = CreatePed(28, hash, SITIO.x, SITIO.y, suelo, SITIO.w, false, false)
    end
    SetModelAsNoLongerNeeded(hash)

    if not entidad or entidad == 0 or not DoesEntityExist(entidad) then
        entidad = nil
        if not camara then ClearFocus() end
        return false, 'No se ha podido montar.'
    end

    SetEntityAsMissionEntity(entidad, true, true)
    SetEntityCollision(entidad, false, false)
    SetEntityInvincible(entidad, true)
    if que == 'vehiculo' then
        SetEntityCoordsNoOffset(entidad, SITIO.x, SITIO.y, SITIO.z, false, false, false)
        -- Una moto o un coche bajo quedarían flotando a la altura de un turismo: al suelo
        SetVehicleOnGroundProperly(entidad)
        SetVehicleDirtLevel(entidad, 0.0)
        SetVehicleEngineOn(entidad, false, true, true)
        SetVehicleHandbrake(entidad, true)
        SetVehicleDoorsLocked(entidad, 2)
        SetVehicleNumberPlateText(entidad, OrigenMarca == 'nacion' and 'NACION' or 'ORIGEN')
    elseif que == 'ropa' or que == 'tatuaje' then
        SetBlockingOfNonTemporaryEvents(entidad, true)
        SetPedCanRagdoll(entidad, false)
        TaskStandStill(entidad, -1)
    else
        -- El aspecto de serie, nunca el que el juego sortea al crearla (puede salir con una textura que el pack no trae)
        SetPedDefaultComponentVariation(entidad)
        SetBlockingOfNonTemporaryEvents(entidad, true)
        SetPedCanRagdoll(entidad, false)
        TaskStandStill(entidad, -1)
    end
    FreezeEntityPosition(entidad, true)

    quiero.giro, quiero.zoom, quiero.alto = GIRO_ENTRADA, ZOOM_ENTRADA, 0.0
    tengo.giro, tengo.zoom, tengo.alto = GIRO_ENTRADA, ZOOM_ENTRADA, 0.0
    if que == 'ropa' then
        -- de frente y entera: es a ella a quien se mira, no a un coche de tres cuartos
        quiero.giro, quiero.zoom, tengo.giro, tengo.zoom = 0.0, 1.7, 0.0, 1.7
    end
    if tatu then
        -- mirando al sitio del tatuaje: de espaldas, de frente, de lado o en primer plano (catalogo/tatuajes.lua: sitios)
        local v = type(tatu.vista) == 'table' and tatu.vista or {}
        local giro = (tonumber(v.giro) or 0.0) + 0.0
        local zoom = Limitar((tonumber(v.zoom) or 2.2) + 0.0, ZOOM_MIN, ZOOM_MAX)
        local alto = Limitar((tonumber(v.alto) or 0.0) + 0.0, -0.9, 0.9)
        quiero.giro, quiero.zoom, quiero.alto = giro, zoom, alto
        tengo.giro, tengo.zoom, tengo.alto = giro, zoom, alto
    end

    if not camara then
        camara = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
        Pintar()
        SetCamActive(camara, true)
        RenderScriptCams(true, false, 0, true, true)

        -- El giro y el zoom llegan a saltos desde la interfaz: aquí se suavizan
        CreateThread(function()
            while camara do
                if entidad and DoesEntityExist(entidad) then
                    tengo.giro = tengo.giro + (quiero.giro - tengo.giro) * 0.25
                    tengo.zoom = tengo.zoom + (quiero.zoom - tengo.zoom) * 0.2
                    tengo.alto = tengo.alto + (quiero.alto - tengo.alto) * 0.2
                    Pintar()
                end
                Wait(0)
            end
        end)
    else
        Pintar()
    end

    return true
end

--- Lo que pide el ratón: grados de giro acumulados, zoom y altura de la cámara.
function Escaparate.Mover(datos)
    if not camara or type(datos) ~= 'table' then return end
    local giro, zoom, alto = tonumber(datos.giro), tonumber(datos.zoom), tonumber(datos.alto)
    if giro and giro == giro then quiero.giro = Limitar(giro, -100000.0, 100000.0) + 0.0 end
    if zoom and zoom == zoom then quiero.zoom = Limitar(zoom, ZOOM_MIN, ZOOM_MAX) + 0.0 end
    if alto and alto == alto then
        if tipo == 'ropa' or tipo == 'tatuaje' then
            quiero.alto = Limitar(alto, -0.9, 0.9) + 0.0
        else
            quiero.alto = Limitar(alto, -0.4, tipo == 'mascota' and 1.2 or 2.5) + 0.0
        end
    end
end

AddEventHandler('onResourceStop', function(recurso)
    if recurso == GetCurrentResourceName() then Escaparate.Cerrar() end
end)
