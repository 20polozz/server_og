Citizen.CreateThread(function()
    local PlayerData = FW_GetPlayerData()
    if PlayerData then
        LoadPlayer(PlayerData)
    end
end)

local haveRadio = false
local translationsRecived = false

function IsRadioItem(name)
    for _, v in pairs(Config.RadioItems) do
        if v == name then
            return true
        end
    end
    return false
end

--[[ Lleva alguna radio encima segun origen_inventory, o nil si no se puede
     saber. PlayerData.items no sirve con este inventario: no siempre trae lo
     que hay de verdad, y por eso el aviso de "has soltado la radio" no llegaba.
     La que manda es la comprobacion del servidor (server/sin_radio.lua); esto
     solo adelanta que la pantalla se entere. ]]
local function RadioEnElInventario()
    if Config.Inventory ~= "origen_inventory" or GetResourceState("origen_inventory") ~= "started" then
        return nil
    end
    for _, item in pairs(Config.RadioItems) do
        local ok, cuantos = pcall(function()
            return exports.origen_inventory:Search('count', item)
        end)
        if not ok or type(cuantos) ~= "number" then return nil end
        if cuantos > 0 then return true end
    end
    return false
end

Citizen.CreateThread(function()
    while true do
        local enInventario = RadioEnElInventario()
        -- PlayerData solo hace falta cuando el inventario no contesta
        local PlayerData
        if enInventario == nil then
            PlayerData = FW_GetPlayerData(true)
        end
        if enInventario ~= nil or PlayerData.items then
            local detectedRadio = enInventario or false
            if enInventario == nil then
                for k, v in pairs(PlayerData.items) do
                    if IsRadioItem(v.name) then
                        detectedRadio = true
                    end
                end
            end
            if detectedRadio and not haveRadio then
                haveRadio = true
                TriggerEvent("origen_radio:client:TakeDropRadio", true)
            end
            if not detectedRadio and haveRadio then
                haveRadio = false
                TriggerEvent("origen_radio:client:TakeDropRadio", false)
            end
        end
        Citizen.Wait(4000)
    end
end)

RegisterNUICallback("translationsRecived", function(data, cb)
    translationsRecived = true
    cb(true)
end)

--[[ Abrir la radio.

     `delRiel` es para cuando se llega desde el boton de Radio del inventario,
     y salta las dos guardas de arriba, que ahi se cumplen las dos:

       · el foco todavia lo tiene el panel que se esta yendo, asi que
         IsNuiFocused() dice que si y la radio se plantaba;
       · `haveRadio` lo lleva un bucle propio que mira PlayerData.items cada
         cuatro segundos, y con origen_inventory ese campo no siempre trae el
         inventario de verdad. El riel ya ha comprobado que llevas la radio
         encima ---y la ha comprobado contra el inventario bueno--- asi que
         volver a mirarlo aqui solo puede fallar.

     Por lo demas es la misma funcion de siempre: el que abre por la tecla no
     pasa `delRiel` y sigue con sus dos guardas. ]]
