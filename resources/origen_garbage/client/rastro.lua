--[[ ── Sin rastro ─────────────────────────────────────────────────────────────

     Todo lo que el basurero crea en el mundo de este cliente (el
     encargado y la bolsa en la mano) lleva la marca `origen_garbage`. Al parar el recurso se borra todo lo
     marcado, y al arrancar se vuelve a barrer: si el recurso se cayó sin
     despedirse o algo se quedó huérfano, no sobrevive a un reinicio.

     Los cables (ropes) no son entidades: cada módulo apunta los suyos en
     `Rastro.Cable` y se borran aquí también. ]]

Rastro = {}

local MARCA = 'origen_garbage'
DecorRegister(MARCA, 3)

function Rastro.Marcar(ent)
    if ent and ent ~= 0 and DoesEntityExist(ent) then DecorSetInt(ent, MARCA, 1) end
    return ent
end

local cables = {}

--- Apunta un cable para borrarlo al parar. Devuelve el mismo cable.
function Rastro.Cable(cuerda)
    if cuerda then cables[cuerda] = true end
    return cuerda
end

function Rastro.QuitarCable(cuerda)
    if not cuerda then return end
    cables[cuerda] = nil
    if DoesRopeExist(cuerda) then DeleteRope(cuerda) end
end

local function Quitar(ent)
    if not DoesEntityExist(ent) then return end
    if IsEntityAttached(ent) then DetachEntity(ent, false, false) end
    SetEntityAsMissionEntity(ent, true, true)
    DeleteEntity(ent)
end

function Rastro.Barrer()
    local n = 0
    for _, ent in ipairs(GetGamePool('CObject')) do
        if DecorExistOn(ent, MARCA) then Quitar(ent) n = n + 1 end
    end
    for _, ped in ipairs(GetGamePool('CPed')) do
        if DecorExistOn(ped, MARCA) and not IsPedAPlayer(ped) then Quitar(ped) n = n + 1 end
    end
    for cuerda in pairs(cables) do
        if DoesRopeExist(cuerda) then DeleteRope(cuerda) end
    end
    cables = {}
    return n
end

Rastro.Barrer()

AddEventHandler('onResourceStop', function(r)
    if r ~= GetCurrentResourceName() then return end
    Rastro.Barrer()
end)
