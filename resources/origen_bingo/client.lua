--[[ Origen Bingo, lado cliente.

     · Pone las piezas de las salas que hay cerca (props locales: cada cliente
       pone los mismos, en el mismo sitio, a partir de lo que dice el servidor).
     · El bombo: la jaula gira mientras se juega, las bolas dan vueltas dentro
       y la que sale baja por la canaleta hasta la cesta. Todo es dibujo: qué
       bola sale lo dice GlobalState.bingo, que lo escribe el servidor.
     · Las pantallas (el panel grande y las de pared): una página en un
       navegador sin ventana (ui/pantalla.html) pegada encima del cristal.
     · La taquilla (E) y los cartones en pantalla mientras estás en una sala.
     · El configurador (/bingoconfig): salas, colocar piezas mirando dónde
       quedan, y los ajustes de las partidas. ]]

local MARCA = OrigenMarca or GetConvar('origen:marca', 'origen')
local TITULO = MARCA == 'nacion' and 'Nación Bingo' or 'Origen Bingo'

local salas, piezas = {}, {}
local objetos = {}     -- [pieza] = { ent, jaula = ent | nil }
local dentro = {}      -- [sala] = true: sus piezas están puestas
local cargado = false

local panel = false
local ajustando = false
local senalado = nil
local desdeElHub = false
local sobrantes = {}   -- el fantasma del configurador, por si el recurso se para a medias

local function Aviso(texto, tipo)
    exports.origen_notify:Notify({ title = TITULO, description = texto, type = tipo or 'info', duration = 5000 })
end

RegisterNetEvent('origen_bingo:cl:aviso', function(texto, tipo) Aviso(texto, tipo) end)

--[[ Lo que llega de la base de datos llega ENTERO si no tiene decimales, y a
     un native que espera un decimal un entero le llega como basura (el rumbo
     de 90 acaba en 0). Todo lo que entra se pasa a decimal aquí. ]]
local function Decimales(t)
    for _, k in ipairs({ 'x', 'y', 'z', 'h' }) do
        if t[k] then t[k] = t[k] + 0.0 end
    end
    return t
end

local function Juego() return GlobalState.bingo end

-- ---------------------------------------------------------------------------
--  Las piezas en el mundo
-- ---------------------------------------------------------------------------

local function Cargar(modelo)
    local hash = joaat(modelo)
    if not IsModelInCdimage(hash) then return nil end
    if not pcall(lib.requestModel, hash, 8000) then return nil end
    return hash
end

local function Borrar(e)
    if e and DoesEntityExist(e) then DeleteEntity(e) end
end

local QuitarBolas      -- más abajo, con el bombo

local function QuitarObjeto(id)
    QuitarBolas(id)
    local o = objetos[id]
    objetos[id] = nil
    if not o then return end
    Borrar(o.ent)
    Borrar(o.jaula)
end

