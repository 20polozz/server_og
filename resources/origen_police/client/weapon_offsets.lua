-- ============================================================
-- ORIGEN POLICE — WEAPON POSITIONS 3D LIVE PREVIEW & GIZMO EDITOR
-- ============================================================

local isEditing = false
local previewEntity = nil
local editorCam = nil
local camDist = 1.35
local camAngleZ = 0.0
local camAngleX = 0.0
local camHeight = 0.05
local camFov = 45.0
local currentPed = nil
local currentPose = "apose"

local currentCategory = "waisthandgun"
local currentBone = 11816
local currentModel = "w_pi_combatpistol"
local currentCoords = { x = -0.04, y = -0.015, z = 0.20, xRot = -90.0, yRot = 17.0, zRot = -13.0 }

local gizmoActive = false
local gizmoMode = "Translate" -- 'Translate' | 'Rotate'
local gizmoCursorActive = false

-- ─────────────────────────────────────────────
-- Helpers de matriz para Gizmo nativo
-- ─────────────────────────────────────────────
local function normalize(x, y, z)
    local len = math.sqrt(x * x + y * y + z * z)
    if len == 0 then return 0, 0, 0 end
    return x / len, y / len, z / len
end

local function makeEntityMatrix(entity)
    local f, r, u, a = GetEntityMatrix(entity)
    local view = DataView.ArrayBuffer(64)
    view:SetFloat32(0,  r[1]):SetFloat32(4,  r[2]):SetFloat32(8,  r[3]):SetFloat32(12, 0)
    view:SetFloat32(16, f[1]):SetFloat32(20, f[2]):SetFloat32(24, f[3]):SetFloat32(28, 0)
    view:SetFloat32(32, u[1]):SetFloat32(36, u[2]):SetFloat32(40, u[3]):SetFloat32(44, 0)
    view:SetFloat32(48, a[1]):SetFloat32(52, a[2]):SetFloat32(56, a[3]):SetFloat32(60, 1)
    return view
end

local function applyEntityMatrix(entity, view)
    local x1, y1, z1 = view:GetFloat32(16), view:GetFloat32(20), view:GetFloat32(24)
    local x2, y2, z2 = view:GetFloat32(0),  view:GetFloat32(4),  view:GetFloat32(8)
    local x3, y3, z3 = view:GetFloat32(32), view:GetFloat32(36), view:GetFloat32(40)
    local tx, ty, tz = view:GetFloat32(48), view:GetFloat32(52), view:GetFloat32(56)
    x1, y1, z1 = normalize(x1, y1, z1)
    x2, y2, z2 = normalize(x2, y2, z2)
    x3, y3, z3 = normalize(x3, y3, z3)
    SetEntityMatrix(entity, x1, y1, z1, x2, y2, z2, x3, y3, z3, tx, ty, tz)
end

local function EnsureModelHash(model)
    if type(model) == "number" then return model end
    return GetHashKey(model)
end

local function LoadModel(model)
    local hash = EnsureModelHash(model)
    if not IsModelInCdimage(hash) or not IsModelValid(hash) then
        hash = GetHashKey("w_pi_combatpistol")
    end
    if not HasModelLoaded(hash) then
        RequestModel(hash)
        local timeout = GetGameTimer() + 2000
        while not HasModelLoaded(hash) and GetGameTimer() < timeout do
            Wait(10)
        end
    end
    return hash
end

local function LoadAnimDictAsync(dict)
    if not HasAnimDictLoaded(dict) then
        RequestAnimDict(dict)
        local timeout = GetGameTimer() + 800
        while not HasAnimDictLoaded(dict) and GetGameTimer() < timeout do
            Wait(10)
        end
    end
    return HasAnimDictLoaded(dict)
end

local function UpdateCamPosition()
    if not editorCam or not DoesCamExist(editorCam) or not currentPed or not DoesEntityExist(currentPed) then return end

    local pedCoords = GetEntityCoords(currentPed)
    local pedHeading = GetEntityHeading(currentPed)

    -- Vector frontal en GTA V con heading H: (-sin(H), cos(H))
    local radZ = math.rad(pedHeading + camAngleZ)
    local radX = math.rad(camAngleX)

    local cx = pedCoords.x - camDist * math.sin(radZ) * math.cos(radX)
    local cy = pedCoords.y + camDist * math.cos(radZ) * math.cos(radX)
    local cz = pedCoords.z + camHeight + camDist * math.sin(radX)

    SetCamCoord(editorCam, cx, cy, cz)
    SetCamFov(editorCam, camFov)

    local targetZ = pedCoords.z + camHeight
    PointCamAtCoord(editorCam, pedCoords.x, pedCoords.y, targetZ)
end

