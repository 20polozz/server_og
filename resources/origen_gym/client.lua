--[[ Origen Gym, lado cliente.

     · Pone los aparatos de los gimnasios que hay cerca (props locales: cada
       cliente pone los mismos, en el mismo sitio, a partir de lo que dice el
       servidor).
     · Usar un aparato es un escenario del juego colocado en su sitio. Es una
       tarea del personaje y el juego ya se la ensena a los demas: nadie tiene
       que repartir la animacion a mano.
     · El configurador (/gymconfig): crear gimnasios, colocar aparatos mirando
       donde quedan y ajustar la postura de cada tipo con un doble delante. ]]

local TITULO = (OrigenMarca or GetConvar('origen:marca', 'origen')) == 'nacion' and 'Nación Gym' or 'Origen Gym'

local gimnasios, aparatos, posturas, enUso = {}, {}, {}, {}
local objetos = {}     -- [aparato] = el prop
local dentro = {}      -- [gimnasio] = true: sus aparatos estan puestos
local usando = nil     -- { id, escenario, desde, proxima }
local panel = false
local ajustando = false
local senalado = nil
local desdeElHub = false   -- se abrio desde la pestana Scripts del panel de admin
local sobrantes = {}   -- el fantasma y el doble del configurador, por si el recurso se para a medias

local function Aviso(texto, tipo)
    exports.origen_notify:Notify({ title = TITULO, description = texto, type = tipo or 'info', duration = 4500 })
end

local function Coma(v, decimales)
    return (('%.' .. (decimales or 1) .. 'f'):format(v):gsub('%.', ','))
end

-- ---------------------------------------------------------------------------
--  Donde va cada cosa
-- ---------------------------------------------------------------------------

--[[ Lo que llega del servidor viene de la base de datos, y un rumbo de 215
     grados llega como el ENTERO 215, no como 215.0. A un native que espera un
     decimal, un entero le llega como basura (practicamente 0): el personaje
     acababa mirando al norte en todos los aparatos y los props sin girar.
     Recien puestos funcionaban --el numero aun era decimal--, y al reiniciar
     dejaban de hacerlo. Todo lo que entra se pasa a decimal aqui. ]]
local function Decimales(t)
    for _, clave in ipairs({ 'x', 'y', 'z', 'h' }) do
        if t[clave] then t[clave] = t[clave] + 0.0 end
    end
    return t
end

local function Postura(tipo)
    return posturas[tipo] or Config.Tipo[tipo].ped
end

--- Donde se pone el personaje en un aparato. Sin prop, el punto ES ese sitio;
--- con prop, es el prop mas la postura de su tipo, girada con el.
local function PoseDelPed(a, postura)
    if not a.prop then return a.x, a.y, a.z, a.h end
    local p = postura or Postura(a.tipo)
    local r = math.rad(a.h)
    local c, s = math.cos(r), math.sin(r)
    return a.x + p.x * c - p.y * s, a.y + p.x * s + p.y * c, a.z + p.z, (a.h + p.h) % 360
end

--- La animacion de un tipo, segun sea el personaje hombre o mujer.
local function AnimDe(tipo, ped)
    return (not IsPedMale(ped) and tipo.anim.f) or tipo.anim.m
end

--- Pone a un personaje (el jugador o el doble del configurador) a hacer el
--- ejercicio en ese sitio.
local function Ejercitar(ped, tipo, x, y, z, h)
    x, y, z, h = x + 0.0, y + 0.0, z + 0.0, h + 0.0
    if tipo.escenario then
        TaskStartScenarioAtPosition(ped, tipo.escenario, x, y, z, h, 0, false, true)
        return
    end
    local a = AnimDe(tipo, ped)
    if not pcall(lib.requestAnimDict, a[1], 5000) then return end
    FreezeEntityPosition(ped, true)
    SetEntityCoordsNoOffset(ped, x, y, z, false, false, false)
    SetEntityHeading(ped, h)
    TaskPlayAnim(ped, a[1], a[2], 8.0, -8.0, -1, 1, 0.0, false, false, false)
    RemoveAnimDict(a[1])
end

local function Ejercitando(ped, tipo)
    if tipo.escenario then return IsPedUsingScenario(ped, tipo.escenario) end
    local a = AnimDe(tipo, ped)
    return IsEntityPlayingAnim(ped, a[1], a[2], 3)
end

--- A que altura sobre su base esta el origen del prop.
local function Alturas(tipo)
    local base = 0.0
    local hash = joaat(tipo.modelo)
    if IsModelInCdimage(hash) and pcall(lib.requestModel, hash, 8000) then
        local mn = GetModelDimensions(hash)
        base = -mn.z
        SetModelAsNoLongerNeeded(hash)
    end
    return base
end

--[[ La barra, las mancuernas: lo que el juego le pone en las manos a quien hace
     un ejercicio. Al dejarlo, el juego no lo guarda: lo SUELTA, y se queda
     tirado en el suelo para siempre. Asi que se apunta lo que cada uno lleva
     mientras entrena y se borra cuando acaba.

     Esos objetos son locales de cada cliente (cada uno ve los suyos), de modo
     que la limpieza corre en todos, no solo en el de quien entrena. ]]
