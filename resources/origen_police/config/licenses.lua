Config.UseDefaultSystem = true
Config.DefaultExpireTime = 1893456000 -- 2029-12-31 18:00:00

-- Default Licenses (Only for QBCore)
Config.Licenses = {
    ['driver'] = Config.Translations.LicensesList.Driver,
    ['weapon'] = Config.Translations.LicensesList.Weapon,
    ['business'] = Config.Translations.LicensesList.Business,
    ['hunting'] = Config.Translations.LicensesList.Hunting,
    ['fishing'] = Config.Translations.LicensesList.Fishing,
}

-- Blacklisted Licenses (Only for ESX)
Config.BlackListedLicenses = {
    ["vipLicense"] = true,
}