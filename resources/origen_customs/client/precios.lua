--[[ El editor de precios para admins (/admincustoms).

     /admincustoms abre el panel de administración del taller (client/admin.lua,
     a pantalla completa) directamente en «Precios del tuneo», que es el mismo
     editor con todos los precios a la vista. Este menú de ox_lib (que se ve
     con org-menu y org-input) queda solo para quien tiene el permiso del
     comando (`Comando:admincustom`) pero no el del panel (`origen_customs`):
     así nadie pierde el acceso que ya tenía.

     Un menú con cada precio y lo que vale ahora; al elegir uno, un diálogo
     para cambiarlo (un campo por nivel en los de rendimiento). Lo que se
     guarda lo decide el servidor: vuelve a mirar el permiso y sanea cada
     número antes de escribirlo en `origen_customs_precios`. ]]

local NOMBRES = {
    { 'pieza', 'Pieza estética' }, { 'pinturaGTA', 'Pintura de la carta' }, { 'pinturaRGB', 'Pintura a medida' },
    { 'perla', 'Perlado' }, { 'colorLlantas', 'Color de llantas' }, { 'colorInterior', 'Color del interior' },
    { 'colorSalpicadero', 'Color del salpicadero' }, { 'vinilo', 'Vinilo' }, { 'llantas', 'Llantas' },
    { 'neumaticos', 'Neumáticos de perfil' }, { 'humo', 'Humo de ruedas' }, { 'xenon', 'Faros de xenón' },
    { 'colorXenon', 'Color del xenón' }, { 'neon', 'Neón (por lado)' }, { 'colorNeon', 'Color del neón' },
    { 'tintado', 'Tintado de lunas' }, { 'matricula', 'Estilo de matrícula' }, { 'extra', 'Extras' },
    { 'bocina', 'Claxon' }, { 'motor', 'Motor (por nivel)' }, { 'frenos', 'Frenos (por nivel)' },
    { 'transmision', 'Transmisión (por nivel)' }, { 'suspension', 'Suspensión (por nivel)' },
    { 'blindaje', 'Blindaje (por nivel)' }, { 'turbo', 'Turbo' },
}

local function Texto(valor)
    if type(valor) == 'table' then
        local t = {}
        for i, v in ipairs(valor) do t[i] = ('%s%d'):format(Config.Moneda, v) end
        return table.concat(t, ' · ')
    end
    return ('%s%d'):format(Config.Moneda, tonumber(valor) or 0)
end

local Abrir

local function Editar(clave, nombre, valor)
    local campos = {}
    if type(valor) == 'table' then
        for i, v in ipairs(valor) do
            campos[i] = { type = 'number', label = ('Nivel %d'):format(i), default = v, min = 0, required = true }
        end
    else
        campos[1] = { type = 'number', label = 'Precio base (compacto)', default = valor, min = 0, required = true }
    end

    local r = lib.inputDialog(nombre, campos)
    if not r then return Abrir() end

    local nuevo = type(valor) == 'table' and r or r[1]
    local ok = lib.callback.await('origen_customs:ponerPrecio', false, clave, nuevo)
    lib.notify({ title = 'Taller', description = ok and 'Precio guardado.' or 'No se pudo guardar.', type = ok and 'success' or 'error' })
    Abrir()
end

Abrir = function(precios)
    precios = precios or lib.callback.await('origen_customs:precios', false) or {}
    local opciones = {}
    for _, par in ipairs(NOMBRES) do
        local clave, nombre = par[1], par[2]
        if precios[clave] ~= nil then
            opciones[#opciones + 1] = {
                title = nombre,
                description = Texto(precios[clave]),
                icon = 'dollar-sign',
                onSelect = function() Editar(clave, nombre, precios[clave]) end,
            }
        end
    end
    lib.registerContext({
        id = 'origen_customs_precios',
        title = 'Precios del taller · base de un compacto',
        options = opciones,
    })
    lib.showContext('origen_customs_precios')
end

RegisterNetEvent('origen_customs:editorPrecios', function(precios)
    if AbrirPreciosEnPanel and AbrirPreciosEnPanel() then return end
    Abrir(precios)
end)
