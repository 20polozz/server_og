--[[
    Datos del personaje para la pestaña de personaje (diseño 9a).

    La pestaña solo sabia de ropa. La 9a pide ademas quien eres, cuanto llevas
    encima, en que trabajas, que equipo llevas y que licencias tienes.

    Aqui NO se usa Bridge.GetPlayerInfo, aunque exista: esa funcion devuelve
    nil, nil, nil si el jugador no tiene banda, y en Qbox eso es lo normal. Con
    ella, un personaje sin banda se quedaba sin nombre, sin empleo y sin nada,
    que es justo lo que pasaba. Se leen los datos crudos del core y se compone
    cada pieza por separado, para que la falta de una no arrastre a las demas.
]]

--- Lee un valor siguiendo un camino, sin reventar si algo por medio no existe.
local function Camino(tabla, ...)
    local actual = tabla
    for _, clave in ipairs({ ... }) do
        if type(actual) ~= 'table' then return nil end
        actual = actual[clave]
    end
    return actual
end

--- Los datos del jugador, por las dos vias que expone Qbox. Si una falla se
--- prueba la otra: en instalaciones distintas responde una u otra.
function DatosJugadorPublico()
    local datos

    if GetResourceState('qb-core'):match('start') then
        local ok, core = pcall(function() return exports['qb-core']:GetCoreObject() end)
        if ok and core and core.Functions and core.Functions.GetPlayerData then
            local ok2, d = pcall(core.Functions.GetPlayerData)
            if ok2 and type(d) == 'table' then datos = d end
        end
    end

    if not datos and GetResourceState('qbx_core'):match('start') then
        local ok, d = pcall(function() return exports.qbx_core:GetPlayerData() end)
        if ok and type(d) == 'table' then datos = d end
    end

    return datos
end

--- La edad a partir de la fecha de nacimiento. Llega como AAAA-MM-DD o
--- DD/MM/AAAA segun la instalacion, asi que se aceptan las dos.
local function EdadDe(nacimiento)
    if type(nacimiento) ~= 'string' then return nil end

    local a, m, d = nacimiento:match('^(%d%d%d%d)-(%d%d)-(%d%d)')
    if not a then
        d, m, a = nacimiento:match('^(%d%d)/(%d%d)/(%d%d%d%d)')
    end
    if not a then return nil end

    --[[ Con GetLocalTime, NO con os.date: la biblioteca `os` no existe en el
         entorno Lua del cliente de FiveM. Usarla no daba un aviso, daba un
         error que reventaba la llamada entera, y la pestaña se quedaba sin
         nombre, sin dinero y sin empleo aunque los datos estuvieran ahi. ]]
    local anio, mes, dia = GetLocalTime()

    local edad = anio - tonumber(a)
    if mes < tonumber(m) or (mes == tonumber(m) and dia < tonumber(d)) then
        edad = edad - 1
    end
    if edad < 0 or edad > 120 then return nil end
    return edad
end

--[[ El equipo que se lleva encima. La maqueta lo pone junto a las licencias
     porque responde a la misma pregunta: ¿voy preparado?

     Cada pieza se comprueba donde de verdad vive:
       chaleco  → el blindaje del ped, que es el que para las balas
       mochila  → la prenda puesta
       radio    → tener el objeto en la bolsa ]]
local function EquipoDe(datos)
    local equipo = {}

    local blindaje = GetPedArmour(PlayerPedId()) or 0
    equipo[#equipo + 1] = {
        nombre = 'Chaleco',
        tiene = blindaje > 0,
        valor = blindaje > 0 and (math.floor(blindaje) .. ' %') or 'Sin',
    }

    local ropa = Camino(datos, 'clothing') or {}
    local mochila = Camino(ropa, 'bags')
    equipo[#equipo + 1] = {
        nombre = 'Mochila',
        tiene = mochila ~= nil and mochila ~= 0,
        valor = (mochila ~= nil and mochila ~= 0) and 'Puesta' or 'Sin',
    }

    return equipo
end

