--[[ Poner cambios en el coche y leer de él lo que la pantalla necesita.

     Todo lo de aquí es ENSEÑAR: el coche del taller se tunea en vivo para que
     el cliente lo vea, pero lo que se queda de verdad lo decide el servidor
     al cobrar (ver shared/cambios.lua). ]]

Aplicar = {}

local function Kit(veh)
    if GetVehicleModKit(veh) ~= 0 then SetVehicleModKit(veh, 0) end
end

-- La carta Gen9 se pinta por índice. El tipo 7 (MCT_NONE) evita que un tipo
-- 6 residual tome el control y deje estos índices negros. Los índices 223-242
-- además usan los metadatos y las rampas que carga este recurso.
local CAMALEON_MIN, CAMALEON_MAX = 161, 242

local function EsCamaleon(n)
    return n >= CAMALEON_MIN and n <= CAMALEON_MAX
end

--[[ Si ese vehiculo puede llevar neones.

     Clases 8 (motos), 13 (bicis) y 14 (barcos) no, y 15/16 (helicopteros y
     aviones) tampoco. Lo que si es un coche se comprueba ademas con que exista
     de verdad: durante el taller la entidad puede haberse ido (dueño perdido,
     reinicio) y seguir llegando cambios de la pantalla. ]]
local SIN_NEON = { [8] = true, [13] = true, [14] = true, [15] = true, [16] = true, [21] = true }

local function LlevaNeon(veh)
    if not veh or veh == 0 or not DoesEntityExist(veh) then return false end
    return not SIN_NEON[GetVehicleClass(veh)]
end

local function PonerColorCarta(veh, capa, n)
    local c1, c2 = GetVehicleColours(veh)
    local perla = select(1, GetVehicleExtraColours(veh))
    local camaleon = EsCamaleon(n)

    if capa == 'primaria' then
        ClearVehicleCustomPrimaryColour(veh)
        local tipoActual = GetVehicleModColor_1(veh)
        if camaleon or tipoActual == 6 then
            SetVehicleModColor_1(veh, 7, 0, perla)
        end
        SetVehicleColours(veh, n, c2)
    else
        ClearVehicleCustomSecondaryColour(veh)
        local tipoActual = GetVehicleModColor_2(veh)
        if camaleon or tipoActual == 6 then
            SetVehicleModColor_2(veh, 7, 0)
        end
        SetVehicleColours(veh, c1, n)
    end
end

local function PonerColorRGB(veh, capa, rgb, acabado)
    local perla = select(1, GetVehicleExtraColours(veh))
    local c1, c2 = GetVehicleColours(veh)
    -- La base del mate es el negro mate (12): con otra base el acabado no agarra.
    local base = acabado == 3 and 12 or 0
    if capa == 'primaria' then
        SetVehicleModColor_1(veh, acabado or 0, 0, perla)
        SetVehicleColours(veh, base, c2)
        SetVehicleCustomPrimaryColour(veh, rgb[1], rgb[2], rgb[3])
    else
        SetVehicleModColor_2(veh, acabado or 0, 0)
        SetVehicleColours(veh, c1, base)
        SetVehicleCustomSecondaryColour(veh, rgb[1], rgb[2], rgb[3])
    end
end

