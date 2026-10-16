function GetPedModel(ped)
    local model = GetEntityModel(ped)
    return Config.Peds[model] or model
end

function GetHeadBlendData(ped)
    local args = {
        0x2746BD9D88C5C5D0, -- GetPedHeadBlendData
        ped
    }
    for _, v in ipairs(AppearanceData.headBlend) do
        local mathType = math.type(v.value)
        if mathType == 'integer' then
            args[#args + 1] = Citizen.PointerValueIntInitialized(0)
        elseif mathType == 'float' then
            args[#args + 1] = Citizen.PointerValueFloatInitialized(0)
        else
            debugger("Unknown type for headBlend: " .. v.index .. " = " .. mathType)
        end
    end

    local headBlend, retval = {Citizen.InvokeNative(table.unpack(args))}, {}

    for _, v in ipairs(AppearanceData.headBlend) do
        if math.type(v.value) == "float" then
            retval[v.index] = headBlend[_] > 1 and 1 or tonumber(string.sub(headBlend[_], 0, 4))
        else
            retval[v.index] = headBlend[_]
        end
    end

    return retval
end

function SetHeadBlendData(ped, headBlendData)
    if not ped or not headBlendData then return end
    local args = {
        0x9414E18B9434C2FE, -- SetPedHeadBlendData
        ped,
        headBlendData.shapeFirst,
        headBlendData.shapeSecond,
        headBlendData.shapeThird,
        headBlendData.skinFirst,
        headBlendData.skinSecond,
        headBlendData.skinThird,
        headBlendData.shapeMix,
        headBlendData.skinMix,
        headBlendData.thirdMix
    }
    Citizen.InvokeNative(table.unpack(args))
end

function GetPedFaceFeatures(ped)
    local retval = {}
    for k, v in pairs(AppearanceData.headStructure) do
        retval[k] = GetPedFaceFeature(ped, v.index)
    end
    return retval
end

function SetPedFaceFeatures(ped, faceFeatures)
    if not ped or not faceFeatures then return end
    for k, v in pairs(AppearanceData.headStructure) do
        if not faceFeatures[k] then
            goto continue
        end
        SetPedFaceFeature(ped, v.index, faceFeatures[k] + 0.0)
        ::continue::
    end
end

function GetPedHeadOverlays(ped)
    local retval = {}
    for k, v in pairs(AppearanceData.headOverlay) do
        local _, overlayValue, colourType, firstColour, secondColour, overlayOpacity = GetPedHeadOverlayData(ped, v.index)
        if overlayValue == 255 then
            overlayValue = 0
            overlayOpacity = 0.0
        end
        retval[k] = {
            overlayValue = overlayValue,
            colourType = colourType,
            firstColor = firstColour,
            secondColor = secondColour,
            overlayOpacity = overlayOpacity
        }
    end
    return retval
end

function SetHeadOverlays(ped, headOverlays)
    if not ped or not headOverlays then return end
    for k, v in pairs(AppearanceData.headOverlay) do
        local overlay = headOverlays[k]
        if not overlay then
            goto continue
        end
        SetPedHeadOverlay(ped, v.index, overlay.overlayValue, overlay.overlayOpacity + 0.0)
        SetPedHeadOverlayColor(ped, v.index, overlay.colourType, overlay.firstColor, overlay.secondColor)
        ::continue::
    end
end

function GetPedHairTint(ped)
    return {
        colorIndex = GetPedHairColor(ped),
        highlightColorIndex = GetPedHairHighlightColor(ped)
    }
end

-- We don't call SetPedHairTint cause it already exist as a native
function SetHairTint(ped, hairData)
    if not ped or not hairData then return end
    SetPedHairColor(ped, hairData.colorIndex, hairData.highlightColorIndex)
end

function GetPedDrawables(ped)
    local retval = {}
    for k, v in pairs(AppearanceData.drawables) do
        retval[k] = {
            drawable = GetPedDrawableVariation(ped, v.index),
            texture = GetPedTextureVariation(ped, v.index)
        }
    end
    return retval
end

exports("GetPedDrawables", GetPedDrawables)

function GetPedDrawableHash(ped, category)
    local v = AppearanceData.drawables[category]
    if not v then return nil end

    local data = {
        collection = GetPedDrawableVariationCollectionName(ped, v.index) == '' and 'none' or GetPedDrawableVariationCollectionName(ped, v.index),
        componentid = v.index,
        drawableid = GetPedDrawableVariationCollectionLocalIndex(ped, v.index),
        texture_id = GetPedTextureVariation(ped, v.index),
    }

    return ('%s--%s--%s--%s'):format(data.collection, data.componentid, data.drawableid, data.texture_id)
end

--[[ Hash (coleccion--componente--indice local--textura) de la prenda que
     ocupa un numero global en ESTE cliente. El numero global depende del
     orden en que el juego cargo las colecciones, y el que se guardo en la
     base al importar un pack con el servidor en marcha puede no coincidir
     (04/10: ropafaccionorigen quedo en 789-804 y en el juego iba en
     1759-1774, asi que el menu no encontraba la prenda y no la aplicaba).
     El hash no depende del orden. Se pone un instante en el ped de la camara
     y se deja como estaba dentro del mismo tick, sin que llegue a dibujarse.
     Si el juego no acepta el numero (o la textura) devuelve nil y el
     servidor busca por numero global como siempre. ]]
function HashDeNumeroGlobal(ped, category, global, texture)
    global, texture = tonumber(global), tonumber(texture) or 0
    if not global or global < 0 then return nil end

    local v = AppearanceData.drawables[category]
    if v then
        local d, t, pal = GetPedDrawableVariation(ped, v.index), GetPedTextureVariation(ped, v.index), GetPedPaletteVariation(ped, v.index)
        SetPedComponentVariation(ped, v.index, global, texture, pal)
        local hash = GetPedDrawableVariation(ped, v.index) == global and GetPedDrawableHash(ped, category) or nil
        SetPedComponentVariation(ped, v.index, d, t, pal)
        return hash
    end

    v = AppearanceData.props[category]
    if not v then return nil end
    local d, t = GetPedPropIndex(ped, v.index), GetPedPropTextureIndex(ped, v.index)
    SetPedPropIndex(ped, v.index, global, texture, true)
    local hash = GetPedPropIndex(ped, v.index) == global and GetPedPropHash(ped, category, true) or nil
    if d == -1 then ClearPedProp(ped, v.index) else SetPedPropIndex(ped, v.index, d, t, true) end
    return hash
end

function GetPedDrawablesHash(ped, ignore, onlyApplied)
    local retval = {}
    for k, v in pairs(AppearanceData.drawables) do
        if ignore and ignore[k] then
            debugger("Ignore drawable hash: ", k)
            goto skip
        end

        if k == 'hair' then
            retval[k] = {
                drawable = GetPedDrawableVariation(ped, 2),
                texture = GetPedTextureVariation(ped, 2)
            }
            goto skip
        end

        local data = {
            collection = GetPedDrawableVariationCollectionName(ped, v.index) == '' and 'none' or GetPedDrawableVariationCollectionName(ped, v.index),
            componentid = v.index,
            drawableid = GetPedDrawableVariationCollectionLocalIndex(ped, v.index),
            texture_id = GetPedTextureVariation(ped, v.index),
        }

        local hash = ('%s--%s--%s--%s'):format(data.collection, data.componentid, data.drawableid, data.texture_id)

        if hash == exports.origen_clothing:GetRemoveHash(GetEntityModel(ped), k) then
            if onlyApplied then
                goto skip
            end
        end

        retval[k] = hash
        ::skip::
    end
    return retval
end

function SetPedDrawables(ped, drawables, ignoreDrawables)
    if not ped then return end
    if not drawables then
        -- Initialize at least 1 drawable to make peds visible
        SetPedComponentVariation(ped, AppearanceData.drawables.masks.index, 0, 0, 0)
        return
    end
    for k, v in pairs(AppearanceData.drawables) do
        local drawable = drawables[k]
        if ignoreDrawables and ignoreDrawables[k] then
            debugger("Ignore drawable: ", k)
            goto skip
        end
        if not drawable then
            debugger("Unknown drawable: ", k)
            goto skip
        end
        SetPedComponentVariation(ped, v.index, drawable.drawable, drawable.texture, 0)
        ::skip::
    end
end

--[[ ¿Tiene el juego esa prenda?

     Antes cualquier prenda guardada se aplicaba a ciegas con
     SetPedCollection*. Si la coleccion no esta cargada —un pack de ropa que no
     arranca, como koja_lspd_v2.5 desde el 12/10 por perder el entitlement—,
     el juego recibia una coleccion que no existe. El 15/10 habia 84 personajes
     con koja puesto y 730 outfits que lo usaban.

     Ahora se le pregunta al juego cuantas prendas tiene esa coleccion en ese
     hueco y, si no llega, esa pieza se salta y el resto del conjunto se pone
     normal. No se borra nada de la base de datos: si el pack vuelve, la ropa
     vuelve sola.

     Solo se miran colecciones addon. La base ('' o 'none') existe siempre, y
     un drawable negativo en un prop significa "quitarlo", que es valido. ]]
local coleccionesAvisadas = {}

function PrendaExiste(ped, itemData)
    local coleccion = itemData.collection
    if coleccion == nil or coleccion == '' or coleccion == 'none' then return true end

    local drawable = itemData.drawable_id
    if type(drawable) ~= 'number' or drawable < 0 then return true end

    local total
    if itemData.anchor then
        total = GetNumberOfPedCollectionPropDrawableVariations(ped, itemData.anchor, coleccion)
    else
        total = GetNumberOfPedCollectionDrawableVariations(ped, itemData.component_id, coleccion)
    end

    if (total or 0) > drawable then return true end

    -- Una vez por coleccion y sesion, para que se vea en la F8 sin inundarla.
    if not coleccionesAvisadas[coleccion] then
        coleccionesAvisadas[coleccion] = true
        print(('^3[origen_clothing]^0 Prenda saltada: la coleccion "%s" no esta cargada o no tiene el drawable %d (hueco %s). Se ignoran sus piezas.')
            :format(coleccion, drawable, tostring(itemData.anchor and ('prop ' .. itemData.anchor) or itemData.component_id)))
    end

    return false
end

function SetPedDrawableByHash(ped, hash, forceSave)
    local itemData = parseItemHash(hash)

    itemData.collection = itemData.collection == 'none' and '' or itemData.collection

    -- Sin guardar tampoco: guardar ahora escribiria encima la prenda que no
    -- se ha podido poner, y se perderia del armario.
    if not PrendaExiste(ped, itemData) then return end

    SetPedCollectionComponentVariation(ped, itemData.component_id, itemData.collection, itemData.drawable_id, itemData.texture_id)

    if forceSave then SaveAppearance() end
end

exports("SetPedDrawableByHash", SetPedDrawableByHash)

function SetPedDrawablesByHash(ped, hashes)
    if not hashes then return end
    for k, hash in pairs(hashes) do 
        if k == 'hair' then
            SetPedComponentVariation(ped, 2, hash.drawable, hash.texture, 0)
            goto continue
        end

        local itemData = parseItemHash(hash)

        itemData.collection = itemData.collection == 'none' and '' or itemData.collection

        if not PrendaExiste(ped, itemData) then goto continue end

        SetPedCollectionComponentVariation(ped, itemData.component_id, itemData.collection, itemData.drawable_id, itemData.texture_id)
        ::continue::
    end
end

function RemoveClothing(ped, category, forceSave)
    local removeData = Config.RemoveItem[GetEntityModel(ped)]
    if not removeData then return end

    local hash = removeData[category]
    if not hash then return end

    if IsProp(category) then
        ClearPedProp(ped, AppearanceData.props[category].index)
        if forceSave then SaveAppearance() end
        return
    end

    SetPedDrawableByHash(ped, hash, forceSave)
end

exports("RemoveClothing", RemoveClothing)

function GetPedProps(ped)
    local retval = {}
    for k, v in pairs(AppearanceData.props) do
        retval[k] = {
            drawable = GetPedPropIndex(ped, v.index),
            texture = GetPedPropTextureIndex(ped, v.index)
        }
    end
    return retval
end

function GetPedPropHash(ped, category, thousand)
    local v = AppearanceData.props[category]
    if not v then return nil end

    local data = {
        collection = (GetPedPropCollectionName(ped, v.index) == '' or GetPedPropCollectionName(ped, v.index) == nil) and 'none' or GetPedPropCollectionName(ped, v.index),
        componentid = v.index,
        drawableid = GetPedPropCollectionLocalIndex(ped, v.index),
        texture_id = GetPedPropTextureIndex(ped, v.index)
    }

    if thousand then
        data.componentid = data.componentid + 1000
    end

    return ('%s--%s--%s--%s'):format(data.collection, data.componentid, data.drawableid, data.texture_id)
end

function GetPedPropsHash(ped, thousand, only)
    local retval = {}
    for k, v in pairs(AppearanceData.props) do
        local data = {
            collection = (GetPedPropCollectionName(ped, v.index) == '' or GetPedPropCollectionName(ped, v.index) == nil) and 'none' or GetPedPropCollectionName(ped, v.index),
            -- componentid = thousand and v.index + 1000 or v.index,
            componentid = v.index + 1000,
            drawableid = GetPedPropCollectionLocalIndex(ped, v.index),
            texture_id = GetPedPropTextureIndex(ped, v.index)
        }

        local hash = ('%s--%s--%s--%s'):format(data.collection, data.componentid, data.drawableid, data.texture_id)

        if hash == exports.origen_clothing:GetRemoveHash(GetEntityModel(ped), k) then
            if only then
                goto skip
            end
        end

        retval[k] = hash
        ::skip::
    end
    return retval
end

function GetPedAllHashes(ped, thousand, onlyApplied)
    local drawables = GetPedDrawablesHash(ped, nil, onlyApplied) or {}
    local props = GetPedPropsHash(ped, thousand, onlyApplied) or {}
    for k, v in pairs(props) do drawables[k] = v end
    return drawables
end

function SetPedProps(ped, props)
    if not ped or not props then return end
    for k, v in pairs(AppearanceData.props) do
        local prop = props[k]
        if prop.drawable  == -1 then
            ClearPedProp(ped, v.index)
            goto continue
        end
        SetPedPropIndex(ped, v.index, prop.drawable, prop.texture, true)
        ::continue::
    end
end

function SetPedPropByHash(ped, hash, forceSave)
    local itemData = parseItemHash(hash)

    if itemData.drawable_id == -1 then
        ClearPedProp(ped, itemData.anchor)
        return
    end

    itemData.collection = itemData.collection == 'none' and '' or itemData.collection

    if not PrendaExiste(ped, itemData) then return end

    SetPedCollectionPropIndex(ped, itemData.anchor or itemData.component_id, itemData.collection, itemData.drawable_id, itemData.texture_id)

    if forceSave then SaveAppearance() end
end

exports("SetPedPropByHash", SetPedPropByHash)

function SetPedPropsByHash(ped, hashes)
    if not hashes then return end
    for k, hash in pairs(hashes) do
        local itemData = parseItemHash(hash)        

        if itemData.drawable_id == -1 then
            ClearPedProp(ped, itemData.anchor)
            goto continue
        end

        itemData.collection = itemData.collection == 'none' and '' or itemData.collection

        if not PrendaExiste(ped, itemData) then goto continue end

        SetPedCollectionPropIndex(ped, itemData.anchor, itemData.collection, itemData.drawable_id, itemData.texture_id)
        ::continue::
    end
end

function Clamp(value, min, max)
    return math.max(min, math.min(max, value))
end

function GetPedGender(ped)
    return GetEntityModel(ped) == `mp_m_freemode_01` and 0
        or GetEntityModel(ped) == `mp_f_freemode_01` and 1
        or 2 -- Custom peds are considered as 'Other'
end

function IsProp(category)
    return TableContains(AppearanceData.props, category, function(v)
        return v.id
    end)
end

function GetEntityModelName(model)
    return Config.Peds[model] or model
end

function DisableControls(controls, cursor)
    if not controls then return end

    for i = 1, #controls do
        DisableControlAction(2, controls[i], true)
    end
    DisablePlayerFiring(PlayerId(), true)

    if cursor then
        SetMouseCursorActiveThisFrame()
    end
end

local function RotationToDirection(rotation)
    local x = rotation.x * math.pi / 180.0
    local z = rotation.z * math.pi / 180.0
    local num = math.abs(math.cos(x))
    return vector3((-math.sin(z) * num), (math.cos(z) * num), math.sin(x))
end

local function RayCastGamePlayCamera(distance, camCoords, camRot)
    local cameraRotation = camRot or GetGameplayCamRot()
    local cameraCoord = camCoords or GetGameplayCamCoord()
    local direction = RotationToDirection(cameraRotation)
    local destination =
    {
        x = cameraCoord.x + direction.x * distance,
        y = cameraCoord.y + direction.y * distance,
        z = cameraCoord.z + direction.z * distance
    }
    local a, b, c, d, e = GetShapeTestResult(StartShapeTestRay(cameraCoord.x, cameraCoord.y, cameraCoord.z, destination.x, destination.y, destination.z, -1, PlayerPedId(), 0))
    return b, c, e
end

function GetScreenCoords(distance, camCoords, camRot)
	local hit, coords, entity = RayCastGamePlayCamera(distance or 1000.0, camCoords, camRot)
    return hit, coords, entity
end

function HandsUp()
    local dict = "random@mugging3"
    local anim = "handsup_standing_base"

    if IsEntityPlayingAnim(cache.ped, dict, anim, 3) then
        return ClearPedTasks(cache.ped)
    end

    lib.requestAnimDict(dict, 1000)
    TaskPlayAnim(cache.ped, dict, anim, 8.0, 8.0, -1, 50, 0, false, false, false)
end

local function getEquippedClothes()
    local skin = exports.origen_clothing:GetAppearanceData(cache.ped, true)
    local equipped = {}

    for k, v in pairs(skin.drawables) do
        equipped[k] = v
    end

    for k, v in pairs(skin.props) do
        equipped[k] = v
    end

    return equipped
end
exports("GetEquippedClothes", getEquippedClothes)