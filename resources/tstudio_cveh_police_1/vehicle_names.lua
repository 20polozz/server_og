CreateThread(function()
    AddTextEntryByHash(0x53602DFB, "Aleutian Pursuit")
    AddTextEntryByHash(0x56BB1FC5, "APC Armored")
    AddTextEntryByHash(0xB45B91DE, "Barrage Armored")
    AddTextEntryByHash(0x4B56AF30, "Police Bati 801")
    AddTextEntryByHash(0x3573C3E9, "Police Bike")
    AddTextEntryByHash(0xB30798F6, "Buffalo STX Enforcer")
    AddTextEntryByHash(0xBD8A3E4D, "Removed Spoiler")
    AddTextEntryByHash(0x9D29D574, "Removed Air Intake")
    AddTextEntryByHash(0x99CD6682, "Buffalo EVX Enforcer")
    AddTextEntryByHash(0x8D82D85E, "Burrito Transporter")
    AddTextEntryByHash(0xA15F0AA4, "Caracara 4x4 Patrol")
    AddTextEntryByHash(0x4429B7CE, "Cavalcade XL Pursuit")
    AddTextEntryByHash(0xCAC1F705, "Cheetah Classic Pursuit")
    AddTextEntryByHash(0xD78F852D, "Coquette D10 Interceptor")
    AddTextEntryByHash(0x66AB779E, "Dinghy Patrol")
    AddTextEntryByHash(0x7B8BF1D8, "Granger 3600LX Pursuit")
    AddTextEntryByHash(0xDC9ACE8D, "Walton L35 Utility")
    AddTextEntryByHash(0x5B8D796F, "Matte Grille w/ Inserts")
    AddTextEntryByHash(0x4BF7DA44, "Chrome Grille")
    AddTextEntryByHash(0x61A905A6, "Chrome Grille w/ Inserts")
    AddTextEntryByHash(0x426E031D, "Menacer Armored")
    AddTextEntryByHash(0xD8C2EABD, "Niobe Interceptor")
    AddTextEntryByHash(0x7B62E61D, "Panto Cruiser")
    AddTextEntryByHash(0x94279D25, "Riata Patrol")
    AddTextEntryByHash(0x3A2C9FDB, "Scorcher")
    AddTextEntryByHash(0xC1C63956, "Stanier Cruiser")
    AddTextEntryByHash(0x05DBC8DF, "Terminus Patrol")
    AddTextEntryByHash(0x868FA3DD, "Verus Patrol")
    AddTextEntryByHash(0xBF4ED485, "Vigero ZX Interceptor")
    AddTextEntryByHash(0xDA38495D, "Baller ST-D Pursuit")
    AddTextEntryByHash(0xC927E02A, "Minimus Cruiser")
    AddTextEntryByHash(0xC84EBCF9, "Omnis E-GT Interceptor")
    AddTextEntryByHash(0x495E4072, "V-STR Pursuit")
    AddTextEntryByHash(0x73B41AC8, "Banshee GTS Interceptor")
    AddTextEntryByHash(0x8DE170DF, "Castigator Patrol")
    AddTextEntryByHash(0x89F0E7ED, "Cypher Interceptor")
    AddTextEntryByHash(0x30480505, "Deity Cruiser")
    AddTextEntryByHash(0x9D3E3B01, "Dominator GT Interceptor")
    AddTextEntryByHash(0xCC87B646, "Ignus Interceptor")
    AddTextEntryByHash(0x43B99C28, "Insurgent Armored")
    AddTextEntryByHash(0x079EA793, "Itali RSX Interceptor")
    AddTextEntryByHash(0xF7EEB093, "Nightshark Armored")
    AddTextEntryByHash(0xF4B2404B, "Raiden Cruiser")
    AddTextEntryByHash(0xC18239E8, "Riot Armored")
    AddTextEntryByHash(0x48EBB6C8, "Sentinel GTS Interceptor")
    AddTextEntryByHash(0x9C07BEF6, "Seven 70 Interceptor")
    AddTextEntryByHash(0x764F7C4B, "Tailgater S Cruiser")
    AddTextEntryByHash(0x82CBA299, "Tempesta Interceptor")
    AddTextEntryByHash(0xF9329991, "10F Interceptor")
    AddTextEntryByHash(0x655FC390, "Turismo Omaggio")
    AddTextEntryByHash(0x97AE3AD9, "Dorado STX Enforcer")
    AddTextEntryByHash(0x29E35969, "Comet S2 Interceptor")
    AddTextEntryByHash(0x38B1637B, "Gauntlet Hellfire Pursuit")
    AddTextEntryByHash(0xE33974C1, "Seashark Patrol")
    AddTextEntryByHash(0x9B3D0B58, "Maverick Air Unit")
    AddTextEntryByHash(0x09A4AEE9, "Iron Mule Air Unit")
    AddTextEntryByHash(0xFE493EAF, "Rhine Interceptor")
    AddTextEntryByHash(0x589196F7, "Rocoto Patrol")
end)