function EstadoPersonaje()
    local datos = DatosJugadorPublico()

    -- Identidad
    local nombre, telefono, edad
    local ficha = Camino(datos, 'charinfo')
    if type(ficha) == 'table' then
        if ficha.firstname then
            nombre = (ficha.firstname .. ' ' .. (ficha.lastname or '')):gsub('%s+$', '')
        end
        telefono = ficha.phone
        edad = EdadDe(ficha.birthdate)
    end

    -- Dinero. En Qbox vive en money.cash y money.bank; otros usan accounts.
    local efectivo = Camino(datos, 'money', 'cash')
        or Camino(datos, 'money', 'money')
        or Camino(datos, 'accounts', 'money')
    local banco = Camino(datos, 'money', 'bank')
        or Camino(datos, 'accounts', 'bank')

    -- Empleo, leido directo en vez de por el puente.
    local trabajo = Camino(datos, 'job')
    local empleo
    if type(trabajo) == 'table' and trabajo.label then
        local grado = trabajo.grade
        if type(grado) == 'table' then grado = grado.level or grado.name end
        empleo = {
            label = trabajo.label,
            grado = grado or 0,
            -- Qbox usa onduty, qb-core usa isduty. Se miran las dos.
            deServicio = (trabajo.onduty or trabajo.isduty) and true or false,
            esJefe = trabajo.isboss and true or false,
        }
    end

    -- Licencias. Cada instalacion guarda las suyas, asi que se recorre lo que
    -- haya en vez de pedir unas concretas.
    local licencias = {}
    local origen = Camino(datos, 'metadata', 'licences')
        or Camino(datos, 'metadata', 'licenses')
    if type(origen) == 'table' then
        local rotulos = {
            driver = 'Conducir', drive = 'Conducir',
            weapon = 'Armas', firearm = 'Armas',
            business = 'Negocios',
            pilot = 'Piloto',
            boat = 'Náutica', fishing = 'Pesca',
        }
        for clave, valor in pairs(origen) do
            licencias[#licencias + 1] = {
                nombre = rotulos[clave] or (tostring(clave):sub(1, 1):upper() .. tostring(clave):sub(2)),
                tiene = valor and true or false,
            }
        end
        table.sort(licencias, function(a, b) return a.nombre < b.nombre end)
    end

    return {
        nombre = nombre,
        id = Camino(datos, 'citizenid'),
        edad = edad,
        telefono = telefono,
        efectivo = efectivo,
        banco = banco,
        empleo = empleo,
        equipo = EquipoDe(datos),
        licencias = licencias,
        -- Para poder ver en consola por que falta algo, si falta.
        hayDatos = datos ~= nil,
    }
end

InventoryUI.On('GetCharacterState', EstadoPersonaje)

--[[ Fichar entrada y salida. Es de las pocas cosas del panel que cambian algo
     del mundo, asi que se manda por el comando del core en vez de tocar los
     datos desde aqui. ]]
InventoryUI.On('ToggleDuty', function()
    ExecuteCommand('duty')
    return true
end)

--[[ Un comando para ver que devuelve, porque si el framework guarda el dinero
     en otro sitio la pestaña se queda muda y desde fuera no se sabe por que. ]]
RegisterCommand('verpj', function()
    local datos = DatosJugadorPublico()
    if not datos then
        print('^1[pruebas]^0 El core no devuelve datos del jugador.')
        return
    end
    print('^2[pruebas]^0 claves de PlayerData: ' .. table.concat((function()
        local k = {}
        for clave in pairs(datos) do k[#k + 1] = clave end
        table.sort(k)
        return k
    end)(), ', '))
    print(('^2[pruebas]^0 dinero: cash=%s bank=%s')
        :format(tostring(Camino(datos, 'money', 'cash')), tostring(Camino(datos, 'money', 'bank'))))
    print(('^2[pruebas]^0 empleo: %s  licencias: %s')
        :format(tostring(Camino(datos, 'job', 'label')),
                tostring(Camino(datos, 'metadata', 'licences') and 'si' or 'no')))
end, false)

--[[ Puente de diagnostico.

     El comando `verpj` de arriba imprime en la consola del JUGADOR, y para
     mirar por que la pestaña sale vacia hace falta verlo desde fuera. Esto
     manda lo mismo al servidor, que lo escribe en su consola. ]]
RegisterNetEvent('origen_inventory:pruebas:pedirPj', function()
    local datos = DatosJugadorPublico()
    local claves = {}
    if type(datos) == 'table' then
        for k in pairs(datos) do claves[#claves + 1] = k end
        table.sort(claves)
    end

    -- Y lo que devuelve EXACTAMENTE la llamada que usa la pestaña, que es lo
    -- que hay que mirar: los datos crudos pueden estar y la respuesta fallar.
    local okResp, resp = pcall(EstadoPersonaje)

    TriggerServerEvent('origen_inventory:pruebas:pj', {
        respuestaOk = okResp,
        respuesta = okResp and resp or tostring(resp),
        hayDatos = datos ~= nil,
        claves = claves,
        cash = datos and datos.money and datos.money.cash,
        bank = datos and datos.money and datos.money.bank,
        job = datos and datos.job and datos.job.label,
        nombre = datos and datos.charinfo and datos.charinfo.firstname,
        telefono = datos and datos.charinfo and datos.charinfo.phone,
        nacimiento = datos and datos.charinfo and datos.charinfo.birthdate,
        citizenid = datos and datos.citizenid,
        licencias = datos and datos.metadata and (datos.metadata.licences or datos.metadata.licenses) and 'si' or 'no',
    })
end)

--[[ «Guardar atuendo» del pie de la pestaña Personaje: guarda lo que llevas
     puesto con el nombre que se escriba. El guardado es de origen_clothing
     (GuardarAtuendoPuesto); aqui solo se le pasa el nombre. ]]
InventoryUI.On('GuardarAtuendo', function(datos)
    if GetResourceState('origen_clothing') ~= 'started' then return false end
    local ok, r = pcall(function()
        return exports.origen_clothing:GuardarAtuendoPuesto(datos and datos.nombre)
    end)
    return ok and r == true
end)
