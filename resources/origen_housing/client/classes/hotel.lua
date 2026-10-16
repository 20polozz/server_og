HotelData = {}

Hotel = {}
Hotel.__index = Hotel
Hotel.table = {}

function Hotel.new(data)
    local self = Hotel.table[data.id]

    if not self then
        self = setmetatable({}, Hotel)
        Hotel.table[data.id] = self
        self.blipHandle = nil
        self.entryPoint = nil
    end
    
    self.id = data.id
    self.name = data.name
    self.coords = data.coords
    self.blip = data.blip
    self.reception_coords = data.reception_coords
    self.rental_options = data.rental_options
    self.auto_renew_available = data.auto_renew_available
    
    self.blipHandle = nil
    self.entryPoint = nil

    if self.receptionPoint then
        self.receptionPoint:remove()
        self.receptionPoint = nil
    end

    Hotel.table[self.id] = self
    HotelData[self.id] = data

    return self
end

function Hotel.get(id)
    id = tonumber(id)
    return Hotel.table[id] or false
end

function Hotel:CreateHotel()
    if self.blip and self.blip.enabled then
        self:CreateBlip()
    end

    self:CreateReceptionPoint()
end

function Hotel:CreateBlip()
    local clave = 'hotel_' .. tostring(self.id)

    if not self.blip or not self.blip.enabled then
        Utils.QuitarDelMapa(clave)
        return
    end

    --- El sprite y el color del panel ya no pintan nada: en los mapas del
    --- servidor la chincheta es dibujo nuestro. El interruptor si manda.

    --[[ Tu hotel: donde tienes una habitacion alquilada. Sale en el rosa de lo
         tuyo y el nombre dice cual es, que es lo que se busca en el mapa
         cuando no te acuerdas de donde dormias. ]]
    local mia = Hotel.MiHabitacion(self.id)
    local nombre = self.name
    if mia then
        nombre = ('%s · tu habitación %s'):format(self.name or 'Hotel', tostring(mia.room_number or mia.id))
    end

    self.blipHandle = Utils.MarcarEnMapa(clave, self.coords, nombre, nil, {
        icono = 'hotel',
        mia = mia and true or false,
    })
end

--[[ La habitacion de este hotel que tienes alquilada, o nil.

     `rented_by` llega en cada habitacion y el identificador del jugador lo
     guarda main.lua en `playerIdentifier` (puede no estar todavia al entrar:
     entonces no hay «tuya» hasta que se refresque).

     La caducidad NO se mira aqui: `expires_at` lo calcula el servidor con
     os.time en su hora local y el cliente no tiene la misma, asi que una
     comparacion daria por caducada una habitacion buena unas horas antes. Al
     caducar, el servidor la libera y avisa (UpdateHotelRoom), y eso repinta. ]]
function Hotel.MiHabitacion(hotelID)
    if not playerIdentifier then return nil end

    for _, room in pairs(HotelRoom.table) do
        if tonumber(room.hotel_id) == tonumber(hotelID)
            and room.rented_by and room.rented_by == playerIdentifier then
            return room
        end
    end
    return nil
end

--- Vuelve a pintar el punto de un hotel (o de todos) sin tocar lo demas.
function Hotel.RefrescarPunto(hotelID)
    for id, hotel in pairs(Hotel.table) do
        if (not hotelID or tonumber(id) == tonumber(hotelID)) and hotel.blip and hotel.blip.enabled then
            hotel:CreateBlip()
        end
    end
end


function Hotel:DeleteHotel()
    Utils.QuitarDelMapa('hotel_' .. tostring(self.id))
    self.blipHandle = nil

    if self.receptionPoint then
        self.receptionPoint:remove()
        self.receptionPoint = nil
    end

    Hotel.table[self.id] = nil
    HotelData[self.id] = nil
end

--[[ ══ El mostrador ═══════════════════════════════════════════════════════
     Un unico punto por hotel desde el que se ve la lista entera de
     habitaciones y se alquila, en vez de recorrer el pasillo probando
     puerta por puerta.

     Es opcional y no sustituye a nada: el hotel al que no se le haya puesto
     recepcion desde el panel se sigue usando igual que antes, en la puerta
     de cada habitacion, y las puertas siguen ahi tambien cuando si la hay. ]]
