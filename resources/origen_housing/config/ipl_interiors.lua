Config.IPL = {
    -- Houses
    {
        model = 'GTAOApartmentHi1',
        cam = vector4(-32.1304, -582.4614, 88.7121, 48.1465),
        enter = vector4(-19.0338, -581.8583, 90.1148, 86.1412),
        label = '4 Integrity Way, apto. 30',
    },
    {
        model = 'GTAOApartmentHi2',
        cam = vector4(-1463.8240, -530.6835, 55.5263, 95.1608),
        enter = vector4(-1458.0516, -520.6088, 56.9290, 145.5460),
        label = 'Dell Perro Heights, apto. 7',
    },
    {
        model = 'GTAOHouseHi1',
        cam = vector4(-171.2311, 488.1940, 137.4434, 230.2099),
        enter = vector4(-174.0481, 497.1868, 137.6669, 199.9451),
        label = '3655 Wild Oats Drive',
    },
    {
        model = 'GTAOHouseHi3',
        cam = vector4(371.2373, 414.4517, 145.6998, 200.4925),
        enter = vector4(373.5523, 423.3747, 145.9078, 168.5456),
        label = '2045 North Conker Avenue',
    },
    {
        model = 'GTAOHouseHi4',
        cam = vector4(-676.0883, 587.0753, 145.1695, 243.8280),
        enter = vector4(-682.0714, 592.3581, 145.3930, 233.3035),
        label = '2862 Hillcrest Avenue',
    },

    {
        model = 'GTAOHouseHi5',
        cam = vector4(-765.6352, 615.6423, 143.9303, 133.2746),
        enter = vector4(-758.9283, 618.7266, 144.1539, 120.2289),
        label = '2868 Hillcrest Avenue',
    },
    {
        model = 'GTAOHouseHi6',
        cam = vector4(-859.5023, 682.4014, 152.6527, 210.1455),
        enter = vector4(-859.8700, 690.9012, 152.8607, 190.6084),
        label = '2874 Hillcrest Avenue',
    },
    {
        model = 'GTAOHouseMid1',
        cam = vector4(346.9821, -1000.3311, -99.1963, 50.7038),
        enter = vector4(346.5080, -1012.6182, -99.1962, 1.1224),
        label = 'Casa media 1',
    },
    {
        model = 'GTAOHouseLow1',
        cam = vector4(265.1100, -1000.6078, -99.0145, 50.7038),
        enter = vector4(266.0410, -1007.3227, -101.0085, 358.5691),
        label = 'Casa sencilla 1',
    },

    -- Apartments
    {
        model = 'HLApartment1',
        cam = vector4(-1464.4905, -534.1597, 73.4440, 168.6028),
        enter = vector4(-1456.8982, -534.0297, 74.0446, 37.4201),
        label = 'Dell Perro Heights, apto. 4',
    },
    {
        model = 'HLApartment2',
        cam = vector4(-920.3992, -377.0860, 113.6745, 254.1811),
        enter = vector4(-919.8299, -368.6981, 114.2749, 116.0406),
        label = 'Richard Majestic, apto. 2',
    },
    {
        model = 'HLApartment3',
        cam = vector4(-614.4249, 52.6888, 97.6001, 209.4506),
        enter = vector4(-611.1195, 58.8597, 98.2004, 94.3943),
        label = 'Tinsel Towers, apto. 42',
    },
    {
        model = 'HLApartment4',
        cam = vector4(-773.4509, 331.8209, 211.4322, 42.0666),
        enter = vector4(-776.6625, 323.7606, 211.9974, 275.5432),
        label = 'Eclipse Towers, apto. 3',
    },
    {
        model = 'HLApartment5',
        cam = vector4(-17.8341, -592.7446, 79.4308, 8.1788),
        enter = vector4(-23.8671, -597.8061, 80.0312, 251.6066),
        label = '4 Integrity Way, apto. 28',
    },

    -- Apartments 2
    {
        GetData = function()
            return exports['bob74_ipl']:GetExecApartment1Object()
        end,
        styles = {
            default = 'modern',
            list = {
                [0] = { label = 'Moderno', name = 'modern', price = 25000 },  
                [1] = { label = 'Sombrío', name = 'moody', price = 25000 },
                [2] = { label = 'Vivo', name = 'vibrant', price = 25000 },
                [3] = { label = 'Elegante', name = 'sharp', price = 25000 },
                [4] = { label = 'Monocromo', name = 'monochrome', price = 25000 },
                [5] = { label = 'Seductor', name = 'seductive', price = 25000 },
                [6] = { label = 'Regio', name = 'regal', price = 25000 },
                [7] = { label = 'Agua', name = 'aqua', price = 25000 },
            }
        },
        model = 'ExecApartment1',
        cam = vector4(-789.3143, 323.8384, 217.0382, 5.4795),
        enter = vector4(-781.8431, 318.3360, 217.6734, 1.2606),
        label = 'Eclipse Towers, ático 1',
        prefix = 'apartment',
    },
    {
        GetData = function()
            return exports['bob74_ipl']:GetExecApartment2Object()
        end,
        styles = {
            default = 'seductive',
            list = {
                [0] = { label = 'Moderno', name = 'modern', price = 25000 },  
                [1] = { label = 'Sombrío', name = 'moody', price = 25000 },
                [2] = { label = 'Vivo', name = 'vibrant', price = 25000 },
                [3] = { label = 'Elegante', name = 'sharp', price = 25000 },
                [4] = { label = 'Monocromo', name = 'monochrome', price = 25000 },
                [5] = { label = 'Seductor', name = 'seductive', price = 25000 },
                [6] = { label = 'Regio', name = 'regal', price = 25000 },
                [7] = { label = 'Agua', name = 'aqua', price = 25000 },
            }
        },
        model = 'ExecApartment2',
        cam = vector4(-771.0553, 333.8823, 196.0860, 154.5697),
        enter = vector4(-779.2373, 339.4887, 196.6861, 191.3078),
        label = 'Eclipse Towers, ático 2',
        prefix = 'apartment',
    },
    {
        GetData = function()
            return exports['bob74_ipl']:GetExecApartment3Object()
        end,
        styles = {
            default = 'seductive',
            list = {
                [0] = { label = 'Moderno', name = 'modern', price = 25000 },  
                [1] = { label = 'Sombrío', name = 'moody', price = 25000 },
                [2] = { label = 'Vivo', name = 'vibrant', price = 25000 },
                [3] = { label = 'Elegante', name = 'sharp', price = 25000 },
                [4] = { label = 'Monocromo', name = 'monochrome', price = 25000 },
                [5] = { label = 'Seductor', name = 'seductive', price = 25000 },
                [6] = { label = 'Regio', name = 'regal', price = 25000 },
                [7] = { label = 'Agua', name = 'aqua', price = 25000 },
            }
        },
        model = 'ExecApartment3',
        cam = vector4(-790.7150, 324.1463, 187.3133, 330.1900),
        enter = vector4(-781.8900, 318.2172, 187.9142, 359.5018),
        label = 'Eclipse Towers, ático 3',
        prefix = 'apartment',
    },

    -- Offices
    {
        GetData = function()
            return exports['bob74_ipl']:GetFinanceOffice1Object()
        end,
        styles = {
            default = 'polished',
            list = {
                [0] = { label = 'Cálido', name = 'warm', price = 125000 },
                [1] = { label = 'Clásico', name = 'classical', price = 125000 },
                [2] = { label = 'Vintage', name = 'vintage', price = 125000 },
                [3] = { label = 'Contraste', name = 'contrast', price = 125000 },
                [4] = { label = 'Lujoso', name = 'rich', price = 125000 },
                [5] = { label = 'Frío', name = 'cool', price = 125000 },
                [6] = { label = 'Hielo', name = 'ice', price = 125000 },
                [7] = { label = 'Sobrio', name = 'conservative', price = 125000 },
                [8] = { label = 'Pulido', name = 'polished', price = 125000 },  
            }
        },
        model = 'FinanceOffice1',
        cam = vector4(-138.7164, -628.7888, 168.8203, 156.8523),
        enter = vector4(-142.3030, -614.0665, 168.8206, 282.7821),
        label = 'Centro de negocios Arcadius',
        prefix = 'office',
    },
    {
        GetData = function()
            return exports['bob74_ipl']:GetFinanceOffice2Object()
        end,
        styles = {
            default = 'warm',
            list = {
                [0] = { label = 'Cálido', name = 'warm', price = 125000 },
                [1] = { label = 'Clásico', name = 'classical', price = 125000 },
                [2] = { label = 'Vintage', name = 'vintage', price = 125000 },
                [3] = { label = 'Contraste', name = 'contrast', price = 125000 },
                [4] = { label = 'Lujoso', name = 'rich', price = 125000 },
                [5] = { label = 'Frío', name = 'cool', price = 125000 },
                [6] = { label = 'Hielo', name = 'ice', price = 125000 },
                [7] = { label = 'Sobrio', name = 'conservative', price = 125000 },
                [8] = { label = 'Pulido', name = 'polished', price = 125000 },   
            }
        },
        model = 'FinanceOffice2',
        cam = vector4(-74.5712, -818.4340, 243.3857, 300.2226),
        enter = vector4(-77.8696, -833.5586, 243.3860, 69.0665),
        label = 'Edificio Maze Bank',
        prefix = 'office',
    },
    {
        GetData = function()
            return exports['bob74_ipl']:GetFinanceOffice3Object()
        end,
        styles = {
            default = 'conservative',
            list = {
                [0] = { label = 'Cálido', name = 'warm', price = 125000 },
                [1] = { label = 'Clásico', name = 'classical', price = 125000 },
                [2] = { label = 'Vintage', name = 'vintage', price = 125000 },
                [3] = { label = 'Contraste', name = 'contrast', price = 125000 },
                [4] = { label = 'Lujoso', name = 'rich', price = 125000 },
                [5] = { label = 'Frío', name = 'cool', price = 125000 },
                [6] = { label = 'Hielo', name = 'ice', price = 125000 },
                [7] = { label = 'Sobrio', name = 'conservative', price = 125000 },
                [8] = { label = 'Pulido', name = 'polished', price = 125000 }, 
            }
        },
        model = 'FinanceOffice3',
        cam = vector4(-1573.4182, -570.6354, 108.5228, 178.1355),
        enter = vector4(-1583.6021, -559.4288, 108.5228, 300.4040),
        label = 'Lom Bank',
        prefix = 'office',
    },
    {
        GetData = function()
            return exports['bob74_ipl']:GetFinanceOffice4Object()
        end,
        styles = {
            default = 'cool',
            list = {
                [0] = { label = 'Cálido', name = 'warm', price = 125000 },
                [1] = { label = 'Clásico', name = 'classical', price = 125000 },
                [2] = { label = 'Vintage', name = 'vintage', price = 125000 },
                [3] = { label = 'Contraste', name = 'contrast', price = 125000 },
                [4] = { label = 'Lujoso', name = 'rich', price = 125000 },
                [5] = { label = 'Frío', name = 'cool', price = 125000 },
                [6] = { label = 'Hielo', name = 'ice', price = 125000 },
                [7] = { label = 'Sobrio', name = 'conservative', price = 125000 },
                [8] = { label = 'Pulido', name = 'polished', price = 125000 }, 
            }
        },
        model = 'FinanceOffice4',
        cam = vector4(-1385.2728, -477.5140, 72.0421, 238.5955),
        enter = vector4(-1399.4094, -481.5109, 72.0421, 9.3194),
        label = 'Maze Bank Oeste',
        prefix = 'office',
    },

    -- Labs
    {
        model = 'BikerCocaine',
        cam = vector4(1087.7415, -3192.9731, -38.9934, 242.4501),
        enter = vector4(1088.6110, -3187.7529, -38.9935, 183.7868),
        label = 'Laboratorio de coca',
    },
    {
        model = 'BikerCounterfeit',
        cam = vector4(1137.0081, -3196.3750, -39.6658, 83.3583),
        enter = vector4(1137.9657, -3198.6870, -39.6657, 1.8609),
        label = 'Fábrica de billetes falsos',
    },
    {
        model = 'BikerMethLab',
        cam = vector4(1015.1557, -3194.2668, -38.1972, 119.9598),
        enter = vector4(997.1916, -3200.6702, -36.3937, 268.9533),
        label = 'Laboratorio de meta',
    },
    {
        model = 'BikerWeedFarm',
        cam = vector4(1062.6161, -3188.0461, -39.1120, 140.7021),
        enter = vector4(1065.9739, -3183.5032, -39.1636, 94.3370),
        label = 'Plantación de maría',
    },
    {
        model = 'BikerClubhouse1',
        cam = vector4(1099.2932, -3165.0874, -37.6011, 312.5567),
        enter = vector4(1110.0775, -3166.1909, -37.5186, 5.8352),
        label = 'Club de moteros 1',
    },
    {
        model = 'BikerClubhouse2',
        cam = vector4(1010.0227, -3156.0972, -38.9075, 134.0797),
        enter = vector4(997.9897, -3164.1882, -38.9074, 279.0373),
        label = 'Club de moteros 2',
    },

    -- Bunkers
    {
        model = 'GunrunningBunker',
        cam = vector4(898.1505, -3208.3833, -98.2107, 59.2065),
        enter = vector4(895.3598, -3245.9509, -98.2529, 95.1291),
        label = 'Búnker de armas',
    },

    -- Hangars
    {
        model = 'SmugglerHangar',
        cam = vector4(-1255.8583, -3043.7490, -48.4903, 19.6144),
        enter = vector4(-1267.1750, -3048.4370, -48.4901, 3.5428),
        label = 'Hangar',
    },

    -- Casino penthouse
    {
        model = 'DiamondPenthouse',
        cam = vector4(971.1683, 50.2129, 116.1641, 114.0913),
        enter = vector4(969.8597, 63.1486, 112.5563, 241.6178),
        label = 'Ático del casino',
    },

    --[[ {
        model = '',
        cam = vector4(),
        enter = vector4(),
        label = 'Etiqueta',
    }, ]]
}

local build = GetGameBuildNumber()
local extra = {}

if build >= 2545 then 
    extra[#extra+1] = {
        model = 'MpSecurityStudio',
        cam = vector4(-1022.7220, -91.0147, -99.4032, 329.9643),
        enter = vector4(-1021.7422, -92.4120, -99.4031, 358.7607),
        label = 'Estudios Record A',
    }

    extra[#extra+1] = {
        model = 'MpSecurityOffice1',
        cam = vector4(-1007.9128, -431.2495, 66.4236, 98.9738),
        enter = vector4(-1028.0580, -432.1894, 63.8613, 279.7576),
        label = 'Oficina de seguridad 1',
    }
end

if build >= 2699 then
    extra[#extra+1] = {
        model = 'CriminalEnterpriseVehicleWarehouse',
        cam = vector4(815.8206, -3011.1477, -69.0000, 62.1696),
        enter = vector4(817.4138, -3001.4702, -68.9999, 90.6814),
        label = 'Almacén de vehículos',
    }
end

if next(extra) then
    for k,v in pairs(extra) do
        Config.IPL[#Config.IPL+1] = v
    end
end