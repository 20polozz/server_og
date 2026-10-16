Outfit = {}
Outfit.__index = Outfit
Outfit.Table = {}
Outfit.CivilianClothes = nil
Outfit.Model = nil

function Outfit.Get(id)
    return Outfit.Table[id]
end

function Outfit.GetCivilOutfits()
    local currentModel = GetEntityModel(cache.ped)
    
    if not Outfit.Model or Outfit.Model ~= currentModel then
        Outfit.LoadOutfits()
    end
    
    local civilOutfits = {}
    for _, outfit in pairs(Outfit.Table) do
        if not outfit.isJob then
            table.insert(civilOutfits, outfit)
        end
    end
    return civilOutfits
end

function Outfit.GetJobOutfits(isBoss)
    local currentModel = GetEntityModel(cache.ped)
    
    if not Outfit.Model or Outfit.Model ~= currentModel then
        Outfit.LoadOutfits()
    end
    
    local jobOutfits = {}
    for _, outfit in pairs(Outfit.Table) do
        if outfit.isJob and (isBoss or outfit.model == GetEntityModelName(currentModel)) then
            table.insert(jobOutfits, outfit)
        end
    end
    
    return jobOutfits
end

function Outfit.CleanUp()
    Outfit.Table = {}
end

function Outfit.New(data)
    local self = setmetatable({}, Outfit)

    self.id = tostring(data.id)
    self.model = data.model
    self.label = data.label
    self.drawables = data.drawables
    self.props = data.props
    self.isJob = data.jobOutfit
    self.isEquipped = data.isEquipped or false

    Outfit.Table[self.id] = self

    return self
end

function Outfit.GetEquipped(onlyJob)
    for _, outfit in pairs(Outfit.Table) do
        if outfit.isEquipped and (not onlyJob or outfit.isJob) then
            return outfit
        end
    end
    return nil
end

exports('getEquippedOutfit', function(onlyJob)
    return Outfit.GetEquipped(onlyJob)
end)

exports["origen_clothing"]:getEquippedOutfit(true)

function Outfit:AddToNui()
    SendNUIMessage({
        action = "addOutfit",
        outfit = {
            id = self.id,
            model = self.model,
            label = self.label,
            drawables = self.drawables,
            props = self.props,
            isJob = self.isJob
        }
    })
end

function Outfit:Remove()
    local result = lib.callback.await('origen_clothing:server:RemoveOutfit', false, self.id, self.isJob)

    if result then
        if not self.isJob then
            Outfit.Table[self.id] = nil
        end

        return true
    end
end

function Outfit:Equip(ped)
    ped = ped or cache.ped

    local equipped = Outfit.GetEquipped()

    if equipped then
        equipped.isEquipped = false
    end

    if self.isJob and not Outfit.CivilianClothes then
        Outfit.CivilianClothes = {
            drawables = GetPedDrawablesHash(ped, {
                ['hair'] = true
            }),
            props = GetPedPropsHash(ped)
        }
    end

    SetPedDrawablesByHash(ped, self.drawables)
    SetPedPropsByHash(ped, self.props)

    if not self.isJob then
        SaveAppearance()
    end
    
    self.isEquipped = true
end

function Outfit:Unequip(ped)
    ped = ped or cache.ped
    self.isEquipped = false
    if Outfit.CivilianClothes then
        SetPedDrawablesByHash(ped, Outfit.CivilianClothes.drawables)
        SetPedPropsByHash(ped, Outfit.CivilianClothes.props)
        Outfit.CivilianClothes = nil
    end
end

function Outfit:UpdateClothes(ped)
    ped = ped or cache.ped
    local drawables = GetPedDrawablesHash(ped, {
        ['hair'] = true
    })
    local props = GetPedPropsHash(ped)

    TriggerServerEvent('origen_clothing:server:UpdateOutfitClothes', {
        id = self.id,
        label = self.label,
        drawables = drawables,
        props = props
    })
end

function Outfit:UpdateData(data)
    self.label = data.label or self.label
    self.isJob = data.isJob or self.isJob
    self.drawables = data.drawables or self.drawables
    self.props = data.props or self.props
    self.model = data.model or self.model
end

function Outfit:IsSame(drawables, props)
    for name, value in pairs(self.drawables) do
        if not drawables[name] or drawables[name] ~= value then
            return false
        end
    end

    for name, value in pairs(self.props) do
        if not props[name] or props[name] ~= value then
            return false
        end
    end

    return true
end

function Outfit:TempEquip(ped)
    ped = ped or cache.ped
    SetPedDrawablesByHash(ped, self.drawables)
    SetPedPropsByHash(ped, self.props)
end

function Outfit.LoadOutfits()
    local currentModel = GetEntityModel(cache.ped)
    local outfitsData = lib.callback.await('origen_clothing:server:GetOutfits', false, Custom.GetPlayerIdentifier(), Config.Peds[currentModel], Custom.GetJob().name)
    local equippedOutfitId = Outfit.GetEquipped() and Outfit.GetEquipped().id or 0

    Outfit.CleanUp()
    Outfit.Model = currentModel

    for _, data in pairs(outfitsData) do
        local outfit = Outfit.New(data)
        
        if outfit.id == equippedOutfitId then
            outfit.isEquipped = true
        end
    end
end

function Outfit.OpenMenu(isJob, canEdit)
    local isBoss = false

    if isJob then
        if canEdit == nil then
            local playerJob = Custom.GetJob()
            local bossGrade = Config.JobOutfits.bossGrade[playerJob.name]

            isBoss = bossGrade and playerJob.grade >= bossGrade
        else
            isBoss = canEdit
        end
    end

    StartCamera(true)
    OpenClothing('outfit', {
        isBoss = isBoss,
        outfits = isJob and Outfit.GetJobOutfits(isBoss) or Outfit.GetCivilOutfits(),
        drawables = GetPedDrawables(cache.ped),
        props = GetPedProps(cache.ped)
    })
end

exports('openOutfitMenu', Outfit.OpenMenu)

RegisterNetEvent('origen_clothing:client:UpdateOutfit', function(outfitData)
    if outfitData.jobOutfit then
        if Custom.GetJob().name ~= outfitData.identifier then
            return
        end
    end

    local outfit = Outfit.Get(outfitData.id)
    if outfit then
        outfit:UpdateData(outfitData)
    else
        local outfit = Outfit.New(outfitData)
        outfit:AddToNui()
    end
end)

RegisterNetEvent('origen_clothing:client:RemoveJobOutfit', function(outfitId)
    local outfit = Outfit.Get(outfitId)
    if outfit then
        Outfit.Table[outfitId] = nil
    end
end)

RegisterNetEvent('origen_clothing:client:onJobUpdate', function()
    Outfit.LoadOutfits()
end)

-- RegisterNetEvent('origen_clothing:client:onPlayerLoad', function()
--     Outfit.LoadOutfits()
-- end)

Citizen.CreateThread(function()
    if Framework.isPlayerLoaded() then
        TriggerEvent('origen_clothing:client:onPlayerLoad')
    end
end)