--[[ El agente de la comisaría (multas, avisar, recuperar ID).

     Salía duplicado —y triplicado— con gente conectada. Los marcadores se
     recargan cada vez que el servidor lo manda A TODOS (cualquiera guarda,
     mueve, crea o borra algo de una comisaría, o activa una estación), y cada
     recarga:
       - volvía a añadir las posiciones a BillsNPCPositions sin vaciarla,
       - creaba NPCs nuevos sin que los hilos viejos se enterasen,
       - dejaba corriendo para siempre el bucle de cada NPC anterior (dos
         «Habla con el agente» y el menú abierto dos veces con un solo E).

     Ahora hay UNA tanda viva: cada creación borra la anterior, sube la
     generación (los hilos viejos se paran solos), junta las posiciones
     repetidas y usa un solo hilo para todas. El NPC es local de cada cliente,
     así que cada jugador ve exactamente uno por sitio. ]]
local NPC_MODELO = GetHashKey("s_m_y_cop_01")
local NPCEntities = {}
local generacion = 0
local avisoVisible = false

local function ocultarAviso()
    if avisoVisible then
        HideHelpNotification()
        avisoVisible = false
    end
end

--- Las posiciones sin repetir: la misma comisaría cargada dos veces, o dos
--- marcadores en el mismo mostrador, no son dos agentes.
local function posicionesUnicas()
    local unicas = {}
    for _, c in pairs(BillsNPCPositions or {}) do
        if c and c.x then
            local repetida = false
            for _, u in ipairs(unicas) do
                if #(vec3(c.x, c.y, c.z) - vec3(u.x, u.y, u.z)) < 1.5 then
                    repetida = true
                    break
                end
            end
            if not repetida then unicas[#unicas + 1] = c end
        end
    end
    return unicas
end

function ClearNPCsBills()
    generacion = generacion + 1
    for _, npc in pairs(NPCEntities) do
        if DoesEntityExist(npc) then
            DeleteEntity(npc)
        end
    end
    NPCEntities = {}
    ocultarAviso()
end

function CreateNPCsBills()
    ClearNPCsBills()
    local mia = generacion
    local posiciones = posicionesUnicas()
    if #posiciones == 0 then return end

    CreateThread(function()
        RequestModel(NPC_MODELO)
        local hasta = GetGameTimer() + 10000
        while not HasModelLoaded(NPC_MODELO) and GetGameTimer() < hasta do
            Wait(10)
        end
        -- Mientras cargaba el modelo pudo llegar otra recarga: esa manda.
        if mia ~= generacion or not HasModelLoaded(NPC_MODELO) then return end

        for _, c in ipairs(posiciones) do
            local npc = CreatePed(4, NPC_MODELO, c.x, c.y, c.z - 1, c.w or 0.0, false, true)
            NPCEntities[#NPCEntities + 1] = npc
            SetEntityHeading(npc, c.w or 0.0)
            FreezeEntityPosition(npc, true)
            SetEntityInvincible(npc, true)
            SetBlockingOfNonTemporaryEvents(npc, true)
            TaskStartScenarioInPlace(npc, "WORLD_HUMAN_CLIPBOARD", 0, true)
        end
        SetModelAsNoLongerNeeded(NPC_MODELO)

        while mia == generacion do
            local wait = 1000
            local pos = GetEntityCoords(PlayerPedId())
            local cerca = false

            for _, c in ipairs(posiciones) do
                if #(pos - vec3(c.x, c.y, c.z)) < 2.5 then
                    cerca = true
                    break
                end
            end

            if cerca then
                wait = 5

                if Config.CustomNotify then
                    ShowHelpNotification("E", "Habla con el agente")
                    avisoVisible = true
                else
                    if Config.Framework == "qbcore" then
                        if not avisoVisible then
                            exports['qb-core']:DrawText("[E] Habla con el agente", 'left')
                            avisoVisible = true
                        end
                    elseif Config.Framework == "esx" then
                        Framework.ShowHelpNotification("~INPUT_PICKUP~ Habla con el agente", true)
                    end
                end

                if IsControlJustPressed(0, 38) then
                    ShowBills()
                end
            else
                ocultarAviso()
            end

            Wait(wait)
        end
    end)
end

-- ===========================================================================
-- NPC DE TRÁMITES Y DUPLICADOS DE DOCUMENTOS (DocumentsNPC)
-- ===========================================================================
local NPC_DOCS_MODELO = GetHashKey("s_m_y_cop_01")
local NPCDocsEntities = {}
local generacionDocs = 0
local avisoDocsVisible = false

local function ocultarAvisoDocs()
    if avisoDocsVisible then
        HideHelpNotification()
        avisoDocsVisible = false
    end
end

local function posicionesDocsUnicas()
    local unicas = {}
    for _, c in pairs(DocumentsNPCPositions or {}) do
        if c and c.x then
            local repetida = false
            for _, u in ipairs(unicas) do
                if #(vec3(c.x, c.y, c.z) - vec3(u.x, u.y, u.z)) < 1.5 then
                    repetida = true
                    break
                end
            end
            if not repetida then unicas[#unicas + 1] = c end
        end
    end
    return unicas
end

function ClearNPCsDocuments()
    generacionDocs = generacionDocs + 1
    for _, npc in pairs(NPCDocsEntities) do
        if DoesEntityExist(npc) then
            DeleteEntity(npc)
        end
    end
    NPCDocsEntities = {}
    ocultarAvisoDocs()
end

function CreateNPCsDocuments()
    ClearNPCsDocuments()
    local mia = generacionDocs
    local posiciones = posicionesDocsUnicas()
    if #posiciones == 0 then return end

    CreateThread(function()
        RequestModel(NPC_DOCS_MODELO)
        local hasta = GetGameTimer() + 10000
        while not HasModelLoaded(NPC_DOCS_MODELO) and GetGameTimer() < hasta do
            Wait(10)
        end
        if mia ~= generacionDocs or not HasModelLoaded(NPC_DOCS_MODELO) then return end

        for _, c in ipairs(posiciones) do
            local npc = CreatePed(4, NPC_DOCS_MODELO, c.x, c.y, c.z - 1, c.w or 0.0, false, true)
            NPCDocsEntities[#NPCDocsEntities + 1] = npc
            SetEntityHeading(npc, c.w or 0.0)
            FreezeEntityPosition(npc, true)
            SetEntityInvincible(npc, true)
            SetBlockingOfNonTemporaryEvents(npc, true)
            TaskStartScenarioInPlace(npc, "WORLD_HUMAN_CLIPBOARD", 0, true)
        end
        SetModelAsNoLongerNeeded(NPC_DOCS_MODELO)

        while mia == generacionDocs do
            local wait = 1000
            local pos = GetEntityCoords(PlayerPedId())
            local cerca = false

            for _, c in ipairs(posiciones) do
                if #(pos - vec3(c.x, c.y, c.z)) < 2.5 then
                    cerca = true
                    break
                end
            end

            if cerca then
                wait = 5
                if Config.CustomNotify then
                    ShowHelpNotification("E", "Trámites y duplicados")
                    avisoDocsVisible = true
                else
                    if Config.Framework == "qbcore" then
                        if not avisoDocsVisible then
                            exports['qb-core']:DrawText("[E] Trámites y duplicados", 'left')
                            avisoDocsVisible = true
                        end
                    elseif Config.Framework == "esx" then
                        Framework.ShowHelpNotification("~INPUT_PICKUP~ Trámites y duplicados", true)
                    end
                end

                if IsControlJustPressed(0, 38) then
                    OpenDocumentsMenu()
                end
            else
                ocultarAvisoDocs()
            end

            Wait(wait)
        end
    end)
end

function OpenDocumentsMenu()
    local menu = {
        {
            header = "Oficina de Trámites y Licencias",
            isMenuHeader = true,
            icon = "fa-solid fa-id-card-clip",
            txt = "Recuperación y duplicados de documentos oficiales"
        },
        {
            header = "Documento de Identidad (ID / DNI)",
            txt = "Solicitar un duplicado de tu ID Card ($50)",
            icon = "fa-solid fa-id-card",
            params = {
                isAction = true,
                event = function()
                    TriggerServerEvent("origen_police:server:RecoverIDCard")
                end
            }
        },
        {
            header = "Carnet de Conducir",
            txt = "Solicitar un duplicado de tu carnet de conducir ($150)",
            icon = "fa-solid fa-id-badge",
            params = {
                isAction = true,
                event = function()
                    TriggerServerEvent("origen_police:server:RecoverDriverLicense")
                end
            }
        },
        {
            header = "Licencia de Caza",
            txt = "Solicitar un duplicado de tu licencia de caza oficial ($200)",
            icon = "fa-solid fa-paw",
            params = {
                isAction = true,
                event = function()
                    TriggerServerEvent("origen_police:server:RecoverHuntingLicense")
                end
            }
        },
        {
            header = "Papeles de Vehículo",
            txt = "Solicitar la documentación oficial de un vehículo propio ($100)",
            icon = "fa-solid fa-car-side",
            params = {
                isAction = true,
                event = function()
                    OpenVehiclePapersMenu()
                end
            }
        }
    }
    OpenMenu(menu)
end

function OpenVehiclePapersMenu()
    FW_TriggerCallback("origen_police:server:GetPlayerOwnedVehicles", function(vehicles)
        if not vehicles or #vehicles == 0 then
            local emptyMenu = {
                {
                    header = "Papeles de Vehículo",
                    isMenuHeader = true,
                    icon = "fa-solid fa-car-side",
                },
                {
                    header = "Sin vehículos registrados",
                    txt = "No tienes ningún vehículo a tu nombre en el registro",
                    icon = "fa-solid fa-triangle-exclamation",
                    disabled = true
                },
                {
                    header = "« Volver",
                    icon = "fa-solid fa-arrow-left",
                    params = {
                        isAction = true,
                        event = function()
                            OpenDocumentsMenu()
                        end
                    }
                }
            }
            OpenMenu(emptyMenu)
            return
        end

        local vehMenu = {
            {
                header = "Papeles de Vehículo ($100)",
                isMenuHeader = true,
                icon = "fa-solid fa-car-side",
                txt = "Selecciona el vehículo para expedir la documentación"
            }
        }

        for i = 1, #vehicles do
            local veh = vehicles[i]
            local label = veh.label or veh.vehicle or "Vehículo"
            local plate = veh.plate or "N/A"
            local stateStr = (veh.state == 1 or veh.state == true) and "En garaje" or "En circulación"
            if veh.garage and veh.garage ~= "" then
                stateStr = stateStr .. " (" .. veh.garage .. ")"
            end

            table.insert(vehMenu, {
                header = label .. " [" .. plate .. "]",
                txt = "Matrícula: " .. plate .. " • " .. stateStr,
                icon = "fa-solid fa-car",
                params = {
                    isAction = true,
                    event = function()
                        TriggerServerEvent("origen_police:server:RecoverVehiclePapers", plate)
                    end
                }
            })
        end

        table.insert(vehMenu, {
            header = "« Volver",
            icon = "fa-solid fa-arrow-left",
            params = {
                isAction = true,
                event = function()
                    OpenDocumentsMenu()
                end
            }
        })

        OpenMenu(vehMenu)
    end)
end

exports("OpenDocumentsMenu", OpenDocumentsMenu)
RegisterNetEvent("origen_police:client:OpenDocumentsMenu", function()
    OpenDocumentsMenu()
end)

function ShowBills()
    local mainMenu = {
        {
            header = "Comisaría",
            isMenuHeader = true,
            icon = "fa-solid fa-building-shield",
            txt = "Selecciona una opción"
        },
        {
            header = "Avisar a Policía",
            txt = "Notificar que hay alguien esperando en el hall",
            icon = "fa-solid fa-bell",
            params = {
                isAction = true,
                event = function()
                    TriggerServerEvent("SendAlert:police", {
                        coords = GetEntityCoords(PlayerPedId()),
                        title = 'Ciudadano en Comisaría',
                        type = 'GENERALES',
                        message = "Un ciudadano está esperando en el hall de la comisaría",
                        job = 'police',
                        ignoreCooldown = true
                    })
                    exports["origen_notify"]:Notify({
                        title = "Comisaría",
                        description = "Se ha notificado a la policía",
                        type = "success",
                        duration = 5000
                    })
                end
            }
        },
        {
            header = "Ver Multas",
            txt = "Consultar y pagar tus multas pendientes",
            icon = "fa-solid fa-file-invoice-dollar",
            params = {
                isAction = true,
                event = function()
                    ShowBillsMenu()
                end
            }
        },
        {
            header = "Recuperar Documentos y Licencias",
            txt = "Duplicados de DNI, carnet de conducir, caza o papeles de vehículo",
            icon = "fa-solid fa-id-card-clip",
            params = {
                isAction = true,
                event = function()
                    OpenDocumentsMenu()
                end
            }
        }
    }
    OpenMenu(mainMenu)
end

function ShowBillsMenu()
    FW_TriggerCallback("origen_police:server:GetBills", function(bills)
        local menu = {
            {
                header = "Multas",
                isMenuHeader = true,
                icon = "fa-solid fa-file-invoice-dollar",
            }
        }

        for i = 1, #bills do
            local txt = ""
            local title = (bills[i].title and bills[i].title) or 'Bill'

            local concepts = {}
            local ok, decoded = pcall(json.decode, bills[i].concepts)
            if ok and type(decoded) == 'table' then
                concepts = decoded
            end

            for j = 1, #concepts do
                if j <= 4 then
                    txt = txt .. concepts[j] .. "<br>"
                elseif j == 5 then
                    txt = txt .. "y " .. (#concepts - 4) .. " artículos más...<br>"
                end
            end

            if #concepts == 0 then
                txt = "Conceptos no especificados"
            end

            table.insert(menu, {
                header = title .. ': $' .. bills[i].price .. "",
                txt = txt,
                params = {
                    event = "origen_police:server:PayBill",
                    isServer = true,
                    args = {
                        id = bills[i].id,
                        price = bills[i].price,
                        job = bills[i].job
                    }
                }
            })
        end

        if #bills == 0 then
            table.insert(menu, {
                header = "No tienes multas pendientes",
                txt = "¡Sigue así!",
                icon = "fa-solid fa-check",
                disabled = true
            })
        end

        OpenMenu(menu)
    end)
end

exports("ShowBills", ShowBills)
RegisterNetEvent("origen_police:client:ShowBills", function()
    ShowBills()
end)

exports("GetBills", function()
    local result = -1
    FW_TriggerCallback("origen_police:server:GetBills", function(bills)
        result = bills
    end)
    while result == -1 do
        Wait(0)
    end
    return result
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    ClearNPCsBills()
    ClearNPCsDocuments()
end)

if Config.IgnoreSettings then LoadMarkers() end