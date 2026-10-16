--[[ ── La maquinaria ──────────────────────────────────────────────────────────

     Lo alquilado en la cooperativa (ver server/vehiculos.lua):

       heno        tractor + carro de pacas: al pasar por encima de tus celdas
                   sin trabajar esparce heno; las pacas se gastan y el carro se
                   queda vacío (se recarga en la cooperativa con G)
       rastrillo   tractor + rastrillo: ara las celdas con heno
       camioneta   pickup: las cajas se cargan a pie por detrás y se descargan
                   aparcándola en la báscula

     El servidor mide dónde está el apero de verdad; aquí solo se elige qué
     celdas hay debajo y se pinta lo que se ve (las pacas del carro y las cajas
     de la camioneta, en todos los clientes, por state bags). ]]

Tractor = { mio = nil }  -- { vehiculo, remolque, tipo }

local V = Config.Vehiculos

local function Entidad(netId, espera)
    local fin = GetGameTimer() + (espera or 0)
    repeat
        if netId and NetworkDoesNetworkIdExist(netId) then
            local ent = NetworkGetEntityFromNetworkId(netId)
            if ent and ent ~= 0 and DoesEntityExist(ent) then return ent end
        end
        if espera then Wait(100) end
    until GetGameTimer() >= fin
    return nil
end
Tractor.Entidad = Entidad

local function Controlar(ent)
    local fin = GetGameTimer() + 2000
    while not NetworkHasControlOfEntity(ent) and GetGameTimer() < fin do
        NetworkRequestControlOfEntity(ent)
        Wait(50)
    end
end

--- La altura de la salida es aproximada: se asienta en el suelo de verdad.
local function AlSuelo(ent)
    local c = GetEntityCoords(ent)
    RequestCollisionAtCoord(c.x, c.y, c.z)
    local fin = GetGameTimer() + 1500
    local ok, z
    repeat
        ok, z = GetGroundZFor_3dCoord(c.x, c.y, c.z + 10.0, false)
        if not ok then Wait(50) end
    until ok or GetGameTimer() > fin
    if ok then SetEntityCoordsNoOffset(ent, c.x, c.y, z + 0.6, false, false, false) end
    SetVehicleOnGroundProperly(ent)
end

local function Enganchar(tractor, remolque)
    if not IsVehicleAttachedToTrailer(tractor) then
        Controlar(tractor)
        Controlar(remolque)
        AttachVehicleToTrailer(tractor, remolque, 1.1)
    end
end

--- El vehículo alquilado en los dos mapas, detrás de él: tractor o camioneta,
--- en el rosa de lo tuyo. El punto se va solo cuando el vehículo deja de existir.
local marcado
function Tractor.Marcar(vehiculo, tipo)
    if not vehiculo or not DoesEntityExist(vehiculo) then
        marcado = nil
        return OrigenMapa.Quitar('alquiler')
    end
    marcado = vehiculo
    OrigenMapa.Poner('alquiler', {
        entidad = vehiculo,
        cat = 'trabajos',
        icono = tipo == 'camioneta' and 'camion' or 'tractor',
        color = '#fc0259',
        propio = true,
        nombre = V.tipos[tipo] and V.tipos[tipo].nombre or 'Vehículo de la cooperativa',
    })
end

RegisterNetEvent('origen_farming:vehiculoListo', function(vehiculoNet, remolqueNet, tipo)
    Tractor.mio = { vehiculo = vehiculoNet, remolque = remolqueNet, tipo = tipo }
    if G.panelAbierto and CerrarPanel then CerrarPanel() end
    local vehiculo = Entidad(vehiculoNet, 6000)
    if not vehiculo then return G.Aviso('No encuentro el vehículo.', 'error') end
    Controlar(vehiculo)
    AlSuelo(vehiculo)
    pcall(function() exports.origen_fuel:SetFuel(vehiculo, 100.0) end)
    SetVehicleEngineOn(vehiculo, true, true, false)
    TaskWarpPedIntoVehicle(cache.ped, vehiculo, -1)
    local remolque = remolqueNet and Entidad(remolqueNet, 6000)
    if remolque then
        Controlar(remolque)
        AlSuelo(remolque)
        Wait(500)
        Enganchar(vehiculo, remolque)
    end
    Tractor.Marcar(vehiculo, tipo)
end)

