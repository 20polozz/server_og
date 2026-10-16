Cfg = {} or Cfg

Cfg.Framework = 'qbcore' -- qbcore, qbox, esx or custom
Cfg.Inventory = 'new-qb-inventory' -- origen_inventory | qb-inventory | new-qb-inventory | qs-inventory | ox_inventory | ls-inventory | codem-inventory

Cfg.CustomNotify = false

Cfg.Percentage = 20

Cfg.AlwaysAlertPolice = true -- Always send police alert when taking hostages
Cfg.AlertChance = 100 -- Percentage chance to send alert (0-100)

Cfg.Language = 'es'

Cfg.KillKey = 38 -- E
Cfg.KneelKey = 194 -- BACKSPACFE

Cfg.CustomMenu = false

Cfg.MaxHostages = 5 -- Max hostages that a player can have
Cfg.DistanceToEscape = 30.0 -- The distance that the hostage have to be from the player to escape 
Cfg.FleeingCooldown = 60000 -- Time in ms that a NPC will be immune to hostage attempts after fleeing (60 seconds) 

-- Blacklist of ped models that cannot be taken hostage
Cfg.PedBlacklist = {
    'a_c_boar', 'a_c_cat_01', 'a_c_chickenhawk', 'a_c_chimp', 'a_c_chop', 'a_c_cormorant', 'a_c_cow', 'a_c_coyote',
    'a_c_crow', 'a_c_deer', 'a_c_dolphin', 'a_c_fish', 'a_c_hen', 'a_c_humpback', 'a_c_husky', 'a_c_killerwhale',
    'a_c_mtlion', 'a_c_pig', 'a_c_pigeon', 'a_c_poodle', 'a_c_pug', 'a_c_rabbit_01', 'a_c_rat', 'a_c_retriever',
    'a_c_rhesus', 'a_c_rottweiler', 'a_c_seagull', 'a_c_sharkhammer', 'a_c_sharktiger', 'a_c_shepherd', 'a_c_stingray', 'a_c_westy'
}

Cfg.PedBlacklistSet = {}
for _, name in ipairs(Cfg.PedBlacklist) do
    Cfg.PedBlacklistSet[ joaat and joaat(name) or GetHashKey(name) ] = true
end

Cfg.Rob = true -- Enable or disable the robbery system
Cfg.RobItems = {
    {
        item = "bread",
        min = 1,
        max = 5,
        chance = 30 -- 50% chance to get this item
    },
    {
        item = "sandwich",
        min = 1,
        max = 5,
        chance = 50 -- 50% chance to get this item
    },
}

-- Police
Cfg.RequireMinimumPolice = true -- Enable or disable minimum police requirement
Cfg.MinimumPolice = 0 -- Minimum number of police officers required online
Cfg.PoliceJobs = {'police', 'sheriff'} -- Jobs that count as police
Cfg.UseOrigenPolice = false -- Set to true if you use origen_police duty system
Cfg.OrigenPoliceCategory = 'police' -- Category

-- Aggressive NPC
Cfg.AggressiveNPCs = true -- Enable or disable aggressive NPCs system
Cfg.AggressiveChance = 20 -- Percentage chance that an NPC will be aggressive (0-100)
Cfg.AggressiveWeapons = {
    {
        weapon = "WEAPON_KNIFE",
        chance = 40 -- 40% chance to get this weapon
    },
    {
        weapon = "WEAPON_BAT",
        chance = 30
    },
    {
        weapon = "WEAPON_PISTOL",
        chance = 15
    },
    {
        weapon = "WEAPON_MACHETE",
        chance = 10
    },
    {
        weapon = "WEAPON_HAMMER",
        chance = 5
    }
}

function GetCoreObject()
    --return YOUR_OWN_CORE_EXPORT
end

