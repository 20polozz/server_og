--[[ ══════════════════════════════════════════════════════════════════════════
     EL MODO DE COLOCAR

     Es la mitad del recurso. Un administrador elige «mesa de ruleta» en el
     panel, el panel se cierra, y aparece una mesa fantasma delante que se
     mueve donde mira. Se gira, se sube, se baja y se confirma. Entonces se
     guarda una fila con sus coordenadas y esa mesa existe para todo el mundo.

     ── Por qué se pintan los asientos ──────────────────────────────────────

     Mientras se mueve la mesa se dibuja un muñeco en cada plaza. Sin eso, la
     mesa se coloca mirando la mesa —que siempre queda bien— y los asientos
     acaban dentro de una pared o encima de una escalera, y eso no se ve hasta
     que alguien se sienta y aparece flotando. Con los muñecos se ve antes de
     guardar, que es cuando se puede arreglar.

     ── El suelo ────────────────────────────────────────────────────────────

     La z se pega al suelo por defecto (`GetGroundZFor_3dCoord`), porque medir
     la altura a ojo es cómo acaban las mesas medio hundidas. En un interior
     con varias plantas el suelo de debajo puede ganar, y por eso se puede
     apagar con G y subir y bajar a mano.
   ══════════════════════════════════════════════════════════════════════════ ]]

local colocando = nil     -- { tipo, ent, x, y, z, h, pegarAlSuelo, editando }

local FANTASMA = { r = 216, g = 27, b = 85 }

-- ── Dibujar ───────────────────────────────────────────────────────────────

--[[ La ayuda ya no se pinta con DrawRect + DrawText de GTA: las teclas van en
     la barra de teclas del servidor (origen_hud) y los datos de la mesa (qué
     es, rumbo, altura, plazas) en el aviso de origen_notify. Las dos cosas se
     mandan a la interfaz solo cuando cambian, y los datos como mucho cada
     150 ms, que con el ratón la altura cambia cada fotograma. ]]
local barraPuesta = nil       -- el «sí»/«no» del suelo que lleva la barra
local datosPuestos, datosCuando = nil, 0

