-- Colocar la casa de un vale (ver config/vales.lua y custom/server/vales.lua).
--
-- Lo llama la tienda desde «Mis cosas» → «Colocar mi casa», ya cerrada:
--     exports.origen_housing:ColocarCasa(idDelVale)
--
-- El jugador va andando al sitio. Abajo, la barra de teclas (nunca un panel):
-- Intro pone la entrada donde está, las flechas giran hacia dónde mira la
-- puerta y Esc lo deja. A sus pies, la marca: verde si ahí se puede, roja si
-- no, con el motivo en el título de la barra. Después se le pide el nombre y el
-- número de la casa con el diálogo del servidor (org-input).
--
-- Aquí solo se AVISA: lo que el cliente puede mirar (agua, interior, calzada,
-- suelo) y lo que contesta el servidor sobre el sitio. Quien decide es el
-- servidor, con las coordenadas que él ve del personaje.
local V = Config.Vales
local colocando = false

Vales = {}

local function Avisar(texto, tipo)
    if Internal and Internal.Notify then return Internal.Notify(texto, tipo or 'error', 6000) end
    lib.notify({ description = texto, type = tipo or 'error' })
end

--- Lo que el cliente ve del sitio: true y la altura del suelo, o false y el motivo
local function SitioLocal(ped, c)
    if IsEntityDead(ped) or IsPedDeadOrDying(ped, true) then return false, 'Así no puedes colocar tu casa' end
    if IsPedInAnyVehicle(ped, true) then return false, 'Bájate del vehículo: la casa se coloca a pie' end
    if GetInteriorFromEntity(ped) ~= 0 then return false, 'Dentro de un interior no: sal a la calle' end
    if IsPedSwimming(ped) or IsEntityInWater(ped) then return false, 'En el agua no se puede construir' end
    if IsPedFalling(ped) or IsPedRagdoll(ped) or IsPedJumping(ped) or IsPedClimbing(ped) or IsEntityInAir(ped) then
        return false, 'Ponte de pie en suelo firme'
    end
    local hay, suelo = GetGroundZFor_3dCoord(c.x, c.y, c.z + 0.5, false)
    if not hay or math.abs((c.z - 1.0) - suelo) > 0.6 then return false, 'Ahí no hay suelo firme' end
    if c.z < V.zMin or c.z > V.zMax then return false, 'Ahí no se puede construir' end
    if IsPointOnRoad(c.x, c.y, c.z, 0) then return false, 'En mitad de la calzada no: súbete a la acera' end

    for _, zona in ipairs(V.zonasProhibidas or {}) do
        local zx, zy, radio = tonumber(zona.x), tonumber(zona.y), tonumber(zona.radio)
        if zx and zy and radio then
            local dz = tonumber(zona.z) and (zona.z - c.z) or 0.0
            if (zx - c.x) ^ 2 + (zy - c.y) ^ 2 + dz ^ 2 < radio ^ 2 then
                return false, ('Demasiado cerca de %s: aquí no se pueden poner casas'):format(zona.nombre or 'una zona protegida')
            end
        end
    end

    -- Las casas que este cliente conoce (el servidor mira además garajes, entradas de garaje y hoteles)
    local minimo = V.distanciaMinima
    for _, house in pairs((House and House.table) or {}) do
        local e = house.houseData and house.houseData.positions and house.houseData.positions.entry
        if type(e) == 'table' or type(e) == 'vector3' or type(e) == 'vector4' then
            local x, y, z = tonumber(e.x), tonumber(e.y), tonumber(e.z)
            if x and y and z and (x - c.x) ^ 2 + (y - c.y) ^ 2 + (z - c.z + 1.0) ^ 2 < minimo ^ 2 then
                return false, ('Hay otra casa a menos de %d m: aléjate un poco'):format(minimo)
            end
        end
    end
    return true, suelo
end

--- La marca del suelo: el redondel, la parcela (la zona exterior que tendrá la casa) y la flecha de la puerta
local function Marca(c, suelo, rumbo, vale)
    local r, g, b = 220, 50, 50
    if vale then r, g, b = 60, 200, 90 end
    local z = suelo + 0.04
    DrawMarker(1, c.x, c.y, suelo - 0.02, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.3, 1.3, 0.12, r, g, b, 130, false, false, 2, false, nil, nil, false)

    local m = V.exterior.medio
    local x1, x2, y1, y2 = c.x - m, c.x + m, c.y - m, c.y + m
    DrawLine(x1, y1, z, x2, y1, z, r, g, b, 220)
    DrawLine(x2, y1, z, x2, y2, z, r, g, b, 220)
    DrawLine(x2, y2, z, x1, y2, z, r, g, b, 220)
    DrawLine(x1, y2, z, x1, y1, z, r, g, b, 220)

    -- hacia dónde mira quien sale por la puerta (rumbo 0 = norte, +Y)
    local a = math.rad(rumbo)
    local dx, dy = -math.sin(a), math.cos(a)
    local px, py = c.x + dx * 1.6, c.y + dy * 1.6
    local zf = z + 0.06
    DrawLine(c.x, c.y, zf, px, py, zf, 255, 255, 255, 255)
    DrawLine(px, py, zf, px - dx * 0.45 - dy * 0.3, py - dy * 0.45 + dx * 0.3, zf, 255, 255, 255, 255)
    DrawLine(px, py, zf, px - dx * 0.45 + dy * 0.3, py - dy * 0.45 - dx * 0.3, zf, 255, 255, 255, 255)
