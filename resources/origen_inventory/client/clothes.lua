

Cooldown = false
local real_hair, real_hair_txt, real_hair_txt2 = false, false, false

eventPublisher:subscribe('origen_inventory:clothing:mask', function(id)
    ToggleClothing('Mask')
end)

eventPublisher:subscribe('origen_inventory:clothing:top', function(id)
    ToggleClothing('Top')
end)

eventPublisher:subscribe('origen_inventory:clothing:hat', function(id)
    ToggleProps('Hat')
end)

eventPublisher:subscribe('origen_inventory:clothing:glasses', function(id) 
    ToggleProps('Glasses')
end)

eventPublisher:subscribe('origen_inventory:clothing:neck', function(id)
    ToggleClothing('Neck')
end)

eventPublisher:subscribe('origen_inventory:clothing:shirts', function(id)
    ToggleClothing('Shirt')
end)

eventPublisher:subscribe('origen_inventory:clothing:decals', function(id)
    ToggleClothing('Decals')
end)

eventPublisher:subscribe('origen_inventory:clothing:vest', function(id)
    ToggleClothing('Vest')
end)

eventPublisher:subscribe('origen_inventory:clothing:backpack', function(id)
    ToggleClothing('Bag')
end)

eventPublisher:subscribe('origen_inventory:clothing:watch', function(id)
    ToggleProps('Watch')
end)

eventPublisher:subscribe('origen_inventory:clothing:gloves', function(id)
    ToggleClothing('Gloves')
end)

eventPublisher:subscribe('origen_inventory:clothing:shoes', function(id)
    ToggleClothing('Shoes')
end)

eventPublisher:subscribe('origen_inventory:clothing:pants', function(id)
    ToggleClothing('Pants')
end)

eventPublisher:subscribe('origen_inventory:clothing:torso', function(id)
    ToggleClothing('Torso')
end)

eventPublisher:subscribe('origen_inventory:clothing:toggleHair', function(id)
    if GetResourceState('origen_clothing') ~= 'started' then
        return Bridge.Notify('origen_clothing no está activo.', 'error')
    end

    TriggerEvent('origen_clothing:client:selectHairSlot')
end)

local real_hair, real_hair_txt, real_hair_txt2
RegisterCommand('pelo', function()
    local ped = PlayerPedId()
    
    if GetResourceState('origen_clothing') ~= 'started' then
        return Bridge.Notify('origen_clothing no está activo.', 'error')
    end

    if real_hair then
        -- Restaurar el pelo desde caché local
        SetPedComponentVariation(ped, 2, real_hair, 0, 0)
        SetPedHairColor(ped, real_hair_txt, real_hair_txt2)
        real_hair = false
        real_hair_txt = false
        real_hair_txt2 = false
    else
        -- Guardar el pelo ANTES de cambiarlo a nada/calvo
        real_hair = GetPedDrawableVariation(ped, 2)
        real_hair_txt = GetPedHairColor(ped)
        real_hair_txt2 = GetPedHairHighlightColor(ped)

        -- Prevenir que se vuelva a guardar "calvo" como original si justo le da click repetidas veces por lag
        if real_hair == 0 and Config.Clothings.DefaultHairy then
             local genderOptions = Config.Clothings.DefaultHairy
             local gender = IsMpPed(ped)
             if gender == 'Female' and real_hair == genderOptions.Male.Drawable then
                  -- ignorar, ya estabamos calvos, y forzamos restablecer depuis de la base de datos origen_clothing
                  real_hair = false
                  local currentSavedClothes = exports.origen_clothing:GetEquippedClothes(ped, true)
                  if currentSavedClothes and currentSavedClothes['2'] then
                       SetPedComponentVariation(ped, 2, currentSavedClothes['2'].drawable, currentSavedClothes['2'].texture, 0)
                       if currentSavedClothes.hairColor then
                            SetPedHairColor(ped, currentSavedClothes.hairColor.color1, currentSavedClothes.hairColor.color2)
                       end
                  end
                  return
             end
        end

        if Config.Clothings.DefaultHairy then
            local gender = IsMpPed(ped)
            if gender then
                local genderOptions = Config.Clothings.DefaultHairy
                if gender == 'Female' then
                    SetPedComponentVariation(ped, 2, genderOptions.Female.Drawable, genderOptions.Female.Texture, 0)
                else
                    SetPedComponentVariation(ped, 2, genderOptions.Male.Drawable, genderOptions.Male.Texture, 0)
                end
            end
        end
    end
end, false)

