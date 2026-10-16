--[[ Ajuste en vivo del encuadre del retrato.

     Se abre con /camara mientras tienes un personaje seleccionado. Mueve la
     camara con el teclado, lo ves al momento, y al guardar deja los valores en
     config/camara_cara.json, que se carga solo al arrancar el recurso.

     Mientras esta abierto se le quita el foco a la NUI para que las teclas
     lleguen al juego; al cerrarlo se devuelve. ]]

local ajustando = false

--[[ Velocidades en unidades POR SEGUNDO, no por fotograma: multiplicando por
     GetFrameTime() se mueve igual a 60 fps que a 144, y sobre todo se puede
     afinar. Antes iba por fotograma y a 60 fps se le escapaba a cualquiera. ]]
local VEL = { normal = 0.05, fino = 0.008 }        -- metros por segundo
local VEL_FOV = { normal = 3.0, fino = 0.5 }       -- grados por segundo

local function paso(fino)
    return (fino and VEL.fino or VEL.normal) * GetFrameTime()
end

local function pasoFov(fino)
    return (fino and VEL_FOV.fino or VEL_FOV.normal) * GetFrameTime()
end

--- Vista que se esta retocando: siempre la que el jugador tiene puesta.
local function actual()
    return CAMARAS[VistaActual]
end

local function guardar()
    local todo = {}
    for _, vista in ipairs(VISTAS) do
        local c = CAMARAS[vista]
        todo[vista] = {
            altura = c.altura, distancia = c.distancia,
            lateral = c.lateral, angulo = c.angulo, fov = c.fov,
        }
    end
    TriggerServerEvent('origen_titlemenu:server:GuardarCamaras', todo)
end

local function texto(x, y, escala, cadena, resaltado)
    SetTextFont(4)
    SetTextScale(escala, escala)
    SetTextColour(resaltado and 209 or 255, resaltado and 33 or 255, resaltado and 142 or 255, 230)
    SetTextOutline()
    SetTextEntry("STRING")
    AddTextComponentString(cadena)
    DrawText(x, y)
end

local NOMBRES = { cara = 'CARA', cuerpo = 'CUERPO ENTERO' }

local function panel()
    local c = actual()
    -- El recuadro tiene que cubrir todo el texto: antes se quedaba corto y la
    -- ficha del personaje se transparentaba por debajo.
    DrawRect(0.195, 0.368, 0.31, 0.475, 0, 0, 0, 190)

    texto(0.055, 0.145, 0.45, "AJUSTE DE CAMARA - " .. (NOMBRES[VistaActual] or '?'), true)
    texto(0.055, 0.183, 0.30, "1 cara      2 cuerpo entero      TAB siguiente")

    texto(0.055, 0.225, 0.34, ("Altura      %.3f"):format(c.altura))
    texto(0.055, 0.255, 0.34, ("Distancia   %.3f"):format(c.distancia))
    texto(0.055, 0.285, 0.34, ("Lateral     %.3f"):format(c.lateral))
    texto(0.055, 0.315, 0.34, ("Angulo      %.1f"):format(c.angulo))
    texto(0.055, 0.345, 0.34, ("FOV         %.1f"):format(c.fov))

    texto(0.055, 0.385, 0.30, "Flechas arriba/abajo   subir / bajar")
    texto(0.055, 0.410, 0.30, "Flechas izq./der.      girar alrededor")
    texto(0.055, 0.435, 0.30, "Q / E                  acercar / alejar")
    texto(0.055, 0.460, 0.30, "A / D                  mover a los lados")
    texto(0.055, 0.485, 0.30, "Z / X                  abrir / cerrar FOV")
    texto(0.055, 0.510, 0.30, "Shift                  seis veces mas fino")
    texto(0.055, 0.540, 0.32, "INTRO  guardar y salir     ESC  salir sin guardar", true)
end

--[[ Se entra desde la interfaz con F2, no por comando: en el menu de personajes
     no hay chat, y ademas la NUI tiene el foco del teclado, asi que las teclas
     ni llegarian al juego. La interfaz escucha F2, avisa por aqui, y entonces
     se suelta el foco para que las flechas si lleguen. ]]
