--[[
    https://github.com/overextended/ox_lib

    This file is licensed under LGPL-3.0 or higher <https://www.gnu.org/licenses/lgpl-3.0.en.html>

    Copyright © 2025 Linden <https://github.com/thelindat>
]]

---@class TextUIOptions
---@field position? 'right-center' | 'left-center' | 'top-center' | 'bottom-center';
---@field icon? string | {[1]: IconProp, [2]: string};
---@field iconColor? string;
---@field style? string | table;
---@field alignIcon? 'top' | 'center';

--[[ ORIGEN (07/10): la textui de ox_lib NO usa la web de ox_lib: lib.showTextUI
     pasa por exports.origen_notify:DrawText(tecla, texto) y lib.hideTextUI por
     exports.origen_notify:HideText(), que la pintan con el estilo del servidor
     (pegatina). Así las llamadas de todos los recursos (los de terceros
     también) salen iguales sin tocarlos.
     OJO: al actualizar ox_lib este fichero se sobrescribe y se pierde; hay que
     volver a ponerlo (ver la memoria ox-lib-dialogos-a-org-menu). ]]

local isOpen = false
local currentText

---@param text string
---@param options? TextUIOptions
function lib.showTextUI(text, options)
    if currentText == text then return end

    if not options then options = {} end

    local key, message = text:match("^%[(.-)%]%s*%-%s*(.+)$")

    if not key then
        key, message = text:match("^(%S+)%s*%-%s*(.+)$")
    end

    if not key then
        key, message = text:match("^(%S+)%s+(.+)$")
    end

    if not key then
        message = text
    end

    if key then
        key = key:gsub("%[", ""):gsub("%]", "")
    end

    options.text = message
    options.key = key
    options.message = message
    currentText = text

    exports.origen_notify:DrawText(options.key, options.message)

    isOpen = true
end

function lib.hideTextUI()
    exports.origen_notify:HideText()

    isOpen = false
    currentText = nil
end

---@return boolean, string | nil
function lib.isTextUIOpen()
    return isOpen, currentText
end
