--[[ ═══════════════════════════════════════════════════════════════════════
     EL PRÁCTICO (lado cliente)

     Una sesión = un examen de shared/examenes.lua. Cada fotograma se vigila
     la etapa que toca; al cumplirla se avisa al servidor, que la comprueba
     con su posición del aparato y deja pasar a la siguiente. Mientras tanto:

       · el examinador va hablando (cuadro de arriba en la pantalla),
       · los aros se pintan en el cielo y el siguiente punto va al mapa,
       · el HUD enseña altitud, velocidad, rumbo y hacia dónde queda el
         objetivo, y los puntos que se van perdiendo.

     Los fallos que restan se juntan en `pend` y viajan con el siguiente
     aviso; los que suspenden de golpe (accidente, dejar los mandos, salir de
     la zona, tiempo) se mandan en el momento.
   ═══════════════════════════════════════════════════════════════════════ ]]

local S = nil            -- la sesión en curso
local P = Vuelo.P

--- Borra del mapa lo del examen: la chincheta del punto y el recorrido.
local function MapaFuera()
    OrigenMapa.Quitar('objetivo')
    OrigenMapa.PonerVarios('recorrido', {})
end

local NOMBRES = {
    motor = 'Motor', rodar = 'Rodaje', parar = 'Alineación', despegue = 'Despegue',
    tren = 'Tren de aterrizaje', altitud = 'Ascenso', aro = 'Navegación', estable = 'Vuelo nivelado',
    viraje = 'Viraje de 360°', pasada = 'Pasada baja', toque = 'Toma y despegue', aterrizar = 'Aterrizaje',
    estacionario = 'Estacionario', tomar = 'Toma de precisión', aparcar = 'Aparcar',
}

-- ── Utilidades ────────────────────────────────────────────────────────────

local function Veh()
    if not S then return nil end
    local veh = NetworkDoesNetworkIdExist(S.vehNet) and NetToVeh(S.vehNet) or 0
    if veh ~= 0 and DoesEntityExist(veh) then return veh end
    return nil
end

local function Examinador()
    if not S or not S.pedNet then return nil end
    local ped = NetworkDoesNetworkIdExist(S.pedNet) and NetToPed(S.pedNet) or 0
    if ped ~= 0 and DoesEntityExist(ped) then return ped end
    return nil
end

local function Texto(t)
    t = tostring(t or '')
    return (t:gsub('{nombre}', S and S.alumno or ''))
end

--- El examinador dice algo (el cuadro de arriba).
local function Dice(texto, tono)
    if not S or not texto then return end
    S.ultimoTexto = Texto(texto)
    A.Nui('dice', { quien = S.examinador, texto = S.ultimoTexto, tono = tono })
    PlaySoundFrontend(-1, 'Menu_Accept', 'Phone_SoundSet_Default', true)
end