local function ApplyPreviewAttachment()
    currentPed = PlayerPedId()
    if not currentPed or not DoesEntityExist(currentPed) then return end

    if not previewEntity or not DoesEntityExist(previewEntity) then
        return
    end

    local boneId = tonumber(currentBone) or 11816
    local boneIndex = GetPedBoneIndex(currentPed, boneId)
    if boneIndex == -1 then
        boneIndex = 0
    end

    local x = (tonumber(currentCoords.x) or 0.0) + 0.0
    local y = (tonumber(currentCoords.y) or 0.0) + 0.0
    local z = (tonumber(currentCoords.z) or 0.0) + 0.0
    local xRot = (tonumber(currentCoords.xRot) or 0.0) + 0.0
    local yRot = (tonumber(currentCoords.yRot) or 0.0) + 0.0
    local zRot = (tonumber(currentCoords.zRot) or 0.0) + 0.0

    SetEntityCollision(previewEntity, false, false)
    AttachEntityToEntity(
        previewEntity,
        currentPed,
        boneIndex,
        x, y, z,
        xRot, yRot, zRot,
        false, false, false, false, 2, true
    )
    SetEntityCollision(previewEntity, false, false)
    SetEntityVisible(previewEntity, true, false)
    SetEntityAlpha(previewEntity, 255, false)
end

local function SpawnPreviewProp(modelName)
    if previewEntity and DoesEntityExist(previewEntity) then
        DetachEntity(previewEntity, true, true)
        DeleteEntity(previewEntity)
        previewEntity = nil
    end

    if not modelName or modelName == "" then
        modelName = "w_pi_combatpistol"
    end

    local hash = LoadModel(modelName)
    currentPed = PlayerPedId()
    local pedCoords = GetEntityCoords(currentPed)
    
    -- Crear entidad local
    previewEntity = CreateObject(hash, pedCoords.x, pedCoords.y, pedCoords.z, false, false, false)
    if not DoesEntityExist(previewEntity) then
        previewEntity = CreateObject(hash, pedCoords.x, pedCoords.y, pedCoords.z, true, true, false)
    end

    if DoesEntityExist(previewEntity) then
        SetEntityCollision(previewEntity, false, false)
        SetEntityInvincible(previewEntity, true)
        SetEntityVisible(previewEntity, true, false)
        SetEntityAlpha(previewEntity, 255, false)
        ApplyPreviewAttachment()
    end
end

local gizmoInitialAttachCoords = nil
local gizmoInitialPropCoords = nil
local gizmoInitialPropRot = nil

local function SetGizmoMode(enable, mode)
    if not isEditing then return end
    
    gizmoActive = enable
    if enable then
        gizmoMode = mode or "Translate"
        if gizmoMode == "Translate" then
            ExecuteCommand("+gizmoTranslation")
        elseif gizmoMode == "Rotate" then
            ExecuteCommand("+gizmoRotation")
        end
        
        -- Detach preview entity so SetEntityMatrix and native Gizmo manipulate it directly in world space without feedback loops
        if previewEntity and DoesEntityExist(previewEntity) then
            DetachEntity(previewEntity, true, true)
            FreezeEntityPosition(previewEntity, true)
            SetEntityCollision(previewEntity, false, false)
        end

        SetNuiFocus(false, false)
        EnterCursorMode()
        gizmoCursorActive = true
        
        SendNUIMessage({
            action = "enterGizmoMode",
            mode = gizmoMode,
            category = currentCategory,
            coords = currentCoords,
        })
    else
        if gizmoCursorActive then
            LeaveCursorMode()
            gizmoCursorActive = false
        end
        
        ApplyPreviewAttachment()
        SetNuiFocus(true, true)
        
        SendNUIMessage({
            action = "exitGizmoMode",
            category = currentCategory,
            coords = currentCoords,
        })
    end
end

