Config.Commands = {
    OpenMenu = {
        enable = false, -- Desactivado, se usa el punto de interacción
        command = 'gangwars',
    },
    CreateCode = {
        command = 'createcode',
        group = 'group.admin',
    },
    AdminPanel = {
        command = nil, -- Desactivado: panel admin solo desde Origen Hub
        group = 'group.admin',
    }
}

-- NPC de Gang Wars
Config.MenuLocation = {
    coords = vector4(2340.57, 3126.54, 48.21, 347.45),
    npc = {
        model = 'g_m_y_salvagoon_03', -- Gángster Salvadoreño (estilo ilegal)
        scenario = 'WORLD_HUMAN_SMOKING', -- Fumando
    },
    blip = {
        enable = true,
        sprite = 84, -- Calavera
        color = 4, -- Rosa
        scale = 0.8,
        label = 'Guerras de bandas'
    },
    target = {
        icon = 'fas fa-skull-crossbones',
        label = 'Hablar con el organizador',
        distance = 5.0
    }
}