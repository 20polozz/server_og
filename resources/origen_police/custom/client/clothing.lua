function GetCurrentPedAppearance()
    local ped = PlayerPedId()
    if Config.Clothing == "illenium-appearance" then
        return exports["illenium-appearance"]:getPedAppearance(ped)
    elseif Config.Clothing == "fivem-appearance" then
        return exports["fivem-appearance"]:getPedAppearance(ped)
    elseif Config.Clothing == "origen_clothing" then
        return exports["origen_clothing"]:GetAppearanceData(ped)
    elseif Config.Clothing == "qb-clothing" then
        return exports["qb-clothing"]:GetSkinData()
    end
    return nil
end

function ApplyPedAppearance(appearance)
    local ped = PlayerPedId()
    if not appearance then return end
    if type(appearance) == "string" then
        appearance = json.decode(appearance)
    end
    
    if Config.Clothing == "illenium-appearance" or Config.Clothing == "fivem-appearance" then
        local current = nil
        if Config.Clothing == "illenium-appearance" then
            current = exports["illenium-appearance"]:getPedAppearance(ped)
        elseif Config.Clothing == "fivem-appearance" then
            current = exports["fivem-appearance"]:getPedAppearance(ped)
        end
        
        if current then
            -- Override specific components: 1 (Mask), 3 (Arms), 4 (Pants), 5 (Bags), 6 (Shoes), 7 (Neck), 8 (Undershirt), 9 (Vest), 10 (Decals), 11 (Jacket)
            local allowedComponents = { [1] = true, [3] = true, [4] = true, [5] = true, [6] = true, [7] = true, [8] = true, [9] = true, [10] = true, [11] = true }
            if appearance.components and current.components then
                for _, comp in ipairs(appearance.components) do
                    if allowedComponents[comp.component_id] then
                        for _, currComp in ipairs(current.components) do
                            if currComp.component_id == comp.component_id then
                                currComp.drawable = comp.drawable
                                currComp.texture = comp.texture
                                break
                            end
                        end
                    end
                end
            end

            -- Override specific props: 0 (Hat), 1 (Glasses)
            local allowedProps = { [0] = true, [1] = true }
            if appearance.props and current.props then
                for _, prop in ipairs(appearance.props) do
                    if allowedProps[prop.prop_id] then
                        for _, currProp in ipairs(current.props) do
                            if currProp.prop_id == prop.prop_id then
                                currProp.drawable = prop.drawable
                                currProp.texture = prop.texture
                                break
                            end
                        end
                    end
                end
            end
            
            -- Apply merged appearance
            if Config.Clothing == "illenium-appearance" then
                exports["illenium-appearance"]:setPedAppearance(ped, current)
                TriggerServerEvent("illenium-appearance:server:saveAppearance", current)
            elseif Config.Clothing == "fivem-appearance" then
                exports["fivem-appearance"]:setPedAppearance(ped, current)
                TriggerServerEvent("fivem-appearance:server:saveAppearance", current)
            end
        end
    elseif Config.Clothing == "origen_clothing" then
        local current = exports["origen_clothing"]:GetAppearanceData(ped)
        if current then
            -- Override specific drawables: masks, torsos, legs, shoes, shirts, vest, jackets, bags, neck, decals
            if appearance.drawables and current.drawables then
                local allowedDrawables = { ["masks"] = true, ["torsos"] = true, ["legs"] = true, ["shoes"] = true, ["shirts"] = true, ["vest"] = true, ["jackets"] = true, ["bags"] = true, ["neck"] = true, ["decals"] = true }
                for k, v in pairs(appearance.drawables) do
                    if allowedDrawables[k] then
                        current.drawables[k] = v
                    end
                end
            end

            -- Override specific props: glasses, hats
            if appearance.props and current.props then
                local allowedProps = { ["glasses"] = true, ["hats"] = true }
                for k, v in pairs(appearance.props) do
                    if allowedProps[k] then
                        current.props[k] = v
                    end
                end
            end

            exports["origen_clothing"]:SetAppearance(ped, current)
            lib.callback.await("origen_clothing:saveAppearance", false, current)
        end
    elseif Config.Clothing == "qb-clothing" then
        local current = exports["qb-clothing"]:GetSkinData()
        if current then
            local keys = { "mask", "arms", "pants", "shoes", "undershirt", "vest", "torso2", "hat", "glass", "bag", "accessory", "decals" }
            for _, key in ipairs(keys) do
                if appearance[key] then
                    current[key] = appearance[key]
                end
            end
            TriggerEvent("qb-clothing:client:loadOutfit", { outfitData = current })
            TriggerServerEvent("qb-clothing:saveSkin", current)
        end
    end