local function ApplyPedPose(pose)
    currentPed = PlayerPedId()
    if not currentPed or not DoesEntityExist(currentPed) then return end
    currentPose = pose

    if pose == "free" then
        FreezeEntityPosition(currentPed, false)
        SetPedCanPlayAmbientAnims(currentPed, true)
        SetPedCanPlayAmbientBaseAnims(currentPed, true)
        SetPedCanArmIk(currentPed, true)
        SetPedCanHeadIk(currentPed, true)
        SetPedCanLegIk(currentPed, true)
        SetPedCanTorsoIk(currentPed, true)
        ClearPedTasks(currentPed)
    else
        FreezeEntityPosition(currentPed, true)
        SetPedCanPlayAmbientAnims(currentPed, false)
        SetPedCanPlayAmbientBaseAnims(currentPed, false)
        SetPedCanArmIk(currentPed, false)
        SetPedCanHeadIk(currentPed, false)
        SetPedCanLegIk(currentPed, false)
        SetPedCanTorsoIk(currentPed, false)
        SetPedCanUseAutoConversationLookat(currentPed, false)
        ClearPedTasksImmediately(currentPed)

        local dict, anim = nil, nil
        if pose == "static_tpose" or pose == "tpose" then
            dict = "mp_sleep"
            anim = "bind_pose_180"
        elseif pose == "apose" or pose == "static_apose" then
            dict = "anim@heists@heist_corona@single_team"
            anim = "single_team_loop_boss"
        elseif pose == "stand" or pose == "static_stand" then
            dict = "amb@world_human_stand_guard@male@base"
            anim = "base"
        elseif pose == "handsup" then
            dict = "missminuteman_1ig_2"
            anim = "handsup_base"
        elseif pose == "waist" then
            dict = "amb@world_human_cop_idles@male@idle_b"
            anim = "idle_e"
        end

        if dict and anim then
            if LoadAnimDictAsync(dict) then
                TaskPlayAnim(currentPed, dict, anim, 8.0, -8.0, -1, 1, 0, false, false, false)
                Wait(30)
                SetEntityAnimSpeed(currentPed, dict, anim, 0.0)
            end
        end
    end

    Wait(30)
    ApplyPreviewAttachment()
end

local function GetDefaultModelForCategory(category)
    if Config and Config.RealWeapons then
        for _, w in ipairs(Config.RealWeapons) do
            if w.model and w.model ~= "" and (w.category == category or (category:find("handgun") and w.category == "handguns") or (category:find("rifle") and w.category == "assault")) then
                return w.model
            end
        end
    end

    if category:find("handgun") or category == "boxers" or category == "revolver" or category == "handguns" or category == "waisthandgun" or category == "chesthandgun" or category == "hiphandgun" or category == "leghandgun" or category == "handguns2" or category == "backhandgun" then
        return "w_pi_combatpistol"
    elseif category:find("rifle") or category == "assault" or category == "machine" or category == "tacticalrifle" then
        return "w_ar_carbinerifle"
    elseif category == "shotgun" then
        return "w_sg_pumpshotgun"
    elseif category == "sniper" then
        return "w_sr_sniperrifle"
    elseif category:find("melee") or category == "bat" or category == "katana" then
        return "prop_w_me_knife_01"
    end
    return "w_pi_combatpistol"
end

-- Lista ordenada de categorías con prioridad en los 10 holsters del QuickMenu
local function BuildCategoriesList(dbOffsets)
    local orderedKeys = {
        -- QuickMenu Pistolas (8 opciones)
        "waisthandgun",
        "handguns",
        "chesthandgun",
        "hiphandgun",
        "leghandgun",
        "handguns2",
        "backhandgun",
        "boxers",
        -- QuickMenu Rifles (2 opciones)
        "tacticalrifle",
        "assault",
        -- Otras categorías de armas
        "shotgun",
        "sniper",
        "machine",
        "heavy",
        "revolver",
        "bighandgun",
        "utilityhandgun",
        "bat",
        "katana",
        "smallmelee",
        "bigmelee",
        "utilitymelee"
    }

    local offsetMap = {}
    if Config and Config.WeaponCategoryOffsets then
        for _, def in ipairs(Config.WeaponCategoryOffsets) do
            offsetMap[def.category] = def
        end
    end

    local list = {}
    local added = {}

    for _, catKey in ipairs(orderedKeys) do
        local def = offsetMap[catKey] or {
            category = catKey,
            bone = 11816,
            x = 0.0, y = 0.0, z = 0.0,
            xRot = 0.0, yRot = 0.0, zRot = 0.0
        }
        local activeOffset = (dbOffsets and dbOffsets[catKey]) or def
        table.insert(list, {
            category    = catKey,
            bone        = activeOffset.bone or def.bone,
            x           = activeOffset.x or def.x,
            y           = activeOffset.y or def.y,
            z           = activeOffset.z or def.z,
            xRot        = activeOffset.xRot or def.xRot,
            yRot        = activeOffset.yRot or def.yRot,
            zRot        = activeOffset.zRot or def.zRot,
            defaultBone = def.bone,
            defaultX    = def.x,
            defaultY    = def.y,
            defaultZ    = def.z,
            defaultXRot = def.xRot,
            defaultYRot = def.yRot,
            defaultZRot = def.zRot,
        })
        added[catKey] = true
    end

    if Config and Config.WeaponCategoryOffsets then
        for _, def in ipairs(Config.WeaponCategoryOffsets) do
            if not added[def.category] then
                local activeOffset = (dbOffsets and dbOffsets[def.category]) or def
                table.insert(list, {
                    category    = def.category,
                    bone        = activeOffset.bone or def.bone,
                    x           = activeOffset.x or def.x,
                    y           = activeOffset.y or def.y,
                    z           = activeOffset.z or def.z,
                    xRot        = activeOffset.xRot or def.xRot,
                    yRot        = activeOffset.yRot or def.yRot,
                    zRot        = activeOffset.zRot or def.zRot,
                    defaultBone = def.bone,
                    defaultX    = def.x,
                    defaultY    = def.y,
                    defaultZ    = def.z,
                    defaultXRot = def.xRot,
                    defaultYRot = def.yRot,
                    defaultZRot = def.zRot,
                })
            end
        end
    end

    return list
