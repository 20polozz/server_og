--[[
    https://github.com/overextended/ox_lib

    This file is licensed under LGPL-3.0 or higher <https://www.gnu.org/licenses/lgpl-3.0.en.html>

    Copyright © 2025 Linden <https://github.com/thelindat>
]]

local contextMenus = {}
local openContextMenu = nil

---@class ContextMenuItem
---@field title? string
---@field menu? string
---@field icon? string | {[1]: IconProp, [2]: string};
---@field iconColor? string
---@field image? string
---@field progress? number
---@field onSelect? fun(args: any)
---@field arrow? boolean
---@field description? string
---@field metadata? string | { [string]: any } | string[]
---@field disabled? boolean
---@field readOnly? boolean
---@field event? string
---@field serverEvent? string
---@field args? any

---@class ContextMenuArrayItem : ContextMenuItem
---@field title string

---@class ContextMenuProps
---@field id string
---@field title string
---@field menu? string
---@field onExit? fun()
---@field onBack? fun()
---@field canClose? boolean
---@field options { [string]: ContextMenuItem } | ContextMenuArrayItem[]

local function closeContext(_, cb, onExit)
    if cb then cb(1) end

    -- ORIGEN: sin menu contextual abierto no hay foco suyo que soltar. Un
    -- lib.hideContext() de cortesia le quitaba el raton a otra pantalla de
    -- ox_lib (un input, un alert) que estuviera abierta.
    if not openContextMenu then return end

    lib.resetNuiFocus()

    if (cb or onExit) and contextMenus[openContextMenu].onExit then contextMenus[openContextMenu].onExit() end

    if not cb then SendNUIMessage({ action = 'hideContext' }) end

    openContextMenu = nil
end

--[[ ORIGEN (07/10): el menu contextual sale en org-menu (el menu pequeño de
     todo el servidor, skill origen-dialogo) y no en la web de ox_lib, igual
     que lib.notify y lib.showTextUI van a origen_notify. La API es la misma;
     las opciones se quedan aqui y org-menu solo devuelve cual se eligio, por
     un evento local (no viajan funciones entre recursos).
     OJO: si se actualiza ox_lib, esto hay que volver a ponerlo. ]]

---Lo que manda ox (`car`, `fas fa-car`, `{ 'fas', 'car' }`) a clase de Font Awesome.
local function icono(ico, defecto)
    if type(ico) == 'table' then
        ico = ('%s fa-%s'):format(ico[1] or 'fas', ico[2] or 'circle')
    end
    if type(ico) ~= 'string' or ico == '' then return defecto end
    if ico:find('fa%-') then return ico end
    return 'fa-solid fa-' .. ico
end

