--[[ ── Mascotas · la tienda ──────────────────────────────────────────────────

     Los puntos de compra: un dependiente, un blip y una zona para hablar con el.
     Las coordenadas y el modelo del ped los pone un admin desde el panel, asi
     que esto no sabe donde estan hasta que el servidor se lo dice.

     Al reconstruir se borra todo y se vuelve a montar. Es de bruto, pero un
     admin mueve una tienda tres veces en la vida del servidor y asi no hay que
     llevar la cuenta de que ped era de que fila. ]]

local peds = {}
local blips = {}
local zonas = {}

CatalogoRazas = {}
ListaTiendas = {}
ArticulosTienda = {}

local function Limpiar()
    for _, hueco in ipairs(peds) do
        --[[ Cada hueco es {ped = ...}, y lo normal es que `ped` sea nil: el
             dependiente no existe hasta que alguien se acerca a 80 m.

             Esto estaba escrito como `type(hueco) == 'table' and hueco.ped or
             hueco`, y con el ped a nil el `and` daba nil, saltaba el `or` y le
             pasaba LA TABLA a DoesEntityExist. Ese es el
             "native 7239b21a38f536ba: invalid table argument": el error cortaba
             Limpiar() en seco, asi que MontarTiendas no llegaba a montar nada y
             no aparecia ningun dependiente en ninguna tienda. ]]
        local ped = hueco
        if type(hueco) == 'table' then ped = hueco.ped end

        if type(ped) == 'number' and ped ~= 0 and DoesEntityExist(ped) then
            DeleteEntity(ped)
        end
    end

    for _, clave in ipairs(blips) do
        OrigenMapa.Quitar(clave)
    end

    for _, zona in ipairs(zonas) do
        if zona and zona.remove then zona:remove() end
    end

    peds, blips, zonas = {}, {}, {}
end