end

local function AdjustCameraForCategory(cat)
    if cat == "chesthandgun" or cat == "tacticalrifle" then
        camHeight = 0.30
        camDist = 1.25
        camAngleZ = 0.0
        camAngleX = 0.0
    elseif cat == "leghandgun" or cat == "handguns2" or cat == "hiphandgun" or cat == "handguns" then
        camHeight = -0.15
        camDist = 1.25
        camAngleZ = 45.0
        camAngleX = -10.0
    elseif cat == "backhandgun" or cat == "assault" or cat == "shotgun" or cat == "sniper" or cat == "heavy" then
        camHeight = 0.20
        camDist = 1.45
        camAngleZ = 180.0
        camAngleX = 0.0
    else
        camHeight = 0.05
        camDist = 1.35
        camAngleZ = 0.0
        camAngleX = -5.0
    end
    UpdateCamPosition()
end

function OpenWeaponOffsetEditor()
    if isEditing then return end

    FW_TriggerCallback("origen_police:server:canEditWeaponOffsets", function(canEdit)
        if not canEdit then
            FW_Notify("No tienes permisos de administrador para ajustar las posiciones de armas.", "error")
            return
        end

        isEditing = true
        gizmoActive = false
        currentPed = PlayerPedId()

        pcall(function()
            exports['origen_police']:SetHolsterPaused(true)
        end)
        RemoveGears()

        if DoesCamExist(editorCam) then
            DestroyCam(editorCam, false)
        end
        editorCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
        SetCamActive(editorCam, true)
        RenderScriptCams(true, true, 500, true, true)

        camDist = 1.35
        camAngleZ = 0.0
        camAngleX = 0.0
        camHeight = 0.05
        camFov = 45.0
        UpdateCamPosition()

        ApplyPedPose("static_tpose")

        CreateThread(function()
            while isEditing do
                if currentPose == "free" then
                    UpdateCamPosition()
                end
                Wait(0)
            end
        end)

        local initialCategories = BuildCategoriesList(nil)
        currentCategory = "waisthandgun"
        local initialEntry = initialCategories[1] or { bone = 11816, x = -0.025, y = 0.017, z = 0.196, xRot = -92.9, yRot = 8.6, zRot = -4.8 }
        currentBone = initialEntry.bone
        currentCoords = {
            x = initialEntry.x,
            y = initialEntry.y,
            z = initialEntry.z,
            xRot = initialEntry.xRot,
            yRot = initialEntry.yRot,
            zRot = initialEntry.zRot
        }
        currentModel = GetDefaultModelForCategory(currentCategory)

        SpawnPreviewProp(currentModel)
        AdjustCameraForCategory(currentCategory)

        SetNuiFocus(true, true)
        SendNUIMessage({
            action = "openWeaponPos",
            categories = initialCategories,
            realWeapons = Config.RealWeapons or {},
            currentCategory = currentCategory,
            currentBone = currentBone,
            currentCoords = currentCoords,
            currentModel = currentModel,
            currentPose = currentPose,
            boneOptions = {
                { id = 11816, label = "Pelvis / Cintura (11816)" },
                { id = 24818, label = "Pecho / Espina Alta (24818)" },
                { id = 24816, label = "Espalda Baja / Espina 1 (24816)" },
                { id = 51826, label = "Muslo Derecho (51826)" },
                { id = 58271, label = "Muslo Izquierdo (58271)" },
                { id = 10706, label = "Clavícula Derecha (10706)" },
                { id = 64729, label = "Clavícula Izquierda (64729)" },
                { id = 6442,  label = "Cadera Derecha (6442)" },
            }
        })

        FW_TriggerCallback("origen_police:server:getGlobalWeaponOffsets", function(dbOffsets)
            if not isEditing then return end
            if dbOffsets and next(dbOffsets) then
                local updatedList = BuildCategoriesList(dbOffsets)
                local cur = dbOffsets[currentCategory]
                if cur then
                    currentBone = cur.bone or currentBone
                    currentCoords = {
                        x = cur.x or currentCoords.x,
                        y = cur.y or currentCoords.y,
                        z = cur.z or currentCoords.z,
                        xRot = cur.xRot or currentCoords.xRot,
                        yRot = cur.yRot or currentCoords.yRot,
                        zRot = cur.zRot or currentCoords.zRot
                    }
                    ApplyPreviewAttachment()
                end

                SendNUIMessage({
                    action = "openWeaponPos",
                    categories = updatedList,
                    realWeapons = Config.RealWeapons or {},
                    currentCategory = currentCategory,
                    currentBone = currentBone,
                    currentCoords = currentCoords,
                    currentModel = currentModel,
                    currentPose = currentPose,
                })
            end
        end)
    end)
