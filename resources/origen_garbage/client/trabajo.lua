--[[ ── La recogida a pie ──────────────────────────────────────────────────────

     De jornada, lo que tienes delante decide qué puedes hacer:
       cubo, bolsa o contenedor del mapa   E sacar una bolsa
       con la bolsa en la mano             E echarla por la trasera del camión
                                           X soltarla (se pierde)
     Con la bolsa no se corre, no se salta ni se pega.

     Cada paso: el servidor dice si se puede y cuánto dura, se hace la
     animación, y el servidor lo vuelve a comprobar al terminar. ]]

Trabajo = {}

local R = Config.Recogida
local B = Config.Bolsa
local TECLA_E, TECLA_X = 38, 73

local TEXTOS = { coger = 'Sacando la bolsa', echar = 'Echando la bolsa', descargar = 'Vaciando el camión' }

-- ── Ejecutar un paso ──────────────────────────────────────────────────────

--- Pide el paso al servidor, anima y lo termina. `mirar` = punto al que girarse.
function Trabajo.Ejecutar(paso, datos, mirar, opciones)
    if L.ocupado then return false end
    opciones = opciones or {}
    L.ocupado = true
    local r = lib.callback.await('origen_garbage:empezar', false, paso, datos or {})
    if not r or not r.ok then
        L.ocupado = false
        if r and r.mensaje then L.Aviso(r.mensaje, 'error') end
        return false
    end
    if mirar then
        TaskTurnPedToFaceCoord(cache.ped, mirar.x + 0.0, mirar.y + 0.0, mirar.z + 0.0, 500)
        Wait(450)
    end
    if opciones.antes then opciones.antes(r.ms) end
    local anim = opciones.anim
    local hecho = lib.progressCircle({
        duration = r.ms,
        label = TEXTOS[paso] or 'Trabajando',
        position = 'bottom',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true, sprint = true },
        anim = anim and { dict = anim.dict, clip = anim.clip, flag = anim.flag or 1 } or nil,
    })
    if not hecho then
        lib.callback.await('origen_garbage:cancelar', false)
        L.ocupado = false
        if opciones.despues then opciones.despues(false) end
        return false
    end
    local fin = lib.callback.await('origen_garbage:terminar', false, paso)
    L.ocupado = false
    if opciones.despues then opciones.despues(fin and fin.ok) end
    if not fin or not fin.ok then
        if fin and fin.mensaje then L.Aviso(fin.mensaje, 'error') end
        return false
    end
    if fin.mensaje then L.Aviso(fin.mensaje, 'success') end
    return true, fin
end

local function Lanzar(paso, datos, mirar, opciones)
    L.QuitarAyuda('trabajo')
    CreateThread(function() Trabajo.Ejecutar(paso, datos, mirar, opciones) end)
end

-- ── La bolsa en la mano ───────────────────────────────────────────────────

--[[ La bolsa se pinta en la mano de TODOS los que la llevan (la state bag
     basuraBolsa de cada jugador): así se ve también a los compañeros. ]]
local enMano = {}   -- [serverId] = ent

local function PonerBolsa(sid, ped)
    if enMano[sid] and DoesEntityExist(enMano[sid]) then return end
    if not Dibujo.Cargar(B.modelo) then return end
    local c = GetEntityCoords(ped)
    local ent = Rastro.Marcar(CreateObject(GetHashKey(B.modelo), c.x, c.y, c.z, false, false, false))
    SetEntityCollision(ent, false, false)
    local m = B.mano
    AttachEntityToEntity(ent, ped, GetPedBoneIndex(ped, m.hueso), m.pos.x, m.pos.y, m.pos.z, m.rot.x, m.rot.y, m.rot.z,
        true, true, false, true, 1, true)
    enMano[sid] = ent
end

local function QuitarBolsa(sid)
    Dibujo.Borrar(enMano[sid])
    enMano[sid] = nil
end