local function PonerObjeto(p)
    QuitarObjeto(p.id)
    local tipo = Config.Pieza[p.tipo]
    if not tipo then return end

    if tipo.ped then
        local hash = Cargar(tipo.ped)
        if not hash or piezas[p.id] ~= p or not dentro[p.sala] or objetos[p.id] then return end
        -- El origen de un ped de pie está un metro por encima de sus pies.
        local ped = CreatePed(4, hash, p.x, p.y, p.z + 1.0, p.h, false, false)
        SetEntityCoordsNoOffset(ped, p.x, p.y, p.z + 1.0, false, false, false)
        SetEntityHeading(ped, p.h)
        FreezeEntityPosition(ped, true)
        SetEntityInvincible(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        SetPedCanRagdoll(ped, false)
        TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_STAND_IMPATIENT', 0, true)
        SetModelAsNoLongerNeeded(hash)
        objetos[p.id] = { ent = ped }
        return
    end

    local hash = Cargar(tipo.modelo)
    -- Cargar el modelo espera: a la vuelta puede que ya no haga falta.
    if not hash or piezas[p.id] ~= p or not dentro[p.sala] or objetos[p.id] then return end
    local o = CreateObjectNoOffset(hash, p.x, p.y, p.z, false, false, false)
    SetEntityHeading(o, p.h)
    FreezeEntityPosition(o, true)
    SetModelAsNoLongerNeeded(hash)
    local reg = { ent = o }

    if p.tipo == 'bombo' then
        local hj = Cargar('origen_bingo_jaula')
        if hj then
            local eje = Modelos.origen_bingo_bombo.eje
            local c = GetOffsetFromEntityInWorldCoords(o, eje.x, eje.y, eje.z)
            reg.jaula = CreateObjectNoOffset(hj, c.x, c.y, c.z, false, false, false)
            SetEntityHeading(reg.jaula, p.h)
            SetEntityCollision(reg.jaula, false, false)
            FreezeEntityPosition(reg.jaula, true)
            SetModelAsNoLongerNeeded(hj)
        end
    end
    objetos[p.id] = reg
end

local function Chincheta(s)
    OrigenMapa.Poner('origen_bingo_' .. s.id, {
        x = s.x, y = s.y, z = s.z,
        cat = Config.Mapa.cat, icono = Config.Mapa.icono, nombre = s.nombre,
    })
end

local function EntrarEn(s)
    dentro[s.id] = true
    for _, p in pairs(piezas) do
        if p.sala == s.id then PonerObjeto(p) end
    end
end

local function SalirDe(id)
    dentro[id] = nil
    for _, p in pairs(piezas) do
        if p.sala == id then QuitarObjeto(p.id) end
    end
end

-- ---------------------------------------------------------------------------
--  El bombo: la jaula, las bolas de dentro y la que sale
-- ---------------------------------------------------------------------------

--[[ El giro de la jaula va por cuaternión y no por ángulos: con Euler, pasado
     de 90 grados el juego da la vuelta a los otros dos ejes y la jaula pega
     un salto. Rumbo h (eje Z) y luego el giro a (eje X de la jaula). ]]
local function Girar(e, h, a)
    local hz, ax = math.rad(h) / 2, math.rad(a) / 2
    local sz, wz, sx, wx = math.sin(hz), math.cos(hz), math.sin(ax), math.cos(ax)
    SetEntityQuaternion(e, wz * sx, sz * sx, wx * sz, wz * wx)
end

local giro = { angulo = 0.0, velocidad = 0.0 }
local dentroBolas = {}     -- [pieza] = { {ent, x, fase, r, giro}... }
local salida = {}          -- [pieza] = { ent, n, desde }
local NUM_DENTRO = 12

QuitarBolas = function(id)
    for _, b in ipairs(dentroBolas[id] or {}) do Borrar(b.ent) end
    dentroBolas[id] = nil
    if salida[id] then Borrar(salida[id].ent) end
    salida[id] = nil
end

local function BolasDentro(id, base)
    if dentroBolas[id] then return dentroBolas[id] end
    local lista = {}
    for k = 1, NUM_DENTRO do
        local n = math.random(1, 90)
        local hash = Cargar('origen_bingo_bola_' .. n)
        if hash then
            local e = CreateObjectNoOffset(hash, base.x, base.y, base.z, false, false, false)
            SetEntityCollision(e, false, false)
            FreezeEntityPosition(e, true)
            SetModelAsNoLongerNeeded(hash)
            lista[#lista + 1] = {
                ent = e,
                x = (k / NUM_DENTRO - 0.5) * 0.42,
                fase = math.random() * math.pi * 2,
                r = 0.19 + math.random() * 0.1,
                rot = vector3(math.random(0, 360), math.random(0, 360), math.random(0, 360)),
            }
        end
    end
    dentroBolas[id] = lista
    return lista
end

--- La bola que sale: del embudo baja a la canaleta y rueda hasta la cesta.
local function SacarBola(id, ent, n)
    if salida[id] then Borrar(salida[id].ent) end
    salida[id] = nil
    local hash = Cargar('origen_bingo_bola_' .. n)
    if not hash or not DoesEntityExist(ent) then return end
    local m = Modelos.origen_bingo_bombo
    local a = GetOffsetFromEntityInWorldCoords(ent, m.embudo.x, m.embudo.y, m.embudo.z)
    local e = CreateObjectNoOffset(hash, a.x, a.y, a.z, false, false, false)
    SetEntityCollision(e, false, false)
    FreezeEntityPosition(e, true)
    SetModelAsNoLongerNeeded(hash)
    salida[id] = { ent = e, n = n, desde = GetGameTimer() }
end

--- Dónde va la bola que sale, t de 0 a 1, en los ejes del bombo.
local function Recorrido(t)
    local m = Modelos.origen_bingo_bombo
    local e, b = m.embudo, m.bandeja
    local c = vector3(0.0, -0.09, 1.045)        -- donde la canaleta empieza, bajo el embudo
    if t < 0.3 then
        local k = t / 0.3
        return e + (c - e) * k
    end
    local k = (t - 0.3) / 0.7
    k = 1 - (1 - k) * (1 - k)                   -- frena al llegar a la cesta
    return c + (b - c) * k
end

CreateThread(function()
    local antes = GetGameTimer()
    local vistas = -1
    while true do
        local ahora = GetGameTimer()
        local dt = (ahora - antes) / 1000.0
        antes = ahora
        local j = Juego()
        local jugando = j and j.estado == 'jugando'
        local bolas = j and j.bolas or {}

        -- La jaula acelera y frena poco a poco, como una de verdad.
        local objetivo = jugando and 140.0 or 0.0
        giro.velocidad = giro.velocidad + (objetivo - giro.velocidad) * math.min(1.0, dt * 1.2)
        giro.angulo = (giro.angulo + giro.velocidad * dt) % 360.0

        local yo = GetEntityCoords(PlayerPedId())
        local cerca = false
        local nueva = #bolas ~= vistas and #bolas > 0 and bolas[#bolas] or nil
        if #bolas ~= vistas then vistas = #bolas end

        for id, o in pairs(objetos) do
            local p = piezas[id]
            if p and p.tipo == 'bombo' and DoesEntityExist(o.ent) then
                local d = #(yo - vector3(p.x, p.y, p.z))
                if d < 35.0 then
                    cerca = true
                    if o.jaula then Girar(o.jaula, p.h, giro.angulo) end

                    -- Las bolas de dentro: amontonadas abajo si está quieta;
                    -- girando, la jaula las sube por la pared y caen.
                    local eje = Modelos.origen_bingo_bombo.eje
                    local base = GetOffsetFromEntityInWorldCoords(o.ent, eje.x, eje.y, eje.z)
                    local fuerza = math.min(1.0, giro.velocidad / 140.0)
                    for k, b in ipairs(BolasDentro(id, base)) do
                        local t = ahora / 1000.0
                        local th = -90.0 + fuerza * (65.0 * math.sin(t * 2.3 + b.fase) + 25.0 * math.sin(t * 5.1 + b.fase * 2))
                        local r = b.r + (0.3 - b.r) * (1 - fuerza)
                        local yy = math.cos(math.rad(th)) * r
                        local zz = math.sin(math.rad(th)) * r + (1 - fuerza) * (k % 3) * 0.06
                        local w = GetOffsetFromEntityInWorldCoords(o.ent, b.x, eje.y + yy, eje.z + zz)
                        SetEntityCoordsNoOffset(b.ent, w.x, w.y, w.z, false, false, false)
                        if fuerza > 0.05 then
                            b.rot = b.rot + vector3(190.0, 140.0, 90.0) * dt * fuerza
                            SetEntityRotation(b.ent, b.rot.x % 360, b.rot.y % 360, b.rot.z % 360, 2, false)
                        end
                    end

                    -- La que sale. Si se llega con la partida empezada, la
                    -- última ya está en la cesta (sin bajar por la canaleta).
                    if nueva then
                        SacarBola(id, o.ent, nueva)
                    elseif not salida[id] and #bolas > 0 and j.estado ~= 'venta' then
                        SacarBola(id, o.ent, bolas[#bolas])
                        if salida[id] then salida[id].desde = ahora - 5000 end
                    end
                    local s = salida[id]
                    if s and DoesEntityExist(s.ent) then
                        local t = math.min(1.0, (ahora - s.desde) / 1100.0)
                        local l = Recorrido(t)
                        local w = GetOffsetFromEntityInWorldCoords(o.ent, l.x, l.y, l.z)
                        SetEntityCoordsNoOffset(s.ent, w.x, w.y, w.z, false, false, false)
                        -- Rueda hacia delante y se queda con el número mirando a la sala.
                        SetEntityRotation(s.ent, (1 - t) * 540.0, 0.0, p.h, 2, false)
                    end
                    if j and j.estado == 'venta' and s then
                        Borrar(s.ent)
                        salida[id] = nil
                    end
                else
                    QuitarBolas(id)
                end
            end
        end
        Wait(cerca and 0 or 500)
    end
end)

-- ---------------------------------------------------------------------------
--  Las pantallas
-- ---------------------------------------------------------------------------

local dui, txd, duiNace = nil, nil, 0
local duiN = 0
local PAGINA = ('nui://%s/ui/pantalla.html'):format(GetCurrentResourceName())

local function ParaPantalla()
    return json.encode({ juego = Juego(), ahora = GetCloudTimeAsInt(), marca = MARCA })
end

local function CrearDui()
    duiN = duiN + 1
    dui = CreateDui(PAGINA, 1600, 900)
    local limite = GetGameTimer() + 5000
    while not IsDuiAvailable(dui) and GetGameTimer() < limite do Wait(20) end
    -- Un runtime txd no se puede borrar: si el navegador se recrea, nombre nuevo.
    txd = 'origen_bingo_pantalla_' .. duiN
    local t = CreateRuntimeTxd(txd)
    CreateRuntimeTextureFromDuiHandle(t, 'pantalla', GetDuiHandle(dui))
    duiNace = GetGameTimer()
    -- La página tarda un poco en estar escuchando.
    SetTimeout(1200, function() if dui then SendDuiMessage(dui, ParaPantalla()) end end)
end

local function DestruirDui()
    if dui then DestroyDui(dui) end
    dui, txd = nil, nil
end

--- Las cuatro esquinas del cristal en el mundo: arriba-dcha, arriba-izq, abajo-dcha, abajo-izq.
local function Esquinas(e, m)
    local s = m.pantalla
    return GetOffsetFromEntityInWorldCoords(e, s.x1, s.y, s.z1), GetOffsetFromEntityInWorldCoords(e, s.x0, s.y, s.z1),
           GetOffsetFromEntityInWorldCoords(e, s.x1, s.y, s.z0), GetOffsetFromEntityInWorldCoords(e, s.x0, s.y, s.z0)
end

CreateThread(function()
    local lejos = 0
    while true do
        local yo = GetEntityCoords(PlayerPedId())
        local visibles = {}
        for id, o in pairs(objetos) do
            local p = piezas[id]
            if p and (p.tipo == 'panel' or p.tipo == 'pantalla') and DoesEntityExist(o.ent)
                and #(yo - vector3(p.x, p.y, p.z)) < 45.0 then
                visibles[#visibles + 1] = { e = o.ent, m = Modelos[Config.Pieza[p.tipo].modelo] }
            end
        end

        if #visibles > 0 then
            lejos = 0
            if not dui then CrearDui() end
            for _, v in ipairs(visibles) do
                local c1, c2, c3, c4 = Esquinas(v.e, v.m)
                local t, n = txd, 'pantalla'
                -- Las dos caras: por detrás la tapa el propio panel.
                DrawTexturedPoly(c1.x, c1.y, c1.z, c2.x, c2.y, c2.z, c4.x, c4.y, c4.z, 255, 255, 255, 255, t, n, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0)
                DrawTexturedPoly(c1.x, c1.y, c1.z, c4.x, c4.y, c4.z, c3.x, c3.y, c3.z, 255, 255, 255, 255, t, n, 1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 1.0, 1.0, 0.0)
                DrawTexturedPoly(c4.x, c4.y, c4.z, c2.x, c2.y, c2.z, c1.x, c1.y, c1.z, 255, 255, 255, 255, t, n, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0)
                DrawTexturedPoly(c3.x, c3.y, c3.z, c4.x, c4.y, c4.z, c1.x, c1.y, c1.z, 255, 255, 255, 255, t, n, 1.0, 1.0, 0.0, 0.0, 1.0, 0.0, 1.0, 0.0, 0.0)
            end
            Wait(0)
        else
            -- Un rato sin pantallas cerca y el navegador se apaga.
            lejos = lejos + 1
            if dui and lejos > 20 then DestruirDui() end
            Wait(500)
        end
    end
end)

-- ---------------------------------------------------------------------------
--  El estado de la partida: pantallas, cartones y avisos
-- ---------------------------------------------------------------------------

local misCartones = {}
local enSala = false

local function MandarJuego()
    local j = Juego()
    SendNUIMessage({ a = 'juego', juego = j, ahora = GetCloudTimeAsInt() })
    if dui and GetGameTimer() - duiNace > 1200 then SendDuiMessage(dui, ParaPantalla()) end
end

local function Nombres(l)
    if not l or #l == 0 then return '' end
    if #l <= 2 then return table.concat(l, ' y ') end
    return ('%s, %s y %d más'):format(l[1], l[2], #l - 2)
end

local antes = { linea = nil, bingo = nil, n = nil }
AddStateBagChangeHandler('bingo', 'global', function(_, _, j)
    if not j then return end
    -- El handler llega antes de que GlobalState tenga el valor nuevo.
    SetTimeout(0, function()
        MandarJuego()
        local interesa = enSala or #misCartones > 0
        if j.n ~= antes.n then
            antes.n, antes.linea, antes.bingo = j.n, j.linea ~= nil, j.bingo ~= nil
            return
        end
        if j.linea and not antes.linea and interesa then
            Aviso(('¡Línea! %s · %s $'):format(Nombres(j.linea.nombres), j.linea.importe), 'success')
        end
        if j.bingo and not antes.bingo and interesa then
            Aviso(('¡BINGO! %s · %s $'):format(Nombres(j.bingo.nombres), j.bingo.importe), 'success')
        end
        antes.linea, antes.bingo = j.linea ~= nil, j.bingo ~= nil
    end)
end)

RegisterNetEvent('origen_bingo:cl:cartones', function(n, lista)
    misCartones = lista or {}
    SendNUIMessage({ a = 'cartones', n = n, cartones = misCartones })
end)

-- ---------------------------------------------------------------------------
--  Cerca de las salas: poner las piezas, ver los cartones, la taquilla
-- ---------------------------------------------------------------------------

local function EnTaquilla()
    local yo = GetEntityCoords(PlayerPedId())
    for _, p in pairs(piezas) do
        if (p.tipo == 'taquilla' or p.tipo == 'empleado') and #(yo - vector3(p.x, p.y, p.z + 0.9)) < Config.Alcance then
            return p
        end
    end
    return nil
end

CreateThread(function()
    while not cargado do Wait(500) end
    while true do
        local yo = GetEntityCoords(PlayerPedId())
        local sala = false
        for id, s in pairs(salas) do
            local d = #(yo - vector3(s.x, s.y, s.z))
            if d < Config.Distancia and not dentro[id] then EntrarEn(s)
            elseif d > Config.Distancia + 10.0 and dentro[id] then SalirDe(id) end
            if d < Config.Radio then sala = true end
        end
        if sala ~= enSala then
            enSala = sala
            SendNUIMessage({ a = 'ver', ver = sala })
        end
        Wait(1000)
    end
end)

local function AbrirTaquilla()
    if panel or ajustando then return end
    local t = lib.callback.await('origen_bingo:taquilla', false)
    if not t then return Aviso('Tienes que estar en la taquilla.', 'error') end
    panel = 'taquilla'
    MandarJuego()
    SendNUIMessage({ a = 'abrir', modo = 'taquilla', datos = t })
    SetNuiFocus(true, true)
end

CreateThread(function()
    local mostrando = false
    while true do
        local p = (not panel and not ajustando) and EnTaquilla() or nil
        if p then
            if not mostrando then
                exports.origen_notify:DrawText('E', 'Comprar cartones de bingo')
                mostrando = true
            end
            if IsControlJustReleased(0, 38) then
                exports.origen_notify:HideText()
                mostrando = false
                AbrirTaquilla()
            end
            Wait(0)
        else
            if mostrando then
                exports.origen_notify:HideText()
                mostrando = false
            end
            Wait(400)
        end
    end
end)

RegisterNUICallback('comprar', function(d, cb)
    if panel ~= 'taquilla' then return cb({ ok = false }) end
    cb(lib.callback.await('origen_bingo:comprar', false, tonumber(d.cuantos), d.medio) or { ok = false })
end)

-- ---------------------------------------------------------------------------
--  Lo que llega del servidor
-- ---------------------------------------------------------------------------

local MandarDatos

RegisterNetEvent('origen_bingo:cl:cambio', function(clase, d)
    if clase == 'sala' then
        salas[d.id] = Decimales(d)
        Chincheta(d)
    elseif clase == 'sala_fuera' then
        SalirDe(d)
        salas[d] = nil
        OrigenMapa.Quitar('origen_bingo_' .. d)
        for id, p in pairs(piezas) do
            if p.sala == d then piezas[id] = nil end
        end
    elseif clase == 'pieza' then
        Decimales(d)
        piezas[d.id] = d
        QuitarBolas(d.id)
        if dentro[d.sala] then PonerObjeto(d) else QuitarObjeto(d.id) end
    elseif clase == 'pieza_fuera' then
        QuitarBolas(d)
        QuitarObjeto(d)
        piezas[d] = nil
    end
    if panel == 'config' and MandarDatos then MandarDatos() end
end)

CreateThread(function()
    local d = lib.callback.await('origen_bingo:datos', false)
    for id, s in pairs(d.salas or {}) do
        salas[tonumber(id)] = Decimales(s)
        Chincheta(s)
    end
    for id, p in pairs(d.piezas or {}) do piezas[tonumber(id)] = Decimales(p) end
    cargado = true

    local c = lib.callback.await('origen_bingo:misCartones', false)
    if c then
        misCartones = c.cartones or {}
        SendNUIMessage({ a = 'cartones', n = c.n, cartones = misCartones })
    end
    MandarJuego()
end)

-- ---------------------------------------------------------------------------
--  El configurador: colocar mirando
-- ---------------------------------------------------------------------------

--- A dónde apunta la cámara.
local function Apuntado()
    local o = GetGameplayCamCoord()
    local r = GetGameplayCamRot(2)
    local rx, rz = math.rad(r.x), math.rad(r.z)
    local d = vector3(-math.sin(rz) * math.cos(rx), math.cos(rz) * math.cos(rx), math.sin(rx))
    local f = o + d * 20.0
    local rayo = StartExpensiveSynchronousShapeTestLosProbe(o.x, o.y, o.z, f.x, f.y, f.z, 1 + 16, PlayerPedId(), 4)
    local _, toca, donde = GetShapeTestResult(rayo)
    return toca == 1 and donde or nil
end

local TECLAS = { 14, 15, 16, 17, 10, 11, 172, 173, 174, 175, 38, 47, 73, 21 }

--[[ Colocar una pieza viéndola. `o.tipo` qué pieza; `o.pose` de dónde se parte
     (mover una que ya está). Sin pose, sigue a la mira.

     Lo que se guarda es el SUELO (o la pared, para la pantalla): el origen de
     los props propios está en su base, y el del empleado se sube un metro al
     ponerlo. ]]
local function Ajustar(o)
    local tipo = Config.Pieza[o.tipo]
    local P, libre
    if o.pose then
        P = { x = o.pose.x, y = o.pose.y, z = o.pose.z, h = o.pose.h }
        libre = false
    else
        local yo = GetEntityCoords(PlayerPedId())
        P = { x = yo.x, y = yo.y, z = yo.z - 1.0, h = GetEntityHeading(PlayerPedId()) }
        libre = true
    end
    local alza = tipo.ped and 1.0 or 0.0

    local fantasma
    local hash = Cargar(tipo.ped or tipo.modelo)
    if hash then
        if tipo.ped then
            fantasma = CreatePed(4, hash, P.x, P.y, P.z + alza, P.h, false, false)
            SetBlockingOfNonTemporaryEvents(fantasma, true)
            SetEntityInvincible(fantasma, true)
        else
            fantasma = CreateObjectNoOffset(hash, P.x, P.y, P.z, false, false, false)
        end
        SetEntityAlpha(fantasma, 190, false)
        SetEntityCollision(fantasma, false, false)
        FreezeEntityPosition(fantasma, true)
        SetModelAsNoLongerNeeded(hash)
    end
    sobrantes = { fantasma }

    local function Controles()
        local lista = {}
        lista[#lista + 1] = { key = 'G', text = libre and 'Fijar aquí y afinar' or 'Volver a seguir la mira' }
        if not libre then lista[#lista + 1] = { key = '←↑↓→', text = 'Mover 1 cm' } end
        lista[#lista + 1] = { key = 'RePág/AvPág', text = 'Subir / bajar' }
        lista[#lista + 1] = { key = 'Rueda', text = 'Girar' }
        lista[#lista + 1] = { key = 'Shift', text = 'Pasos grandes' }
        lista[#lista + 1] = { key = 'E', text = 'Poner aquí' }
        lista[#lista + 1] = { key = 'X', text = 'Salir' }
        pcall(function() exports.origen_hud:setupControls(lista) end)
    end
    Controles()

    local function Pulsa(c) return IsDisabledControlJustPressed(0, c) end
    local resultado = nil
    ajustando = true
    while true do
        Wait(0)
        for _, c in ipairs(TECLAS) do DisableControlAction(0, c, true) end

        local grande = IsDisabledControlPressed(0, 21)
        local paso = grande and 0.05 or 0.01
        local giroP = grande and 15.0 or 2.0
        local dx, dy, dz, dh = 0.0, 0.0, 0.0, 0.0

        if Pulsa(47) then libre = not libre Controles() end

        if libre then
            local donde = Apuntado()
            if donde then P.x, P.y, P.z = donde.x, donde.y, donde.z end
        else
            -- Las flechas, respecto de la cámara: arriba es alejar, derecha es derecha.
            local rz = math.rad(GetGameplayCamRot(2).z)
            local ax, ay = -math.sin(rz), math.cos(rz)
            if Pulsa(172) then dx, dy = dx + ax * paso, dy + ay * paso end
            if Pulsa(173) then dx, dy = dx - ax * paso, dy - ay * paso end
            if Pulsa(175) then dx, dy = dx + ay * paso, dy - ax * paso end
            if Pulsa(174) then dx, dy = dx - ay * paso, dy + ax * paso end
        end
        if Pulsa(10) then dz = paso end
        if Pulsa(11) then dz = -paso end
        if Pulsa(15) or Pulsa(17) then dh = giroP end
        if Pulsa(14) or Pulsa(16) then dh = -giroP end
        P.x, P.y, P.z, P.h = P.x + dx, P.y + dy, P.z + dz, (P.h + dh) % 360

        if fantasma then
            SetEntityCoordsNoOffset(fantasma, P.x, P.y, P.z + alza, false, false, false)
            SetEntityHeading(fantasma, P.h)
        end
        -- La flecha del frente: hacia dónde mira la pieza (su cara va hacia ti).
        local r = math.rad(P.h)
        DrawMarker(2, P.x + math.sin(r) * 0.9, P.y - math.cos(r) * 0.9, P.z + 0.15, 0.0, 0.0, 0.0, 90.0, 0.0, -P.h, 0.25, 0.25, 0.25, 216, 27, 85, 220, false, false, 2, false, nil, nil, false)

        if Pulsa(38) then resultado = P break end
        if Pulsa(73) then break end
    end
    ajustando = false

    pcall(function() exports.origen_hud:hideControls() end)
    Borrar(fantasma)
    sobrantes = {}
    return resultado
end

-- ---------------------------------------------------------------------------
--  El configurador: el panel
-- ---------------------------------------------------------------------------

local function HudFuera(fuera)
    TriggerEvent('qv2:suppressHud', fuera)
    pcall(function() exports.origen_hud:toggleHud(not fuera) end)
    if GetResourceState('origen_map') == 'started' then
        pcall(function() exports.origen_map:Apartar(fuera) end)
    end
end

local function Datos()
    local yo = GetEntityCoords(PlayerPedId())
    local cuantos, taquillas, ps = {}, {}, {}
    for _, p in pairs(piezas) do
        cuantos[p.sala] = (cuantos[p.sala] or 0) + 1
        if p.tipo == 'taquilla' or p.tipo == 'empleado' then taquillas[p.sala] = (taquillas[p.sala] or 0) + 1 end
        ps[#ps + 1] = { id = p.id, sala = p.sala, tipo = p.tipo, nombre = Config.Pieza[p.tipo].nombre,
                        dist = #(yo - vector3(p.x, p.y, p.z)), h = p.h }
    end
    table.sort(ps, function(a, b) return a.dist < b.dist end)
    local ss = {}
    for _, s in pairs(salas) do
        ss[#ss + 1] = { id = s.id, nombre = s.nombre, piezas = cuantos[s.id] or 0, taquillas = taquillas[s.id] or 0,
                        dist = #(yo - vector3(s.x, s.y, s.z)) }
    end
    table.sort(ss, function(a, b) return a.dist < b.dist end)
    local tipos = {}
    for _, t in ipairs(Config.Piezas) do tipos[#tipos + 1] = { id = t.id, nombre = t.nombre } end
    return { salas = ss, piezas = ps, tipos = tipos, tope = Config.Topes.piezas, radio = math.floor(Config.Radio) }
end

MandarDatos = function()
    SendNUIMessage({ a = 'datos', datos = Datos() })
end

--- `tarde`: se llega desde el panel de admin, que tarda en apartarse. Si se
--- coge el ratón antes, su pantalla de carga se queda con él.
local function AbrirPanel(seccion, sala, tarde)
    if panel then return end
    panel = 'config'
    HudFuera(true)
    MandarJuego()
    SendNUIMessage({ a = 'abrir', modo = 'config', datos = Datos(), seccion = seccion, sala = sala })
    if tarde then
        CreateThread(function()
            Wait(2800)
            if panel then SetNuiFocus(true, true) end
        end)
    else
        SetNuiFocus(true, true)
    end

    -- La flecha sobre la pieza que se señala en la lista.
    CreateThread(function()
        while panel == 'config' do
            local p = senalado and piezas[senalado]
            if p then
                DrawMarker(2, p.x, p.y, p.z + 2.6, 0.0, 0.0, 0.0, 180.0, 0.0, 0.0, 0.35, 0.35, 0.35, 216, 27, 85, 220, true, true, 2, false, nil, nil, false)
            end
            Wait(p and 0 or 200)
        end
    end)
end

--- `sigue`: no es un cierre de verdad, se sale al juego a colocar algo y se
--- vuelve. Solo el cierre de verdad devuelve al panel de admin.
local function CerrarPanel(sigue)
    if not panel then return end
    local era = panel
    panel = false
    senalado = nil

    SetNuiFocus(false, false)             -- primero, siempre
    if era == 'config' then HudFuera(false) end

    SetTimeout(280, function()            -- 280 > los 260 de la transición
        if not panel then SendNUIMessage({ a = 'cerrar' }) end
    end)

    if era == 'config' and desdeElHub and not sigue then
        desdeElHub = false
        if GetResourceState('origen_admin') == 'started' then
            exports['origen_admin']:ReturnToScripts()
        end
    end
end

RegisterNUICallback('cerrar', function(_, cb)
    CerrarPanel()
    cb('ok')
end)

RegisterNUICallback('senalar', function(d, cb)
    senalado = tonumber(d.id)
    cb('ok')
end)

--- Marca en el mapa (con su ruta) una sala o una pieza.
RegisterNUICallback('ubicar', function(d, cb)
    cb('ok')
    local t = d.clase == 'pieza' and piezas[tonumber(d.id) or -1] or salas[tonumber(d.id) or -1]
    if not t then return end
    SetNewWaypoint(t.x, t.y)
    Aviso('Marcado en el mapa.', 'success')
end)

RegisterNUICallback('sala', function(d, cb)
    if panel ~= 'config' then return cb({ ok = false }) end
    cb(lib.callback.await('origen_bingo:admin:sala', false, d) or { ok = false })
end)

RegisterNUICallback('ajustes', function(d, cb)
    if panel ~= 'config' then return cb({ ok = false }) end
    cb(lib.callback.await('origen_bingo:admin:ajustes', false, d) or { ok = false })
end)

RegisterNUICallback('quitar', function(d, cb)
    if panel ~= 'config' then return cb({ ok = false }) end
    cb(lib.callback.await('origen_bingo:admin:pieza', false, { op = 'quitar', id = d.id }) or { ok = false })
end)

--- Sale del panel, hace lo que toque mirando al juego y vuelve a donde estaba.
local function ConElJuego(seccion, sala, que)
    CerrarPanel(true)
    CreateThread(function()
        Wait(300)
        que()
        AbrirPanel(seccion, sala)
    end)
end

RegisterNUICallback('colocar', function(d, cb)
    cb('ok')
    local s = salas[tonumber(d.sala) or -1]
    if not s or not Config.Pieza[d.tipo] or ajustando then return end
    ConElJuego('piezas', s.id, function()
        -- Una detrás de otra hasta que se salga.
        while true do
            local P = Ajustar({ tipo = d.tipo })
            if not P then break end
            local r = lib.callback.await('origen_bingo:admin:pieza', false,
                { op = 'poner', sala = s.id, tipo = d.tipo, x = P.x, y = P.y, z = P.z, h = P.h })
            if r and r.ok then Aviso(Config.Pieza[d.tipo].nombre .. ' puesta.', 'success')
            else Aviso(r and r.motivo or 'No se pudo poner.', 'error') end
        end
    end)
end)

RegisterNUICallback('mover', function(d, cb)
    cb('ok')
    local p = piezas[tonumber(d.id) or -1]
    if not p or ajustando then return end
    ConElJuego('piezas', p.sala, function()
        -- La de verdad se esconde mientras se mueve su fantasma.
        local o = objetos[p.id]
        if o then
            SetEntityVisible(o.ent, false, false)
            if o.jaula then SetEntityVisible(o.jaula, false, false) end
        end
        QuitarBolas(p.id)
        local P = Ajustar({ tipo = p.tipo, pose = p })
        if o and DoesEntityExist(o.ent) then
            SetEntityVisible(o.ent, true, false)
            if o.jaula then SetEntityVisible(o.jaula, true, false) end
        end
        if not P then return end
        local r = lib.callback.await('origen_bingo:admin:pieza', false,
            { op = 'mover', id = p.id, x = P.x, y = P.y, z = P.z, h = P.h })
        if not (r and r.ok) then Aviso(r and r.motivo or 'No se pudo mover.', 'error') end
    end)
end)

RegisterCommand(Config.Comando, function()
    if panel or ajustando then return end
    if not lib.callback.await('origen_bingo:admin:puede', false) then return end
    desdeElHub = false
    AbrirPanel()
end, false)

--- Como lo abre la pestaña Scripts del panel de administración. Si no se
--- puede, el panel de admin ya se apartó: que vuelva.
exports('openManagement', function()
    CreateThread(function()
        local puede = not panel and not ajustando and lib.callback.await('origen_bingo:admin:puede', false)
        if not puede then
            if GetResourceState('origen_admin') == 'started' then
                exports['origen_admin']:ReturnToScripts()
            end
            return
        end
        desdeElHub = true
        AbrirPanel(nil, nil, true)
    end)
end)

-- ---------------------------------------------------------------------------

AddEventHandler('onResourceStop', function(recurso)
    if recurso ~= GetCurrentResourceName() then return end
    for id in pairs(objetos) do QuitarBolas(id) QuitarObjeto(id) end
    for _, e in pairs(sobrantes) do Borrar(e) end
    for id in pairs(salas) do OrigenMapa.Quitar('origen_bingo_' .. id) end
    DestruirDui()
    pcall(function() exports.origen_notify:HideText() end)
    if panel then
        SetNuiFocus(false, false)
        HudFuera(false)
    end
    if ajustando then pcall(function() exports.origen_hud:hideControls() end) end
end)