end

function CloseWeaponOffsetEditor()
    if not isEditing then return end
    isEditing = false
    
    if gizmoActive then
        SetGizmoMode(false)
    end

    SetNuiFocus(false, false)
    SendNUIMessage({ action = "closeWeaponPos" })

    if previewEntity and DoesEntityExist(previewEntity) then
        DetachEntity(previewEntity, true, true)
        DeleteEntity(previewEntity)
        previewEntity = nil
    end

    if DoesCamExist(editorCam) then
        SetCamActive(editorCam, false)
        DestroyCam(editorCam, false)
        editorCam = nil
    end
    RenderScriptCams(false, true, 500, true, true)

    if currentPed and DoesEntityExist(currentPed) then
        FreezeEntityPosition(currentPed, false)
        SetPedCanPlayAmbientAnims(currentPed, true)
        SetPedCanPlayAmbientBaseAnims(currentPed, true)
        SetPedCanArmIk(currentPed, true)
        SetPedCanHeadIk(currentPed, true)
        SetPedCanLegIk(currentPed, true)
        SetPedCanTorsoIk(currentPed, true)
        ClearPedTasks(currentPed)
    end

    pcall(function()
        exports['origen_police']:SetHolsterPaused(false)
    end)
    Wait(200)
    SetGears()
end

