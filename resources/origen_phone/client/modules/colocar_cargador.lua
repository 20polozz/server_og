--[[ ══════════════════════════════════════════════════════════════════════════
     MODO DE COLOCAR PUNTOS DE CARGA EN VIVO (Admin)

     Permite a un administrador colocar un punto de carga directamente en el
     mundo, viendo el prop antes de guardarlo:
       · Cierra el panel de administración
       · Enseña el prop como un FANTASMA semitransparente (sin colisión) que
         sigue a donde apunta la cámara
       · Las teclas salen en la ayuda de teclas del servidor
         (exports.origen_hud:setupControls)
       · Permite girar, ajustar altura y cambiar de prop [TAB]
       · Al pulsar [ENTER] guarda el punto CON SU RUMBO en la base de datos y
         lo activa en caliente para todos los jugadores, sin reiniciar
       · Con `replace` recoloca un punto que ya existe en vez de añadir otro
       · Reabre el panel de administración con el punto ya registrado

     04/10 (el usuario: «ya que tiene prop, quita el círculo del suelo y el
     blip ese volando, y usa ese prop … previsualizándolo»): el prop por
     defecto es el poste propio `prop_phone_charger`, el fantasma es
     transparente y ya no lleva el cilindro azul ni el galón encima.
    ══════════════════════════════════════════════════════════════════════════ ]]

--- El primero es el de siempre; con TAB se pasa por los demás.
local PROPS_DISPONIBLES = {
    'prop_phone_charger',
    'prop_payphone_01b',
    'prop_phonebox_01',
    'prop_atm_01',
    'prop_elecbox_01',
}

local colocando = nil

local function RotationToDirection(rot)
    local rx = math.rad(rot.x)
    local rz = math.rad(rot.z)
    return vec3(
        -math.sin(rz) * math.abs(math.cos(rx)),
         math.cos(rz) * math.abs(math.cos(rx)),
         math.sin(rx)
    )
end

local function RayCastCamera(distance)
    local camRot   = GetGameplayCamRot(2)
    local camCoord = GetGameplayCamCoord()
    local dir      = RotationToDirection(camRot)
    local dest     = camCoord + dir * distance
    local ray = StartShapeTestRay(camCoord.x, camCoord.y, camCoord.z, dest.x, dest.y, dest.z, -1, PlayerPedId(), 0)
    local _, hit, coords = GetShapeTestResult(ray)
    return hit == 1, coords
end

local function Suelo(x, y, z)
    local bien, alto = GetGroundZFor_3dCoord(x, y, z + 2.0, false)
    if bien then return alto end
    return z
end

--- El modelo que se va a pintar de verdad (entorno.lua): el poste si el punto
--- traía el de por defecto, la cabina si el recurso del poste no está.
local function NormalizarProp(modelo)
    local nombre = ModeloDeCargador(modelo)
    return nombre
end

--[[ La ayuda de teclas del servidor, la misma de los colocadores de negocios.
     Con pcall: si origen_hud no está arrancado no se va a quedar sin colocar. ]]
local function PonerAyuda(c)
    pcall(function()
        exports.origen_hud:setupControls({
            { key = 'ENTER', text = c.replace and 'Guardar el sitio nuevo' or 'Guardar el punto' },
            { key = 'ESC', text = 'Cancelar' },
            { key = 'Q / E', text = 'Girar' },
            { key = 'Rueda', text = 'Giro fino' },
            { key = 'Shift', text = 'Más despacio' },
            { key = '↑ / ↓', text = 'Altura' },
            { key = 'R', text = 'Altura a cero' },
            { key = 'Alt + Rueda', text = 'Distancia' },
            { key = 'TAB', text = ('Modelo: %s'):format(c.modelo) },
        })
    end)
end

local function QuitarAyuda()
    pcall(function() exports.origen_hud:hideControls() end)
end

