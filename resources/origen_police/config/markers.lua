Config.Maps = { -- YOU CAN USE THIS OPTION OR THE IN GAME MENU INSIDE THE POLICE TABLET
    -- PLACE YOUR STATION NAME HERE, Example: "default-gta"
}

Config.MarkersDraw = true -- Draw the markers on the map

-- DONT TOUCH BELOW;

MarkersList = {
    RepairVehicle = {
        sprite = 36,
        radius = 4.0,
        event = "origen_police:client:repairveh",
        text = "Reparar vehículo",
        rgba = {r = 0, g = 180, b = 255, a = 200}
    },
    VehicleFingerprints = {
        sprite = 36,
        scale = 0.25,
        drawDistance = 2.0,
        radius = 2.0,
        event = "origen_police:client:inspectVehicleFingerprints",
        text = "Inspeccionar huellas del vehículo",
        rgba = {r = 0, g = 0, b = 0, a = 255}
    },
    RequestVehicle = {
        sprite = 36,
        event = "origen_police:client:buyveh",
        text = "Solicitar vehículo",
        rgba = {r = 0, g = 0, b = 0, a = 255}
    },
    ModifyVehicle = {
        sprite = 36,
        radius = 5,
        event = "origen_police:client:modifyveh",
        text = "Modificar vehículo",
        rgba = {r = 0, g = 0, b = 0, a = 255}
    },
    SaveVehicle = {
        sprite = 36,
        radius = 3,
        event = "origen_police:client:deletevehicle",
        text = "Guardar vehículo",
        rgba = {r = 0, g = 0, b = 0, a = 255}
    },
    RequestBoat = {
        sprite = 35,
        event = "origen_police:client:boat",
        text = "Solicitar barco",
        rgba = {r = 0, g = 0, b = 0, a = 255}
    },
    SaveBoat = {
        sprite = 35,
        radius = 3,
        event = "origen_police:client:deletevehicle",
        text = "Guardar barco",
        rgba = {r = 0, g = 0, b = 0, a = 255}
    },
    SaveHelicopter = {
        sprite = 34,
        radius = 3,
        event = "origen_police:client:deletevehicle",
        text = "Guardar helicóptero",
        rgba = {r = 0, g = 0, b = 0, a = 255}
    },
    RequestHelicopter = {
        sprite = 34,
        event = "origen_police:client:helicop",
        text = "Solicitar helicóptero",
        rgba = {r = 0, g = 0, b = 0, a = 255}
    },
    DressingRoom = {
        sprite = 20,
        event = "origen_police:client:clothing",
        text = "Vestuario",
        rgba = {r = 0, g = 0, b = 0, a = 255}
    },
    Stash = {
        sprite = 20,
        event = "origen_police:client:stash",
        text = "Inventario Común",
        rgba = {r = 0, g = 0, b = 0, a = 255}
    },
    ["Inventory/Armoury"] = {
        sprite = 20,
        event = "origen_police:client:inventory",
        text = "Armería",
        rgba = {r = 0, g = 0, b = 0, a = 255}
    },
    ["Ambulance/Armoury"] = {
        sprite = 20,
        event = "origen_police:client:ambulance_inventory",
        text = "Armería y Taquilla",
        rgba = {r = 0, g = 0, b = 0, a = 255}
    },
    EvidenceReport = {
        sprite = 20,
        event = "origen_police:client:makereport",
        text = "Escribir Informe",
        rgba = {r = 0, g = 0, b = 0, a = 255}
    },
}

PublicMarkerList = {
    Duty = {
        sprite = 20,
        event = "origen_police:client:enterOnDuty",
        text = "Entrar en servicio",
        rgba = {r = 0, g = 0, b = 0, a = 255}
    },
    Finger = {
        sprite = 20,
        event = "origen_police:client:domyfinguer",
        text = "Colocar dedo en el lector",
        rgba = {r = 0, g = 0, b = 0, a = 255}
    },
    CriminalClothes = {
        sprite = 20,
        event = "origen_police:client:CriminalClothes",
        text = "Cambiar ropa",
        rgba = {r = 0, g = 0, b = 0, a = 255}
    },
    PatientClothes = {
        sprite = 20,
        event = "origen_police:client:PatientClothes",
        text = "Cambiar ropa (Paciente)",
        rgba = {r = 0, g = 0, b = 0, a = 255}
    },
    Pertenences = {
        sprite = 20,
        event = "origen_police:client:pertenences",
        text = "Dejar pertenencias",
        rgba = {r = 0, g = 0, b = 0, a = 255}
    },
    ConfiscatedVehicles = {
        sprite = 36,
        event = "origen_police:client:openConfiscatedMenu",
        text = "Vehículos confiscados",
        rgba = {r = 0, g = 0, b = 0, a = 255}
    },
}

