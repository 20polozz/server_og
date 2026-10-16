--[[ Las zonas del cuerpo, por el hueso que registra el motor.

     Estaba en ingles y a medias —"Damaged Hipbone", "Damaged"—, y eso es lo
     que se leia tal cual en el parte del sanitario. Ahora que la pantalla de
     inconsciente tambien enseña las lesiones al propio herido, esto lo lee
     cualquiera, asi que va en castellano.

     Los niveles son UNA sola tabla compartida: son los mismos para todas las
     zonas, y escribirlos veintiuna veces solo garantiza que algun dia digan
     cosas distintas. `updateInjuries` busca levels[valor] y cae en `default`
     cuando ese escalon no existe. ]]
local niveles = {
    ["default"] = "Traumatismo leve",
    ["20"] = "Traumatismo moderado",
    ["30"] = "Traumatismo moderado",
    ["40"] = "Herida de consideracion",
    ["50"] = "Herida de consideracion",
    ["60"] = "Herida grave",
    ["70"] = "Herida grave",
    ["80"] = "Lesion severa",
    ["90"] = "Lesion severa",
    ["100"] = "Lesion critica",
}

return {
    ["0"] = { id = "hip", label = "Cadera", levels = niveles },                        -- hip bone
    ["10706"] = { id = "rclavicle", label = "Clavicula derecha", levels = niveles },   -- right clavicle
    ["64729"] = { id = "lclavicle", label = "Clavicula izquierda", levels = niveles }, -- left clavicle
    ["14201"] = { id = "lfoot", label = "Pie izquierdo", levels = niveles },           -- left foot
    ["18905"] = { id = "lhand", label = "Mano izquierda", levels = niveles },          -- left hand
    ["24816"] = { id = "lbdy", label = "Torax inferior", levels = niveles },           -- lower chest
    ["24817"] = { id = "ubdy", label = "Torax superior", levels = niveles },           -- upper chest
    ["24818"] = { id = "shoulder", label = "Hombro", levels = niveles },               -- shoulder
    ["28252"] = { id = "rforearm", label = "Antebrazo derecho", levels = niveles },    -- right forearm
    ["36864"] = { id = "rleg", label = "Pierna derecha", levels = niveles },           -- right leg
    ["39317"] = { id = "neck", label = "Cuello", levels = niveles },                   -- neck
    ["40269"] = { id = "ruparm", label = "Brazo derecho", levels = niveles },          -- right upper arm
    ["45509"] = { id = "luparm", label = "Brazo izquierdo", levels = niveles },        -- left upper arm
    ["51826"] = { id = "rthigh", label = "Muslo derecho", levels = niveles },          -- right thigh
    ["52301"] = { id = "rfoot", label = "Pie derecho", levels = niveles },             -- right foot
    ["57005"] = { id = "rhand", label = "Mano derecha", levels = niveles },            -- right hand
    ["57597"] = { id = "5lumbar", label = "Quinta lumbar", levels = niveles },         -- waist
    ["58271"] = { id = "lthigh", label = "Muslo izquierdo", levels = niveles },        -- left thigh
    ["61163"] = { id = "lforearm", label = "Antebrazo izquierdo", levels = niveles },  -- left forearm
    ["63931"] = { id = "lleg", label = "Pierna izquierda", levels = niveles },         -- left leg
    ["31086"] = { id = "head", label = "Cabeza", levels = niveles },                   -- head
}
