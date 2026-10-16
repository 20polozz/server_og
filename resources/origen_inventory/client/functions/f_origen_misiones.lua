--[[
    La pestaña de Misiones.

    Era el diario de origen_quests: un panel propio que se abría con F5 sobre
    el juego, con su columna y su riel al canto derecho —los mismos que este—.
    Dos paneles idénticos abriéndose por separado en el mismo sitio.

    Ahora es una pestaña más, como Ciudad: el jugador consulta lo que lleva
    entre manos sin salir del panel en el que ya está, y F5 abre el inventario
    directamente por aquí.

    Aquí no hay lógica de misiones. Quién las tiene, cuál está fijada y qué se
    puede hacer con ellas lo sabe origen_quests; este fichero es sólo el cable
    entre esa puerta y la interfaz. Si el recurso no está en marcha, la
    pestaña se queda con su aviso en vez de reventar.
]]

local RECURSO = 'origen_quests'

local function Vivo()
    return GetResourceState(RECURSO) == 'started'
end

--- Llama a un export de misiones sin que un fallo suyo tumbe la pestaña.
local function Pedir(metodo, ...)
    if not Vivo() then return nil end
    local ok, valor = pcall(function(...)
        return exports[RECURSO][metodo](exports[RECURSO], ...)
    end, ...)
    if not ok then
        print(('^1[misiones]^0 %s fallo: %s'):format(metodo, tostring(valor)))
        return nil
    end
    return valor
end

--[[ Lo que se ve al entrar: las misiones activas, cuál está fijada, cuáles
     están plegadas del HUD y la hora del servidor.

     La hora hace falta para las cuentas atrás de los objetivos de aguantar:
     el reloj del navegador no es el del servidor, y sin ella el tiempo que
     queda se calcularía contra una referencia distinta cada vez. ]]
InventoryUI.On('GetMisiones', function()
    if not Vivo() then return { hay = false } end

    local datos = Pedir('MisionesDatos')
    if type(datos) ~= 'table' then return { hay = false } end

    datos.hay = true
    return datos
end)

--- Fijar una: es la que sale entera en el HUD y la que marca el mapa.
InventoryUI.On('MisionFijar', function(datos)
    return Pedir('MisionFijar', datos and datos.mission_id) == true
end)

--[[ «Seguir la fijada» (J en el pie del tema arcade): vuelve a poner el GPS
     en el siguiente objetivo de la que está fijada. Es lo mismo que fijarla
     otra vez, que en origen_quests ya limpia el punto viejo y pone el nuevo. ]]
InventoryUI.On('MisionSeguir', function()
    local datos = Pedir('MisionesDatos')
    local id = type(datos) == 'table' and datos.focused or nil
    if not id then return false end
    return Pedir('MisionFijar', id) == true
end)

--- Plegarla o desplegarla del HUD, sin abandonarla.
InventoryUI.On('MisionPlegar', function(datos)
    return Pedir('MisionPlegar', datos and datos.mission_id) == true
end)

--- Abandonarla. Lo confirma el servidor de misiones, que es quien la borra.
InventoryUI.On('MisionAbandonar', function(datos)
    return Pedir('MisionAbandonar', datos and datos.mission_id) == true
end)

--[[ Y el aviso cuando algo cambia mientras la pestaña está delante.

     Un objetivo se cumple solo —matas al último, llegas al punto, se acaba la
     cuenta atrás— y sin esto habría que salir y volver a entrar para verlo.
     origen_quests dispara este evento LOCAL en cada refresco suyo.

     Se manda siempre, esté abierta la pestaña o no: comprobarlo desde aquí
     obligaría a llevar la cuenta de qué está mirando la interfaz, y el
     mensaje que no le toca lo ignora ella sola. ]]
AddEventHandler('origen_quests:misiones', function()
    local datos = Pedir('MisionesDatos')
    if type(datos) ~= 'table' then return end

    datos.hay = true
    InventoryUI.Emit({ action = 'misiones', data = datos }, nil, true)
end)

--[[ Una que se acaba de completar.

     El historial es de la sesion —no se guarda en ninguna parte— asi que si
     nadie lo apunta al pasar, se pierde. Lo apunta la interfaz, que es quien
     lo enseña; aqui solo se le pasa el aviso. ]]
AddEventHandler('origen_quests:completada', function(nombre, resumen)
    InventoryUI.Emit({
        action = 'misionCompletada',
        data = { name = nombre, summary = resumen or {} },
    }, nil, true)
end)
