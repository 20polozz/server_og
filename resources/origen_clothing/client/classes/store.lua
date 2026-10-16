Store = {}
Store.__index = Store
Store.table = {}

function Store.new(data)
    local self = setmetatable({}, Store)

    self.id = data.id
    self.type = data.type or 'clothes'
    self.label = data.label
    self.coords = data.coords    
    self.polyzone = data.polyzone
    self.blipData = data.blip or {}
    self.stock = data.stock -- 0: Stock disabled, 1: Stock enabled
    self.is_free = data.is_free == 1 or data.is_free == true
    self.blip = nil
    self.point = nil
    self.zone = nil    

    self:createInteraction()
    self:createBlip()

    Store.table[self.id] = self

    return self
end

function Store.get(id)
    return Store.table[id]
end

function Store:GetCenterOfPolyzone()
    local points = self.polyzone.points
    local sumX, sumY, sumZ = 0, 0, 0
    local count = #points

    for _, p in ipairs(points) do
        sumX = sumX + p.x
        sumY = sumY + p.y
        sumZ = sumZ + p.z
    end

    return vec3(sumX / count, sumY / count, sumZ / count)
end

function Store:edit(data)
    if self.blip then
        OrigenMapa.Quitar(self.blip)
        self.blip = nil
    end

    if self.zone then
        self.zone:remove()
        self.zone = nil
    end

    if self.point then
        self.point:remove()
        self.point = nil
    end
    
    self.type = data.type
    self.label = data.label
    self.coords = data.coords
    self.stock = data.stock
    self.is_free = data.is_free == 1 or data.is_free == true
    self.status = data.status
    self.polyzone = data.polyzone
    self.blipData = data.blip or {}

    self:createInteraction()
    self:createBlip()
end

function Store:delete()
    if self.blip then
        OrigenMapa.Quitar(self.blip)
        self.blip = nil
    end

    if self.zone then
        self.zone:remove()
        self.zone = nil
    end

    if self.point then
        self.point:remove()
        self.point = nil
    end

    Store.table[self.id] = nil
end

function Store:createBlip()
    -- 08/10: las tiendas VIP y exclusiva ya no estan en el mapa; los cosmeticos
    -- se venden en el panel (server/cosmeticos.lua).
    if self.type == 'vip' or self.type == 'exclusiva' then return end
    local storeData = Config.StoreTypes[self.type]
    if not storeData or not storeData.blip then
        return
    end

    local blipConfig = self.blipData or {}
    local enabled = blipConfig.enabled
    if enabled == nil then enabled = true end
    if enabled == false then
        return
    end

    local label = self.label or storeData.blip.name

    local coords = self.coords
    if not coords then
        coords = self:GetCenterOfPolyzone()
    end

    --[[ La tienda, en el mapa.

         Ya no se crea un blip del juego: se registra el punto en origen_map,
         que es de donde lo leen los tres mapas del servidor. El interruptor,
         el color y el sprite del panel siguen mandando igual: el color pasa
         por OrigenMapa.Color y el sprite por OrigenMapa.Icono, que traducen el
         numero de GTA de toda la vida al de la chincheta.

         Lo que se gana es el nombre: antes los mapas de Leaflet solo veian el
         numero del sprite y todas las tiendas de ropa salian llamadas «Tienda
         de ropa»; ahora sale la suya. ]]
    self.blip = 'tienda_' .. tostring(self.id)

    --[[ Las tiendas VIP y exclusiva llevan SIEMPRE su dibujo y su color
         (corona dorada y gema morada, Config.StoreTypes): el panel pone el
         sprite 73 y el color 4 por defecto a todas, y sin esto saldrian con
         la camiseta rosa de cualquier tienda de ropa. ]]
    local propio = storeData.blip.icono
    local icono = propio or OrigenMapa.Icono(blipConfig.sprite or storeData.blip.sprite)
    local color = propio and storeData.blip.color or (blipConfig.color or storeData.blip.color)

    OrigenMapa.Poner(self.blip, {
        x = coords.x, y = coords.y, z = coords.z,
        cat = 'shops',
        --- Ropa, barberia o tatuajes: lo dice el sprite de su tipo de tienda.
        --- Las mascaras (362) no tienen dibujo propio y se quedan con la cesta.
        icono = icono,
        nombre = label,
        --- El color que diga el config, traducido del numero de GTA. Si ese
        --- numero no esta en la tabla de OrigenMapa.Color, manda el de la
        --- categoria.
        color = OrigenMapa.Color(color),
    })
