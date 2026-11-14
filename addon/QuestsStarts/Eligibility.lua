local _, ns = ...
local function hasBit(mask, value)
    return math.floor(mask / value) % 2 == 1
end
ns.HasBit = hasBit

-- Pure state evaluation shared by the UI and offline behavioral tests.
-- true = passes supported checks, false = known unavailable, nil = unknown requirement.
function ns.IsAvailable(id, quests, state)
    local q = quests[id]
    if not q then return nil, 'missing quest data' end
    if state.completed(id) then return false, 'completed' end
    if state.active(id) then return false, 'in quest log' end
    if q.requiredRaces and q.requiredRaces ~= 0 then
        if not state.raceMask then return nil, 'unknown race' end
        if not hasBit(q.requiredRaces, state.raceMask) then return false, 'race' end
    end
    if q.requiredClasses and q.requiredClasses ~= 0 then
        if not state.classMask then return nil, 'unknown class' end
        if not hasBit(q.requiredClasses, state.classMask) then return false, 'class' end
    end
    -- Race/class exclusions must remain visible to the dungeon planner even
    -- when the same quest is also above the character's level.
    if (q.requiredLevel or 0) > state.level then return false, 'minimum level' end
    if q.requiredMaxLevel and q.requiredMaxLevel < state.level then return false, 'maximum level' end
    local event = ns.GetQuestEvent(id, q)
    -- Inactive holidays are unavailable, even when uncertain pickups are enabled.
    if event and not ns.IsEventAvailable(event, state) then return false, 'inactive holiday' end
    if not event and (q.questLevel or 0) > state.level + 5 then return false, 'recommended level' end
    if state.showLowLevel == false and q.questLevel and q.questLevel > 0
        and q.questLevel < state.level - (state.trivialRange or 5) then return false, 'low-level filter' end
    local function isDone(dependency)
        if state.completed(math.abs(dependency)) then return true end
        -- Positive group requirements can also be satisfied by an exclusive alternative.
        if dependency > 0 then
            local pre = quests[dependency]
            for _, alternative in ipairs(pre and pre.exclusiveTo or {}) do
                if state.completed(math.abs(alternative)) then return true end
            end
        end
        return false
    end
    if q.preQuestSingle and #q.preQuestSingle > 0 then
        local any = false
        for _, pre in ipairs(q.preQuestSingle) do if state.completed(math.abs(pre)) then any = true end end
        if not any then return false, 'prerequisite' end
    elseif q.preQuestGroup then
        for _, pre in ipairs(q.preQuestGroup) do if not isDone(pre) then return false, 'prerequisite' end end
    end
    for _, exclusive in ipairs(q.exclusiveTo or {}) do
        if state.completed(math.abs(exclusive)) or state.active(math.abs(exclusive)) then return false, 'exclusive quest' end
    end
    for _, field in ipairs({'nextQuestInChain', 'breadcrumbForQuestId', 'availableUntilCompleted'}) do
        local other = q[field]
        if other and (state.completed(other) or (field ~= 'availableUntilCompleted' and state.active(other))) then return false, 'quest chain state' end
    end
    if q.parentQuest and not state.active(q.parentQuest) then return false, 'parent quest' end
    if q.disabledByQuest and state.active(q.disabledByQuest) then return false, 'disabling quest' end
    if q.availableStartingWith and not (state.active(q.availableStartingWith) or state.completed(q.availableStartingWith)) then return false, 'enabling quest' end
    local unknown
    if q.requiredSkill then
        local pair=q.requiredSkill
        local rank=type(pair)=='table' and type(pair[1])=='number' and state.skill and state.skill(pair[1])
        if type(rank)~='number' or type(pair[2])~='number' then unknown='requiredSkill'
        elseif rank<=0 then return false,'profession'
        elseif rank<pair[2] then return false,'profession skill' end
    end
    for _,field in ipairs({'requiredMinRep','requiredMaxRep'}) do
        local pair=q[field]
        if pair then
            local value=type(pair)=='table' and type(pair[1])=='number' and state.reputation and state.reputation(pair[1])
            if type(value)~='number' or type(pair[2])~='number' then unknown=unknown or field
            elseif field=='requiredMinRep' and value<pair[2] then return false,'minimum reputation'
            elseif field=='requiredMaxRep' and value>=pair[2] then return false,'maximum reputation' end
        end
    end
    -- Special gates are not guessed: opt-in uncertain pins remain visually distinct.
    for _, field in ipairs({'requiredSpell','requiredSpecialization','requiredRanks'}) do
        if q[field] then unknown=unknown or field end
    end
    if unknown then return nil,unknown end
    if hasBit(q.specialFlags or 0, 2) and not event then return nil, 'event-gated quest' end
    if q.sourceUnverified then return nil,'pickup source unverified' end
    return true
end

function ns.BuildGroups(data, mapID, state, includeUnknown, nativeOffers)
    local groups, stats, counted = {}, {total=0,eligible=0,hidden={}}, {}
    -- QuestieDB lists the library collection records as Research Access alternatives.
    local bookIDs={}
    local research=data.quests[97286]
    for _,id in ipairs(research and research.preQuestSingle or {}) do bookIDs[id]=true end
    for _, starter in ipairs(data.maps[mapID] or {}) do
        local group = {starter=starter, quests={}}
        local seen = {}
        for _, id in ipairs(starter.quests) do
            local collection=starter.kind=='Object' and bookIDs[id]
            local itemSource=starter.kind=='Item' or collection
            local available, reason = ns.IsAvailable(id, data.quests, state)
            local bookItem=collection and data.quests[id] and data.quests[id].libraryBookItem
            local bookLocation
            if bookItem and state.hasItem and reason~='completed' then
                if state.hasItem(bookItem) then bookLocation='bags'
                elseif state.hasItem(bookItem,true) then bookLocation='bank' end
                if bookLocation then available,reason=true,nil end
            end
            local turnedIn=collection and reason=='completed'
            if turnedIn then
                available=state.showTurnedInBooks==true
                if available then reason=nil end
            elseif itemSource and state.showItemStarts==false then
                available,reason=false,'item sources hidden'
            elseif not itemSource and state.showQuestGivers==false then
                available,reason=false,'quest givers hidden'
            end
            if available~=false and starter.kind=='Item' and state.hasItem and state.hasItem(starter.id) then
                available,reason=false,'quest item in bags'
            end
            local nativeOffer=nativeOffers and nativeOffers[id] and not bookLocation and not turnedIn
            if not counted[id] then
                counted[id]=true stats.total=stats.total+1
                local hidden
                if nativeOffer then hidden='native map pin'
                elseif available then stats.eligible=stats.eligible+1
                elseif available==nil and includeUnknown then stats.eligible=stats.eligible+1
                else hidden=reason or 'unverified requirements' end
                if hidden then stats.hidden[hidden]=(stats.hidden[hidden] or 0)+1 end
            end
            if not seen[id] and not nativeOffer and (available or (available == nil and includeUnknown)) then
                seen[id] = true
                group.quests[#group.quests+1] = {id=id, uncertain=available==nil, reason=reason,
                    collection=collection, bookLocation=bookLocation, turnedIn=turnedIn}
            end
        end
        if #group.quests > 0 then groups[#groups+1] = group end
    end
    return groups, stats
end
