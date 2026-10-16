---------------------
----  CARRRY  -------
---------------------

RegisterCommand("carry", function()
    exports['origen_inventory']:Carry()
end, false)

RegisterCommand("piggy", function()
    exports['origen_inventory']:Piggyback()
end, false)


---------------------
---- CLOTIHNG -------
---------------------

RegisterCommand('mask', function()
    ToggleClothing('Mask')
end, false)

RegisterCommand('neck', function()
    ToggleClothing('Neck')
end, false)

RegisterCommand('decals', function()
    ToggleClothing('Decals')
end, false)

RegisterCommand('top', function()
    ToggleClothing('Top')
end, false)

RegisterCommand('vest', function()
    ToggleClothing('Vest')
end, false)

RegisterCommand('torso', function()
    ToggleClothing('Torso')
end, false)


RegisterCommand('hat', function()
    ToggleProps('Hat')
end, false)

RegisterCommand('glasses', function()
    ToggleProps('Glasses')
end, false)
