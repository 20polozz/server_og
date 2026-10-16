--[[ ══ Modo rendimiento (/fpson, /fpsoff) ════════════════════════════════════

     Para los PCs flojos: baja lo que mas carga la grafica en SU juego y en
     nada mas. Es todo del cliente; a los demas no les cambia nada.

         /fpson        medio: sombras cortas, algo menos de detalle lejano,
                       menos trafico y peatones
         /fpson max    lo anterior mas fuerte, sin coches lejanos y con
                       menos variedad de modelos en memoria
         /fpsoff       todo como estaba

     Se guarda con KVP (por jugador y por maquina): al reconectar sigue puesto.

     Lo que NO toca, a proposito:
       - la hierba y la vegetacion: quitarla deja ver a quien se esconde;
       - las luces de la ciudad y la linterna: tambien se juega con ellas;
       - el timecycle: origen_gangwars usa el "extra" y las drogas/clima el
         normal; uno propio se pisaria con ellos.

     La densidad de trafico y peatones NO se pone aqui cada fotograma: ya lo
     hace qbx_density, y dos scripts llamando a los ...ThisFrame se pisan segun
     quien llegue ultimo. Se le baja por su export, partiendo de su config, y
     se le devuelve la config al apagar. ]]

local CLAVE = 'origen_hud:rendimiento'

local NIVELES = {
    medio = {
        nombre = 'medio',
        lodscale = 0.8,     -- 1.0 es lo normal
        sombras = 0.5,      -- alcance de las sombras (cascadas)
        densidad = 0.6,     -- sobre lo que diga qbx_density
    },
    max = {
        nombre = 'máximo',
        lodscale = 0.6,
        sombras = 0.0,
        densidad = 0.3,
        cochesLejanos = false,
        reducirModelos = true,
    },
}

local nivel = nil       -- nil = apagado; si no, una de NIVELES

-- ── Densidad, por qbx_density ───────────────────────────────────────────────

local DENSIDAD = 'qbx_density'
local densidadOriginal = nil

local function LeerDensidadOriginal()
    if densidadOriginal then return densidadOriginal end
    local codigo = LoadResourceFile(DENSIDAD, 'config/client.lua')
    if not codigo then return end
    local fn = load(codigo, '@qbx_density/config/client.lua', 't', {})
    local ok, cfg = pcall(fn or error)
    if ok and type(cfg) == 'table' then densidadOriginal = cfg end
    return densidadOriginal
end

local function AplicarDensidad(factor)
    if GetResourceState(DENSIDAD) ~= 'started' then return end
    local cfg = LeerDensidadOriginal()
    if not cfg then return end
    for _, tipo in ipairs({ 'parked', 'vehicle', 'randomvehicles', 'peds', 'scenario' }) do
        if type(cfg[tipo]) == 'number' then
            pcall(function() exports[DENSIDAD]:SetDensity(tipo, cfg[tipo] * factor) end)
        end
    end
end

-- Si qbx_density se reinicia vuelve a su config: se le baja otra vez.
AddEventHandler('onClientResourceStart', function(recurso)
    if recurso == DENSIDAD and nivel then
        densidadOriginal = nil
        SetTimeout(500, function() if nivel then AplicarDensidad(nivel.densidad) end end)
    end
end)

-- ── Encender y apagar ───────────────────────────────────────────────────────

--[[ Lo que no es "ThisFrame" se queda puesto hasta que se quite; al apagar hay
     que devolverlo a mano. CascadeShadowsInitSession deja las sombras como
     las pone el juego al empezar. ]]
local function Restaurar()
    CascadeShadowsInitSession()
    SetDistantCarsEnabled(true)
    SetReducePedModelBudget(false)
    SetReduceVehicleModelBudget(false)
    AplicarDensidad(1.0)
end

local function Aplicar(n)
    Restaurar()
    SetDistantCarsEnabled(n.cochesLejanos ~= false)
    SetReducePedModelBudget(n.reducirModelos == true)
    SetReduceVehicleModelBudget(n.reducirModelos == true)
    AplicarDensidad(n.densidad)
end

-- Lo que el juego olvida cada fotograma, o que otro script puede devolver.
CreateThread(function()
    while true do
        local n = nivel
        if n then
            OverrideLodscaleThisFrame(n.lodscale)
            CascadeShadowsSetCascadeBoundsScale(n.sombras)
            CascadeShadowsEnableEntityTracker(true)   -- sombras solo de cerca
            CascadeShadowsSetEntityTrackerScale(n.sombras)
            CascadeShadowsSetDynamicDepthMode(false)
            CascadeShadowsSetAircraftMode(false)
            Wait(0)
        else
            Wait(500)
        end
    end
end)

local function Avisar(texto, tipo)
    if GetResourceState('origen_notify') == 'started' then
        exports.origen_notify:Notify(texto, tipo or 'info')
    else
        print(texto)
    end
end

local function Poner(clave, callado)
    local n = clave and NIVELES[clave]
    if n then
        nivel = n
        Aplicar(n)
        SetResourceKvp(CLAVE, clave)
        if not callado then Avisar(('Modo rendimiento %s activado. /fpsoff para quitarlo.'):format(n.nombre), 'success') end
    else
        local estaba = nivel ~= nil
        nivel = nil
        Restaurar()
        DeleteResourceKvp(CLAVE)
        if not callado then
            Avisar(estaba and 'Modo rendimiento desactivado.' or 'El modo rendimiento ya estaba apagado.', 'info')
        end
    end
end

RegisterCommand('fpson', function(_, args)
    local pedido = (args[1] or ''):lower()
    Poner((pedido == 'max' or pedido == 'maximo' or pedido == 'máximo') and 'max' or 'medio')
end, false)

RegisterCommand('fpsoff', function()
    Poner(nil)
end, false)

TriggerEvent('chat:addSuggestion', '/fpson', 'Modo rendimiento: menos sombras, detalle lejano y tráfico', {
    { name = 'nivel', help = 'vacío = medio · max = máximo' },
})
TriggerEvent('chat:addSuggestion', '/fpsoff', 'Quita el modo rendimiento')

-- Para un interruptor en unos ajustes: 'medio', 'max' o nil.
exports('ModoRendimiento', function() return nivel and (nivel == NIVELES.max and 'max' or 'medio') or nil end)
exports('PonerModoRendimiento', function(clave) Poner(NIVELES[clave] and clave or nil, true) end)

-- Lo que el jugador dejo puesto la ultima vez.
CreateThread(function()
    local guardado = GetResourceKvpString(CLAVE)
    if guardado and NIVELES[guardado] then
        Wait(2000)  -- que qbx_density haya arrancado
        Poner(guardado, true)
    end
end)

-- Al parar el recurso, que no se quede el juego a medias.
AddEventHandler('onResourceStop', function(recurso)
    if recurso == GetCurrentResourceName() and nivel then Restaurar() end
end)
