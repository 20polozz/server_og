Config.MultifrecOrdered = {
    {
        category = "LSPD",
        freqs = {
            "Asignacion LSPD",
            "AIRE-10",
            "AIRE-20",
            "6-LINCOLN-10",   
            "6-ADAM-100",
            "Central LSPD",
            "6-ADAM-10",
            "6-ADAM-20",
            "6-ADAM-30",
            "6-ADAM-40",
            "6-ADAM-50",
            "6-ADAM-60",
            "6-ADAM-70",
            "6-ADAM-80",
            "6-ADAM-90", 
            "6-MARY-1",
            "6-MARY-2",
            "6-UNION-10",
            "6-UNION-20",
            "6-KING-10",
            "6-KING-20",
            "7-ADAM-10",
            "7-ADAM-20",
            "7-ADAM-30",
            "7-ADAM-40",
            "7-ADAM-50",
            "7-ADAM-60",
            "7-ADAM-70",
            "7-ADAM-80",
            "7-ADAM-90",
            "7-ADAM-100",
            "7-LINCOLN-10",
        }
    },
    {
        category = "BCSD",
        freqs = {
            "Asignacion BCSD",
            "AIRE-30",
            "AIRE-40",
            "Central BCSD",
            "DISPATCH",
            "283-SAM-100",
            "283-SAM-200",
            "283-SAM-300",
            "283-ADAM-11",
            "283-ADAM-12",
            "283-ADAM-13",
            "283-ADAM-14",
            "283-ADAM-15",
            "283-ADAM-16",
            "283-ADAM-17",
            "283-ADAM-18",
            "283-ADAM-19",
            "283-ADAM-21",
            "283-ADAM-22",
            "283-ADAM-23",
            "283-ADAM-24",
            "283-ADAM-25",
            "283-MERY-11",
            "283-MERY-12",
            "283-MERY-13",
            "283-MERY-14",
        }
    },
    {
        category = "UNIDADES SAPD",
        freqs = {
            "TAC-01",
            "TAC-02",
            "TAC-03",
            "TAC-04",
            "TAC-05",
            "TAC-06",
            "TAC-07",
            "TAC-08",
            "TAC-09",
            "TAC-10",
            "OPERATIVO-10",
            "OPERATIVO-20",
            "OPERATIVO-30",
            "OPERATIVO-40",
            "OPERATIVO-50",
            "LIBRE-10",
            "LIBRE-20",
            "LIBRE-30",
            "OFICINA-METRO",
            "METRO-10",
            "METRO-20",
            "DAVID-10",
            "DAVID-20",
            "OFICINA-K9",
            "K9-10",
            "K9-20",
            "OFICINA-DETECTIVES",
            "DB-10",
            "DB-20",
            "DB-30",
            "OFICINA-RTD",
            "RTD-10",
            "RTD-20",
            "OFICINA-ASD",
            "ASD-10",
            "ASD-20",
            "OFICINA-SAHP",
            "SAHP-10",
            "SAHP-20",
            "OFICINA-RRPP",
            "RRPP-10",
            "Comisaria LSPD",
            "Comisaria BCSD",
            "ESCALA EJECUTIVA",
            "ESCALA MANDO",
        }
    },
    {
        category = "SASPA",
        freqs = {
            "Central SASPA",
            "Capitania",
            "Batallon",
            "Esc. Alfa",
            "Esc. Beta",
            "Esc. Omega",
            "Celdas",
            "Patio",
            "Puertas",
            "Reten Exterior",
            "Pajaro Loco",
        }
    },{
        category = "FIB",
        freqs = {
            "Central FIB",
            "FIB-AIR-1",
            "FIB-AIR-2",
            "FIB-TAC-1",
            "FIB-TAC-2",
            "FIB-TAC-3",
            "FIB-TAC-4",
            "FIB-TAC-5",
            "FIB-TAC-6",
            "FIB-TAC-7",
            "FIB-TAC-8",
            "FIB-TAC-9",
            "FIB-TAC-10",
            "FIB-COMMAND",
            "FIB-OPS-1",
            "FIB-OPS-2",
            "FIB-OPS-3",
            "FIB-OPS-4",
            "FIB-SURV-1",
            "FIB-SURV-2",
            "FIB-SURV-3",
            "FIB-SURV-4",
            "FIB-INTEL-1",
            "FIB-INTEL-2",
            "FIB-INTEL-3",
            "FIB-INTEL-4",
            "FIB-SECURE-1",
            "FIB-SECURE-2",
            "FIB-SECURE-3",
            "FIB-SECURE-4",
            "FIB-ALPHA",
            "FIB-BRAVO",
            "FIB-CHARLIE",
            "FIB-DELTA",
        }
    },
    {
        category = "UNIDADES SAMS",
        freqs = {
            "Espera asignación",
            "Cafetería",
            "Central SAMS",
            "Hospital Sur",
            "Hospital Norte",
            "Unidad-10",
            "Unidad-20",
            "Unidad-30",
            "Unidad-40",
            "Unidad-50",
            "Unidad-60",
            "Quirófano A",
            "Quirófano B",
            "Quirófano C",
            "Consultorio-10",
            "Consultorio-20",
            "Consultorio-30",
            "Jefatura Instrucción",
            "Instru-10",
            "Instru-20",
            "Instru-30",
            "Instru-40",
            "Instru-50",
            "Instru-60",
            "Área Psicología",
            "Psico-10",
            "Psico-20",
            "Psico-30",
            "Aerea-10",
            "Aerea-20",
            "Area R.R.P.P",
            "Citaciones",
            "Oficina Directiva SAMS",
            "Oficina Jefes Hospitalarias",
            "Oficina Dirección",
        }
    }
}

