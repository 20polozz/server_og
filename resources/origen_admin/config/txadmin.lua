Config.TxAdmin = {}
Config.TxAdmin.Enabled = GetResourceState('monitor') ~= "missing" -- If monitor is in the server this will be true, if not, it will be false
Config.TxAdmin.IncludeBans = true -- If true, the script will include all the txAdmin bans in the ban list(If txAdmin is not installed, this will do nothing)
Config.TxAdmin.OverrideDataFolder = "" -- If you want to override the txAdmin data folder location, you can set it here. This is useful if you have txAdmin installed in a different folder than the default one. If you leave it empty, it will use the default txAdmin data folder.