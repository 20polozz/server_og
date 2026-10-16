--[[ ── Los puntos que se pueden mover en el juego ─────────────────────────────

     El editor (`/minaeditor`) mueve estos sitios y los guarda en
     `shared/puntos.json`, que se lee al arrancar y pisa lo que hay en
     config.lua. Así la cantera se coloca a ojo, dentro del juego, sin tocar
     código: lo que se guarda son solo coordenadas.

     La planta se mueve entera: su punto es el ancla y todas las piezas van
     colgadas de él. `rumbo` a false significa que ese sitio solo tiene
     posición. ]]

local M = Config.Mina

--- La lista, en el orden en que sale en el editor.
Mina.Sitios = {
    { id = 'ped_capataz', nombre = 'NPC: capataz (jornada, pico, vehículo, cargas)', rumbo = true,
      leer = function() return M.Peds.Capataz.coords end,
      poner = function(v) M.Peds.Capataz.coords = v end },

    { id = 'descarga', nombre = 'Cuadro de descarga (el vehículo mira hacia la flecha)', rumbo = true,
      leer = function() return Config.Planta.descarga.pos end,
      poner = function(v) Config.Planta.descarga.pos = v end },

    { id = 'borde', nombre = 'Borde del foso (descargar a pie)', rumbo = false,
      leer = function() return Config.Planta.borde.pos end,
      poner = function(v) Config.Planta.borde.pos = v end },

    { id = 'boca', nombre = 'Dónde cae la piedra en el foso', rumbo = false,
      leer = function() return Config.Planta.boca end,
      poner = function(v) Config.Planta.boca = v end },

    { id = 'salida1', nombre = 'Salida del vehículo 1', rumbo = true,
      leer = function() return M.salidas[1] end,
      poner = function(v) M.salidas[1] = v end },

    { id = 'salida2', nombre = 'Salida del vehículo 2', rumbo = true,
      leer = function() return M.salidas[2] end,
      poner = function(v) M.salidas[2] = v end },

    { id = 'salida3', nombre = 'Salida del vehículo 3', rumbo = true,
      leer = function() return M.salidas[3] end,
      poner = function(v) M.salidas[3] = v end },

    { id = 'devolver', nombre = 'Sitio donde se deja el vehículo', rumbo = false,
      leer = function() return M.devolver.coords end,
      poner = function(v) M.devolver.coords = v end },
}

for _, b in ipairs(Config.Bloques) do
    Mina.Sitios[#Mina.Sitios + 1] = {
        id = 'bloque_' .. b.id, nombre = b.nombre .. ' (voladuras)', rumbo = true,
        leer = function() return b.pos end,
        poner = function(v) b.pos = v end,
    }
end

Mina.SitioPorId = {}
for _, p in ipairs(Mina.Sitios) do Mina.SitioPorId[p.id] = p end

--- Lo que hay ahora en Config, listo para guardar.
function Mina.SitiosAhora()
    local t = {}
    for _, p in ipairs(Mina.Sitios) do
        local v = p.leer()
        if v then
            t[p.id] = { x = v.x + 0.0, y = v.y + 0.0, z = v.z + 0.0, w = p.rumbo and (v.w or 0.0) + 0.0 or nil }
        end
    end
    return t
end

--- Pisa Config con lo guardado (lo llaman el arranque y el editor).
function Mina.AplicarSitios(t)
    if type(t) ~= 'table' then return 0 end
    local n = 0
    for id, v in pairs(t) do
        local p = Mina.SitioPorId[id]
        if p and tonumber(v.x) and tonumber(v.y) and tonumber(v.z) then
            if p.rumbo then
                p.poner(vec4(v.x + 0.0, v.y + 0.0, v.z + 0.0, (tonumber(v.w) or 0.0) + 0.0))
            else
                p.poner(vec3(v.x + 0.0, v.y + 0.0, v.z + 0.0))
            end
            n = n + 1
        end
    end
    return n
end

-- Al arrancar: si hay puntos guardados, mandan ellos.
local guardado = LoadResourceFile(GetCurrentResourceName(), 'shared/puntos.json')
if guardado then
    local ok, t = pcall(json.decode, guardado)
    if ok then Mina.AplicarSitios(t) end
end
