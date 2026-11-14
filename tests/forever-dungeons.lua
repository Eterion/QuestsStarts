return function(ns,check)
    local player={level=30,raceMask=16,classMask=16,holidays={},
        completed=function()return false end,active=function()return false end}
    local expected={
        [16611]={source=13,horde=9,low=15,high=20,mapID=1458},
        [16919]={source=4,horde=2,low=13,high=18,mapID=1455},
        [16732]={source=14,horde=5,low=24,high=29,mapID=1437},
        [16544]={source=10,horde=5,low=28,high=33,mapID=1416},
    }
    for id,entry in pairs(expected)do
        local dungeon=ns.Data.dungeons[id]
        check(dungeon and #dungeon.quests==entry.source,'Forever dungeon retains source and reviewed membership: '..id)
        local plan=ns.BuildDungeonPlan(ns.Data,id,player)
        check(plan.total==entry.horde,'Forever dungeon filters faction variants for Horde priest: '..id)
        local low,high=ns.DungeonLevelRange(id,ns.Data)
        check(low==entry.low and high==entry.high,'Forever dungeon has a published level band: '..id)
        local entrance=dungeon.entrances[1]
        check(entrance.mapID==entry.mapID and entrance.x>0 and entrance.x<1 and entrance.y>0 and entrance.y<1,'Forever entrance uses valid source coordinates in its actual outdoor map: '..id)
        local complete=true
        for _,row in ipairs(plan.rows)do
            for _,step in ipairs(row.steps)do if not ns.Data.quests[step.id] then complete=false end end
        end
        check(complete,'Forever prerequisite chains retain their quest records: '..id)
    end
    local hall=ns.BuildDungeonPlan(ns.Data,16919,player)
    local sections=ns.OrganizeDungeonPlan(ns.Data,hall)
    check(#sections.inside==1 and sections.inside[1].id==96395,'An Ancient Grudge is an inside Hall pickup for Horde')
    local attendant=ns.Data.pickups[96395][1]
    check(attendant.id==265002 and attendant.name=='Ghostly Attendant' and attendant.insideDungeon==16919 and not attendant.mapID and not attendant.x,'reported Hall inside giver has identity but no invented waypoint')
    local heirlooms=ns.Data.pickups[96403][1]
    check(heirlooms.id==265003 and heirlooms.mapID==1455 and heirlooms.x and heirlooms.y,'neutral Thom Filch retains the recorded Ironforge location')
    player.level=9
    local _,reason=ns.IsAvailable(96395,ns.Data.quests,player)
    check(reason=='minimum level','reviewed Hall quest minimum level is enforced')
    player.level=15
    check(ns.IsAvailable(96395,ns.Data.quests,player)==true and ns.IsAvailable(96403,ns.Data.quests,player)==true,'both reported neutral Hall quests pass Horde eligibility at their level')
    local head=ns.Data.pickups[97288][1]
    check(head.kind=='Item' and head.id==280438 and head.insideDungeon==16611 and not head.mapID,'Unending Torment retains its recorded inside Lordaeron item source')
    local crest=ns.Data.pickups[95204][1]
    check(crest.kind=='Item' and crest.insideDungeon==16611 and crest.sourceKind=='Object' and crest.sourceID==614679 and not crest.mapID,'Crest of Lordaeron resolves its recorded inside container without a fake waypoint')
    local rexxie=ns.Data.pickups[96987][1]
    check(rexxie.name=='Rexxie Copperclutch' and rexxie.zoneMapID==1416 and not rexxie.mapID and not rexxie.x,'Rexxie is identified by source but retains unknown exact coordinates')
    check(ns.PickupLabel(rexxie,ns.Data):find('coordinates unknown',1,true),'zone-only pickup label explicitly retains its coordinate gap')
    local relic=ns.Data.pickups[95664][1]
    check(relic.kind=='Item' and relic.sourceID==260326 and relic.insideDungeon==16732 and relic.droppedBy=='Relic Guardian' and not relic.mapID,'Titan Relic has its source-backed boss and inside dungeon location')
    local maw=ns.Data.pickups[95682][1]
    check(maw.mapID==1437 and maw.x==.514 and maw.y==.592 and not maw.insideDungeon,'Open the Maw has the recorded outdoor Deathstalker Agent location')
    player.level=30
    local mawPlan=ns.BuildDungeonPlan(ns.Data,16732,player)
    local mawRow
    for _,row in ipairs(mawPlan.rows)do if row.id==95682 then mawRow=row end end
    check(mawRow and #mawRow.steps==2 and mawRow.steps[1].id==95663,'Open the Maw retains its reported Dragonmaw Rumors prerequisite')
    local dala=ns.BuildDungeonPlan(ns.Data,16544,player)
    local negotiation
    for _,row in ipairs(dala.rows)do if row.id==97287 then negotiation=row end end
    check(negotiation and ns.Data.quests[97287].zoneOrSort==36,'Dalaran includes its inside objective quest despite an outdoor sort')
    check(ns.Data.pickups[97287][1].mapID==1424 and not ns.Data.pickups[97287][1].insideDungeon,'Shrewd Negotiations is picked up outside, not at its inside objective')
    local ruins=ns.BuildDungeonPlan(ns.Data,16611,player)
    local wrath
    for _,row in ipairs(ruins.rows)do if row.id==92422 then wrath=row end end
    check(wrath and #wrath.steps==3 and wrath.steps[2].id==99156,'Lordaeron retains the Deathguard Kristof prerequisite chain')
end
