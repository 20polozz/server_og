-- f_weapon.lua

--#region Variables y Configuración

WeaponAttachment = {}

local weaponObject = nil
local weaponName = nil
local weaponAttachments = {}
local initialRotation = vec3(0.0, 0.0, 0.0)
local cam = nil

local weaponsFov = {
    [-957766203] = 30.0,
    [416676503] = 20.0,
    [1159398588] = 30.0,
    [-1212426201] = 50.0,
    [-1569042529] = 40.0,
}

local weaponsAttachments = {
    suppressor = { 'WAPSupp', 'WAPSupp_2' },
    flashlight = { 'WAPFlshLasr', 'WAPFlshLasr_2' },
    grip = { 'WAPGrip', 'WAPGrip_2' },
    scope = { 'WAPScop', 'WAPScop_2' },
    clip = { 'WAPClip', 'WAPClip_2' },
    finish = 'Gun_GripR',
    barrel = 'WAPBarrel',
}

--#endregion

--#region Utilidades de Attachments

local function getWeaponBoneLocation(entity, boneName, customOffset)
    local boneIndex = GetEntityBoneIndexByName(entity, boneName)
    if boneIndex == -1 then return nil end

    local boneCoords = GetWorldPositionOfEntityBone(entity, boneIndex)
    local _, screenX, screenY = GetScreenCoordFromWorldCoord(boneCoords.x, boneCoords.y, boneCoords.z)

    if customOffset then
        screenX = screenX * 100
        screenY = screenY * 100
        screenY = screenY + (screenY > 45 and 10.0 or -10.0)
        screenX = screenX + (screenX > 50 and 10.0 or -10.0)
    end

    return vec2(screenX, screenY)
end

local function getWeaponAttachment(entity, boneName, customOffset)
    local attachment = weaponsAttachments[boneName]
    if not attachment then return nil end

    if type(attachment) == 'table' then
        return getWeaponBoneLocation(entity, attachment[1], customOffset) or
            getWeaponBoneLocation(entity, attachment[2], customOffset)
    end

    return getWeaponBoneLocation(entity, attachment, customOffset)
end

local function weaponCanTakeComponent(componentName)
    if Config.WeaponAttachments[componentName] and Config.WeaponAttachments[componentName][weaponName] then
        return Config.WeaponAttachments[componentName][weaponName]
    end
    return false
end

local function ensureModelLoaded(model)
    local tries, errorLoadingModel = 0, false
    if not HasModelLoaded(model) then
        RequestModel(model)
        while not HasModelLoaded(model) do
            tries = tries + 1
            if tries > 100 then
                errorLoadingModel = true
                break
            end
            Wait(0)
        end
    end
    return not errorLoadingModel
end

--#endregion

--#region Preview de Armas

local function createWeaponPreview(item)
    weaponName = string.lower(item.name)
    local weaponModel = GetHashKey(item.name)
    RequestWeaponAsset(weaponModel, 31, 0)
    while not HasWeaponAssetLoaded(weaponModel) do Wait(0) end

    local playerCoords = GetEntityCoords(PlayerPedId())
    weaponObject = CreateWeaponObject(weaponModel, 120, playerCoords.x + 5.0, playerCoords.y, playerCoords.z, true, 1.0,
        0)
    SetEntityRotation(weaponObject, initialRotation)
    FreezeEntityPosition(weaponObject, true)

    local camOffset = GetOffsetFromEntityInWorldCoords(weaponObject, 1.0, 1.0, 0.0)
    cam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", camOffset, 0.0, 0.0, 0, 70.00, false, 0)
    PointCamAtEntity(cam, weaponObject, 0, 0, 0, true)
    SetCamFov(cam, weaponsFov[weaponModel] or 35.0)
    SetCamActive(cam, true)
    RenderScriptCams(true, false, 1, true, true)

    WeaponAttachment.updateWeaponPreviewAttachments(item)

    CreateThread(function()
        local spin = 50.0
        while spin > -20.0 do
            spin = spin - 1
            SetEntityRotation(weaponObject, vector3(0.0, 0.0, spin))
            Wait(1)
        end

        InventoryUI.Emit({
            action = 'registerWeaponAttachments',
            data = {
                weapon = item,
                attachments = {
                    suppressor = getWeaponAttachment(weaponObject, 'suppressor', true),
                    flashlight = getWeaponAttachment(weaponObject, 'flashlight', true),
                    scope = getWeaponAttachment(weaponObject, 'scope', true),
                    grip = getWeaponAttachment(weaponObject, 'grip', true),
                    clip = getWeaponAttachment(weaponObject, 'clip', true),
                    barrel = getWeaponAttachment(weaponObject, 'barrel', true),
                    finish = getWeaponAttachment(weaponObject, 'finish', true)
                }
            }
        }, nil, true)
    end)