---------------
-- Functions --
---------------

local function PlayToggleEmote(e, cb)
	local Ped = PlayerPedId()
	if not e then return cb() end
	while not HasAnimDictLoaded(e.Dict) do RequestAnimDict(e.Dict) Wait(100) end
	local move = e.Move
	if IsPedInAnyVehicle(Ped) then move = 51 end
	TaskPlayAnim(Ped, e.Dict, e.Anim, 3.0, 3.0, e.Dur, move, 0, false, false, false)
	local Pause = e.Dur-500 if Pause < 500 then Pause = 500 end
	IncurCooldown(Pause)
	Wait(Pause) -- Lets wait for the emote to play for a bit then do the callback.
	cb()
end

--[[ ═══════════════════════════════════════════════════════════════════════
     Poner y quitar ropa (reescrito el 14/09).

     Lo de antes llevaba una memoria por BOTON (LastEquipped[boton]) y varios
     botones tocan las mismas piezas del ped: Chaqueta y Torso cambian las dos
     el componente 11 y los brazos, y se pisaban lo guardado. Ademas decidia
     si una prenda estaba puesta comparando un numero con una tabla (siempre
     "puesta"), y Guantes cambiaba los brazos aunque no llevaras guantes.

     Ahora:
       · "Sin prenda" es un numero por componente y sexo
         (Config.Clothings.Desnudo). Una prenda esta puesta si su componente
         NO tiene ese numero. Es la misma regla que usa la pestaña Personaje
         para pintar en rosa (EstadoRopa), asi que no pueden discrepar.
       · Lo que se quita se guarda por COMPONENTE, no por boton. Quitar deja
         guardado lo que habia; poner devuelve lo guardado a los componentes
         que siguen desnudos. Da igual con que boton se quitara.
       · Cada boton tiene sus componentes principales (los que dicen si esta
         puesta) y los que arrastra al quitarse: la chaqueta se lleva los
         brazos, que van a juego con ella.
   ═══════════════════════════════════════════════════════════════════════ ]]

local PIEZAS = {
    Mask   = { comps = { 1 } },
    Neck   = { comps = { 7 } },
    Decals = { comps = { 10 } },
    Vest   = { comps = { 9 } },
    Bag    = { comps = { 5 } },
    Shoes  = { comps = { 6 } },
    Pants  = { comps = { 4 } },
    Shirt  = { comps = { 8 } },
    Top    = { comps = { 11 }, arrastra = { 3 } },
    -- Toda la parte de arriba: chaqueta, camiseta, brazos y accesorio.
    Torso  = { comps = { 11, 8 }, arrastra = { 3, 10 } },
}

local PROPS = { Hat = 0, Glasses = 1, Ear = 2, Watch = 6, Bracelet = 7 }

--- Lo guardado, del modelo que lo llevaba: con otro personaje no vale.
local Guardado = { modelo = nil, comp = {}, prop = {}, guantes = nil }

local function Memoria(ped)
    local modelo = GetEntityModel(ped)
    if Guardado.modelo ~= modelo then
        Guardado = { modelo = modelo, comp = {}, prop = {}, guantes = nil }
    end
    return Guardado
end

local function Desnudo(sexo)
    return Config.Clothings.Desnudo and Config.Clothings.Desnudo[sexo]
end