Tables = {
    Markers = {

    }
}

Public = {
    Markers = {},
    CriminalClothe = {
        ["qb-clothing"] = {
            ["male"] = {
                ["hat"] = { item = -1, texture = 0},
                ["t-shirt"] = {
                    item = 15, texture = 0
                },
                ["torso2"] = {
                    item = 31, texture = 0
                },
                ["pants"] = {
                    item = 5, texture = 7
                },
                ["shoes"] = {
                    item = 56, texture = 1
                },
                ["arms"] = {
                    item = 12, texture = 0
                },
            }
        },
        ["illenium-appearance"] = {
            ["male"] = {
                model = "mp_m_freemode_01",
                components = {
                    {texture = 0, component_id = 0, drawable = 0},
                    {texture = 0, component_id = 1, drawable = 0},
                    {texture = 0, component_id = 2, drawable = 0},
                    {texture = 0, component_id = 3, drawable = 5},
                    {texture = 2, component_id = 4, drawable = 27},
                    {texture = 0, component_id = 5, drawable = 0},
                    {texture = 0, component_id = 6, drawable = 8},
                    {texture = 0, component_id = 7, drawable = 0},
                    {texture = 0, component_id = 8, drawable = 15},
                    {texture = 0, component_id = 9, drawable = 0},
                    {texture = 0, component_id = 10, drawable = 0},
                    {texture = 0, component_id = 11, drawable = 5}
                },
            }
        },
        ["origen_clothing"] = {
            ["male"] = {
                props = {
                    glasses = "none--1001---1---1",
                    bracelets = "none--1007---1---1",
                    earrings = "none--1002---1---1",
                    watches = "none--1006---1---1",
                    hats = "none--1000---1---1"
                },
                drawables = {
                    bags = "none--5--0--0",
                    torsos = "none--3--5--0",
                    masks = "none--1--0--0",
                    shoes = "none--6--8--0",
                    legs = "Male_freemode_hipster--4--1--2",
                    shirts = "none--8--15--0",
                    vest = "none--9--0--0",
                    jackets = "none--11--5--0",
                    neck = "none--7--0--0",
                    decals = "none--10--0--0"
                }
            },
            ["female"] = {
                props = {
                    glasses = "none--1001---1---1",
                    bracelets = "none--1007---1---1",
                    earrings = "none--1002---1---1",
                    watches = "none--1006---1---1",
                    hats = "none--1000---1---1"
                },
                drawables = {
                    bags = "none--5--0--0",
                    torsos = "none--3--4--0",
                    masks = "none--1--0--0",
                    shoes = "none--6--1--0",
                    legs = "mp_f_sum--4--1--10",
                    shirts = "none--8--15--0",
                    vest = "none--9--0--0",
                    jackets = "Female_freemode_valentines--11--2--0",
                    neck = "none--7--0--0",
                    decals = "none--10--0--0"
                }
            }
        },
    },
    -- -------------------------------------------------------
    -- ROPA DE PACIENTE (configurar independientemente)
    -- Misma estructura que CriminalClothe pero para pacientes
    -- -------------------------------------------------------
    PatientClothe = {
        ["qb-clothing"] = {
            ["male"] = {
                ["hat"] = { item = -1, texture = 0},
                ["t-shirt"] = {
                    item = 15, texture = 0  -- Cambia el número de ropa aquí
                },
                ["torso2"] = {
                    item = 31, texture = 0
                },
                ["pants"] = {
                    item = 5, texture = 7
                },
                ["shoes"] = {
                    item = 56, texture = 1
                },
                ["arms"] = {
                    item = 12, texture = 0
                },
            }
        },
        ["illenium-appearance"] = {
            ["male"] = {
                model = "mp_m_freemode_01",
                components = {
                    {texture = 0, component_id = 0, drawable = 0},
                    {texture = 0, component_id = 1, drawable = 0},
                    {texture = 0, component_id = 2, drawable = 0},
                    {texture = 0, component_id = 3, drawable = 5},
                    {texture = 2, component_id = 4, drawable = 27},  -- Cambia drawable/texture
                    {texture = 0, component_id = 5, drawable = 0},
                    {texture = 0, component_id = 6, drawable = 8},
                    {texture = 0, component_id = 7, drawable = 0},
                    {texture = 0, component_id = 8, drawable = 15},
                    {texture = 0, component_id = 9, drawable = 0},
                    {texture = 0, component_id = 10, drawable = 0},
                    {texture = 0, component_id = 11, drawable = 5}
                },
            }
        },
        ["origen_clothing"] = {
            ["male"] = {
                props = {
                    glasses = "none--1001--15--10",
                    bracelets = "none--1007---1---1",
                    earrings = "none--1002---1---1",
                    watches = "none--1006---1---1",
                    hats = "mp_m_origenclothestrendy_m_p_a--1000--18--1"
                },
                drawables = {
                    bags = "none--5--0--0",
                    torsos = "Male_Heist--3--74--0",
                    masks = "mp_m_origenclothestrendy_m_a--1--3--0",
                    shoes = "mp_m_christmas3--6--4--3",
                    legs = "Male_freemode_valentines--4--0--0",
                    shirts = "none--8--15--0",
                    vest = "none--9--0--0",
                    jackets = "mp_m_origenclothestrendy_m_a--11--25--2",
                    neck = "mp_m_origenclothestrendy_m_a--7--11--9",
                    decals = "none--10--0--0"
                }
            },
            ["female"] = {
                props = {
                    glasses = "none--1001--9--10",
                    bracelets = "none--1007---1---1",
                    earrings = "none--1002---1---1",
                    watches = "none--1006---1---1",
                    hats = "none--1000---1---1"
                },
                drawables = {
                    bags = "none--5--0--0",
                    torsos = "Female_Heist--3--81--0",
                    masks = "mp_f_origenclothestrendy_f_a--1--2--0",
                    shoes = "mp_f_christmas3--6--4--3",
                    legs = "Female_Heist--4--9--3",
                    shirts = "none--8--2--0",
                    vest = "none--9--0--0",
                    jackets = "mp_f_origenclothestrendy_f_a--11--13--1",
                    neck = "mp_f_origenclothestrendy_f_a--7--18--8",
                    decals = "none--10--0--0"
                }
            }
        },
    },
    Radars = {},
    Blips = {
        {
            coords = vector4(429.7668, -976.2729, 30.7057, 159.6318),
            sprite = 60,
            color = 0,
            name = "Comisaria de Mission Row",
            size = 0.8
        },
        {
            coords = vector4(2846.5, 4739.85, 48.63, 202.99),
            sprite = 60,
            color = 0,
            name = "Comisaria de Sandy Shores",
            size = 0.8
        },
        {
            coords = vector4(647.19, -7.91, 82.74, 37.78),
            sprite = 60,
            color = 40,
            name = "FIB",
            size = 0.8
        },
        {
            coords = vector4(1855.47, 2585.71, 45.67, 93.78),
            sprite = 188,
            color = 0,
            name = "Prision Federal",
            size = 0.8
        },
    },
    TrafficZones = {}
}