function Hotel:CreateReceptionPoint()
    if self.receptionPoint then return end

    --  Sin poner, o puesto y luego quitado desde el panel: en los dos casos
    --  el hotel se queda sin mostrador. El cero de verdad no existe como
    --  sitio, asi que vale de "vacio".
    local coords = self.reception_coords
    if not coords or not coords.x then return end
    if coords.x == 0 and coords.y == 0 and coords.z == 0 then return end

    self.receptionPoint = lib.points.new({
        coords = vector3(coords.x, coords.y, coords.z),
        distance = 5.0,
        hotel = self,
        onExit = function(point)
            Internal.HideText()
            point.noty = false
        end,
        nearby = function(point)
            local markerConfig = Config.Markers.reception or Config.Markers.hotel
            DrawMarker(markerConfig.type, point.coords.x, point.coords.y, point.coords.z + markerConfig.coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, markerConfig.size.x, markerConfig.size.y, markerConfig.size.z, markerConfig.color[1], markerConfig.color[2], markerConfig.color[3], markerConfig.color[4], markerConfig.bobUpAndDown, markerConfig.faceCamera, 2, markerConfig.rotate, nil, false, false)

            if point.currentDistance < 1.5 then
                if not point.noty then
                    Internal.DrawText(Config.Translations.drawtext.openReception, 'E')
                    point.noty = true
                end

                if IsControlJustPressed(0, 38) then
                    local hotel = point.hotel

                    Internal.HideText()
                    point.noty = false

                    --  La lista se pide al servidor, y pedirla es esperar.
                    --  En hilo aparte: aqui dentro se quedarian parados los
                    --  demas puntos mientras llega la respuesta.
                    CreateThread(function()
                        hotel:OpenReception()
                    end)
                end
            elseif point.noty then
                Internal.HideText()
                point.noty = false
            end
        end
    })
end

function Hotel:OpenReception()
    local data = lib.callback.await('origen_housing:server:getReceptionRooms', false, self.id)
    if not data then return end

    Nui.OpenHotelReception(data)
end


HotelRoom = {}
HotelRoom.__index = HotelRoom
HotelRoom.table = {}

function HotelRoom.new(data)    
    local self = HotelRoom.table[data.id]
    local isNew = false

    if not self then
        self = setmetatable({}, HotelRoom)
        HotelRoom.table[data.id] = self
        isNew = true
    end
    
    self.id = data.id
    self.hotel_id = data.hotel_id
    self.room_number = data.room_number
    self.door_coords = data.door_coords
    self.interior_ipl = data.interior_ipl
    self.spawn_coords = data.spawn_coords
    self.wardrobe_coords = data.wardrobe_coords
    self.stash_coords = data.stash_coords
    self.stash_data = data.stash_data
    self.rented_by = data.rented_by
    self.rental_type = data.rental_type
    self.rental_price = data.rental_price
    self.rented_at = data.rented_at
    self.expires_at = data.expires_at
    self.auto_renew = data.auto_renew
    self.door_locked = data.door_locked or 1
    self.status = data.status or 'available'
    
    self.doorPoint = nil
    self.insidePoints = {}

    HotelRoom.table[self.id] = self
    return self
end

function HotelRoom.get(id)
    id = tonumber(id)
    return HotelRoom.table[id] or false
end

--[[ Una habitacion puede no tener puerta en el mundo: se alquila y se entra
     desde la recepcion del hotel, y en el pasillo no hay nada que pisar. El
     cero no existe como sitio, asi que vale de "sin poner". ]]
function HotelRoom:HasDoor()
    local c = self.door_coords
    if not c or not c.x then return false end
    if c.x == 0 and c.y == 0 and c.z == 0 then return false end
    return true
end

--[[ Por donde se sale. Con puerta, por la puerta. Sin ella se sale por donde
     se entro —la recepcion—, y si el hotel tampoco la tiene, al punto del
     hotel en el mapa: lo ultimo antes de dejar a alguien encerrado en un
     interior sin salida. ]]