---Las opciones en orden: lista, o tabla con el titulo de clave (por orden alfabetico, como ox).
local function opcionesEnOrden(options)
    local lista = {}
    if options[1] ~= nil then
        for i = 1, #options do lista[#lista + 1] = { clave = i, op = options[i] } end
    else
        for k, v in pairs(options) do lista[#lista + 1] = { clave = k, op = v } end
        table.sort(lista, function(a, b) return tostring(a.clave) < tostring(b.clave) end)
    end
    return lista
end

---Los datos de debajo del titulo: la descripcion, y si no hay, la metadata en una linea.
local function renglon(op)
    if op.description and op.description ~= '' then return op.description end
    local m = op.metadata
    if type(m) == 'string' then return m end
    if type(m) ~= 'table' then return nil end
    local partes = {}
    if m[1] ~= nil then
        for i = 1, #m do
            local v = m[i]
            if type(v) == 'table' then
                partes[#partes + 1] = v.value ~= nil and ('%s: %s'):format(v.label, v.value) or tostring(v.label)
            else
                partes[#partes + 1] = tostring(v)
            end
        end
    else
        for k, v in pairs(m) do partes[#partes + 1] = ('%s: %s'):format(k, v) end
        table.sort(partes)
    end
    return #partes > 0 and table.concat(partes, ' · ') or nil
end

---@param id string
function lib.showContext(id)
    if not contextMenus[id] then error('No context menu of such id found.') end

    local data = contextMenus[id]
    openContextMenu = id

    local menu = { { header = data.title or '', isMenuHeader = true, icon = 'fa-solid fa-list-ul' } }

    if data.menu then
        menu[#menu + 1] = {
            header = 'Volver',
            icon = 'fa-solid fa-arrow-left',
            params = { event = 'ox_lib:origen:contexto', args = { id = id, volver = true } },
        }
    end

    for _, e in ipairs(opcionesEnOrden(data.options or {})) do
        local op = e.op
        local hace = op.menu or op.event or op.serverEvent or op.onSelect
        menu[#menu + 1] = {
            header = op.title or (type(e.clave) == 'string' and e.clave) or '',
            txt = renglon(op),
            icon = icono(op.icon, op.menu and 'fa-solid fa-angle-right' or nil),
            disabled = op.disabled or nil,
            -- Lo que solo se lee no hace nada al pulsarlo (ni cierra).
            noclose = (not hace or op.disabled) and true or nil,
            params = hace and { event = 'ox_lib:origen:contexto', args = { id = id, clave = e.clave } } or nil,
        }
    end

    exports['org-menu']:openMenu(menu)
end

-- Lo elegido en org-menu (que ya se ha cerrado).
AddEventHandler('ox_lib:origen:contexto', function(args)
    if type(args) ~= 'table' or openContextMenu ~= args.id then return end
    local menu = contextMenus[args.id]
    if not menu then return end

    if args.volver then
        if menu.onBack then menu.onBack() end
        return lib.showContext(menu.menu)
    end

    local op = menu.options[args.clave]
    if not op then return end

    if op.menu then return lib.showContext(op.menu) end

    openContextMenu = nil
    if op.onSelect then op.onSelect(op.args) end
    if op.event then TriggerEvent(op.event, op.args) end
    if op.serverEvent then TriggerServerEvent(op.serverEvent, op.args) end
end)

-- Cerrado con Escape o clic derecho.
AddEventHandler('org-menu:client:menuClosed', function()
    local id = openContextMenu
    if not id then return end
    openContextMenu = nil
    local menu = contextMenus[id]
    if menu and menu.onExit then menu.onExit() end
end)

---@param context ContextMenuProps | ContextMenuProps[]
function lib.registerContext(context)
    for k, v in pairs(context) do
        if type(k) == 'number' then
            contextMenus[v.id] = v
        else
            contextMenus[context.id] = context
            break
        end
    end
end

---@return string?
function lib.getOpenContextMenu() return openContextMenu end

---@param onExit boolean?
function lib.hideContext(onExit)
    local id = openContextMenu
    if not id then return end
    openContextMenu = nil
    exports['org-menu']:closeMenu()
    local menu = contextMenus[id]
    if onExit and menu and menu.onExit then menu.onExit() end
end

RegisterNUICallback('openContext', function(data, cb)
    cb(1)

    local menu = openContextMenu and contextMenus[openContextMenu]
    if data.back and menu and menu.onBack then menu.onBack() end

    lib.showContext(data.id)
end)

RegisterNUICallback('clickContext', function(id, cb)
    cb(1)

    if math.type(tonumber(id)) == 'float' then
        id = math.tointeger(id)
    elseif tonumber(id) then
        id += 1
    end

    local menu = openContextMenu and contextMenus[openContextMenu]
    local data = menu and menu.options[id]
    if not data then return end

    if not data.event and not data.serverEvent and not data.onSelect then return end

    openContextMenu = nil

    SendNUIMessage({ action = 'hideContext' })
    lib.resetNuiFocus()

    if data.onSelect then data.onSelect(data.args) end
    if data.event then TriggerEvent(data.event, data.args) end
    if data.serverEvent then TriggerServerEvent(data.serverEvent, data.args) end
end)

RegisterNUICallback('closeContext', closeContext)



