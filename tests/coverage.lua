return function(ns,check,loadAddon)
    local data=ns.Data
    local state={level=15,raceMask=16,classMask=16,showLowLevel=true,holidays={},
        completed=function()return false end,active=function()return false end}
    local expected={
        [1413]={name='The Barrens',count=95,quest=6548},
        [1421]={name='Silverpine Forest',count=31,quest=447},
        [1454]={name='Orgrimmar',count=109,quest=5726},
        [1458]={name='Undercity',count=67,quest=5725},
        [1456]={name='Thunder Bluff',count=49,quest=5722},
        [1412]={name='Mulgore',count=44,quest=96259,level=25},
        [1442]={name='Stonetalon Mountains',count=19,quest=6542,level=25},
        [1440]={name='Ashenvale',count=30,quest=6383,level=25},
        [1441]={name='Thousand Needles',count=29,quest=4542,level=25},
        [1424]={name='Hillsbrad Foothills',count=37,quest=496,level=25},
    }
    for mapID,entry in pairs(expected) do
        local starters=data.maps[mapID]
        local ordinary=0
        for _,starter in ipairs(starters or {}) do if starter.kind~='Item' then ordinary=ordinary+1 end end
        check(starters and ordinary==entry.count and data.mapNames[mapID]==entry.name,'generated NPC/object pickup coverage for '..entry.name)
        local valid,known=true,false
        for _,starter in ipairs(starters) do
            valid=valid and starter.mapID==mapID and starter.x>=0 and starter.x<=1 and starter.y>=0 and starter.y<=1
            for _,id in ipairs(starter.quests)do valid=valid and data.quests[id]~=nil if id==entry.quest then known=true end end
        end
        check(valid,'all '..entry.name..' coordinates and quest references are valid')
        check(known,'known zone/dungeon pickup is retained in '..entry.name)
        state.level=entry.level or 15
        local groups,stats=ns.BuildGroups(data,mapID,state,false)
        check(#groups>0 and stats.eligible>0,'Undead priest has eligible pickups at the tested level in '..entry.name)
        local hiddenEvents=true
        for _,group in ipairs(groups)do
            for _,quest in ipairs(group.quests)do if ns.GetQuestEvent(quest.id,data.quests[quest.id]) then hiddenEvents=false end end
        end
        check(hiddenEvents,'inactive holiday pickups remain hidden in '..entry.name)
    end
    local unitClass=UnitClass
    UnitClass=function()return 'Warrior','WARRIOR',1 end
    loadAddon('Data/Tirisfal.lua')
    check(ns.Data.quests[9015].nextQuestInChain==9022,'warrior receives its own Challenge follow-up')
    UnitClass=function()return 'Priest','PRIEST',5 end
    loadAddon('Data/Tirisfal.lua')
    check(ns.Data.quests[9015].nextQuestInChain==9019,'priest receives its own Challenge follow-up')
    UnitClass=unitClass
    ns.Data=data
end