end

local function destroyWeaponPreview()
    if weaponObject then DeleteEntity(weaponObject) end
    if cam then DestroyCam(cam, true) end
    RenderScriptCams(false, false, 1, true, true)
    weaponObject = nil
    weaponName = nil
    weaponAttachments = {}
    cam = nil
end

local function previewWeapon(state, item)
    if state then
        createWeaponPreview(item)
    else
        destroyWeaponPreview()
    end
    return true
end

--#endregion

--#region Gestión de Attachments en Preview

WeaponAttachment.updateWeaponPreviewAttachments = function(weaponData)
    if not weaponObject or not weaponData then return false end

    local function addComponent(component, comp)
        local weaponComponent = weaponCanTakeComponent(comp)
        if not weaponComponent then return false end
        if HasWeaponGotWeaponComponent(weaponObject, weaponComponent) then return false end

        weaponAttachments[component] = weaponComponent
        local componentModel = GetWeaponComponentTypeModel(weaponComponent)

        if not ensureModelLoaded(componentModel) then
            print("Error loading model:", componentModel)
            return false
        end

        GiveWeaponComponentToWeaponObject(weaponObject, weaponComponent)
        return true
    end

    local attachents = weaponData.metadata.attachments or {}
    for component, attachmentItem in pairs(attachents) do
        if component == 'finish' then
            local tintIndex = Config.WeaponTints[attachmentItem] or 0
            SetWeaponObjectTintIndex(weaponObject, tintIndex)
            goto continue
        end
        
        addComponent(component, attachmentItem)
        :: continue ::
    end
end

WeaponAttachment.updateTint = function(tintIndex, updateCurrent)
    if updateCurrent then
        local ped = PlayerPedId()
        local currentWeapon = GetSelectedPedWeapon(ped)
        SetPedWeaponTintIndex(ped, currentWeapon, tintIndex)
    end
    if not weaponObject then return false end
    SetWeaponObjectTintIndex(weaponObject, tintIndex)
    return true
end
WeaponAttachment.updateWeaponPreviewAttachment = function(component, componentItemName)
    if not weaponObject then return false end

    local function removeComponent(comp)
        RemoveWeaponComponentFromWeaponObject(weaponObject, comp)
        weaponAttachments[component] = nil
        WeaponAttachment.updateCurrentWeaponAttachments()
        return true
    end

    local function addComponent(comp)
        local weaponComponent = weaponCanTakeComponent(comp)
        if not weaponComponent then return false end
        if HasWeaponGotWeaponComponent(weaponObject, weaponComponent) then return false end

        weaponAttachments[component] = weaponComponent
        local componentModel = GetWeaponComponentTypeModel(weaponComponent)

        if not ensureModelLoaded(componentModel) then
            print("Error loading model:", componentModel)
            return false
        end

        GiveWeaponComponentToWeaponObject(weaponObject, weaponComponent)
        WeaponAttachment.updateCurrentWeaponAttachments()
        return true
    end

    if weaponAttachments[component] then
        return removeComponent(weaponAttachments[component])
    else
        return addComponent(componentItemName)
    end
end

