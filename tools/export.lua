-- Run from the pinned QuestieDB checkout; see tools/build.ps1.
local output, revision, classFile, classId = assert(arg[1]), assert(arg[2]), assert(arg[3]), tonumber(arg[4])
local toolRoot=assert(arg[0]:match('^(.*[\\/])'))
local corrections=dofile(toolRoot..'forever-overrides.lua')
local client = dofile('emulator/client.lua')
client.install({ expansion='Forever', faction='Horde', raceName='Undead', raceFile='Scourge', raceId=5, classFile=classFile, classId=classId })
local db = dofile('emulator/metadata.lua').loadAddon('QuestieDB.toc', 'QuestieDB')
local zone = db.Support.Get('ZoneDB')
local mapIds = assert(loadstring(zone.private.areaIdToUiMapId))()
local overrides = assert(loadstring(zone.private.areaIdToUiMapIdOverride))()
for area, map in pairs(overrides) do mapIds[area] = map end
local fields = {'name','requiredLevel','questLevel','requiredRaces','requiredClasses','preQuestGroup','preQuestSingle','exclusiveTo','zoneOrSort','requiredSkill','requiredMinRep','requiredMaxRep','nextQuestInChain','questFlags','specialFlags','parentQuest','breadcrumbForQuestId','requiredSpell','requiredSpecialization','requiredMaxLevel','availableUntilCompleted','availableStartingWith','requiredRanks','disabledByQuest'}
local quests, starters, included = {}, {}, {}
local libraryBooks={}
for _,id in ipairs(db.Quest.preQuestSingle(97286) or {}) do libraryBooks[id]=true end
local coveredMaps = {
    [1420]='Tirisfal Glades', [1411]='Durotar', [1413]='The Barrens',
    [1421]='Silverpine Forest', [1454]='Orgrimmar', [1458]='Undercity', [1456]='Thunder Bluff',
    [1412]='Mulgore', [1442]='Stonetalon Mountains', [1440]='Ashenvale',
    [1441]='Thousand Needles', [1424]='Hillsbrad Foothills',
    [1416]='Alterac Mountains', [1417]='Arathi Highlands', [1418]='Badlands', [1419]='Blasted Lands',
    [1422]='Western Plaguelands', [1423]='Eastern Plaguelands', [1425]='The Hinterlands',
    [1426]='Dun Morogh', [1427]='Searing Gorge', [1428]='Burning Steppes', [1429]='Elwynn Forest',
    [1430]='Deadwind Pass', [1431]='Duskwood', [1432]='Loch Modan', [1433]='Redridge Mountains',
    [1434]='Stranglethorn Vale', [1435]='Swamp of Sorrows', [1436]='Westfall', [1437]='Wetlands',
    [1438]='Teldrassil', [1439]='Darkshore', [1443]='Desolace', [1444]='Feralas',
    [1445]='Dustwallow Marsh', [1446]='Tanaris', [1447]='Azshara', [1448]='Felwood',
    [1449]="Un'Goro Crater", [1450]='Moonglade', [1451]='Silithus', [1452]='Winterspring',
    [1453]='Stormwind City', [1455]='Ironforge', [1457]='Darnassus',
    [2482]='Mount Hyjal', [2521]='Zephras Isle',
    [2548]='Riverglades', [2652]="Shen'dralas",
}
local dungeons,insideDungeonByArea = {},{}
for _,areaID in ipairs({2437,718,209,719,491,721,796,722,16611,16919,16732,16544,
    1337,1176,2100,1477,1584,1583,2557,2057,2017}) do
    local source=assert(zone.private.dungeons[areaID])
    local entry={name=source[1],quests={},entrances={}}
    for _,position in ipairs(source[4] or {}) do
        local mapID=mapIds[position[1]]
        if mapID and mapID>0 then entry.entrances[#entry.entrances+1]={mapID=mapID,x=position[2]/100,y=position[3]/100} end
    end
    dungeons[areaID]=entry
    insideDungeonByArea[areaID]=areaID
    for _,alias in ipairs(source[2] or {}) do insideDungeonByArea[alias]=areaID end
end
-- Modern Forever instance roots and the source's Dire Maul wing records refer
-- to the same combined classic checklists, not additional instances.
insideDungeonByArea[17803]=1584
insideDungeonByArea[17804]=1583
for _,area in ipairs({10022,10023,10024,10025,10026,10027}) do insideDungeonByArea[area]=2557 end
-- Interior NPCs can be recorded against a named sub-area rather than the
-- dungeon's root area. Resolve that ancestry without treating outdoor parent
-- zones as interiors, and retain explicit aliases such as Gnomeregan's 133.
local parents=assert(loadstring(zone.private.subZoneToParentZone))()
local parentOverrides=assert(loadstring(zone.private.subZoneToParentZoneOverride))()
for area,parent in pairs(parentOverrides) do parents[area]=parent end
for area in pairs(parents) do
    local current,visited=area,{}
    while current and not visited[current] do
        if insideDungeonByArea[current] then insideDungeonByArea[area]=insideDungeonByArea[current] break end
        visited[current]=true current=parents[current]
    end
end
local checklistMapByArea={}
local function checklistMap(area)
    if not area or area<=0 then return end
    if checklistMapByArea[area]~=nil then return checklistMapByArea[area] end
    local original=area
    local visited={}
    while area and area>0 and not visited[area] do
        if insideDungeonByArea[area] then break end
        local mapID=mapIds[area]
        if coveredMaps[mapID] then
            checklistMapByArea[original]=mapID
            return mapID
        end
        visited[area]=true
        area=parents[area]
    end
    checklistMapByArea[original]=false
    return false
end
local dungeonNeeded = {}
local function include(id)
    if included[id] then return end
    included[id] = true
    local values = db.Quest.GetAll(id, fields)
    if not values then return end
    local row = {}
    for i, field in ipairs(fields) do
        local value = values[i]
        if value ~= nil and value ~= 0 and not (type(value)=='table' and next(value)==nil) then row[field] = value end
    end
    for field,value in pairs(corrections[id] and corrections[id].fields or {}) do row[field]=value end
    if libraryBooks[id] then
        local objectives=db.Quest.objectives(id)
        local items=objectives and objectives[3]
        if items and #items==1 then row.libraryBookItem=items[1][1] end
    end
    quests[id] = row
    for _, field in ipairs({'preQuestGroup','preQuestSingle','exclusiveTo'}) do
        for _, dependency in ipairs(row[field] or {}) do include(math.abs(dependency)) end
    end
    for _, field in ipairs({'nextQuestInChain','parentQuest','breadcrumbForQuestId','availableUntilCompleted','availableStartingWith','disabledByQuest'}) do
        if row[field] then include(math.abs(row[field])) end
    end
end
local function includeInChecklist(id,mapID)
    if not coveredMaps[mapID] then return end
    include(id)
    local quest=quests[id]
    if not quest then return end
    quest.checklistMaps=quest.checklistMaps or {}
    quest.checklistMaps[mapID]=true
end
local function includeDungeon(id)
    if dungeonNeeded[id] then return end
    dungeonNeeded[id]=true
    include(id)
    local row=quests[id]
    if not row then return end
    for _, field in ipairs({'preQuestGroup','preQuestSingle'}) do
        for _, dependency in ipairs(row[field] or {}) do includeDungeon(math.abs(dependency)) end
    end
    for _,field in ipairs({'parentQuest','availableStartingWith'}) do
        if row[field] then includeDungeon(math.abs(row[field])) end
    end
end
for _,id in ipairs(db.Quest.GetAllIds()) do
    local category=db.Quest.zoneOrSort(id)
    local areaID=(corrections[id] and corrections[id].dungeonID) or insideDungeonByArea[category]
    local dungeon=areaID and dungeons[areaID]
    if dungeon then dungeon.quests[#dungeon.quests+1]=id includeDungeon(id) end
    includeInChecklist(id,checklistMap(category))
end
local itemSources=dofile(toolRoot..'item-sources.lua')
local pickups={}
for id in pairs(dungeonNeeded) do
    local starts=db.Quest.startedBy(id) or {}
    local locations={}
    for kindIndex,kind in ipairs({'Npc','Object'}) do
        for _,starterId in ipairs(starts[kindIndex] or {}) do
            local entity=db[kind]
            local friendly=kind=='Npc' and entity.friendlyToFaction(starterId) or nil
            if friendly~='A' or (corrections[id] and corrections[id].allowAllianceStarter) then
                for area,spawns in pairs(entity.spawns(starterId) or {}) do
                    for _,pos in ipairs(spawns) do
                        local mapID=mapIds[area]
                        local common={kind=kind,id=starterId,name=entity.name(starterId),areaID=area,insideDungeon=insideDungeonByArea[area]}
                        if pos[1]==-1 and pos[2]==-1 and common.insideDungeon then
                            locations[#locations+1]=common
                        elseif mapID and mapID>0 and not (pos[3] and pos[3]~=0)
                            and pos[1]>=0 and pos[1]<=100 and pos[2]>=0 and pos[2]<=100 then
                            common.mapID=mapID common.x=pos[1]/100 common.y=pos[2]/100
                            locations[#locations+1]=common
                        end
                    end
                end
            end
        end
    end
    for _,itemID in ipairs(starts[3] or {}) do
        for _,location in ipairs(itemSources(db,itemID,mapIds,insideDungeonByArea)) do
            locations[#locations+1]=location
        end
    end
    for _,location in ipairs(corrections[id] and corrections[id].pickups or {}) do locations[#locations+1]=location end
    local unique,seenLocations={},{}
    for _,location in ipairs(locations) do
        local key=table.concat({location.kind,location.id,location.mapID or location.zoneMapID or 0,
            location.insideDungeon or 0,location.x or '',location.y or '',location.sourceKind or '',
            location.sourceID or 0,location.droppedBy or location.foundIn or ''},':')
        if not seenLocations[key] then seenLocations[key]=true unique[#unique+1]=location end
    end
    locations=unique
    table.sort(locations,function(a,b)
        local ak=string.format('%d:%d:%.8f:%.8f:%d:%s:%d',a.mapID or 0,a.id,a.x or 0,a.y or 0,a.insideDungeon or 0,a.sourceKind or a.kind,a.sourceID or 0)
        local bk=string.format('%d:%d:%.8f:%.8f:%d:%s:%d',b.mapID or 0,b.id,b.x or 0,b.y or 0,b.insideDungeon or 0,b.sourceKind or b.kind,b.sourceID or 0)
        return ak<bk
    end)
    pickups[id]=locations
end
local skipped = {itemQuestsWithoutMapSources=0, missingLocations=0, phasedLocations=0}
for _, id in ipairs(db.Quest.GetAllIds()) do
    local starts = db.Quest.startedBy(id)
    if starts then
        if starts[3] and next(starts[3]) then
            local located=false
            for _,itemID in ipairs(starts[3]) do
                for _,location in ipairs(itemSources(db,itemID,mapIds,insideDungeonByArea)) do
                    if not location.insideDungeon then
                        includeInChecklist(id,location.mapID or location.zoneMapID)
                    end
                    if not location.insideDungeon and coveredMaps[location.mapID] and location.x and location.y then
                        local key=table.concat({location.mapID,'Item',itemID,location.sourceKind,location.sourceID},':')
                        local starter=starters[key]
                        if not starter then
                            starter={kind='Item',id=itemID,mapID=location.mapID,name=location.name,x=location.x,y=location.y,
                                sourceKind=location.sourceKind,sourceID=location.sourceID,droppedBy=location.droppedBy,
                                foundIn=location.foundIn,containedIn=location.containedIn,quests={}}
                            starters[key]=starter
                        end
                        local duplicate=false
                        for _,questID in ipairs(starter.quests) do if questID==id then duplicate=true end end
                        if not duplicate then starter.quests[#starter.quests+1]=id end
                        include(id) located=true
                    end
                end
            end
            if not located then skipped.itemQuestsWithoutMapSources=skipped.itemQuestsWithoutMapSources+1 end
        end
        for kindIndex, kind in ipairs({'Npc','Object'}) do
            for _, starterId in ipairs(starts[kindIndex] or {}) do
                local entity = db[kind]
                local friendly = kind == 'Npc' and entity.friendlyToFaction(starterId) or nil
                if friendly ~= 'A' or (corrections[id] and corrections[id].allowAllianceStarter) then
                    for area, locations in pairs(entity.spawns(starterId) or {}) do
                        includeInChecklist(id,checklistMap(area))
                        local mapID = mapIds[area]
                        if coveredMaps[mapID] then
                            local duplicates=kind=='Object' and corrections[id] and corrections[id].duplicateObjectSpawns
                            local duplicatePoints=duplicates and duplicates[starterId] and duplicates[starterId][area]
                            for _, position in ipairs(locations) do
                                local x, y = position[1], position[2]
                                if duplicatePoints and duplicatePoints[x] and duplicatePoints[x][y] then
                                    -- Keep only the documented pin for this object.
                                elseif position[3] and position[3] ~= 0 then
                                    skipped.phasedLocations = skipped.phasedLocations + 1
                                elseif type(x)=='number' and type(y)=='number' and x>=0 and x<=100 and y>=0 and y<=100 then
                                    local key = mapID..':'..kind..':'..starterId..':'..string.format('%.6f:%.6f', x, y)
                                    local starter = starters[key]
                                    if not starter then
                                        starter = {kind=kind, id=starterId, mapID=mapID, name=entity.name(starterId), x=x/100, y=y/100, quests={}}
                                        starters[key] = starter
                                    end
                                    starter.quests[#starter.quests+1] = id
                                    include(id)
                                else skipped.missingLocations = skipped.missingLocations + 1 end
                            end
                        end
                    end
                end
            end
        end
    end
end
local serialize=dofile(toolRoot..'serialize.lua')
-- Reviewed NPC/object coordinates also belong on ordinary pickup maps. Item
-- sources stay in the dungeon planner; they are not general quest-giver pins.
for id,correction in pairs(corrections) do
    for _,location in ipairs(correction.pickups or {}) do
        if (location.kind=='Npc' or location.kind=='Object') and coveredMaps[location.mapID]
            and location.x and location.y and not location.insideDungeon then
            local key=location.mapID..':'..location.kind..':'..location.id..':'..string.format('%.6f:%.6f',location.x*100,location.y*100)
            local starter=starters[key]
            if not starter then
                starter={kind=location.kind,id=location.id,mapID=location.mapID,name=location.name,x=location.x,y=location.y,quests={}}
                starters[key]=starter
            end
            local duplicate=false
            for _,existing in ipairs(starter.quests) do if existing==id then duplicate=true end end
            if not duplicate then starter.quests[#starter.quests+1]=id end
            include(id)
        end
    end
end
local list = {}
for key, starter in pairs(starters) do
    starter.key = key
    table.sort(starter.quests)
    list[#list+1] = starter
end
table.sort(list, function(a,b) return a.key<b.key end)
local maps = {}
for mapID in pairs(coveredMaps) do maps[mapID]={} end
for _, starter in ipairs(list) do maps[starter.mapID][#maps[starter.mapID]+1] = starter end
local data = {revision=revision, faction='Horde', maps=maps, mapNames=coveredMaps, quests=quests, raceMasks=db.Enum.raceMaskById, skipped=skipped,dungeons=dungeons,pickups=pickups}
local file = assert(io.open(output, 'wb'))
file:write('-- Generated from Questie/QuestieDB@'..revision..'. See THIRD_PARTY_NOTICES.md.\nlocal _, ns = ...\nns.Data = '..serialize(data)..'\n')
file:close()
local count=0 for _ in pairs(quests) do count=count+1 end
local mapCount,locationCount=0,0
for mapID in pairs(coveredMaps) do mapCount=mapCount+1 locationCount=locationCount+#maps[mapID] end
print(classFile..': '..mapCount..' maps, '..locationCount..' pickup locations; '..count..' quest records')
