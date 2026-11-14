return function(ns,check)
    local player={level=60,raceMask=16,classMask=16,showLowLevel=true,holidays={},
        completed=function()return false end,active=function()return false end}
    local maps,populated,locations=0,0,0
    for mapID,starters in pairs(ns.Data.maps)do
        maps=maps+1 locations=locations+#starters
        if #starters>0 then populated=populated+1 end
        local valid=true
        for _,starter in ipairs(starters)do
            valid=valid and starter.mapID==mapID and starter.x>=0 and starter.x<=1 and starter.y>=0 and starter.y<=1
            for _,id in ipairs(starter.quests)do if not ns.Data.quests[id] then valid=false end end
        end
        check(valid,'world map coordinates and quest references are valid: '..mapID)
        local groups=ns.BuildGroups(ns.Data,mapID,player,false)
        local eligible=true
        for _,group in ipairs(groups)do
            for _,entry in ipairs(group.quests)do
                local q=ns.Data.quests[entry.id]
                if ns.GetQuestEvent(entry.id,q) then eligible=false end
                if q.requiredRaces and q.requiredRaces~=0 and not ns.HasBit(q.requiredRaces,player.raceMask) then eligible=false end
                if q.requiredClasses and q.requiredClasses~=0 and not ns.HasBit(q.requiredClasses,player.classMask) then eligible=false end
            end
        end
        check(eligible,'all-world pickup filtering excludes inactive holidays and incompatible races/classes: '..mapID)
    end
    check(maps==50 and populated==47 and locations==2225,'world coverage includes NPC, object, and item sources on 47 populated maps')
    check(ns.Data.maps[2524]==nil,'Darkspear battleground is excluded from overworld quest-start coverage')
    for _,mapID in ipairs({2548,2482,1430})do
        check(ns.Data.maps[mapID] and #ns.Data.maps[mapID]==0,'map without recorded coordinates stays empty: '..mapID)
    end
    local known={
        [1416]=27,[1417]=26,[1418]=23,[1419]=10,[1422]=27,[1423]=41,[1425]=19,
        [1427]=14,[1428]=16,[1434]=62,[1435]=16,[1437]=25,[1443]=36,[1444]=23,
        [1445]=28,[1446]=43,[1447]=17,[1448]=55,[1449]=21,[1450]=10,[1451]=35,[1452]=23,
        [2521]=55,[2652]=3,
    }
    for mapID,count in pairs(known)do
        local ordinary=0
        for _,starter in ipairs(ns.Data.maps[mapID]) do if starter.kind~='Item' then ordinary=ordinary+1 end end
        check(ordinary==count,'remaining leveling map retains its NPC/object pickup locations: '..mapID)
    end
    player.level=15
    local groups=ns.BuildGroups(ns.Data,1455,player,false)
    local thom=false
    for _,group in ipairs(groups)do
        for _,entry in ipairs(group.quests)do
            if entry.id==96403 then thom=group.starter.id==265003 and group.starter.mapID==1455 end
        end
    end
    check(thom,'reviewed neutral Thom Filch pickup is available on Ironforge map for Horde')
end
