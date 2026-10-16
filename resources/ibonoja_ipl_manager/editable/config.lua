--[[
    Default configurations for maps

    When the value in the menu is a checkbox, the possible values will be 0 or 1.
    If it is a scroll value, the values will range from 0 (disabled) to the maximum available in the menu.

    When it is a scroll value, the value assigned to that variant appears in parentheses in the option description.

    CUSTOM YMAPS LISTS:
    For options that use ymaps (like Circuit), you can ADD custom ymaps to the menu.
    These custom ymaps will appear AFTER the default options defined.

    Format: [OptionName]Ymaps = { {label = "Name", ymap = "ymap_name"}, ... }

    Example:
        CircuitYmaps = {
            {label = "Expert Track", ymap = "my_expert_circuit"},
            {label = "Night Track", ymap = "night_circuit"},
        }

    If the map has 4 default options (Off, Pattern 1, Pattern 2, Pattern 3):
        - Circuit = 1 → Off (default)
        - Circuit = 2 → Pattern 1 (default)
        - Circuit = 3 → Pattern 2 (default)
        - Circuit = 4 → Pattern 3 (default)
        - Circuit = 5 → Expert Track (custom) - loads "my_expert_circuit"
        - Circuit = 6 → Night Track (custom) - loads "night_circuit"

    The custom ymaps are ADDED to the existing options, not replaced.

    There is an export to change the variant through code, only available on SERVER.
    To execute it, you must call SetVariant(mapName, optionName, value).
    For example, if you want to change the value of the Sandy Shores room on the LEO Training Center map, you must call
    exports:ibonoja_ipl_manager:SetVariant("LEOTrainingCenter", "SandyRoom", newValue)

    The names for mapName and optionName are the same as those shown below.

    It is very important not to change these names, since it will stop working correctly.
]]

EditableConfig = {
    Menu = {
        Restricted = false, -- false or group name(s) (e.g. "group.admin") or a function that returns a boolean
        --[[

        Restricted = "group.admin", -- If you want to restrict the menu to a specific group
        Restricted = {"group.admin", "group.moderator"}, -- If you want to restrict the menu to more than one group
        Restricted = function(source) -- If you want to restrict the menu based on a function. (true = allowed, false = not allowed)
            return true
        end,

        ]]
    },

    --[[ LEO Training Center Configurations]]
    LEOTrainingCenter = {
        HangarKillHouse = 1,
        HangarHelicopter = 1,
        HangarHelicopterColor = 1, -- Color control for hangar helicopter floor
        BriefingRoom = 1,
        PaletoRoom = 1,
        GreatOceanRoom = 1,
        SandyRoom = 1,
        MissionRowRoom = 1,
        SenoraRoom = 1,
        VespucciRoom = 1,
        VinewoodRoom = 1,
        UnderLeftSection = 1,
        UnderLeftSectionTargets = 1,
        UnderRightSection = 1,
        UnderRightSectionTargets = 1,
        CarGenerator = 1,
        PerimetralFence = 1,
        Circuit = 1,

        --[[ Custom Circuit Ymaps (Optional)
             Add custom ymaps to the Circuit menu. These will appear AFTER the default options.

             Default options from map file (always present):
               1. Off
               2. Pattern 1
               3. Pattern 2
               4. Pattern 3

             Custom ymaps below will be added as options 5, 6, 7, etc.
             Format: Array of {label = "Display Name", ymap = "ymap_name"}

             IMPORTANT: Order matters! The order here determines the menu position.

             Example:
        ]]
        CircuitYmaps = {
            -- Add more custom circuits here:
            -- {label = "Custom Track 1", ymap = "custom_track_1"},         -- Would be option 5
            -- {label = "Custom Track 2", ymap = "custom_track_2"},         -- Would be option 6
        },
    },

    --[[ Mission Row PD Configurations]]
    MRPD = {
        Toilets = 1
    },

    --[[ Senora Station Configurations]]
    SenoraStation = {
        BriefingRoom = 1,
        ExtraRoom = 1,
        DetectiveRoomBlinds = 1,
        WallLogos = 1,
    },

    --[[ Davis Fire Station Configurations ]]
    DavisFireStation = {
        TruckBay = 1,
        TruckBayColor = 1,
        Lights = 1,
        DispatchBlinds = 1,
        MeetingBlinds = 1,
        LivingBlinds = 1,
    },

    --[[ Paleto Substation Configurations ]]
    PaletoSubstation = {
        BriefingRoom = 1,
        BriefingBlinds = 1,
        ReceptionBlinds = 1,
        CentralBlinds = 1,
        ChiefBlinds = 1,
        MeetingBlinds = 1,
        ArmoryBlinds = 1,
        LockerBlinds = 1,
    },

    --[[ Vespucci Substation Configurations ]]
    VespucciSubstation = {
        CentralBlinds = 1,
        MeetingBlinds = 1,
    }
}
