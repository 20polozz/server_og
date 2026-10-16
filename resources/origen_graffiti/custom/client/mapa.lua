--[[ ═══════════════════════════════════════════════════════════════════════
     La tienda de graffiti, en el mapa de ORIGEN

     ── Por que esta aqui y no en client/shop.lua ──────────────────────────

     Porque shop.lua viene cifrado (FXAP) y no se puede tocar. Ese fichero es
     el que monta la tienda, y con ella el blip del bote de spray —Config.Shop
     .blip, sprite 73— que ya no pinta ningun mapa de este servidor: los dos
     son de Leaflet y leen el registro de origen_map, no los blips del juego.

     El resultado era que la tienda salia sin nombre en el mapa grande, colada
     por la recogida de blips sueltos, y no salia en el minimapa.

     ── Por que no estorba al blip que sigue creando el codigo cifrado ─────

     Porque el registro tapa cualquier blip que caiga a menos de cinco metros
     de uno de sus puntos (origen_pausemenu/client/mapa.lua). El del spray cae
     justo encima de este, asi que se queda debajo y se ve solo el nuestro, con
     su nombre y su categoria.

     ── El config sigue mandando ───────────────────────────────────────────

     `enabled` y `label` se leen de Config.Shop.blip, que es donde estaban y
     donde el que administra el servidor va a buscarlos. El `color`, si esta en
     la tabla de OrigenMapa.Color, tambien manda. El `sprite` no: es el 73, que
     en GTA es la tienda de ropa, y pasarlo por OrigenMapa.Icono pintaria una
     camiseta. El bote de spray va puesto aqui a mano.
   ═══════════════════════════════════════════════════════════════════════ ]]

CreateThread(function()
    local shop = Config and Config.Shop
    local blip = shop and shop.blip

    if not blip or not blip.enabled then return end
    if type(shop.locations) ~= 'table' then return end

    local lista = {}

    for i, sitio in ipairs(shop.locations) do
        lista[#lista + 1] = {
            x = sitio.x, y = sitio.y, z = sitio.z,
            cat = 'shops',
            icono = 'spray',
            nombre = blip.label or 'Tienda de graffiti',
            color = OrigenMapa.Color(blip.color),
        }
    end

    --- Una tanda y no uno a uno: si algun dia hay varias tiendas, reemplazar
    --- la tanda entera es lo que hace que las que se quiten desaparezcan.
    OrigenMapa.PonerVarios('tienda', lista)
end)
