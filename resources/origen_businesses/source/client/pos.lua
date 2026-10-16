BusinessPOS = {}

RegisterNUICallback('pos:models', function(_, cb)
    local models = {}
    for _, model in ipairs(Config.POS.Models or {}) do
        models[#models + 1] = { model = model, label = (Config.POS.ModelLabels or {})[model] or model }
    end
    cb(models)
end)

local objetos, puntos, cerca, datosPuntos = {}, {}, {}, {}
local dui, texturaLista, camara, sesion
local texturasAplicadas = {}
local modelosPorHash = {}
local cajaAutomatica, negocioAutomatico, cajaActiva
for _, modelo in ipairs(Config.POS.Models) do modelosPorHash[joaat(modelo)] = modelo end
local borradores = {}
local ancho, alto = 1920, 1080
local cursorX, cursorY = ancho / 2, alto / 2

local function coordenadas(c)
    if type(c) ~= 'table' and type(c) ~= 'vector3' and type(c) ~= 'vector4' then return nil end
    local x, y, z = tonumber(c.x or c[1]), tonumber(c.y or c[2]), tonumber(c.z or c[3])
    if not x or not y or x ~= x or y ~= y or (z and z ~= z) then return nil end
    return x, y, z
end

local function dentroDelPoligono(pos, puntos, grosor)
    if type(puntos) ~= 'table' or #puntos < 3 then return false end

    local vertices, sumaZ, conZ = {}, 0.0, 0
    for i = 1, #puntos do
        local x, y, z = coordenadas(puntos[i])
        if not x then return false end
        vertices[#vertices + 1] = { x, y }
        if z then sumaZ, conZ = sumaZ + z, conZ + 1 end
    end

    if conZ > 0 then
        local media = sumaZ / conZ
        local mitad = (tonumber(grosor) or 4.0) / 2.0 + 1.0
        if math.abs(pos.z - media) > mitad then return false end
    end

    local dentro, j = false, #vertices
    for i = 1, #vertices do
        local xi, yi = vertices[i][1], vertices[i][2]
        local xj, yj = vertices[j][1], vertices[j][2]
        if ((yi > pos.y) ~= (yj > pos.y)) and (pos.x < (xj - xi) * (pos.y - yi) / (yj - yi) + xi) then
            dentro = not dentro
        end
        j = i
    end
    return dentro
end

function BusinessPOS.ObtenerZonaNegocio(business)
    local zonas = business and business.polyzone
    if type(zonas) ~= 'table' then return nil end
    if type(zonas.points) == 'table' then return zonas end

    local preferida = tostring(business.id or '') .. '_dj'
    if type(zonas[preferida]) == 'table' and type(zonas[preferida].points) == 'table' then
        return zonas[preferida]
    end

    local claves = {}
    for clave, zona in pairs(zonas) do
        if type(zona) == 'table' and type(zona.points) == 'table' and #zona.points >= 3 then
            claves[#claves + 1] = { orden = tostring(clave), clave = clave }
        end
    end
    table.sort(claves, function(a, b) return a.orden < b.orden end)
    local primera = claves[1]
    return primera and zonas[primera.clave] or nil
end

function BusinessPOS.DentroPolyzone(business, pos)
    if not business or business.productSystem ~= 'recipes' then return false end
    local zona = BusinessPOS.ObtenerZonaNegocio(business)
    pos = pos or GetEntityCoords(PlayerPedId())
    if zona and dentroDelPoligono(pos, zona.points or zona.zone_points, zona.thickness) then
        return true
    end

    -- No todos los negocios tienen polyzone (muchos solo tienen el punto de
    -- gestión). Mantén la interacción disponible junto a sus puntos de trabajo.
    local px, py, pz = coordenadas(pos)
    if not px or not py or not pz then return false end
    local origen = vector3(px, py, pz)
    for _, punto in pairs((business and business.points) or {}) do
        local x, y, z = coordenadas(type(punto) == 'table' and punto.coords)
        if x and y and z and #(origen - vector3(x, y, z)) <= 30.0 then
            return true
        end
    end
    return false
end

local function zonaTPVActiva()
    local duty = LocalPlayer.state.isOnDuty
    if duty and duty ~= false then
        return BusinessPOS.DentroPolyzone(Business.Get(tostring(duty)))
    end

    -- Los clientes también ven la pantalla del TPV asignado, pero solo dentro
    -- de la zona del negocio que tiene ese punto configurado.
    for clave in pairs(cerca) do
        local datos = datosPuntos[clave]
        if datos and BusinessPOS.DentroPolyzone(datos.business) then return true end
    end
    return false
end

local function avisar(mensaje, tipo)
    Custom.Notify({ title = 'TPV', description = mensaje, type = tipo or 'inform' })
end

local function render(mensaje)
    if not sesion or not dui or not IsDuiAvailable(dui) then return end
    local total = 0
    for _, item in ipairs(sesion.cart) do total = total + item.price * item.quantity end
    SendDuiMessage(dui, json.encode({ action = 'menu', data = {
        mode = sesion.mode,
        businessLabel = sesion.data.businessLabel,
        menu = sesion.data.menu,
        customers = sesion.data.customers,
        cart = sesion.cart,
        total = total,
        customerModal = sesion.customerModal,
        manualCustomerId = sesion.manualCustomerId,
        selectedIndex = sesion.selectedIndex,
        selectedCustomerIndex = sesion.selectedCustomerIndex,
        orderId = sesion.orderId,
        message = mensaje or sesion.message,
    } }))
end

local function cerrar()
    cajaActiva = nil
    if not sesion then return end
    local id = tostring(sesion.business.id)
    local resumenPendiente
    if sesion.mode == 'menu' and #sesion.cart > 0 then
        borradores[id] = sesion.cart
        local total = 0
        for _, item in ipairs(sesion.cart) do total = total + item.price * item.quantity end
        resumenPendiente = {
            mode = 'draft',
            businessLabel = sesion.data.businessLabel,
            menu = sesion.data.menu,
            customers = {},
            cart = sesion.cart,
            total = total,
            message = 'PEDIDO PENDIENTE · Pulsa E para continuar',
        }
    else
        borradores[id] = nil
    end
    sesion = nil
    if dui and IsDuiAvailable(dui) then
        SendDuiMouseUp(dui, 'left')
        SendDuiMouseUp(dui, 'right')
        SendDuiMessage(dui, json.encode({ action = 'cursorMode', active = false }))
        SendDuiMessage(dui, json.encode({ action = 'menu', data = resumenPendiente or { mode = 'idle' } }))
    end
    if camara then
        RenderScriptCams(false, true, 350, true, true)
        DestroyCam(camara, false)
        camara = nil
    end
end

local function enfocar(objeto)
    local minimo, maximo = GetModelDimensions(GetEntityModel(objeto))
    local pos = GetEntityCoords(objeto)
    local direccion = GetEntityForwardVector(objeto)
    local ped = GetEntityCoords(PlayerPedId())
    local lado = (ped.x - pos.x) * direccion.x + (ped.y - pos.y) * direccion.y >= 0 and 1.0 or -1.0
    local y = minimo.y + (maximo.y - minimo.y) * (lado > 0 and 0.72 or 0.28)
    local z = minimo.z + (maximo.z - minimo.z) * 0.94
    local objetivo = GetOffsetFromEntityInWorldCoords(objeto, 0.0, y, z) + vector3(0.0, 0.0, 0.08)
    local posicion = objetivo + direccion * lado * 0.46 + vector3(0.0, 0.0, 0.21)
    camara = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    if not camara or camara == 0 then camara = nil return false end
    SetCamCoord(camara, posicion.x, posicion.y, posicion.z)
    PointCamAtCoord(camara, objetivo.x, objetivo.y, objetivo.z)
    SetCamFov(camara, 34.0)
    SetCamActive(camara, true)
    RenderScriptCams(true, true, 450, true, true)
    cursorX, cursorY = ancho / 2, alto / 2
    SendDuiMouseMove(dui, cursorX, cursorY)
    SendDuiMessage(dui, json.encode({ action = 'cursorMode', active = true }))
    return true
end

local function aplicarTextura(modelo)
    if not texturaLista or not dui or not IsDuiAvailable(dui) or texturasAplicadas[modelo]
        or not zonaTPVActiva() then return end
    local permitida = false
    for _, diccionario in ipairs(Config.POS.TextureDictionaries) do
        if diccionario == modelo then permitida = true break end
    end
    if not permitida then return end
    local ok, err = pcall(AddReplaceTexture, modelo, Config.POS.TextureName, 'origen_businesses_pos', 'screen')
    if ok then texturasAplicadas[modelo] = true
    else print(('[origen_businesses] No se pudo aplicar la pantalla al modelo %s: %s'):format(modelo, tostring(err))) end
end

local function quitarTexturas()
    for modelo in pairs(texturasAplicadas) do
        RemoveReplaceTexture(modelo, Config.POS.TextureName)
        texturasAplicadas[modelo] = nil
    end
end

local function cajaExistente(coords)
    local buscada = vector3(coords.x, coords.y, coords.z)
    local mejor, distancia = nil, 2.5
    for _, objeto in ipairs(GetGamePool('CObject')) do
        if DoesEntityExist(objeto) and modelosPorHash[GetEntityModel(objeto)] then
            local actual = #(GetEntityCoords(objeto) - buscada)
            if actual < distancia then mejor, distancia = objeto, actual end
        end
    end
    return mejor
end

local function quitar(clave)
    local objeto = objetos[clave]
    objetos[clave] = nil
    if objeto and DoesEntityExist(objeto) then
        if sesion and sesion.objeto == objeto then cerrar() end
        DeleteEntity(objeto)
    end
end

local function poner(clave, coords, modelo)
    quitar(clave)
    if not modelo then return end
    local ok, hash = pcall(lib.requestModel, modelo, 10000)
    if not ok or not hash or not cerca[clave] then return end
    local objeto = CreateObject(hash, coords.x, coords.y, coords.z, false, false, false)
    SetEntityHeading(objeto, coords.w or 0.0)
    FreezeEntityPosition(objeto, true)
    SetEntityInvincible(objeto, true)
    SetModelAsNoLongerNeeded(hash)
    if not cerca[clave] then DeleteEntity(objeto) return end
    objetos[clave] = objeto
    aplicarTextura(modelo)
end

function BusinessPOS.Registrar(business, indice, punto, coords)
    if not business or business.productSystem ~= 'recipes' then return end
    local clave = tostring(business.id) .. ':' .. tostring(indice)
    local modelo = type(punto.prop) == 'table' and punto.prop.model or nil
    if not modelosPorHash[joaat(modelo or '')] then modelo = nil end
    datosPuntos[clave] = { coords = coords, modelo = modelo, business = business }
    local point = lib.points.new({ coords = vector3(coords.x, coords.y, coords.z), distance = Config.POS.SpawnDistance })
    puntos[clave] = point
    function point:onEnter()
        cerca[clave] = true
        if modelo then CreateThread(function() poner(clave, coords, modelo) end) end
    end
    function point:onExit()
        cerca[clave] = nil
        quitar(clave)
    end
end

function BusinessPOS.QuitarDe(businessId)
    local prefijo = tostring(businessId) .. ':'
    for clave, point in pairs(puntos) do
        if clave:sub(1, #prefijo) == prefijo then
            point:remove()
            puntos[clave] = nil
            cerca[clave] = nil
            datosPuntos[clave] = nil
            quitar(clave)
        end
    end
end

function BusinessPOS.Abrir(business, indice, objetoExterno)
    if sesion then return end
    if not BusinessPOS.DentroPolyzone(business) then
        avisar('Debes estar dentro de la zona del negocio para usar el TPV.', 'error')
        return
    end
    local clave = tostring(business.id) .. ':' .. tostring(indice)
    local datos = datosPuntos[clave]
    local objeto = objetoExterno or objetos[clave]
    if datos and not datos.modelo then objeto = cajaExistente(datos.coords) end
    if not objeto or not DoesEntityExist(objeto) or not dui or not IsDuiAvailable(dui) then
        avisar('No se encontró una caja compatible junto al punto de TPV.', 'error')
        return
    end
    cajaActiva = objeto
    aplicarTextura(modelosPorHash[GetEntityModel(objeto)])
    local resultado = lib.callback.await('origen_businesses:cb:posBootstrap', false, business.id)
    if not resultado or not resultado.success then
        cajaActiva = nil
        avisar(resultado and resultado.message or 'No se pudo abrir la caja.', 'error')
        return
    end
    local menuPorId, cart = {}, {}
    for _, item in ipairs(resultado.menu) do menuPorId[tonumber(item.recipeId)] = item end
    for _, item in ipairs(borradores[tostring(business.id)] or {}) do
        local vigente = menuPorId[tonumber(item.recipeId)]
        if vigente and #cart < Config.POS.MaxOrderItems then
            cart[#cart + 1] = { recipeId = vigente.recipeId, label = vigente.label,
                price = vigente.price, quantity = math.min(math.max(1, tonumber(item.quantity) or 1), Config.POS.MaxItemQuantity) }
        end
    end
    sesion = { business = business, objeto = objeto, data = resultado, cart = cart,
        mode = 'menu', customerModal = false, manualCustomerId = '', selectedIndex = 1, selectedCustomerIndex = 1 }
    if not enfocar(objeto) then cerrar() avisar('No se pudo enfocar la caja.', 'error') return end
    render('Selecciona los productos de la carta.')
    avisar('Usa el ratón para el TPV. Pulsa ESC para salir.')
end

local function actualizarCartaYClientes()
    local actual = sesion
    local respuesta = lib.callback.await('origen_businesses:cb:posBootstrap', false, actual.business.id)
    if sesion ~= actual then return false end
    if not respuesta or not respuesta.success then
        sesion.message = respuesta and respuesta.message or 'No se pudo actualizar el TPV.'
        return false
    end
    sesion.data = respuesta
    local vigentes = {}
    for _, item in ipairs(respuesta.menu) do vigentes[tonumber(item.recipeId)] = item end
    local cart = {}
    for _, item in ipairs(sesion.cart) do
        local vigente = vigentes[tonumber(item.recipeId)]
        if vigente then cart[#cart + 1] = { recipeId = vigente.recipeId, label = vigente.label,
            price = vigente.price, quantity = item.quantity } end
    end
    sesion.cart = cart
    return true
end

RegisterNUICallback('posAction', function(data, cb)
    if not sesion or type(data) ~= 'table' then cb({ ok = false }) return end
    local action, index = data.action, math.floor(tonumber(data.index) or 0)
    if action == 'close' then cerrar() cb({ ok = true }) return end
    if sesion.mode == 'receipt' then cb({ ok = true }) return end

    if action == 'addProduct' and not sesion.customerModal then
        local producto = sesion.data.menu[index]
        if producto then
            local linea
            for _, item in ipairs(sesion.cart) do if item.recipeId == producto.recipeId then linea = item break end end
            if linea then linea.quantity = math.min(Config.POS.MaxItemQuantity, linea.quantity + 1)
            elseif #sesion.cart < Config.POS.MaxOrderItems then
                sesion.cart[#sesion.cart + 1] = { recipeId = producto.recipeId, label = producto.label,
                    price = producto.price, quantity = 1 }
            else sesion.message = 'El pedido admite 20 productos distintos.' end
        end
    elseif action == 'increaseProduct' and not sesion.customerModal then
        local item = sesion.cart[index]
        if item then item.quantity = math.min(Config.POS.MaxItemQuantity, item.quantity + 1) end
    elseif action == 'decreaseProduct' and not sesion.customerModal then
        local item = sesion.cart[index]
        if item then if item.quantity <= 1 then table.remove(sesion.cart, index) else item.quantity = item.quantity - 1 end end
    elseif action == 'removeProduct' and not sesion.customerModal then
        if sesion.cart[index] then table.remove(sesion.cart, index) end
    elseif action == 'clearCart' and not sesion.customerModal then
        sesion.cart = {}
    elseif action == 'showCustomers' and #sesion.cart > 0 then
        if actualizarCartaYClientes() then
            sesion.customerModal = true
            sesion.selectedCustomerIndex = 1
        end
    elseif action == 'refreshCustomers' and sesion.customerModal then
        actualizarCartaYClientes()
    elseif action == 'closeCustomerModal' or action == 'backToMenu' then
        sesion.customerModal = false
        sesion.manualCustomerId = ''
    elseif action == 'customerDigit' and sesion.customerModal then
        local digito = tostring(data.value or '')
        if digito:match('^%d$') and #sesion.manualCustomerId < 5 then
            sesion.manualCustomerId = sesion.manualCustomerId .. digito
        end
    elseif action == 'backspaceCustomerId' and sesion.customerModal then
        sesion.manualCustomerId = sesion.manualCustomerId:sub(1, -2)
    elseif action == 'clearCustomerId' and sesion.customerModal then
        sesion.manualCustomerId = ''
    elseif (action == 'assignCustomer' or action == 'manualCustomer') and sesion.customerModal then
        local cliente = action == 'assignCustomer' and sesion.data.customers[index]
        local objetivo = action == 'manualCustomer' and tonumber(sesion.manualCustomerId) or (cliente and cliente.serverId)
        if objetivo and #sesion.cart > 0 then
            local actual = sesion
            local lineas = {}
            for _, item in ipairs(sesion.cart) do lineas[#lineas + 1] = { recipeId = item.recipeId, quantity = item.quantity } end
            local respuesta = lib.callback.await('origen_businesses:cb:createInvoice', false, {
                businessId = sesion.business.id, accountId = objetivo, recipeItems = lineas, pos = true,
            })
            if sesion ~= actual then cb({ ok = true }) return end
            if respuesta and respuesta.success then
                sesion.mode = 'receipt'
                sesion.orderId = respuesta.invoice and respuesta.invoice.invoice_number
                sesion.cart = {}
                sesion.customerModal = false
                sesion.message = ('Factura enviada al cliente por $%s.'):format(respuesta.invoice.amount)
            else
                sesion.message = respuesta and respuesta.message or 'No se pudo enviar la factura.'
                avisar(sesion.message, 'error')
            end
        end
    elseif action == 'previousPage' or action == 'nextPage' then
        local lista = sesion.customerModal and sesion.data.customers or sesion.data.menu
        local clave = sesion.customerModal and 'selectedCustomerIndex' or 'selectedIndex'
        local actual = sesion[clave]
        if action == 'nextPage' then sesion[clave] = math.min(#lista, math.floor((actual - 1) / 4) * 4 + 5)
        else sesion[clave] = math.max(1, math.floor((actual - 1) / 4) * 4 - 3) end
    end
    render()
    cb({ ok = true })
end)

CreateThread(function()
    local url = ('https://cfx-nui-%s/ui/build/pos-screen.html?resource=%s'):format(GetCurrentResourceName(), GetCurrentResourceName())
    dui = CreateDui(url, ancho, alto)
    if not dui then print('[origen_businesses] No se pudo crear el DUI del TPV.') return end
    local limite = GetGameTimer() + 10000
    while not IsDuiAvailable(dui) and GetGameTimer() < limite do Wait(50) end
    if not IsDuiAvailable(dui) then print('[origen_businesses] No cargó la página del TPV: ' .. url) return end
    local txd = CreateRuntimeTxd('origen_businesses_pos')
    texturaLista = CreateRuntimeTextureFromDuiHandle(txd, 'screen', GetDuiHandle(dui)) ~= nil
    if not texturaLista then print('[origen_businesses] No se pudo crear la textura del TPV.') end
end)

CreateThread(function()
    while true do
        if texturaLista and zonaTPVActiva() then
            -- Algunos modelos se cargan después del DUI. Se aplica el reemplazo
            -- mientras el jugador está dentro de la polyzone de un negocio.
            for _, objeto in ipairs(GetGamePool('CObject')) do
                local modelo = modelosPorHash[GetEntityModel(objeto)]
                if modelo and not texturasAplicadas[modelo] then aplicarTextura(modelo) end
            end
            Wait(700)
        else
            -- AddReplaceTexture afecta a todas las instancias de ese modelo:
            -- retirar el reemplazo en cuanto se sale de las zonas de negocio.
            if next(texturasAplicadas) then quitarTexturas() end
            Wait(500)
        end
    end
end)

local function negocioDeCaja()
    local duty = LocalPlayer.state.isOnDuty
    if not duty or duty == false then return nil end
    local business = Business.Get(tostring(duty))
    if not BusinessPOS.DentroPolyzone(business) then return nil end
    return business
end

CreateThread(function()
    while true do
        local nuevaCaja, nuevoNegocio
        local business = not sesion and negocioDeCaja() or nil
        if business and BusinessPOS.DentroPolyzone(business) then
            local ped = PlayerPedId()
            local pos = GetEntityCoords(ped)
            local distancia = Config.POS.AutoInteractionDistance
            for _, objeto in ipairs(GetGamePool('CObject')) do
                if modelosPorHash[GetEntityModel(objeto)] then
                    local actual = #(GetEntityCoords(objeto) - pos)
                    if actual < distancia then
                        local tienePuntoTPV = false
                        for _, punto in pairs(business.points or {}) do
                            if punto.type == 'pos' and punto.coords then
                                local c = punto.coords
                                if #(pos - vector3(tonumber(c.x) or 0, tonumber(c.y) or 0, tonumber(c.z) or 0)) <= Config.POS.InteractionDistance then
                                    tienePuntoTPV = true
                                    break
                                end
                            end
                        end
                        if not tienePuntoTPV then
                            nuevaCaja, nuevoNegocio, distancia = objeto, business, actual
                        end
                    end
                end
            end
        end
        cajaAutomatica, negocioAutomatico = nuevaCaja, nuevoNegocio
        Wait(500)
    end
end)

CreateThread(function()
    local mostraba = false
    while true do
        if cajaAutomatica and negocioAutomatico and not sesion and DoesEntityExist(cajaAutomatica)
            and BusinessPOS.DentroPolyzone(negocioAutomatico)
            and #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(cajaAutomatica)) <= Config.POS.AutoInteractionDistance then
            Custom.DrawText('Usar TPV', 'E')
            mostraba = true
            if IsControlJustReleased(0, 38) then
                local business, objeto = negocioAutomatico, cajaAutomatica
                cajaAutomatica, negocioAutomatico = nil, nil
                Custom.HideText()
                mostraba = false
                BusinessPOS.Abrir(business, nil, objeto)
            end
            Wait(0)
        else
            if mostraba then Custom.HideText() mostraba = false end
            Wait(100)
        end
    end
end)

CreateThread(function()
    while true do
        if sesion and dui and IsDuiAvailable(dui) then
            if not BusinessPOS.DentroPolyzone(sesion.business) then
                cerrar()
                Wait(150)
            else
                DisableAllControlActions(0)
                EnableControlAction(0, 249, true)
                local x, y = GetDisabledControlNormal(0, 1), GetDisabledControlNormal(0, 2)
                if x ~= 0 or y ~= 0 then
                    cursorX = math.max(0, math.min(ancho - 1, cursorX + x * Config.POS.CursorSensitivity))
                    cursorY = math.max(0, math.min(alto - 1, cursorY + y * Config.POS.CursorSensitivity))
                    SendDuiMouseMove(dui, math.floor(cursorX), math.floor(cursorY))
                    SendDuiMessage(dui, json.encode({ action = 'cursor', x = cursorX, y = cursorY }))
                end
                if IsDisabledControlJustPressed(0, 24) then SendDuiMouseDown(dui, 'left') end
                if IsDisabledControlJustReleased(0, 24) then SendDuiMouseUp(dui, 'left') end
                if IsDisabledControlJustPressed(0, 202) or IsDisabledControlJustPressed(0, 322) then
                    if sesion.customerModal then sesion.customerModal = false render() else cerrar() end
                end
                if sesion and (not DoesEntityExist(sesion.objeto)
                    or not BusinessPOS.DentroPolyzone(sesion.business)
                    or #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(sesion.objeto)) > Config.POS.InteractionDistance + 1.0) then
                    cerrar()
                end
                Wait(0)
            end
        else Wait(150) end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    cerrar()
    for clave in pairs(objetos) do quitar(clave) end
    for _, point in pairs(puntos) do point:remove() end
    quitarTexturas()
    if dui then DestroyDui(dui) end
end)
