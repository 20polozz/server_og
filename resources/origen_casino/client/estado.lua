--[[ ══════════════════════════════════════════════════════════════════════════
     EL ESTADO DEL CASINO EN ESTE CLIENTE

     Es un espejo: lo que manda es el servidor. Aquí solo se guarda para pintar
     y para no preguntar lo mismo en cada fotograma.

     Los puntos —las mesas, las máquinas, los mostradores— llegan por
     GlobalState, no por un evento: así los tiene también quien conecte dentro
     de diez minutos, sin que nadie tenga que acordarse de mandárselos.
   ══════════════════════════════════════════════════════════════════════════ ]]

C = {
    puntos = {},          -- [id] = punto tal y como lo manda el servidor
    abierto = true,
    jackpot = 0,
    sesion = nil,         -- { punto, tipo, juego, plaza, asiento } si está sentado
    pantalla = nil,       -- lo que se está enseñando: 'juego' | 'caja' | 'admin'
    colocando = false,
    saldo = { fichas = 0, socio = false, vip = false },
}

function C.Aviso(titulo, texto, tipo, duracion)
    lib.notify({
        title = titulo or Config.General.nombre,
        description = texto,
        type = tipo or 'inform',
        duration = duracion,
    })
end

function C.Enviar(accion, datos)
    SendNUIMessage({ accion = accion, datos = datos })
end

--[[ El foco del ratón, en un solo sitio. Encenderlo desde tres ficheros
     distintos es cómo se acaba con el ratón preso y el juego sin responder:
     uno lo apaga, otro lo vuelve a encender, y nadie sabe quién manda. ]]
local conFoco = false

function C.Foco(quiero)
    if quiero == conFoco then return end
    conFoco = quiero
    SetNuiFocus(quiero, quiero)
end

function C.HayFoco()
    return conFoco
end

--[[ Raton soltado a la fuerza (vigilante de origen_map/shared/foco.lua o
     `soltarraton`): el foco ya no es nuestro y no hay pantalla. Sin esto
     `conFoco` seguia en true y el siguiente C.Foco(true) no hacia nada.
     Cada pantalla (caja, admin, juego) recoge lo suyo en su fichero. ]]
if OrigenFoco then
    OrigenFoco.AlSoltar(function()
        conFoco = false
        C.pantalla = nil
    end)
end

-- ── Los puntos ────────────────────────────────────────────────────────────

local suscriptores = {}

function C.AlCambiarPuntos(fn)
    suscriptores[#suscriptores + 1] = fn
end

local function Repartir(lista)
    local nuevos = {}
    for _, p in ipairs(lista or {}) do nuevos[p.id] = p end
    C.puntos = nuevos
    for _, fn in ipairs(suscriptores) do
        local ok, err = pcall(fn, nuevos)
        if not ok then print('[casino] al repartir los puntos: ' .. tostring(err)) end
    end
end

AddStateBagChangeHandler('origen_casino:puntos', 'global', function(_, _, valor)
    if type(valor) == 'table' then Repartir(valor) end
end)

AddStateBagChangeHandler('origen_casino:abierto', 'global', function(_, _, valor)
    C.abierto = valor ~= false
end)

AddStateBagChangeHandler('origen_casino:jackpot', 'global', function(_, _, valor)
    C.jackpot = tonumber(valor) or 0
    if C.pantalla == 'juego' then C.Enviar('jackpot', C.jackpot) end
end)

CreateThread(function()
    -- Al arrancar el recurso (o al reiniciarlo) el estado ya está puesto: hay
    -- que leerlo, porque el cambio ya pasó y no va a volver a pasar.
    Wait(500)
    local lista = GlobalState['origen_casino:puntos']
    if type(lista) == 'table' then Repartir(lista) end
    C.abierto = GlobalState['origen_casino:abierto'] ~= false
    C.jackpot = tonumber(GlobalState['origen_casino:jackpot']) or 0
end)

-- ── El blip del casino ────────────────────────────────────────────────────

CreateThread(function()
    Wait(2000)
    local b = Config.General.blip
    if not b or not b.activo then return end
    local z = Config.General.zona
    OrigenMapa.Poner('casino', {
        x = z.x, y = z.y, z = z.z,
        cat = 'activities',
        icono = b.icono or 'casino',
        nombre = b.nombre or Config.General.nombre,
    })
end)

-- ── Avisos del servidor ───────────────────────────────────────────────────

RegisterNetEvent('origen_casino:decir', function(texto, tipo)
    C.Aviso(Config.General.nombre, texto, tipo)
end)

RegisterNetEvent('origen_casino:anuncio', function(datos)
    if type(datos) ~= 'table' then return end
    C.Aviso(
        datos.tipo == 'jackpot' and 'HA CAÍDO EL BOTE' or Config.General.nombre,
        datos.texto,
        'success', 12000)
end)

-- ── El saldo, para las pantallas ──────────────────────────────────────────

function C.RefrescarSaldo()
    local datos = lib.callback.await('origen_casino:saldo', false)
    if datos and datos.ok then
        C.saldo = datos
        C.jackpot = datos.jackpot or C.jackpot
    end
    return C.saldo
end

AddEventHandler('onResourceStop', function(recurso)
    if recurso == GetCurrentResourceName() then
        SetNuiFocus(false, false)
    end
end)