function openMenu(entity)
    lib.registerContext({
        id = 'hostageped',
        title = '¿En que puedo ayudarte?',
        options = {
            {
                title = 'Liberar',
                icon = 'fa-solid fa-person-running',
                onSelect = function()
                    release(entity)
                end
            },
            {
                title = 'Sigueme',
                icon = 'fa-solid fa-person-walking-arrow-right',
                onSelect = function()
                    follow(entity)
                end
            },
            {
                title = 'Quedate aquí',
                icon = 'fa-solid fa-person-praying',
                onSelect = function()
                    kneel(entity)
                end
            },
            {
                title = 'Cogerlo del cuello',
                icon = 'fa-solid fa-gun',
                onSelect = function()
                    threaten(entity)
                end
            },
            {
                title = 'Robar',
                icon = 'fa-solid fa-hand-holding-usd',
                onSelect = function()
                    RobEntity(entity)
                end
            }
        }
    })
    -- Functions to make this work
    -- release(entity)
    -- follow(entity)
    -- kneel(entity)
    -- threaten(entity)
    lib.showContext('hostageped')
end

local notify_buffer = {}

function ShowHelpNotification(key, msg, entity)
    if GetResourceState("origen_hud") == "started" then
        exports['origen_hud']:setupControls({
            { key = key, text = msg },
        })
        return
    end
    -- Fallback
    if Cfg.Framework == 'qbcore' then
        exports['qb-core']:DrawText(msg)
    elseif Cfg.Framework == 'qbox' then
        lib.showTextUI(msg)
    end
end

function HideHelpNotification()
    if GetResourceState("origen_hud") == "started" then
        exports['origen_hud']:hideControls()
        return
    end
    -- Fallback
    if Cfg.Framework == 'qbcore' then
        exports['qb-core']:HideText()
    elseif Cfg.Framework == 'qbox' then
        lib.hideTextUI()
    end
end

-- @param msg string 
function ShowNotification(msg)
    if Cfg.Framework == "qbcore" then
        Framework.Functions.Notify(msg, "primary")
    elseif Cfg.Framework == "qbox" then
        exports.qbx_core:Notify(msg, "primary")
    elseif Cfg.Framework == "esx" then
        Framework.ShowNotification(msg)
    end
end

function sendPoliceAlert(coords)
    if not Cfg.AlwaysAlertPolice then
        return
    end
    
    math.randomseed(GetGameTimer())
    if math.random(0, 100) > Cfg.AlertChance then
        return
    end
    
    TriggerServerEvent("SendAlert:police", {
        coords = coords,
        title = "Intento de secuestro",
        description = "Una persona armada está intentando secuestrar a alguien, ayuda por favor!!",
        type = "SECUESTRO",
        job = {"police", "sheriff", "fib"}
    })
end

function CanKillNPC()
    -- Your code to check if the player can kill the npc
    return true
end

function AddItem(xPlayer, name, amount, slot, info) -- THIS IS A SERVER SIDE FUNCTION
    if Cfg.Inventory == "ox_inventory" then
        return exports.ox_inventory:AddItem(xPlayer.source, name, amount, info, slot)
    end

    return xPlayer.addInventoryItem(name, amount, slot, info)
end

