Config = Config or {}
----------------------------------------
-------------- SHOPS -------------------
----------------------------------------
Config.Shop ={
    -- ['shopId'] = 'item'
    ---- IMPORTANT: If you enable MoneyAsItem set item as ItemName otherwise set item as ACCOUNT name.
    --[[
        Example:
        ** If MoneyAsItem is True 
        default = 'money'

        ** If MoneyAsItem is False
        default = 'bank' or 'cash' or 'money' or 'any'
    ]]
    default = DetectMoneyOrCash()
    
}


---------------------------------------------
-------------- SHOPS SETUP ------------------
---------------------------------------------
Config.ShopItems = {
    ['weapons'] = {
        {
            name = 'weapon_pistol',
            price = 20,
            amount = 10,
            metadata = {
                serie = 'LSDP'
            },
        },
        {
            name = 'tosti',
            price = 2,
            amount = 10,
            metadata = {},
        },
    },
    ['24-7'] = {
        {
            name = 'tosti',
            price = 2,
            amount = 10,
            metadata = {},
            type = 'item'
        },
        {
            name = 'kurkakola',
            price = 0,
            amount = 10,
            metadata = {},
            type = 'item'
        },
        {
            name = 'twerks_candy',
            price = 10,
            amount = 10,
            metadata = {},
            type = 'item'
        },
        {
            name = 'water_bottle',
            price = 10,
            amount = 10,
            metadata = {},
            type = 'item'
        },
    },
    ['tecno'] = {
        {
            name = 'ognphone',
            price = 1500,
            amount = 10,
            metadata = {},
            type = 'item'
        },
        {
            name = 'fitbit',
            price = 700,
            amount = 10,
            metadata = {},
            type = 'item'
        },
        {
            name = 'radio',
            price = 500,
            amount = 10,
            metadata = {},
            type = 'item'
        },
    }
}

Config.Shops = {
    -- ['weapons'] = {
    --     label = 'Shop',
    --     slots = 4,
    --     marker = {
    --         type = 20,
    --         size = vector3(0.3, 0.3, 0.3),
    --         color = {r = 0, g = 0, b = 0, a = 255},
    --         distanceView = 5,
    --         distanceInteract = 1
    --     },
    --     blip = {
    --         enabled = true,
    --         sprite = 52,
    --         color = 2,
    --         scale = 0.8,
    --         name = 'ORIGEN Shop Armas',
    --     },
    --     locations = {vector3(-1299.95, -2458.56, 13.94)},
    --     items = Config.ShopItems['weapons']
    -- },
    -- ['tecno'] = {
    --     label = 'Tecnologia',
    --     slots = 3,
    --     marker = {
    --         type = 20,
    --         size = vector3(0.3, 0.3, 0.3),
    --         color = {r = 0, g = 0, b = 0, a = 255},
    --     },
    --     blip = {
    --         enabled = true,
    --         sprite = 52,
    --         color = 2,
    --         scale = 0.8,
    --         name = 'ORIGEN Shop',
    --     },
    --     pos = vector3(-1115, -234, 37),
    --     items = Config.ShopItems['tecno']
    -- },
    -- ['mi_tienda_uno'] = {
    --     label = 'Shop',
    --     slots = 4,
    --     marker = {
    --         type = 20,
    --         size = vector3(0.3, 0.3, 0.3),
    --         color = {r = 0, g = 0, b = 0, a = 255},
    --     },
    --     blip = {
    --         enabled = true,
    --         sprite = 52,
    --         color = 2,
    --         scale = 0.8,
    --         name = 'ORIGEN Shop',
    --     },
    --     pos = vector3(25.94, -1347.76, 29.5),
    --     items = Config.ShopItems['24-7']
    -- },
    -- ['mi_tienda_dos'] = {
    --     label = 'Shop',
    --     slots = 4,
    --     marker = {
    --         type = 20,
    --         size = vector3(0.3, 0.3, 0.3),
    --         color = {r = 0, g = 0, b = 0, a = 255},
    --     },
    --     blip = {
    --         enabled = true,
    --         sprite = 52,
    --         color = 2,
    --         scale = 0.8,
    --         name = 'ORIGEN Shop',
    --     },
    --     pos = vector3(-707.74, -914.0, 19.22),
    --     items = Config.ShopItems['24-7']
    -- },
    -- ['origen_gang'] = {
    --     label = 'ORIGEN Shop',
    --     slots = 8,
    --     gang = 'lostmc',
    --     gang_gradeup = 0,
    --     gang_gradedown = 3,
    --     marker = {
    --         type = 20,
    --         size = vector3(0.3, 0.3, 0.3),
    --         color = {r = 0, g = 0, b = 0, a = 255},
    --     },
    --     blip = {
    --         enabled = true,
    --         sprite = 52,
    --         color = 2,
    --         scale = 0.8,
    --         name = 'ORIGEN Shop',
    --     },
    --     pos = vector3(-68.74, -817.08, 326.18),
    --     items = Config.ShopItems['24-7']
    -- },
    -- ['origen_job'] = {
    --     label = 'ORIGEN POLICE TEST',
    --     job = 'police', -- or gang = 'origen',
    --     job_gradeup = 0, -- or gang_grade = 0,
    --     job_gradedown = 4, -- or gang_grade = 0,
    --     -- gang = 'origen',
    --     -- gang_gradeup = 0,
    --     -- gang_gradedown = 3,
    --     marker = {
    --         type = 20,
    --         size = vector3(0.3, 0.3, 0.3),
    --         color = {r = 0, g = 0, b = 0, a = 255},
    --     },
    --     blip = {
    --         enabled = true,
    --         sprite = 52,
    --         color = 2,
    --         scale = 0.8,
    --         name = 'ORIGEN Shop',
    --     },
    --     pos = vector3(-70.92, -813.53, 326.18),
    --     items = Config.ShopItems['24-7']
    -- }
}