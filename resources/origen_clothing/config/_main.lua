-- General
Config.Language = 'es' -- System language (es, en)
Config.Debug = false -- Debug mode for developers

-- Commands
Config.managementCommand = 'clothingadmin' -- Open store management menu
Config.reloadSkinCommand = 'fixpj' -- Reload player appearance
Config.openClothingCommand = 'skin' -- Open clothing menu
Config.openPedsMenuCommand = 'pedmenu' -- Open peds menu

Config.UseOnlyInputs = true -- Use only inputs to change clothes and not images

-- Permissions
-- Permissions required to manage the script in game
-- Leave empty {} to allow access to all players
Config.Permissions = {
    'god',
    'superadmin',
    'admin',
}

-- Payment System
Config.DefaultPaymentMethod = 'bank' -- Default payment method

Config.PaymentMethods = {
    ['cash'] = true,
    ['bank'] = true,
    -- ['custom_account'] = true,
}

-- Prices
Config.DefaultPrice = 20 -- Default price for all items

Config.DefaultPriceByCategory = {
    ['masks'] = 20,
    ['jackets'] = 20,
    ['shirts'] = 20,
    ['torsos'] = 20,
    ['vest'] = 20,
    ['legs'] = 20,
    ['shoes'] = 20,
    ['bags'] = 20,
    ['neck'] = 20,
    ['decals'] = 20,
    ['hats'] = 20,
    ['glasses'] = 20,
    ['earrings'] = 20,
    ['watches'] = 20,
    ['bracelets'] = 20,
}

-- Gameplay Options
Config.FixWetClothPhysics = true -- Fix wet clothes physics when raining

-- Spawn coordinates after first-time character creation.
--
-- A nil: de donde aparece un personaje nuevo se encarga origen_intro, que le
-- monta la llegada en coche. Este bloque de EndPedCreation es el unico sitio
-- que lee esta variable, asi que ponerla a nil desactiva el teleport entero
-- sin tocar client/character.lua (que NO esta en escrow_ignore).
--
-- Para volver atras, descomenta la linea de abajo y quita origen_intro.
-- Config.SpawnCoords = vector4(-1385.68, 271.74, 72.07, 17.3)
Config.SpawnCoords = nil

-- Character creator coordinates (used by StartPedCreation in client/character.lua)
-- Keep this synced with origen_titlemenu Config.CreationCoords when using multichar setup.
Config.CreationCoords = vector4(1046.64, 4875.51, -31.8, 5.33)

-- Remove Items
-- Default values to remove clothing items
Config.RemoveItem = {
    [`mp_m_freemode_01`] = {
        ['masks'] = 'none--1--0--0',
        ['torsos'] = 'none--3--15--0',
        ['legs'] = 'mp_m_valentines_02--4--1--1',
        ['bags'] = 'none--5--0--0',
        ['shoes'] = 'Male_Apt01--6--1--0',
        ['neck'] = 'none--7--0--0',
        ['shirts'] = 'none--8--15--0',
        ['vest'] = 'none--9--0--0',
        ['decals'] = 'none--10--0--0',
        ['jackets'] = 'none--11--15--0',
        ['hats'] = 'none--1000---1---1',
        ['glasses'] = 'none--1001---1---1',
        ['earrings'] = 'none--1002---1---1',
        ['watches'] = 'none--1006---1---1',
        ['bracelets'] = 'none--1007---1---1',
    },
    -- Female Model
    [`mp_f_freemode_01`] = {
        ['masks'] = 'none--1--0--0',
        ['torsos'] = 'none--3--0--0',
        ['legs'] = 'none--4--0--0',
        ['bags'] = 'none--5--0--0',
        ['shoes'] = 'none--6--0--0',
        ['neck'] = 'none--7--0--0',
        ['shirts'] = 'none--8--0--0',
        ['vest'] = 'none--9--0--0',
        ['decals'] = 'none--10--0--0',
        ['jackets'] = 'none--11--0--0',
        ['hats'] = 'none--1000---1--0',
        ['glasses'] = 'none--1001---1--0',
        ['earrings'] = 'none--1002---1--0',
        ['watches'] = 'none--1006---1--0',
        ['bracelets'] = 'none--1007---1--0',
    }
}