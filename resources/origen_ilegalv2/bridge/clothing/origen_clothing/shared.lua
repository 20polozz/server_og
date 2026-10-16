---@diagnostic disable: duplicate-set-field
if GetResourceState('origen_clothing') == 'missing' then return end

Clothing = Clothing or {}