Cfg.Translations = {
    ['es'] = {
        ['someter'] = 'Someter',
        ['Matar'] = {
            ['kill'] = 'Matar', -- Only if you use origen_notify
            ['kneel'] = 'Volver a arrodillar', -- Only if you use origen_notify
            ['fullText'] = '[E] Matar | [Backspace] Volver a arrodillar',
        },
        ['ignored'] = 'El civil ha ignorado tu amenaza',
        ['hostage_options'] = 'Opciones de rehén',
        ['release_hostage'] = 'Liberar rehén',
        ['release_hostage_desc'] = 'Deja al rehén libre',
        ['follow_hostage'] = 'Sigueme',
        ['follow_hostage_desc'] = 'Ordena al rehén que te siga',
        ['kneel_hostage'] = 'Arrodillate',
        ['kneel_hostage_desc'] = 'Ordena al rehén que se arrodille',
        ['threat_hostage'] = 'Amenzar',
        ['threat_hostage_desc'] = 'Amenaza al rehén con un arma en el cuello',
        ['rob_hostage'] = 'Robar',
        ['rob_hostage_desc'] = 'Roba al rehén',
        ['max_hostages'] = 'No puedes tener más rehenes',
        ['no_items'] = 'El civil no tiene objetos',
        ['robbed_notify'] = 'Has robado a un civil',
        ['not_enough_police'] = 'No hay suficientes policías en línea (Mínimo: %s)',
        ['npc_aggressive'] = 'El civil se ha vuelto agresivo y te está atacando!',
        ['npc_fought_back'] = 'El civil se ha defendido con un arma!',
    },
    ['en'] = {
        ['someter'] = '~y~E~w~ Subdue',
        ['Matar'] = {
            ['kill'] = 'Kill',-- Only if you use origen_notify
            ['kneel'] = 'Return to kneeling',-- Only if you use origen_notify
            ['fullText'] = '[E] Kill  | [Backspace] Return to kneeling',
        },
        ['ignored'] = 'The civilian ignored your threat',
        ['hostage_options'] = 'Hostage options',
        ['release_hostage'] = 'Release hostage',
        ['release_hostage_desc'] = 'Set the hostage free',
        ['follow_hostage'] = 'Follow me',
        ['follow_hostage_desc'] = 'Order the hostage to follow you',
        ['kneel_hostage'] = 'Kneel',
        ['kneel_hostage_desc'] = 'Order the hostage to kneel',
        ['threat_hostage'] = 'Threaten',
        ['threat_hostage_desc'] = 'Threaten the hostage with a weapon at the neck',
        ['rob_hostage'] = 'Rob',
        ['rob_hostage_desc'] = 'Rob the hostage',
        ['max_hostages'] = 'You can\'t have more hostages',
        ['no_items'] = 'The civilian has no items',
        ['robbed_notify'] = 'You have robbed a civilian',
        ['not_enough_police'] = 'Not enough police online (Minimum: %s)',
        ['npc_aggressive'] = 'The civilian has become aggressive and is attacking you!',
        ['npc_fought_back'] = 'The civilian fought back with a weapon!',
    },
    ['it'] = {
        ['someter'] = '~y~E~w~ Sottomettere',
        ['Matar'] = {
            ['kill'] = 'Uccidi', -- Only if you use origen_notify
            ['kneel'] = 'Torna a far inginocchiare', -- Only if you use origen_notify
            ['fullText'] = '[E] Uccidi | [Backspace] Torna a far inginocchiare',
        },
        ['ignored'] = 'Il civile ha ignorato la tua minaccia',
        ['hostage_options'] = 'Opzioni ostaggio',
        ['release_hostage'] = 'Liberare ostaggio',
        ['release_hostage_desc'] = "Lascia libero l'ostaggio",
        ['follow_hostage'] = 'Segui ostaggio',
        ['follow_hostage_desc'] = "Ordina all'ostaggio di seguirti",
        ['kneel_hostage'] = 'Fai inginocchiare ostaggio',
        ['kneel_hostage_desc'] = "Ordina all'ostaggio di inginocchiarsi",
        ['threat_hostage'] = 'Minaccia ostaggio',
        ['threat_hostage_desc'] = "Minaccia l'ostaggio con un'arma al collo",
        ['rob_hostage'] = 'Rubare ostaggio',
        ['rob_hostage_desc'] = 'Rubare l ostaggio',
        ['max_hostages'] = 'Non puoi avere più ostaggi',
        ['no_items'] = 'Il civile non ha oggetti',
        ['robbed_notify'] = 'Hai rubato un civile',
        ['not_enough_police'] = 'Non ci sono abbastanza poliziotti online (Minimo: %s)',
        ['npc_aggressive'] = 'Il civile è diventato aggressivo e ti sta attaccando!',
        ['npc_fought_back'] = 'Il civile si è difeso con un\'arma!',
    },
}

Cfg.Translations = Cfg.Translations[Cfg.Language] -- DONT TOUCH THIS

if GetResourceState("origen_notify") == "started" then
    Cfg.CustomNotify = true
end