-- Packs, piezas sueltas y tamaño de la casa, en el cliente (ver
-- custom/server/packs.lua, que es quien manda). Aquí solo se enseña:
--   · en la cinta (custom/client/obra.lua), lo que la casa no tiene sale al
--     final de su categoría, apagado y con candado, y no se puede poner;
--   · junto a «Gastado», lo que le queda a la casa según su tamaño;
--   · el panel de admin de cosméticos y lo que necesita la pantalla de crear casas.
-- El servidor vuelve a mirarlo todo: saltarse esto no da nada.
local P = Config.Packs
local O = Config.Obra

PacksCliente = {}

local estado = nil          -- lo que dice el servidor de la casa de la cinta: { id, libre, packs, sueltas, tamano, limites, uso }
local gastadoObra = 0       -- lo cobrado (menos lo devuelto) por la obra en esta sesión

-- ── Qué está cerrado ────────────────────────────────────────────────────
local function Permitida(c)
    if c.tipo == 'f' then return P.Permite(estado, 'modelo', c.modelo), 'modelo', c.modelo end
    if c.tipo == 'm' then return P.Permite(estado, 'material', c.id), 'material', c.id end
    if P.Permite(estado, 'herramienta', c.id) then return true end
    -- una herramienta de estilos (barandilla, puerta secreta, trampilla) se abre con tener suelto uno de sus estilos
    local grupo = c.id == 'barandilla' and 'estilo:barandillas:' or c.id == 'secreto' and 'estilo:secretos:' or c.id == 'trampilla' and 'estilo:trampillas:' or nil
    if grupo and type(estado.sueltas) == 'table' then
        for clave in pairs(estado.sueltas) do
            if clave:sub(1, #grupo) == grupo then return true end
        end
    end
    return false, 'herramienta', c.id
end

--- Si la casa de la cinta no tiene esa cosa (una de las de la cinta: { tipo,
--- id | modelo }), el nombre de lo que le falta («Pack Cocina profesional»).
--- nil si la tiene, o si aún no se sabe qué tiene la casa (el servidor decide).
function PacksCliente.Bloqueada(c)
    if type(c) ~= 'table' or type(estado) ~= 'table' or type(estado.packs) ~= 'table' then return nil end
    local si, que, id = Permitida(c)
    if si then return nil end
    local pack = P.lista[P.PackDe(que, id)]
    return 'Pack ' .. (pack and pack.nombre or '')
end

--- ¿Le falta a la casa de la cinta ese estilo ('secretos', 'libreria')?
function PacksCliente.EstiloCerrado(grupo, id)
    if type(estado) ~= 'table' or type(estado.packs) ~= 'table' then return false end
    return not P.Permite(estado, 'estilo', grupo .. ':' .. tostring(id))
end

--- Las cosas de un grupo de la cinta como hay que enseñarlas en esta casa:
--- primero lo que tiene y detrás lo que no (saldrá con candado, al final de
--- su subgrupo), o sin lo que no tiene si Config.Packs.candado = false.
--- Devuelve una lista nueva: la que recibe no se toca.
function PacksCliente.Filtrar(cosas)
    if type(estado) ~= 'table' or type(cosas) ~= 'table' then return cosas end
    local si, no = {}, {}
    for _, c in ipairs(cosas) do
        if PacksCliente.Bloqueada(c) then no[#no + 1] = c else si[#si + 1] = c end
    end
    if #no == 0 then return cosas end
    if P.candado ~= false then
        for _, c in ipairs(no) do si[#si + 1] = c end
    end
    return si
end

-- ── El contador ─────────────────────────────────────────────────────────
local function Contar(t)
    local n = 0
    for _ in pairs(t or {}) do n = n + 1 end
    return n
end

local function Contador()
    if type(estado) ~= 'table' or not estado.libre or type(estado.limites) ~= 'table' then return nil end
    local o = Obra and Obra.Actual and Obra.Actual()
    if not o or tostring(o.id) ~= tostring(estado.id) then return nil end
    local l = estado.limites
    local objetos, tope = #GetGamePool('CObject'), O.maxObjetos or 2000
    return {
        tamano = estado.tamano and estado.tamano.nombre or '',
        celdas = { Contar(o.celdas), l.celdas },
        piezas = { Contar(o.piezas), l.piezas },
        muebles = { estado.uso and estado.uso.muebles or 0, l.muebles },
        objetos = objetos >= tope * 0.8 and { objetos, tope } or nil,
    }
end

local function Enviar()
    SendNUIMessage({ action = 'cintaExtra', contador = Contador() or false, gastado = gastadoObra })
end

local pidiendo = false
local function Pedir(casa)
    local r = lib.callback.await('origen_housing:packs:casa', false, casa)
    if type(r) == 'table' then estado = r end
    Enviar()
end

--- Lo llama la cinta al abrirse, antes de montar sus categorías: pide al
--- servidor lo que tiene esa casa.
function PacksCliente.AlAbrir(casa)
    estado = nil
    Pedir(casa)
end

-- Al comprar o quitar un mueble cambian los que quedan
local function Repasar()
    if pidiendo or type(estado) ~= 'table' then return end
    pidiendo = true
    SetTimeout(400, function()
        pidiendo = false
        if type(estado) == 'table' and Obra and Obra.CintaAbierta and Obra.CintaAbierta() then Pedir(estado.id) end
    end)
end

RegisterNetEvent('origen_housing:client:updateFurniture', function(houseID)
    if type(estado) == 'table' and tostring(houseID) == tostring(estado.id) then Repasar() end
end)

-- Cada cambio de obra mueve las celdas y las piezas que quedan (custom/client/obra.lua ya lo ha apuntado)
RegisterNetEvent('origen_housing:obra:cambio', function(id)
    if type(estado) == 'table' and tostring(id) == tostring(estado.id) then Enviar() end
end)

-- Lo que el servidor acaba de cobrar (o devolver, en negativo) por la obra
RegisterNetEvent('origen_housing:obra:cobro', function(neto)
    gastadoObra = gastadoObra + (tonumber(neto) or 0)
    Enviar()
end)

-- A la casa le han dado o quitado algo, o le han cambiado el tamaño
RegisterNetEvent('origen_housing:packs:cambio', function(nuevo)
    if type(nuevo) ~= 'table' or type(estado) ~= 'table' or tostring(nuevo.id) ~= tostring(estado.id) then return end
    estado = nuevo
    Enviar()
end)

-- Con la casa cerca del tope de objetos, el aviso se refresca solo
CreateThread(function()
    while true do
        Wait(3000)
        if type(estado) == 'table' and estado.libre and Obra and Obra.CintaAbierta and Obra.CintaAbierta() then Enviar() end
    end
end)

-- ── Crear una casa ──────────────────────────────────────────────────────
-- Lo que enseña la pantalla de crear casas (ui/js/packs.js): los tamaños y,
-- si quien crea puede darlos, los packs.
RegisterNUICallback('packsCatalogo', function(_, cb)
    local tamanos = {}
    for _, id in ipairs(O.tamanosOrden or {}) do
        local t = O.tamanos[id]
        tamanos[#tamanos + 1] = { id = id, nombre = t.nombre, descripcion = t.descripcion, celdas = t.celdas, piezas = t.piezas, muebles = t.muebles,
            plantas = t.plantasArriba, sotanos = t.sotanos }
    end
    local packs = {}
    if lib.callback.await('origen_housing:packs:puedeDar', false) == true then
        for _, id in ipairs(P.orden) do
            local pack = P.lista[id]
            if id ~= P.base and pack then
                packs[#packs + 1] = { id = id, nombre = pack.nombre, descripcion = pack.descripcion, grupo = P.NombreGrupo(P.Grupo(id)), piezas = P.Contenido(id).total }
            end
        end
    end
    local grupos = {}
    for q, g in ipairs(P.gruposOrden) do grupos[q] = P.NombreGrupo(g) end
    cb({ tamanos = tamanos, tamano = O.tamanoNueva, packs = packs, grupos = grupos })
end)

-- ── Panel de admin «Vivienda: cosméticos» ───────────────────────────────
-- A pantalla completa (ui/js/packs.js). Lo abre /casacosmeticos o el export
-- `exports.origen_housing:openCosmeticos()` (para el panel de admin del
-- servidor). El cliente solo lleva y trae: el servidor comprueba el permiso
-- en cada llamada.
local panel = false

-- Las piezas que se pueden dar sueltas: todo lo que es de un pack de pago
local function PiezasPosibles()
    local r = { material = {}, herramienta = {}, estilo = {}, modelo = {} }
    local function Meter(que, tabla)
        for id, pack in pairs(tabla) do
            if pack ~= P.base then
                local nombre = P.NombrePieza(que .. ':' .. id)
                r[que][#r[que] + 1] = { id = id, nombre = (nombre:gsub('^[^:]+: ', '')), pack = P.lista[pack] and P.lista[pack].nombre or pack }
            end
        end
        table.sort(r[que], function(a, b) return a.nombre < b.nombre end)
    end
    Meter('material', P.deMaterial)
    Meter('herramienta', P.deHerramienta)
    Meter('estilo', P.deEstilo)
    Meter('modelo', P.deModelo)
    return r
end

local function AbrirCosmeticos(casa)
    if panel then return end
    local r = lib.callback.await('origen_housing:cosmeticos:abrir', false)
    if not r then return Custom.Notify(Config.Translations.notify.error.noPermission, 'error', 5000) end
    panel = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'cosmeticos', ver = true, casa = casa or r.casa, posibles = PiezasPosibles(), ambito = P.ambito })
end

RegisterNetEvent('origen_housing:cosmeticos:abrir', function(casa)
    AbrirCosmeticos(casa)
end)

exports('openCosmeticos', function(casa)
    AbrirCosmeticos(casa and tostring(casa) or nil)
end)

RegisterNUICallback('cosmeticosCerrar', function(_, cb)
    cb({})
    if not panel then return end
    panel = false
    SetNuiFocus(false, false)
end)

RegisterNUICallback('cosmeticosBuscar', function(data, cb)
    cb(panel and lib.callback.await('origen_housing:cosmeticos:buscar', false, tostring(data and data.texto or '')) or false)
end)

RegisterNUICallback('cosmeticosCasa', function(data, cb)
    cb(panel and lib.callback.await('origen_housing:cosmeticos:casa', false, tostring(data and data.id or '')) or false)
end)

RegisterNUICallback('cosmeticosRegistro', function(_, cb)
    cb(panel and lib.callback.await('origen_housing:cosmeticos:registro', false) or false)
end)

RegisterNUICallback('cosmeticosOrden', function(data, cb)
    if not panel or type(data) ~= 'table' or type(data.orden) ~= 'table' then return cb(false) end
    cb(lib.callback.await('origen_housing:cosmeticos:orden', false, tostring(data.id or ''), data.orden) or false)
end)

AddEventHandler('onResourceStop', function(r)
    if r == GetCurrentResourceName() and panel then SetNuiFocus(false, false) end
end)