end

function OpenClothing(stationName)
    local gender = GetGender()
    FW_TriggerCallback("origen_police:callback:getOutfitsForPlayers", function(dbOutfits)
        local menu = {
            {
                header = "Vestuario de la Estación",
                isMenuHeader = true
            }
        }
        
        if dbOutfits and #dbOutfits > 0 then
            table.insert(menu, {
                header = "Conjuntos Preestablecidos",
                txt = "Elegir un conjunto diseñado por el administrador",
                params = {
                    isAction = true,
                    event = function()
                        local outfitSubmenu = {
                            {
                                header = "Seleccionar Conjunto",
                                isMenuHeader = true
                            }
                        }
                        for _, outfit in ipairs(dbOutfits) do
                            table.insert(outfitSubmenu, {
                                header = outfit.name,
                                txt = "Ponerse este conjunto",
                                params = {
                                    isAction = true,
                                    event = function()
                                        ApplyPedAppearance(outfit.data)
                                        ShowNotification("Te has puesto el conjunto: " .. outfit.name, "success")
                                    end
                                }
                            })
                        end
                        table.insert(outfitSubmenu, {
                            header = "Atrás",
                            params = {
                                isAction = true,
                                event = function()
                                    OpenClothing(stationName)
                                end
                            }
                        })
                        OpenMenu(outfitSubmenu)
                    end
                }
            })
        end

        table.insert(menu, {
            header = "Vestuario Estándar",
            txt = "Abrir vestuario del departamento",
            params = {
                isAction = true,
                event = function()
                    OpenStandardClothing(stationName)
                end
            }
        })

        --[[ Los atuendos personales (los que guarda origen_clothing por
             personaje). Antes el vestuario de la comisaria solo daba los del
             trabajo y para ponerse la ropa propia habia que ir a una tienda
             o a casa. Ponerlos lo valida origen_clothing en su servidor
             (dueño del atuendo), igual que desde casa. ]]
        if Config.Clothing == "origen_clothing" then
            table.insert(menu, {
                header = "Mis atuendos",
                txt = "Ponerte uno de tus atuendos guardados",
                params = {
                    isAction = true,
                    event = function()
                        exports["origen_clothing"]:openOutfitMenu(false)
                    end
                }
            })
        end

        table.insert(menu, {
            header = "Cerrar",
            params = {
                isAction = true,
                event = function()
                end
            }
        })

        OpenMenu(menu)
    end, gender)
end