function HotelRoom:ExitCoords()
    if self:HasDoor() then return self.door_coords end

    local hotel = Hotel.get(self.hotel_id)
    if not hotel then return nil end

    local r = hotel.reception_coords
    if r and r.x and not (r.x == 0 and r.y == 0 and r.z == 0) then return r end

    if hotel.coords and hotel.coords.x then return hotel.coords end

    return nil
end

function HotelRoom:CreateRoom()
    self:CreateDoorPoint()
end

function HotelRoom:CreateDoorPoint()
    if self.doorPoint then 
        return 
    end

    --  Sin puerta no hay punto que crear: la habitacion vive en la recepcion.
    if not self:HasDoor() then return end

    self.doorPoint = lib.points.new({
        coords = vector3(self.door_coords.x, self.door_coords.y, self.door_coords.z),
        distance = 5.0,
        room = self,
        onExit = function(point)
            Internal.HideText()
            point.noty = false
        end,
        nearby = function(point)
            local markerConfig = Config.Markers.hotel
            DrawMarker(markerConfig.type, point.coords.x, point.coords.y, point.coords.z + markerConfig.coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, markerConfig.size.x, markerConfig.size.y, markerConfig.size.z, markerConfig.color[1], markerConfig.color[2], markerConfig.color[3], markerConfig.color[4], markerConfig.bobUpAndDown, markerConfig.faceCamera, 2, markerConfig.rotate, nil, false, false)
            
            if point.currentDistance < 1.3 then
                if not point.noty then
                    Internal.DrawText(Config.Translations.drawtext.viewRoomInfo, 'E')
                    point.noty = true
                end

                if IsControlJustPressed(0, 38) then
                    local hotel = Hotel.get(point.room.hotel_id)
                    if hotel then
                        Nui.OpenRoomDetailPanel(point.room, hotel)
                    end
                end
            elseif point.noty then
                Internal.HideText()
                point.noty = false
            end
        end
    })
end

function HotelRoom:EnterRoom()
    local iplData = self.interior_ipl and Config.Hotels and Config.Hotels.interiorIPLs and Config.Hotels.interiorIPLs[self.interior_ipl] or nil

    --[[ Manda el config, no la copia que guardo la habitacion al crearse.

         Al crear una habitacion se le copiaban dentro las coordenadas del
         interior, asi que tocar `Config.Hotels.interiorIPLs` no arreglaba
         ninguna de las que ya existian: seguian yendo al sitio de antes
         —en el caso del estudio, a un hueco bajo el mapa, donde no hay
         suelo—. Con el config delante, cambiarlo arregla todas de golpe y
         no hay que borrar y volver a crear nada.

         La copia se queda de ultimo recurso, por si algun dia se quita un
         interior del config y quedan habitaciones que lo usaban.

         Se mira `.x` porque Utils.Format devuelve {} cuando el campo de la
         base de datos viene vacio. ]]
    local spawn = (iplData and iplData.spawn) or (self.spawn_coords and self.spawn_coords.x and self.spawn_coords)

    --  Se comprueba antes de fundir a negro: asi no hay que deshacer nada.
    if not spawn or not spawn.x then
        Internal.Notify(Config.Translations.notify.error.noSpawnCoords, 'error', 5000)
        return
    end

    --[[ El aviso al servidor va PRIMERO, porque es quien mete al jugador en
         el bucket de la habitacion.

         Al reves —saltar y cambiar de bucket despues— el juego rehace el
         mundo alrededor de alguien que acaba de aterrizar en un interior que
         todavia no ha cargado; no encuentra suelo bajo sus pies y lo
         devuelve donde estaba, o sea a la recepcion. Ese era el "le doy a
         entrar y me deja en la puerta".

         Es el orden de Shell:EnterIPL, que es como entran las casas. ]]
    TriggerServerEvent('origen_housing:server:enterHotelRoom', self.id)

    SetLocalPlayerAsGhost(true)
    Internal.FadeOut(500)
    Wait(650)

    if iplData and iplData.ipl then
        RequestIpl(iplData.ipl)
    end

    SetPedCoordsKeepVehicle(cache.ped, spawn.x, spawn.y, spawn.z)
    SetEntityHeading(cache.ped, spawn.w or 0.0)
    SetGameplayCamRelativeHeading(0)

    --  Y esperar al suelo antes de quitar el negro, igual que al salir.
    Wait(500)

    local intentos = 0
    while not HasCollisionLoadedAroundEntity(cache.ped) and intentos < 50 do
        Wait(200)
        intentos = intentos + 1
    end

    self:CreateInsidePoints(iplData)

    Internal.FadeIn(500)
    SetLocalPlayerAsGhost(false)