local function Todos(pieza)
    local l = {}
    for _, c in ipairs(pieza.comps) do l[#l + 1] = c end
    for _, c in ipairs(pieza.arrastra or {}) do l[#l + 1] = c end
    return l
end

local function EstaPuesta(ped, pieza, desnudo)
    for _, c in ipairs(pieza.comps) do
        if desnudo[c] ~= nil and GetPedDrawableVariation(ped, c) ~= desnudo[c] then return true end
    end
    return false
end

local function HayGuardado(mem, pieza)
    for _, c in ipairs(Todos(pieza)) do
        if mem.comp[c] then return true end
    end
    return false
end

--- 'quitar' si lleva guantes, 'poner' si se los quito y los brazos siguen
--- como los dejo, nil si no hay nada que hacer.
local function Guantes(ped, sexo, mem)
    local tabla = Config.Clothings.Variations.Gloves and Config.Clothings.Variations.Gloves[sexo] or {}
    local brazos = GetPedDrawableVariation(ped, 3)
    local g = mem.guantes
    -- Primero lo guardado: el 185 (hombre) es a la vez brazo con y sin guantes.
    if g and brazos == g.sin then return 'poner' end
    if tabla[brazos] ~= nil then return 'quitar', tabla[brazos] end
    return nil
end

local function ToggleGuantes(ped, sexo)
    local mem = Memoria(ped)
    local que, sin = Guantes(ped, sexo, mem)
    local emote = Config.Clothings.Drawables.Gloves and Config.Clothings.Drawables.Gloves.Emote
    if que == 'quitar' then
        PlayToggleEmote(emote, function()
            mem.guantes = {
                d = GetPedDrawableVariation(ped, 3), t = GetPedTextureVariation(ped, 3),
                p = GetPedPaletteVariation(ped, 3), sin = sin,
            }
            SetPedComponentVariation(ped, 3, sin, 0, 0)
        end)
        return true
    elseif que == 'poner' then
        local g = mem.guantes
        PlayToggleEmote(emote, function()
            SetPedComponentVariation(ped, 3, g.d, g.t, g.p)
            mem.guantes = nil
        end)
        return true
    end
    Bridge.Notify(locale:t('notify.nothingtotakeaway'))
    return false
end

function ToggleClothing(whic)
    local which = type(whic) == 'table' and tostring(whic.id) or whic
    if Cooldown then return false end

    local ped = PlayerPedId()
    local sexo = IsMpPed(ped)
    if sexo ~= 'Male' and sexo ~= 'Female' then
        Bridge.Notify(locale:t('notify.thispednotsupport'), 'error')
        return false
    end

    if which == 'Gloves' then return ToggleGuantes(ped, sexo) end

    local pieza = PIEZAS[which]
    local desnudo = Desnudo(sexo)
    if not pieza or not desnudo then return false end

    local mem = Memoria(ped)
    local cfg = Config.Clothings.Drawables[which]
    local emote = cfg and cfg.Emote

    if EstaPuesta(ped, pieza, desnudo) then
        PlayToggleEmote(emote, function()
            for _, c in ipairs(Todos(pieza)) do
                local d = GetPedDrawableVariation(ped, c)
                if desnudo[c] ~= nil and d ~= desnudo[c] then
                    mem.comp[c] = { d = d, t = GetPedTextureVariation(ped, c), p = GetPedPaletteVariation(ped, c) }
                    SetPedComponentVariation(ped, c, desnudo[c], 0, 0)
                end
            end
        end)
        return true
    end

    if not HayGuardado(mem, pieza) then
        Bridge.Notify(locale:t('notify.nothingtotakeaway'))
        return false
    end

    PlayToggleEmote(emote, function()
        for _, c in ipairs(Todos(pieza)) do
            local g = mem.comp[c]
            -- Solo donde sigue desnudo: si mientras tanto se puso otra cosa
            -- (una tienda, un atuendo), manda lo nuevo.
            if g and GetPedDrawableVariation(ped, c) == desnudo[c] then
                SetPedComponentVariation(ped, c, g.d, g.t, g.p)
            end
            mem.comp[c] = nil
        end
    end)
    return true
end

function ToggleProps(whic)
    local which = type(whic) == 'table' and tostring(whic.id) or whic
    if Cooldown then return false end
    local idx = PROPS[which]
    local cfg = Config.Clothings.Props[which]
    if not idx or not cfg then return false end

    local ped = PlayerPedId()
    local mem = Memoria(ped)
    local actual = GetPedPropIndex(ped, idx)

    if actual ~= -1 then
        PlayToggleEmote(cfg.Emote and cfg.Emote.Off, function()
            mem.prop[idx] = { d = actual, t = GetPedPropTextureIndex(ped, idx) }
            ClearPedProp(ped, idx)
        end)
        return true
    end

    local g = mem.prop[idx]
    if g then
        PlayToggleEmote(cfg.Emote and cfg.Emote.On, function()
            SetPedPropIndex(ped, idx, g.d, g.t, true)
            mem.prop[idx] = nil
        end)
        return true
    end

    Bridge.Notify(locale:t('notify.nothingtotakeaway'))
    return false
end

--[[ Lo que la pestaña Personaje necesita saber: que lleva puesto (con la misma
     regla que usan los botones) y que se puede volver a poner. Las claves son
     las de la pestaña (ArcadePersonaje.vue). ]]
local CLAVES = {
    masks = 'Mask', neck = 'Neck', decals = 'Decals', vest = 'Vest', bags = 'Bag',
    shoes = 'Shoes', legs = 'Pants', shirts = 'Shirt', jackets = 'Top', torsos = 'Torso',
}
local CLAVES_PROP = { hats = 'Hat', glasses = 'Glasses', watches = 'Watch' }

function EstadoRopa()
    local ped = PlayerPedId()
    local sexo = IsMpPed(ped)
    local desnudo = (sexo == 'Male' or sexo == 'Female') and Desnudo(sexo)
    if not desnudo then return nil end
    local mem = Memoria(ped)
    local puesta, recuperable = {}, {}

    for clave, which in pairs(CLAVES) do
        local pieza = PIEZAS[which]
        puesta[clave] = EstaPuesta(ped, pieza, desnudo)
        recuperable[clave] = not puesta[clave] and HayGuardado(mem, pieza)
    end
    for clave, which in pairs(CLAVES_PROP) do
        local idx = PROPS[which]
        puesta[clave] = GetPedPropIndex(ped, idx) ~= -1
        recuperable[clave] = not puesta[clave] and mem.prop[idx] ~= nil
    end
    local g = Guantes(ped, sexo, mem)
    puesta.guantes = g == 'quitar'
    recuperable.guantes = g == 'poner'
    return puesta, recuperable
end

--- Al salir del personaje: devolverle lo que se quito, para que no se guarde
--- asi ni le llegue al siguiente.
function ResetClothesToDefault()
    local ped = PlayerPedId()
    if real_hair then
        SetPedComponentVariation(ped, 2, real_hair, 0, 0)
        SetPedHairColor(ped, real_hair_txt, real_hair_txt2)
        real_hair = false
        real_hair_txt = false
        real_hair_txt2 = false
    end

    if Guardado.modelo == GetEntityModel(ped) then
        local desnudo = Desnudo(IsMpPed(ped)) or {}
        for c, g in pairs(Guardado.comp) do
            if GetPedDrawableVariation(ped, c) == desnudo[c] then
                SetPedComponentVariation(ped, c, g.d, g.t, g.p)
            end
        end
        for idx, g in pairs(Guardado.prop) do
            if GetPedPropIndex(ped, idx) == -1 then SetPedPropIndex(ped, idx, g.d, g.t, true) end
        end
        local gl = Guardado.guantes
        if gl and GetPedDrawableVariation(ped, 3) == gl.sin then
            SetPedComponentVariation(ped, 3, gl.d, gl.t, gl.p)
        end
    end
    Guardado = { modelo = nil, comp = {}, prop = {}, guantes = nil }
    Cooldown = false
end

RegisterCommand('rest_clothing', function( source, args, rawCommand) 
    SetPedComponentVariation(PlayerPedId(), tonumber(args[1]), tonumber(args[2]) or 0, tonumber(args[3]) or 0,0)
end)