local function MontarTienda(tienda)
    local nombreModelo = tienda.ped or 's_m_y_shop_mask'

    --[[ El dependiente, solo con alguien cerca: aparece a 80 m y se borra al
         irte. Antes estaban los de todas las tiendas desde que entrabas,
         ocupando sitio en el pool de peds de GTA (256 para todo el servidor). ]]
    local hueco = { ped = nil }
    peds[#peds + 1] = hueco

    zonas[#zonas + 1] = lib.points.new({
        coords = vec3(tienda.x + 0.0, tienda.y + 0.0, tienda.z + 0.0),
        distance = 80.0,
        onEnter = function()
            if hueco.ped and DoesEntityExist(hueco.ped) then return end

            --[[ Un ped que no existe --mal escrito en el panel, o de un stream
                 que este cliente no tiene-- se queda sin dependiente y lo dice
                 en consola una vez. La tienda sigue funcionando: se compra
                 igual, solo que no hay nadie detras del mostrador. ]]
            local modelo = Mascotas.CargarModelo(nombreModelo)

            if not modelo then
                if not hueco.avisado then
                    hueco.avisado = true
                    print(('[origen_pets] la tienda "%s" tiene un ped que no existe: %s')
                        :format(tienda.nombre or '?', nombreModelo))
                end
                return
            end

            local ped = CreatePed(4, modelo, tienda.x + 0.0, tienda.y + 0.0, tienda.z - 1.0, tienda.h + 0.0, false, true)
            SetModelAsNoLongerNeeded(modelo)

            -- Un dependiente no se mueve, no se asusta y no se le puede pegar:
            -- es mobiliario con cara.
            FreezeEntityPosition(ped, true)
            SetEntityInvincible(ped, true)
            SetBlockingOfNonTemporaryEvents(ped, true)
            SetPedDiesWhenInjured(ped, false)
            hueco.ped = ped
        end,
        onExit = function()
            if hueco.ped and DoesEntityExist(hueco.ped) then DeleteEntity(hueco.ped) end
            hueco.ped = nil
        end,
    })

    --[[ La tienda, en el mapa. Ya no es un blip del juego: se registra el
         punto en origen_map y de ahi lo leen los tres mapas del servidor.

         Antes habia que elegir un sprite del juego —el 442, el de mascotas—
         porque la huella no existe como blip. Aqui la huella la dibujamos
         nosotros, asi que ese apaño se acabo. ]]
    if tienda.blip == true or tienda.blip == 1 then
        local clave = 'tienda_' .. tostring(tienda.id or (#blips + 1))

        OrigenMapa.Poner(clave, {
            x = tienda.x, y = tienda.y, z = tienda.z,
            cat = 'mascotas',
            nombre = tienda.nombre or 'Tienda de mascotas',
        })

        blips[#blips + 1] = clave
    end

    zonas[#zonas + 1] = lib.points.new({
        coords = vec3(tienda.x + 0.0, tienda.y + 0.0, tienda.z + 0.0),
        distance = 2.5,
        onEnter = function()
            lib.showTextUI('[E] ' .. (tienda.nombre or 'Tienda de mascotas'))
        end,
        onExit = function()
            lib.hideTextUI()
        end,
        nearby = function(self)
            if self.currentDistance < 2.0 and IsControlJustReleased(0, 38) then
                AbrirTienda(tienda)
            end
        end,
    })
end

--- Rehace todos los puntos con lo que mande el servidor.
function MontarTiendas(razas, tiendas, articulos)
    CatalogoRazas = razas or CatalogoRazas
    ListaTiendas = tiendas or ListaTiendas
    ArticulosTienda = articulos or ArticulosTienda

    Limpiar()

    for _, tienda in ipairs(ListaTiendas) do
        MontarTienda(tienda)
    end
end

RegisterNetEvent('origen_pets:client:catalogo', function(razas, tiendas, articulos)
    MontarTiendas(razas, tiendas, articulos)
end)

CreateThread(function()
    Wait(3000)

    local datos = lib.callback.await('origen_pets:catalogo', false)
    if datos then MontarTiendas(datos.razas, datos.tiendas, datos.articulos) end
end)

AddEventHandler('onResourceStop', function(recurso)
    if recurso ~= GetCurrentResourceName() then return end
    -- Con la tienda abierta, el raton se quedaria puesto sin nadie detras.
    SetNuiFocus(false, false)
    Limpiar()
    lib.hideTextUI()
end)

--[[ ── Comprar ──────────────────────────────────────────────────────────────

     La tienda es una pantalla NUESTRA, no un diálogo prestado: la misma columna
     del canto derecho que el panel de mascotas, con el catálogo y su precio.

     Aquí solo se elige; el cobro lo hace el servidor, que es quien sabe el
     precio de verdad. ]]
function AbrirTienda(tienda)
    local catalogo = {}

    for clave, raza in pairs(CatalogoRazas) do
        if raza.enVenta then
            catalogo[#catalogo + 1] = {
                clave = clave,
                nombre = raza.nombre,
                precio = raza.precio or 0,
                pelea = raza.pelea,
                salud = raza.salud,
                slots = raza.alijo and raza.alijo.slots or 0,
                peso = math.floor(((raza.alijo and raza.alijo.peso) or 0) / 1000),

                -- Las dos monedas: un cero quiere decir que con esa no se paga.
                precioXp = raza.precioXp or 0,
                vip = raza.vip or false,

                imagen = raza.imagen or '',
                dano = raza.dano or 100,

                -- Que come y que bebe, para la ficha. Vacio quiere decir lo de
                -- siempre, asi que se manda ya resuelto y la pantalla no tiene
                -- que conocer el config.
                comida = (raza.comidaItem ~= '' and raza.comidaItem)
                    or Config.Necesidades.comida.nombre,
                bebida = (raza.bebidaItem ~= '' and raza.bebidaItem)
                    or Config.Necesidades.bebida.nombre,
            }
        end
    end

    -- Los suministros, tal cual llegan: los que estan a la venta.
    local articulos = {}
    for _, a in ipairs(ArticulosTienda or {}) do
        if a.enVenta then articulos[#articulos + 1] = a end
    end

    -- Sin razas Y sin suministros no hay tienda. Con una de las dos cosas si:
    -- se puede entrar solo a por pienso.
    if #catalogo == 0 and #articulos == 0 then
        return TriggerEvent('QBCore:Notify', 'Hoy no hay nada a la venta.', 'error')
    end

    --[[ Las normales primero y las VIP debajo, cada grupo de mas barato a mas
         caro. Ordenar todo junto por precio no vale: son dos monedas distintas
         y un perro de 800 XP acabaria colado entre los de 3.000 dolares. ]]
    table.sort(catalogo, function(a, b)
        if a.vip ~= b.vip then return not a.vip end
        local pa = a.precio > 0 and a.precio or a.precioXp
        local pb = b.precio > 0 and b.precio or b.precioXp
        return pa < pb
    end)

    lib.hideTextUI()
    AbrirPantallaTienda(tienda.nombre or 'Tienda de mascotas', catalogo, articulos)
end
