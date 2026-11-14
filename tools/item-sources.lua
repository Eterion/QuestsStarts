-- Offline source resolver. Keep a recorded point, never a fabricated centroid,
-- for each item/source/map. Bound runtime pin counts even for roaming mobs.
return function(db,itemID,mapIds,insideAreas)
    local visited,bySource={},{}
    local function visit(containerID)
        if visited[containerID] then return end
        visited[containerID]=true
        for _,kind in ipairs({'Npc','Object'}) do
            local ids
            if kind=='Npc' then ids=db.Item.npcDrops(containerID)
            else ids=db.Item.objectDrops(containerID) end
            local entity=db[kind]
            for _,sourceID in ipairs(ids or {}) do
                for area,positions in pairs(entity.spawns(sourceID) or {}) do
                    local inside,mapID=insideAreas[area],mapIds[area]
                    local location={kind='Item',id=itemID,name=db.Item.name(itemID),sourceKind=kind,
                        sourceID=sourceID,areaID=area,insideDungeon=inside}
                    if kind=='Npc' then location.droppedBy=entity.name(sourceID)
                    else location.foundIn=entity.name(sourceID) end
                    if containerID~=itemID then location.containedIn=db.Item.name(containerID) end
                    if not inside and mapID and mapID>0 then
                        for _,pos in ipairs(positions) do
                            local x,y=pos[1],pos[2]
                            if not (pos[3] and pos[3]~=0) and type(x)=='number' and type(y)=='number'
                                and x>=0 and x<=100 and y>=0 and y<=100
                                and (not location.x or x/100<location.x or (x/100==location.x and y/100<location.y)) then
                                location.mapID=mapID location.x=x/100 location.y=y/100
                            end
                        end
                    end
                    if inside or location.mapID then
                        local key=kind..':'..sourceID..(inside and ':inside:'..inside or ':map:'..mapID)
                        local old=bySource[key]
                        if not old or (location.x and (not old.x or location.x<old.x or (location.x==old.x and location.y<old.y)))
                            or (location.x==old.x and location.y==old.y and area<old.areaID) then
                            bySource[key]=location
                        end
                    end
                end
            end
        end
        for _,parent in ipairs(db.Item.itemDrops(containerID) or {}) do visit(parent) end
    end
    visit(itemID)
    local keys,result={},{}
    for key in pairs(bySource) do keys[#keys+1]=key end
    table.sort(keys)
    for _,key in ipairs(keys) do result[#result+1]=bySource[key] end
    return result
end
