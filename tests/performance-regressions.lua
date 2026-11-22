return function(ns,check)
    -- Independent all-pairs oracle for the optimized coordinate sweep.
    local function reference(groups,width,height,radius)
        local parents={}
        for i=1,#groups do parents[i]=i end
        local function root(i)
            while parents[i]~=i do i=parents[i] end
            return i
        end
        for i=1,#groups do
            for j=i+1,#groups do
                local dx=(groups[i].starter.x-groups[j].starter.x)*width
                local dy=(groups[i].starter.y-groups[j].starter.y)*height
                if dx*dx+dy*dy<=radius*radius then parents[root(j)]=root(i) end
            end
        end
        local result,byRoot={},{}
        for i,group in ipairs(groups) do
            local key=root(i)
            if not byRoot[key] then
                byRoot[key]={starter=group.starter,groups={}}
                result[#result+1]=byRoot[key]
            end
            table.insert(byRoot[key].groups,group)
        end
        return result
    end
    local function compare(groups,width,height,radius,label)
        local actual,expected=ns.ClusterGroups(groups,width,height,radius),reference(groups,width,height,radius)
        local equal=#actual==#expected
        for i,cluster in ipairs(actual) do
            local other=expected[i]
            if not other or cluster.starter~=other.starter or #cluster.groups~=#other.groups then equal=false
            else
                for j,group in ipairs(cluster.groups) do if group~=other.groups[j] then equal=false end end
            end
        end
        check(equal,'clustering retains exact components, first marker and order: '..label)
    end
    local points={{starter={x=0,y=0}},{starter={x=.1,y=0}},
        {starter={x=.2,y=0}},{starter={x=.2,y=0}},{starter={x=.3,y=.1}}}
    for _,size in ipairs({{100,100,10},{0,100,10},{100,0,0},{0,0,0},{-100,100,10}}) do
        compare(points,size[1],size[2],size[3],'boundary/duplicate/degenerate')
    end
    compare({},100,100,10,'empty')
    local seed=1729
    local function random()seed=(seed*16807)%2147483647 return seed/2147483647 end
    for fixture=1,30 do
        local groups={}
        for i=1,100 do groups[i]={starter={x=random(),y=random()}} end
        compare(groups,1000,668,fixture%3==0 and 0 or fixture%2==0 and 28 or 200,'random '..fixture)
    end
    for mapID,starters in pairs(ns.Data.maps) do
        local groups={}
        for _,starter in ipairs(starters) do groups[#groups+1]={starter=starter} end
        compare(groups,1000,668,28,'actual map '..mapID)
        compare(groups,1700,900,14,'actual resized map '..mapID)
    end
    local fixture={maps={[1]={{kind='Item',id=11,quests={1,2,1}},
        {kind='Npc',id=12,quests={1,2}},{kind='Object',id=13,quests={1,2}}}},
        quests={[1]={},[2]={requiredSpell=123}}}
    local state={level=60,completed=function()return false end,active=function()return false end,
        hasItem=function()return false end}
    local original,calls=ns.IsAvailable,0
    ns.IsAvailable=function(...)calls=calls+1 return original(...)end
    local groups=ns.BuildGroups(fixture,1,state,true)
    check(calls==2 and #groups==3 and #groups[1].quests==2 and groups[1].quests[2].uncertain,
        'each distinct quest is evaluated once per map build, including unknown results and duplicate sources')
    calls=0
    state.active=function(id)return id==1 end
    groups=ns.BuildGroups(fixture,1,state,true)
    check(calls==2 and #groups==3 and #groups[1].quests==1 and groups[1].quests[1].id==2,
        'eligibility memoization cannot survive a changed player snapshot or suppress unknown results')
    state.active=function()return false end
    state.showItemStarts=false
    groups=ns.BuildGroups(fixture,1,state,true)
    check(#groups==2 and groups[1].starter.kind=='Npc' and #groups[1].quests==2,
        'source-specific filters do not pollute the shared base eligibility result')
    ns.IsAvailable=original
    local checklist=ns.BuildZoneChecklist({[1]={name='Shared',requiredClasses=0,requiredRaces=0}},
        {[1]=true},{},{classMask=128,raceMask=16,active=function()return false end,completed=function()return false end},true)
    check(checklist.total==1,'explicit unrestricted class/race masks remain visible in zone checklists')
end