function OpenRadio(delRiel)
    if not delRiel then
        if not haveRadio and Config.NeedRadioItem then return end
        if IsNuiFocused() then return end
    end

    if not CanOpenRadio() then return end
    RequestAnimDict("cellphone@")
    while not HasAnimDictLoaded("cellphone@") do
        Citizen.Wait(0)
    end
    local ped = PlayerPedId()
    local PlayerData = FW_GetPlayerData(true)
    TaskPlayAnim(ped, "cellphone@", "cellphone_text_read_base", 2.0, 3.0, -1, 49, 0, 0, 0, 0)
    radioHandProp = CreateObject(`prop_cs_hand_radio`, 1.0, 1.0, 1.0, 1, 1, 0)
    AttachEntityToEntity(radioHandProp, ped, GetPedBoneIndex(ped, 57005), 0.14, 0.01, -0.02, 110.0, 120.0, -15.0, 1, 0, 0, 0, 2, 1)
    SendNUIMessage({
        action = "OpenQuickAccess",
        translations = not translationsRecived and Lang.nui or nil,
        citizenid = PlayerData.citizenid,
        jobData = {
            duty = PlayerData.job.onduty,
            name = PlayerData.job.name,
            level = PlayerData.job.grade.level,
        },
        bindSystem = Config.BindSystem,
        --[[ Llegando desde otro panel del riel, la barra del canto YA esta en
             pantalla: la pinta el que se esta yendo, identica y en el mismo
             sitio. Con esto la de aqui aparece ya puesta encima en vez de
             deslizarse, que durante el cruce enseñaria dos barras moviendose
             una sobre otra. ]]
        relevo = delRiel == true,
    })
    wasOpened = true
    --[[ Que la radio esta delante AHORA. `wasOpened` no vale para esto: se
         pone a true la primera vez y no se apaga nunca, asi que dice "se abrio
         alguna vez", no "esta abierta". Lo consulta origen_inventory por el
         export EstaAbierto para comprobar --tras pasarle el relevo-- que este
         panel llego a abrirse de verdad. ]]
    RadioAbierta = true
    SetNuiFocus(true, true)

    --[[ ── Y SE COMPRUEBA QUE LA PANTALLA LLEGO A PINTARSE ──────────────────

         Mandar el mensaje no prueba nada. Si la interfaz revienta al montarse
         --un dato que llega mal, una lista que no era lista-- Vue desmonta el
         trozo roto sin decir nada: queda la pantalla en blanco con el foco de
         la NUI cogido, el raton en medio y nada que pulsar. Y desde aqui todo
         parece correcto, porque `RadioAbierta` sigue en true.

         Asi que la interfaz contesta cuando se ha pintado de verdad --mirando
         que su columna este en el DOM, no solo que le hayan llamado-- y si en
         un segundo y medio no ha contestado, se suelta el foco. ]]
    RadioPintada = false

    SetTimeout(1500, function()
        if not RadioAbierta or RadioPintada then return end

        print('^1[origen_radio]^0 La radio no llego a pintarse. Se cierra y se suelta el foco para no dejar el raton preso.')
        RadioAbierta = false
        SendNUIMessage({ action = 'CerrarRadio' })
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
    end)
    Citizen.CreateThread(function()
        if Config.KeepInputOnNUI then
            SetNuiFocusKeepInput(true)
        end
        while IsNuiFocused() do
            Citizen.Wait(0)
            DisableAllControlActions(0)
            EnableControlAction(0, 249, true)
            EnableControlAction(1, 249, true)
            EnableControlAction(2, 249, true)
            EnableControlAction(0, 22, true)
            EnableControlAction(0, 30, true)
            EnableControlAction(0, 31, true)
            EnableControlAction(0, 32, true)
            EnableControlAction(0, 33, true)
            EnableControlAction(0, 34, true)
            EnableControlAction(0, 35, true)
            EnableControlAction(0, 59, true)
            EnableControlAction(0, 71, true)
            EnableControlAction(0, 72, true)
            EnableControlAction(0, 76, true)
            EnableControlAction(0, 21, true)
        end
        if Config.KeepInputOnNUI then
            SetNuiFocusKeepInput(false)
        end
        while IsControlPressed(0, 200) or IsDisabledControlPressed(0, 200) do
            Citizen.Wait(0)
            DisableControlAction(0, 200, true)
        end
        DisableControlAction(0, 200, true)
    end)
end

--[[ Los eventos NO pueden apuntar a OpenRadio a pelo: el primer argumento que
     mande quien dispare el evento acabaria de `delRiel`. El servidor manda
     `true` en `TriggerClientEvent("key-5", src, true)`, por ejemplo. ]]
RegisterNetEvent("key-5", function() OpenRadio() end)
RegisterNetEvent("origen_radio:client:OpenRadio", function() OpenRadio() end)

exports("OpenRadio", function() OpenRadio() end)

--[[ La puerta del riel del inventario. Suelta el foco que todavia tiene el
     panel que se va y abre sin guardas; es la misma puerta aparte que tiene el
     menu rapido de policia. ]]
exports("AbrirDelRiel", function()
    SetNuiFocus(false, false)

    SetTimeout(0, function()
        OpenRadio(true)
    end)
end)