CreateThread(function()
    while true do
        local vistos = {}
        for _, id in ipairs(GetActivePlayers()) do
            local sid = GetPlayerServerId(id)
            local ped = GetPlayerPed(id)
            if Player(sid).state.basuraBolsa and ped ~= 0 and #(GetEntityCoords(ped) - GetEntityCoords(cache.ped)) < 120.0 then
                vistos[sid] = true
                PonerBolsa(sid, ped)
            end
        end
        for sid in pairs(enMano) do
            if not vistos[sid] then QuitarBolsa(sid) end
        end
        Wait(400)
    end
end)

--[[ El portón de atrás (la trampilla con la pala, puerta 5 del camión): se
     abre solo al llegar a la trasera con una bolsa y se cierra al apartarse.
     Se pide el control del camión para que lo vean abrirse todos. ]]
CreateThread(function()
    local abierto, cerrarEn = nil, 0
    while true do
        local espera = 400
        local quiere = nil
        if L.Jornada() and L.ConBolsa() and not cache.vehicle then
            local _, veh = Vehiculos.TraseraCerca(4.5)
            quiere = veh
        end
        if quiere then
            espera = 100
            cerrarEn = GetGameTimer() + 1500
            if abierto ~= quiere or GetVehicleDoorAngleRatio(quiere, 5) < 0.5 then
                NetworkRequestControlOfEntity(quiere)
                SetVehicleDoorOpen(quiere, 5, false, false)
                abierto = quiere
            end
        elseif abierto and GetGameTimer() > cerrarEn then
            if DoesEntityExist(abierto) then
                NetworkRequestControlOfEntity(abierto)
                SetVehicleDoorShut(abierto, 5, false)
            end
            abierto = nil
        end
        Wait(espera)
    end
end)

--- Andar con la bolsa: sin correr, saltar ni pegar, y el andar de llevarla.
CreateThread(function()
    while true do
        if L.ConBolsa() and not cache.vehicle then
            if not L.ocupado and not IsEntityPlayingAnim(cache.ped, B.llevar.dict, B.llevar.clip, 3) and Dibujo.Anim(B.llevar.dict) then
                TaskPlayAnim(cache.ped, B.llevar.dict, B.llevar.clip, 8.0, -8.0, -1, B.llevar.flag, 0, false, false, false)
            end
            for _, c in ipairs({ 21, 22, 24, 25, 140, 141, 142, 257, 263, 264 }) do DisableControlAction(0, c, true) end
            Wait(0)
        else
            if IsEntityPlayingAnim(cache.ped, B.llevar.dict, B.llevar.clip, 3) then
                StopAnimTask(cache.ped, B.llevar.dict, B.llevar.clip, 2.0)
            end
            Wait(300)
        end
    end
end)

-- ── Lo que tienes delante ─────────────────────────────────────────────────

--[[ Los cubos del mapa cerca: se miran cada 300 ms en la lista de objetos
     (no en cada fotograma, que es lo que pesaba en el basurero de antes).
     Devuelve el más cercano de la lista de Config.Modelos. ]]
local objetivo = nil

CreateThread(function()
    while true do
        local espera = 800
        objetivo = nil
        if L.Jornada() and not cache.vehicle and not L.ConBolsa() and not L.panelAbierto then
            espera = 300
            local pos = GetEntityCoords(cache.ped)
            local mejor, dMejor = nil, R.distancia
            for _, o in ipairs(GetGamePool('CObject')) do
                local c = GetEntityCoords(o)
                local dx, dy = c.x - pos.x, c.y - pos.y
                if dx * dx + dy * dy <= 16.0 and math.abs(c.z - pos.z) < 3.0 then
                    local hash = GetEntityModel(o)
                    local tipo = Basura.Tipo(hash)
                    -- Los cubos y contenedores del mapa son dinámicos: con la
                    -- animación de sacar la bolsa se empujaban, el juego los
                    -- soltaba con física (se tumbaban) y volvía a poner el
                    -- original en su sitio, y parecían duplicarse (29/09).
                    -- Quietos mientras se trabaja a su lado.
                    if tipo and tipo ~= 'bolsa' and not IsEntityPositionFrozen(o) then FreezeEntityPosition(o, true) end
                    if tipo and IsEntityVisible(o) and not IsEntityAttached(o) and not DecorExistOn(o, 'origen_garbage') then
                        local d = math.sqrt(dx * dx + dy * dy)
                        if d <= dMejor then mejor, dMejor = { ent = o, hash = hash, tipo = tipo, pos = c }, d end
                    end
                end
            end
            objetivo = mejor
        end
        Wait(espera)
    end
end)

