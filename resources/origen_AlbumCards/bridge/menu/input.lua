Bridge = Bridge or {}
Bridge.Input = Bridge.Input or {}

local menuType = Config.Menu or 'auto'

if menuType == 'auto' then
    if GetResourceState('org-input') == 'started' then menuType = 'org-input'
    elseif GetResourceState('qb-input') == 'started' then menuType = 'qb-input'
    elseif GetResourceState('ox_lib') == 'started' then menuType = 'ox_lib'
    elseif GetResourceState('org-menu') == 'started' then menuType = 'org-input'
    elseif GetResourceState('qb-menu') == 'started' then menuType = 'qb-input'
    else menuType = 'qb-input' end
end

-- ============================================================
-- Bridge.Input.Show(data)
-- data = {
--     header = "Title",
--     inputs = {
--         { type = "text", name = "name", label = "Name", required = true },
--         { type = "select", name = "album", label = "Album", options = { { value = 1, label = "Album 1" } } },
--         { type = "number", name = "amount", label = "Amount" }
--     },
--     callback = function(result) ... end
-- }
-- ============================================================

function origenalbumcards_ShowInput(data)
    if menuType == 'ox_lib' then
        local oxFields = {}
        for _, v in ipairs(data.inputs) do
            if v.type == 'text' then
                table.insert(oxFields, { type = 'input', label = v.label, placeholder = v.placeholder, required = v.required, name = v.name, icon = v.icon })
            elseif v.type == 'number' then
                table.insert(oxFields, { type = 'number', label = v.label, placeholder = v.placeholder, required = v.required, name = v.name, icon = v.icon })
            elseif v.type == 'select' then
                local options = {}
                for _, opt in ipairs(v.options) do
                    table.insert(options, {
                        value = opt.value,
                        label = opt.label or opt.text or opt.value
                    })
                end
                table.insert(oxFields, { type = 'select', label = v.label, options = options, required = v.required, name = v.name, icon = v.icon })
            end
        end
        local input = lib.inputDialog(data.header, oxFields)
        if not input then return data.callback(nil) end
        
        local result = {}
        for i, v in ipairs(data.inputs) do
            result[v.name] = input[i]
        end
        data.callback(result)

    elseif menuType == 'qb-input' or menuType == 'org-input' then
        local qbFields = {}
        for _, v in ipairs(data.inputs) do
            local field = {
                text = v.label,
                name = v.name,
                type = v.type == 'select' and 'select' or (v.type == 'number' and 'number' or 'text'),
                isRequired = v.required,
                icon = v.icon
            }
            if v.type == 'select' then
                local options = {}
                for _, opt in ipairs(v.options) do
                    table.insert(options, {
                        value = opt.value,
                        text = opt.label or opt.text or opt.value
                    })
                end
                field.options = options
            end
            table.insert(qbFields, field)
        end
        
        local input = exports[menuType]:ShowInput({
            header = data.header,
            submitText = "Confirmar",
            inputs = qbFields
        })
        
        data.callback(input)
    else
        Bridge.Framework.Notify("No hay sistema de formularios (ox_lib, qb-input u org-input)", "error")
        data.callback(nil)
    end
end

Bridge.Input.Show = origenalbumcards_ShowInput