function OpenStandardClothing(stationName)
    if Config.Clothing == "illenium-appearance" or Config.Clothing == "fivem-appearance" then
        local Player = FW_GetPlayerData(false)
        local retval = {}
        for _, v in pairs(Config.Outfits[GetGender()]) do
            if v.grades == nil then
                table.insert(retval, v)
            else
                local canBeAdded1 = false
                local canBeAdded2 = false
                local canBeAdded3 = false
                for _, u in pairs(v.grades) do
                    if u == Player.job.grade.level then
                        canBeAdded1 = true
                    end
                end
                for _, u in pairs(v.job) do
                    if u == Player.job.name then
                        canBeAdded2 = true
                    end
                end
                for _, u in pairs(v.maps) do
                    if u == stationName then
                        canBeAdded3 = true
                    end
                end
                if canBeAdded1 and canBeAdded2 and canBeAdded3 then
                    table.insert(retval, v)
                end
            end
        end
        if #retval == 0 then
            Debuger("No outfits available for job: "..Player.job.name..", grade: "..Player.job.grade.level.." and map: "..stationName..".")
            Debuger("To fix this, add an outfit to the config file with the correct job, grade and map.")
            return
        end
        TriggerEvent(Config.Clothing..":client:openJobOutfitsMenu", retval)
    elseif Config.Clothing == "qb-clothing" then
        local Player = FW_GetPlayerData(false)
        exports["qb-clothing"]:getOutfits(Player.job.grade.level, Config.Outfits)
    elseif Config.Clothing == "codem-appearance" then
        exports['codem-appearance']:OpenMenu("job")
    elseif Config.Clothing == "tgiann-clothing" then
        exports["tgiann-clothing"]:OpenJobOutiftMenu("police1")
    elseif Config.Clothing == "dx_clothing" then
        exports['dx_clothing']:openJobsOutfitMenu(false)
    elseif Config.Clothing == "rcore_clothing" then
        TriggerEvent('rcore_clothing:openJobChangingRoom', 'police', {
            label = 'Police Clothing',
            pos = GetEntityCoords(PlayerPedId())
        })
    elseif Config.Clothing == "origen_clothing" then
        exports["origen_clothing"]:openOutfitMenu(true)
    else
        print("No supported clothing found.")
    end
end

function SetCriminalClothes(gender, PlayerData)
    if gender then
        local ped = PlayerPedId()
        if type(PlayerData.metadata.criminalclothe) == "table" then
            if Config.Clothing == "qb-clothing" then
                TriggerEvent("qb-clothing:client:loadOutfit", {
                    outfitData = PlayerData.metadata.criminalclothe
                })
            elseif Config.Clothing == "illenium-appearance" then
                exports["illenium-appearance"]:setPedAppearance(ped, PlayerData.metadata.criminalclothe)
            elseif Config.Clothing == "fivem-appearance" then
                exports["fivem-appearance"]:setPedAppearance(ped, PlayerData.metadata.criminalclothe)
            elseif Config.Clothing == "origen_clothing" then
                exports["origen_clothing"]:SetAppearance(ped, PlayerData.metadata.criminalclothe)
            end
            TriggerServerEvent("origen_police:SetMetaData", "criminalclothe", 0)
            ShowNotification(Config.Translations.ChangedCloth)
        else
            if Public.CriminalClothe and Public.CriminalClothe[gender] then
                if Config.Clothing == "qb-clothing" then
                    local skin = {}
                    local success, _ = pcall(function()
                        skin = exports["qb-clothing"]:GetSkinData()
                    end)
                    if not success then
                        return Debuger("[^1ERROR^0] The export (GetSkinData) does not exist in your qb-clothing resource.")
                    end
                    TriggerServerEvent("origen_police:SetMetaData", "criminalclothe", skin)
                    TriggerEvent("qb-clothing:client:loadOutfit", {
                        outfitData = Public.CriminalClothe[gender]
                    })
                elseif Config.Clothing == "illenium-appearance" then
                    TriggerServerEvent("origen_police:SetMetaData", "criminalclothe", exports["illenium-appearance"]:getPedAppearance(ped))
                    exports["illenium-appearance"]:setPedAppearance(ped, Public.CriminalClothe[gender])
                elseif Config.Clothing == "fivem-appearance" then
                    TriggerServerEvent("origen_police:SetMetaData", "criminalclothe", exports["fivem-appearance"]:getPedAppearance(ped))
                    exports["fivem-appearance"]:setPedAppearance(ped, Public.CriminalClothe[gender])
                elseif Config.Clothing == "origen_clothing" then
                    TriggerServerEvent("origen_police:SetMetaData", "criminalclothe", exports["origen_clothing"]:GetAppearanceData(ped))
                    exports["origen_clothing"]:SetAppearance(ped, Public.CriminalClothe[gender])
                end

                ShowNotification(Config.Translations.ChangedCloth)
            else
                ShowNotification(Config.Translations.NoFederalClothAvailable)
            end
        end
    else
        ShowNotification(Config.Translations.PedCantChangeCloth)
    end