--- Pone un cambio (ya normalizado) en el coche.
function Aplicar.Cambio(veh, c)
    if not veh or not DoesEntityExist(veh) or type(c) ~= 'table' then return end
    Kit(veh)
    local k = c.k

    if k == 'mod' then
        if c.i == 48 then
            SetVehicleMod(veh, 48, c.v, false)
        else
            SetVehicleMod(veh, c.i, c.v, false)
        end
    elseif k == 'interruptor' then
        ToggleVehicleMod(veh, c.i, c.v)
    elseif k == 'llanta' then
        local custom = GetVehicleModVariation(veh, 23)
        SetVehicleWheelType(veh, c.tipo)
        SetVehicleMod(veh, 23, c.v, custom)
        if GetVehicleClass(veh) == 8 then SetVehicleMod(veh, 24, c.v, custom) end
    elseif k == 'neumaticos' then
        SetVehicleMod(veh, 23, GetVehicleMod(veh, 23), c.v)
        if GetVehicleClass(veh) == 8 then SetVehicleMod(veh, 24, GetVehicleMod(veh, 24), c.v) end
    elseif k == 'pintura' then
        if type(c.color) == 'table' then
            PonerColorRGB(veh, c.capa, c.color, c.acabado)
        else
            PonerColorCarta(veh, c.capa, c.color)
        end
    elseif k == 'perla' then
        local _, llanta = GetVehicleExtraColours(veh)
        SetVehicleExtraColours(veh, c.v, llanta)
    elseif k == 'llantasColor' then
        local perla = GetVehicleExtraColours(veh)
        SetVehicleExtraColours(veh, perla, c.v)
    elseif k == 'interior' then
        SetVehicleInteriorColor(veh, c.v)
    elseif k == 'salpicadero' then
        SetVehicleDashboardColor(veh, c.v)
    elseif k == 'vinilo' then
        if c.modo == 'livery' then SetVehicleLivery(veh, c.v) else SetVehicleMod(veh, 48, c.v, false) end
    elseif k == 'xenonColor' then
        ToggleVehicleMod(veh, 22, true)
        SetVehicleXenonLightsColor(veh, c.v)
    elseif k == 'neon' then
        --[[ Las motos, las bicis y lo que no es un coche no llevan neon: el
             panel no deberia ofrecerlo y, si llega igual, aqui se para. Los
             neones son lo unico que toca un bone del modelo que puede no
             existir, y encender uno que no esta es la clase de llamada que
             tira el juego al suelo. ]]
        if LlevaNeon(veh) then
            for i = 1, 4 do SetVehicleNeonLightEnabled(veh, i - 1, c.lados[i]) end
        end
    elseif k == 'neonColor' then
        if LlevaNeon(veh) then
            SetVehicleNeonLightsColour(veh, c.c[1], c.c[2], c.c[3])
        end
    elseif k == 'humo' then
        ToggleVehicleMod(veh, 20, true)
        SetVehicleTyreSmokeColor(veh, c.c[1], c.c[2], c.c[3])
    elseif k == 'tintado' then
        SetVehicleWindowTint(veh, c.v)
    elseif k == 'matricula' then
        SetVehicleNumberPlateTextIndex(veh, c.v)
    elseif k == 'extra' then
        -- El tercer parámetro es «quitar»: para ponerlo hay que pasar false.
        SetVehicleExtra(veh, c.i, not c.v)
    end
end

--- Deja el coche exactamente como en `props` (lo de antes de abrir o lo que
--- quedó pagado).
function Aplicar.Restaurar(veh, props)
    if not veh or not DoesEntityExist(veh) or type(props) ~= 'table' then return end
    Kit(veh)

    -- ox_lib aplica paintType solo cuando el color es RGB. Para los índices de
    -- carta, limpia aquí el tipo camaleón nativo y deja que el índice Gen9 pinte.
    if type(props.color1) == 'number' and EsCamaleon(props.color1) then
        local perla = tonumber(props.pearlescentColor) or select(1, GetVehicleExtraColours(veh))
        SetVehicleModColor_1(veh, 7, 0, perla)
    end
    if type(props.color2) == 'number' and EsCamaleon(props.color2) then
        SetVehicleModColor_2(veh, 7, 0)
    end

    --[[ La gasolina no es cosa del taller. `props` sale de la base de datos
         (la de la última vez que se guardó el coche) y el ox_lib de aquí la
         pone con origen_fuel:SetFuel: pagar un tuning dejaba el depósito como
         estaba entonces, muchas veces vacío (19/09). Se deja la que lleva. ]]
    local estado = Entity(veh).state
    if estado.fuel ~= nil then
        local copia = {}
        for k, v in pairs(props) do copia[k] = v end
        copia.fuelLevel = estado.fuel
        copia.fuelTank = estado.fuelTank
        props = copia
    end

    lib.setVehicleProperties(veh, props)
end

-- ── Leer el coche ─────────────────────────────────────────────────────────

local function Texto(etiqueta)
    if not etiqueta or etiqueta == '' or etiqueta == 'NULL' then return nil end
    local t = GetLabelText(etiqueta)
    if not t or t == 'NULL' or t == '' then return nil end
    return t
end

local function NombreOpcion(veh, tipo, j, def)
    local t = Texto(GetModTextLabel(veh, tipo, j))
    return t or ('%s %d'):format(def, j + 1)
end

