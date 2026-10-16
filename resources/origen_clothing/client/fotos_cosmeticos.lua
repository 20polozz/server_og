--[[ Las fotos de los cosméticos, en el juego del admin (ver server/fotos_cosmeticos.lua).

     Llega la lista de prendas sin foto, por modelo, y se le pasa a la máquina de
     fotos de siempre (origen_clothing_screenshot: fotografiarLista). Una sesión
     por modelo: pone un maniquí de ese modelo en la pantalla verde, lo viste
     prenda a prenda y hace las fotos. El personaje del admin no posa ni cambia
     (decisión del dueño); su pantalla enseña el estudio mientras dura, porque la
     foto es una captura de su juego. Con E se para. ]]

local FOTOS = 'origen_clothing_screenshot'
local MODELOS = { 'mp_m_freemode_01', 'mp_f_freemode_01' }
local ocupado = false

local function Avisar(texto, tipo)
    if Custom and Custom.Notify then
        Custom.Notify(texto, tipo or 'info')
    else
        lib.notify({ description = texto, type = tipo or 'inform' })
    end
end

RegisterNetEvent('origen_clothing:client:fotosCosmeticosAviso', function(texto)
    Avisar(tostring(texto))
end)

--- 'coleccion--hueco--prenda--textura' (el hueco de un accesorio va con 1000 de más)
local function DeHash(hash)
    local coleccion, hueco, prenda, textura = tostring(hash):match('^(.-)%-%-(%d+)%-%-(%d+)%-%-(%d+)$')
    hueco, prenda, textura = tonumber(hueco), tonumber(prenda), tonumber(textura)
    if not hueco or not prenda or not textura then return nil end
    local esProp = hueco >= 1000
    return { collection = coleccion, component = esProp and hueco - 1000 or hueco, drawable = prenda, texture = textura, isProp = esProp }
end

local function NombreDe(modelo)
    local n = tonumber(modelo)
    if not n then return nil end
    for _, nombre in ipairs(MODELOS) do
        if (joaat(nombre) & 0xFFFFFFFF) == (n & 0xFFFFFFFF) then return nombre end
    end
    return nil
end

RegisterNetEvent('origen_clothing:client:fotosCosmeticos', function(porModelo, cuantas)
    if ocupado or type(porModelo) ~= 'table' then return end
    if GetResourceState(FOTOS) ~= 'started' then
        return Avisar('El recurso de fotos no está arrancado: las fotos de los cosméticos quedan pendientes.', 'error')
    end
    if cache.vehicle or IsEntityDead(cache.ped) then
        return Avisar('Ahora no se pueden hacer las fotos de los cosméticos. Usa /fotoscosmeticos a pie.', 'error')
    end

    ocupado = true
    Avisar(('Haciendo %d fotos de cosméticos. Pulsa E para parar.'):format(tonumber(cuantas) or 0))
    Wait(1200)

    local parado = false
    local corriendo = false
    local fin = AddEventHandler('origen_clothing_screenshot:progressEnd', function(datos)
        corriendo = false
        if type(datos) == 'table' and datos.cancelled then parado = true end
    end)
    local inicio = AddEventHandler('origen_clothing_screenshot:progressStart', function()
        corriendo = true
    end)

    for modelo, hashes in pairs(porModelo) do
        if parado then break end
        local nombre = NombreDe(modelo)
        local items = {}
        for _, hash in ipairs(type(hashes) == 'table' and hashes or {}) do
            local it = DeHash(hash)
            if it then items[#items + 1] = it end
        end
        if nombre and #items > 0 then
            exports[FOTOS]:fotografiarLista({ ped = nombre, items = items, maniqui = true })
            -- por si el export volviera antes de acabar la sesión
            local desde = GetGameTimer()
            while corriendo and GetGameTimer() - desde < 3600000 do Wait(200) end
            Wait(1500)
        end
    end

    RemoveEventHandler(fin)
    RemoveEventHandler(inicio)
    ocupado = false
    Avisar(parado and 'Fotos de cosméticos paradas. Las que falten se hacen con /fotoscosmeticos.' or 'Fotos de cosméticos hechas.', parado and 'error' or 'success')
end)