-- ============================================================
-- BUCLE PRINCIPAL DE GIZMO NATIVO
-- ============================================================
CreateThread(function()
    while true do
        if isEditing and gizmoActive and previewEntity and DoesEntityExist(previewEntity) then
            DisableControlAction(0, 24, true)   -- Attack (Left click)
            DisableControlAction(0, 25, true)   -- Aim (Right click)
            DisableControlAction(0, 140, true)
            DisableControlAction(0, 14, true)
            DisableControlAction(0, 15, true)
            DisableControlAction(0, 1, true)
            DisableControlAction(0, 2, true)
            DisablePlayerFiring(PlayerId(), true)

            -- Manejo de clic derecho para rotar la cámara orbital
            local isRightClickPressed = IsDisabledControlPressed(0, 25) or IsControlPressed(0, 25)
            if isRightClickPressed then
                if gizmoCursorActive then
                    LeaveCursorMode()
                    gizmoCursorActive = false
                end
                local mouseX = GetDisabledControlNormal(0, 1) * -7.5
                local mouseY = GetDisabledControlNormal(0, 2) * -7.5
                if mouseX ~= 0.0 or mouseY ~= 0.0 then
                    camAngleZ = (camAngleZ + mouseX) % 360.0
                    camAngleX = math.max(-45.0, math.min(60.0, camAngleX + mouseY))
                    UpdateCamPosition()
                end
            else
                if not gizmoCursorActive then
                    EnterCursorMode()
                    gizmoCursorActive = true
                end
            end

            -- Zoom con la rueda del ratón
            if IsDisabledControlJustPressed(0, 14) or IsControlJustPressed(0, 14) then -- Scroll Down
                camDist = math.min(3.5, camDist + 0.12)
                camFov = math.min(70.0, camFov + 2.0)
                UpdateCamPosition()
            elseif IsDisabledControlJustPressed(0, 15) or IsControlJustPressed(0, 15) then -- Scroll Up
                camDist = math.max(0.5, camDist - 0.12)
                camFov = math.max(20.0, camFov - 2.0)
                UpdateCamPosition()
            end

            -- Tecla W -> Traslación
            if IsDisabledControlJustPressed(0, 32) or IsControlJustPressed(0, 32) then -- W
                gizmoMode = 'Translate'
                ExecuteCommand('+gizmoTranslation')
                SendNUIMessage({ action = "setGizmoTool", tool = "Translate" })
            end

            -- Tecla R -> Rotación
            if IsDisabledControlJustPressed(0, 45) or IsControlJustPressed(0, 45) then -- R
                gizmoMode = 'Rotate'
                ExecuteCommand('+gizmoRotation')
                SendNUIMessage({ action = "setGizmoTool", tool = "Rotate" })
            end

            -- Tecla Q -> Local / Mundo
            if IsDisabledControlJustPressed(0, 44) or IsControlJustPressed(0, 44) then -- Q
                ExecuteCommand('+gizmoLocal')
            end

            -- Tecla ENTER -> Guardar posición a BBDD y notificar
            if IsDisabledControlJustPressed(0, 191) or IsControlJustPressed(0, 191) then -- Enter
                TriggerServerEvent("origen_police:server:saveGlobalWeaponOffset", {
                    category = currentCategory,
                    bone     = currentBone,
                    x        = currentCoords.x,
                    y        = currentCoords.y,
                    z        = currentCoords.z,
                    xRot     = currentCoords.xRot,
                    yRot     = currentCoords.yRot,
                    zRot     = currentCoords.zRot,
                })
                SendNUIMessage({
                    action = "showSaveSuccess",
                    category = currentCategory,
                    coords = currentCoords,
                })
                SetGizmoMode(false)
            end

            -- Tecla ESC / BACKSPACE / G -> Volver al panel completo
            if IsDisabledControlJustPressed(0, 177) or IsControlJustPressed(0, 177) or IsDisabledControlJustPressed(0, 47) or IsControlJustPressed(0, 47) then
                if not isRightClickPressed then
                    SetGizmoMode(false)
                end
            end

            -- Invocar Gizmo nativo de FiveM
            local matrixBuffer = makeEntityMatrix(previewEntity)
            local changed = Citizen.InvokeNative(
                0xEB2EDCA2,
                matrixBuffer:Buffer(),
                'WeaponOffsetGizmo',
                Citizen.ReturnResultAnyway()
            )

            if changed then
                applyEntityMatrix(previewEntity, matrixBuffer)

                local propPos = GetEntityCoords(previewEntity)
                local bonePos = GetPedBoneCoords(currentPed, currentBone, 0.0, 0.0, 0.0)
                local dx = propPos.x - bonePos.x
                local dy = propPos.y - bonePos.y
                local dz = propPos.z - bonePos.z
                local f, r, u, a = GetEntityMatrix(currentPed)

                currentCoords.x = math.floor((dx * r[1] + dy * r[2] + dz * r[3]) * 1000 + 0.5) / 1000
                currentCoords.y = math.floor((dx * f[1] + dy * f[2] + dz * f[3]) * 1000 + 0.5) / 1000
                currentCoords.z = math.floor((dx * u[1] + dy * u[2] + dz * u[3]) * 1000 + 0.5) / 1000

                local propRot = GetEntityRotation(previewEntity, 2)
                local pedRot = GetEntityRotation(currentPed, 2)
                local dRx = propRot.x - pedRot.x
                local dRy = propRot.y - pedRot.y
                local dRz = propRot.z - pedRot.z

                while dRx > 180 do dRx = dRx - 360 end
                while dRx < -180 do dRx = dRx + 360 end
                while dRy > 180 do dRy = dRy - 360 end
                while dRy < -180 do dRy = dRy + 360 end
                while dRz > 180 do dRz = dRz - 360 end
                while dRz < -180 do dRz = dRz + 360 end

                currentCoords.xRot = math.floor(dRx * 10 + 0.5) / 10
                currentCoords.yRot = math.floor(dRy * 10 + 0.5) / 10
                currentCoords.zRot = math.floor(dRz * 10 + 0.5) / 10

                SendNUIMessage({
                    action = "updateGizmoCoords",
                    coords = currentCoords,
                    category = currentCategory,
                })
            end

            Wait(0)
        else
            Wait(200)
        end
    end
end)

-- ─────────────────────────────────────────────
-- Mappings de teclas para Gizmo
-- ─────────────────────────────────────────────
RegisterCommand('+wpos_gizmoSelect', function()
    if not gizmoActive then return end
    ExecuteCommand('+gizmoSelect')
end, false)
RegisterCommand('-wpos_gizmoSelect', function()
    ExecuteCommand('-gizmoSelect')
end, false)
RegisterKeyMapping('+wpos_gizmoSelect', 'Ajuste de armas: seleccionar', 'MOUSE_BUTTON', 'MOUSE_LEFT')

RegisterCommand('+wpos_gizmoTranslation', function()
    if not gizmoActive then return end
    gizmoMode = 'Translate'
    ExecuteCommand('+gizmoTranslation')
    SendNUIMessage({ action = "setGizmoTool", tool = "Translate" })
end, false)
RegisterCommand('-wpos_gizmoTranslation', function()
    ExecuteCommand('-gizmoTranslation')
end, false)
RegisterKeyMapping('+wpos_gizmoTranslation', 'Ajuste de armas: mover', 'keyboard', 'W')

