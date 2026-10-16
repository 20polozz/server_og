local PlayerAccessCache = {}
local JobCategoryParsed = {}

function CanOpenTablet(xjob) -- This function is used to check if the player can open the tablet.
    if not xjob then return {false, nil, nil}; end
    if type(xjob) == "table" and xjob.name then
        xjob = xjob.name
    end
    if type(xjob) == "number" or (type(xjob) == "string" and tonumber(xjob) and tonumber(xjob) > 0 and not (Config.JobCategory and Config.JobCategory[xjob])) then
        local player = FW_GetPlayer(tonumber(xjob))
        if player == nil or player.PlayerData == nil or player.PlayerData.job == nil or player.PlayerData.job.name == nil then
            return {false, nil, nil};
        end
        xjob = player.PlayerData.job.name
    end

    local cleanJob = string.lower(tostring(xjob))

    -- Fallback directo para cuerpos oficiales y DOJ (garantiza acceso siempre)
    if cleanJob == "police" or cleanJob == "sheriff" or cleanJob == "sapd" or cleanJob == "saspa" or cleanJob == "fib" or cleanJob == "doj" then
        local cat = (cleanJob == "doj" and "doj") or (cleanJob == "saspa" and "saspa") or (cleanJob == "fib" and "fib") or "police"
        return {true, cat, "police"};
    end

    for category, jobList in pairs(Config.JobCategory or {}) do
        for _, job in pairs(jobList) do
            if string.lower(tostring(job.name)) == cleanJob then
                if job.penalFilter == nil then
                    print("ERROR: The job "..job.name.." does not have a penalFilter set in the config/permissions.lua file.")
                end
                return {true, category, job.penalFilter or "police"};
            end
        end
    end

    local job = JobCategoryParsed[cleanJob]

    return job and {true, job.category, job.penalFilter or "police"} or {false, nil, nil};
end

exports("CanOpenTablet", CanOpenTablet) -- exports['origen_police']:CanOpenTablet('police')

function GetMinimunGrade(jobName, param)
    if not jobName then return 888 end
    if jobName == "sapd" then return 0 end
    if Config.Permissions[jobName] and Config.Permissions[jobName][param] then
        return Config.Permissions[jobName][param]
    end
    -- Si no existe en este job, intentar heredar de "police" como fallback
    if Config.Permissions["police"] and Config.Permissions["police"][param] then
        return Config.Permissions["police"][param]
    end
    Debuger("ERROR: The job "..tostring(jobName).." does not exist in the config file or the parameter "..tostring(param).." is not set.")
    return 888
end

exports("GetMinimunGrade", GetMinimunGrade)

function GetTableLength(table)
    if type(table) ~= "table" then return 0 end
    if(table == nil) then return 0 end
    local count = 0
    for _ in pairs(table) do count = count + 1 end
    return count
end

function TableContains(table, value)
    if type(table) ~= "table" then return false end
    if(table == nil) then return false end
    for _, v in pairs(table) do
        if v == value then
            return true
        end
    end
    return false
end

function ParseConfigJobs()
    JobCategoryParsed = {}
    for category, jobList in pairs(Config.JobCategory) do
        for _, job in pairs(jobList) do
            JobCategoryParsed[string.lower(job.name)] = {category = category, penalFilter = job.penalFilter or "police"}
        end
    end
end

ParseConfigJobs()
exports("ParseConfigJobs", ParseConfigJobs)
exports("CanOpenTablet", CanOpenTablet)

function HandleJsonException(reason, value)
    if type(value) == 'function' then return tostring(value) end
    return reason
end