local llevando = {}    -- [aparato] = { quien, antes = { [obj] = true }, suyo = { [obj] = true } }

--- Lo que un personaje lleva pegado ahora mismo.
local function Agarrado(ped)
    local l = {}
    if ped and ped ~= 0 and DoesEntityExist(ped) then
        for _, o in ipairs(GetGamePool('CObject')) do
            if IsEntityAttachedToEntity(o, ped) then l[o] = true end
        end
    end
    return l
end

local function BorrarSuelto(o)
    if DoesEntityExist(o) then
        SetEntityAsMissionEntity(o, true, true)
        DeleteEntity(o)
    end
end

local function PedDe(quien)
    local jugador = GetPlayerFromServerId(quien)
    return jugador ~= -1 and GetPlayerPed(jugador) or 0
end

--- Apunta lo nuevo que lleva: lo que ya llevaba al empezar (una mochila, lo que
--- le haya puesto otro recurso) no es del ejercicio y no se toca.
local function Apuntar(t)
    for o in pairs(Agarrado(PedDe(t.quien))) do
        if not t.antes[o] then t.suyo[o] = true end
    end
end

local function EmpiezaALlevar(id, quien)
    llevando[id] = { quien = quien, antes = Agarrado(PedDe(quien)), suyo = {} }
end

local function DejaDeLlevar(id)
    local t = llevando[id]
    if not t then return end
    llevando[id] = nil
    Apuntar(t)
    for o in pairs(t.suyo) do BorrarSuelto(o) end
    -- Y otra pasada: si aun lo tenia en la mano, lo suelta un momento despues.
    SetTimeout(1500, function()
        for o in pairs(t.suyo) do BorrarSuelto(o) end
    end)
end

CreateThread(function()
    while true do
        for _, t in pairs(llevando) do Apuntar(t) end
        Wait(next(llevando) and 400 or 1000)
    end
end)

local function QuitarObjeto(id)
    local o = objetos[id]
    objetos[id] = nil
    if o and DoesEntityExist(o) then DeleteEntity(o) end
end

local function PonerObjeto(a)
    QuitarObjeto(a.id)
    local modelo = a.prop and Config.Tipo[a.tipo].modelo
    if not modelo then return end

    local hash = joaat(modelo)
    if not IsModelInCdimage(hash) then return end
    if not pcall(lib.requestModel, hash, 8000) then return end

    -- Cargar el modelo espera: a la vuelta puede que ya no haga falta.
    if aparatos[a.id] ~= a or not dentro[a.gimnasio] or objetos[a.id] then
        SetModelAsNoLongerNeeded(hash)
        return
    end

    local o = CreateObjectNoOffset(hash, a.x, a.y, a.z, false, false, false)
    SetEntityHeading(o, a.h)
    FreezeEntityPosition(o, true)
    SetModelAsNoLongerNeeded(hash)
    objetos[a.id] = o
end

local function Chincheta(g)
    -- El de un negocio ya sale en el mapa con el punto de su negocio.
    if g.negocio then return end
    OrigenMapa.Poner('origen_gym_' .. g.id, {
        x = g.x, y = g.y, z = g.z,
        cat = 'activities', icono = 'gimnasio', nombre = g.nombre,
    })
end

local function EntrarEn(g)
    dentro[g.id] = true
    for _, a in pairs(aparatos) do
        if a.gimnasio == g.id then PonerObjeto(a) end
    end
end

local function SalirDe(id)
    dentro[id] = nil
    for _, a in pairs(aparatos) do
        if a.gimnasio == id then QuitarObjeto(a.id) end
    end
end

-- ---------------------------------------------------------------------------
--  Entrenar
-- ---------------------------------------------------------------------------

local function Dejar()
    local u = usando
    if not u then return end
    usando = nil
    Juego.Parar()
    SendNUIMessage({ a = 'juego_cerrar' })
    pcall(function() exports.origen_hud:HideProgress() end)
    local ped = PlayerPedId()
    ClearPedTasks(ped)
    FreezeEntityPosition(ped, false)
    TriggerServerEvent('origen_gym:soltar')
    exports.origen_notify:HideText()

    --[[ Al levantarse queda metido en el aparato (tumbado en el banco, subido
         a la cinta). En cuanto acaba de salir del ejercicio, vuelve a donde
         estaba de pie al empezar. ]]
    CreateThread(function()
        local tope = GetGameTimer() + 3500
        while u.tipo.escenario and IsPedUsingScenario(ped, u.tipo.escenario) and GetGameTimer() < tope do Wait(50) end
        if usando or IsEntityDead(ped) then return end
        if #(GetEntityCoords(ped) - u.vuelta) < 6.0 then
            SetEntityCoordsNoOffset(ped, u.vuelta.x, u.vuelta.y, u.vuelta.z, false, false, false)
            SetEntityHeading(ped, u.rumbo)
        end
    end)
