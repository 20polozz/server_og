local utils = {}

--[[ Apartar el HUD del canto derecho mientras hay un panel nuestro abierto.

     El rastreador de misiones de origen_quests y el logo OGN de origen_notify
     viven en la esquina de arriba a la derecha, justo donde cae la columna de
     la gasolinera, y se veian por encima del cristal. Los dos escuchan la misma
     señal, la del menu radial de origen_hud: quien esconde uno esconde el otro,
     no hay que avisar a los dos.

     Ellos solos ya se apartan cuando una interfaz coge el foco del raton, pero
     eso lo miran cada 150 ms; avisando aqui se van en el mismo momento en que
     el panel entra, sin el parpadeo por encima.

     Si el recurso se para con el panel abierto no se queda nadie escondido:
     los dos devuelven el suyo en su onClientResourceStop, que ya nombra a
     origen_fuel. ]]
function ApartarHud(apartar)
    TriggerEvent('qv2:suppressHud', apartar == true)
end

function utils.rotateOffset(offset, rotation)
	local rad = math.rad(rotation)
	local cos = math.cos(rad)
	local sin = math.sin(rad)
	return vec3(offset.x * cos - offset.y * sin, offset.x * sin + offset.y * cos, offset.z)
end

return utils