--- Un fallo que resta puntos. `clave` evita contarlo dos veces en la etapa.
local function Penal(motivo, puntos, clave)
    if not S then return end
    clave = clave or motivo
    if S.e.penales[clave] then return end
    S.e.penales[clave] = true
    S.pend[#S.pend + 1] = { motivo = motivo, puntos = puntos }
    S.historial = S.historial or {}
    S.historial[#S.historial + 1] = { motivo = motivo, puntos = puntos, etapa = S.i, t = GetGameTimer() }
    S.restado = S.restado + puntos
    A.Nui('penal', { motivo = motivo, puntos = puntos })
    PlaySoundFrontend(-1, 'CHECKPOINT_MISSED', 'HUD_MINI_GAME_SOUNDSET', true)
end

local function Suspender(motivo)
    if not S or S.fin then return end
    S.fin = true
    local pend = S.pend
    S.pend = {}
    TriggerServerEvent('origen_aviacion:practico:fallo', motivo, pend)
    -- Si el servidor ya no tenía sesión, no contesta: no dejar el HUD colgado.
    local yo = S
    SetTimeout(8000, function()
        if S == yo then
            S, A.practico = nil, nil
            MapaFuera()
            A.Nui('finPractico')
        end
    end)
end

--[[ Solo IsEntityInAir: la altura sobre el suelo se mide desde el centro del
     aparato, y un reactor grande aparcado ya da 2-3 metros. ]]
local function EnAire(veh)
    return IsEntityInAir(veh)
end

--- La altura de un aro: nunca por debajo del terreno + margen.
local function AlturaAro(e)
    local x, y = e.pos.x, e.pos.y
    local top = GetHeightmapTopZForPosition(x + 0.0, y + 0.0)
    if e.agl then return top + e.agl end
    return math.max(e.pos.z, top + (e.sobre or 60.0))
end

--- El punto al que apunta cada etapa (para el HUD y el mapa), o nil.
local function Objetivo(e)
    if e.tipo == 'aro' then return vec3(e.pos.x, e.pos.y, S.e.z or AlturaAro(e)) end
    if e.tipo == 'pasada' then return e.pos end
    if e.pos then return e.pos end
    if e.tipo == 'aterrizar' or e.tipo == 'toque' then return Vuelo.EnPista(e.hasta - 30.0, 0.0) end
    if e.tipo == 'despegue' then return Vuelo.EnPista(e.antesDe, 0.0) end
    return nil
end

-- ── Marcas en el mundo ────────────────────────────────────────────────────

local ROSA = { 216, 27, 85 }

local function Aro(pos, radio, alfa)
    DrawMarker(6, pos.x, pos.y, pos.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
        radio * 2.0, radio * 2.0, radio * 2.0, ROSA[1], ROSA[2], ROSA[3], alfa, false, true, 2, false, nil, nil, false)
end

--[[ Una marca de tierra tiene que verse desde la cabina a 300 m: un disco
     de un palmo en la arena no se veía (19/09). Columna translúcida de 6 m,
     flecha grande encima y un haz vertical de 60 m que se ve de lejos. ]]
local function Suelo(pos, radio)
    local z = S.e.zSuelo or pos.z
    DrawMarker(1, pos.x, pos.y, z - 0.5, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
        radio * 2.0, radio * 2.0, 6.0, ROSA[1], ROSA[2], ROSA[3], 70, false, false, 2, false, nil, nil, false)
    DrawMarker(25, pos.x, pos.y, z + 0.15, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
        radio * 2.0, radio * 2.0, 1.0, 220, 221, 224, 170, false, false, 2, false, nil, nil, false)
    DrawMarker(2, pos.x, pos.y, z + 9.0, 0.0, 0.0, 0.0, 180.0, 0.0, 0.0,
        5.0, 5.0, 5.0, ROSA[1], ROSA[2], ROSA[3], 230, true, true, 2, false, nil, nil, false)
    DrawLine(pos.x, pos.y, z, pos.x, pos.y, z + 60.0, ROSA[1], ROSA[2], ROSA[3], 255)
end

--- Las dos rayas de la zona de toma, a lo largo de la pista.
local function Zona(desde, hasta)
    local w = Config.Pista.semiancho
    for _, l in ipairs({ -w, w }) do
        local a, b = Vuelo.EnPista(desde, l), Vuelo.EnPista(hasta, l)
        DrawLine(a.x, a.y, a.z + 0.4, b.x, b.y, b.z + 0.4, 60, 220, 120, 255)
    end
    local a1, a2 = Vuelo.EnPista(desde, -w), Vuelo.EnPista(desde, w)
    DrawLine(a1.x, a1.y, a1.z + 0.4, a2.x, a2.y, a2.z + 0.4, 60, 220, 120, 255)
end

local function Marcar(e)
    local t = e.tipo
    if t == 'aro' then
        Aro(vec3(e.pos.x, e.pos.y, S.e.z), e.radio, 170)
        -- El siguiente aro, apagado, para ir preparando el giro.
        local sig = S.examen.etapas[S.i + 1]
        if sig and sig.tipo == 'aro' then
            S.e.zSig = S.e.zSig or AlturaAro(sig)
            Aro(vec3(sig.pos.x, sig.pos.y, S.e.zSig), sig.radio, 55)
        end
    elseif t == 'pasada' then
        local zc = P.z + (e.min + e.max) / 2
        Aro(vec3(e.pos.x, e.pos.y, zc), (e.max - e.min) / 2, 150)
    elseif t == 'rodar' or t == 'parar' or t == 'aparcar' then
        Suelo(e.pos, e.radio)
    elseif t == 'tomar' or t == 'estacionario' then
        Suelo(e.pos, e.radio)
    elseif t == 'aterrizar' or t == 'toque' then
        Zona(e.desde, e.hasta)
    end
end

-- ── El mapa: el camino del examen ─────────────────────────────────────────

--[[ Aqui NO se pone `ruta = true`: el GPS del juego traza caminos por
     CARRETERA, y una linea de asfalto hasta un aro que esta a 400 m de altura
     no lleva a ninguna parte —marea mas que ayuda—. Lo que se marca es el
     punto que toca, latiendo en los dos mapas, y el resto del recorrido solo
     en el mapa GRANDE (`minimapa = false`), para ver la vuelta entera sin
     llenar el minimapa. En el aire se vuela con el rumbo que canta el
     examinador, no siguiendo una raya. ]]

--- Como Objetivo(), pero sin depender de la etapa en curso: vale para
--- cualquier etapa del examen (el mapa solo mira x e y).
local function ObjetivoMapa(e)
    if e.pos then return e.pos end
    if e.tipo == 'aterrizar' or e.tipo == 'toque' then return Vuelo.EnPista(e.hasta - 30.0, 0.0) end
    if e.tipo == 'despegue' then return Vuelo.EnPista(e.antesDe, 0.0) end
    return nil
end

local function PuntoMapa(e)
    local o = Objetivo(e)
    if not o then OrigenMapa.Quitar('objetivo') return end
    OrigenMapa.Poner('objetivo', {
        x = o.x, y = o.y, z = o.z, cat = 'eventos', icono = 'bandera',
        nombre = 'Examen de vuelo · ' .. (NOMBRES[e.tipo] or 'Siguiente'), pulso = true, prioridad = 5, propio = true,
    })
end

--- Lo que queda por delante, en el mapa grande.
local function Recorrido()
    if not S then return end
    local etapas = S.examen.etapas
    local lista = {}
    for i = S.i + 1, #etapas do
        local e = etapas[i]
        local o = ObjetivoMapa(e)
        if o then
            lista[#lista + 1] = {
                id = i, x = o.x, y = o.y, z = o.z, cat = 'eventos',
                icono = (e.tipo == 'aterrizar' or e.tipo == 'aparcar' or e.tipo == 'tomar') and 'bandera' or 'chincheta',
                nombre = ('Examen de vuelo · %d de %d · %s'):format(i, #etapas, NOMBRES[e.tipo] or e.tipo),
                minimapa = false, propio = true,
            }
        end
    end
    OrigenMapa.PonerVarios('recorrido', lista)
end

-- ── Empezar una etapa ─────────────────────────────────────────────────────

local function Etapa(i)
    S.i = i
    local e = S.examen.etapas[i]
    S.e = { t0 = GetGameTimer(), penales = {}, cuenta = 0, fase = 1 }
    if e.tipo == 'aro' then S.e.z = AlturaAro(e) S.e.dMin = 1e9 end
    if e.pos and (e.tipo == 'rodar' or e.tipo == 'parar' or e.tipo == 'aparcar' or e.tipo == 'tomar' or e.tipo == 'estacionario') then
        S.e.zSuelo = A.Suelo(e.pos.x, e.pos.y, e.pos.z + 20.0) or e.pos.z
    end
    Dice(e.texto)
    PuntoMapa(e)
    Recorrido()
    A.Nui('etapa', { i = i, total = #S.examen.etapas, nombre = NOMBRES[e.tipo] or e.tipo })
end

--- La etapa está hecha: avisar al servidor (en otro hilo, que espera).
local function Hecha(fallada)
    if not S or S.enviando or S.fin then return end
    S.enviando = true
    local i, e = S.i, S.examen.etapas[S.i]
    local pend = S.pend
    S.pend = {}
    CreateThread(function()
        local r = lib.callback.await('origen_aviacion:practico:etapa', false, i, { fallada = fallada, penal = pend })
        if not S then return end
        -- `enviando` sigue puesto hasta que arranca la etapa siguiente: si no,
        -- el bucle vería la etapa vieja cumplida y la volvería a mandar.
        if r and r.ok then
            if not fallada then PlaySoundFrontend(-1, 'CHECKPOINT_NORMAL', 'HUD_MINI_GAME_SOUNDSET', true) end
            if r.fin then
                S.fin = true
                if e.bien then Dice(e.bien, 'bien') end
                return
            end
            if e.bien and not fallada then Dice(e.bien, 'bien') Wait(2500) end
            if S and not S.fin then Etapa(i + 1) S.enviando = false end
        elseif r and r.fin then
            S.fin = true
        else
            S.enviando = false
            -- No lo ha dado por bueno: vuelven los descuentos y se repite.
            for _, p in ipairs(pend) do S.pend[#S.pend + 1] = p end
            if r and r.mensaje then Dice(r.mensaje, 'mal') end
            S.e = { t0 = GetGameTimer(), penales = S.e.penales, cuenta = 0, fase = 1, z = S.e.z, dMin = 1e9, zSuelo = S.e.zSuelo }
        end
    end)
end

-- ── Cada tipo de etapa ────────────────────────────────────────────────────
-- Devuelven true (hecha) o 'fallada' (aro saltado: resta y sigue).

local T = {}
local dt = 0.0   -- segundos desde el fotograma anterior

--- La E, aunque otro script la tenga desactivada dentro del aparato.
local function PulsaE()
    return IsControlJustReleased(0, 38) or IsDisabledControlJustReleased(0, 38)
end

function T.motor(e, veh)
    local enMarcha = GetIsVehicleEngineRunning(veh)
    if e.apagar then
        if not enMarcha then A.QuitarAyuda('motor') return true end
        if GetEntitySpeed(veh) < 0.5 and not EnAire(veh) then
            A.Ayuda('motor', 'E', 'Apagar el motor')
            if PulsaE() then
                A.QuitarAyuda('motor')
                SetVehicleEngineOn(veh, false, false, true)
                return true
            end
        end
        return false
    end
    if enMarcha then A.QuitarAyuda('motor') return true end
    if S.e.arrancando then return false end
    A.Ayuda('motor', 'E', 'Comprobaciones y arrancar el motor')
    if PulsaE() then
        A.QuitarAyuda('motor')
        S.e.arrancando = true
        CreateThread(function()
            local ok = lib.progressBar({
                duration = 4500, label = 'Comprobaciones: mandos, combustible, flaps y frenos',
                canCancel = false, disable = { move = true, car = true, combat = true },
            })
            local v = Veh()
            if ok and v then SetVehicleEngineOn(v, true, false, true) end
            if S then S.e.arrancando = false end
        end)
    end
    return false
end

function T.rodar(e, veh)
    return Vuelo.Plano(GetEntityCoords(veh), e.pos) <= e.radio and not EnAire(veh)
end

function T.aparcar(e, veh)
    if Vuelo.Plano(GetEntityCoords(veh), e.pos) > e.radio or EnAire(veh) then S.e.cuenta = 0 return false end
    if GetEntitySpeed(veh) > 0.6 then S.e.cuenta = 0 return false end
    S.e.cuenta = S.e.cuenta + dt
    return S.e.cuenta >= 1.0
end

function T.parar(e, veh)
    local pos = GetEntityCoords(veh)
    if Vuelo.Plano(pos, e.pos) > e.radio or GetEntitySpeed(veh) > 0.6 then S.e.cuenta = 0 return false end
    if math.abs(Vuelo.DifRumbo(GetEntityHeading(veh), e.rumbo)) > 20.0 then
        S.e.cuenta = 0
        S.e.aviso = 'Alinéate con el eje de la pista'
        return false
    end
    S.e.aviso = nil
    S.e.cuenta = S.e.cuenta + dt
    S.e.progreso = math.min(1.0, S.e.cuenta / e.seg)
    return S.e.cuenta >= e.seg
end

function T.despegue(e, veh)
    local pos = GetEntityCoords(veh)
    local aire = IsEntityInAir(veh)
    if not aire and not S.e.despego then
        local sobre = Vuelo.SobrePista(pos, -20.0, P.L + 40.0, 8.0)
        if not sobre and GetEntitySpeed(veh) > 12.0 then Penal('Te sales de la pista en la carrera', 10, 'fuera') end
    end
    if aire and not S.e.despego then
        S.e.despego = true
        local d = Vuelo.AEjes(pos)
        if d > e.antesDe then Penal('Despegue demasiado largo', e.puntos or 10, 'largo') end
    end
    return S.e.despego and GetEntityHeightAboveGround(veh) >= e.agl
end

function T.tren(e, veh)
    if not GetVehicleHasLandingGear(veh) then return true end
    local estado = GetLandingGearState(veh)
    local ok = (e.arriba and estado == 3) or (not e.arriba and estado == 0)
    if ok then return true end
    S.e.aviso = e.arriba and 'Sube el tren (G)' or 'Baja el tren (G)'
    if (GetGameTimer() - S.e.t0) / 1000 > e.seg then
        Penal(e.arriba and 'Tardas en subir el tren' or 'Tardas en bajar el tren', e.puntos or 5, 'tarde')
        if (GetGameTimer() - S.e.t0) / 1000 > e.seg * 2 then return true end
    end
    return false
end

function T.altitud(e, veh)
    local z = GetEntityCoords(veh).z
    local seg = (GetGameTimer() - S.e.t0) / 1000
    if e.tope and seg > e.tope then Penal('Tardas demasiado en coger altura', e.puntos or 5, 'tope') end
    if z >= e.min and z <= e.max and EnAire(veh) then
        S.e.cuenta = S.e.cuenta + dt
        S.e.aviso = nil
    else
        S.e.cuenta = 0
        S.e.aviso = z < e.min and ('Sube: faltan %d m'):format(math.ceil(e.min - z)) or ('Baja: sobran %d m'):format(math.ceil(z - e.max))
    end
    S.e.progreso = math.min(1.0, S.e.cuenta / e.seg)
    return S.e.cuenta >= e.seg
end

function T.aro(e, veh)
    local pos = GetEntityCoords(veh)
    local c = vec3(e.pos.x, e.pos.y, S.e.z)
    local d = #(pos - c)
    if d <= e.radio then return true end
    -- Saltado: se acercó y ya se aleja sin haber entrado.
    if d < S.e.dMin then S.e.dMin = d end
    if S.e.dMin < 260.0 and d > S.e.dMin + 90.0 then
        Penal('Aro saltado', e.puntos or 10, 'saltado')
        Dice('Te has saltado el aro. Sigue al siguiente.', 'mal')
        return 'fallada'
    end
    local dz = pos.z - S.e.z
    S.e.aviso = math.abs(dz) > e.radio and (dz > 0 and ('Aro %d m más abajo'):format(math.floor(dz)) or ('Aro %d m más arriba'):format(math.floor(-dz))) or nil
    return false
end

function T.estable(e, veh)
    if not EnAire(veh) then S.e.cuenta = 0 return false end
    local z = GetEntityCoords(veh).z
    S.e.z0 = S.e.z0 or z
    local alabeo = math.abs(GetEntityRoll(veh))
    if math.abs(z - S.e.z0) > e.alto or alabeo > e.alabeo then
        S.e.fallos = (S.e.fallos or 0) + 1
        S.e.z0 = z
        S.e.cuenta = 0
        S.e.aviso = alabeo > e.alabeo and 'Alas rectas' or 'Mantén la altitud'
        if S.e.fallos >= 3 then Penal('No mantiene el vuelo nivelado', e.puntos or 10, 'nivel') end
        return false
    end
    S.e.aviso = nil
    S.e.cuenta = S.e.cuenta + dt
    S.e.progreso = math.min(1.0, S.e.cuenta / e.seg)
    return S.e.cuenta >= e.seg
end

function T.viraje(e, veh)
    if not EnAire(veh) then return false end
    local h, z = GetEntityHeading(veh), GetEntityCoords(veh).z
    if not S.e.h then S.e.h, S.e.z0, S.e.giro = h, z, 0.0 end
    S.e.giro = S.e.giro + Vuelo.DifRumbo(h, S.e.h)
    S.e.h = h
    if math.abs(z - S.e.z0) > e.alto then
        Penal('Pierde o gana demasiada altura en el viraje', e.puntos or 10, 'altura')
        S.e.aviso = 'Mantén la altitud en el giro'
    else
        S.e.aviso = nil
    end
    if (GetGameTimer() - S.e.t0) / 1000 > e.seg then Penal('Viraje demasiado lento', 5, 'lento') end
    S.e.progreso = math.min(1.0, math.abs(S.e.giro) / 330.0)
    return math.abs(S.e.giro) >= 330.0
end

function T.pasada(e, veh)
    local pos = GetEntityCoords(veh)
    local d, l = Vuelo.AEjes(pos)
    local alto = pos.z - P.z
    local sobre = Vuelo.SobrePista(pos, 0.0, P.L, 10.0)
    if sobre and not IsEntityInAir(veh) then Penal('Has tocado la pista en la pasada', e.puntos or 15, 'toca') end
    if sobre then
        S.e.aviso = alto < e.min and 'Demasiado bajo' or (alto > e.max and 'Demasiado alto' or nil)
    end
    local mitad = P.L * 0.5
    if S.e.dPrev and (S.e.dPrev - mitad) * (d - mitad) <= 0 then
        S.e.dPrev = d
        if math.abs(l) <= e.radio and alto >= e.min and alto <= e.max then return true end
        Penal('Pasada fuera de altura o del eje', e.puntos or 15, 'mal')
        Dice('Esa pasada no vale. Sigue con el circuito.', 'mal')
        return 'fallada'
    end
    S.e.dPrev = d
    return false
end

--[[ Toque con el suelo. Devuelve si acaba de tocar y con qué velocidad
     vertical: la peor de los últimos fotogramas en el aire (la del mismo
     fotograma del toque ya viene frenada por el choque). ]]
local function Contacto(veh)
    local vz = GetEntityVelocity(veh).z
    local aire = IsEntityInAir(veh)
    S.e.vzs = S.e.vzs or {}
    if aire then
        table.insert(S.e.vzs, vz)
        if #S.e.vzs > 8 then table.remove(S.e.vzs, 1) end
    end
    local toca = S.e.aireAntes and not aire
    S.e.aireAntes = aire
    local peor = 0.0
    for _, v in ipairs(S.e.vzs) do if v < peor then peor = v end end
    if toca then S.e.vzs = {} end
    return toca, math.abs(peor)
end

function T.toque(e, veh)
    local pos = GetEntityCoords(veh)
    if S.e.fase == 1 then
        local toca, vz = Contacto(veh)
        if not toca then return false end
        S.e.fase = 2
        local sobre, d = Vuelo.SobrePista(pos, -30.0, P.L + 40.0, 6.0)
        if not sobre then Penal('Toque fuera de la pista', 20, 'fuera')
        elseif d < e.desde or d > e.hasta then Penal('Toque fuera de la zona marcada', 5, 'zona') end
        if vz > (e.vzMax or 5.0) then Penal('Toque demasiado fuerte', e.puntos or 10, 'fuerte') end
        return false
    end
    if not IsEntityInAir(veh) and GetEntitySpeed(veh) < 15.0 then
        Penal('Has parado: era toma y despegue', 10, 'parado')
        S.e.aviso = 'Motor a tope y arriba'
    end
    return IsEntityInAir(veh) and GetEntityHeightAboveGround(veh) > 15.0
end

function T.aterrizar(e, veh)
    local pos = GetEntityCoords(veh)
    if S.e.fase == 1 then
        local toca, vz = Contacto(veh)
        if not toca then return false end
        S.e.fase = 2
        local sobre, d = Vuelo.SobrePista(pos, -30.0, P.L + 40.0, 6.0)
        if not sobre then Suspender('Aterrizaje fuera de la pista.') return false end
        if vz > e.vzDura then Suspender(('Aterrizaje durísimo (%.1f m/s).'):format(vz)) return false end
        if vz > e.vzBlanda then Penal(('Toma fuerte (%.1f m/s)'):format(vz), e.puntos or 10, 'fuerte') end
        if d < e.desde then Penal('Toma larga: fuera de la zona', 10, 'larga')
        elseif d > e.hasta then Penal('Toma corta: antes del umbral', 10, 'corta') end
        return false
    end
    if not Vuelo.SobrePista(pos, -40.0, P.L + 60.0, 4.0) and GetEntitySpeed(veh) > 3.0 then
        Penal('Te sales de la pista frenando', 15, 'sale')
    end
    if IsEntityInAir(veh) then S.e.aviso = 'Mantenlo en el suelo' return false end
    S.e.aviso = 'Frena hasta parar'
    return GetEntitySpeed(veh) < 1.5
end

function T.estacionario(e, veh)
    local pos = GetEntityCoords(veh)
    local agl = GetEntityHeightAboveGround(veh)
    local d = Vuelo.Plano(pos, e.pos)
    if d > e.radio then S.e.cuenta = 0 S.e.aviso = 'Colócate sobre la marca' return false end
    if agl < e.min or agl > e.max then
        S.e.cuenta = 0
        S.e.aviso = agl < e.min and 'Sube un poco' or 'Baja un poco'
        return false
    end
    if GetEntitySpeed(veh) > 2.5 then S.e.cuenta = 0 S.e.aviso = 'Quieto' return false end
    S.e.aviso = nil
    S.e.cuenta = S.e.cuenta + dt
    S.e.progreso = math.min(1.0, S.e.cuenta / e.seg)
    return S.e.cuenta >= e.seg
end

function T.tomar(e, veh)
    local pos = GetEntityCoords(veh)
    local toca, vz = Contacto(veh)
    if toca then
        if vz > (e.vzMax or 2.5) then Penal(('Toma brusca (%.1f m/s)'):format(vz), e.puntos or 10, 'brusca') end
        if Vuelo.Plano(pos, e.pos) > e.radio then
            Penal('Posado fuera de la marca', 5, 'fuera')
            Dice('Fuera de la marca. Levanta un poco y vuelve a posarlo dentro.', 'mal')
        end
    end
    if EnAire(veh) or Vuelo.Plano(pos, e.pos) > e.radio then S.e.cuenta = 0 return false end
    if GetEntitySpeed(veh) > 1.0 then S.e.cuenta = 0 return false end
    S.e.cuenta = S.e.cuenta + dt
    return S.e.cuenta >= 2.0
end

-- ── El bucle ──────────────────────────────────────────────────────────────

local function Hud(veh, e)
    local pos = GetEntityCoords(veh)
    local o = Objetivo(e)
    local obj
    if o then
        local dx, dy = o.x - pos.x, o.y - pos.y
        local rumboA = (math.deg(math.atan(-dx, dy)) + 360.0) % 360.0
        obj = {
            dist = math.floor(math.sqrt(dx * dx + dy * dy)),
            dif = math.floor(Vuelo.DifRumbo(rumboA, GetEntityHeading(veh))),
            alt = (e.tipo == 'aro' or e.tipo == 'pasada') and math.floor(o.z) or nil,
        }
    end
    local tren
    if GetVehicleHasLandingGear(veh) then
        local g = GetLandingGearState(veh)
        tren = g == 0 and 'abajo' or (g == 3 and 'arriba' or 'moviendo')
    end
    local quedan = S.tiempo - (GetGameTimer() - S.inicio) / 1000
    A.Nui('hud', {
        alt = math.floor(pos.z),
        agl = math.floor(GetEntityHeightAboveGround(veh)),
        vel = math.floor(GetEntitySpeed(veh) * 3.6),
        vs = math.floor(GetEntityVelocity(veh).z * 10) / 10,
        rumbo = math.floor((360.0 - GetEntityHeading(veh)) % 360.0),
        obj = obj,
        puntos = math.max(0, 100 - S.restado),
        quedan = math.max(0, math.floor(quedan)),
        aviso = S.e.aviso or S.avisoGlobal,
        progreso = S.e.progreso,
        tren = tren,
        motor = GetIsVehicleEngineRunning(veh),
    })
end

local function Bucle()
    local ultimoHud, anterior = 0, GetGameTimer()
    local sinMandos, fuera = 0.0, 0.0
    local chapa = nil
    while S do
        local ahora = GetGameTimer()
        dt = (ahora - anterior) / 1000
        anterior = ahora
        local veh = Veh()
        if not S.fin then
            if not veh then
                Suspender('El aparato se ha perdido.')
            else
                local e = S.examen.etapas[S.i]
                local ped = cache.ped
                local mando = GetPedInVehicleSeat(veh, -1) == ped
                S.avisoGlobal = nil

                -- Dejar los mandos (menos al final, aparcado).
                if not mando then
                    sinMandos = sinMandos + dt
                    S.avisoGlobal = 'Vuelve a los mandos'
                    if sinMandos > 10.0 then Suspender('Has dejado los mandos.') end
                else
                    sinMandos = 0.0
                end

                -- Golpes y accidente.
                local ch = GetVehicleBodyHealth(veh)
                -- Solo si de verdad ha chocado: la chapa de un avión baja
                -- también a tirones sin tocar nada (hélice, sincronía).
                if chapa and chapa - ch > Config.Practico.golpe and HasEntityCollidedWithAnything(veh) then
                    Penal('Golpe con el aparato', Config.Practico.puntosGolpe, 'golpe' .. ahora)
                end
                chapa = ch
                if IsEntityDead(veh) or GetVehicleEngineHealth(veh) <= 0 or ch < Config.Practico.chapaMinima then
                    Suspender('Accidente: el aparato ha quedado muy dañado.')
                elseif IsEntityDead(ped) then
                    Suspender('Accidente.')
                else
                    local ex = Examinador()
                    if ex and IsEntityDead(ex) then Suspender('El examinador ha resultado herido.') end
                end

                -- Fuera de la zona del examen.
                local pos = GetEntityCoords(veh)
                if Vuelo.Plano(pos, Config.Escuela.centro) > Config.Escuela.radioExamen then
                    fuera = fuera + dt
                    S.avisoGlobal = 'Fuera de la zona del examen: vuelve'
                    if fuera > Config.Practico.fueraMax then Suspender('Te has ido fuera de la zona del examen.') end
                else
                    fuera = 0.0
                end

                -- El tiempo.
                if (ahora - S.inicio) / 1000 > S.tiempo then Suspender('Se ha acabado el tiempo.') end

                -- Rodaje demasiado rápido.
                if e and (e.tipo == 'rodar' or e.tipo == 'parar' or e.tipo == 'aparcar')
                    and not EnAire(veh) and GetEntitySpeed(veh) * 3.6 > Config.Practico.rodajeMax then
                    S.e.rapido = (S.e.rapido or 0.0) + dt
                    S.avisoGlobal = ('En tierra, máximo %d km/h'):format(math.floor(Config.Practico.rodajeMax))
                    if S.e.rapido > 2.0 then Penal('Rodaje demasiado rápido', Config.Practico.puntosRodaje, 'rapido') end
                end

                if e and not S.fin then
                    Marcar(e)
                    if mando and not S.enviando then
                        local r = T[e.tipo] and T[e.tipo](e, veh)
                        if r == true then Hecha(false) elseif r == 'fallada' then Hecha(true) end
                    end
                end

                if ahora - ultimoHud > 150 and e then
                    ultimoHud = ahora
                    Hud(veh, e)
                end
            end
        end
        Wait(0)
    end
end

-- ── Empezar ───────────────────────────────────────────────────────────────

function A.EmpezarPractico(r)
    local ex = Config.Examenes[r.examen]
    if not ex then return end
    S = {
        examen = ex, vehNet = r.veh, pedNet = r.ped,
        examinador = r.examinador, alumno = r.alumno,
        i = 1, e = { penales = {} }, pend = {}, restado = 0,
        inicio = GetGameTimer(), tiempo = r.tiempo or ex.tiempo,
    }
    A.practico = S

    -- Esperar a que el aparato exista aquí.
    local fin = GetGameTimer() + 10000
    while not Veh() and GetGameTimer() < fin do Wait(50) end
    local veh = Veh()
    if not veh then
        A.Aviso('No llega el aparato. Habla otra vez con la instructora.', 'error')
        Suspender('El aparato no llegó.')
        return
    end
    pcall(function() exports.origen_fuel:SetFuel(veh, 100.0) end)
    SetVehicleEngineOn(veh, false, true, true)
    DoScreenFadeOut(400)
    Wait(450)
    TaskWarpPedIntoVehicle(cache.ped, veh, -1)
    --[[ El examinador lo crea el servidor y puede tardar en llegar por red:
         se le va preguntando unos segundos. Sin esto, al primer susto se
         bajaba del avión. ]]
    CreateThread(function()
        local fin2 = GetGameTimer() + 8000
        local ped = Examinador()
        while not ped and GetGameTimer() < fin2 do Wait(100) ped = Examinador() end
        if not ped then return end
        NetworkRequestControlOfEntity(ped)
        local f2 = GetGameTimer() + 1500
        while not NetworkHasControlOfEntity(ped) and GetGameTimer() < f2 do Wait(20) end
        SetBlockingOfNonTemporaryEvents(ped, true)
        SetPedCanBeDraggedOut(ped, false)
        SetPedConfigFlag(ped, 184, true)   -- no se cambia de asiento
        SetPedKeepTask(ped, true)
        SetEntityInvincible(ped, true)
        local v = Veh()
        if v and GetVehiclePedIsIn(ped, false) ~= v then TaskWarpPedIntoVehicle(ped, v, 0) end
    end)
    Wait(300)
    DoScreenFadeIn(600)

    A.Nui('practico', {
        nombre = ex.nombre, aparato = ex.aparato, examinador = S.examinador,
        total = #ex.etapas, tiempo = S.tiempo, aprobado = Config.Practico.aprobado,
    })
    Etapa(1)
    CreateThread(Bucle)
end

RegisterNetEvent('origen_aviacion:practico:resultado', function(r)
    if not S then return end
    S.fin = true
    A.QuitarAyuda('motor')
    MapaFuera()
    if r.aprobado then
        Dice(r.nivelNuevo
            and ('Aprobado. Enhorabuena, {nombre}: ya tienes la licencia %s. La tarjeta está en tu inventario.'):format(r.nivelNuevo:lower())
            or 'Aprobado. Te falta el otro práctico de este nivel para la licencia.', 'bien')
    else
        Dice(r.enAire and 'Examen suspendido. Vuelve al aeródromo, aterriza y deja el aparato.'
            or 'Examen suspendido. Deja el aparato aquí mismo.', 'mal')
    end
    -- Con el aparato en el aire NO se coge el ratón: el cuadro sale solo y se
    -- va solo. En tierra, con botón.
    r.soloVer = r.enAire == true
    A.Nui('resultado', r)
    if not r.enAire then SetNuiFocus(true, true) end
    S = nil
    A.practico = nil
end)

RegisterNetEvent('origen_aviacion:practico:retirado', function()
    MapaFuera()
    A.Nui('finPractico')
end)

RegisterNUICallback('resultadoCerrar', function(_, cb)
    cb({})
    SetNuiFocus(false, false)
end)

--- Abandonar a propósito (cuenta como suspenso).
RegisterCommand('abandonarexamen', function()
    if not S or S.fin then return end
    S.fin = true
    TriggerServerEvent('origen_aviacion:practico:abandonar')
end, false)

AddEventHandler('onResourceStop', function(r)
    if r ~= GetCurrentResourceName() then return end
    A.QuitarAyuda('motor')
end)
