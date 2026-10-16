Config = Config or {}
Mechanic = {}
Custom = {}
Internal = {}
IsServer = IsDuplicityVersion()

Mechanic.StateKey = 'mechanicHealth'

Mechanic.ComponentCondition = {
    FAILED = 'failed',
    CRITICAL = 'critical',
    WORN = 'worn',
    OPTIMAL = 'optimal'
}

Mechanic.ServiceCondition = {
    OVERDUE = 'overdue',
    DUE = 'due',
    OK = 'ok'
}

Mechanic.FuelType = {
    COMBUSTION = 'combustion',
    ELECTRIC = 'electric',
    BOTH = 'both'
}

--[[ Quien esta ocupado con el taller lo apunta aqui. Existe porque los avisos de
     [E] de otros recursos —empujar un coche, esconderse en un maletero— se pisan
     con los del taller: comparten tecla y comparten pantalla. ]]
Mechanic.Ocupacion = {}

function Mechanic.EstaOcupado()
    for _, informa in pairs(Mechanic.Ocupacion) do
        local ok, ocupado = pcall(informa)
        if ok and ocupado then return true end
    end

    return false
end
