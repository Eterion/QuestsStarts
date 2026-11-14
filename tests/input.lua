return function(ns,check)
    local oldMap,oldTimer,oldCursor,oldModifier,oldOpen=WorldMapFrame,C_Timer,GetCursorPosition,IsModifierKeyDown,ns.OpenDungeons
    local oldWaypoint,oldMenu=ns.SetPickupWaypoint,MenuUtil
    local pending,opened,waypoint,choices={},nil,nil,{}
    local cursorX,cursorY,modified=400,200,false
    C_Timer={After=function(_,fn)pending[#pending+1]=fn end}
    GetCursorPosition=function()return cursorX,cursorY end
    IsModifierKeyDown=function()return modified end
    ns.OpenDungeons=function(id)opened=id end
    ns.SetPickupWaypoint=function(mapID,starter)waypoint={mapID=mapID,x=starter.x}end
    MenuUtil={CreateContextMenu=function(owner,generator)
        check(owner~=nil,'cluster menu retains a real frame owner')
        generator(nil,{CreateTitle=function()end,CreateButton=function()
            return {CreateButton=function(_,text,fn)choices[#choices+1]=fn end}
        end})
    end}
    local function pin(x,y,scale)
        return {
            GetCenter=function()return x,y end,GetEffectiveScale=function()return scale end,
            GetWidth=function()return 22 end,GetHeight=function()return 22 end,IsShown=function()return true end,
            SetMouseClickEnabled=function(self,value)self.clicks=value end,
            SetMouseMotionEnabled=function(self,value)self.motion=value end,
        }
    end
    local entrance=pin(200,100,2) entrance.dungeonID=2437
    local group={starter={name='Giver',x=.25,y=.5},quests={{id=363}}}
    local pickup=pin(300,100,2) pickup.cluster={starter=group.starter,groups={group}}
    local mapID=1454
    WorldMapFrame={
        IsShown=function()return true end,GetMapID=function()return mapID end,
        EnumeratePinsByTemplate=function(_,template)
            local p=template==ns.EntrancePinTemplate and entrance or pickup
            local emitted=false return function()if not emitted then emitted=true return p end end
        end,
        AddCanvasClickHandler=function(self,fn,priority)self.handler=fn self.priority=priority end,
    }
    local map=WorldMapFrame
    local function flush()local tasks=pending pending={}for _,fn in ipairs(tasks)do fn()end end
    ns.InstallMapInput()
    ns.ConfigurePinInput(entrance) ns.ConfigurePinInput(pickup)
    check(not entrance.clicks and entrance.motion and not pickup.clicks and pickup.motion,'both marker types deliver clicks to canvas and retain tooltips')
    check(map.priority==100,'canvas registration precedes native waypoint and navigation handlers')
    check(map.handler(map,'LeftButton')==true,'canvas claims a click inside the scaled entrance hit rectangle')
    check(opened==nil,'dungeon action waits until Spoken canvas hooks finish')
    entrance.dungeonID=nil -- Simulate a provider recycling the pin before the timer.
    flush()
    check(opened==2437,'dungeon opens using captured data after pin recycling without global mouse events')
    entrance.dungeonID=2437
    cursorX=600
    check(map.handler(map,'LeftButton')==true,'pickup click uses the same canvas route')
    pickup.cluster=nil flush()
    check(waypoint and waypoint.mapID==1454 and waypoint.x==.25,'pickup uses captured giver after pin recycling')
    local group2={starter={name='Second',x=.3,y=.5},quests={{id=364}}}
    pickup.cluster={starter=group.starter,groups={group,group2}}
    check(map.handler(map,'LeftButton')==true,'cluster click is consumed by map handler') flush()
    check(#choices==2,'canvas cluster click opens the individual quest choices') choices[2]()
    check(waypoint.x==.3,'canvas menu selects the exact second giver')
    cursorX=400 opened=nil choices={}
    entrance.dungeonID=1584 entrance.dungeonIDs={1584,1583}
    MenuUtil={CreateContextMenu=function(_,generator)
        generator(nil,{CreateTitle=function()end,CreateButton=function(_,text,fn)choices[#choices+1]=fn end})
    end}
    check(map.handler(map,'LeftButton')==true,'canvas consumes a shared entrance click')
    entrance.dungeonID=nil entrance.dungeonIDs=nil
    flush()
    check(opened==nil and #choices==2,'shared entrance survives frame recycling and opens a choice menu')
    choices[2]() check(opened==1583,'canvas shared entrance routes to the selected dungeon')
    entrance.dungeonID=2437
    check(map.handler(map,'RightButton')==false,'right click stays with native map navigation')
    modified=true check(map.handler(map,'LeftButton')==false,'modified click stays with native handlers') modified=false
    cursorX=800 check(map.handler(map,'LeftButton')==false,'empty map click stays with native navigation')
    cursorX=400 opened=nil
    map.handler(map,'LeftButton') mapID=1420 flush()
    check(opened==nil,'map navigation cancels a pending entrance activation')
    WorldMapFrame=oldMap C_Timer=oldTimer GetCursorPosition=oldCursor IsModifierKeyDown=oldModifier ns.OpenDungeons=oldOpen
    ns.SetPickupWaypoint=oldWaypoint MenuUtil=oldMenu
end
