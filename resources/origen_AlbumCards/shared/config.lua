Config = {}
Config.Debug = false

function DebugPrint(...)
    if Config.Debug then
        print('^3[origen_AlbumCards]^0', ...)
    end
end

Config.Locale = 'es'

Config.Framework = 'qbx'    -- 'esx', 'qb', 'qbx'
Config.Inventory = 'origen' -- 'origen', 'ox', 'qb'
Config.Menu      = 'auto'   -- 'auto', 'org-menu', 'qb-menu', 'ox_lib'

Config.Items = {
    album = 'album',
    pack  = 'albumpack',
    -- Individual card items are referenced by full name (albumcardcommon, albumcardrare, etc.)
}

Config.PackSize     = 5   -- How many cards are inside a pack
Config.MaxGiveCount = 100 -- Max number of items an admin can give at once

Config.Shop = {
    InteractionRadius = 2.5, -- Distance (meters) to trigger shop interaction
    InteractionKey    = 38,  -- GTA control index (38 = E key)
}

Config.Rarities = {
    { name = 'Common',    chance = 60, filter = 'grayscale(1) brightness(1.1)' },
    { name = 'Uncommon',  chance = 25, filter = 'sepia(1) hue-rotate(65deg) saturate(2.5) brightness(1)' },
    { name = 'Rare',      chance = 10, filter = 'sepia(1) hue-rotate(185deg) saturate(3) brightness(1)' },
    { name = 'Epic',      chance = 4,  filter = 'sepia(1) hue-rotate(245deg) saturate(3.5) brightness(1.1)' },
    { name = 'Legendary', chance = 1,  filter = 'sepia(1) hue-rotate(-28deg) saturate(4) brightness(1.4) contrast(1.1)' },
}
