-- Orden dentro de cada categoría del catálogo (se carga el último de config/).
-- Lo que se ve primero al abrir un grupo de la cinta es lo de casa; lo de
-- armas y droga (que está para las guaridas) va al final de su categoría.
-- El orden relativo de lo demás no cambia.
local AL_FINAL = { 'grenade', 'gas_mask', 'weed', 'meth', 'coke', 'pills', 'ammo', 'guncase', 'sgun_casing', 'riot_shield', 'cash_case', 'cigar' }

local function Peso(modelo)
    modelo = tostring(modelo)
    for _, trozo in ipairs(AL_FINAL) do
        if modelo:find(trozo, 1, true) then return 2 end
    end
    return 1
end

for _, cat in ipairs(Config.Furniture or {}) do
    local items = cat.items
    if type(items) == 'table' and #items > 1 then
        local primero, ultimo = {}, {}
        for _, it in ipairs(items) do
            if Peso(it.model) == 1 then primero[#primero + 1] = it else ultimo[#ultimo + 1] = it end
        end
        if #ultimo > 0 and #primero > 0 then
            for i = 1, #primero do items[i] = primero[i] end
            for i = 1, #ultimo do items[#primero + i] = ultimo[i] end
        end
    end
end
