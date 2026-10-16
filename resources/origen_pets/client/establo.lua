--[[ ── Mascotas · el establo ────────────────────────────────────────────────

     El rancho O'Neil con todos los caballos a la vista (config_establo.lua).
     Aqui solo se pinta y se elige; vender, lo vende server/establo.lua.

     Todo lo que se planta es LOCAL y solo con alguien cerca: entrar en los
     `Distancia` metros lo monta, salir lo borra. ]]

local E = Config.Establo
local P = E.Centro

local montado = false
local caballos = {}   -- { [i] = { ped, cfg, pos } }
local objetos = {}
local caballerizo = nil
local precios = {}    -- lo que dice el servidor para este jugador: [id] = { gratis, reservado, precio }
local cerca = nil     -- el caballo (indice) al que se le ve el [E]
local enCaballerizo = false
local ocupado = false -- un menu o una compra en marcha

local function Aviso(texto, tipo)
    if GetResourceState('origen_notify') == 'started' then
        exports.origen_notify:Notify(texto, tipo or 'info')
    end
end

local function Dinero(n)
    local s = tostring(math.floor(n or 0))
    local con = s:reverse():gsub('(%d%d%d)', '%1.'):reverse()
    return '$' .. con:gsub('^%.', '')
end

--- Donde va el caballo i: en fila a lo largo del cobertizo, todos mirando
--- al claro (`E.Fila.rumbo`).
local function Sitio(i)
    local total = #E.Caballos
    local rumbo = E.Fila.rumbo
    local r = math.rad(rumbo)
    -- Hacia donde miran, en el rumbo de GTA; la fila va a su derecha.
    local fx, fy = -math.sin(r), math.cos(r)
    local ax, ay = fy, -fx
    local d = (i - (total + 1) / 2) * E.Fila.separacion
    return vector3(P.x + ax * d, P.y + ay * d, P.z), rumbo
end

local function Suelo(x, y, z)
    local ok, gz = GetGroundZFor_3dCoord(x, y, z + 3.0, false)
    return ok and gz or z
end

