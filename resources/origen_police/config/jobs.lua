Config.JobCategory = {
    ["police"] = {
        {
            name = "police",
            titleListLabel = "LSPD",
            color = "#3f5ba1",
            badge = "lspd_badge", -- lspd_badge | bcsd_badge | fib_badge
            penalFilter = "police", -- The name of the penal code filter to separate the penal code by job
            colorHueDeg = 0, -- The hue degree of the color, 0 is the default color, you can change it to get a different color
            society = "police", -- The name of the society that will receive the money when a player pay a bill
        },
        {
            name = "sheriff",
            titleListLabel = "BCSD",
            color = "#a1823f",
            badge = "bcsd_badge", -- lspd_badge | bcsd_badge | fib_badge
            penalFilter = "police", -- The name of the penal code filter to separate the penal code by job
            colorHueDeg = 0, -- The hue degree of the color, 0 is the default color, you can change it to get a different color
            society = "police", -- The name of the society that will receive the money when a player pay a bill
        },
        {
            name = "sapd",
            titleListLabel = "SAPD",
            color = "#1f1f1fff",
            badge = "lspd_badge",
            penalFilter = "police",
            colorHueDeg = 0, -- The hue degree of the color, 0 is the default color, you can change it to get a different color
            society = "police",
        },
    },
    ["ambulance"] = {
        {
            name = "ambulance",
            titleListLabel = "SAMS",
            color = "#bf3737",
            badge = "ems_badge", -- lspd_badge | bcsd_badge | fib_badge | ems_badge
            penalFilter = "ambulance", -- The name of the penal code filter to separate the penal code by job
            colorHueDeg = 140, -- The hue degree of the color, 0 is the default color, you can change it to get a different color
            society = "ambulance", -- The name of the society that will receive the money when a player pay a bill
        },
    },
    ["saspa"] = {
        {
            name = "saspa",
            titleListLabel = "SASPA",
            color = "#054708ff",
            badge = "lspd_badge",
            penalFilter = "police",
            colorHueDeg = 0, -- The hue degree of the color, 0 is the default color, you can change it to get a different color
            society = "police",
        },
    },
    ["fib"] = {
        {
            name = "fib",
            titleListLabel = "FIB",
            color = "#050141ff",
            badge = "fib_badge",
            penalFilter = "police",
            colorHueDeg = 0, -- The hue degree of the color, 0 is the default color, you can change it to get a different color
            society = "fib",
        },
    },
    ["doj"] = {
        {
            name = "doj",
            titleListLabel = "DOJ",
            color = "#8b7355",
            badge = "lspd_badge",
            penalFilter = "police",
            colorHueDeg = 0,
            society = "doj",
        },
    },
}

Config.PoliceJobCategory = "police" -- This is to send the police alerts to a specific job category
Config.EmsJobCategory = "ambulance" -- If you want to remove ems jobs you can set this to nil
Config.BossGrade = { 4 }  -- ONLY ESX, set the grades that will be considered as boss and will have more permissions like manage penal code

--[[ Como se presenta cada categoria en el menu rapido del riel del inventario.

     El recurso no es solo de policia: la tablet y el menu rapido los abre
     cualquiera de las categorias de arriba. Sin esto, a un sanitario le salia
     un boton que ponia "Policia" con un icono de sirena, y el panel se abria
     de azul policial diciendo ORIGEN POLICIA.

     De cada categoria se saca:
       · `label`  el nombre del boton en el riel del inventario;
       · `brand`  el rotulo del canto y del pie del panel;
       · `icon`   el icono del boton, en nombre de lucide;
       · `accent` el color de la pantalla.

     Los colores NO son los `color` de cada trabajo de aqui arriba: aquellos
     son para el mapa y la lista de agentes, y varios son casi negros —el FIB
     es #050141—, que sobre el fondo del panel no se ven. Estos estan elegidos
     para leerse sobre negro y para no confundirse con los tres colores que ya
     significan algo en la pantalla: verde "libre", ambar "ocupado" y rosa
     "aviso". Cambialos si quieres, pero mirando eso.

     Una categoria que no este aqui cae en `Config.CategoryUI.default`, y se ve
     igual: perderla seria peor que enseñarla sin su color. ]]
Config.CategoryUI = {
    default = {
        label = "Servicio",
        brand = "Origen Servicio",
        icon = "lucide:shield",
        accent = "#8a8a94",
    },
    ["police"] = {
        label = "Policía",
        brand = "Origen Policía",
        icon = "lucide:siren",
        accent = "#2f7fe0",
    },
    ["ambulance"] = {
        label = "Sanidad",
        brand = "Origen Sanidad",
        icon = "lucide:briefcase-medical",
        -- Turquesa: el rojo de las ambulancias se confundiria con el rosa de
        -- los avisos, y el verde con el "libre" de la lista de agentes.
        accent = "#2fb8c6",
    },
    ["saspa"] = {
        label = "SASPA",
        brand = "Origen SASPA",
        icon = "lucide:trees",
        accent = "#4f9e57",
    },
    ["fib"] = {
        label = "FIB",
        brand = "Origen FIB",
        icon = "lucide:shield",
        accent = "#7d6bff",
    },
    ["doj"] = {
        label = "DOJ",
        brand = "Origen Justicia",
        icon = "lucide:scale",
        accent = "#c89b3c",
    },
}

-- DON'T TOUCH BELOW THIS LINE UNLESS YOU KNOW WHAT YOU ARE DOING
function GetJobCategory(jobName)
    for category, jobs in pairs(Config.JobCategory) do
        for _, job in pairs(jobs) do
            if job.name:lower() == jobName:lower() then
                return category
            end
        end
    end
    return nil
end

if Config.EmsJobCategory ~= nil and Config.JobCategory[Config.EmsJobCategory] == nil then
    print("Warning: The EMS job category '"..Config.EmsJobCategory.."' does not exist in Config.JobCategory. If you want to remove EMS jobs, set Config.EmsJobCategory to nil.")
elseif Config.JobCategory[Config.PoliceJobCategory] == nil then
    print("Warning: The Police job category '"..Config.PoliceJobCategory.."' does not exist in Config.JobCategory.")
end