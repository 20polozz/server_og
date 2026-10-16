local GRS = GetResourceState
local GRS_M = function(res) return GRS(res):match('start') end
local AutoSelectFramework = function()
    if GRS_M('qbx_core') then
        return 'qbx'
    elseif GRS_M('es_extended') then
        return 'esx'
    elseif GRS_M('qb-core') then
        return 'qbcore'
    end
    return 'NONE'
end

--[[
   ___       _                    ___                      _                   
  / _ \ _ __(_) __ _  ___ _ __   |_ _|_ ____   _____ _ __ | |_ ___  _ __ _   _ 
 | | | | '__| |/ _` |/ _ \ '_ \   | || '_ \ \ / / _ \ '_ \| __/ _ \| '__| | | |
 | |_| | |  | | (_| |  __/ | | |  | || | | \ V /  __/ | | | || (_) | |  | |_| |
  \___/|_|  |_|\__, |\___|_| |_| |___|_| |_|\_/ \___|_| |_|\__\___/|_|   \__, |
               |___/                                                     |___/ 
    Origen Inventory by Origen Network
    Version: 2.0.0
]]


Config = Config or {}

-----------------------------------------
------------------- DEBUG - EXPERIMENTALS
-----------------------------------------
Config.Debug = false

--[[
    *** Attention user, this section is only for advanced users (or devs).
        Inventory experiments are functions modified to the default behavior, 
        activating any of these functions may corrupt the data information or something may stop working.

        If the experiments work successfully, in next versions will be added as a feature.
]]
Config.Experimentals = {
    --- Give Algorithm
    -- 'stack_unique' : Allow give stack of unique items. (Ex, give two pistols with same serie) (just work with v2 exports)
    -- 'slot_based'   : Allow give weapons and automatically asign slots for each them.
    -- 'no_stack'     : Old stack system, if you give 5, just recives one.
    --- Please give feedback about this feature
    giveItemAlgorithm = 'no_stack',
}
---------------------------

Config.Language = "es" -- es, en
Config.Framework = AutoSelectFramework() -- 'esx', 'qbcore', 'NONE'

----------------------------------------
-------------- DROPS -------------------
----------------------------------------
Config.Drop = {
    MaxWeight = 100000,
    MaxSlots = 10,
}

----------------------------------------
-------- STATUS NOTIFICATIONS ----------
----------------------------------------
Config.StatusNotifications = {
    Enabled = true, -- Enable/Disable the system
    -- Thresholds: percentage -> interval (in minutes)
    -- When status is below key%, notify every value minutes
    Hunger = {
        [50] = 10, -- 50% or less: notify every 10 minutes
        [25] = 5,  -- 25% or less: notify every 5 minutes
        [10] = 1,  -- 10% or less: notify every 1 minute
    },
    Thirst = {
        [50] = 10,
        [25] = 5,
        [10] = 1,
    }
}


----------------------------------------
-------- INVENTORY SYSTEMS -------------
----------------------------------------
Config.UseInventoryComsumables = true -- config your items comsumables at inventory
Config.CreateStashIfNoExists = true -- Create stash when inventory is open and doesn't existing 


Config.MarkerColors = {
    give_player = vec4(0, 0, 0, 255),
}

-----------------------------------------
-------------- PHONES -----------------
-----------------------------------------
--- 
Config.Phone = {
    Resource = 'qs-smartphone-pro', -- 'qs-smartphone-pro', 'lb-phone', 'none'
}

--- QS Smartphone & QS Smartphone PRO are supported too ;)
--- You not need touch anything for this resources <3

----------------------------------------
----------------------------------------
----------------------------------------
-- LIST OF AVAILABLE PROGRESSBARS:
-- 'default'
-- 'esx_progressbar'
-- 'qb-core'
-- 'qs-progressbar'
-- 'ox_lib' :: Note: You must uncomment ox_lib line in fxmanifest.lua 

Config.Progressbar = 'default'


function DetectMoneyOrCash()
    return Config.Framework == 'esx' and 'money' or 'cash'
end