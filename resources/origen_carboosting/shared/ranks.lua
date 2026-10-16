local function getRanksPool(missionType)
    missionType = tostring(missionType or 'vehicle')
    if GlobalState and GlobalState.RanksByType and GlobalState.RanksByType[missionType] and #GlobalState.RanksByType[missionType] > 0 then
        return GlobalState.RanksByType[missionType]
    end
    return GlobalState.Ranks or {}
end

function GetRankByXP(xp, missionType)
    local ranks = getRanksPool(missionType)
    if not ranks or #ranks == 0 then
        return {
            actualRank = {
                name = 'N/A',
                xp = tonumber(xp) or 0
            },
            nextRank = false
        }
    end

    xp = tonumber(xp) or 0
    for i, rank in ipairs(ranks) do
        if xp >= rank.xp then
            xp = xp - rank.xp
        else
            local nextRank = ranks[i + 1]
            return {
                actualRank = {
                    name = rank.name,
                    xp = xp
                },
                nextRank = nextRank and {
                    name = nextRank.name,
                    xp = rank.xp
                } or false
            }
        end
    end
    return {
        actualRank = {
            name = ranks[#ranks].name,
            xp = xp
        },
        nextRank = false
    }
end

function canStartContract(xp, rank, missionType)
    local ranks = getRanksPool(missionType)
    -- If ranks can't be determined, allow through (fail-open) to avoid blocking all contracts
    if not ranks or #ranks == 0 then
        return true
    end
    local userRank = GetRankByXP(xp, missionType).actualRank.name
    -- If user rank is 'N/A' (ranks pool unavailable during GetRankByXP call), allow through
    if userRank == 'N/A' then
        return true
    end
    local userRankIndex = 0
    local contractRankIndex = 0
    for i = 1, #ranks do
        if ranks[i].name == userRank then
            userRankIndex = i
        end
        if ranks[i].name == rank then
            contractRankIndex = i
        end
    end
    -- If either rank can't be found in the pool, allow through
    if userRankIndex == 0 or contractRankIndex == 0 then
        return true
    end
    local result = userRankIndex >= contractRankIndex
    return result
end