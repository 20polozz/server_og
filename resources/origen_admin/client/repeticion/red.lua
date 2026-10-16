--[[ ── Repeticion: el cliente ──────────────────────────────────────────

     Las dos puntas en el mismo fichero, porque todo cliente es las dos:

       - el que GRABA: contesta cuando el servidor le pide sus ultimos
         segundos;
       - el STAFF: pide desde la pestaña Espectar, guarda los clips que le
         llegan y los reproduce cuando se pulsa «Ver».

     Los clips se quedan aqui, en el cliente del staff: a la interfaz solo le
     llega el resumen (quien, cuanto dura, en que estado va). ]]

local clips = {}   -- id -> { id, estado, targetId, nombre, segundos, duracion, frames, clip, hora }
local orden = {}   -- ids de mas nuevo a mas viejo

local function Resumen()
    local lista = {}
    for _, id in ipairs(orden) do
        local c = clips[id]
        if c then
            lista[#lista + 1] = {
                id = c.id,
                estado = c.estado,
                targetId = c.targetId,
                nombre = c.nombre,
                segundos = c.segundos,
                duracion = c.duracion,
                frames = c.frames,
                motivo = c.motivo,
                hora = c.hora,
            }
        end
    end
    return lista
end

local function AvisarInterfaz()
    SendNUIMessage({ action = 'repeticion:lista', lista = Resumen() })
    TriggerEvent('origen_police:client:repeticionActualizada', Resumen())
end

local function Guardar(c)
    if not clips[c.id] then
        table.insert(orden, 1, c.id)
    end
    clips[c.id] = c

    -- Solo se guardan los ultimos: un clip de dos minutos ocupa lo suyo.
    while #orden > Config.Repeticion.clipsGuardados do
        local viejo = table.remove(orden)
        clips[viejo] = nil
    end
end

-- ── El que graba ─────────────────────────────────────────────────────

RegisterNetEvent('origen_admin:client:repeticionCaptura', function(id, segundos)
    local ok, paquete = pcall(RepWire.pack, tonumber(segundos) or 60)
    if not ok or not paquete then
        return TriggerServerEvent('origen_admin:server:repeticionVacia', id)
    end
    TriggerLatentServerEvent('origen_admin:server:repeticionDatos', 250000, id, paquete)
end)

CreateThread(function()
    if not Config.Repeticion.grabarSiempre then return end
    Wait(2000)
    RepRecorder.start()
end)

-- ── El staff ─────────────────────────────────────────────────────────

RegisterNUICallback('RepeticionPedir', function(data, cb)
    local r = lib.callback.await('origen_admin:server:repeticionPedir', false, tonumber(data.targetId), tonumber(data.segundos))
    if r and r.success then
        Guardar({
            id = r.id,
            estado = 'pidiendo',
            targetId = r.targetId,
            nombre = r.nombre,
            segundos = r.segundos,
            hora = GetCloudTimeAsInt(),
        })
        AvisarInterfaz()
    end
    cb(r or { success = false, message = 'Sin respuesta del servidor' })
end)

RegisterNUICallback('RepeticionLista', function(_, cb)
    cb(Resumen())
end)

RegisterNUICallback('RepeticionBorrar', function(data, cb)
    local id = tonumber(data.id)
    if id and clips[id] and clips[id].estado ~= 'pidiendo' then
        clips[id] = nil
        for i, v in ipairs(orden) do
            if v == id then table.remove(orden, i) break end
        end
    end
    AvisarInterfaz()
    cb('ok')
end)

--- «Ver»: la interfaz cierra el panel en cuanto le contestamos, y la
--- reproduccion arranca un poco despues para no pelear con ese cierre por
--- el foco. Al salir de ella se vuelve al panel, en esta pestaña.
RegisterNUICallback('RepeticionVer', function(data, cb)
    local c = clips[tonumber(data.id)]
    if not c or c.estado ~= 'lista' or not c.clip then
        return cb({ success = false, message = 'Esa repeticion ya no esta' })
    end
    if RepPlayback.active then
        return cb({ success = false, message = 'Ya hay una repeticion en marcha' })
    end

    cb({ success = true })

    SetTimeout(350, function()
        RepPlayback.label = ('%s [%d]'):format(c.nombre or '?', c.targetId or 0)
        RepPlayback.alTerminar = function()
            if AbrirPanelAdminEn then AbrirPanelAdminEn('spectate') end
        end
        RepPlayback.start(c.clip, ('p%d'):format(c.targetId or 0))
    end)
end)

RegisterNetEvent('origen_admin:client:repeticionLista', function(id, paquete, info)
    local c = clips[tonumber(id)]
    if not c then return end

    local ok, clip = pcall(RepWire.unpack, paquete)
    if not ok or not clip or #clip.frames < 2 then
        c.estado = 'fallo'
        c.motivo = 'El clip recibido no se puede leer'
    else
        c.estado = 'lista'
        c.clip = clip
        c.duracion = info and info.duracion or clip.duration
        c.frames = #clip.frames
    end

    AvisarInterfaz()
    ShowNotification(c.estado == 'lista'
        and ('Repeticion de %s lista para ver'):format(c.nombre or '?')
        or c.motivo)
end)

RegisterNetEvent('origen_admin:client:repeticionFallo', function(id, motivo)
    local c = clips[tonumber(id)]
    if not c then return end
    c.estado = 'fallo'
    c.motivo = type(motivo) == 'string' and motivo:sub(1, 120) or 'No ha llegado'
    AvisarInterfaz()
end)

-- ── Exports para recursos externos (origen_police) ───────────────────

exports('PedirRepeticion', function(targetId, segundos)
    local r = lib.callback.await('origen_admin:server:repeticionPedir', false, tonumber(targetId), tonumber(segundos))
    if r and r.success then
        Guardar({
            id = r.id,
            estado = 'pidiendo',
            targetId = r.targetId,
            nombre = r.nombre,
            segundos = r.segundos,
            hora = GetCloudTimeAsInt(),
        })
        AvisarInterfaz()
    end
    return r or { success = false, message = 'Sin respuesta del servidor' }
end)

exports('ObtenerRepeticiones', function()
    return Resumen()
end)

exports('BorrarRepeticion', function(id)
    id = tonumber(id)
    if id and clips[id] and clips[id].estado ~= 'pidiendo' then
        clips[id] = nil
        for i, v in ipairs(orden) do
            if v == id then table.remove(orden, i) break end
        end
    end
    AvisarInterfaz()
    return true
end)

exports('VerRepeticion', function(id, alTerminarCb)
    local c = clips[tonumber(id)]
    if not c or c.estado ~= 'lista' or not c.clip then
        return { success = false, message = 'Esa repetición ya no está disponible' }
    end
    if RepPlayback.active then
        return { success = false, message = 'Ya hay una repetición en marcha' }
    end

    SetTimeout(350, function()
        RepPlayback.label = ('%s [%d]'):format(c.nombre or '?', c.targetId or 0)
        RepPlayback.alTerminar = function()
            if alTerminarCb then
                alTerminarCb()
            elseif AbrirPanelAdminEn then
                AbrirPanelAdminEn('spectate')
            end
        end
        RepPlayback.start(c.clip, ('p%d'):format(c.targetId or 0))
    end)
    return { success = true }
end)