end

local function Barra(titulo)
    Nui.ControlsNotify({ title = titulo, keys = {
        { key = 'enter', text = 'Poner aquí la entrada' },
        { key = 'fizquierda', text = 'Girar la puerta' },
        { key = 'fderecha', text = 'Girar la puerta' },
        { key = 'ESC', text = 'Cancelar' },
    } })
end

local function Calle(c)
    local hash = GetStreetNameAtCoord(c.x, c.y, c.z)
    local nombre = hash and hash ~= 0 and GetStreetNameFromHashKey(hash) or ''
    return V.CalleLimpia(nombre)
end

--- Pide el nombre y el número con el diálogo del servidor. Devuelve { nombre, numero } o nil si se cancela.
local function PedirDatos(calle, nombre, numero, nombreTamano)
    local titulo = ('Casa %s en %s'):format(nombreTamano, calle)
    local textoNombre = ('Nombre de la casa (de %d a %d letras)'):format(V.nombre.min, V.nombre.max)
    local textoNumero = ('Número de la casa en %s'):format(calle)
    if GetResourceState('org-input') == 'started' then
        local r = exports['org-input']:ShowInput({
            header = titulo, submitText = 'Crear mi casa', icon = 'fa-solid fa-house',
            inputs = {
                { type = 'text', name = 'nombre', text = textoNombre, default = nombre ~= '' and nombre or nil, isRequired = true },
                { type = 'number', name = 'numero', text = textoNumero, default = numero, isRequired = true },
            },
        })
        if type(r) ~= 'table' then return nil end
        return { nombre = tostring(r.nombre or ''), numero = r.numero }
    end
    local r = lib.inputDialog(titulo, {
        { type = 'input', label = textoNombre, default = nombre ~= '' and nombre or nil, required = true },
        { type = 'number', label = textoNumero, default = numero, required = true, min = V.numero.min, max = V.numero.max },
    })
    if type(r) ~= 'table' then return nil end
    return { nombre = tostring(r[1] or ''), numero = r[2] }
end

--- Pregunta al servidor por el sitio, reintentando una vez si dice que espere
local function Preguntar(datos)
    for _ = 1, 3 do
        local r = lib.callback.await('origen_housing:vales:comprobar', 5000, datos)
        if type(r) ~= 'table' then return { ok = false, msg = 'El servidor no contesta' } end
        if not r.espera then return r end
        Wait((V.ritmoComprobar or 350) + 60)
    end
    return { ok = false, msg = 'El servidor no contesta' }
end

--- El paso del nombre y el número, y el alta. Devuelve 'hecho', 'sitio' (volver a elegir sitio) o 'fuera' (cerrar).
local function Confirmar(sesion, c, suelo, rumbo)
    local calle = Calle(c)
    local r = Preguntar({ z = suelo, calle = calle })
    if not r.ok then
        Avisar(r.msg or 'Ahí no se puede')
        return r.cerrar and 'fuera' or 'sitio'
    end
    calle = r.calle or calle
    local nombre, numero = sesion.nombre or '', r.numero or 1
    local ultimo = 0

    while true do
        local datos = PedirDatos(calle, nombre, numero, sesion.nombreTamano)
        if not datos then return 'sitio' end        -- cancelar el diálogo vuelve a la marca
        nombre = datos.nombre
        sesion.nombre = nombre

        -- Lo mismo que mirará el servidor, para avisar antes
        local limpio, porNombre = V.NombreLimpio(datos.nombre)
        local n, porNumero = V.NumeroLimpio(datos.numero)
        if not limpio then
            Avisar(porNombre)
        elseif not n then
            Avisar(porNumero)
        else
            numero = n
            -- (el servidor no admite dos intentos seguidos del mismo jugador)
            local espera = (V.ritmoColocar or 3000) + 200 - (GetGameTimer() - ultimo)
            if ultimo > 0 and espera > 0 then Wait(espera) end
            ultimo = GetGameTimer()
            local res = lib.callback.await('origen_housing:vales:colocar', 20000, { nombre = limpio, numero = n, calle = calle, rumbo = rumbo, z = suelo })
            if type(res) ~= 'table' then
                Avisar('El servidor no ha contestado. Mira en el mapa si tu casa ya está antes de repetirlo.')
                return 'fuera'
            end
            if res.ok then
                Avisar(res.msg or 'Tu casa ya está en el mapa', 'success')
                return 'hecho'
            end
            Avisar(res.msg or 'No se ha podido colocar la casa')
            if res.cerrar then return 'fuera' end
            if res.campo == 'numero' and res.numero then numero = res.numero end
            if res.campo ~= 'nombre' and res.campo ~= 'numero' then return 'sitio' end
        end
    end
