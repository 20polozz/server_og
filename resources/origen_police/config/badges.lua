Config.PoliceBadgeLength = 3 -- We recommend 3 or 4, more or less will break the badge
Config.OnlyPoliceCanUseBadge = true -- If you want to allow only police to use the badge
Config.ShowBadgePreview = true -- If you want to show the badge preview for the player that uses the badge
Config.NotPoliceCanShowBadge = false -- If you want to allow non-police to show the badge to other players
Config.GenerateBadgeToTheAgent = false -- If you want to generate the badge and give it to the agent directly

Config.CustomBadges = {
    {
        item = "lspd_badge",
        type = "LSPD",
        model = "prop_lspd_badge",
    },
    {
        item = "bcsd_badge",
        type = "BCSD",
        model = "prop_bcso_badge",
    },
    {
        item = "fib_badge",
        type = "FIB",
        model = "prop_fib_badge",
    },
    {
        item = "ems_badge",
        type = "EMS",
        model = "prop_lspd_badge",
    },
    {
        item = "ems_badge",
        type = "SAMS",
        model = "prop_lspd_badge",
    },
    {
        item = "lspd_badge",
        type = "SAPD",
        model = "prop_lspd_badge",
    },
    {
        item = "sapd_badge",
        type = "SAPD",
        model = "prop_lspd_badge",
    },
    {
        item = "lspd_badge",
        type = "SASPA",
        model = "prop_lspd_badge",
    },
    {
        item = "saspa_badge",
        type = "SASPA",
        model = "prop_lspd_badge",
    },
}

function GetBadgeConfig(itemName, type)
    if not itemName and not type then return nil end
    for _, badge in pairs(Config.CustomBadges) do
        if (itemName and badge.item == itemName) or (type and badge.type == type) then
            return badge
        end
    end
    return nil
end