RegisterCommand('+wpos_gizmoRotation', function()
    if not gizmoActive then return end
    gizmoMode = 'Rotate'
    ExecuteCommand('+gizmoRotation')
    SendNUIMessage({ action = "setGizmoTool", tool = "Rotate" })
end, false)
RegisterCommand('-wpos_gizmoRotation', function()
    ExecuteCommand('-gizmoRotation')
end, false)
RegisterKeyMapping('+wpos_gizmoRotation', 'Ajuste de armas: rotar', 'keyboard', 'R')

RegisterCommand('+wpos_gizmoLocal', function()
    if not gizmoActive then return end
    ExecuteCommand('+gizmoLocal')
end, false)
RegisterCommand('-wpos_gizmoLocal', function()
    ExecuteCommand('-gizmoLocal')
end, false)
RegisterKeyMapping('+wpos_gizmoLocal', 'Ajuste de armas: espacio local/mundo', 'keyboard', 'Q')

-- ============================================================
-- NUI CALLBACKS
-- ============================================================

RegisterNUICallback("origen_police:weaponpos:toggleGizmo", function(data, cb)
    local state = data and data.enable
    if state == nil then state = not gizmoActive end
    SetGizmoMode(state, data and data.mode)
    cb("ok")
end)

RegisterNUICallback("origen_police:weaponpos:setGizmoMode", function(data, cb)
    if data and data.mode then
        gizmoMode = data.mode
        if data.mode == 'Translate' then
            ExecuteCommand('+gizmoTranslation')
        elseif data.mode == 'Rotate' then
            ExecuteCommand('+gizmoRotation')
        end
    end
    cb("ok")
end)

RegisterNUICallback("origen_police:weaponpos:updateLive", function(data, cb)
    if not isEditing then return cb("error") end

    if data.bone then currentBone = tonumber(data.bone) end
    if data.x ~= nil then currentCoords.x = tonumber(data.x) end
    if data.y ~= nil then currentCoords.y = tonumber(data.y) end
    if data.z ~= nil then currentCoords.z = tonumber(data.z) end
    if data.xRot ~= nil then currentCoords.xRot = tonumber(data.xRot) end
    if data.yRot ~= nil then currentCoords.yRot = tonumber(data.yRot) end
    if data.zRot ~= nil then currentCoords.zRot = tonumber(data.zRot) end

    if not previewEntity or not DoesEntityExist(previewEntity) then
        SpawnPreviewProp(currentModel)
    else
        ApplyPreviewAttachment()
    end
    cb("ok")
end)

RegisterNUICallback("origen_police:weaponpos:setPedPose", function(data, cb)
    if not isEditing or not data or not data.pose then return cb("error") end
    ApplyPedPose(data.pose)
    cb("ok")
end)

RegisterNUICallback("origen_police:weaponpos:changeCategory", function(data, cb)
    if not isEditing or not data or not data.category then return cb("error") end

    currentCategory = data.category
    currentBone = tonumber(data.bone) or 11816
    currentCoords = {
        x = tonumber(data.x) or 0.0,
        y = tonumber(data.y) or 0.0,
        z = tonumber(data.z) or 0.0,
        xRot = tonumber(data.xRot) or 0.0,
        yRot = tonumber(data.yRot) or 0.0,
        zRot = tonumber(data.zRot) or 0.0,
    }

    local targetModel = data.model or GetDefaultModelForCategory(currentCategory)
    currentModel = targetModel
    SpawnPreviewProp(currentModel)
    AdjustCameraForCategory(currentCategory)

    cb("ok")
end)

RegisterNUICallback("origen_police:weaponpos:changeModel", function(data, cb)
    if not isEditing or not data or not data.model then return cb("error") end

    currentModel = data.model
    SpawnPreviewProp(currentModel)
    cb("ok")
end)

RegisterNUICallback("origen_police:weaponpos:rotateCam", function(data, cb)
    if not isEditing or not data then return cb("error") end

    local deltaX = tonumber(data.dx) or 0.0
    local deltaY = tonumber(data.dy) or 0.0

    camAngleZ = (camAngleZ + deltaX * 0.45) % 360.0
    camAngleX = math.max(-45.0, math.min(60.0, camAngleX + deltaY * 0.45))

    UpdateCamPosition()
    cb("ok")
end)

RegisterNUICallback("origen_police:weaponpos:zoomCam", function(data, cb)
    if not isEditing or not data then return cb("error") end

    local delta = tonumber(data.delta) or 0.0
    if delta > 0 then
        camDist = math.max(0.6, camDist - 0.15)
        camFov = math.max(20.0, camFov - 2.5)
    else
        camDist = math.min(3.5, camDist + 0.15)
        camFov = math.min(70.0, camFov + 2.5)
    end

    UpdateCamPosition()
    cb("ok")
end)