end

function Vales.Colocar(id)
    if colocando then return Avisar('Ya estás colocando una casa', 'info') end
    if type(id) ~= 'string' then return end
    colocando = true
    CreateThread(function()
        Wait(350)       -- la tienda suelta antes el ratón
        local sesion = lib.callback.await('origen_housing:vales:abrir', 8000, id)
        if type(sesion) ~= 'table' or not sesion.ok then
            colocando = false
            return Avisar((type(sesion) == 'table' and sesion.msg) or 'No se ha podido abrir el configurador')
        end

        local titulo = ('Colocar mi casa · %s'):format(sesion.nombreTamano or '')
        local giro = 0.0                -- lo que se ha girado la puerta respecto a donde mira el jugador
        local visto = nil               -- el último título puesto en la barra
        local servidor = { t = 0, x = 0.0, y = 0.0, z = 0.0, ok = false, msg = 'Comprobando el sitio…', pendiente = false }
        local ultimoNo = 0
        local salida = nil

        while colocando and not salida do
            local ped = PlayerPedId()
            local c = GetEntityCoords(ped)
            local rumbo = (GetEntityHeading(ped) + giro) % 360.0
            local vale, dato = SitioLocal(ped, c)
            local suelo = vale and dato or (c.z - 1.0)
            local motivo = not vale and dato or nil

            -- El servidor, cada medio segundo si se ha movido (y cada 2 s aunque no)
            if vale and not servidor.pendiente then
                local movido = (servidor.x - c.x) ^ 2 + (servidor.y - c.y) ^ 2 + (servidor.z - c.z) ^ 2 > 0.09
                local hace = GetGameTimer() - servidor.t
                if (movido and hace > 500) or hace > 2000 then
                    servidor.pendiente = true
                    local px, py, pz = c.x, c.y, c.z
                    CreateThread(function()
                        local r = lib.callback.await('origen_housing:vales:comprobar', 5000, { z = suelo })
                        servidor.pendiente = false
                        servidor.t = GetGameTimer()
                        if type(r) ~= 'table' or r.espera then return end
                        servidor.x, servidor.y, servidor.z = px, py, pz
                        servidor.ok, servidor.msg = r.ok == true, r.msg
                        if r.cerrar then
                            Avisar(r.msg or 'El configurador se ha cerrado')
                            salida = 'fuera'
                        end
                    end)
                end
            end
            if vale then
                -- lo que dijo el servidor vale mientras no se aleje un metro de donde se preguntó
                local lejos = (servidor.x - c.x) ^ 2 + (servidor.y - c.y) ^ 2 + (servidor.z - c.z) ^ 2 > 1.0
                if lejos then
                    vale, motivo = false, 'Comprobando el sitio…'
                elseif not servidor.ok then
                    vale, motivo = false, servidor.msg or 'Ahí no se puede'
                end
            end

            Marca(c, suelo, rumbo, vale)
            local rotulo = vale and (titulo .. ' · aquí se puede') or ('Aquí no: ' .. (motivo or 'no se puede'))
            if rotulo ~= visto then
                visto = rotulo
                Barra(rotulo)
            end

            DisableControlAction(0, 200, true)      -- Esc no abre el menú de pausa
            DisableControlAction(0, 174, true)      -- las flechas no mueven el móvil
            DisableControlAction(0, 175, true)
            if IsDisabledControlPressed(0, 174) then giro = (giro + 90.0 * GetFrameTime()) % 360.0 end
            if IsDisabledControlPressed(0, 175) then giro = (giro - 90.0 * GetFrameTime()) % 360.0 end

            if IsControlJustPressed(0, 191) then
                if vale then
                    Nui.ControlsNotify()
                    visto = nil
                    local que = Confirmar(sesion, c, suelo, rumbo)
                    if que ~= 'sitio' then salida = que end
                    servidor.t = 0
                elseif GetGameTimer() - ultimoNo > 1500 then
                    ultimoNo = GetGameTimer()
                    Avisar(motivo or 'Ahí no se puede', 'info')
                end
            elseif IsControlJustPressed(0, 202) or IsDisabledControlJustPressed(0, 200) then
                salida = 'cancelada'
            end
            Wait(0)
        end

        Nui.ControlsNotify()
        if salida ~= 'hecho' then TriggerServerEvent('origen_housing:vales:cerrar') end
        if salida == 'cancelada' then Avisar('Tu casa sigue por colocar: la tienes en «Mis cosas» de la tienda', 'info') end
        colocando = false
    end)
end

exports('ColocarCasa', function(id) return Vales.Colocar(id) end)

AddEventHandler('onResourceStop', function(recurso)
    if recurso == GetCurrentResourceName() then colocando = false end
end)
