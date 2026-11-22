return function(ns,check,loadAddon,root)
    local savedData,savedClass=ns.Data,UnitClass
    local classes={1,2,3,4,5,7,8,9,11}
    local reviews=dofile(root..'/tools/class-gate-reviews.lua')
    local exclusions=0
    for _,classID in ipairs(classes) do
        UnitClass=function()return '', '', classID end
        loadAddon('Data/Tirisfal.lua')
        local data=ns.Data
        local state={level=60,classMask=2^(classID-1),raceMask=16,showLowLevel=true,
            holidays={},completed=function()return false end,active=function()return false end}
        local reviewed=0
        for _,review in pairs(reviews) do
            for _,id in ipairs(review.ids) do
                reviewed=reviewed+1
                local q=data.quests[id]
                local valid=q~=nil
                for field,value in pairs(review.fields) do if not q or q[field]~=value then valid=false end end
                check(valid,'reviewed class disposition is preserved for quest/profile '..id..'/'..classID)
            end
        end
        check(reviewed==49,'every reviewed inherited class difference is checked for profile '..classID)
        for _,raceMask in ipairs({2,16,32,128,8589934592}) do
            state.raceMask=raceMask
            for stage,id in ipairs(reviews.earthmother.ids) do
                state.completed=function(other)return stage>1 and other==76156 or stage>2 and other==76160 end
                check((ns.IsAvailable(id,data.quests,state)==true)==(raceMask==32),
                    'Earthmother keeps its chain and allows only Tauren for quest/profile/race '..id..'/'..classID..'/'..raceMask)
            end
        end
        state.raceMask=16
        state.completed=function()return false end
        for _,includeUnknown in ipairs({false,true}) do
            local seen={}
            for _,group in ipairs(ns.BuildGroups(data,1440,state,includeUnknown)) do
                for _,entry in ipairs(group.quests) do
                    for _,id in ipairs(reviews.dragonslayer.ids) do
                        if entry.id==id then seen[id]=entry.uncertain and entry.reason=='pickup source unverified' end
                    end
                end
            end
            for _,id in ipairs(reviews.dragonslayer.ids) do
                check((seen[id]==true)==includeUnknown,
                    'quarantined Dragonslayer quest has only opt-in uncertain markers for quest/profile '..id..'/'..classID)
            end
        end
        for id,q in pairs(data.quests) do
            if q.requiredClasses and q.requiredClasses~=0 and not ns.HasBit(q.requiredClasses,state.classMask) then
                -- An unresolved race must not mask a definite class exclusion.
                state.raceMask=nil
                local allowed,reason=ns.IsAvailable(id,data.quests,state)
                check(allowed==false and reason=='class','wrong-class quest stays unavailable with unknown race: '..id..'/'..classID)
                exclusions=exclusions+1
            end
        end
        state.raceMask=16
        for mapID in pairs(data.maps) do
            for _,includeUnknown in ipairs({false,true}) do
                local groups=ns.BuildGroups(data,mapID,state,includeUnknown)
                local valid=true
                for _,group in ipairs(groups) do
                    for _,entry in ipairs(group.quests) do
                        local mask=data.quests[entry.id].requiredClasses
                        if mask and mask~=0 and not ns.HasBit(mask,state.classMask) then valid=false end
                    end
                end
                check(valid,'all map source kinds respect class masks: '..mapID..'/'..classID..'/'..tostring(includeUnknown))
            end
        end
    end
    check(exclusions>5000,'audit exercises thousands of actual quest/class exclusions across all nine class datasets')
    local lockpicks=ns.Data.quests[78270]
    check(lockpicks.requiredClasses==8 and lockpicks.parentQuest==78261,
        'the sparse inherited Goblin Lockpicks record retains its original rogue and active-parent gates')
    for _,classID in ipairs(classes) do
        local state={level=26,classMask=2^(classID-1),raceMask=16,showLowLevel=true,
            completed=function()return false end,active=function(id)return id==78261 end}
        local allowed,reason=ns.IsAvailable(78270,ns.Data.quests,state)
        check(classID==4 and allowed==true or classID~=4 and allowed==false and reason=='class',
            'captured level-26 Stonetalon case respects the original quest class for profile '..classID)
        local shown=false
        for _,group in ipairs(ns.BuildGroups(ns.Data,1442,state,true)) do
            for _,entry in ipairs(group.quests) do if entry.id==78270 then shown=true end end
        end
        check(shown==(classID==4),
            'the actual Stonetalon map draws Goblin Lockpicks only for the eligible rogue, even with unverified markers enabled')
        state.active=function()return false end
        check(ns.IsAvailable(78270,ns.Data.quests,state)==false,
            'Goblin Lockpicks is unavailable without its active parent, including to rogues')
    end
    local state={level=60,classMask=1,raceMask=16,showLowLevel=true,
        completed=function()return false end,active=function()return false end,hasItem=function()return true end}
    local fixture={quests={[97286]={preQuestSingle={1}},[1]={requiredClasses=8,libraryBookItem=123}},
        maps={[1]={{kind='Object',id=1,quests={1}}}}}
    check(#ns.BuildGroups(fixture,1,state,true)==0,'carrying a collection item cannot override a known class exclusion')
    state.classMask=8
    check(#ns.BuildGroups(fixture,1,state,true)==1,'an eligible class retains the carried collection item shortcut')
    fixture.quests[1].requiredClasses=nil
    fixture.quests[1].requiredRaces=1
    check(#ns.BuildGroups(fixture,1,state,true)==0,'carrying a collection item cannot override a known race exclusion')
    local chain={quests={[1]={requiredClasses=8},[2]={preQuestSingle={1}},[3]={preQuestGroup={1}}},
        maps={[1]={{kind='Npc',id=1,quests={1,2,3}},{kind='Item',id=2,quests={1}}}}}
    state.classMask=1
    state.hasItem=function()return false end
    check(#ns.BuildGroups(chain,1,state,true)==0,
        'another class chain cannot leak through its unrestricted follow-ups or item starter with unverified pickups enabled')
    ns.Data,UnitClass=savedData,savedClass
end