end

function HotelRoom:CreateInsidePoints(iplData)
    --[[ Se limpia antes de crear. Si se entra dos veces sin haber salido
         —el panel abierto dos veces, o volver a entrar desde la recepcion—
         las referencias de los puntos viejos se perdian al sobrescribirlas y
         quedaban dibujandose para siempre, con dos marcadores encima del
         mismo sitio. ]]
    self:RemoveInsidePoints()

    local markerConfig = Config.Markers.hotel

    --[[ El ropero. Estuvo desactivado una temporada y vuelve a estar, ahora
         que los interiores tienen un sitio medido para el.

         Solo aparece si el interior trae `wardrobe` en el config: los que no
         lo tengan se quedan sin ropero, sin romper nada. ]]
    local wardrobe = (iplData and iplData.wardrobe) or (self.wardrobe_coords and self.wardrobe_coords.x and self.wardrobe_coords)
    if wardrobe and wardrobe.x then
        self.insidePoints.wardrobe = lib.points.new({
            coords = vector3(wardrobe.x, wardrobe.y, wardrobe.z),
            distance = 10.0,
            room = self,
            onExit = function(point)
                Internal.HideText()
                point.noty = false
            end,
            nearby = function(point)
                DrawMarker(markerConfig.type, point.coords.x, point.coords.y, point.coords.z + markerConfig.coords.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, markerConfig.size.x, markerConfig.size.y, markerConfig.size.z, markerConfig.color[1], markerConfig.color[2], markerConfig.color[3], markerConfig.color[4], markerConfig.bobUpAndDown, markerConfig.faceCamera, 2, markerConfig.rotate, nil, false, false)

                if point.currentDistance < 2.5 then
                    if not point.noty then
                        Internal.DrawText(Config.Translations.drawtext.openWardrobe, 'E')
                        point.noty = true
                    end
                    if IsControlJustPressed(0, 38) then
                        Internal.Wardrobe('hotelroom_'..point.room.id)
                    end
                elseif point.noty then
                    Internal.HideText()
                    point.noty = false
                end
            end
        })
    end

    --  Igual que el spawn: manda el config y la copia guardada es el ultimo
    --  recurso, para que mover el almacen en config/hotels.lua valga para
    --  todas las habitaciones de ese interior y no solo para las nuevas.
    local stash = (iplData and iplData.stash) or (self.stash_coords and self.stash_coords.x and self.stash_coords)

    --[[ Sin ropero medido, el armario va en el almacén, con la G.

         El interior de gama media no trae `wardrobe` y sus inquilinos se
         quedaban sin poder cambiarse ni guardar conjuntos en su propia
         habitación. El almacén sí está en todos los interiores, así que ahí
         no hay que medir nada nuevo ni arriesgarse a un punto dentro de una
         pared. Si algún día se mide el ropero de ese interior, basta con
         ponerlo en config/hotels.lua y esto deja de hacer falta solo. ]]
    local armarioEnAlmacen = not self.insidePoints.wardrobe
    local textoAlmacen = armarioEnAlmacen
        and string.format('%s | [G] %s', Config.Translations.drawtext.openStash, Config.Translations.drawtext.openWardrobe)
        or Config.Translations.drawtext.openStash

    if stash and stash.x then
        self.insidePoints.stash = lib.points.new({
            coords = vector3(stash.x, stash.y, stash.z),
            distance = 5.0,
            room = self,
            onExit = function(point)
                Internal.HideText()
                point.noty = false
            end,
            nearby = function(point)
                DrawMarker(markerConfig.type, point.coords.x, point.coords.y, point.coords.z + markerConfig.coords.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, markerConfig.size.x, markerConfig.size.y, markerConfig.size.z, markerConfig.color[1], markerConfig.color[2], markerConfig.color[3], markerConfig.color[4], markerConfig.bobUpAndDown, markerConfig.faceCamera, 2, markerConfig.rotate, nil, false, false)

                if point.currentDistance < 1.3 then
                    if not point.noty then
                        Internal.DrawText(textoAlmacen, 'E')
                        point.noty = true
                    end
                    if IsControlJustPressed(0, 38) then
                        Internal.OpenStash('hotelroom_'..point.room.id, point.room.stash_data)
                        TriggerServerEvent('origen_housing:server:RegisterStash', 'hotelroom_'..point.room.id, point.room.stash_data)
                    elseif armarioEnAlmacen and IsControlJustPressed(0, 47) then -- G
                        Internal.HideText()
                        point.noty = false
                        Internal.Wardrobe('hotelroom_'..point.room.id)
                    end
                elseif point.noty then
                    Internal.HideText()
                    point.noty = false
                end
            end
        })
    end

    local spawn = (iplData and iplData.spawn) or (self.spawn_coords and self.spawn_coords.x and self.spawn_coords)
    if spawn and spawn.x then
        self.insidePoints.exit = lib.points.new({
            coords = vector3(spawn.x, spawn.y, spawn.z),
            distance = 5.0,
            room = self,
            onExit = function(point)
                Internal.HideText()
                point.noty = false
            end,
            nearby = function(point)
                DrawMarker(markerConfig.type, point.coords.x, point.coords.y, point.coords.z + markerConfig.coords.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, markerConfig.size.x, markerConfig.size.y, markerConfig.size.z, markerConfig.color[1], markerConfig.color[2], markerConfig.color[3], markerConfig.color[4], markerConfig.bobUpAndDown, markerConfig.faceCamera, 2, markerConfig.rotate, nil, false, false)
                
                if point.currentDistance < 1.3 then
                    if not point.noty then
                        Internal.DrawText(Config.Translations.drawtext.exitRoom, 'E')
                        point.noty = true
                    end
                    if IsControlJustPressed(0, 38) then
                        local room = point.room

                        Internal.HideText()
                        point.noty = false

                        --  Salir tarda: se funde a negro y se espera a que
                        --  cargue el suelo. En hilo aparte, que aqui dentro
                        --  se quedarian parados los demas puntos.
                        CreateThread(function()
                            room:ExitRoom()
                        end)
                    end
                elseif point.noty then
                    Internal.HideText()
                    point.noty = false
                end
            end
        })
    end