WeaponAttachment.updateCurrentWeaponAttachments = function()
    local _, _, weaponData = Internal__GetCurrentWeapon()
    if not weaponData then return false end
    if not weaponData.metadata or not weaponData.metadata.attachments then return false end

    local ped = PlayerPedId()
    local currentWeapon = GetSelectedPedWeapon(ped)
    local weaponName = weaponData.name

    for attachIndex, attachmentItem in pairs(weaponData.metadata.attachments) do

        if attachIndex == 'finish' then
            local tintIndex = Config.WeaponTints[weaponData.metadata.attachments.finish] or 0
            SetPedWeaponTintIndex(ped, currentWeapon, tintIndex)
            goto continue
        end

        local attachmentData = Config.WeaponAttachments[attachmentItem]
        if not attachmentData then goto continue end
        local attachment = attachmentData[weaponName]
        if not attachment then goto continue end

        local componentModel = GetWeaponComponentTypeModel(attachment)

        if not ensureModelLoaded(componentModel) then
            goto continue
        end

        GiveWeaponComponentToPed(ped, currentWeapon, attachment)

        :: continue ::
    end
end

--#endregion

--#region Eventos de UI

InventoryUI.On('moveWeaponAttachment', function(data)
    if not weaponObject then return end
    local rotation = GetEntityRotation(weaponObject)
    SetEntityRotation(weaponObject, vector3(rotation.x, rotation.y + data.y, rotation.z + data.x))
end)

InventoryUI.On('viewAttachments', function(data)
    if not data or not data.item then return end
    return previewWeapon(true, data.item)
end)

InventoryUI.On('closeAttachments', function()
    previewWeapon(false)
end)

InventoryUI.On('addAttachment', function(data)
    local item, component, weaponSlot = data.item, data.component, data.weaponSlot
    local promise = promise.new()

    Bridge.TriggerCallback('origen_inventory:weapons:server:addWeaponAttachment', function(success)
        if success then
            if component ~= 'finish' then
                WeaponAttachment.updateWeaponPreviewAttachment(component, item.name)
            end
            promise:resolve({ success = true })
        else
            promise:resolve({ success = false })
        end
    end, weaponSlot, item.slot, component)

    return Citizen.Await(promise)
end)

InventoryUI.On('removeAttachment', function(data)
    local component, weaponSlot = data.component, data.weaponSlot
    local promise = promise.new()

    Bridge.TriggerCallback('origen_inventory:weapons:server:removeWeaponAttachment', function(success)
        if success then
            if component ~= 'finish' then
                WeaponAttachment.updateWeaponPreviewAttachment(component)
            end
            promise:resolve({ success = true })
        else
            promise:resolve({ success = false })
        end
    end, weaponSlot, component)

    return Citizen.Await(promise)
end)

--[[ ══ La ficha del arma (pantalla «Inspeccionar» del tema arcade) ══════════

     Las barras de Daño, Cadencia, Precisión y Cargador son las del propio GTA:
     GET_WEAPON_HUD_STATS da los valores de 0 a 100 que el juego enseña en
     Ammu-Nation, y GET_WEAPON_COMPONENT_HUD_STATS lo que suma o resta cada
     accesorio. Las dos escriben en un struct de cinco enteros de 8 bytes; el
     buffer mutable es string.blob de CfxLua (lo mismo que usa DataView). Si el
     native no responde, la ficha sale sin barras en vez de reventar.

     Solo lectura: nada de aquí cambia el arma, y lo que se pinta es para el
     propio jugador. Poner y quitar sigue yendo por los callbacks del servidor. ]]

local HUD_ARMA = 0xD92C739EE34C9EBA       -- GET_WEAPON_HUD_STATS
local HUD_COMPONENTE = 0xB3CAF387AE12E9F8 -- GET_WEAPON_COMPONENT_HUD_STATS

local function LeerHud(native, hash)
    if type(string.blob) ~= 'function' then return nil end
    local ok, datos = pcall(function()
        local blob = string.blob(64)
        if not Citizen.InvokeNative(native, hash, blob, Citizen.ReturnResultAnyway()) then return nil end
        local function entero(o) return (string.unpack('<i4', blob, o + 1)) end
        return {
            dano = entero(0), cadencia = entero(8), capacidad = entero(16),
            precision = entero(24), alcance = entero(32),
        }
    end)
    return ok and datos or nil
