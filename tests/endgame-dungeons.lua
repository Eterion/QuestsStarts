return function(ns,check)
    check(not ns.Data.quests[2955] and #ns.Data.pickups[2955]==0,'missing upstream Gnomeregan dependency remains unknown without an invented pickup')
    local expected={
        [1337]={29,709,41,51},[1176]={10,2768,44,54},[2100]={11,7046,46,55},
        [1477]={9,3373,50,60},[1584]={41,3982,52,60},[1583]={37,4903,55,60},
        [2557]={37,5525,54,60},[2057]={12,5382,58,60},[2017]={16,5122,58,60},
    }
    local player={level=60,raceMask=16,classMask=16,holidays={},completed=function()return false end,active=function()return false end}
    for id,entry in pairs(expected)do
        local dungeon=ns.Data.dungeons[id]
        check(dungeon and #dungeon.quests==entry[1],'remaining classic dungeon retains source quest rows: '..id)
        local plan=ns.BuildDungeonPlan(ns.Data,id,player)
        local known=false
        for _,row in ipairs(plan.rows)do if row.id==entry[2] then known=true end end
        check(known and plan.total>0,'known Horde quest is accessible in endgame checklist: '..id)
        local low,high=ns.DungeonLevelRange(id,ns.Data)
        check(low==entry[3] and high==entry[4],'remaining classic dungeon has its published fallback band: '..id)
    end
    check(ns.Data.pickups[7046][1].insideDungeon==2100,'Celebras is an inside Maraudon pickup')
    check(ns.Data.pickups[3373][1].kind=='Item' and ns.Data.pickups[3373][1].insideDungeon==1477,'Essence of Eranikus is an inside Sunken Temple item starter')
    check(ns.Data.pickups[5122][1].insideDungeon==2017,'Aurius is an inside Stratholme pickup')
    check(ns.Data.pickups[7508][1].fromQuest==7507 and not ns.Data.pickups[7508][1].mapID,'Quel Serrar item step identifies its prerequisite item without a fake waypoint')
    check(ns.PickupLabel(ns.Data.pickups[7508][1],ns.Data):find('item from',1,true),'carried-item pickup is explicitly labeled')
    local status,reason=ns.IsAvailable(1318,ns.Data.quests,player)
    check(status==nil and reason=='pickup source unverified','unconfirmed legacy Gordok variant is not presented as known available')
    check(ns.Data.pickups[1318][1].insideDungeon==2557 and not ns.Data.pickups[1318][1].mapID,'reported legacy Gordok provider has an inside label without guessed coordinates')
    local captured={}
    local oldRect=C_Map.GetMapRectOnMap
    C_Map.GetMapRectOnMap=nil
    local map={AcquirePin=function(_,template,id,x,y,ids)captured[#captured+1]={id=id,x=x,y=y,ids=ids}end}
    ns.DrawDungeonEntrances(map,1427)
    check(#captured==1 and #captured[1].ids==2,'Depths and Spire share one entrance pin in Searing Gorge')
    local group=captured[1].ids
    check(group[1]==1584 and group[2]==1583,'shared entrance names are deterministically sorted')
    ns.DrawDungeonEntrances(map,1427)
    check(#captured==1 and ns.lastEntranceCount==1,'same-map refresh retains entrance frames instead of reshuffling pooled overlaps')
    ns.Settings.showEntrances=false ns.DrawDungeonEntrances(map,1427)
    check(ns.lastEntranceCount==0,'entrance cache respects the map filter')
    ns.Settings.showEntrances=true ns.DrawDungeonEntrances(map,1427)
    check(#captured==2 and ns.lastEntranceCount==1,'re-enabling entrance pins rebuilds their cache')
    captured={} ns.DrawDungeonEntrances(map,1418)
    check(#captured==2 and #captured[1].ids==1 and #captured[2].ids==1,'different Uldaman entrances remain separate pins')
    C_Map.GetMapRectOnMap=oldRect
    local oldMenu,oldShowMap,oldWaypoint=MenuUtil,ns.ShowDungeonMap,ns.SetPickupWaypoint
    local choices,opened={},nil
    MenuUtil={CreateContextMenu=function(owner,generator)
        check(owner==WorldMapFrame,'shared entrance menu has a stable owner across pin refreshes')
        generator(nil,{CreateTitle=function()end,CreateButton=function(_,text,fn)choices[#choices+1]={text=text,fn=fn}end})
    end}
    ns.ShowDungeonMap=function(id)opened=id end
    ns.SetPickupWaypoint=function()error('entrance choices must not create waypoints')end
    ns.OpenEntranceDungeons(group)
    check(#choices==2 and not opened,'shared entrance waits for an explicit dungeon choice')
    choices[1].fn() check(opened==1584,'shared entrance choice opens Depths')
    choices[2].fn() check(opened==1583,'shared entrance choice opens Spire')
    local oldTimer,oldFoci,oldOver,oldCursor,oldModifier=C_Timer,GetMouseFoci,MouseIsOver,GetCursorPosition,IsModifierKeyDown
    local oldEnumerate=WorldMapFrame.EnumeratePinsByTemplate
    local sharedPin={dungeonID=1584,dungeonIDs=group,IsShown=function()return true end}
    local native={pinTemplate='DungeonEntrancePinTemplate',name='Blackrock Spire',GetParent=function()return WorldMapFrame end}
    GetMouseFoci=function()return {native}end
    MouseIsOver=function(pin)return pin==sharedPin end
    GetCursorPosition=function()return 100,100 end
    IsModifierKeyDown=function()return false end
    C_Timer={After=function(_,fn)fn()end}
    WorldMapFrame.EnumeratePinsByTemplate=function(_,template)
        local emitted=false
        return function()if template==ns.EntrancePinTemplate and not emitted then emitted=true return sharedPin end end
    end
    choices={} opened=nil
    ns.HandleEntranceMouse('GLOBAL_MOUSE_DOWN','LeftButton') ns.HandleEntranceMouse('GLOBAL_MOUSE_UP','LeftButton')
    check(#choices==2 and not opened,'covering native Spire marker preserves the visible shared entrance choice')
    choices[1].fn() check(opened==1584,'covering native marker does not make Depths inaccessible')
    C_Timer=oldTimer GetMouseFoci=oldFoci MouseIsOver=oldOver GetCursorPosition=oldCursor IsModifierKeyDown=oldModifier
    WorldMapFrame.EnumeratePinsByTemplate=oldEnumerate
    MenuUtil=oldMenu ns.ShowDungeonMap=oldShowMap ns.SetPickupWaypoint=oldWaypoint
end