end

function HotelRoom:ExitRoom()
    local salida = self:ExitCoords()

    if not salida then
        Internal.Notify(Config.Translations.notify.error.noExitCoords, 'error', 5000)
        return
    end

    SetLocalPlayerAsGhost(true)
    Internal.FadeOut(500)
    Wait(650)

    --[[ Primero el aviso al servidor —que es quien devuelve al jugador al
         bucket 0— y despues el salto. Es el orden que usan las casas:
         aterrizar en la calle con el bucket de la habitacion todavia puesto
         obliga a recargarlo todo otra vez al cambiarlo. ]]
    TriggerServerEvent('origen_housing:server:exitHotelRoom', self.id)

    self:RemoveInsidePoints()

    SetPedCoordsKeepVehicle(cache.ped, salida.x, salida.y, salida.z)
    SetEntityHeading(cache.ped, salida.w or 0.0)
    SetGameplayCamRelativeHeading(0)

    --[[ Y aqui se espera a que cargue el suelo, que es lo que faltaba.

         Antes se soltaba al jugador con un SetEntityCoords a secas en un
         sitio que todavia no existia: sin colision bajo los pies, el juego
         lo devolvia al interior del que venia. Se notaba justo en la salida
         de una habitacion sin puerta, porque el salto va de un interior bajo
         el mapa hasta la calle y ahi hay mucho que cargar.

         Es el mismo bucle que usan el ascensor y los garajes, con un tope:
         quedarse esperando para siempre seria una pantalla en negro de la
         que no se sale. ]]
    Wait(1000)

    local intentos = 0
    while not HasCollisionLoadedAroundEntity(cache.ped) and intentos < 50 do
        Wait(200)
        intentos = intentos + 1
    end

    Internal.FadeIn(500)
    SetLocalPlayerAsGhost(false)