local function PintarAyuda(c)
    local suelo = c.pegarAlSuelo and 'sí' or 'no'
    if barraPuesta ~= suelo and GetResourceState('origen_hud') == 'started' then
        barraPuesta = suelo
        exports.origen_hud:setupControls({
            { key = 'Q / E', text = 'Girar' },
            { key = 'WHEEL', text = 'Girar fino' },
            { key = 'SHIFT', text = 'Paso corto' },
            { key = 'UP', text = 'Subir' },
            { key = 'DOWN', text = 'Bajar' },
            { key = 'G', text = 'Al suelo: ' .. suelo },
            { key = 'ALT', text = 'Con rueda: acercar' },
            { key = 'ENTER', text = 'Guardar' },
            { key = 'BACKSPACE', text = 'Dejarlo' },
        })
    end

    local ahora = GetGameTimer()
    if ahora - datosCuando < 150 then return end
    datosCuando = ahora
    local texto = ('Colocando %s · rumbo %.0f° · altura %.2f'):format(c.tipo.nombre, c.h, c.z)
    if #c.tipo.asientos > 0 then
        texto = texto .. (' · %d plazas en rosa'):format(#c.tipo.asientos)
    end
    if texto ~= datosPuestos and GetResourceState('origen_notify') == 'started' then
        datosPuestos = texto
        exports.origen_notify:DrawText('i', texto)
    end
end

local function QuitarAyuda()
    if barraPuesta and GetResourceState('origen_hud') == 'started' then
        exports.origen_hud:hideControls()
    end
    if datosPuestos and GetResourceState('origen_notify') == 'started' then
        exports.origen_notify:HideText()
    end
    barraPuesta, datosPuestos, datosCuando = nil, nil, 0
end

--- Un muñeco en cada plaza, para ver dónde va a acabar sentada la gente.
local function PintarAsientos(c)
    for i = 1, #c.tipo.asientos do
        local a = Casino.Asiento({ x = c.x, y = c.y, z = c.z, h = c.h }, c.tipo, i)
        if a then
            DrawMarker(23, a.x, a.y, a.z - 0.9, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                0.45, 0.45, 0.45, FANTASMA.r, FANTASMA.g, FANTASMA.b, 140,
                false, false, 2, false, nil, nil, false)
            -- La flecha dice hacia dónde mira quien se siente ahí.
            local rad = math.rad(a.h)
            DrawLine(a.x, a.y, a.z, a.x - math.sin(rad) * 0.7, a.y + math.cos(rad) * 0.7, a.z,
                FANTASMA.r, FANTASMA.g, FANTASMA.b, 200)
        end
    end
end

-- ── Dónde se pone ─────────────────────────────────────────────────────────

--[[ Un rayo desde la cámara hacia donde se mira. Lo que devuelve es el primer
     sitio sólido; si no toca nada, se queda a la distancia elegida en el aire,
     que es lo que hace falta para poner algo en un altillo. ]]
local function Mirando(distancia)
    local cam = GetGameplayCamCoord()
    local rot = GetGameplayCamRot(2)
    local r = math.rad(rot.z)
    local p = math.rad(rot.x)
    local dir = vec3(-math.sin(r) * math.cos(p), math.cos(r) * math.cos(p), math.sin(p))
    local fin = cam + dir * distancia

    local rayo = StartShapeTestRay(cam.x, cam.y, cam.z, fin.x, fin.y, fin.z, 1 | 16 | 256, cache.ped, 4)
    local _, toco, pos = GetShapeTestResult(rayo)
    if toco == 1 then return pos end
    return fin
end

local function Suelo(x, y, z)
    local bien, alto = GetGroundZFor_3dCoord(x, y, z + 1.5, false)
    if bien then return alto end
    return z
end

-- ── El fantasma ───────────────────────────────────────────────────────────

local function CrearFantasma(tipo)
    if not tipo.modelo then return nil end
    local hash = joaat(tipo.modelo)
    if not pcall(lib.requestModel, hash, 8000) then return nil end
    local ent
    if tipo.ped then
        ent = CreatePed(4, hash, 0.0, 0.0, 0.0, 0.0, false, false)
        SetBlockingOfNonTemporaryEvents(ent, true)
    else
        ent = CreateObject(hash, 0.0, 0.0, 0.0, false, false, false)
    end
    SetModelAsNoLongerNeeded(hash)
    SetEntityCollision(ent, false, false)
    SetEntityAlpha(ent, 180, false)
    SetEntityInvincible(ent, true)
    FreezeEntityPosition(ent, true)
    return ent
end

local function Soltar()
    if colocando and colocando.ent and DoesEntityExist(colocando.ent) then
        DeleteEntity(colocando.ent)
    end
    QuitarAyuda()
    colocando = nil
    C.colocando = false
end

-- ── Entrar y salir ────────────────────────────────────────────────────────

--[[ `existente` viene cuando se está MOVIENDO un punto que ya está puesto: se
     arranca donde está y al guardar se edita en vez de crear otro. ]]
function Colocar(tipoId, existente)
    if colocando then return end
    local tipo = Catalogo.Tipo(tipoId)
    if not tipo then
        C.Aviso(Config.General.nombre, 'Ese tipo de mesa no existe.', 'error')
        return
    end

    local p = GetEntityCoords(cache.ped)
    colocando = {
        tipo = tipo,
        ent = CrearFantasma(tipo),
        x = existente and existente.x or p.x,
        y = existente and existente.y or p.y,
        z = existente and existente.z or p.z,
        h = existente and existente.h or GetEntityHeading(cache.ped),
        distancia = 3.0,
        pegarAlSuelo = existente == nil,
        editando = existente,
    }
    C.colocando = true

    C.Aviso(Config.General.nombre,
        existente and 'Mueve la mesa y pulsa INTRO.' or 'Coloca la mesa y pulsa INTRO.', 'inform')
end

local function Guardar()
    local c = colocando
    local datos = {
        tipo = c.tipo.id,
        x = math.floor(c.x * 1000) / 1000,
        y = math.floor(c.y * 1000) / 1000,
        z = math.floor(c.z * 1000) / 1000,
        h = math.floor(c.h * 10) / 10,
    }
    local accion = 'crear'
    if c.editando then
        accion = 'editar'
        datos.id = c.editando.id
        datos.nombre = c.editando.nombre
        datos.plazas = c.editando.plazas
        datos.apuestaMin = c.editando.apuestaMin
        datos.apuestaMax = c.editando.apuestaMax
        datos.activo = c.editando.activo
        datos.ajustes = { sinProp = c.editando.sinProp, sinBlip = c.editando.sinBlip }
    end

    Soltar()
    local res = lib.callback.await('origen_casino:admin:punto', false, accion, datos)
    if res and res.ok then
        C.Aviso(Config.General.nombre, accion == 'crear' and 'Mesa puesta.' or 'Mesa movida.', 'success')
    else
        C.Aviso(Config.General.nombre, (res and res.mensaje) or 'No se ha podido guardar.', 'error')
    end
    VolverAlPanel()
end

-- ── El bucle ──────────────────────────────────────────────────────────────

CreateThread(function()
    while true do
        if not colocando then
            Wait(250)
        else
            Wait(0)
            local c = colocando

            -- Mientras se coloca, el juego no dispara ni cambia de arma.
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 37, true)
            DisableControlAction(0, 44, true)
            DisableControlAction(0, 38, true)

            -- Acercar y alejar con ALT pulsado.
            if IsControlPressed(0, 19) then
                if IsControlJustPressed(0, 241) then c.distancia = math.min(20.0, c.distancia + 0.5) end
                if IsControlJustPressed(0, 242) then c.distancia = math.max(1.0, c.distancia - 0.5) end
            else
                if IsControlJustPressed(0, 241) then c.h = (c.h + 1.0) % 360.0 end
                if IsControlJustPressed(0, 242) then c.h = (c.h - 1.0) % 360.0 end
            end

            local paso = IsControlPressed(0, 21) and 1.0 or 5.0
            if IsControlJustPressed(0, 44) then c.h = (c.h + paso) % 360.0 end
            if IsControlJustPressed(0, 38) then c.h = (c.h - paso) % 360.0 end

            local pos = Mirando(c.distancia)
            c.x, c.y = pos.x, pos.y
            if c.pegarAlSuelo then
                c.z = Suelo(pos.x, pos.y, pos.z)
            else
                c.z = pos.z
            end

            local fino = IsControlPressed(0, 21) and 0.01 or 0.05
            if IsControlPressed(0, 172) then c.z = c.z + fino c.pegarAlSuelo = false end
            if IsControlPressed(0, 173) then c.z = c.z - fino c.pegarAlSuelo = false end
            if IsControlJustPressed(0, 47) then c.pegarAlSuelo = not c.pegarAlSuelo end

            if c.ent and DoesEntityExist(c.ent) then
                SetEntityCoordsNoOffset(c.ent, c.x, c.y, c.z, false, false, false)
                SetEntityHeading(c.ent, c.h)
            else
                DrawMarker(23, c.x, c.y, c.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                    1.0, 1.0, 1.0, FANTASMA.r, FANTASMA.g, FANTASMA.b, 140,
                    false, false, 2, false, nil, nil, false)
            end

            PintarAsientos(c)
            PintarAyuda(c)

            if IsControlJustPressed(0, 191) or IsControlJustPressed(0, 201) then
                Guardar()
            elseif IsControlJustPressed(0, 194) or IsControlJustPressed(0, 202) then
                Soltar()
                C.Aviso(Config.General.nombre, 'Lo dejamos.', 'inform')
                VolverAlPanel()
            end
        end
    end
end)

AddEventHandler('onResourceStop', function(recurso)
    if recurso == GetCurrentResourceName() then Soltar() end
end)
