local function SetupImage_Callback(slot)
    local dialog = exports['org-input']:ShowInput({
        header = 'Enlace de la imagen',
        submitText = 'Confirmar',
        icon = 'fa-solid fa-image',
        inputs = {
            {
                type = "text",
                name = "url",
                text = "Enlace (http o https, .png, .jpg, .gif o .webp)",
                isRequired = true
            },
            {
                type = "number",
                name = "amount",
                text = "Número de copias (1-10)",
                isRequired = true
            }
        }
    })

    if dialog and dialog.url and dialog.amount then
        TriggerServerEvent('origen_prints:server:SaveImage', slot, dialog.url, tonumber(dialog.amount))
    end
end

RegisterNetEvent('origen_prints:client:SetupImage', function(slot)
    SetupImage_Callback(slot)
end)

local animDict = "missfam4"
local animName = "base"
local propModel = "p_amb_clipboard_01"
local currentProp = nil

local function StartPrintAnim()
    local ped = PlayerPedId()
    
    -- Cargar diccionario de animación
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do Wait(0) end
    
    -- Cargar modelo del prop
    RequestModel(propModel)
    while not HasModelLoaded(propModel) do Wait(0) end

    -- Reproducir animación
    TaskPlayAnim(ped, animDict, animName, 8.0, -8.0, -1, 49, 0, false, false, false)

    -- Crear y fixear prop según configuración de origen_anims
    local coords = GetEntityCoords(ped)
    currentProp = CreateObject(GetHashKey(propModel), coords.x, coords.y, coords.z, true, true, true)
    
    -- Bone: 36029 (SKEL_L_Hand)
    -- Offset: 0.16, 0.08, 0.10
    -- Rotation: -130.0, -50.0, 0.0
    AttachEntityToEntity(currentProp, ped, GetPedBoneIndex(ped, 36029), 0.16, 0.08, 0.10, -130.0, -50.0, 0.0, true, true, false, true, 1, true)
end

local function StopPrintAnim()
    local ped = PlayerPedId()
    StopAnimTask(ped, animDict, animName, 1.0)
    if currentProp and DoesEntityExist(currentProp) then
        DeleteEntity(currentProp)
        currentProp = nil
    end
end

RegisterNetEvent('origen_prints:client:ShowImage', function(url)
    StartPrintAnim()
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "showImage",
        url = url
    })
end)

RegisterNUICallback("closeImage", function(_, cb)
    StopPrintAnim()
    SetNuiFocus(false, false)
    cb("ok")
end)

-- Si el vigilante de @origen_map/shared/foco.lua suelta el raton a la fuerza,
-- se cierra la lamina y se quita la animacion.
if OrigenFoco and OrigenFoco.AlSoltar then
    OrigenFoco.AlSoltar(function()
        StopPrintAnim()
        SendNUIMessage({ action = "hideImage" })
    end)
end