end

function Store:createInteraction()    
    -- 08/10: las tiendas VIP y exclusiva ya no estan en el mapa; los cosmeticos
    -- se venden en el panel (server/cosmeticos.lua).
    if self.type == 'vip' or self.type == 'exclusiva' then return end
    local function onEnter()
        if IsCreatingZone then return end
        Custom.DrawText(locale('open_store'), 'E')
    end

    local function onExit()
        Custom.HideText()
    end

    local function inZone()
        if IsCreatingZone then return end
        if IsControlJustReleased(0, 38) then
            if not Custom.CanOpenStore(self.id) then return end
            self:Open()
        end
    end

    if not self.coords or self.coords == nil then
        self.zone = lib.zones.poly({
            points = self.polyzone.points,
            debug = false,
            thickness = self.polyzone.thickness or 50.0,
            onEnter = onEnter,
            onExit = onExit,
            inside = inZone
        })
    else
        self.point = lib.points.new({
            coords = self.coords,
            distance = 3,
            onEnter = onEnter,
            onExit = onExit,
            nearby = inZone,
        })
    end
end

--- Si el servidor cree que sigues en una tienda VIP o exclusiva, te saca. Se
--- llama al cerrar el menu y al abrir cualquier otro, por si se cerro sin avisar.
function SalirDeTiendaEspecial()
    if not EnTiendaEspecial then return end
    EnTiendaEspecial = false
    TriggerServerEvent('origen_clothing:especial:salir')
end

local TIPOS_ESPECIALES = { vip = true, exclusiva = true }

function Store:Open()
    --[[ Las tiendas VIP y exclusiva (server/especiales.lua): el servidor mira
         la distancia (y en la VIP el rol de Discord) y apunta que estas
         dentro. Sin eso no te ensena ni te vende nada de ellas aunque la
         pantalla se abriera. Se abren como una tienda de ropa normal, sin stock. ]]
    local especial = TIPOS_ESPECIALES[self.type] and self.type or nil
    if especial then
        local r = lib.callback.await('origen_clothing:especial:entrar', false, self.id)
        if not r or not r.ok then
            Custom.Notify((r and r.error) or 'No puedes entrar en esta tienda', 'error', 5000)
            return
        end
        EnTiendaEspecial = true
    else
        SalirDeTiendaEspecial()
    end

    StartCamera(true)
    OpenClothing(especial and 'clothes' or (self.stock and 'stock' or self.type), {
        stock = {},
        storeId = self.id,
        is_free = self.is_free,
        tipoTienda = especial or '',
        outfits = Outfit.GetCivilOutfits(),
        actualClothes = GetPedAllHashes(cache.ped, true),
        drawables = GetPedDrawables(cache.ped),
        props = GetPedProps(cache.ped)
    })
end

function Store:GetGlobalCloths(ped)
    local result = {
        drawables = {},
        props = {},
    }
    for k, v in pairs(AppearanceData.drawables) do
        result.drawables[k] = GetNumberOfPedDrawableVariations(ped, v.index)
    end
    for k, v in pairs(AppearanceData.props) do
        result.props[k] = GetNumberOfPedPropDrawableVariations(ped, v.index)
    end
    return result
end

function Store.GetAllData()
    local result = {}
    for id, store in pairs(Store.table) do
        result[#result+1] = {
            id = store.id,
            type = store.type,
            label = store.label,
            coords = store.coords,
            stock = store.stock,
            is_free = store.is_free,
            status = store.status,
            polyzone = store.polyzone,
            blip = store.blipData,
        }
    end
    return result
end