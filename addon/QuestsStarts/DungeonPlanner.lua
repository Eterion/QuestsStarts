local _, ns = ...
-- Recommended leveling bands (not entry restrictions). Prefer the client's LFG
-- recommendations when it exposes a matching dungeon; retain explicit fallbacks.
local recommendations={
    [2437]={13,18,lfgID=4},[718]={17,24,lfgID=1},[209]={22,30,lfgID=8},
    -- Classic Era Group Finder bands, unconfirmed for Forever; see README.
    -- Scarlet Monastery combines the Graveyard through Cathedral bands.
    [719]={24,32},[491]={29,38},[721]={29,38},[796]={30,46},[722]={37,46},
    [1337]={41,51},[1176]={44,54},[2100]={46,55},[1477]={50,60},
    [1584]={52,60},[1583]={55,60},[2557]={54,60},[2057]={58,60},[2017]={58,60},
    -- New Forever dungeon bands; reference recorded in README.
    [16611]={15,20},[16919]={13,18},[16732]={24,29},[16544]={28,33},
}
function ns.DungeonLevelRange(id,data)
    local range=recommendations[id]
    if not range then return end
    if range.lfgID and GetLFGDungeonInfo then
        local name,_,_,_,_,_,low,high=GetLFGDungeonInfo(range.lfgID)
        if name==data.dungeons[id].name and type(low)=='number' and type(high)=='number' and low>0 and high>=low then return low,high end
    end
    return range[1],range[2]
end

local function evaluate(id,data,state)
    if state.completed(id) then return 'completed' end
    if state.active(id) then return 'in log' end
    local available,reason=ns.IsAvailable(id,data.quests,state)
    if available then return 'available' end
    if available==nil then return 'unverified',reason end
    return 'blocked',reason
end