local function CrearFantasma(modelo, initPos)
    local modeloValido = NormalizarProp(modelo)
    local hash = joaat(modeloValido)

    RequestModel(hash)
    local timer = GetGameTimer()
    while not HasModelLoaded(hash) and (GetGameTimer() - timer < 5000) do
        Wait(50)
    end
    if not HasModelLoaded(hash) then
        modeloValido = 'prop_payphone_01b'
        hash = joaat(modeloValido)
        RequestModel(hash)
        timer = GetGameTimer()
        while not HasModelLoaded(hash) and (GetGameTimer() - timer < 3000) do
            Wait(50)
        end
        if not HasModelLoaded(hash) then return nil, modeloValido end
    end

    local p = initPos or GetEntityCoords(PlayerPedId())
    local ent = CreateObject(hash, p.x, p.y, p.z, false, false, false)
    SetModelAsNoLongerNeeded(hash)
    if not ent or ent == 0 or not DoesEntityExist(ent) then return nil, modeloValido end

    -- Fantasma: se ve a través y no choca (ni con el jugador ni con el rayo)
    SetEntityAlpha(ent, 170, false)
    SetEntityCollision(ent, false, false)
    SetEntityInvincible(ent, true)
    FreezeEntityPosition(ent, true)
    return ent, modeloValido
end

local function Soltar()
    if colocando and colocando.ent and DoesEntityExist(colocando.ent) then
        DeleteEntity(colocando.ent)
    end
    colocando = nil
    QuitarAyuda()
    -- El prop del punto que se estaba recolocando vuelve a pintarse
    CargadorApartado = nil
end

local function Guardar()
    local c = colocando
    if not c or not c.listoParaGuardar then return end

    local datos = {
        x = math.floor(c.x * 1000) / 1000,
        y = math.floor(c.y * 1000) / 1000,
        z = math.floor(c.z * 1000) / 1000,
        h = math.floor((c.h % 360.0) * 10) / 10,
        prop = c.modelo,
        price = c.price or 0,
        exemptJobs = c.exemptJobs or '',
        -- Recolocar: qué punto de la lista y dónde estaba
        replace = c.replace,
        de = c.de,
    }

    local zona = GetLabelText(GetNameOfZone(datos.x, datos.y, datos.z))
    if not zona or zona == 'NULL' or zona == '' then zona = 'Ciudad' end
    datos.name = ('Punto de carga · %s'):format(zona)

    local recolocado = c.replace ~= nil
    Soltar()

    local res = lib.callback.await('origen_phone:admin:addCharger', false, datos)
    if res and res.ok then
        if res.settings then
            AjustesDelServidor = res.settings
            if PintarPuntosDeCarga then PintarPuntosDeCarga() end
            if ActualizarCargadoresEnMundo then ActualizarCargadoresEnMundo() end
        end
        PlaySoundFrontend(-1, 'CONFIRM_BEEP', 'HUD_MINI_GAME_SOUNDSET', true)
        lib.notify({
            title = 'Punto de carga',
            description = recolocado and 'Punto de carga recolocado.' or 'Punto de carga colocado y funcional en vivo.',
            type = 'success',
        })
    else
        lib.notify({
            title = 'Punto de carga',
            description = (res and res.error) or 'Error al guardar el punto de carga.',
            type = 'error',
        })
    end

    -- Reabrir el panel de administracion del telefono
    TriggerServerEvent('origen_phone:sv:openAdmin')
end

local function Cancelar()
    Soltar()
    PlaySoundFrontend(-1, 'CANCEL', 'HUD_MINI_GAME_SOUNDSET', true)
    lib.notify({
        title = 'Punto de carga',
        description = 'Colocación cancelada.',
        type = 'inform',
    })
    TriggerServerEvent('origen_phone:sv:openAdmin')
end

local function CambiarProp(c)
    local sig = (c.iProp or 1) + 1
    if sig > #PROPS_DISPONIBLES then sig = 1 end
    c.iProp = sig
    local nuevoModelo = PROPS_DISPONIBLES[sig]

    if c.ent and DoesEntityExist(c.ent) then
        DeleteEntity(c.ent)
    end
    c.ent = nil
    local nuevoEnt, modeloFinal = CrearFantasma(nuevoModelo, vector3(c.x, c.y, c.z))
    -- Mientras cargaba el modelo han podido cancelar: ese fantasma sobra
    if colocando ~= c then
        if nuevoEnt and DoesEntityExist(nuevoEnt) then DeleteEntity(nuevoEnt) end
        return
    end
    c.ent = nuevoEnt
    c.modelo = modeloFinal
    PonerAyuda(c)
