local DefaultOverrideJob = "police" -- This is the default job that will be used when a player have a job not listed here
local CustomTranslations = {
    ["ambulance"] = {
        Report = "ReportEms",
        Reports = "ReportsEms",
        Fine = "ReportBillsEms",
        AddFine = "AddReportBillEms",
        ReportName = "ReportNameEms",
        ReportID = "ReportIdEms",
        ReportDescription = "ReportDescEms",
        Evidences = "ReportEvidencesEms",
        AddEvidence = "AddReportEvidenceEms",
        PeopleInvolved = "ReportPeopleEms",
        AddPeople = "ReportAddPeopleEms",
        AgentsInvolved = "ReportAgentsEms",
        AddAgent = "ReportAddAgentEms",
        ReportList = "ReportListEms",
        SearchReport = "SearchReportEms",
        NewReport = "NewReportEms",
        SelectReport = "SelectReportEms",
        AgentInCharge = "AgentInChargeEms",
        EnterReportDesc = "EnterReportDescEms",
        DestroyReport = "DestroyReportEms"
    }
}

function GenerateDefaultTranslations() -- This generate the default translations for the job that is not listed in the CustomTranslations table
    for job, _ in pairs(CustomTranslations) do
        CustomTranslations[DefaultOverrideJob] = {}
        for k, v in pairs(CustomTranslations[job]) do
            CustomTranslations[DefaultOverrideJob][k] = k
        end
        break
    end
end

local ReservedTranslations = {}
local currentOverrideJob = DefaultOverrideJob
function ApplyTranslationsOverride(job)
    if not job or not CustomTranslations[job] then
        job = DefaultOverrideJob
    end
    if currentOverrideJob == job then return end
    currentOverrideJob = job
    for k, v in pairs(CustomTranslations[job]) do
        if k == v then
            Translations[k] = ReservedTranslations[k] or Translations[k] -- Keep old translation if it exists
            ReservedTranslations[k] = nil -- Remove old translation
            goto skip
        end
        ReservedTranslations[k] = Translations[k] -- Save old translation
        Translations[k] = Translations[v]
        ::skip::
    end
    SendNUIMessage({
        action = "UpdateTranslations",
        translations = Translations,
    })
end

RegisterNetEvent('origen_police:client:OnJobUpdate', function(job)
    if not job or not job.name then return end
    ApplyTranslationsOverride(job.name)
end)

RegisterNetEvent('origen_police:client:OnPlayerLoaded', function()
    local Player = FW_GetPlayerData()
    if Player and Player.job and Player.job.name then
        ApplyTranslationsOverride(Player.job.name)
    end
end)

GenerateDefaultTranslations()