function AbrirAjusteCamara()
    if ajustando then return end

    local ped = PedRetratado()
    if not ped or not DoesEntityExist(ped) then
        print('^3[origen_titlemenu] Elige antes un personaje: el ajuste actua sobre el retrato.^0')
        return
    end

    -- Copia de las TRES vistas, para poder deshacer si sales con ESC.
    local previo = {}
    for _, vista in ipairs(VISTAS) do
        local c = CAMARAS[vista]
        previo[vista] = { altura = c.altura, distancia = c.distancia,
                          lateral = c.lateral, angulo = c.angulo, fov = c.fov }
    end
    local vistaInicial = VistaActual
    local guardado = false

    ajustando = true
    SetNuiFocus(false, false)      -- las teclas tienen que llegar al juego

    CreateThread(function()
        while ajustando do
            local ped = PedRetratado()
            if not ped or not DoesEntityExist(ped) then break end

            --[[ Cambiar de vista. 157 y 158 son las teclas 1 y 2 (antes
                 puse 160 para el 3, que en realidad es el 4). Se admiten
                 tambien pulsadas con los controles deshabilitados, y TAB para
                 ir pasando de una a otra sin acordarse de los numeros. ]]
            local pulsada = function(control)
                return IsControlJustPressed(0, control) or IsDisabledControlJustPressed(0, control)
            end

            if pulsada(157) then CambiarVista('cara') end
            if pulsada(158) then CambiarVista('cuerpo') end

            if pulsada(37) then                          -- TAB: siguiente vista
                local i = 1
                for n, v in ipairs(VISTAS) do
                    if v == VistaActual then i = n break end
                end
                CambiarVista(VISTAS[(i % #VISTAS) + 1])
            end

            local c = actual()
            local fino = IsControlPressed(0, 21)      -- Shift
            local p = paso(fino)
            local pg = (fino and 6.0 or 40.0) * GetFrameTime()   -- grados por segundo
            local pf = pasoFov(fino)
            local cambiado = false

            if IsControlPressed(0, 172) then c.altura = c.altura + p; cambiado = true end        -- arriba
            if IsControlPressed(0, 173) then c.altura = c.altura - p; cambiado = true end        -- abajo
            if IsControlPressed(0, 174) then c.angulo = (c.angulo - pg) % 360; cambiado = true end -- girar izq.
            if IsControlPressed(0, 175) then c.angulo = (c.angulo + pg) % 360; cambiado = true end -- girar der.
            if IsControlPressed(0, 44)  then c.distancia = math.max(0.15, c.distancia - p); cambiado = true end -- Q
            if IsControlPressed(0, 38)  then c.distancia = c.distancia + p; cambiado = true end   -- E
            if IsControlPressed(0, 34)  then c.lateral = c.lateral - p; cambiado = true end       -- A
            if IsControlPressed(0, 30)  then c.lateral = c.lateral + p; cambiado = true end       -- D
            if IsControlPressed(0, 20)  then c.fov = math.min(70.0, c.fov + pf); cambiado = true end -- Z
            if IsControlPressed(0, 73)  then c.fov = math.max(8.0,  c.fov - pf); cambiado = true end -- X

            if cambiado then RefrescarCamaraCara(ped) end

            if IsControlJustPressed(0, 201) then          -- Intro: guardar y salir
                guardar()
                guardado = true
                ajustando = false
            end

            if IsControlJustPressed(0, 202) then          -- Esc: salir sin guardar
                ajustando = false
            end

            panel()
            Wait(0)
        end

        -- Al salir con ESC se deshacen los cambios de las tres vistas: si no,
        -- quedarian movidos en esta sesion aunque no los hubieras guardado.
        if not guardado then
            for vista, valores in pairs(previo) do
                for k, v in pairs(valores) do CAMARAS[vista][k] = v end
            end
            VistaActual = vistaInicial
            local ped = PedRetratado()
            if ped and DoesEntityExist(ped) then IniciarCamaraCara(ped) end
        end

        ajustando = false
        SetNuiFocus(true, true)                           -- devolver el raton al menu
    end)
end

RegisterNUICallback('AjustarCamara', function(_, cb)
    AbrirAjusteCamara()
    cb(true)
end)

-- Por si algun dia hay chat disponible en esta pantalla.
RegisterCommand('camara', AbrirAjusteCamara, false)

RegisterNetEvent('origen_titlemenu:client:CamarasGuardadas', function(ok, motivo)
    if ok then
        print('^2[origen_titlemenu] Encuadres guardados en config/camaras.json^0')
    else
        print('^1[origen_titlemenu] No se han podido guardar: ' .. tostring(motivo) .. '^0')
    end
end)

--- La interfaz pide cambiar de vista (los iconos de la derecha).
RegisterNUICallback('CamaraVista', function(data, cb)
    cb(CambiarVista(data and data.vista or 'cara'))
end)