end

InventoryUI.On('armaFicha', function(data)
    local item = data and data.item
    if type(item) ~= 'table' or type(item.name) ~= 'string' then return nil end

    local nombre = string.lower(item.name)
    local hash = GetHashKey(item.name)
    local puestos = (item.metadata and item.metadata.attachments) or {}

    -- Los accesorios que le valen a ESTE arma, por nombre de item.
    local compatibles = {}
    for itemName, porArma in pairs(Config.WeaponAttachments or {}) do
        if type(porArma) == 'table' and porArma[nombre] then compatibles[#compatibles + 1] = itemName end
    end
    for tinte in pairs(Config.WeaponTints or {}) do compatibles[#compatibles + 1] = tinte end

    -- Lo que suma o resta cada accesorio puesto.
    local extras = {}
    for componente, itemName in pairs(puestos) do
        if componente ~= 'finish' then
            local porArma = Config.WeaponAttachments and Config.WeaponAttachments[itemName]
            local compHash = porArma and porArma[nombre]
            if compHash then extras[componente] = LeerHud(HUD_COMPONENTE, compHash) end
        end
    end

    -- ¿La lleva en la mano? Cambia «Equipar» por «Guardar».
    local equipada = false
    local ok, _, _, actual = pcall(Internal__GetCurrentWeapon)
    if ok and type(actual) == 'table' then equipada = actual.slot == item.slot end

    local ped = PlayerPedId()
    local cargador = GetWeaponClipSize(hash)
    if equipada and GetSelectedPedWeapon(ped) == hash then
        local max = GetMaxAmmoInClip(ped, hash, true)
        if max and max > 0 then cargador = max end
    end

    return {
        hud = LeerHud(HUD_ARMA, hash),
        extras = extras,
        dano = GetWeaponDamage(hash, 0),
        cargadorBase = GetWeaponClipSize(hash),
        cargador = cargador,
        compatibles = compatibles,
        equipada = equipada,
    }
end)

--- Vuelve a poner el arma de frente, como al abrirla.
InventoryUI.On('armaCentrar', function()
    if not weaponObject then return false end
    SetEntityRotation(weaponObject, vector3(0.0, 0.0, -20.0))
    return true
end)

--#endregion

RegisterNetEvent('inventory:client:ApplyWeaponTint', function(response)
    WeaponAttachment.updateTint(response.tintIndex, response.currentWeapon)
end)

--#region Actualización Continua de UI

CreateThread(function()
    while true do
        if weaponObject then
            InventoryUI.Emit({
                action = 'registerWeaponAttachments',
                data = {
                    attachments = {
                        suppressor = getWeaponAttachment(weaponObject, 'suppressor', true),
                        flashlight = getWeaponAttachment(weaponObject, 'flashlight', true),
                        scope = getWeaponAttachment(weaponObject, 'scope', true),
                        grip = getWeaponAttachment(weaponObject, 'grip', true),
                        clip = getWeaponAttachment(weaponObject, 'clip', true),
                        barrel = getWeaponAttachment(weaponObject, 'barrel', true),
                        finish = getWeaponAttachment(weaponObject, 'finish', true)
                    }
                }
            }, nil, true)

            InventoryUI.Emit({
                action = 'attachmentLine',
                data = {
                    suppressor = getWeaponAttachment(weaponObject, 'suppressor', false),
                    flashlight = getWeaponAttachment(weaponObject, 'flashlight', false),
                    scope = getWeaponAttachment(weaponObject, 'scope', false),
                    grip = getWeaponAttachment(weaponObject, 'grip', false),
                    clip = getWeaponAttachment(weaponObject, 'clip', false),
                    barrel = getWeaponAttachment(weaponObject, 'barrel', false),
                    finish = getWeaponAttachment(weaponObject, 'finish', false)
                }
            }, nil, true)
        end
        -- weaponObject solo existe con el editor abierto; sin el, no hay que ir por fotograma
        Wait(weaponObject and 0 or 250)
    end
end)

--#endregion