end

--- El gimnasio es de un negocio y no eres socio: se ofrece la membresia ahi
--- mismo. Devuelve true si la compra (o ya la tenia).
local function HacerseSocio(socio)
    local pregunta = lib.alertDialog({
        header = socio.nombre or 'Gimnasio',
        content = ('Para entrenar aquí hace falta la membresía.\n\n**%d $** · %d %s. Se cobra del banco o, si no llega, en efectivo, y te llevas la tarjeta en el inventario.')
            :format(socio.precio, socio.dias, socio.dias == 1 and 'día' or 'días'),
        centered = true,
        cancel = true,
        labels = { confirm = 'Hacerme socio', cancel = 'Ahora no' },
    })
    if pregunta ~= 'confirm' then return false end

    local r = lib.callback.await('origen_gym:socio', false, socio.gimnasio)
    if r and r.ok then
        Aviso('Ya eres socio. La tarjeta está en tu inventario.', 'success')
        return true
    end
    Aviso(r and r.motivo or 'No se pudo comprar la membresía.', 'error')
    return false
end

local function Usar(a)
    local r = lib.callback.await('origen_gym:ocupar', false, a.id)
    if r and r.socio then
        if not HacerseSocio(r.socio) then return end
        r = lib.callback.await('origen_gym:ocupar', false, a.id)
    end
    if not r or not r.ok then
        if r and r.motivo then Aviso(r.motivo, 'error') end
        return
    end

    local tipo = Config.Tipo[a.tipo]
    local x, y, z, h = PoseDelPed(a)
    local ahora = GetGameTimer()
    local ped = PlayerPedId()
    usando = {
        id = a.id, tipo = tipo, desde = ahora,
        vuelta = GetEntityCoords(ped), rumbo = GetEntityHeading(ped),
        -- Unos segundos para colocarse antes de la primera serie.
        serie = 0, fase = 'pausa', hasta = ahora + 3500,
    }

    Ejercitar(ped, tipo, x, y, z, h)
    exports.origen_notify:DrawText('X', 'Dejar de entrenar')
end

RegisterNetEvent('origen_gym:cl:fuera', Dejar)

--- Lo que sigue suelto mientras se entrena: mirar, hablar y el menu de pausa.
local LIBRES = { 1, 2, 245, 249, 199, 200 }

--- Acaba la serie: la nota del minijuego va al servidor, que dice cuanto ha subido.
local function CerrarSerie(u)
    local nota = Juego.Nota()
    CreateThread(function()
        local r = lib.callback.await('origen_gym:tanda', false, nota)
        if usando ~= u or not r then return end
        if r.ok then
            local habilidad = Config.Habilidades[r.clave] or r.clave
            SendNUIMessage({ a = 'juego_serie', nota = nota,
                texto = ('+%s %s'):format(Coma(r.sube, 2), habilidad),
                total = ('%s %s %%'):format(habilidad, Coma(r.valor)) })
        elseif r.cansado then
            Aviso(('Estás agotado. Descansa unos %d minutos antes de seguir.'):format(r.minutos or 1), 'error')
            Dejar()
        elseif r.fuera then
            Dejar()
        end
    end)
end

--- Mientras se entrena: la tecla de dejarlo, las series y si te han sacado.
local function Entrenando()
    local u = usando
    local ped = PlayerPedId()
    local ahora = GetGameTimer()

    --[[ Las teclas del minijuego son del juego (saltar, las flechas del
         movil...): se apaga todo y se leen como apagadas. Asi, ademas, ninguna
         saca al personaje del ejercicio. ]]
    DisableAllControlActions(0)
    for _, c in ipairs(LIBRES) do EnableControlAction(0, c, true) end

    if IsDisabledControlJustReleased(0, 73) or IsEntityDead(ped) then return Dejar() end

    -- Un empujon, un golpe o un susto cortan el escenario: el aparato se suelta.
    if ahora - u.desde > 4000 and not Ejercitando(ped, u.tipo) then return Dejar() end

    if u.fase == 'serie' then
        Juego.Paso()
        if ahora >= u.hasta then
            u.fase, u.hasta = 'pausa', ahora + Config.Descanso * 1000
            CerrarSerie(u)
        end
    elseif ahora >= u.hasta then
        u.serie = u.serie + 1
        u.fase, u.hasta = 'serie', ahora + Config.Tanda * 1000
        Juego.Empezar(u.tipo.juego, u.tipo.nombre, u.serie)
        -- La barra de progreso de siempre, la del HUD, marca lo que queda de serie.
        pcall(function()
            exports.origen_hud:ShowProgress(Config.Tanda * 1000, ('%s · serie %d'):format(u.tipo.nombre, u.serie))
        end)
    end
end

