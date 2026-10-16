Config.Anticheat = {}
Config.Anticheat.TimeToCollectEvents = 30 -- Time in seconds to recollect events that a player has done
Config.Anticheat.EntitiesPerCollectWatch = 3 -- Max amount of entities that a player can create in the time to not be watched
Config.Anticheat.TimeToWatch = 5 -- Time in seconds to watch an entity
Config.Anticheat.MaxEntityVelocity = 100.0 -- Max velocity that an entity can have in the first 10 seconds to not be marked as warning
Config.Anticheat.BlockAttachmentToOtherPeds = true -- Block other players from attaching entities to other player peds

-- origen_anticheat integration
-- Los admins con el permiso 'Anticheat:Exempt' se excluyen de todos los checks.
-- Cuando un admin activa AdminDuty, se marca su estado para la exención.
Config.Anticheat.AdminExempt = true