end

function ColocarCargador(params)
    if colocando then return end

    CreateThread(function()
        Wait(200)
        if colocando then return end

        local ped = PlayerPedId()
        local p = GetEntityCoords(ped)
        local fwd = GetEntityForwardVector(ped)
        local initPos = vector3(p.x + fwd.x * 2.0, p.y + fwd.y * 2.0, p.z)

        local modeloDeseado = NormalizarProp(params and params.prop)

        local idxProp = 1
        for i, m in ipairs(PROPS_DISPONIBLES) do
            if m == modeloDeseado then idxProp = i break end
        end

        --[[ Recolocar uno que ya existe: llega su sitio en la lista (desde 1) y
             dónde está. Su prop se quita mientras se apunta (entorno.lua mira
             `CargadorApartado`), o el rayo chocaba con él y el fantasma se
             subía encima; y se empieza con el rumbo que ya tenía. ]]
        local replace, de, rumbo = nil, nil, (GetEntityHeading(ped) + 180.0) % 360.0
        local sitio = params and tonumber(params.replace)
        if sitio and type(params.de) == 'table' and tonumber(params.de.x) and tonumber(params.de.y) then
            replace = math.floor(sitio)
            de = { x = params.de.x + 0.0, y = params.de.y + 0.0, z = (tonumber(params.de.z) or 0) + 0.0 }
            if tonumber(params.h) then rumbo = (params.h + 0.0) % 360.0 end
            CargadorApartado = ('%.1f:%.1f:%.1f'):format(de.x, de.y, de.z)
            if ActualizarCargadoresEnMundo then ActualizarCargadoresEnMundo() end
        end

        local ent, modeloCargado = CrearFantasma(modeloDeseado, initPos)
        if not ent then
            CargadorApartado = nil
            lib.notify({
                title = 'Error',
                description = 'No se pudo cargar el modelo del prop: ' .. tostring(modeloDeseado),
                type = 'error',
            })
            TriggerServerEvent('origen_phone:sv:openAdmin')
            return
        end

        -- Dos pulsaciones seguidas: mientras cargaba el modelo ya hay otro
        -- colocando. Este fantasma sobra.
        if colocando then
            DeleteEntity(ent)
            return
        end

        colocando = {
            modelo = modeloCargado,
            iProp = idxProp,
            ent = ent,
            x = initPos.x,
            y = initPos.y,
            z = initPos.z,
            zOffset = 0.0,
            h = rumbo,
            distancia = 3.5,
            price = math.max(0, math.floor(tonumber(params and (params.price or params.precio)) or 0)),
            exemptJobs = params and (params.exemptJobs or params.exencionJobs) or '',
            replace = replace,
            de = de,
            listoParaGuardar = false,
        }

        PonerAyuda(colocando)

        -- Periodo de gracia de 350ms para evitar confirmar con el clic de la NUI
        local esta = colocando
        SetTimeout(350, function()
            if colocando == esta then
                colocando.listoParaGuardar = true
            end
        end)
    end)
end

