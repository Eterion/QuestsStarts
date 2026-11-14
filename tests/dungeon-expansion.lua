return function(ns,check)
    local expected={
        [719]={count=12,quest=6561,low=24,high=32},
        [491]={count=6,quest=1102,low=29,high=38},
        [721]={count=27,quest=2841,low=29,high=38},
        [796]={count=8,quest=1048,low=30,high=46},
        [722]={count=7,quest=3341,low=37,high=46},
    }
    local player={level=12,raceMask=16,classMask=16,holidays={},
        completed=function()return false end,active=function()return false end}
    for id,entry in pairs(expected)do
        local dungeon=ns.Data.dungeons[id]
        check(dungeon and #dungeon.quests==entry.count,'new dungeon retains all source quest records: '..id)
        local found=false
        for _,questID in ipairs(dungeon.quests)do if questID==entry.quest then found=true end end
        check(found,'known quest is associated with its canonical dungeon: '..entry.quest)
        local valid=true
        for _,location in ipairs(dungeon.entrances)do
            valid=valid and location.mapID>0 and location.x>=0 and location.x<=1 and location.y>=0 and location.y<=1
        end
        check(valid and #dungeon.entrances>0,'new dungeon has valid source entrance coordinates: '..id)
        local low,high=ns.DungeonLevelRange(id,ns.Data)
        check(low==entry.low and high==entry.high,'new dungeon has an explicit recommended band: '..id)
        local plan=ns.BuildDungeonPlan(ns.Data,id,player)
        check(plan.total>0,'new dungeon is browseable before the character reaches its quest level: '..id)
        local correct=true
        for _,row in ipairs(plan.rows)do
            local q=ns.Data.quests[row.id]
            if q.requiredRaces and not ns.HasBit(q.requiredRaces,player.raceMask) then correct=false end
            if q.requiredClasses and not ns.HasBit(q.requiredClasses,player.classMask) then correct=false end
        end
        check(correct,'race/class exclusions are honored even for underlevel quests: '..id)
    end
    check(ns.Data.quests[1102].zoneOrSort==1717 and ns.Data.quests[2841].zoneOrSort==133,'RFK and Gnomeregan quest-area aliases are preserved in source rows')
    local willix=ns.Data.pickups[1144][1]
    check(willix.insideDungeon==491 and not willix.mapID,'Willix is picked up inside RFK without invented outdoor coordinates')
    local vorrel=ns.Data.pickups[1051][1]
    check(vorrel.insideDungeon==796,'Vorrel is identified as an inside Scarlet Monastery pickup')
    local scroll=ns.Data.pickups[6522][1]
    check(scroll.kind=='Item' and scroll.insideDungeon==491,'RFD preparation retains its item pickup inside RFK')
    check(ns.PickupLabel(scroll,ns.Data):find('inside Razorfen Kraul',1,true),'cross-instance pickup label uses the source dungeon')
    local fixture={dungeons={[1]={quests={1,2}}},quests={
        [1]={requiredRaces=1,requiredLevel=60},[2]={requiredClasses=1,requiredLevel=60}},pickups={}}
    check(ns.BuildDungeonPlan(fixture,1,player).total==0,'underlevel incompatible race/class quests are omitted rather than shown as level-blocked')
end