-- Planner state is independent of map display preferences. Low-level quests stay
-- in a dungeon checklist, and completed/logged steps remain visible as progress.
function ns.BuildDungeonPlan(data,dungeonID,player)
    local dungeon=data.dungeons and data.dungeons[dungeonID]
    if not dungeon then return {rows={},completed=0,accepted=0,total=0} end
    local state={}
    for key,value in pairs(player) do state[key]=value end
    state.showLowLevel=true
    local result={rows={},completed=0,accepted=0,total=0}
    for _,id in ipairs(dungeon.quests) do
        local status,reason=evaluate(id,data,state)
        local row={id=id,status=status,reason=reason,steps={}}
        local visited={}
        local function walk(current,depth,branch,path)
            if path[current] then
                row.steps[#row.steps+1]={id=current,status='unverified',reason='cyclic prerequisite',depth=depth,branch=branch}
                return
            end
            if visited[current] then return end
            visited[current]=true path[current]=true
            local currentStatus,currentReason=evaluate(current,data,state)
            local startLocations=data.pickups[current] or {}
            local insidePickup=#startLocations>0
            for _,location in ipairs(startLocations) do
                if not location.insideDungeon then insidePickup=false end
            end
            local q=data.quests[current]
            if q then
                if q.preQuestSingle and #q.preQuestSingle>0 then
                    for _,pre in ipairs(q.preQuestSingle) do
                        walk(math.abs(pre),depth+1,#q.preQuestSingle>1 and 'one of' or nil,path)
                    end
                else
                    for _,pre in ipairs(q.preQuestGroup or {}) do
                        walk(math.abs(pre),depth+1,'all',path)
                    end
                end
                if q.parentQuest then walk(q.parentQuest,depth+1,nil,path) end
                if q.availableStartingWith then walk(q.availableStartingWith,depth+1,nil,path) end
            end
            row.steps[#row.steps+1]={id=current,status=currentStatus,reason=currentReason,depth=depth,
                branch=branch,insidePickup=insidePickup}
            path[current]=nil
        end
        walk(id,0,nil,{})
        if reason~='race' and reason~='class' then
            result.rows[#result.rows+1]=row result.total=result.total+1
            if status=='completed' then result.completed=result.completed+1 end
            if status=='in log' then result.accepted=result.accepted+1 end
        end
    end
    return result
end

function ns.OrganizeDungeonPlan(data,plan)
    local sections={}
    for _,key in ipairs({'in log','available','inside','chains','blocked','completed'}) do sections[key]={} end
    local earlier,dependencies={},{}
    for _,row in ipairs(plan.rows) do
        dependencies[row.id]={}
        for index=1,#row.steps-1 do dependencies[row.id][row.steps[index].id]=true end
    end
    for _,row in ipairs(plan.rows) do
        for index,step in ipairs(row.steps) do
            if index<#row.steps and not step.branch and step.status~='unverified'
                and not (dependencies[step.id] and dependencies[step.id][row.id]) then
                earlier[step.id]=true
            end
        end
    end
    for _,row in ipairs(plan.rows) do
        local locations=data.pickups[row.id] or {}
        local inside,outside=false,false
        for _,location in ipairs(locations) do
            if location.insideDungeon then inside=true else outside=true end
        end
        row.insidePickup=inside and not outside
        row.hasChain=#row.steps>1
        local section
        if row.hasChain then section='chains'
        elseif row.status=='in log' or row.status=='completed' then section=row.status
        elseif row.insidePickup then section='inside'
        elseif row.status=='available' or row.status=='unverified' then section='available'
        else section='blocked' end
        row.section=section
        if not earlier[row.id] then sections[section][#sections[section]+1]=row end
    end
    return sections
end

local function hasEntranceOnMap(dungeon,mapID,continentID)
    for _,entrance in ipairs(dungeon.entrances or {}) do
        if entrance.mapID==mapID or (continentID and ns.GetChecklistContinent(entrance.mapID)==continentID) then
            return true
        end
    end
    return false
end

function ns.ListDungeons(data,player,mapID)
    local list={}
    local world=not mapID or ns.IsChecklistWorldMap(mapID)
    local continentID=not world and ns.GetChecklistContinent(mapID)
    local continentScope=continentID==mapID and continentID or nil
    for id,dungeon in pairs(data.dungeons or {}) do
        if world or hasEntranceOnMap(dungeon,mapID,continentScope) then
            local plan=ns.BuildDungeonPlan(data,id,player)
            local minimum,available=math.huge,0
            for _,row in ipairs(plan.rows) do
                local q=data.quests[row.id]
                minimum=math.min(minimum,q and q.requiredLevel or math.huge)
                if row.status=='available' then available=available+1 end
            end
            if plan.total>0 then
                local low,high=ns.DungeonLevelRange(id,data)
                list[#list+1]={id=id,name=dungeon.name,minLevel=minimum<math.huge and minimum or nil,
                    levelLow=low,levelHigh=high,eligible=player.level>=minimum,available=available,accepted=plan.accepted,completed=plan.completed,total=plan.total}
            end
        end
    end
    table.sort(list,function(a,b)
        if a.eligible~=b.eligible then return a.eligible end
        if a.minLevel~=b.minLevel then return (a.minLevel or 999)<(b.minLevel or 999) end
        return a.name<b.name
    end)
    return list
end

function ns.PickupLabel(location,data)
    if location.fromQuest then
        local quest=data.quests[location.fromQuest]
        return (location.name or UNKNOWN)..' (item from '..(quest and quest.name or 'Quest '..location.fromQuest)..')'
    end
    local source=location.droppedBy and (', dropped by '..location.droppedBy)
        or location.foundIn and (', found in '..location.foundIn) or ''
    if location.insideDungeon then
        local dungeon=data.dungeons[location.insideDungeon]
        return (location.name or UNKNOWN)..' (inside '..(dungeon and dungeon.name or 'dungeon')..source..')'
    end
    local mapID=location.mapID or location.zoneMapID
    local map=C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(mapID)
    local mapName=map and map.name or data.mapNames and data.mapNames[mapID] or 'Map '..tostring(mapID)
    local hint=location.locationHint and (', '..location.locationHint) or ''
    if location.zoneMapID and not location.mapID then hint=hint..', coordinates unknown' end
    return (location.name or UNKNOWN)..' ('..mapName..hint..source..')'
end
