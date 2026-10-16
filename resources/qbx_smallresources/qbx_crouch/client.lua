AddStateBagChangeHandler('crouch', ('player:%s'):format(cache.serverId), function(_, _, value, _, replicated)
  if replicated then return end
  lib.requestAnimSet('move_Ped_crouched')
  if not value then
    ResetPedMovementClipset(cache.ped, 1.0)
    ResetPedWeaponMovementClipset(cache.ped)
    ResetPedStrafeClipset(cache.ped)
    SetPedStealthMovement(cache.ped, false, 'DEFAULT_ACTION')
  else
    SetPedMovementClipset(cache.ped, 'move_Ped_crouched', 1.0)
    SetPedStrafeClipset(cache.ped, 'move_Ped_crouched_strafing')
    SetPedStealthMovement(cache.ped, false, 'DEFAULT_ACTION')
  end
  RemoveAnimSet('move_Ped_crouched')
end)

lib.addKeybind({
  name = 'agacharseogn',
  description = 'Agacharse',
  defaultKey = 'LCONTROL',
  onReleased = function(self)
    if cache.vehicle then return end
    -- Con un menu delante (inventario, movil...) el Control es de ese menu: en el
    -- inventario sirve para elegir varios objetos, y el personaje se agachaba cada vez.
    if IsNuiFocused() or IsPauseMenuActive() then return end
    LocalPlayer.state:set("crouch", not LocalPlayer.state.crouch, false)
  end
})


-- Deshabilitar modo sigilo de GTA permanentemente
CreateThread(function()
  while true do
    -- Solo verificar cuando el jugador está a pie (no en vehículo)
    if not cache.vehicle then
      -- Verificar si el jugador está en modo sigilo de GTA
      if GetPedStealthMovement(cache.ped) then
        -- Forzar salida del modo sigilo
        SetPedStealthMovement(cache.ped, false, 'DEFAULT_ACTION')
      end
      Wait(100) -- Verificar cada 100ms es suficiente
    else
      Wait(500) -- En vehículo no es necesario, esperar más tiempo
    end
  end
end)


