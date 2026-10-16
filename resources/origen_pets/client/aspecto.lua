--[[ ── Mascotas · el aspecto ────────────────────────────────────────────────

     Un ped recien creado sale con una textura AL AZAR en cada pieza (cabeza,
     cuerpo, accesorio...). En los perros de GTA eso es un pelaje u otro; en los
     del pack de animales mezcla diseños que no van juntos --la cabeza de uno,
     el chaleco de otro-- y, peor, algunos .ymt declaran texturas o piezas cuyo
     fichero no viene en el pack. Si el azar cae ahi, el perro sale con la
     textura rota.

     Asi que el aspecto ya no se deja al azar: lo elige el jugador al comprarla,
     viendola delante, se guarda con la mascota y se pone igual cada vez que
     sale. Una mascota sin aspecto guardado sale con el de serie.

     Lo que se puede elegir sale de dos sitios:
       - Los modelos del pack: shared/texturas.lua, sacado de los FICHEROS que
         hay de verdad (ver herramientas/texturas.py). El .ymt no vale: miente.
       - Los de GTA, que no estan ahi: lo que diga el juego.

     El aspecto viaja como una lista de { pieza, drawable, textura }. ]]

Aspecto = {}

--- Como se llama cada pieza en la tienda. Son los huecos de ropa de un ped;
--- en un animal el 0 es casi siempre el cuerpo entero con su pelaje.
local NOMBRES = {
    [0] = 'Pelaje', [1] = 'Complemento', [2] = 'Pelo', [3] = 'Cuerpo',
    [4] = 'Patas', [5] = 'Manos', [6] = 'Pies', [7] = 'Dientes',
    [8] = 'Accesorio', [9] = 'Chaleco', [10] = 'Marcas', [11] = 'Ropa',
}

--[[ Las combinaciones que se pueden poner en ESTE ped, por pieza:
     { [pieza] = { {d, t}, {d, t}, ... } }, ordenadas de forma que la primera
     es la de serie (drawable 0, textura 0) cuando existe.

     Para los del pack se cruza la tabla de ficheros con lo que dice el juego:
     una textura que tiene fichero pero que el .ymt no declara tampoco se puede
     poner. ]]