end

function HotelRoom:RemoveInsidePoints()
    for _, point in pairs(self.insidePoints) do
        if point then
            point:remove()
        end
    end
    self.insidePoints = {}
end

function HotelRoom:DeleteRoom()
    if self.doorPoint then
        self.doorPoint:remove()
        self.doorPoint = nil
    end

    self:RemoveInsidePoints()

    HotelRoom.table[self.id] = nil
end

RegisterNetEvent('origen_housing:client:CreateHotel', function(data)
    local hotel = Hotel.new(data)
    hotel:CreateHotel()
end)

RegisterNetEvent('origen_housing:client:UpdateHotel', function(data)
    local hotel = Hotel.get(data.id)
    if hotel then
        hotel:DeleteHotel()
    end
    hotel = Hotel.new(data)
    hotel:CreateHotel()
end)

RegisterNetEvent('origen_housing:client:DeleteHotel', function(hotelID)
    local hotel = Hotel.get(hotelID)
    if hotel then
        hotel:DeleteHotel()
    end
end)

--[[ Cada cambio de una habitacion puede cambiar de quien es su hotel: la
     alquilas, la dejas, caduca o te echan. Se vuelve a pintar el punto de ESE
     hotel, que es barato, y asi pasa de violeta a rosa (y al reves) al momento. ]]
RegisterNetEvent('origen_housing:client:CreateHotelRoom', function(data)
    local room = HotelRoom.new(data)
    if room then
        room:CreateRoom()
        Hotel.RefrescarPunto(room.hotel_id)
    end
end)

RegisterNetEvent('origen_housing:client:UpdateHotelRoom', function(data)
    local room = HotelRoom.get(data.id)
    local hotelAntes = room and room.hotel_id
    if room then
        room:DeleteRoom()
    end
    room = HotelRoom.new(data)
    room:CreateRoom()
    Hotel.RefrescarPunto(room.hotel_id)
    if hotelAntes and tonumber(hotelAntes) ~= tonumber(room.hotel_id) then
        Hotel.RefrescarPunto(hotelAntes)
    end
end)

RegisterNetEvent('origen_housing:client:DeleteHotelRoom', function(roomID)
    local room = HotelRoom.get(roomID)
    if room then
        local hotelID = room.hotel_id
        room:DeleteRoom()
        Hotel.RefrescarPunto(hotelID)
    end
end)

RegisterNetEvent('origen_housing:client:kickFromHotelRoom', function(roomID)
    local room = HotelRoom.get(roomID)
    if room then
        room:ExitRoom()
    end
    Internal.Notify(Config.Translations.notify.error.evictedFromRoom, 'error', 5000)
end)

CreateThread(function()
    Wait(1000)
    
    if not Config.Hotels or not Config.Hotels.enabled then 
        return 
    end
    
    lib.callback('origen_housing:server:getAllHotels', false, function(hotels)
        if hotels and next(hotels) then
            for _, data in pairs(hotels) do
                local hotel = Hotel.new(data)
                hotel:CreateHotel()
            end
        end
    end)

    lib.callback('origen_housing:server:getHotelRooms', false, function(rooms)
        if rooms and next(rooms) then
            for _, data in pairs(rooms) do
                local room = HotelRoom.new(data)
                room:CreateRoom()
            end
        end

        --[[ Los hoteles se pintaron antes de saber de quien era cada
             habitacion (llegan por dos peticiones sueltas). Y el
             identificador del jugador puede tardar: se espera un poco y se
             repintan, para que tu hotel salga en rosa desde el principio. ]]
        CreateThread(function()
            for _ = 1, 60 do
                if playerIdentifier then break end
                Wait(500)
            end
            Hotel.RefrescarPunto()
        end)
    end, nil)
end)