--- Las opciones de una pieza con el nombre que les da el propio juego.
local function Opciones(veh, tipo, def, nivel)
    local n = GetNumVehicleMods(veh, tipo)
    local lista = {}
    for j = 0, n - 1 do
        lista[#lista + 1] = { v = j, nombre = nivel and ('Nivel %d'):format(j + 1) or NombreOpcion(veh, tipo, j, def) }
    end
    return lista
end

--- Las llantas de una familia. Cambiar de familia es la única forma de que el
--- juego diga cuántas hay, así que se pone, se lee y se deja como estaba.
function Aplicar.LlantasDe(veh, tipo)
    if not DoesEntityExist(veh) then return {} end
    Kit(veh)
    local antesTipo, antesMod, antesCustom = GetVehicleWheelType(veh), GetVehicleMod(veh, 23), GetVehicleModVariation(veh, 23)
    SetVehicleWheelType(veh, tipo)
    local lista = Opciones(veh, 23, 'Llanta', false)
    SetVehicleWheelType(veh, antesTipo)
    SetVehicleMod(veh, 23, antesMod, antesCustom)
    return lista
end

local function Vinilos(veh)
    local n = GetNumVehicleMods(veh, 48)
    if n > 0 then return 'mod', Opciones(veh, 48, 'Vinilo', false) end
    local total = GetVehicleLiveryCount(veh)
    if total and total > 0 then
        local lista = {}
        for j = 0, total - 1 do
            lista[#lista + 1] = { v = j, nombre = Texto(GetLiveryName(veh, j)) or ('Vinilo %d'):format(j + 1) }
        end
        return 'livery', lista
    end
    return nil, {}
end

--[[ Cifras de rendimiento de 0 a 1 para las barras. Salen del propio coche
     (los natives «estimated» ya cuentan las mejoras montadas), escaladas
     con topes razonables de GTA. ]]
function Aplicar.Rendimiento(veh)
    if not DoesEntityExist(veh) then return {} end
    local punta = GetVehicleEstimatedMaxSpeed(veh) * 3.6
    local acel = GetVehicleAcceleration(veh)
    local frenos = GetVehicleMaxBraking(veh)
    local agarre = GetVehicleMaxTraction(veh)
    local function f(x, tope) return math.max(0.0, math.min(1.0, x / tope)) end
    return {
        punta = f(punta, 330.0), acel = f(acel, 0.62), frenos = f(frenos, 1.9), agarre = f(agarre, 3.4),
        kmh = math.floor(punta + 0.5),
    }
end

--- Todo lo que la pantalla necesita saber del coche al abrir.
function Aplicar.Leer(veh, piezasBloqueadas)
    Kit(veh)
    local modelo = GetEntityModel(veh)
    local bloqueadas = {}
    for _, i in ipairs(piezasBloqueadas or {}) do bloqueadas[i] = true end

    local mods = {}
    for i, def in pairs(Catalogo.Mods) do
        if i ~= 48 and not bloqueadas[i] then
            local opciones = Opciones(veh, i, def.nombre, def.nivel)
            if #opciones > 0 then
                mods[#mods + 1] = {
                    i = i, nombre = def.nombre, zona = def.zona, nivel = def.nivel == true,
                    opciones = opciones,
                }
            end
        end
    end
    table.sort(mods, function(a, b) return a.i < b.i end)

    local viniloModo, vinilos = Vinilos(veh)

    local extras = {}
    for i = 1, 15 do
        if DoesExtraExist(veh, i) then extras[#extras + 1] = i end
    end

    local props = lib.getVehicleProperties(veh)
    -- ox_lib lee los extras del 1 al 15 con clave numérica: en la pantalla van
    -- en texto, como vuelven de la base de datos.
    local e = {}
    for i, v in pairs(props.extras or {}) do e[tostring(i)] = v end
    props.extras = e

    local clase = GetVehicleClass(veh)
    local marca = Texto(GetMakeNameFromVehicleModel(modelo))
    local nombre = Texto(GetDisplayNameFromVehicleModel(modelo)) or GetDisplayNameFromVehicleModel(modelo)

    return {
        coche = {
            nombre = nombre, marca = marca, clase = clase, moto = clase == 8,
            matricula = GetVehicleNumberPlateText(veh),
        },
        props = props,
        mods = mods,
        interruptores = {
            turbo = true, humo = true, xenon = true,
        },
        tiposLlanta = Catalogo.TiposLlanta,
        tipoLlanta = GetVehicleWheelType(veh),
        llantas = Opciones(veh, 23, 'Llanta', false),
        vinilos = vinilos, viniloModo = viniloModo,
        extras = extras,
        rendimiento = Aplicar.Rendimiento(veh),
    }
end