BillsNPCPositions = {}
DocumentsNPCPositions = {}
SpawnConfiscatedVehicles = {}
MapOptions = {}

function Shallowcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else
        copy = orig
    end
    return copy
end

function LoadMarkers()
    Debuger("Loading markers for " .. #Config.Maps .. " maps")
    -- Se rellena desde cero en cada carga: sin vaciarla, cada recarga sumaba
    -- otra vez las mismas posiciones y el agente de la comisaría salía repetido.
    for i = #BillsNPCPositions, 1, -1 do BillsNPCPositions[i] = nil end
    for i = #DocumentsNPCPositions, 1, -1 do DocumentsNPCPositions[i] = nil end
    for mapIndex, mapName in pairs(Config.Maps) do
        Debuger("Loading map: " .. mapName)
        Tables.Markers[mapIndex] = {}
        local mapData = exports["origen_police"]:LoadMarkers(mapName)
        for markerType, markersData in pairs(mapData) do
            if markerType == "Options" then
                MapOptions[mapIndex] = markersData
                goto skip_marker_type
            end
            -- Translate legacy names to valid MarkersList keys
            if markerType == "Dressing" then
                markerType = "DressingRoom"
            elseif markerType == "Armory" or markerType == "Armoury" then
                markerType = "Inventory/Armoury"
            elseif markerType == "Evidence" then
                markerType = "EvidenceReport"
            elseif markerType == "Helipad" then
                markerType = "RequestHelicopter"
            elseif markerType == "Garage" then
                markerType = "RequestVehicle"
            end

            for _, markerData in pairs(markersData) do
                local newMarkerData = MarkersList[markerType]
                local newMarkerDataCopy = Shallowcopy(newMarkerData)
                if not newMarkerData then
                    if markerType == "BillsNPC" then
                        BillsNPCPositions[#BillsNPCPositions + 1] = markerData.coords
                        goto skip_marker
                    end
                    if markerType == "DocumentsNPC" then
                        DocumentsNPCPositions[#DocumentsNPCPositions + 1] = markerData.coords
                        goto skip_marker
                    end
                    if markerType == 'SpawnConfiscatedVehicles' then
                        SpawnConfiscatedVehicles[mapIndex] = markerData.coords
                        goto skip_marker
                    end
                    if markerType == 'Options' then
                        goto skip_marker
                    end
                    newMarkerData = PublicMarkerList[markerType]
                    newMarkerDataCopy = Shallowcopy(newMarkerData)
                    if newMarkerDataCopy then
                        newMarkerDataCopy.coords = markerData.coords
                        newMarkerDataCopy.spawn = markerData.spawn
                        newMarkerDataCopy.station = mapIndex
                        newMarkerDataCopy.stationName = mapName
                        if markerType == "ConfiscatedVehicles" and markerData.spawn then
                            SpawnConfiscatedVehicles[mapIndex] = markerData.spawn
                        end
                        Public.Markers[#Public.Markers + 1] = newMarkerDataCopy
                    else
                        print("^1[origen_police] Warning: Marker type '" .. tostring(markerType) .. "' not found in MarkersList or PublicMarkerList. It was ignored.^7")
                    end
                else
                    if newMarkerDataCopy then
                        newMarkerDataCopy.coords = markerData.coords
                        newMarkerDataCopy.spawn = markerData.spawn
                        newMarkerDataCopy.station = mapIndex
                        newMarkerDataCopy.stationName = mapName
                        Tables.Markers[mapIndex][#Tables.Markers[mapIndex] + 1] = newMarkerDataCopy
                    end
                end
                ::skip_marker::
            end
            ::skip_marker_type::
        end

        if not MapOptions[mapIndex] then
            MapOptions[mapIndex] = {}
        end
    end
    CreateNPCsBills()
    if CreateNPCsDocuments then
        CreateNPCsDocuments()
    end
end

function ReloadMarkers()
    if Config.IgnoreSettings then return end
    Debuger("Reloading markers...")
    Tables.Markers = {}
    Public.Markers = {}
    ClearNPCsBills()
    if ClearNPCsDocuments then
        ClearNPCsDocuments()
    end
    LoadMarkers()
end

function IsJobAllowed(options, jobCat)
    if not options or not options.AllowedJobCat or #options.AllowedJobCat == 0 then return true end
    for _, job in pairs(options.AllowedJobCat) do
        if job == jobCat then
            return true
        end
    end
    return false
end

Public.CriminalClothe = Public.CriminalClothe[Config.Clothing == "fivem-appearance" and "illenium-appearance" or Config.Clothing]
Public.PatientClothe = Public.PatientClothe[Config.Clothing == "fivem-appearance" and "illenium-appearance" or Config.Clothing]
Config.IgnoreSettings = #Config.Maps > 0