local function PonerObjeto(modelo, x, y, z, h)
    local hash = Mascotas.CargarModelo(modelo)
    if not hash then return end
    local o = CreateObjectNoOffset(hash, x, y, Suelo(x, y, z), false, false, false)
    SetModelAsNoLongerNeeded(hash)
    if o == 0 then return end
    SetEntityHeading(o, h + 0.0)
    PlaceObjectOnGroundProperly(o)
    FreezeEntityPosition(o, true)
    objetos[#objetos + 1] = o
end

local function PedQuieto(ped)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedCanRagdoll(ped, false)
    SetPedDiesWhenInjured(ped, false)
    SetPedCanBeTargetted(ped, false)
end

local function Desmontar()
    for _, c in pairs(caballos) do
        if c.ped and DoesEntityExist(c.ped) then DeleteEntity(c.ped) end
    end
    for _, o in ipairs(objetos) do
        if DoesEntityExist(o) then DeleteEntity(o) end
    end
    if caballerizo and DoesEntityExist(caballerizo) then DeleteEntity(caballerizo) end
    caballos, objetos, caballerizo = {}, {}, nil
    cerca, enCaballerizo = nil, false
    lib.hideTextUI()
    montado = false
end

local function Montar()
    if montado then return end
    montado = true

    for i, cfg in ipairs(E.Caballos) do
        local raza = Mascotas.Raza(cfg.raza)
        local hash = raza and Mascotas.CargarModelo(raza.modelo)
        local pos, rumbo = Sitio(i)

        if hash and montado then
            local z = Suelo(pos.x, pos.y, pos.z)
            -- A ras de suelo y SIN congelar: la fisica lo deja de pie sobre los
            -- cascos y se congela despues (mas abajo). Restarle GetModelDimensions,
            -- como en la tienda, con el esqueleto del ciervo los dejaba flotando.
            local ped = CreatePed(28, hash, pos.x, pos.y, z, rumbo, false, false)
            SetModelAsNoLongerNeeded(hash)
            if ped ~= 0 then
                Aspecto.Aplicar(ped, raza.modelo, cfg.aspecto)
                SetEntityInvincible(ped, true)
                SetBlockingOfNonTemporaryEvents(ped, true)
                TaskStandStill(ped, -1)
                caballos[i] = { ped = ped, cfg = cfg, pos = vector3(pos.x, pos.y, z) }

                -- El heno de delante.
                for _, a in ipairs(E.Atrezo) do
                    local o = GetOffsetFromEntityInWorldCoords(ped, a.lado, a.delante, 0.0)
                    PonerObjeto(a.modelo, o.x, o.y, z, rumbo + (a.h or 0.0))
                end
            end
        end
    end

    -- Ya asentados en el suelo: ahora si, quietos para siempre y en su rumbo.
    Wait(1500)
    for i, c in pairs(caballos) do
        if DoesEntityExist(c.ped) then
            local _, rumbo = Sitio(i)
            SetEntityHeading(c.ped, rumbo)
            PedQuieto(c.ped)
            c.pos = GetEntityCoords(c.ped) - vector3(0.0, 0.0, 1.0)
        end
    end

    for _, a in ipairs(E.AtrezoFijo) do
        PonerObjeto(a.modelo, a.x, a.y, a.z, a.h)
    end

    local c = E.Caballerizo
    local hash = Mascotas.CargarModelo(c.modelo)
    if hash and montado then
        local ped = CreatePed(4, hash, c.x, c.y, Suelo(c.x, c.y, c.z), c.h, false, false)
        SetModelAsNoLongerNeeded(hash)
        if ped ~= 0 then
            PedQuieto(ped)
            TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_CLIPBOARD', 0, true)
            caballerizo = ped
        end
    end

    -- Los precios, para este jugador (gratis o no segun su trabajo).
    precios = lib.callback.await('origen_pets:establo:precios', false) or {}
end

-- ── Lo que se ve: precio y estado de cada caballo ─────────────────────────

local function Etiqueta(cfg)
    local p = precios[cfg.id]
    if p and p.gratis then return 'Gratis · de servicio' end
    if p and p.reservado then return 'Solo para el servicio' end
    local oficio = ''
    if cfg.oficios then
        local nombres, vistos = {}, {}
        for _, o in ipairs(cfg.oficios) do
            local n = E.Oficios[o] or o
            if not vistos[n] then vistos[n] = true nombres[#nombres + 1] = n end
        end
        oficio = (' · gratis %s'):format(table.concat(nombres, '/'))
    end
    return Dinero(cfg.precio) .. oficio
end

-- ── Comprar ───────────────────────────────────────────────────────────────

local function SacarCuandoLlegue(id)
    local hasta = GetGameTimer() + 5000
    while GetGameTimer() < hasta do
        for _, m in ipairs(Mascotas.lista or {}) do
            if m.id == id then return Mascotas.Sacar(id) end
        end
        Wait(250)
    end
end

--- El ultimo paso: el nombre y la compra. `cuenta` = 'cash', el id de una
--- cuenta del banco, o nil si sale gratis.
local function Finalizar(cfg, cuenta, gratis)
    local titulo = gratis and ('%s · gratis'):format(cfg.nombre) or ('%s · %s'):format(cfg.nombre, Dinero(cfg.precio))
    -- Solo un campo de texto: la forma de pago ya se eligio en el menu.
    local r = lib.inputDialog(titulo, {
        { type = 'input', label = 'Nombre del caballo', placeholder = cfg.nombre, max = 32 },
    })
    if not r then return end

    local res = lib.callback.await('origen_pets:establo:comprar', false, {
        id = cfg.id, nombre = r[1], cuenta = cuenta,
    })

    if not res or not res.ok then
        return Aviso(res and res.mensaje or 'No se pudo comprar.', 'error')
    end

    Aviso(res.mensaje, 'success')

    -- Con otra mascota fuera no se saca: se queda en el panel.
    if Mascotas.EnLaCalle() then
        Aviso('Lo tienes en tus mascotas para sacarlo cuando quieras.', 'info')
        return
    end

    local sacar = lib.alertDialog({
        header = 'Ya es tuyo',
        content = '¿Te lo llevas ahora? Se monta con la E.',
        centered = true,
        cancel = true,
        labels = { confirm = 'Sacarlo', cancel = 'Luego' },
    })
    if sacar == 'confirm' then SacarCuandoLlegue(res.id) end
end

--[[ Comprar. Gratis, directo al nombre. Pagando, primero con que: el menu
     pequeño de siempre (org-menu), con el efectivo arriba y luego las
     cuentas del banco; lo que no llega al precio sale apagado. Nada de
     desplegables del navegador.
     Devuelve true si deja un menu abierto (el que lo cierre suelta `ocupado`). ]]
local function Comprar(cfg)
    local p = precios[cfg.id] or {}
    if p.reservado then
        Aviso('Ese caballo es solo para el servicio.', 'error')
        return false
    end

    if p.gratis then
        Finalizar(cfg, nil, true)
        return false
    end

    local precio = cfg.precio or 0
    local function Pagar(cuenta)
        return function()
            ocupado = true
            CreateThread(function()
                Finalizar(cfg, cuenta, false)
                ocupado = false
            end)
        end
    end

    local efectivo = lib.callback.await('origen_pets:establo:efectivo', false) or 0
    local opciones = {
        {
            title = 'Efectivo',
            description = ('Llevas %s'):format(Dinero(efectivo)),
            icon = 'fa-solid fa-money-bill-wave',
            disabled = efectivo < precio,
            onSelect = Pagar('cash'),
        },
    }
    for _, c in ipairs(lib.callback.await('origen_pets:cuentas', false) or {}) do
        opciones[#opciones + 1] = {
            title = c.nombre,
            description = ('Saldo %s'):format(Dinero(c.saldo)),
            icon = 'fa-solid fa-building-columns',
            disabled = c.saldo < precio,
            onSelect = Pagar(c.id),
        }
    end

    lib.registerContext({
        id = 'origen_pets_establo_pago',
        title = ('Pagar %s'):format(Dinero(precio)),
        menu = 'origen_pets_establo_caballo',
        onExit = function() ocupado = false end,
        options = opciones,
    })
    ocupado = true
    lib.showContext('origen_pets_establo_pago')
    return true
end

local function Ficha(i)
    local c = caballos[i]
    if not c then return end
    local cfg = c.cfg
    local raza = Mascotas.Raza(cfg.raza) or {}
    local p = precios[cfg.id] or {}

    local opciones = {
        {
            title = cfg.detalle or cfg.nombre,
            description = ('Vida %d · Alforjas: %d huecos, %d kg'):format(raza.salud or 0,
                raza.alijo and raza.alijo.slots or 0, math.floor(((raza.alijo and raza.alijo.peso) or 0) / 1000)),
            icon = 'fa-solid fa-horse',
            readOnly = true,
        },
    }

    if p.reservado then
        opciones[#opciones + 1] = { title = 'Solo para el servicio', description = Etiqueta(cfg), icon = 'fa-solid fa-lock', disabled = true }
    else
        opciones[#opciones + 1] = {
            title = p.gratis and 'Llevártelo (gratis)' or ('Comprar · %s'):format(Dinero(cfg.precio)),
            description = p.gratis and 'Cortesía del servicio: uno por persona.' or 'En efectivo o por banco.',
            icon = p.gratis and 'fa-solid fa-shield-halved' or 'fa-solid fa-cart-shopping',
            onSelect = function()
                ocupado = true
                CreateThread(function()
                    -- Si abre el menu de pago, ese menu suelta `ocupado` al cerrarse.
                    if not Comprar(cfg) then ocupado = false end
                end)
            end,
        }
    end

    lib.registerContext({
        id = 'origen_pets_establo_caballo',
        title = cfg.nombre,
        menu = enCaballerizo and 'origen_pets_establo' or nil,
        onExit = function() ocupado = false end,
        options = opciones,
    })
    ocupado = true
    lib.showContext('origen_pets_establo_caballo')
end

local function Catalogo()
    local opciones = {}
    for i, cfg in ipairs(E.Caballos) do
        opciones[#opciones + 1] = {
            title = cfg.nombre,
            description = Etiqueta(cfg),
            icon = cfg.oficios and 'fa-solid fa-shield-halved' or 'fa-solid fa-horse',
            arrow = true,
            onSelect = function() Ficha(i) end,
        }
    end

    lib.registerContext({
        id = 'origen_pets_establo',
        title = E.Nombre,
        onExit = function() ocupado = false end,
        options = opciones,
    })
    ocupado = true
    lib.showContext('origen_pets_establo')
end

-- ── El bucle ──────────────────────────────────────────────────────────────

local function TextoUI(texto)
    if texto then lib.showTextUI(texto) else lib.hideTextUI() end
end

CreateThread(function()
    -- El punto en los mapas.
    OrigenMapa.Poner('establo', {
        x = P.x, y = P.y, z = P.z,
        cat = 'mascotas',
        icono = 'caballo',
        nombre = E.Nombre,
    })

    local centro = vector3(P.x, P.y, P.z)
    while true do
        local yo = GetEntityCoords(cache.ped)
        local d = #(yo - centro)

        if d > E.Distancia then
            if montado then Desmontar() end
            Wait(1500)
        else
            if not montado then Montar() end

            -- El [E] mas cercano: el caballerizo manda sobre los caballos.
            local cual, mejor = nil, E.DistanciaVer
            for i, c in pairs(caballos) do
                local dc = #(yo - c.pos)
                if dc < mejor then cual, mejor = i, dc end
            end
            local cz = E.Caballerizo
            local junto = #(yo - vector3(cz.x, cz.y, cz.z)) < 2.2

            if ocupado or IsPedInAnyVehicle(cache.ped, false) then
                if cerca or enCaballerizo then TextoUI(nil) end
                cerca, enCaballerizo = nil, false
            elseif junto then
                if not enCaballerizo then TextoUI('[E] Hablar con el caballerizo') end
                enCaballerizo, cerca = true, nil
                if IsControlJustReleased(0, 38) then TextoUI(nil) Catalogo() end
            elseif cual then
                if cerca ~= cual or enCaballerizo then
                    TextoUI(('[E] %s · %s'):format(caballos[cual].cfg.nombre, Etiqueta(caballos[cual].cfg)))
                end
                cerca, enCaballerizo = cual, false
                if IsControlJustReleased(0, 38) then TextoUI(nil) Ficha(cual) end
            else
                if cerca or enCaballerizo then TextoUI(nil) end
                cerca, enCaballerizo = nil, false
            end

            Wait(0)
        end
    end
end)

-- Al cambiar de trabajo cambia lo que es gratis.
RegisterNetEvent('QBCore:Client:OnJobUpdate', function()
    if montado then precios = lib.callback.await('origen_pets:establo:precios', false) or {} end
end)

AddEventHandler('onResourceStop', function(recurso)
    if recurso ~= GetCurrentResourceName() then return end
    Desmontar()
end)
