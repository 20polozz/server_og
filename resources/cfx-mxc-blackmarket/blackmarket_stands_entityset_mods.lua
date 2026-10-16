--[[ Los puestos de cada mercado negro (mapeado de MXC).

     Hay tres sotanos iguales, cada uno con siete puestos, y cada puesto puede
     vestirse de una de estas siete maneras (entity sets del interior):

         weapons_stand        armas
         explosives_stand     explosivos
         drugsitem_stand      droga
         drugsequiment_stand  material para hacer droga   (sic: asi lo escribe el mapa)
         medicals_stand       botiquines
         carparts_stand       piezas de coche
         fakeid_stand         documentacion falsa

     De fabrica venian los tres con un puesto de cada. En ORIGEN cada sotano es
     un mercado distinto de origen_blackmarket y solo tiene UN puesto, el del
     que queda enfrente al entrar (el cuarto), que es donde esta el vendedor; los otros seis se quedan
     vacios (02/10, el usuario: «quitar los otros puestos y dejar solo el de
     frente»):

         1 · Puerto Sur            ARMAS    weapons_stand
         2 · Tongva Valley         DROGA    drugsitem_stand
         3 · Avenida San Andreas   CREWS    carparts_stand

     `puestos` son los siete en orden, del 1 al 7; `false` es un hueco vacio.
     Para volver a llenar uno basta con poner ahi el nombre de su decorado. Lo
     que vende de verdad cada mercado se elige en el panel de origen_blackmarket
     («Que se vende»). ]]

local TODOS = {
    'weapons_stand', 'medicals_stand', 'drugsequiment_stand', 'explosives_stand',
    'drugsitem_stand', 'carparts_stand', 'fakeid_stand',
}

local MERCADOS = {
    {   -- 1 · Puerto Sur · ARMAS
        centro = vec3(254.47, -2950.83, -8.21),
        puestos = { false, false, false, 'weapons_stand', false, false, false },
        coords = {
            vec3(260.875671, -2961.36, -8.209399),
            vec3(253.6904, -2961.68726, -8.2092),
            vec3(247.769363, -2957.62769, -8.208956),
            vec3(246.2245, -2950.8684, -5.3954),
            vec3(248.0728, -2944.6794, -5.3954),
            vec3(253.7636, -2940.4983, -5.3954),
            vec3(260.4677, -2940.6318, -5.3954),
        },
    },
    {   -- 2 · Tongva Valley · DROGA
        centro = vec3(-1481.63, 2055.76, 47.67),
        puestos = { false, false, false, 'drugsitem_stand', false, false, false },
        coords = {
            vec3(-1478.07068, 2067.51025, 47.6718941),
            vec3(-1473.02576, 2062.41846, 47.6718941),
            vec3(-1472.04871, 2055.32349, 47.67136),
            vec3(-1475.56958, 2049.04077, 47.67136),
            vec3(-1482.15564, 2046.1792, 47.67136),
            vec3(-1489.1217, 2047.83679, 47.67136),
            vec3(-1493.698, 2053.362, 47.67136),
        },
    },
    {   -- 3 · Avenida San Andreas · CREWS
        centro = vec3(1220.66, -304.88, 32.0),
        puestos = { false, false, false, 'carparts_stand', false, false, false },
        coords = {
            vec3(1226.20325, -295.013641, 32.01045),
            vec3(1231.02979, -300.328278, 32.0106468),
            vec3(1231.67957, -307.462158, 32.01089),
            vec3(1227.891, -313.572052, 32.0109),
            vec3(1221.19653, -316.166656, 32.0107231),
            vec3(1214.27185, -314.168549, 32.01078),
            vec3(1209.97131, -308.455963, 32.0107422),
        },
    },
}

--- Viste los siete puestos de un mercado. Devuelve cuantos ha podido vestir.
local function Vestir(mercado)
    local hechos = 0

    for i, coords in ipairs(mercado.coords) do
        local interior = GetInteriorAtCoordsWithType(coords.x, coords.y, coords.z, 'mxc_blackmarket_stands_col')

        if IsValidInterior(interior) then
            local quiero = mercado.puestos[i]

            for _, set in ipairs(TODOS) do
                if set == quiero then
                    ActivateInteriorEntitySet(interior, set)
                else
                    DeactivateInteriorEntitySet(interior, set)
                end
            end

            RefreshInterior(interior)
            hechos = hechos + 1
        end
    end

    return hechos
end

--[[ Se visten al arrancar y otra vez al acercarse.

     El guion original lo hacia una sola vez, nada mas cargar. Con el jugador en
     la otra punta del mapa el interior puede no estar disponible todavia, y
     entonces el puesto se quedaba como venia de fabrica. Al entrar en el radio
     se repite hasta que los siete estan puestos; una vez hechos no se toca
     mas mientras siga cerca. ]]
local CERCA = 150.0
local vestido = {}

CreateThread(function()
    for i, mercado in ipairs(MERCADOS) do
        vestido[i] = Vestir(mercado) == #mercado.coords and 'lejos' or nil
    end

    while true do
        Wait(2000)
        local yo = GetEntityCoords(PlayerPedId())

        for i, mercado in ipairs(MERCADOS) do
            if #(yo - mercado.centro) < CERCA then
                if vestido[i] ~= 'cerca' and Vestir(mercado) == #mercado.coords then
                    vestido[i] = 'cerca'
                end
            elseif vestido[i] == 'cerca' then
                vestido[i] = 'lejos'
            end
        end
    end
end)