--- ¿Hay un cubo delante? (el camión no enseña su tarjeta encima de la del cubo)
function Trabajo.HayObjetivo() return objetivo ~= nil end

--- La trasera del camión del equipo más cercana a menos de `metros`.
local function TraseraCerca(metros)
    return Vehiculos.TraseraCerca and Vehiculos.TraseraCerca(metros)
end

CreateThread(function()
    while true do
        local espera = 500
        local quiero, puesta = nil, nil
        if L.Jornada() and not cache.vehicle and not L.panelAbierto and not L.ocupado then
            local pos = GetEntityCoords(cache.ped)
            if L.ConBolsa() then
                espera = 0
                local trasera, veh = TraseraCerca(2.6)
                if trasera then
                    quiero = { 'E', 'Echar la bolsa al camión', { 'X', 'Soltarla' } }
                    if IsControlJustReleased(0, TECLA_E) then
                        Lanzar('echar', {}, trasera, { anim = B.tirar })
                    end
                else
                    quiero = { 'X', 'Soltar la bolsa' }
                    puesta = 'bolsa'
                    L.Tarjeta('bolsa', { aviso = 'Llévala a la trasera del camión.' })
                end
                if IsControlJustReleased(0, TECLA_X) then
                    CreateThread(function()
                        local r = lib.callback.await('origen_garbage:soltar', false)
                        if r and r.ok then L.Aviso('Has soltado la bolsa.', 'inform') end
                    end)
                end
            elseif objetivo then
                espera = 0
                local o = objetivo
                local k = Basura.Clave(o.hash, o.pos.x, o.pos.y)
                local v = L.Vaciado(k)
                local def = Config.Tipos[o.tipo]
                local aro = { 60, 200, 110, 140 }
                if v and v.q <= 0 then
                    aro = { 200, 80, 60, 120 }
                    puesta = 'cubo'
                    L.Tarjeta('cubo', { nombre = def.nombre, quedan = 0, total = def.bolsas,
                        aviso = ('Vacío: vuelve a llenarse en %s.'):format(Basura.Duracion((v.hasta - GetGameTimer()) / 1000)) })
                else
                    local quedan = v and v.q or def.bolsas
                    puesta = 'cubo'
                    L.Tarjeta('cubo', { nombre = def.nombre, quedan = quedan, total = def.bolsas, aviso = nil,
                        pago = L.yo and L.yo.pago or Config.Descarga.pago })
                    quiero = { 'E', def.bolsas > 1 and ('Sacar una bolsa (%d)'):format(quedan) or 'Recoger la basura' }
                    if IsControlJustReleased(0, TECLA_E) then
                        Lanzar('coger', { hash = o.hash, x = o.pos.x, y = o.pos.y, z = o.pos.z }, o.pos,
                            { anim = o.tipo == 'bolsa' and B.coger or B.cubo })
                    end
                end
                local suelo = Dibujo.Suelo(o.pos.x, o.pos.y, o.pos.z) or (o.pos.z - 0.5)
                Dibujo.Aro(vec3(o.pos.x, o.pos.y, suelo), o.tipo == 'contenedor' and 1.6 or 0.8, 0.1, aro)
            end
        end
        if quiero then
            L.Ayuda('trabajo', quiero[1], quiero[2], quiero[3])
        else
            L.QuitarAyuda('trabajo')
        end
        if puesta ~= 'bolsa' then L.SinTarjeta('bolsa') end
        if puesta ~= 'cubo' then L.SinTarjeta('cubo') end
        Wait(espera)
    end
end)

AddEventHandler('onResourceStop', function(r)
    if r ~= GetCurrentResourceName() then return end
    for sid in pairs(enMano) do QuitarBolsa(sid) end
end)
