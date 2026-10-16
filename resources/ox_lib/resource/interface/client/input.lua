--[[
    https://github.com/overextended/ox_lib

    This file is licensed under LGPL-3.0 or higher <https://www.gnu.org/licenses/lgpl-3.0.en.html>

    Copyright © 2025 Linden <https://github.com/thelindat>
]]

local input

---@class InputDialogRowProps
---@field type 'input' | 'number' | 'checkbox' | 'select' | 'slider' | 'multi-select' | 'date' | 'date-range' | 'time' | 'textarea' | 'color'
---@field label string
---@field options? { value: string, label: string, default?: string }[]
---@field password? boolean
---@field icon? string | {[1]: IconProp, [2]: string};
---@field iconColor? string
---@field placeholder? string
---@field default? string | number
---@field disabled? boolean
---@field checked? boolean
---@field min? number
---@field max? number
---@field step? number
---@field autosize? boolean
---@field required? boolean
---@field format? string
---@field returnString? boolean
---@field clearable? boolean
---@field searchable? boolean
---@field description? string
---@field maxSelectedValues? number
---@field minLength? number
---@field maxLength? number

---@class InputDialogOptionsProps
---@field allowCancel? boolean
---@field size? 'xs' | 'sm' | 'md' | 'lg' | 'xl'

--[[ ORIGEN (07/10): el formulario sale en org-input (el menu pequeño de todo
     el servidor, skill origen-dialogo) y no en la web de ox_lib. La API y lo
     que se devuelve son los de ox: una lista en el orden de las filas, con
     numeros, booleanos y listas donde toca. Lo que org-input no tiene se
     acerca a lo mas parecido (area de texto, fecha, hora y color se escriben;
     el deslizador es un numero; la seleccion multiple, casillas).
     OJO: si se actualiza ox_lib, esto hay que volver a ponerlo. ]]

local function opcionesDe(row)
    local ops = {}
    for i, o in ipairs(row.options or {}) do
        ops[i] = { value = tostring(o.value), text = o.label or tostring(o.value) }
    end
    return ops
end

---@param heading string
---@param rows string[] | InputDialogRowProps[]
---@param options InputDialogOptionsProps[]?
---@return string[] | number[] | boolean[] | nil
function lib.inputDialog(heading, rows, options)
    if input then return end
    input = true

    local filas, campos = {}, {}
    for i = 1, #rows do
        local row = rows[i]
        if type(row) == 'string' then row = { type = 'input', label = row } end
        filas[i] = row

        local nombre = 'c' .. i
        local t = row.type or 'input'
        local texto = row.label or ''
        if row.description and row.description ~= '' then texto = ('%s — %s'):format(texto, row.description) end
        local campo = { name = nombre, text = texto, isRequired = row.required or nil, default = row.default }

        if t == 'number' or t == 'slider' then
            campo.type = 'number'
            if t == 'slider' and campo.default == nil then campo.default = row.min or 0 end
        elseif t == 'checkbox' then
            campo.type = 'checkbox'
            campo.text = nil
            campo.options = { { value = nombre, text = row.label or '', checked = row.checked or nil } }
        elseif t == 'select' then
            campo.type = 'select'
            campo.options = opcionesDe(row)
            if campo.default ~= nil then campo.default = tostring(campo.default) end
        elseif t == 'multi-select' then
            campo.type = 'checkbox'
            campo.options = opcionesDe(row)
            local def = type(row.default) == 'table' and row.default or {}
            for _, o in ipairs(campo.options) do
                for _, d in ipairs(def) do
                    if tostring(d) == o.value then o.checked = true end
                end
                o.value = nombre .. '_' .. o.value
            end
        elseif t == 'input' and row.password then
            campo.type = 'password'
        else
            campo.type = 'text'
        end

        if campo.default ~= nil and campo.type ~= 'select' then campo.default = tostring(campo.default) end
        campos[i] = campo
    end

    local datos = exports['org-input']:ShowInput({
        header = heading,
        submitText = 'Confirmar',
        inputs = campos,
    })

    input = nil
    if not datos then return end

    local res = {}
    for i, row in ipairs(filas) do
        local t = row.type or 'input'
        local nombre = 'c' .. i
        local v = datos[nombre]
        if t == 'number' or t == 'slider' then
            v = tonumber(v)
            if v and row.min and v < row.min then v = row.min end
            if v and row.max and v > row.max then v = row.max end
        elseif t == 'checkbox' then
            v = datos[nombre] == true or datos[nombre] == 'true'
        elseif t == 'multi-select' then
            local lista = {}
            for _, o in ipairs(row.options or {}) do
                local m = datos[nombre .. '_' .. tostring(o.value)]
                if m == true or m == 'true' then lista[#lista + 1] = o.value end
            end
            v = #lista > 0 and lista or nil
        elseif t == 'select' then
            if v ~= nil then
                for _, o in ipairs(row.options or {}) do
                    if tostring(o.value) == tostring(v) then v = o.value break end
                end
            end
        elseif v == '' then
            v = nil
        end
        res[i] = v
    end
    return res
end

function lib.closeInputDialog()
    if not input then return end
    input = nil
    exports['org-input']:CloseInput()
end

RegisterNUICallback('inputData', function(_, cb) cb(1) end)
