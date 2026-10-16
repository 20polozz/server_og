Config = {}

--[[ De que es cada localizacion.

     Los nombres dicen QUE HACE cada tipo, no como se llama por dentro. El de
     "model" se llamaba "Modelo" y se entendia como «pon un ped de este
     modelo»: no lo pone, se engancha a uno que YA este ahi —un peaton del
     juego, un ped de otro recurso—, y si no hay ninguno no aparece nada. Con
     ese nombre, elegirlo por error y no ver salir el NPC estaba cantado. ]]
--[[ Si el sitio sale en el mapa, y cuándo.

     Vale para los dos mapas del servidor a la vez —el del juego (minimapa y
     mapa grande) y el del menú de pausa—, porque el del menú de pausa lee los
     blips que hay puestos en el juego.

     `descubrir` es lo de siempre y por eso es lo que se supone cuando una
     localización no dice nada: hasta ahora todas se marcaban al interactuar. ]]
Config.MapModes = {
    ["siempre"]   = "Siempre, desde el principio",
    ["descubrir"] = "Al descubrirla, y ya se queda",
    ["nunca"]     = "Nunca sale en el mapa"
}

Config.MapModeDefault = "descubrir"

Config.LocationsTypes = {
    ["marker"]   = "Un punto en el suelo",
    ["new_npc"]  = "Poner un NPC",
    ["new_prop"] = "Poner un objeto",
    ["model"]    = "Engancharse a un ped que ya esta ahi"
}

Config.SpawnNPCsRadius = 10

-- Radio en el que se crean los NPCs/Props de quest al acercarse el jugador
Config.NPCSpawnRadius   = 80.0
-- Radio en el que se borran los NPCs/Props de quest al alejarse el jugador
Config.NPCDespawnRadius = 100.0

-- Poda 2026-07-19: el listado original arrastraba ~27 entradas apuntando a
-- recursos de la plantilla QBCore base (heists, futbol, airsoft, concesionarios,
-- GoPostal, carreras, hacking minigames externos...) que YA NO EXISTEN en este
-- repo — quedaban seleccionables en el panel pero fallaban en silencio al
-- disparar la misión. Se quitan. Solo quedan las que de verdad funcionan
-- (registradas en client/helper_events.lua o compat QBox) + 3 nuevas con
-- ox_lib.skillCheck (cero dependencias nuevas, ox_lib ya se usa en todo el
-- resource) para tener un "reto" genérico reutilizable en cualquier misión.
Config.TriggerEvents = {
    ["origen_quests:c:heal_ilegal"] = "Médico ilegal",
    ["qb-ambulancejob:reviveFromNPC"] = "Revivir en hospital (camilla más cercana)",
    ['org_progressbar'] = 'Progressbar',
    ['origen_quests:c:secadora'] = 'Abrir secadora',

    ['origen_quests:c:skillcheck_easy'] = 'Reto de habilidad (fácil)',
    ['origen_quests:c:skillcheck_medium'] = 'Reto de habilidad (medio)',
    ['origen_quests:c:skillcheck_hard'] = 'Reto de habilidad (difícil)',
}