return function(ns,check,loadAddon)
    local completed,accepted={},{}
    local player={level=12,raceMask=16,classMask=16,showLowLevel=false,
        completed=function(id)return completed[id] or false end,
        active=function(id)return accepted[id] or false end}
    local plan=ns.BuildDungeonPlan(ns.Data,2437,player)
    check(plan.total==6 and plan.completed==0 and plan.accepted==0,'six known RFC quest records')
    local hidden
    for _,row in ipairs(plan.rows) do if row.id==5728 then hidden=row end end
    check(hidden and hidden.steps[1].id==5726 and hidden.steps[1].status=='available','Hidden Enemies starts at first missing pickup')
    check(hidden.steps[2].id==5727 and hidden.steps[3].id==5728,'multi-stage prerequisites preserve order')
    completed[5726]=true accepted[5727]=true
    plan=ns.BuildDungeonPlan(ns.Data,2437,player)
    for _,row in ipairs(plan.rows) do if row.id==5728 then hidden=row end end
    check(hidden.steps[1].status=='completed' and hidden.steps[2].id==5727 and hidden.steps[2].status=='in log','accepted prerequisite remains a finish-first step')
    accepted[5727]=nil completed[5727]=true
    plan=ns.BuildDungeonPlan(ns.Data,2437,player)
    for _,row in ipairs(plan.rows) do if row.id==5728 then hidden=row end end
    check(hidden.status=='available' and #hidden.steps==3 and hidden.steps[2].status=='completed','completed chain unlocks dungeon pickup')
    completed[5728]=true
    plan=ns.BuildDungeonPlan(ns.Data,2437,player)
    for _,row in ipairs(plan.rows) do if row.id==5728 then hidden=row end end
    check(#hidden.steps==3 and hidden.steps[1].status=='completed' and hidden.steps[3].status=='completed',
        'a fully completed chain retains its first and final quests')
    completed[5728]=nil
    accepted[5728]=true completed[5722]=true
    plan=ns.BuildDungeonPlan(ns.Data,2437,player)
    check(plan.accepted==1 and plan.completed==1,'accepted and completed counts are separate')
    local inside=ns.Data.pickups[5724][1]
    check(inside.insideDungeon==2437 and not inside.mapID and not inside.x,'inside-dungeon pickup has no invented coordinates')
    check(ns.Data.pickups[5726][1].mapID==1454,'prerequisite pickup resolves to Orgrimmar')
    local fixture={dungeons={[1]={quests={1}}},quests={[1]={preQuestGroup={2,3}},[2]={},[3]={}},pickups={}}
    completed={} accepted={}
    plan=ns.BuildDungeonPlan(fixture,1,player)
    check(#plan.rows[1].steps==3 and plan.rows[1].steps[1].branch=='all','AND prerequisite list retains all requirements')
    fixture.quests[1]={preQuestSingle={2,3}}
    plan=ns.BuildDungeonPlan(fixture,1,player)
    check(plan.rows[1].steps[1].branch=='one of' and plan.rows[1].steps[2].branch=='one of','OR prerequisites stay alternatives')
    completed[3]=true
    check(ns.BuildDungeonPlan(fixture,1,player).rows[1].status=='available','one completed alternative unlocks root')
    completed={}
    fixture.quests[1]={preQuestSingle={2},requiredLevel=20}
    plan=ns.BuildDungeonPlan(fixture,1,player)
    check(plan.rows[1].reason=='minimum level' and plan.rows[1].steps[1].id==2,'underlevel dungeon still exposes earlier preparation')
    fixture.quests[1]={preQuestSingle={2}} fixture.quests[2]={preQuestSingle={1}}
    plan=ns.BuildDungeonPlan(fixture,1,player)
    check(plan.rows[1].steps[1].reason=='cyclic prerequisite','cyclic chain terminates with uncertainty')
    fixture.quests[2]=nil
    check(ns.BuildDungeonPlan(fixture,1,player).rows[1].steps[1].status=='unverified','missing prerequisite is not invented')
    fixture.quests[1]={questLevel=1}
    player.level=40
    check(ns.BuildDungeonPlan(fixture,1,player).rows[1].status=='available' and not player.showLowLevel,'planner ignores map low-level display without mutating player state')
    player.level=12
    check(#ns.BuildDungeonPlan(ns.Data,999,player).rows==0,'unknown dungeon is empty')
    local sections=ns.OrganizeDungeonPlan(ns.Data,ns.BuildDungeonPlan(ns.Data,2437,player))
    check(#sections.available==3 and #sections.chains==2,'RFC groups dungeon quests under their full chains')
    check(sections.chains[1].steps[2].insidePickup,'inside pickup is labelled inside the chain')
    accepted[5728]=true completed[5722]=true
    sections=ns.OrganizeDungeonPlan(ns.Data,ns.BuildDungeonPlan(ns.Data,2437,player))
    check(sections.chains[1].steps[1].status=='completed' and sections.chains[2].steps[3].status=='in log','completed and accepted steps stay visible in their chains')
    accepted={} completed={}
    local list=ns.ListDungeons(ns.Data,player)
    check(#list==21 and list[1].id==2437 and list[1].eligible,'instance browser includes twenty-one dungeons with RFC ordered for character level')
    check(ns.Data.dungeons[718].name=='Wailing Caverns' and ns.Data.dungeons[209].name=='Shadowfang Keep','additional early Horde dungeons are included')
    local shard=ns.Data.pickups[6981][1]
    check(shard.kind=='Item' and shard.insideDungeon==718 and shard.droppedBy=='Mutanus the Devourer','item-started dungeon quest identifies actual inside source')
    local x,y=ns.ProjectEntrance({mapID=1454,x=.5,y=.25},1454)
    check(x==.5 and y==.25,'entrance exact-map coordinates are preserved')
    x,y=ns.ProjectEntrance({mapID=1454,x=.5,y=.25},1411,function()return .2,.4,.4,.8 end)
    check(math.abs(x-.3)<.00001 and math.abs(y-.5)<.00001,'native map rectangle projects city entrance to parent map')
    check(ns.ProjectEntrance({mapID=1454,x=.5,y=.25},1420,function()end)==nil,'unrelated map does not get invented entrance')
    local low,high=ns.DungeonLevelRange(2437,ns.Data)
    check(low==13 and high==18,'recommended dungeon range is distinct from quest minimum')
    GetLFGDungeonInfo=function()return 'Ragefire Chasm',1,1,10,60,15,14,19 end
    low,high=ns.DungeonLevelRange(2437,ns.Data)
    check(low==14 and high==19,'matching client recommendation overrides fallback')
    GetLFGDungeonInfo=nil

    -- Exercise the native-template UI wiring with stateful frame doubles.
    loadAddon('DungeonUI.lua')
    local function object()
        local value={scripts={},hooks={},shown=false,height=1}
    for _,method in ipairs({'SetNormalFontObject','SetJustifyH','SetJustifyV','SetWordWrap','SetMaxLines','SetTexture','SetAtlas','SetTexCoord','SetAlpha','SetTextColor','SetClampedToScreen','SetFrameStrata','SetTitle','SetPortraitToAsset','SetScrollChild','SetEnabled','SetVerticalScroll'}) do value[method]=function()end end
        value.GetStringHeight=function()return 14 end
        value.GetEffectiveScale=function()return 1 end
        value.GetRight=function()return nil end
        value.GetAlpha=function(self)return self.alpha or 1 end
        value.SetAlpha=function(self,alpha)self.alpha=alpha end
        value.SetFrameStrata=function(self,strata)self.strata=strata end
        value.GetFrameStrata=function(self)return self.strata or 'MEDIUM' end value.GetFrameLevel=function()return 10 end
        value.SetFrameLevel=function()end value.SetScale=function()end value.EnableMouse=function()end
        value.SetChecked=function(self,state)self.checked=state end
        value.SetCustomOnMouseUpHandler=function(self,callback)self.customClick=callback end
        value.RegisterForClicks=function(self,click)self.registeredClick=click end
        value.SetMouseClickEnabled=function(self,enabled)self.mouseClicks=enabled end
        value.SetMouseMotionEnabled=function(self,enabled)self.mouseMotion=enabled end
        value.SetPosition=function()end
        value.SetWidth=function(self,width)self.width=width end
        value.GetWidth=function(self)return self.width or 294 end
        value.SetPoint=function(self,...)self.point={...}end
        value.ClearAllPoints=function(self)self.point=nil end
        value.SetHeight=function(self,height)self.height=height end
        value.GetHeight=function(self)return self.height end
        value.SetSize=function(self,width,height)self.width=width self.height=height end
        value.SetText=function(self,text)self.text=text end
        value.GetText=function(self)return self.text end
        value.SetScript=function(self,name,fn)self.scripts[name]=fn end
        value.GetScript=function(self,name)return self.scripts[name]end
        value.GetPoint=function(self)return unpack(self.point or {})end
        value.HookScript=function(self,name,fn)self.hooks[name]=self.hooks[name]or{} table.insert(self.hooks[name],fn)end
        value.Show=function(self)local was=self.shown self.shown=true if not was then if self.scripts.OnShow then self.scripts.OnShow(self)end for _,fn in ipairs(self.hooks.OnShow or {})do fn(self)end end end
        value.Hide=function(self)local was=self.shown self.shown=false if was then if self.scripts.OnHide then self.scripts.OnHide(self)end for _,fn in ipairs(self.hooks.OnHide or {})do fn(self)end end end
        value.IsShown=function(self)return self.shown end
        value.IsVisible=value.IsShown
        value.SetShown=function(self,state)if state then self:Show()else self:Hide()end end
        value.CreateFontString=function()return object()end
        value.CreateTexture=function()
            local texture=object()
            texture.SetAllPoints=function(self,parent)self.fill=parent end
            texture.SetTexture=function(self,id)self.file=id return true end
            texture.SetColorTexture=function()end
            return texture
        end
        value.GetFontString=function(self)self.font=self.font or object() return self.font end
        return value
    end
    local oldCreateFrame=CreateFrame
    CreateFrame=function(kind,name,parent,template)
        local frame=object()
        frame.template=template frame.parent=parent
        if template=='QuestTitleButtonTemplate' or template=='LargeSideTabButtonTemplate' then frame.Icon=object()end
        if template=='ButtonFrameTemplate' then frame.Inset=object()end
        return frame
    end
    local oldState=ns.GetPlayerState
    ns.GetPlayerState=function()return player end
    local oldUIParent,oldSpoken,oldSpokenAPI,oldStoryTab=UIParent,SpokenPlacesPanel,SpokenPlaces,SpokenPlacesPanelToggle
    local oldHook=hooksecurefunc
    hooksecurefunc=function(target,name,callback)
        if type(target)=='string' then target,name,callback=_G,target,name end
        local original=target[name]
        target[name]=function(...)local result=original(...) callback(...) return result end
    end
    NavBar_Initialize=function(nav,template,home)nav.trail={home}end
    NavBar_Reset=function(nav)nav.trail={nav.trail[1]}end
    NavBar_AddButton=function(nav,entry)nav.trail[#nav.trail+1]=entry end
    UIParent={GetLeft=function()return 0 end,GetBottom=function()return 0 end,GetRight=function()return nil end,GetEffectiveScale=function()return 1 end,GetWidth=function()return 1920 end}
    WorldMapFrame.IsVisible=function()return true end
    WorldMapFrame.GetEffectiveScale=function()return 1 end
    WorldMapFrame.GetLeft=function()return 100 end WorldMapFrame.GetRight=function()return 800 end
    WorldMapFrame.GetTop=function()return 900 end WorldMapFrame.GetBottom=function()return 366 end
    WorldMapFrame.GetHeight=function()return 534 end WorldMapFrame.GetFrameStrata=function()return 'MEDIUM'end WorldMapFrame.GetFrameLevel=function()return 10 end
    local mapHooks={}
    WorldMapFrame.HookScript=function(_,event,fn)mapHooks[event]=fn end
    local oldMapAlpha=WorldMapFrame.GetAlpha
    local mapAlpha=1
    WorldMapFrame.GetAlpha=function()return mapAlpha end
    SpokenPlacesPanel=object() SpokenPlacesPanel:SetSize(320,500) SpokenPlacesPanel:Show()
    SpokenPlacesPanelToggle=object() SpokenPlacesPanelToggle:SetPoint('TOPLEFT',WorldMapFrame,'TOPRIGHT',0,-30)
    SpokenPlaces={SetMapPanelCollapsed=function(_,collapsed)
        if collapsed then SpokenPlacesPanel:Hide() SpokenPlacesPanelToggle:Show()
        else SpokenPlacesPanel:Show() SpokenPlacesPanelToggle:Hide() end
    end,RefreshPanel=function()end}
    loadAddon('Dock.lua')
    local oldGetAttribute,oldSetPanel,oldUpdatePanels=WorldMapFrame.GetAttribute,SetUIPanelAttribute,UpdateUIPanelPositions
    local extraWidth=12
    WorldMapFrame.GetAttribute=function(_,key)if key=='UIPanelLayout-extraWidth' then return extraWidth end end
    SetUIPanelAttribute=function(_,_,value)extraWidth=value end
    UpdateUIPanelPositions=function()end
    SpokenPlacesPanel.GetRight=function()return 1120 end
    local places,story,storyTab=SpokenPlaces,SpokenPlacesPanel,SpokenPlacesPanelToggle
    SpokenPlaces,SpokenPlacesPanel,SpokenPlacesPanelToggle=nil,nil,nil
    ns.InstallDungeonButton()
    check(ns.DungeonButton:IsShown() and ns.DungeonButton.point[2]==WorldMapFrame,
        'dock installs and anchors its own tab with Spoken absent at startup')
    SpokenPlaces,SpokenPlacesPanel,SpokenPlacesPanelToggle=places,story,storyTab
    places.IsPartOn=function()return false end
    ns.SyncDock()
    check(not ns.GetStorySurfaces() and ns.DungeonButton.point[2]==WorldMapFrame,
        'disabled Places module uses the standalone layout even with its frames loaded')
    places.IsPartOn=function()return true end
    places.Get=function(_,key)if key=='showMapPanel' then return false end end
    ns.SyncDock()
    check(not ns.GetStorySurfaces() and ns.DungeonButton.point[2]==WorldMapFrame,
        'disabled Spoken map panel uses the standalone layout')
    places.Get=nil
    ns.SyncDock()
    check(extraWidth==332,'visible Spoken panel adds its measured overhang to the native allowance')
    ns.SyncDock()
    check(extraWidth==332,'repeated layout refreshes do not count the overhang twice')
    local oldGetUIPanel,oldHidePanel=GetUIPanel,HideUIPanel
    local spellbook=object()
    GetUIPanel=function(slot)if slot=='center' then return spellbook end end
    spellbook:SetWidth(300)
    spellbook.GetLeft=function()return 840 end
    spellbook.GetTop=function()return 850 end
    spellbook.GetBottom=function()return 450 end
    SpokenPlacesPanel.GetTop=function()return 900 end
    SpokenPlacesPanel.GetBottom=function()return 400 end
    SpokenPlacesPanel.GetLeft=function()return 800 end
    spellbook:Show()
    ns.SyncDock()
    check(spellbook.point and spellbook.point[4]==1128,'an already-open Spellbook moves past the visible companion')
    local screenWidth=UIParent.GetWidth
    UIParent.GetWidth=function()return 1300 end
    HideUIPanel=function(sheet)sheet:Hide()end
    ns.SyncDock()
    check(not spellbook:IsShown(),'an overlapping Spellbook closes if the remaining width is too small')
    UIParent.GetWidth=screenWidth
    GetUIPanel,HideUIPanel=oldGetUIPanel,oldHidePanel
    check(ns.DungeonButton.point[2]==SpokenPlacesPanelToggle and SpokenPlacesPanelToggle.point[2]==SpokenPlacesPanel,'both tabs sit beyond open story with dungeon tab below story tab')
    ns.OpenDungeons()
    check(ns.DungeonFrame and ns.DungeonFrame:IsShown(),'native dungeon companion opens')
    check(ns.DungeonFrame.dungeonID==nil and #ns.DungeonFrame.Rows==21,'browser lists known instances before selection')
    check(ns.DungeonFrame.point[2]==SpokenPlacesPanel and ns.DungeonFrame.point[3]=='TOPLEFT','dungeon panel replaces story in the same slot')
    check(ns.DungeonFrame:GetWidth()==320 and ns.DungeonFrame:GetHeight()==500 and not SpokenPlacesPanel:IsShown(),'replacement matches story dimensions and collapses story')
    check(ns.DungeonFrame.template=='DefaultPanelFlatTemplate','flat native frame has no portrait')
    mapAlpha=.35 mapHooks.OnUpdate()
    check(ns.DungeonFrame:GetAlpha()==.35 and ns.DungeonButton:GetAlpha()==.35,'open dungeon panel and tab follow movement fading while Spoken is installed')
    local oldFader,oldMouseOver,oldGetCVarBool=PlayerMovementFrameFader,WorldMapFrame.IsMouseOver,GetCVarBool
    local fadePredicate
    PlayerMovementFrameFader={AddDeferredFrame=function(_,_,_,_,predicate)fadePredicate=predicate end}
    WorldMapFrame.IsMouseOver=function()return false end
    GetCVarBool=function()return true end
    ns.DungeonFrame.IsMouseOver=function()return true end
    mapHooks.OnShow()
    check(not fadePredicate(),'hovering the visible dungeon panel inhibits the native movement fade')
    ns.DungeonFrame.IsMouseOver=function()return false end
    check(fadePredicate(),'leaving the map and side panel allows native fading')
    ns.DungeonButton.customClick()
    check(ns.DungeonsOpen,'clicking the active windowed tab leaves the dungeon panel open')
    PlayerMovementFrameFader,WorldMapFrame.IsMouseOver,GetCVarBool=oldFader,oldMouseOver,oldGetCVarBool
    mapAlpha=1 mapHooks.OnUpdate()
    check(ns.DungeonFrame:GetAlpha()==1 and ns.DungeonButton:GetAlpha()==1,'dungeon panel and tab become opaque when map fading ends')
    check(ns.DungeonFrame.Browse==nil and ns.DungeonFrame.Navigation.trail[1].name=='World','native World breadcrumb replaces back button')
    check(ns.DungeonFrame.Hint==nil,'bottom hints are removed')
    local instanceRow
    for _,row in ipairs(ns.DungeonFrame.Rows)do if row.step.id==2437 then instanceRow=row end end
    check(instanceRow.Art.fill==instanceRow and instanceRow.Art.file==131862 and instanceRow.Progress.text=='0/6','dungeon banner fills its card and shows completion over the artwork')
    instanceRow:GetScript('OnClick')(instanceRow)
    check(ns.DungeonFrame.dungeonID==2437,'instance browser can select RFC')
    check(#ns.DungeonFrame.Navigation.trail==2 and ns.DungeonFrame.Navigation.trail[2].id==2437,'native breadcrumb follows World to dungeon')
    local headings={}
    for _,label in ipairs(ns.DungeonFrame.Headings)do if label:IsShown()then headings[#headings+1]=label.Label.text end end
    check(table.concat(headings,'\n'):find('Prerequisite Chains',1,true),'chain section is actually rendered')
    local header
    for _,row in ipairs(ns.DungeonFrame.Rows)do if row.step.id==5728 and row.isHeader then header=row end end
    check(header and header.kind=='chain','only prerequisite chain has expansion control')
    local detail
    for _,row in ipairs(ns.DungeonFrame.Rows)do if row.step.id==5726 and not row.isHeader then detail=row end end
    check(detail and detail:IsShown(),'expansion reveals missing prerequisite pickup')
    local waypoint,map
    local oldSetMap=WorldMapFrame.SetMapID
    WorldMapFrame.SetMapID=function(_,id)map=id end
    local oldWaypoint=C_Map.SetUserWaypoint
    C_Map.SetUserWaypoint=function(point)waypoint=point end
    detail:GetScript('OnClick')(detail)
    check(map==1454 and waypoint and waypoint.map==1454,'prerequisite click navigates map and sets native waypoint')
    check(not ns.DungeonFrame:IsShown(),'pickup navigation uncovers map and leaves Spoken untouched')
    check(ns.NavigateDungeonPickup(5724,inside)==false,'inside pickup does not produce fake waypoint')
    ns.OpenDungeons(2437)
    waypoint,map=nil,nil
    local entranceButton=ns.DungeonFrame.EntranceButton
    check(entranceButton:IsShown(),'dungeon detail exposes the entrance action')
    entranceButton:GetScript('OnClick')(entranceButton)
    check(map==1454 and waypoint==nil and ns.DungeonFrame:IsShown() and ns.DungeonFrame.dungeonID==2437,
        'entrance action shows Orgrimmar and keeps the selected dungeon panel open')
    accepted[5728]=true
    ns.OpenDungeons(2437)
    ns.Refresh()
    check(ns.DungeonFrame.Summary.text:find('1 in log',1,true),'visible preparation view refreshes after quest-state changes')
    ns.OpenDungeons(722)
    local scrollRow
    for _,row in ipairs(ns.DungeonFrame.Rows)do if row:IsShown() and row.step.id==6522 and row.step.insidePickup then scrollRow=row end end
    check(scrollRow and scrollRow:GetHeight()==23,'inside chain pickups fit a compact quest row')
    scrollRow:GetScript('OnEnter')(scrollRow)
    ns.OpenDungeons(1584)
    local longChain
    for _,row in ipairs(ns.DungeonFrame.Rows)do if row:IsShown() and row.step.id==9015 and row.kind=='chain' then longChain=row end end
    check(longChain and not longChain:GetScript('OnClick'),'long endgame prerequisite chains need no expansion')
    local firstStep=longChain.step.steps[1].id

    local expandedStep=false
    for _,row in ipairs(ns.DungeonFrame.Rows)do if row:IsShown() and row.kind=='step' and row.step.id==firstStep then expandedStep=true end end
    check(expandedStep,'expanding a long endgame chain reveals its real prerequisite steps')
    ns.DungeonFrame:Hide()
    local calls=0
    local oldOpen=ns.OpenDungeons
    ns.OpenDungeons=function(id)calls=id end
    local entrance=CreateFromMixins(object(),QuestsStartsEntrancePinMixin)
    entrance.Texture=object()
    entrance.Glow=object()
    entrance.Glow:Show()
    entrance:SetScript('OnClick',nil)
    entrance:OnAcquired(2437,.5,.5)
    check(not entrance.Glow:IsShown(),'recycled entrance starts without hover glow')
    entrance:OnMouseEnter()
    check(entrance.Glow:IsShown(),'entrance glow appears on hover')
    entrance:OnMouseLeave()
    check(not entrance.Glow:IsShown(),'entrance glow clears on mouse leave')
    entrance:OnMouseEnter() entrance:OnReleased()
    check(not entrance.Glow:IsShown(),'released entrance does not retain hover glow')
    entrance:OnAcquired(2437,.5,.5)
    check(entrance.mouseClicks==false and entrance.mouseMotion==true,'portal keeps hover input while clicks reach the map canvas')
    entrance:OnClick('LeftButton')
    check(calls==2437,'controller activation opens selected dungeon')
    calls=0 entrance:OnClick('RightButton')
    check(calls==0,'right click does not open preparation')
    -- A covering map pin can receive input while our visible entrance stays under
    -- the pointer. Global mouse events bridge that case, without a broad map hook.
    local oldTimer,oldEnumerate=C_Timer,WorldMapFrame.EnumeratePinsByTemplate
    local oldFoci,oldMouse,oldCursor,oldModifier=GetMouseFoci,MouseIsOver,GetCursorPosition,IsModifierKeyDown
    local pending={} C_Timer={After=function(_,fn)pending[#pending+1]=fn end}
    local cursorX,cursorY=100,100
    local focus={GetName=function()return 'CoveringNativeMapPin' end,GetParent=function()return WorldMapFrame end}
    GetMouseFoci=function()return {focus}end
    GetCursorPosition=function()return cursorX,cursorY end
    IsModifierKeyDown=function()return false end
    MouseIsOver=function(pin)return pin==entrance end
    entrance:Show()
    WorldMapFrame.EnumeratePinsByTemplate=function(_,template)
        if template~=ns.EntrancePinTemplate then return function()end end
        local emitted=false return function()if not emitted then emitted=true return entrance end end
    end
    local function flush()local tasks=pending pending={}for _,fn in ipairs(tasks)do fn()end end
    calls=0
    ns.HandleEntranceMouse('GLOBAL_MOUSE_DOWN','LeftButton') ns.HandleEntranceMouse('GLOBAL_MOUSE_UP','LeftButton') flush()
    check(calls==2437,'visible entrance activates when a covering native map pin owns input')
    calls=0
    focus={pinTemplate='DungeonEntrancePinTemplate',name='Ragefire Chasm',GetParent=function()return WorldMapFrame end}
    MouseIsOver=function()return false end
    ns.HandleEntranceMouse('GLOBAL_MOUSE_DOWN','LeftButton') ns.HandleEntranceMouse('GLOBAL_MOUSE_UP','LeftButton') flush()
    check(calls==2437,'native entrance marker resolves by dungeon identity even at a different coordinate')
    check(ns.DungeonFromNativePin({pinTemplate='AreaPOIPinTemplate',poiInfo={name='Ragefire Chasm'}})==2437,'native area-POI entrance resolves from client POI data')
    check(ns.DungeonFromNativePin({pinTemplate='AreaPOIPinTemplate',poiInfo={name='Auction House'}})==nil,'unrelated native map POI keeps its normal action')
    MouseIsOver=function(pin)return pin==entrance end
    focus={GetParent=function()return WorldMapFrame end}
    calls=0
    ns.HandleEntranceMouse('GLOBAL_MOUSE_DOWN','LeftButton') cursorX=130 ns.HandleEntranceMouse('GLOBAL_MOUSE_UP','LeftButton') flush()
    check(calls==0,'drag across portal never opens preparation') cursorX=100
    ns.HandleEntranceMouse('GLOBAL_MOUSE_DOWN','LeftButton') entrance:OnClick('LeftButton') calls=0
    ns.HandleEntranceMouse('GLOBAL_MOUSE_UP','LeftButton') flush()
    check(calls==0,'fallback never duplicates a handled button click')
    focus={GetName=function()return 'OtherWindow'end,GetParent=function()return UIParent end}
    ns.HandleEntranceMouse('GLOBAL_MOUSE_DOWN','LeftButton') ns.HandleEntranceMouse('GLOBAL_MOUSE_UP','LeftButton') flush()
    check(calls==0,'another window over the map is not intercepted')
    focus={GetParent=function()return WorldMapFrame end}
    IsModifierKeyDown=function()return true end
    ns.HandleEntranceMouse('GLOBAL_MOUSE_DOWN','LeftButton') ns.HandleEntranceMouse('GLOBAL_MOUSE_UP','LeftButton') flush()
    check(calls==0,'modified clicks retain native behavior')
    C_Timer=oldTimer WorldMapFrame.EnumeratePinsByTemplate=oldEnumerate
    GetMouseFoci=oldFoci MouseIsOver=oldMouse GetCursorPosition=oldCursor IsModifierKeyDown=oldModifier
    local oldDraw=WorldMapFrame.AcquirePin
    local portalCount=0
    WorldMapFrame.AcquirePin=function(_,template,id,x,y)check(template==ns.EntrancePinTemplate and id==2437,'RFC portal payload')portalCount=portalCount+1 end
    ns.Settings.showEntrances=true ns.DrawDungeonEntrances(WorldMapFrame,1454)
    check(portalCount==1,'entrance renders on Orgrimmar map outside general pickup coverage')
    ns.Settings.showEntrances=false ns.DrawDungeonEntrances(WorldMapFrame,1454)
    check(portalCount==1 and ns.lastEntranceCount==0,'entrance filter suppresses portals')
    ns.Settings.showEntrances=true WorldMapFrame.AcquirePin=oldDraw
    ns.OpenDungeons=oldOpen
    ns.OpenDungeons(2437)
    SpokenPlaces:SetMapPanelCollapsed(false)
    ns.SyncDock()
    check(not ns.DungeonsOpen and not ns.DungeonFrame:IsShown() and SpokenPlacesPanel:IsShown(),'story selection replaces dungeon view')
    local oldMapShown=WorldMapFrame.IsShown
    WorldMapFrame.IsShown=function()return false end
    mapHooks.OnHide()
    check(extraWidth==12,'closing the map restores the original native allowance')
    WorldMapFrame.IsShown=function()return true end
    mapHooks.OnShow()
    check(not SpokenPlacesPanel:IsShown() and SpokenPlacesPanelToggle:IsShown(),'map close collapses Spoken while keeping its tab available on reopen')
    SpokenPlaces=nil SpokenPlacesPanel=nil SpokenPlacesPanelToggle=nil
    ns.OpenDungeons()
    ns.SyncDock()
    mapAlpha=.5 mapHooks.OnUpdate()
    check(ns.DungeonFrame:GetAlpha()==.5 and ns.DungeonButton:GetAlpha()==.5,'movement fading also follows the map without Spoken')
    check(not ns.DungeonButton:IsShown(),'without Spoken the windowed dungeon tab hides while its panel is open')
    WorldMapFrame.IsShown=function()return false end
    mapHooks.OnHide()
    WorldMapFrame.IsShown=function()return true end
    mapHooks.OnShow()
    check(not ns.DungeonsOpen and not ns.DungeonFrame:IsShown(),'map close clears the selected dungeon view before reopen')
    WorldMapFrame.IsShown=oldMapShown
    mapAlpha=1 mapHooks.OnUpdate()
    check(ns.DungeonButton:GetAlpha()==1,'closed-panel tab follows the map back to full opacity')
    check(ns.DungeonButton:IsShown() and ns.DungeonButton.point[2]==WorldMapFrame,'without Spoken closed panel has first right-side tab')
    local oldCanvas,oldResize=WorldMapFrame.ScrollContainer,WorldMapFrame.OnFrameSizeChanged
    local canvas=object()
    canvas:SetPoint('RIGHT',WorldMapFrame,'RIGHT',-3,0)
    canvas.GetNumPoints=function(self)return self.point and 1 or 0 end
    WorldMapFrame.ScrollContainer=canvas
    local resizeCount=0
    WorldMapFrame.OnFrameSizeChanged=function()resizeCount=resizeCount+1 end
    local oldMaximized=WorldMapFrame.IsMaximized
    WorldMapFrame.IsMaximized=function()return true end
    UIParent.GetHeight=function()return 1080 end
    ns.SyncDock()
    check(ns.DungeonButton:IsShown() and ns.DungeonButton.point[3]=='TOPRIGHT','fullscreen dungeon tab is anchored inside the screen')
    ns.DungeonButton.customClick()
    check(ns.DungeonsOpen and ns.DungeonFrame:IsShown() and ns.DungeonFrame.point[2]==UIParent,
        'opening the fullscreen dungeon tab keeps the maximized map open')
    ns.DungeonButton.customClick()
    check(ns.DungeonsOpen and ns.DungeonFrame:IsShown() and not ns.DungeonFrame.CloseButton:IsShown(),'fullscreen dungeon panel stays open')
    ns.CloseDungeons()
    SpokenPlacesPanel=object()
    SpokenPlacesPanelToggle=object()
    SpokenPlaces={Get=function(_,key)return key=='showMapPanel' end,RefreshPanel=function()
        if not WorldMapFrame:IsMaximized() then SpokenPlacesPanel:Show() end
    end}
    ns.SyncDock()
    check(SpokenPlacesPanel:IsShown() and SpokenPlacesPanel.point[2]==UIParent and WorldMapFrame:IsMaximized(),
        'Spoken refresh loads fullscreen lore and restores the native maximized flag')
    ns.DungeonButton.customClick()
    check(ns.DungeonFrame:IsShown() and ns.DungeonFrame:GetFrameStrata()=='FULLSCREEN_DIALOG'
        and not SpokenPlacesPanel:IsShown() and ns.DungeonButton.point[2]==SpokenPlacesPanelToggle,
        'switching from Spoken shows the dungeon panel on the fullscreen layer with its own tab space')
    check(canvas.point[4]==-404 and resizeCount==1,'fullscreen inset gives the viewport its own native zoom levels')
    WorldMapFrame.IsMaximized=function()return false end
    ns.SyncDock()
    check(canvas.point[4]==-3 and resizeCount==2,'windowed viewport and native zoom bounds are rebuilt together')
    WorldMapFrame.ScrollContainer,WorldMapFrame.OnFrameSizeChanged=oldCanvas,oldResize
    WorldMapFrame.IsMaximized=oldMaximized
    UIParent=oldUIParent SpokenPlacesPanel=oldSpoken SpokenPlaces=oldSpokenAPI SpokenPlacesPanelToggle=oldStoryTab hooksecurefunc=oldHook
    CreateFrame=oldCreateFrame ns.GetPlayerState=oldState WorldMapFrame.SetMapID=oldSetMap C_Map.SetUserWaypoint=oldWaypoint
    WorldMapFrame.GetAlpha=oldMapAlpha
    WorldMapFrame.GetAttribute,SetUIPanelAttribute,UpdateUIPanelPositions=oldGetAttribute,oldSetPanel,oldUpdatePanels
end