Config.Multifrec = {}
for _, v in ipairs(Config.MultifrecOrdered) do
    Config.Multifrec[v.category] = v.freqs
end

Config.ButtonsMultiFreqOrdered = {
    { label = "BROADCAST SAMS", categories = {"UNIDADES SAMS"} },
    { label = "BROADCAST SAPD", categories = {"BCSD", "LSPD"} }
}

Config.ButtonsMultiFreq = {}
for _, v in ipairs(Config.ButtonsMultiFreqOrdered) do
    Config.ButtonsMultiFreq[v.label] = v.categories
end

Config.BindFreqsOrdered = {
    { label = "hablar-central-lspd", freqs = {"Central LSPD"}, description = "Habla al canal de central de LSPD"},
    { label = "hablar-central-bcsd", freqs = {"Central BCSD"}, description = "Habla al canal de central de BCSD"},
    { label = "hablar-central-sams", freqs = {"Central SAMS"}, description = "Habla al canal de central de SAMS"},
    { label = "hablar-central-saspa", freqs = {"Central SASPA"}, description = "Habla al canal de central de SASPA"},
    { label = "hablar-central-fib", freqs = {"Central FIB"}, description = "Habla al canal de central de FIB"},
    { label = "hablar-lspd", freqs = {"LSPD"}, description = "Hablar a todas las frecuencias de LSPD"},
    { label = "hablar-bcsd", freqs = {"BCSD"}, description = "Hablar a todas las frecuencias de BCSD"},
    { label = "hablar-sams", freqs = {"UNIDADES SAMS"}, description = "Hablar a todas las frecuencias de SAMS"},
    { label = "hablar-sapd", freqs = {"BCSD", "LSPD"}, description = "Hablar a todas las frecuencias de BCSD y LSPD"},
    { label = "hablar-unidades-sapd", freqs = {"UNIDADES SAPD"}, description = "Hablar a todas las frecuencias de Unidades SAPD"},
    { label = "hablar-fib", freqs = {"FIB"}, description = "Hablar a todas las frecuencias de FIB"},
}

Config.BindFreqs = {}
for _, bind in ipairs(Config.BindFreqsOrdered) do
    local copy = {}
    for _, f in ipairs(bind.freqs) do
        table.insert(copy, f)
    end
    Config.BindFreqs[bind.label] = copy
end

Config.MegaphoneVoiceDist = 50.0 -- The distance that the voice of the megaphone will be heared
Config.MegaphoneItemVoiceDist = 25.0 -- The distance that the voice of the handheld megaphone will be heard

exports("GetPoliceRadioBinds", function()
    return Config.BindFreqsOrdered
end)

exports("GetPoliceRadioChannels", function()
    return Config.MultifrecOrdered
end)

exports("GetPoliceRadioButtons", function()
    return Config.ButtonsMultiFreqOrdered
end)

Config.RequestsTime = 10 -- Minutos

-- DONT TOUCH THIS

function GetCategoryFreqs(category)
    local list = Config.Multifrec[category]
    if not list then
        print("Category not found: " .. category .. " in Config.Multifrec")
        return {}
    end
    local freqs = {}
    for _, v in pairs(list) do
        table.insert(freqs, v)
    end
    return freqs
end

local nextButtonMultiFreqUpdate = {}
for buttonName, categories in pairs(Config.ButtonsMultiFreq) do
    for _, category in pairs(categories) do
        for _, v in pairs(GetCategoryFreqs(category)) do
            if nextButtonMultiFreqUpdate[buttonName] == nil then
                nextButtonMultiFreqUpdate[buttonName] = {}
            end
            nextButtonMultiFreqUpdate[buttonName][#nextButtonMultiFreqUpdate[buttonName] + 1] = v
        end
    end
end

local newBindFreqs = {}
for button, freqs in pairs(Config.BindFreqs) do
    for _, freq in pairs(freqs) do
        if Config.Multifrec[freq] then
            for _, freq2 in pairs(Config.Multifrec[freq]) do
                newBindFreqs[button] = newBindFreqs[button] or {}
                table.insert(newBindFreqs[button], freq2:lower())
            end
        else
            newBindFreqs[button] = newBindFreqs[button] or {}
            table.insert(newBindFreqs[button], freq)
        end
    end
end

for button, freqs in pairs(newBindFreqs) do
    Config.BindFreqs[button] = freqs
end

Config.ButtonsMultiFreq = nextButtonMultiFreqUpdate