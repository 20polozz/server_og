--[[ ── Afinar la caja de la plataforma ────────────────────────────────────────

     Las poses de la caja movil —metida, sacada hacia atras y tumbada— y el
     hueco donde queda el coche encima no se pueden sacar a ojo desde fuera
     del juego. Con /gruaajuste (solo admins) se mueven en vivo con el
     teclado numerico y, al terminar, salen por consola (F8) en el mismo
     formato de shared/config.lua, listas para pegar.

         4 / 6   izquierda / derecha      8 / 5   adelante / atras
         7 / 9   abajo / arriba           1 / 3   inclinar
         0       cambiar de pose          Mayus   paso fino
         Intro   terminar

     La caja se va colocando donde la dejas, para verla mientras. ]]

local POSES = { 'puesta', 'atras', 'bajada', 'coche' }

local ajustando = false

--[[ Antes se pintaba con DrawText de GTA. Ahora las teclas van en la barra
     de origen_hud y las medidas de la pose elegida en el aviso de
     origen_notify; las dos cosas se mandan solo cuando cambian (las medidas,
     como mucho cada 150 ms). ]]
local barraPose, datosPuestos, datosCuando = nil, nil, 0

local function Barra(pose)
    if barraPose == pose or GetResourceState('origen_hud') ~= 'started' then return end
    barraPose = pose
    exports.origen_hud:setupControls({
        { key = '4 / 6', text = 'Eje X' },
        { key = '8 / 5', text = 'Eje Y' },
        { key = '7 / 9', text = 'Eje Z' },
        { key = '1 / 3', text = 'Inclinar' },
        { key = '0', text = 'Pose: ' .. pose },
        { key = 'SHIFT', text = 'Paso fino' },
        { key = 'ENTER', text = 'Terminar' },
    })
end

local function Datos(texto)
    local ahora = GetGameTimer()
    if ahora - datosCuando < 150 then return end
    datosCuando = ahora
    if texto == datosPuestos or GetResourceState('origen_notify') ~= 'started' then return end
    datosPuestos = texto
    exports.origen_notify:DrawText('', texto)
end

local function QuitarAyuda()
    if barraPose and GetResourceState('origen_hud') == 'started' then exports.origen_hud:hideControls() end
    if datosPuestos and GetResourceState('origen_notify') == 'started' then exports.origen_notify:HideText() end
    barraPose, datosPuestos, datosCuando = nil, nil, 0
end

RegisterNetEvent('origen_tow:cliente:ajustar', function()
    if ajustando then
        ajustando = false
        return
    end

    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    local grua, ficha

    for _, veh in ipairs(GetGamePool('CVehicle')) do
        local f = Tow.Ficha(GetEntityModel(veh))
        if f and f.tipo == 'plataforma' and f.caja and #(pos - GetEntityCoords(veh)) <= 20.0 then
            grua, ficha = veh, f
            break
        end
    end

    if not grua then
        return lib.notify({ description = 'No hay ninguna plataforma de caja movil cerca.', type = 'error' })
    end

    local gruaNet = NetworkGetNetworkIdFromEntity(grua)

    -- Copia de trabajo: no tocamos la config de verdad.
    local c = ficha.caja
    local valores = {
        puesta = { pos = c.puesta.pos, rot = c.puesta.rot },
        atras  = { pos = c.atras.pos,  rot = c.atras.rot },
        bajada = { pos = c.bajada.pos, rot = c.bajada.rot },
        coche  = { pos = c.coche,      rot = vec3(0.0, 0.0, 0.0) },
    }

    local cual = 1
    local modelo = GetLabelText(GetDisplayNameFromVehicleModel(GetEntityModel(grua)))
    ajustando = true
    lib.notify({ description = 'Ajuste de la caja abierto. Intro para terminar.', type = 'inform' })

    CreateThread(function()
        while ajustando do
            Wait(0)

            if not DoesEntityExist(grua) then break end

            local nombre = POSES[cual]
            local v = valores[nombre]
            local paso = IsRawKeyPressed(16) and 0.01 or 0.05   -- Mayus = fino

            local dx, dy, dz = 0.0, 0.0, 0.0
            if IsRawKeyPressed(100) then dx = -paso end
            if IsRawKeyPressed(102) then dx = paso end
            if IsRawKeyPressed(104) then dy = paso end
            if IsRawKeyPressed(101) then dy = -paso end
            if IsRawKeyPressed(103) then dz = -paso end
            if IsRawKeyPressed(105) then dz = paso end

            if dx ~= 0.0 or dy ~= 0.0 or dz ~= 0.0 then
                v.pos = vec3(v.pos.x + dx, v.pos.y + dy, v.pos.z + dz)
            end

            local dr = 0.0
            if IsRawKeyPressed(97) then dr = -0.3 end
            if IsRawKeyPressed(99) then dr = 0.3 end
            if dr ~= 0.0 then v.rot = vec3(v.rot.x + dr, v.rot.y, v.rot.z) end

            if IsRawKeyReleased(96) then cual = cual % #POSES + 1 end
            if IsRawKeyReleased(13) then ajustando = false end

            -- La caja, donde la estas dejando. Con el hueco del coche se
            -- queda tumbada, que es cuando se carga.
            local caja = Plataforma.Caja(gruaNet)
            if caja then
                local pose = nombre == 'coche' and valores.bajada or v
                Plataforma.FijarPose(gruaNet, { pos = pose.pos, rot = pose.rot })

                local _, remolque = Estado.RemolqueDe(grua)
                if remolque then
                    local coche = Estado.Ent(remolque.coche)
                    if coche then
                        Plataforma.PegarCocheEn(grua, ficha, coche, pose, valores.coche.pos, 0.0)
                    end
                end
            end

            Barra(nombre)
            Datos(('Caja de %s · %s: %.2f, %.2f, %.2f · inclina %.1f'):format(
                modelo, nombre, v.pos.x, v.pos.y, v.pos.z, v.rot.x))
        end

        ajustando = false
        QuitarAyuda()

        local texto = ([[

        caja = {
            prop = '%s',
            extra = %s,
            hueso = '%s',
            puesta = { pos = vec3(%.2f, %.2f, %.2f), rot = vec3(%.1f, 0.0, 0.0) },
            atras  = { pos = vec3(%.2f, %.2f, %.2f), rot = vec3(%.1f, 0.0, 0.0) },
            bajada = { pos = vec3(%.2f, %.2f, %.2f), rot = vec3(%.1f, 0.0, 0.0) },
            coche = vec3(%.2f, %.2f, %.2f),
        },
]]):format(
            c.prop, tostring(c.extra), c.hueso or 'chassis',
            valores.puesta.pos.x, valores.puesta.pos.y, valores.puesta.pos.z, valores.puesta.rot.x,
            valores.atras.pos.x, valores.atras.pos.y, valores.atras.pos.z, valores.atras.rot.x,
            valores.bajada.pos.x, valores.bajada.pos.y, valores.bajada.pos.z, valores.bajada.rot.x,
            valores.coche.pos.x, valores.coche.pos.y, valores.coche.pos.z)

        print('[origen_tow] Medidas para shared/config.lua:' .. texto)
        lib.notify({ description = 'Medidas en la consola (F8).', type = 'success' })
    end)
end)