end

-- -------------------------------------------------------
-- ROPA DE PACIENTE — funciona igual que criminal clothes
-- pero usa Public.PatientClothe y la meta "patientclothe"
-- -------------------------------------------------------
function SetPatientClothes(gender, PlayerData)
    if gender then
        local ped = PlayerPedId()
        if type(PlayerData.metadata.patientclothe) == "table" then
            if Config.Clothing == "qb-clothing" then
                TriggerEvent("qb-clothing:client:loadOutfit", {
                    outfitData = PlayerData.metadata.patientclothe
                })
            elseif Config.Clothing == "illenium-appearance" then
                exports["illenium-appearance"]:setPedAppearance(ped, PlayerData.metadata.patientclothe)
            elseif Config.Clothing == "fivem-appearance" then
                exports["fivem-appearance"]:setPedAppearance(ped, PlayerData.metadata.patientclothe)
            elseif Config.Clothing == "origen_clothing" then
                exports["origen_clothing"]:SetAppearance(ped, PlayerData.metadata.patientclothe)
            end
            TriggerServerEvent("origen_police:SetMetaData", "patientclothe", 0)
            ShowNotification(Config.Translations.ChangedCloth)
        else
            if Public.PatientClothe and Public.PatientClothe[gender] then
                if Config.Clothing == "qb-clothing" then
                    local skin = {}
                    local success, _ = pcall(function()
                        skin = exports["qb-clothing"]:GetSkinData()
                    end)
                    if not success then
                        return Debuger("[^1ERROR^0] The export (GetSkinData) does not exist in your qb-clothing resource.")
                    end
                    TriggerServerEvent("origen_police:SetMetaData", "patientclothe", skin)
                    TriggerEvent("qb-clothing:client:loadOutfit", {
                        outfitData = Public.PatientClothe[gender]
                    })
                elseif Config.Clothing == "illenium-appearance" then
                    TriggerServerEvent("origen_police:SetMetaData", "patientclothe", exports["illenium-appearance"]:getPedAppearance(ped))
                    exports["illenium-appearance"]:setPedAppearance(ped, Public.PatientClothe[gender])
                elseif Config.Clothing == "fivem-appearance" then
                    TriggerServerEvent("origen_police:SetMetaData", "patientclothe", exports["fivem-appearance"]:getPedAppearance(ped))
                    exports["fivem-appearance"]:setPedAppearance(ped, Public.PatientClothe[gender])
                elseif Config.Clothing == "origen_clothing" then
                    TriggerServerEvent("origen_police:SetMetaData", "patientclothe", exports["origen_clothing"]:GetAppearanceData(ped))
                    exports["origen_clothing"]:SetAppearance(ped, Public.PatientClothe[gender])
                end

                ShowNotification(Config.Translations.ChangedCloth)
            else
                ShowNotification(Config.Translations.NoFederalClothAvailable)
            end
        end
    else
        ShowNotification(Config.Translations.PedCantChangeCloth)
    end
end

RegisterCommand("getropa", function()
    local ped = PlayerPedId()
    local data = ""
    if Config.Clothing == "qb-clothing" then
        data = json.encode(exports["qb-clothing"]:GetSkinData(), {indent = true})
    elseif Config.Clothing == "illenium-appearance" then
        data = json.encode(exports["illenium-appearance"]:getPedAppearance(ped), {indent = true})
    elseif Config.Clothing == "fivem-appearance" then
        data = json.encode(exports["fivem-appearance"]:getPedAppearance(ped), {indent = true})
    elseif Config.Clothing == "origen_clothing" then
        data = json.encode(exports["origen_clothing"]:GetAppearanceData(ped), {indent = true})
    end
    print("^2[ROPA ACTUAL]^0\n" .. data)
    TriggerEvent('chat:addMessage', {
        color = {0, 255, 0},
        multiline = true,
        args = {"Sistema", "Ropa impresa en F8 (consola). Abre F8 para copiarla."}
    })
end)