-- Al reconectar o reiniciar el recurso, se recupera el alquiler.
CreateThread(function()
    Wait(3000)
    Tractor.mio = lib.callback.await('origen_farming:miVehiculo', false)
    --[[ El punto va detrás del vehículo y el registro lo borra cuando el
         vehículo deja de existir PARA ESTE CLIENTE, que también pasa al
         alejarse lo bastante. Así que se vuelve a poner cuando reaparece, y se
         quita cuando ya no hay alquiler. ]]
    while true do
        local mio = Tractor.mio
        local vehiculo = mio and Entidad(mio.vehiculo)
        if vehiculo and (vehiculo ~= marcado or not DoesEntityExist(marcado)) then
            Tractor.Marcar(vehiculo, mio.tipo)
        elseif not mio and marcado then
            Tractor.Marcar(nil)
        elseif mio and not vehiculo then
            marcado = nil
        end
        Wait(3000)
    end
end)

-- ── La tarjeta y el trabajo ───────────────────────────────────────────────

local ultimaTarjeta = ''
local function Tarjeta(datos)
    local huella = json.encode(datos)
    if huella ~= ultimaTarjeta then
        ultimaTarjeta = huella
        G.Nui('tractor', datos)
    end
end

--- Las celdas de parcelas tuyas bajo el apero en el estado que ese apero trabaja.
local function CeldasBajo(punto, ancho, estado)
    for _, cfg in ipairs(Config.Parcelas) do
        local v = G.parcelas[cfg.id]
        -- Tuyas o libres (la primera pasada por una libre la hace tuya).
        if v and (G.EsMia(v) or not v.cid) and Granja.Plano(punto, cfg.centro) <= cfg.radio + ancho then
            local lista = {}
            for idx = 1, cfg.celdas do
                local c = v.celdas[idx]
                if (c and c.e or 'yermo') == estado and Granja.Plano(Granja.PosCelda(cfg, idx), punto) <= ancho then
                    lista[#lista + 1] = idx
                end
            end
            if #lista > 0 then return cfg, lista end
        end
    end
    return nil
end

--- Un poco de polvo o paja donde trabaja el apero.
local function Polvo(punto, heno)
    UseParticleFxAssetNextCall('core')
    StartParticleFxNonLoopedAtCoord(heno and 'ent_dst_gen_straw' or 'ent_dst_dust', punto.x, punto.y, punto.z + 0.3,
        0.0, 0.0, 0.0, heno and 2.0 or 1.5, false, false, false)
end

-- ── La guía en el suelo ───────────────────────────────────────────────────

--[[ Subido al tractor de heno o de rastrillo: las celdas que ese apero puede
     trabajar se marcan en el suelo (amarillo el heno, naranja el rastrillo) y
     cada fila con trabajo lleva una línea de ruta por el centro, de punta a
     punta de la parcela. ]]
local GUIA = {
    heno = { estado = 'yermo', celda = { 240, 200, 60, 55 }, ruta = { 240, 200, 60, 170 } },
    rastrillo = { estado = 'empajada', celda = { 235, 130, 40, 60 }, ruta = { 235, 130, 40, 180 } },
}

local function CabeOtra()
    local max = Granja.Tope(G.mochila and G.mochila.nivel or 1)
    local mias = 0
    for _, v in pairs(G.parcelas) do if G.EsMia(v) then mias = mias + 1 end end
    return mias < max
end

local function DibujarGuia(tipo, pos)
    local g = GUIA[tipo]
    if not g then return end
    local libres = CabeOtra()
    for id, v in pairs(G.parcelas) do
        local cfg = Granja.Parcela(id)
        if cfg and Granja.Plano(pos, cfg.centro) < 55.0 and (G.EsMia(v) or (not v.cid and libres)) then
            for fila = 0, cfg.filas - 1 do
                local pendiente = false
                for col = 0, cfg.columnas - 1 do
                    local idx = fila * cfg.columnas + col + 1
                    local c = v.celdas[idx]
                    if (c and c.e or 'yermo') == g.estado then
                        pendiente = true
                        local p = Granja.PosCelda(cfg, idx)
                        Plantas.Relleno(cfg, p.x, p.y, cfg.paso * 0.86, 2, g.celda)
                    end
                end
                if pendiente then
                    local b = (fila - (cfg.filas - 1) / 2) * cfg.paso
                    local largo = cfg.columnas * cfg.paso / 2
                    local ax = cfg.centro.x + cfg.ejeFila.x * b - cfg.ejeCol.x * largo
                    local ay = cfg.centro.y + cfg.ejeFila.y * b - cfg.ejeCol.y * largo
                    local bx = cfg.centro.x + cfg.ejeFila.x * b + cfg.ejeCol.x * largo
                    local by = cfg.centro.y + cfg.ejeFila.y * b + cfg.ejeCol.y * largo
                    Plantas.Tira(cfg.centro.z, ax, ay, bx, by, 0.22, g.ruta)
                end
            end
        end
    end
end

CreateThread(function()
    while true do
        local espera = 500
        local mio = Tractor.mio
        local vehiculo = mio and Entidad(mio.vehiculo)
        if vehiculo and cache.vehicle == vehiculo and GUIA[mio.tipo] and G.cerca then
            espera = 0
            DibujarGuia(mio.tipo, GetEntityCoords(vehiculo))
        end
        Wait(espera)
    end
end)

--[[ El heno tiene colisión (a pie no se atraviesa), pero el tractor de trabajo
     tiene que pasar por encima: el rastrillo deshace los rollos al pisarlos.
     Cada fotograma, el tractor y su apero ignoran el heno de alrededor. ]]
CreateThread(function()
    while true do
        local espera = 500
        local mio = Tractor.mio
        local vehiculo = mio and V.tipos[mio.tipo] and V.tipos[mio.tipo].trabajo and Entidad(mio.vehiculo)
        if vehiculo and cache.vehicle == vehiculo and G.cerca then
            espera = 0
            local remolque = mio.remolque and Entidad(mio.remolque)
            for _, ent in ipairs(Plantas.Heno(GetEntityCoords(vehiculo), 25.0)) do
                SetEntityNoCollisionEntity(vehiculo, ent, true)
                SetEntityNoCollisionEntity(ent, vehiculo, true)
                if remolque then
                    SetEntityNoCollisionEntity(remolque, ent, true)
                    SetEntityNoCollisionEntity(ent, remolque, true)
                end
            end
        end
        Wait(espera)
    end
end)

local trabajando = 0
CreateThread(function()
    while true do
        local espera = 1000
        local mio = Tractor.mio
        local veh = cache.vehicle
        local vehiculo = mio and Entidad(mio.vehiculo)
        if vehiculo and veh == vehiculo and GetPedInVehicleSeat(vehiculo, -1) == cache.ped then
            espera = 350
            local def = V.tipos[mio.tipo]
            local remolque = mio.remolque and Entidad(mio.remolque)
            local enganchado = remolque and IsVehicleAttachedToTrailer(vehiculo)
            local heno = remolque and Entity(remolque).state.granjaHeno
            local ayuda

            if def.trabajo then
                if not enganchado then
                    ayuda = 'Da marcha atrás hasta el apero para engancharlo.'
                elseif mio.tipo == 'heno' and heno and heno.q <= 0 then
                    ayuda = 'Sin heno: vuelve a la cooperativa a recargar.'
                else
                    ayuda = mio.tipo == 'heno' and 'Pasa por encima de tus celdas sin trabajar.'
                        or 'Pasa por encima de tus celdas con heno.'
                    if G.cerca and GetEntitySpeed(vehiculo) > 0.5 then
                        local punto = GetOffsetFromEntityInWorldCoords(remolque, 0.0, def.trabajo.atras, 0.0)
                        local cfg, lista = CeldasBajo(punto, def.trabajo.ancho, mio.tipo == 'heno' and 'yermo' or 'empajada')
                        if cfg then
                            local r = lib.callback.await('origen_farming:pasada', false, cfg.id, lista)
                            if r and r.mensaje and r.mensaje ~= 'ajena' and GetGameTimer() > (Tractor.avisado or 0) then
                                Tractor.avisado = GetGameTimer() + 8000
                                G.Aviso(r.mensaje, 'error')
                            end
                            if r and r.hechas > 0 then
                                trabajando = GetGameTimer() + 1500
                                Polvo(punto, mio.tipo == 'heno')
                            end
                        end
                    end
                end
            else
                local cajas = Entity(vehiculo).state.granjaCajas or {}
                ayuda = #cajas > 0 and 'Aparca en la báscula de la cooperativa y descarga desde atrás.'
                    or 'Carga las cajas a pie por la parte de atrás.'
            end

            local cajas = mio.tipo == 'camioneta' and (Entity(vehiculo).state.granjaCajas or {}) or {}
            local cargaCam = V.tipos.camioneta.carga
            Tarjeta({
                visible = not G.panelAbierto,
                implemento = mio.tipo,
                cajas = #cajas,
                capacidad = mio.tipo == 'camioneta' and #cargaCam.columnas * #cargaCam.filas * cargaCam.pisos or 0,
                heno = mio.tipo == 'heno' and heno and { quedan = heno.q, max = heno.max } or nil,
                arando = GetGameTimer() < trabajando,
                ayuda = ayuda,
            })

            -- En la cooperativa: devolver (E) y, con el heno, recargar (G).
            local d = Config.Cooperativa.devolver
            if #(GetEntityCoords(vehiculo) - d.coords) <= d.radio then
                espera = 0
                local alt = (mio.tipo == 'heno' and heno and heno.q < heno.max)
                    and { 'G', ('Recargar heno · %s'):format(Granja.Dinero(def.recarga)) } or nil
                G.Ayuda('tractor', 'E', 'Devolver ' .. (mio.tipo == 'camioneta' and 'la camioneta' or 'el tractor'), alt)
                if IsControlJustReleased(0, 38) then
                    local r = lib.callback.await('origen_farming:panel:devolverVehiculo', false, {})
                    if r and r.mensaje then G.Aviso(r.mensaje, r.ok and 'success' or 'error') end
                    if r and r.ok then Tractor.mio = nil end
                elseif alt and IsControlJustReleased(0, 47) then
                    local r = lib.callback.await('origen_farming:recargarHeno', false)
                    if r and r.mensaje then G.Aviso(r.mensaje, r.ok and 'success' or 'error') end
                end
            end
        else
            Tarjeta({ visible = false })
        end
        if espera ~= 0 then G.QuitarAyuda('tractor') end
        Wait(espera)
    end
end)

-- ── Lo que se ve: pacas y cajas ───────────────────────────────────────────

local encima = {}   -- [netId] = { ent, props, clave }

local function Limpiar(netId)
    local e = encima[netId]
    if not e then return end
    for _, p in ipairs(e.props) do if DoesEntityExist(p) then DeleteEntity(p) end end
    Relleno.Borrar(e.dentro)
    encima[netId] = nil
end

--- Los huecos de la caja de la camioneta, en orden de carga.
local HUECOS = {}
do
    local c = V.tipos.camioneta.carga
    for piso = 0, c.pisos - 1 do
        for _, y in ipairs(c.filas) do
            for _, x in ipairs(c.columnas) do
                HUECOS[#HUECOS + 1] = { x = x, y = y, piso = piso }
            end
        end
    end
end

local function PintarCajas(veh, cajas)
    local netId = NetworkGetNetworkIdFromEntity(veh)
    local partes = {}
    for i, caja in ipairs(cajas) do partes[i] = Relleno.Clave(caja) end
    local clave = table.concat(partes, ',')
    local e = encima[netId]
    if e and e.ent == veh and e.clave == clave then return end
    Limpiar(netId)
    e = { ent = veh, props = {}, dentro = {}, clave = clave }
    encima[netId] = e
    local c = V.tipos.camioneta.carga
    for i, caja in ipairs(cajas) do
        local hueco = HUECOS[i]
        local tipo = type(caja) == 'table' and caja.t or caja
        local cfg = Config.Carga[tipo]
        if hueco and cfg then
            local hash = GetHashKey(cfg.modelo)
            lib.requestModel(hash, 3000)
            local min, max = GetModelDimensions(hash)
            local pos = GetEntityCoords(veh)
            local p = Rastro.Marcar(CreateObject(hash, pos.x, pos.y, pos.z + 2.0, false, false, false))
            SetEntityCollision(p, false, false)
            local z = c.suelo + hueco.piso * (max.z - min.z) - min.z
            AttachEntityToEntity(p, veh, 0, hueco.x, hueco.y, z, 0.0, 0.0, ((i * 13) % 7 - 3) + 0.0,
                false, false, false, false, 2, true)
            e.props[#e.props + 1] = p
            if tipo == 'caja' and type(caja) == 'table' then
                for _, pieza in ipairs(Relleno.Llenar(p, caja.c, caja.l)) do e.dentro[#e.dentro + 1] = pieza end
            end
        end
    end
end

CreateThread(function()
    while true do
        Wait(1000)
        local pos = GetEntityCoords(cache.ped)
        local vistos = {}
        for _, veh in ipairs(GetGamePool('CVehicle')) do
            if #(GetEntityCoords(veh) - pos) < 150.0 then
                local st = Entity(veh).state
                local vehEst = st.granjaVehiculo
                if vehEst and vehEst.tipo == 'camioneta' then
                    local netId = NetworkGetNetworkIdFromEntity(veh)
                    vistos[netId] = true
                    PintarCajas(veh, st.granjaCajas or {})
                end
                -- El carro de heno: las pacas son el extra 1 del baletrailer;
                -- vacío, se quitan.
                local heno = st.granjaHeno
                if heno and DoesExtraExist(veh, 1) then
                    local vacio = (heno.q or 0) <= 0
                    if IsVehicleExtraTurnedOn(veh, 1) == vacio then SetVehicleExtra(veh, 1, vacio) end
                end
            end
        end
        for netId in pairs(encima) do
            if not vistos[netId] then Limpiar(netId) end
        end
    end
end)

AddEventHandler('onResourceStop', function(r)
    if r ~= GetCurrentResourceName() then return end
    for netId in pairs(encima) do Limpiar(netId) end
end)
