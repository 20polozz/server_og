--[[ origen_notify, sin que un reinicio suyo rompa los puntos. Los onEnter,
     onExit y nearby de lib.points corren en el hilo de ox_lib sin pcall: un
     export que falla mientras notify esta reiniciando mataba ese hilo y los
     NPC de Gang Wars dejaban de responder hasta reiniciar este recurso. ]]
function NotifySeguro(fn, ...)
    if GetResourceState('origen_notify') ~= 'started' then return end
    local args = { ... }
    pcall(function() exports['origen_notify'][fn](exports['origen_notify'], table.unpack(args)) end)
end

-- Sistema de NPC para abrir el menú de Gang Wars
local npcPed = nil
local npcBlip = nil
local npcCreated = false
local isNearNPC = false
local npcPoint = nil
local npcSpawnPoint = nil

-- Crear blip en el mapa
--- El punto del menu, en el mapa. Ya no es un blip del juego: se registra en
--- origen_map y de ahi lo leen los tres mapas del servidor. El interruptor y
--- el rotulo del panel siguen mandando, y el sprite y el color tambien,
--- traducidos del numero de GTA por OrigenMapa.Icono y OrigenMapa.Color.
local function CreateBlip()
    if not Config.MenuLocation.blip.enable then return end
    if npcBlip then return end

    local coords = Config.MenuLocation.coords
    npcBlip = 'menu'

    OrigenMapa.Poner(npcBlip, {
        x = coords.x, y = coords.y, z = coords.z,
        cat = 'illegal',
        --- El sprite del config, traducido. Si no lo conoce, manda la categoria.
        icono = OrigenMapa.Icono(Config.MenuLocation.blip.sprite),
        nombre = Config.MenuLocation.blip.label,
        --- El color del config, traducido del numero de GTA. Si no esta en la
        --- tabla de OrigenMapa.Color, manda el de la categoria.
        color = OrigenMapa.Color(Config.MenuLocation.blip.color),
    })

    debugger('Punto de Gang Wars puesto en el mapa')
end

-- Crear NPC
local function CreateNPC()
    if npcCreated then return end
    
    local coords = Config.MenuLocation.coords
    local modelHash = GetHashKey(Config.MenuLocation.npc.model)
    
    --[[ El NPC, solo con alguien cerca: aparece a 80 m y se borra al irte.
         Antes estaba desde que entrabas, ocupando sitio en el pool de peds de
         GTA (256 para todo el servidor). El punto de interaccion no cambia. ]]
    local function crearPed()
        lib.requestModel(modelHash, 10000)
        npcPed = CreatePed(4, modelHash, coords.x, coords.y, coords.z - 1.0, coords.w, false, true)
        SetEntityAsMissionEntity(npcPed, true, true)
        SetPedFleeAttributes(npcPed, 0, false)
        SetPedDiesWhenInjured(npcPed, false)
        SetPedKeepTask(npcPed, true)
        SetBlockingOfNonTemporaryEvents(npcPed, true)
        SetEntityInvincible(npcPed, true)
        FreezeEntityPosition(npcPed, true)
        if Config.MenuLocation.npc.scenario then
            TaskStartScenarioInPlace(npcPed, Config.MenuLocation.npc.scenario, 0, true)
        end
    end

    npcSpawnPoint = lib.points.new({ coords = vec3(coords.x, coords.y, coords.z), distance = 80.0 })
    function npcSpawnPoint:onEnter()
        if not (npcPed and DoesEntityExist(npcPed)) then crearPed() end
    end
    function npcSpawnPoint:onExit()
        if npcPed and DoesEntityExist(npcPed) then DeleteEntity(npcPed) end
        npcPed = nil
    end

    -- Crear punto de interacción
    npcPoint = lib.points.new({
        coords = vec3(coords.x, coords.y, coords.z),
        distance = Config.MenuLocation.target.distance or 2.5,
    })

    function npcPoint:onEnter()
        -- Mostrar DrawText de origen_notify
        NotifySeguro('DrawText', 'E', 'Guerras de bandas')
        isNearNPC = true
    end

    function npcPoint:onExit()
        -- Ocultar DrawText
        NotifySeguro('HideText')
        isNearNPC = false
    end

    function npcPoint:nearby()
        -- Verificar si presiona E
        if isNearNPC and IsControlJustReleased(0, 38) then -- E key
            Nui.ToggleMenu(true)
        end
    end
    
    npcCreated = true
    debugger('NPC de Gang Wars creado en ' .. coords.x .. ', ' .. coords.y .. ', ' .. coords.z)
end

-- Eliminar NPC
local function DeleteNPC()
    if npcPed then
        if DoesEntityExist(npcPed) then
            DeleteEntity(npcPed)
        end
        npcPed = nil
        npcCreated = false
    end
    
    if npcPoint then
        npcPoint:remove()
        npcPoint = nil
    end

    if npcSpawnPoint then
        npcSpawnPoint:remove()
        npcSpawnPoint = nil
    end
    npcCreated = false
    
    if isNearNPC then
        NotifySeguro('HideText')
        isNearNPC = false
    end
    
    if npcBlip then
        OrigenMapa.Quitar(npcBlip)
        npcBlip = nil
    end
end

-- Inicializar cuando el jugador carga
CreateThread(function()
    -- Esperar a que el jugador esté completamente cargado
    while not NetworkIsPlayerActive(PlayerId()) do
        Wait(100)
    end
    
    Wait(1000) -- Esperar un segundo adicional
    
    CreateBlip()
    CreateNPC()
end)

-- Limpiar al descargar el recurso
AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        DeleteNPC()
    end
end)