function Aspecto.Piezas(ped, modelo)
    -- Los caballos, por la tabla revisada a mano en config_caballos.lua: su
    -- .ydd es de una pieza y texturas.py los da por «sin piezas sueltas».
    local nombre = string.lower(modelo or '')
    local tabla = Config.Caballos.Piezas[nombre]
    if tabla == nil then tabla = Texturas[nombre] end
    local piezas = {}

    -- Un modelo del pack sin piezas sueltas: solo tiene su aspecto de serie.
    if tabla == false then return piezas end

    for c = 0, 11 do
        local drawables = GetNumberOfPedDrawableVariations(ped, c)
        local lista = {}

        if tabla then
            local porDrawable = tabla[c]
            if porDrawable then
                local ds = {}
                for d in pairs(porDrawable) do ds[#ds + 1] = d end
                table.sort(ds)

                for _, d in ipairs(ds) do
                    if d < drawables then
                        local tope = GetNumberOfPedTextureVariations(ped, c, d)
                        for _, t in ipairs(porDrawable[d]) do
                            if t < tope then lista[#lista + 1] = { d, t } end
                        end
                    end
                end
            end
        else
            for d = 0, drawables - 1 do
                for t = 0, GetNumberOfPedTextureVariations(ped, c, d) - 1 do
                    if IsPedComponentVariationValid(ped, c, d, t) then
                        lista[#lista + 1] = { d, t }
                    end
                end
            end
        end

        if #lista > 0 then piezas[c] = lista end
    end

    return piezas
end

--- Pone un aspecto. Lo que no este en `aspecto`, o no se pueda poner en este
--- modelo, se queda en lo primero valido de su pieza --nunca al azar--.
--- Devuelve el aspecto que ha quedado puesto de verdad.
function Aspecto.Aplicar(ped, modelo, aspecto)
    SetPedDefaultComponentVariation(ped)
    ClearAllPedProps(ped)

    local quiero = {}
    for _, x in ipairs(type(aspecto) == 'table' and aspecto or {}) do
        -- La primera de cada pieza, igual que al guardarla en el servidor.
        local c = type(x) == 'table' and tonumber(x[1])
        if c and not quiero[c] then quiero[c] = { tonumber(x[2]), tonumber(x[3]) } end
    end

    local puesto = {}
    for c, lista in pairs(Aspecto.Piezas(ped, modelo)) do
        local elegido = lista[1]
        local q = quiero[c]

        if q then
            for _, op in ipairs(lista) do
                if op[1] == q[1] and op[2] == q[2] then elegido = op break end
            end
        end

        SetPedComponentVariation(ped, c, elegido[1], elegido[2], 0)
        puesto[#puesto + 1] = { c, elegido[1], elegido[2] }
    end

    return puesto
end

-- ── La vista previa de la tienda ──────────────────────────────────────────

--[[ El perro que se ve en la tienda. Es SOLO de este cliente (sin red): nadie
     mas lo ve y no ocupa sitio en el servidor. Se planta delante del jugador,
     gira despacio y una camara lo encuadra a la izquierda, porque la tienda
     ocupa el canto derecho de la pantalla. ]]
local vista = { ped = nil, cam = nil, modelo = nil, raza = nil, piezas = {}, eleccion = {} }

--- Sube cada vez que se cierra la vista. VerRaza espera a que cargue el
--- modelo, y si mientras tanto se cerro la tienda, al volver lo ve cambiado y
--- no planta nada: si no, el perro y la camara se quedaban con la tienda ya
--- cerrada.
local turnoVista = 0

local function BorrarPedVista()
    if vista.ped and DoesEntityExist(vista.ped) then DeleteEntity(vista.ped) end
    vista.ped = nil
end

function Aspecto.CerrarVista()
    turnoVista = turnoVista + 1
    BorrarPedVista()

    if vista.cam then
        RenderScriptCams(false, true, 300, true, true)
        DestroyCam(vista.cam, false)
        vista.cam = nil
    end

    vista.modelo, vista.raza, vista.piezas, vista.eleccion = nil, nil, {}, {}
end

local function Encuadrar(ped, hash)
    local min, max = GetModelDimensions(hash)
    local tam = math.max(max.x - min.x, max.y - min.y, max.z - min.z, 0.6)

    local centro = GetEntityCoords(ped)
    local haciaMi = GetEntityCoords(cache.ped) - centro
    haciaMi = vec3(haciaMi.x, haciaMi.y, 0.0)
    haciaMi = #haciaMi > 0.01 and (haciaMi / #haciaMi) or vec3(0.0, -1.0, 0.0)

    -- La derecha de la camara, mirando hacia el perro.
    local derecha = vec3(haciaMi.y, -haciaMi.x, 0.0)

    local distancia = 1.3 + tam * 1.4
    local desde = centro + haciaMi * distancia + vec3(0.0, 0.0, 0.35 + tam * 0.35)
    -- Apuntar a la DERECHA del perro deja al perro a la izquierda de la
    -- pantalla, fuera de la columna de la tienda.
    local mira = centro + derecha * (distancia * 0.32) + vec3(0.0, 0.0, (max.z - min.z) * 0.15)

    if not vista.cam then
        vista.cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
        SetCamCoord(vista.cam, desde.x, desde.y, desde.z)
        PointCamAtCoord(vista.cam, mira.x, mira.y, mira.z)
        SetCamFov(vista.cam, 45.0)
        RenderScriptCams(true, true, 400, true, true)
    else
        SetCamCoord(vista.cam, desde.x, desde.y, desde.z)
        PointCamAtCoord(vista.cam, mira.x, mira.y, mira.z)
    end
end

--- Lo que necesita la tienda para pintar los selectores.
local function OpcionesParaNui()
    local salida = {}
    for c = 0, 11 do
        local lista = vista.piezas[c]
        -- Una pieza con una sola opcion no se elige: se pone y ya.
        if lista and #lista > 1 then
            salida[#salida + 1] = {
                pieza = c,
                nombre = NOMBRES[c] or ('Pieza ' .. c),
                total = #lista,
                actual = vista.eleccion[c] or 1,
            }
        end
    end
    return salida
end

local function PonerEleccion()
    if not vista.ped then return end
    for c, lista in pairs(vista.piezas) do
        local op = lista[vista.eleccion[c] or 1] or lista[1]
        SetPedComponentVariation(vista.ped, c, op[1], op[2], 0)
    end
end

--- Saca en la tienda el perro de una raza. nil = quitarlo.
function Aspecto.VerRaza(clave)
    if not clave then
        Aspecto.CerrarVista()
        return { opciones = {} }
    end

    local raza = Mascotas.Raza(clave)
    if not raza or not raza.modelo then return { opciones = {}, error = true } end

    local turno = turnoVista
    local hash = Mascotas.CargarModelo(raza.modelo)

    -- Cerraron la tienda mientras cargaba: nada que plantar.
    if turno ~= turnoVista then
        if hash then SetModelAsNoLongerNeeded(hash) end
        return { opciones = {} }
    end

    if not hash then
        BorrarPedVista()
        return { opciones = {}, error = true }
    end

    BorrarPedVista()

    local delante = GetOffsetFromEntityInWorldCoords(cache.ped, 0.0, 2.4, 0.0)
    local ok, suelo = GetGroundZFor_3dCoord(delante.x, delante.y, delante.z + 1.5, false)
    local z = ok and suelo or (GetEntityCoords(cache.ped).z - 1.0)

    -- El origen de un ped esta en la cadera, no en los pies: congelado a ras
    -- de suelo se quedaria medio enterrado.
    local min = GetModelDimensions(hash)
    z = z - min.z

    local ped = CreatePed(28, hash, delante.x, delante.y, z, GetEntityHeading(cache.ped) + 180.0, false, false)
    SetModelAsNoLongerNeeded(hash)

    if ped == 0 then return { opciones = {}, error = true } end

    SetEntityInvincible(ped, true)
    FreezeEntityPosition(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedCanRagdoll(ped, false)
    SetEntityCoordsNoOffset(ped, delante.x, delante.y, z, false, false, false)

    vista.ped, vista.modelo, vista.raza = ped, raza.modelo, clave
    vista.piezas = {}
    vista.eleccion = {}

    Aspecto.Aplicar(ped, raza.modelo, nil)
    vista.piezas = Aspecto.Piezas(ped, raza.modelo)
    for c in pairs(vista.piezas) do vista.eleccion[c] = 1 end

    Encuadrar(ped, hash)

    -- Que gire despacio para verlo por todos lados.
    CreateThread(function()
        local propio = ped
        while vista.ped == propio and DoesEntityExist(propio) do
            SetEntityHeading(propio, (GetEntityHeading(propio) + 0.4) % 360.0)
            Wait(0)
        end
    end)

    return { opciones = OpcionesParaNui() }
end

--- Pasar a la opcion `indice` (desde 1) de una pieza.
function Aspecto.Cambiar(pieza, indice)
    local lista = vista.piezas[pieza]
    if not lista then return { opciones = OpcionesParaNui() } end

    indice = math.floor(tonumber(indice) or 1)
    if indice < 1 then indice = #lista end
    if indice > #lista then indice = 1 end

    vista.eleccion[pieza] = indice
    PonerEleccion()

    return { opciones = OpcionesParaNui() }
end

--- El aspecto elegido en la tienda, si es de esa raza. nil si no hay vista.
function Aspecto.Elegido(clave)
    if not vista.raza or vista.raza ~= clave then return nil end

    local salida = {}
    for c, lista in pairs(vista.piezas) do
        local op = lista[vista.eleccion[c] or 1] or lista[1]
        salida[#salida + 1] = { c, op[1], op[2] }
    end
    return salida
end

AddEventHandler('onResourceStop', function(recurso)
    if recurso ~= GetCurrentResourceName() then return end
    Aspecto.CerrarVista()
end)
