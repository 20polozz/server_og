-- ── Coke Lab — Registro en el runner genérico ────────────────────────────────
--
-- Toda la lógica de puntos, markers, animaciones, barra de progreso y
-- estado de producción la maneja LabProcessRunner (client/lab_process_runner.lua).
--
-- Este archivo solo:
--   1. Registra el lab en el runner con su config
--   2. Expone el export de reset (compatibilidad con código existente)
--
-- Si el lab tiene comportamiento que el runner NO puede manejar genéricamente
-- (ej: prop de bandeja como en meth), se pasa en el tercer argumento de Register
-- como hooks: { onEnter, onExit, onReset }.

if not Config.LabCoke or not Config.LabCoke.Enabled then return end

-- Registrar en el runner. A partir de aquí el runner escucha:
--   'origen:Lab:OnEnter' con type == 'coke'  → crea puntos
--   'origen:Lab:OnExit'  con type == 'coke'  → limpia puntos y estado
LabProcessRunner.Register('coke', Config.LabCoke)

-- Compatibilidad con código existente que llame a este export directamente
exports('CokeLabResetProduction', function()
    LabProcessRunner.ResetProduction('coke')
end)