CreateThread(function()
    while true do
        if not colocando then
            Wait(250)
        else
            Wait(0)
            local c = colocando
            if not c then goto fin_ciclo end

            -- Desactivar disparos y acciones conflictivas mientras se coloca
            DisableControlAction(0, 24, true)  -- Attack
            DisableControlAction(0, 25, true)  -- Aim
            DisableControlAction(0, 37, true)  -- Weapon Wheel (TAB)
            DisableControlAction(0, 44, true)  -- Cover (Q)
            DisableControlAction(0, 140, true) -- Melee Attack light
            DisableControlAction(0, 141, true) -- Melee Attack heavy
            DisableControlAction(0, 142, true) -- Melee Attack alternate
            DisableControlAction(0, 200, true) -- Pausa: el ESC cancela, no abre el mapa

            --[[ Q y TAB están desactivadas justo arriba (cobertura y rueda de
                 armas), y una tecla desactivada no la ve IsControlPressed:
                 hasta el 04/10 ni Q giraba ni TAB cambiaba el modelo. Se leen
                 con las IsDisabledControl*. ]]

            -- Distancia con ALT + rueda
            if IsControlPressed(0, 19) then -- Left ALT
                if IsControlJustPressed(0, 241) then c.distancia = math.min(20.0, c.distancia + 0.5) end
                if IsControlJustPressed(0, 242) then c.distancia = math.max(1.2, c.distancia - 0.5) end
            else
                -- Giro fino con rueda
                if IsControlJustPressed(0, 241) then c.h = (c.h + 3.0) % 360.0 end
                if IsControlJustPressed(0, 242) then c.h = (c.h - 3.0) % 360.0 end
            end

            -- Giro con Q y E
            local pasoGiro = IsControlPressed(0, 21) and 1.0 or 4.0 -- Shift para giro lento
            if IsDisabledControlPressed(0, 44) then c.h = (c.h + pasoGiro) % 360.0 end -- Q
            if IsControlPressed(0, 38) then c.h = (c.h - pasoGiro) % 360.0 end -- E

            -- Posición donde mira la cámara usando raycast
            local hit, hitCoords = RayCastCamera(c.distancia)
            if hit and hitCoords and hitCoords.x ~= 0.0 then
                c.x = hitCoords.x
                c.y = hitCoords.y
                c.z = hitCoords.z + (c.zOffset or 0.0)
            else
                -- Apuntando al aire: a esa distancia, de pie en el suelo
                local camRot = GetGameplayCamRot(2)
                local dir = RotationToDirection(camRot)
                local camCoord = GetGameplayCamCoord()
                local forwardPos = camCoord + dir * c.distancia
                c.x = forwardPos.x
                c.y = forwardPos.y
                c.z = Suelo(c.x, c.y, forwardPos.z) + (c.zOffset or 0.0)
            end

            -- Ajuste manual de altura con flechas
            local pasoZ = IsControlPressed(0, 21) and 0.01 or 0.05
            if IsControlPressed(0, 172) then -- Flecha arriba
                c.zOffset = (c.zOffset or 0.0) + pasoZ
            end
            if IsControlPressed(0, 173) then -- Flecha abajo
                c.zOffset = (c.zOffset or 0.0) - pasoZ
            end

            -- Altura a cero con R
            if IsControlJustPressed(0, 45) then -- R
                c.zOffset = 0.0
            end

            -- Actualizar entidad fantasma
            if c.ent and DoesEntityExist(c.ent) then
                SetEntityCoords(c.ent, c.x, c.y, c.z, false, false, false, false)
                SetEntityHeading(c.ent, c.h)
            end

            -- Cambiar prop con TAB. Va lo último del fotograma que toca al
            -- fantasma: espera a que cargue el modelo nuevo.
            if IsDisabledControlJustPressed(0, 37) then
                CambiarProp(c)
                if colocando ~= c then goto fin_ciclo end
            end

            -- Confirmar con ENTER (teclas 18 / 191 / 201) tras el período de gracia
            if c.listoParaGuardar and (IsControlJustPressed(0, 18) or IsControlJustPressed(0, 191) or IsControlJustPressed(0, 201)) then
                Guardar()
            elseif IsControlJustPressed(0, 177) or IsControlJustPressed(0, 194) or IsControlJustPressed(0, 202) or IsControlJustPressed(0, 322) then -- ESC o BACKSPACE
                Cancelar()
            end

            ::fin_ciclo::
        end
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then
        Soltar()
    end
end)

-- NUI Action llamada desde Admin.vue
Nui.On('adminColocarCargador', function(params)
    if CerrarAdmin then CerrarAdmin() end
    CreateThread(function()
        Wait(150)
        ColocarCargador(params)
    end)
    return { ok = true }
end)