--- El aparato libre mas cercano que queda al alcance.
local function ElMasCercano()
    local yo = GetEntityCoords(PlayerPedId()) - vector3(0.0, 0.0, 1.0)
    local mejor, cuanto
    for _, a in pairs(aparatos) do
        if dentro[a.gimnasio] and not enUso[a.id] then
            local x, y, z = PoseDelPed(a)
            local d = math.min(#(yo - vector3(a.x, a.y, a.z)), #(yo - vector3(x, y, z)))
            if d < Config.Alcance and (not cuanto or d < cuanto) then mejor, cuanto = a, d end
        end
    end
    return mejor
end

CreateThread(function()
    local cerca, rotulado, mirado = nil, nil, 0

    while true do
        local espera = 500

        if usando then
            espera = 0
            Entrenando()
        elseif next(dentro) and not panel and not ajustando then
            local ahora = GetGameTimer()
            if ahora - mirado > 300 then
                mirado = ahora
                cerca = not IsPedInAnyVehicle(PlayerPedId(), false) and ElMasCercano() or nil
            end

            if cerca then
                espera = 0
                if rotulado ~= cerca.id then
                    rotulado = cerca.id
                    exports.origen_notify:DrawText('E', 'Usar: ' .. Config.Tipo[cerca.tipo].nombre)
                end
                if IsControlJustReleased(0, 38) then
                    local a = cerca
                    cerca, rotulado = nil, nil
                    exports.origen_notify:HideText()
                    Usar(a)
                end
            end
        else
            cerca = nil
        end

        if not cerca and rotulado then
            rotulado = nil
            if not usando then exports.origen_notify:HideText() end
        end

        Wait(espera)
    end
end)

--- Que gimnasios quedan cerca: se ponen y se quitan sus aparatos.
CreateThread(function()
    while true do
        local yo = GetEntityCoords(PlayerPedId())
        for id, g in pairs(gimnasios) do
            local d = #(yo - vector3(g.x, g.y, g.z))
            if not dentro[id] and d < Config.Distancia then
                EntrarEn(g)
            elseif dentro[id] and d > Config.Distancia + 10.0 then
                SalirDe(id)
            end
        end
        Wait(1000)
    end
end)

--[[ Quien entrena no choca con su aparato. Se hace en TODOS los clientes y no
     solo en el suyo: el prop es local de cada uno, y sin esto el personaje de
     otro tiembla contra el banco en la pantalla de quien mira. ]]
CreateThread(function()
    while true do
        local alguno = false
        for id, quien in pairs(enUso) do
            local o = objetos[id]
            local jugador = o and GetPlayerFromServerId(quien) or -1
            if jugador ~= -1 and DoesEntityExist(o) then
                SetEntityNoCollisionEntity(GetPlayerPed(jugador), o, true)
                alguno = true
            end
        end
        Wait(alguno and 0 or 500)
    end
end)

-- ---------------------------------------------------------------------------
--  Las habilidades, aplicadas al personaje
-- ---------------------------------------------------------------------------

--[[ Lo que hace que entrenar sirva de algo. Son las estadisticas del propio
     GTA --aguante al correr, fuerza, punteria-- mas el dano y el aguante cuerpo
     a cuerpo, hasta un 50 % mas con la fuerza al 100.

     Lo hacia prompt_anim_core; al retirarlo (03/10/2026) se quedo aqui, igual. ]]
local function AplicarHabilidades(d)
    if type(d) ~= 'table' then return end
    local jugador = PlayerId()

    -- Sin premio de velocidad: correr mas que los demas no entra en el rol.
    SetRunSprintMultiplierForPlayer(jugador, 1.0)
    SetSwimMultiplierForPlayer(jugador, 1.0)

    StatSetInt(`MP0_STAMINA`, math.floor(tonumber(d.condition) or 0), true)
    StatSetInt(`MP0_STRENGTH`, math.floor(tonumber(d.strength) or 0), true)
    StatSetInt(`MP0_SHOOTING_ABILITY`, math.floor(tonumber(d.shooting) or 0), true)

    local fuerza = 1.0 + ((tonumber(d.strength) or 0) / 100) * 0.5
    SetPlayerMeleeWeaponDamageModifier(jugador, fuerza)
    SetPlayerMeleeWeaponDefenseModifier(jugador, fuerza)
end

RegisterNetEvent('gym:updateGymData', AplicarHabilidades)

-- ---------------------------------------------------------------------------
--  Lo que llega del servidor
-- ---------------------------------------------------------------------------

local MandarDatos

RegisterNetEvent('origen_gym:cl:uso', function(id, quien)
    enUso[id] = quien or nil
    if quien then EmpiezaALlevar(id, quien) else DejaDeLlevar(id) end
end)

RegisterNetEvent('origen_gym:cl:cambio', function(clase, d)
    if clase == 'gimnasio' then
        gimnasios[d.id] = Decimales(d)
        Chincheta(d)
    elseif clase == 'gimnasio_fuera' then
        SalirDe(d)
        gimnasios[d] = nil
        OrigenMapa.Quitar('origen_gym_' .. d)
    elseif clase == 'aparato' then
        aparatos[d.id] = Decimales(d)
        if dentro[d.gimnasio] then PonerObjeto(d) end
    elseif clase == 'aparato_fuera' then
        QuitarObjeto(d)
        aparatos[d] = nil
        enUso[d] = nil
        DejaDeLlevar(d)
    elseif clase == 'postura' then
        posturas[d.tipo] = Decimales(d.p)
    end

    if panel then MandarDatos() end
end)

CreateThread(function()
    while not NetworkIsSessionStarted() do Wait(200) end
    local d = lib.callback.await('origen_gym:datos', false)
    if not d then return end

    for _, g in ipairs(d.gimnasios) do
        gimnasios[g.id] = Decimales(g)
        Chincheta(g)
    end
    for _, a in ipairs(d.aparatos) do aparatos[a.id] = Decimales(a) end
    for tipo, p in pairs(d.posturas) do posturas[tipo] = Decimales(p) end
    for _, u in ipairs(d.enUso) do
        enUso[u[1]] = u[2]
        EmpiezaALlevar(u[1], u[2])
    end
end)

-- ---------------------------------------------------------------------------
--  El configurador: colocar y ajustar mirando
-- ---------------------------------------------------------------------------

--- A donde apunta la camara.
local function Apuntado()
    local o = GetGameplayCamCoord()
    local r = GetGameplayCamRot(2)
    local rx, rz = math.rad(r.x), math.rad(r.z)
    local d = vector3(-math.sin(rz) * math.cos(rx), math.cos(rz) * math.cos(rx), math.sin(rx))
    local f = o + d * 15.0
    local rayo = StartExpensiveSynchronousShapeTestLosProbe(o.x, o.y, o.z, f.x, f.y, f.z, 1 + 16, PlayerPedId(), 4)
    local _, toca, donde = GetShapeTestResult(rayo)
    return toca == 1 and donde or nil
end

local TECLAS = { 14, 15, 16, 17, 10, 11, 172, 173, 174, 175, 38, 47, 73, 21 }

--[[ Colocar un aparato o ajustar la postura de su tipo, viendolo.

     o.tipo    el tipo de aparato
     o.prop    con su prop o solo el punto
     o.pose    de donde se parte (mover uno que ya esta). Sin ella, sigue a la mira.
     o.base    modo postura: el aparato sobre el que se ajusta. Lo que se mueve
               es el doble, no el aparato, y lo que se devuelve es la postura.

     Delante va siempre un doble del propio personaje haciendo el ejercicio:
     es la unica forma de saber si queda bien antes de guardarlo. ]]
local function Ajustar(o)
    local tipo = Config.Tipo[o.tipo]
    local dePostura = o.base ~= nil
    local P, libre

    --[[ Siguiendo la mira, lo que se apoya en el suelo es la BASE del prop, no
         su origen (el del banco esta a media altura). Y sin prop, el punto es
         el propio personaje, a la altura que le toca en ese ejercicio. ]]
    local base = Alturas(tipo)
    local alza = o.prop and base or (base + Postura(o.tipo).z)

    if dePostura then
        local p = Postura(o.tipo)
        P = { x = p.x, y = p.y, z = p.z, h = p.h }
        libre = false
    elseif o.pose then
        P = { x = o.pose.x, y = o.pose.y, z = o.pose.z, h = o.pose.h }
        libre = false
    else
        local yo = GetEntityCoords(PlayerPedId())
        P = { x = yo.x, y = yo.y, z = yo.z - 1.0, h = GetEntityHeading(PlayerPedId()) }
        libre = true
    end

    -- El prop fantasma (colocando) y el doble.
    local fantasma
    if not dePostura and o.prop and tipo.modelo and IsModelInCdimage(joaat(tipo.modelo))
        and pcall(lib.requestModel, joaat(tipo.modelo), 8000) then
        fantasma = CreateObjectNoOffset(joaat(tipo.modelo), P.x, P.y, P.z, false, false, false)
        SetEntityAlpha(fantasma, 190, false)
        SetEntityCollision(fantasma, false, false)
        FreezeEntityPosition(fantasma, true)
        SetModelAsNoLongerNeeded(joaat(tipo.modelo))
    end

    -- Sin congelar ni quitarle la colision: asi se porta igual que un jugador de verdad.
    local doble = ClonePed(PlayerPedId(), false, false, true)
    SetEntityAlpha(doble, 215, false)
    SetEntityInvincible(doble, true)
    SetBlockingOfNonTemporaryEvents(doble, true)
    local contra = fantasma or (o.base and objetos[o.base.id])
    sobrantes = { fantasma, doble }

    local function Controles()
        local lista = {}
        if not dePostura then
            lista[#lista + 1] = { key = 'G', text = libre and 'Fijar aquí y afinar' or 'Volver a seguir la mira' }
        end
        if not libre then
            lista[#lista + 1] = { key = '←↑↓→', text = 'Mover 1 cm' }
        end
        lista[#lista + 1] = { key = 'RePág/AvPág', text = 'Subir / bajar' }
        lista[#lista + 1] = { key = 'Rueda', text = 'Girar' }
        lista[#lista + 1] = { key = 'Shift', text = 'Pasos grandes' }
        lista[#lista + 1] = { key = 'E', text = dePostura and 'Guardar la postura' or 'Poner aquí' }
        lista[#lista + 1] = { key = 'X', text = 'Salir' }
        pcall(function() exports.origen_hud:setupControls(lista) end)
    end
    Controles()

    local function Pulsa(c) return IsDisabledControlJustPressed(0, c) end

    local resultado = nil
    local sucio, cambiado = true, 0

    ajustando = true
    while true do
        Wait(0)
        for _, c in ipairs(TECLAS) do DisableControlAction(0, c, true) end
        if contra and DoesEntityExist(contra) then SetEntityNoCollisionEntity(doble, contra, true) end
        SetEntityNoCollisionEntity(doble, PlayerPedId(), true)

        local grande = IsDisabledControlPressed(0, 21)
        local paso = grande and 0.05 or 0.01
        local giro = grande and 15.0 or 2.0
        local dx, dy, dz, dh = 0.0, 0.0, 0.0, 0.0

        if Pulsa(47) and not dePostura then
            libre = not libre
            Controles()
        end

        if libre then
            local donde = Apuntado()
            if donde and (math.abs(donde.x - P.x) + math.abs(donde.y - P.y) + math.abs(donde.z + alza - P.z)) > 0.002 then
                P.x, P.y, P.z = donde.x, donde.y, donde.z + alza
                sucio = true
            end
        else
            -- Las flechas, respecto de la camara: arriba es alejar, derecha es derecha.
            local rz = math.rad(GetGameplayCamRot(2).z)
            local ax, ay = -math.sin(rz), math.cos(rz)
            if Pulsa(172) then dx, dy = dx + ax * paso, dy + ay * paso end
            if Pulsa(173) then dx, dy = dx - ax * paso, dy - ay * paso end
            if Pulsa(175) then dx, dy = dx + ay * paso, dy - ax * paso end
            if Pulsa(174) then dx, dy = dx - ay * paso, dy + ax * paso end
        end

        if Pulsa(10) then dz = paso end
        if Pulsa(11) then dz = -paso end
        if Pulsa(15) or Pulsa(17) then dh = giro end
        if Pulsa(14) or Pulsa(16) then dh = -giro end

        if dx ~= 0.0 or dy ~= 0.0 or dz ~= 0.0 or dh ~= 0.0 then
            if dePostura then
                -- La postura se guarda en los ejes del prop, no en los del mundo.
                local r = math.rad(o.base.h)
                local c, s = math.cos(r), math.sin(r)
                P.x, P.y = P.x + dx * c + dy * s, P.y - dx * s + dy * c
            else
                P.x, P.y = P.x + dx, P.y + dy
            end
            P.z, P.h = P.z + dz, (P.h + dh) % 360
            sucio = true
        end

        if sucio then
            sucio, cambiado = false, GetGameTimer()
            if fantasma then
                SetEntityCoordsNoOffset(fantasma, P.x, P.y, P.z, false, false, false)
                SetEntityHeading(fantasma, P.h)
            end
        end

        --[[ El doble se recoloca cuando la cosa se queda quieta un momento:
             volver a lanzar el escenario en cada fotograma lo dejaria siempre
             empezando. ]]
        if cambiado ~= 0 and GetGameTimer() - cambiado > 200 then
            cambiado = 0
            local x, y, z, h
            if dePostura then
                x, y, z, h = PoseDelPed(o.base, P)
            else
                x, y, z, h = PoseDelPed({ tipo = o.tipo, prop = o.prop, x = P.x, y = P.y, z = P.z, h = P.h })
            end
            -- Cada vez que se recoloca soltaria otra barra en el suelo.
            for o in pairs(Agarrado(doble)) do BorrarSuelto(o) end
            ClearPedTasksImmediately(doble)
            Ejercitar(doble, tipo, x, y, z, h)
        end

        if Pulsa(38) then resultado = P break end
        if Pulsa(73) then break end
    end
    ajustando = false

    pcall(function() exports.origen_hud:hideControls() end)
    if fantasma then DeleteEntity(fantasma) end
    for o in pairs(Agarrado(doble)) do BorrarSuelto(o) end
    DeleteEntity(doble)
    sobrantes = {}
    return resultado
end

-- ---------------------------------------------------------------------------
--  El configurador: el panel
-- ---------------------------------------------------------------------------

local function HudFuera(fuera)
    TriggerEvent('qv2:suppressHud', fuera)
    pcall(function() exports.origen_hud:toggleHud(not fuera) end)
    if GetResourceState('origen_map') == 'started' then
        pcall(function() exports.origen_map:Apartar(fuera) end)
    end
end

local function Datos()
    local yo = GetEntityCoords(PlayerPedId())
    local cuantos = {}
    local as = {}
    for _, a in pairs(aparatos) do
        cuantos[a.gimnasio] = (cuantos[a.gimnasio] or 0) + 1
        as[#as + 1] = {
            id = a.id, gimnasio = a.gimnasio, tipo = a.tipo, nombre = Config.Tipo[a.tipo].nombre,
            prop = a.prop == true, ocupado = enUso[a.id] ~= nil,
            dist = #(yo - vector3(a.x, a.y, a.z)),
        }
    end
    table.sort(as, function(a, b) return a.dist < b.dist end)

    local gs = {}
    for _, g in pairs(gimnasios) do
        gs[#gs + 1] = {
            id = g.id, nombre = g.nombre, item = g.item or '', aparatos = cuantos[g.id] or 0,
            dist = #(yo - vector3(g.x, g.y, g.z)),
        }
    end
    table.sort(gs, function(a, b) return a.dist < b.dist end)

    local tipos = {}
    for _, t in ipairs(Config.Tipos) do
        local clave, v = next(t.gana)
        tipos[#tipos + 1] = {
            id = t.id, nombre = t.nombre, grupo = t.grupo, conModelo = t.modelo ~= nil,
            gana = ('+%s %s'):format(Coma(v, 2), Config.Habilidades[clave] or clave),
        }
    end

    return { gimnasios = gs, aparatos = as, tipos = tipos, radio = Config.Radio, tope = Config.Topes.aparatos }
end

MandarDatos = function()
    SendNUIMessage({ a = 'datos', datos = Datos() })
end

--- `tarde`: se llega desde el panel de admin, que tarda en apartarse. Si se
--- coge el raton antes, su pantalla de carga se queda con el y no se puede
--- pulsar nada.
local function AbrirPanel(seccion, gimnasio, tarde)
    if panel then return end
    panel = true
    HudFuera(true)
    SendNUIMessage({ a = 'abrir', datos = Datos(), seccion = seccion, gimnasio = gimnasio })
    if tarde then
        CreateThread(function()
            Wait(2800)
            if panel then SetNuiFocus(true, true) end
        end)
    else
        SetNuiFocus(true, true)
    end

    -- La flecha sobre el aparato que se senala en la lista.
    CreateThread(function()
        while panel do
            local a = senalado and aparatos[senalado]
            if a then
                DrawMarker(2, a.x, a.y, a.z + 2.0, 0.0, 0.0, 0.0, 180.0, 0.0, 0.0, 0.3, 0.3, 0.3, 216, 27, 85, 220, true, true, 2, false, nil, nil, false)
            end
            Wait(a and 0 or 200)
        end
    end)
end

--- `sigue`: no es un cierre de verdad, se sale al juego a colocar algo y se
--- vuelve. Solo el cierre de verdad devuelve al panel de admin.
local function CerrarPanel(sigue)
    if not panel then return end
    panel = false
    senalado = nil

    SetNuiFocus(false, false)             -- primero, siempre
    HudFuera(false)

    SetTimeout(280, function()            -- 280 > los 260 de la transicion
        if not panel then SendNUIMessage({ a = 'cerrar' }) end
    end)

    if desdeElHub and not sigue then
        desdeElHub = false
        if GetResourceState('origen_admin') == 'started' then
            exports['origen_admin']:ReturnToScripts()
        end
    end
end

RegisterNUICallback('cerrar', function(_, cb)
    CerrarPanel()
    cb('ok')
end)

RegisterNUICallback('senalar', function(d, cb)
    senalado = tonumber(d.id)
    cb('ok')
end)

--- Marca en el mapa (con su ruta) un gimnasio o un aparato.
RegisterNUICallback('ubicar', function(d, cb)
    cb('ok')
    local t = d.clase == 'aparato' and aparatos[tonumber(d.id) or -1] or gimnasios[tonumber(d.id) or -1]
    if not t then return end
    SetNewWaypoint(t.x, t.y)
    Aviso('Marcado en el mapa.', 'success')
end)

RegisterNUICallback('gimnasio', function(d, cb)
    cb(lib.callback.await('origen_gym:admin:gimnasio', false, d) or { ok = false })
end)

RegisterNUICallback('quitar', function(d, cb)
    cb(lib.callback.await('origen_gym:admin:aparato', false, { op = 'quitar', id = d.id }) or { ok = false })
end)

--- Sale del panel, hace lo que toque mirando al juego y vuelve a donde estaba.
local function ConElJuego(seccion, gimnasio, que)
    CerrarPanel(true)
    CreateThread(function()
        Wait(300)
        que()
        AbrirPanel(seccion, gimnasio)
    end)
end

RegisterNUICallback('colocar', function(d, cb)
    cb('ok')
    local g = gimnasios[tonumber(d.gimnasio) or -1]
    if not g or not Config.Tipo[d.tipo] or ajustando then return end
    local prop = d.prop == true

    ConElJuego('colocar', g.id, function()
        -- Uno detras de otro hasta que se salga: amueblar un gimnasio es poner muchos.
        while true do
            local P = Ajustar({ tipo = d.tipo, prop = prop })
            if not P then break end
            local r = lib.callback.await('origen_gym:admin:aparato', false,
                { op = 'poner', gimnasio = g.id, tipo = d.tipo, prop = prop, x = P.x, y = P.y, z = P.z, h = P.h })
            if r and r.ok then
                Aviso(Config.Tipo[d.tipo].nombre .. ' puesto.', 'success')
            else
                Aviso(r and r.motivo or 'No se pudo poner.', 'error')
            end
        end
    end)
end)

RegisterNUICallback('mover', function(d, cb)
    cb('ok')
    local a = aparatos[tonumber(d.id) or -1]
    if not a or ajustando then return end

    ConElJuego('puestos', a.gimnasio, function()
        -- El de verdad se esconde mientras se mueve su fantasma.
        local o = objetos[a.id]
        if o then SetEntityVisible(o, false, false) end
        local P = Ajustar({ tipo = a.tipo, prop = a.prop, pose = a })
        if o and DoesEntityExist(o) then SetEntityVisible(o, true, false) end
        if not P then return end

        local r = lib.callback.await('origen_gym:admin:aparato', false,
            { op = 'mover', id = a.id, x = P.x, y = P.y, z = P.z, h = P.h })
        if not (r and r.ok) then Aviso(r and r.motivo or 'No se pudo mover.', 'error') end
    end)
end)

RegisterNUICallback('postura', function(d, cb)
    cb('ok')
    local a = aparatos[tonumber(d.id) or -1]
    if not a or not a.prop or ajustando then return end

    ConElJuego('puestos', a.gimnasio, function()
        local P = Ajustar({ tipo = a.tipo, prop = true, base = a })
        if not P then return end

        local r = lib.callback.await('origen_gym:admin:postura', false, { tipo = a.tipo, x = P.x, y = P.y, z = P.z, h = P.h })
        if r and r.ok then
            Aviso(('Postura guardada para todos los aparatos «%s».'):format(Config.Tipo[a.tipo].nombre), 'success')
        else
            Aviso(r and r.motivo or 'No se pudo guardar.', 'error')
        end
    end)
end)

--[[ Las maquinas de un negocio (origen_businesses, Ajustes del panel).

     El panel del negocio se aparta y pide por aqui colocar una maquina nueva
     o mover una suya: es el mismo modo de colocar del configurador, con el
     fantasma del aparato y el doble haciendo el ejercicio. Aqui solo se elige
     el sitio; quien guarda, y quien decide si se puede, es el otro recurso,
     que recibe la respuesta en `origen_businesses:client:gimnasioSitio`
     (nil si se sale sin poner nada). ]]
AddEventHandler('origen_gym:cl:negocio', function(d)
    local function Contestar(P)
        TriggerEvent('origen_businesses:client:gimnasioSitio', P and { x = P.x, y = P.y, z = P.z, h = P.h } or nil)
    end
    if type(d) ~= 'table' or panel or ajustando or usando then return Contestar(nil) end

    CreateThread(function()
        local P
        if d.id then
            local a = aparatos[tonumber(d.id) or -1]
            if a then
                -- El de verdad se esconde mientras se mueve su fantasma.
                local o = objetos[a.id]
                if o then SetEntityVisible(o, false, false) end
                P = Ajustar({ tipo = a.tipo, prop = a.prop, pose = a })
                if o and DoesEntityExist(o) then SetEntityVisible(o, true, false) end
            end
        elseif Config.Tipo[d.tipo] then
            P = Ajustar({ tipo = d.tipo, prop = d.prop == true })
        end
        Contestar(P)
    end)
end)

RegisterCommand(Config.Comando, function()
    if panel or ajustando or usando then return end
    if not lib.callback.await('origen_gym:admin:puede', false) then return end
    desdeElHub = false
    AbrirPanel()
end, false)

--- Como lo abre la pestana Scripts del panel de administracion, igual que el
--- resto de recursos. Si no se puede, el panel de admin ya se aparto: que
--- vuelva, o el jugador se queda sin nada delante.
exports('openManagement', function()
    CreateThread(function()
        local puede = not panel and not ajustando and not usando
            and lib.callback.await('origen_gym:admin:puede', false)
        if not puede then
            if GetResourceState('origen_admin') == 'started' then
                exports['origen_admin']:ReturnToScripts()
            end
            return
        end
        desdeElHub = true
        AbrirPanel(nil, nil, true)
    end)
end)

-- ---------------------------------------------------------------------------

AddEventHandler('onResourceStop', function(recurso)
    if recurso ~= GetCurrentResourceName() then return end

    for id in pairs(objetos) do QuitarObjeto(id) end
    for _, t in pairs(llevando) do
        Apuntar(t)
        for o in pairs(t.suyo) do BorrarSuelto(o) end
    end
    for _, e in pairs(sobrantes) do
        if DoesEntityExist(e) then DeleteEntity(e) end
    end
    for id in pairs(gimnasios) do OrigenMapa.Quitar('origen_gym_' .. id) end
    if usando then
        ClearPedTasks(PlayerPedId())
        exports.origen_notify:HideText()
    end
    if panel then
        SetNuiFocus(false, false)
        HudFuera(false)
    end
    if ajustando then pcall(function() exports.origen_hud:hideControls() end) end
end)
