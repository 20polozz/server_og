Quests = {}
Quests.__index = Quests
Quests.Table = {}

local function isQuestInteractPressed()
    return IsControlJustPressed(0, 38)
        or IsDisabledControlJustPressed(0, 38)
        or IsControlJustPressed(0, 51)
        or IsDisabledControlJustPressed(0, 51)
end

function Quests.Create(data)
    if Quests.Table[data.id] then
        Quests.Table[data.id]:Delete()
        Quests.Table[data.id] = nil
    end

    if data.active ~= 1 then return end
    local self = setmetatable({}, Quests)
    self.data = data

    if self.data.type == 'new_npc' or self.data.type == 'new_prop' then
        self:EntityHandler()
    end

    self:CreateInteraction()

    Quests.Table[self.data.id] = self
    return self
end

function Quests:EntityHandler()
    self.entityPoint = lib.points.new({
        coords = self.data.location,
        distance = 20.0,
    })

    local Quest = self
    local npc = nil

    function self.entityPoint:onEnter()
        if Quest.data.type == 'new_npc' then
            Quest:SpawnNPC(Quest.data.model, Quest.data.location, Quest.data.anim1, Quest.data.extra)
        elseif Quest.data.type == 'new_prop' then
            Quest:SpawnProp(Quest.data.model, Quest.data.location, Quest.data.anim1, Quest.data.extra)
        end
    end

    function self.entityPoint:onExit()
        Quest:QuitarEntidad()
    end
end

--[[ Quita el NPC o el prop del punto Y lo que lleva en la mano.

     Antes solo se borraba la entidad: los props de la animacion (una
     carpeta, un cafe, una herramienta) se quedaban flotando en el mundo cada
     vez que te alejabas, y con cientos de puntos eso es llenar un pool a
     base de pasar por delante. ]]
function Quests:QuitarEntidad()
    local e = self.entity
    self.entity = nil
    if not e then return end
    if LocationAnimProps and LocationAnimProps[e] then
        for _, prop in ipairs(LocationAnimProps[e]) do
            if DoesEntityExist(prop) then DeleteEntity(prop) end
        end
        LocationAnimProps[e] = nil
    end
    if DoesEntityExist(e) then DeleteEntity(e) end
end

function Quests:SpawnNPC()
    -- Nunca dos del mismo punto: si quedaba uno, fuera antes de crear otro.
    self:QuitarEntidad()
    local hash = GetHashKey(self.data.model)
    lib.requestModel(hash)
    self.entity = CreatePed(4, hash, self.data.location.x, self.data.location.y, self.data.location.z - 1.0, self.data.location.w, false, true)
    SetModelAsNoLongerNeeded(hash)

    SetEntityHeading(self.entity, self.data.location.w)
    FreezeEntityPosition(self.entity, true)
    SetEntityInvincible(self.entity, true)
    SetBlockingOfNonTemporaryEvents(self.entity, true)
    SetPedConfigFlag(self.entity, 79, true)

    SetPedRelationshipGroupHash(self.entity, GetHashKey("QuestsNPCs"))

    if self.data.anim1 and self.data.anim1 ~= "" then
        ApplyPedAnim(self.entity, self.data.anim1)
    end

    if self.data.extra and self.data.extra.skin then
        SetNPCSkin(self.entity, self.data.extra.skin)
    end

    if self.data.extra and self.data.extra.weapon then
        GiveNPCVisualWeapon(self.entity, self.data.extra.weapon)
    end
end

function Quests:SpawnProp()
    self:QuitarEntidad()
    lib.requestModel(GetHashKey(self.data.model))
    
    if GetMakeNameFromVehicleModel(GetHashKey(self.data.model)) ~= "CARNOTFOUND" then
        self.entity = CreateVehicle(GetHashKey(self.data.model), self.data.location.x, self.data.location.y, self.data.location.z - 1.0, self.data.location.w, false, false)
        SetVehicleUndriveable(self.entity, true)
        SetVehicleDoorsLocked(self.entity, 4)
    else
        self.entity = CreateObject(GetHashKey(self.data.model), self.data.location.x, self.data.location.y, self.data.location.z - 1.0, false, false, false)
    end

    SetEntityHeading(self.entity, self.data.location.w)
    FreezeEntityPosition(self.entity, true)
    SetEntityInvincible(self.entity, true)
end

function Quests:CreateInteraction()
    self.interactionPoint = lib.points.new({
        coords = self.data.location,
        distance = 20.0,
        drawTextShown = false
    })

    local Quest = self

    function self.interactionPoint:onExit()
        exports.origen_notify:HideText()
    end

    function self.interactionPoint:nearby()
        if Quest.data.type == 'marker' then
            local icon, size, color = GetLocationIconVisual(Quest, false)
            DrawMarker(icon, Quest.data.location.xyz, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, size, size, size, color.r, color.g, color.b, color.a, false, false, 0, true)
        elseif (Quest.data.type == 'new_npc' or Quest.data.type == 'new_prop') and Quest.data.extra and Quest.data.extra.hint then
            local icon, size, color = GetLocationIconVisual(Quest, true)
            if icon == 9 then
                DrawMarker(icon, Quest.data.location.xyz + vector3(0.0, 0.0, 1.0), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, size, size, size, color.r, color.g, color.b, color.a, false, false, 0, true)
            else
                DrawMarker(icon, Quest.data.location.xyz + vector3(0.0, 0.0, 1.0), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, size, size, size, color.r, color.g, color.b, color.a, false, false, 0, true)
            end
        end

        if not (Quest.data.extra and Quest.data.extra.interaction) then return end

        if self.currentDistance < 2.0 then
            if not self.drawTextShown then
                exports.origen_notify:DrawText('E', 'Interactuar')
                self.drawTextShown = true
            end
             if isQuestInteractPressed() then
                --[[ Por la misma puerta que todos los demas.

                     Este camino llamaba a OpenMissionsMenu directamente y se
                     saltaba IntentarAbrirSitio: un sitio cerrado a un crew o a
                     una banda se le abria a cualquiera, con el menu vacio
                     porque luego ningun encargo pasaba el filtro. ]]
                IntentarAbrirSitio(Quest.data)
            end
        else
            if self.drawTextShown then
                exports.origen_notify:HideText()
                self.drawTextShown = false
            end
        end
    end
end

function Quests:Delete()
    self:QuitarEntidad()
    if self.entityPoint then self.entityPoint:remove() end
    if self.interactionPoint then self.interactionPoint:remove() end
end

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        for _, Quest in pairs(Quests.Table) do
            Quest:Delete()
        end
    end
end)