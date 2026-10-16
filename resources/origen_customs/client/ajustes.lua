--[[ Los ajustes que cambia el panel de admin y también usa el cliente
     (distancias, cámara y piezas bloqueadas). Llegan por GlobalState y se
     vuelcan sobre las MISMAS tablas de Config: la cámara guarda la referencia
     (`local C = Config.Camara`) y con una tabla nueva seguiría con la vieja. ]]

local function Volcar(destino, origen)
    if type(destino) ~= 'table' or type(origen) ~= 'table' then return end
    for k in pairs(destino) do destino[k] = nil end
    for k, v in pairs(origen) do destino[k] = v end
end

local function Aplicar(a)
    if type(a) ~= 'table' then return end
    Volcar(Config.Acceso, a.acceso)
    Volcar(Config.Camara, a.camara)
    Volcar(Config.PiezasBloqueadas, a.bloqueadas)
end

Aplicar(GlobalState['origen_customs:ajustes'])

AddStateBagChangeHandler('origen_customs:ajustes', 'global', function(_, _, valor)
    Aplicar(valor)
end)