RegisterNUICallback("origen_police:weaponpos:setCamPreset", function(data, cb)
    if not isEditing or not data or not data.preset then return cb("error") end

    local p = data.preset
    if p == "front" then
        camAngleZ = 0.0
        camAngleX = 0.0
        camDist = 1.35
        camHeight = 0.05
        camFov = 45.0
    elseif p == "back" then
        camAngleZ = 180.0
        camAngleX = 0.0
        camDist = 1.45
        camHeight = 0.1
        camFov = 45.0
    elseif p == "right" then
        camAngleZ = 90.0
        camAngleX = 0.0
        camDist = 1.35
        camHeight = 0.0
        camFov = 45.0
    elseif p == "left" then
        camAngleZ = 270.0
        camAngleX = 0.0
        camDist = 1.35
        camHeight = 0.0
        camFov = 45.0
    elseif p == "chest" then
        camAngleZ = 0.0
        camAngleX = 5.0
        camDist = 1.05
        camHeight = 0.32
        camFov = 35.0
    elseif p == "waist" then
        camAngleZ = 0.0
        camAngleX = -10.0
        camDist = 1.15
        camHeight = 0.0
        camFov = 35.0
    elseif p == "leg" then
        camAngleZ = 50.0
        camAngleX = -15.0
        camDist = 1.15
        camHeight = -0.2
        camFov = 35.0
    elseif p == "full" then
        camAngleZ = 0.0
        camAngleX = 0.0
        camDist = 2.2
        camHeight = 0.0
        camFov = 50.0
    end

    UpdateCamPosition()
    cb("ok")
end)

RegisterNUICallback("origen_police:weaponpos:saveGlobal", function(data, cb)
    if not isEditing or not data then return cb("error") end

    TriggerServerEvent("origen_police:server:saveGlobalWeaponOffset", {
        category = data.category or currentCategory,
        bone     = tonumber(data.bone) or currentBone,
        x        = tonumber(data.x) or currentCoords.x,
        y        = tonumber(data.y) or currentCoords.y,
        z        = tonumber(data.z) or currentCoords.z,
        xRot     = tonumber(data.xRot) or currentCoords.xRot,
        yRot     = tonumber(data.yRot) or currentCoords.yRot,
        zRot     = tonumber(data.zRot) or currentCoords.zRot,
    })

    cb("ok")
end)

RegisterNUICallback("origen_police:weaponpos:saveAllGlobal", function(data, cb)
    if not isEditing or not data or not data.allOffsets then return cb("error") end

    TriggerServerEvent("origen_police:server:saveAllGlobalWeaponOffsets", data.allOffsets)
    cb("ok")
end)

RegisterNUICallback("origen_police:weaponpos:resetDefault", function(data, cb)
    if not isEditing or not data or not data.category then return cb("error") end

    TriggerServerEvent("origen_police:server:resetGlobalWeaponOffset", data.category)

    if Config and Config.WeaponCategoryOffsets then
        for _, def in ipairs(Config.WeaponCategoryOffsets) do
            if def.category == data.category then
                currentBone = def.bone
                currentCoords = {
                    x = def.x,
                    y = def.y,
                    z = def.z,
                    xRot = def.xRot,
                    yRot = def.yRot,
                    zRot = def.zRot
                }
                ApplyPreviewAttachment()
                break
            end
        end
    end

    cb("ok")
end)

RegisterNUICallback("origen_police:weaponpos:close", function(data, cb)
    CloseWeaponOffsetEditor()
    cb("ok")
end)

-- ============================================================
-- COMMANDS & NET EVENTS
-- ============================================================

RegisterCommand("weaponpos", function()
    OpenWeaponOffsetEditor()
end, false)

RegisterCommand("ajustararmas", function()
    OpenWeaponOffsetEditor()
end, false)

RegisterNetEvent("origen_police:client:openWeaponPosEditor", function()
    OpenWeaponOffsetEditor()
end)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName == GetCurrentResourceName() then
        if isEditing then
            CloseWeaponOffsetEditor()
        end
    end
end)

--[[ Raton soltado a la fuerza con el editor abierto: se cierra entero (camara,
     prop de muestra, pose del personaje), o el jugador se quedaba en T con la
     camara del editor y sin raton para salir. El gizmo se apaga a mano antes:
     SetGizmoMode(false) volveria a coger el foco. Sin editor, no hace nada. ]]
if OrigenFoco and OrigenFoco.AlSoltar then
    OrigenFoco.AlSoltar(function()
        if not isEditing then return end
        if gizmoActive then
            gizmoActive = false
            if gizmoCursorActive then
                LeaveCursorMode()
                gizmoCursorActive = false
            end
        end
        -- Espera 200 ms por dentro: en su propio hilo.
        CreateThread(CloseWeaponOffsetEditor)
    end)
end