-- Tuning-menu text entries for this pack.
-- Two kinds of key, both defined in data/**/carcols.meta:
--   <modShopLabel>  names an individual PART inside a category
--   <slotNames><name>  renames the CATEGORY header of a VMT_ slot
-- Owned here (not in tstudio_aveh_metadata) so each pack names its own parts.
CreateThread(function()
    ---- PART NAMES  (modShopLabel) ----------------------------------

    -- Call sign digits -- slots A/C/D/E (metadata's original names)
    AddTextEntry("POL_CSIGN0", "0")
    AddTextEntry("POL_CSIGN1", "1")
    AddTextEntry("POL_CSIGN2", "2")
    AddTextEntry("POL_CSIGN3", "3")
    AddTextEntry("POL_CSIGN4", "4")
    AddTextEntry("POL_CSIGN5", "5")
    AddTextEntry("POL_CSIGN6", "6")
    AddTextEntry("POL_CSIGN7", "7")
    AddTextEntry("POL_CSIGN8", "8")
    AddTextEntry("POL_CSIGN9", "9")

    -- Call sign digits -- slot B only (were never registered anywhere)
    AddTextEntry("POL_CSIGN",   "1")
    AddTextEntry("POL_CSIGN2B", "2")
    AddTextEntry("POL_CSIGN3B", "3")
    AddTextEntry("POL_CSIGN5B", "5")
    AddTextEntry("POL_CSIGN6B", "6")
    AddTextEntry("POL_CSIGN7B", "7")
    AddTextEntry("POL_CSIGN8B", "8")

    -- Console / ALPR / dashcam / partitions / trunks
    AddTextEntry("POL_CONS1A",    "Closed Computer Console")
    AddTextEntry("POL_CONS1B",    "Opened Computer Console")
    AddTextEntry("POL_ALPR1A",    "Front Facing Roof ALPR")
    AddTextEntry("POL_ALPR1B",    "Rear Facing Roof ALPR")
    AddTextEntry("POL_ALPR1C",    "Double Facing Roof ALPR")
    AddTextEntry("POL_DASHCAM1A", "Dashcam")
    AddTextEntry("POL_PART1",     "Partition Glass")
    AddTextEntry("POL_PART2",     "Partition Net")
    AddTextEntry("POL_TRUNK1A",   "Messy Trunk")
    AddTextEntry("POL_TRUNK2A",   "Empty Drawers")
    AddTextEntry("POL_TRUNK2B",   "Organized Drawers")

    -- Liveries -- one key per agency (split out of the old shared TS_POL_LIV1)
    AddTextEntry("TS_POL_LIV_LSPD",  "LSPD")
    AddTextEntry("TS_POL_LIV_LSSD",  "LSSD")
    AddTextEntry("TS_POL_LIV_MRPD",  "MRPD")
    AddTextEntry("TS_POL_LIV_SAHP",  "SAHP")
    AddTextEntry("TS_POL_LIV_BP",    "BP")
    AddTextEntry("TS_POL_LIV_EBH",   "EBH")
    AddTextEntry("TS_POL_LIV_FZ",    "FZ")
    AddTextEntry("TS_POL_LIV_MWS",   "MWS")
    AddTextEntry("TS_POL_LIV_NOOSE", "NOOSE")

    -- Console variants C-F (from <linkedModels>)
    AddTextEntry("POL_CONS1C", "Computer Console + Shotgun and Partition")
    AddTextEntry("POL_CONS1D", "Computer Console + Rifle")
    AddTextEntry("POL_CONS1E", "Computer Console + Rifle and Glass Partition")
    AddTextEntry("POL_CONS1F", "Computer Console + Rifle and Net Partition")

    -- Roof antennas
    AddTextEntry("POL_ANTA", "Antenna Type 1")
    AddTextEntry("POL_ANTB", "Antenna Type 2")
    AddTextEntry("POL_ANTC", "Antenna Type 3")
    AddTextEntry("POL_ANTD", "Antenna Type 4")
    AddTextEntry("POL_ANTE", "Antenna Type 5")
    AddTextEntry("POL_ANTF", "Antenna Type 6")
    AddTextEntry("POL_ANTG", "Antenna Type 7")

    -- Pillar spotlights
    AddTextEntry("POL_SLIGHTB", "Spotlight Type 1")
    AddTextEntry("POL_SLIGHTC", "Spotlight Type 2")
    AddTextEntry("POL_SLIGHTD", "Spotlight Type 3")
    AddTextEntry("POL_SLIGHTE", "Spotlight Type 4")
    AddTextEntry("POL_SLIGHTF", "Spotlight Type 5")

    -- Front push bars
    AddTextEntry("POL_PBARA", "Push Bar Type 1")
    AddTextEntry("POL_PBARB", "Push Bar Type 2")
    AddTextEntry("POL_PBARC", "Push Bar Type 3")
    AddTextEntry("POL_PBARD", "Push Bar Type 4")
    AddTextEntry("POL_PBARE", "Push Bar Type 5")
    AddTextEntry("POL_PBARF", "Push Bar Type 6")

    -- Door unit tags
    AddTextEntry("POL_UNITTAG1A", "Door Unit Tag 1")
    AddTextEntry("POL_UNITTAG1B", "Door Unit Tag 2")
    AddTextEntry("POL_UNITTAG1C", "Door Unit Tag 3")

    -- Police bike top boxes
    AddTextEntry("POLBATI_TBD", "Top Box Type 1")
    AddTextEntry("POLBATI_TBE", "Top Box Type 2")
    AddTextEntry("POLBATI_TBF", "Top Box Type 3")
    AddTextEntry("POLBATI_TBG", "Top Box Type 4")

    ---- CATEGORY NAMES  (slotNames -> renames the VMT_ slot header) -

    -- Call sign character slots (VMT_CHASSIS..CHASSIS5)
    AddTextEntry("TOP_CALLSIGNA", "Callsign 1")
    AddTextEntry("TOP_CALLSIGNB", "Callsign 2")
    AddTextEntry("TOP_CALLSIGNC", "Callsign 3")
    AddTextEntry("TOP_CALLSIGND", "Callsign 4")
    AddTextEntry("TOP_CALLSIGNE", "Callsign 5")

    -- Police equipment categories (all 45 vehicles)
    AddTextEntry("TOP_POLANTENNA",  "Antenna")
    AddTextEntry("TOP_POLALPR",     "ALPR")
    AddTextEntry("TOP_POLCONS",     "Console")
    AddTextEntry("TOP_POLDASH",     "Dashboard")
    AddTextEntry("TOP_POLPART",     "Partition")
    AddTextEntry("TOP_PUSH",        "Push Bar")
    AddTextEntry("TOP_SEARCHLIGHT", "Spotlight")

    -- Per-vehicle categories
    AddTextEntry("TOP_MIR",       "Mirrors")
    AddTextEntry("TOP_BODY",      "Body")
    AddTextEntry("TOP_FARI",      "Headlights")
    AddTextEntry("TOP_ARCHCOVER", "Arch Covers")
    AddTextEntry("TOP_BED",       "Bed Cover")
    AddTextEntry("TOP_BULL",      "Bull Bar")
    AddTextEntry("TOP_ENGINE",    "Engine")
    AddTextEntry("TOP_EXH",       "Rear Diffuser")
    AddTextEntry("TOP_HOODLIP",   "Hood Accessories")
    AddTextEntry("TOP_RACK",      "Rack")
    AddTextEntry("TOP_ROOFSC",    "Hood")
    AddTextEntry("TOP_SPARE",     "Spare Wheel")
    AddTextEntry("TOP_SSTEP",     "Side Steps")
end)

local wasInAPC = false
local lastAPC = nil

CreateThread(function()
    while true do
        Wait(200)
        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, false) then
            local vehicle = GetVehiclePedIsIn(ped, false)
            if GetEntityModel(vehicle) == GetHashKey("tstudio_polapc") then
                wasInAPC = true
                lastAPC = vehicle
            end
        else
            if wasInAPC and lastAPC and DoesEntityExist(lastAPC) then
                ClearPedTasksImmediately(ped)
                ClearVehicleTasks(lastAPC)
                wasInAPC = false
                lastAPC = nil
            end
        end
    end
end)
