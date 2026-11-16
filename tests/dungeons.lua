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
        for _,method in ipairs({'SetAllPoints','SetBackdropColor','SetBackdropBorderColor','SetShadowColor','SetShadowOffset','SetHitRectInsets'}) do value[method]=function()end end
        value.SetBackdrop=function(self,style)self.backdrop=style end
        value.GetStringHeight=function()return 14 end
        value.GetStringWidth=function(self)return #(self.text or '')*6 end
        value.GetEffectiveScale=function()return 1 end
        value.GetRight=function()return nil end
        value.GetAlpha=function(self)return self.alpha or 1 end
        value.SetAlpha=function(self,alpha)self.alpha=alpha end
        value.SetFrameStrata=function(self,strata)self.strata=strata end
        value.GetFrameStrata=function(self)return self.strata or 'MEDIUM' end value.GetFrameLevel=function()return 10 end
        value.SetFrameLevel=function()end value.SetScale=function()end value.EnableMouse=function()end
        value.SetChecked=function(self,state)self.checked=state end
        value.GetChecked=function(self)return self.checked end
        value.SetCustomOnMouseUpHandler=function(self,callback)self.customClick=callback end
        value.SetFillToInterior=function(self,fill)self.fillToInterior=fill end
        value.SetHighlightTexture=function(self,texture)self.highlight=object() self.highlight.file=texture end
        value.GetHighlightTexture=function(self)return self.highlight end
        value.RegisterForClicks=function(self,click)self.registeredClick=click end
        value.SetMouseClickEnabled=function(self,enabled)self.mouseClicks=enabled end
        value.SetMouseMotionEnabled=function(self,enabled)self.mouseMotion=enabled end
        value.SetPosition=function()end
        value.SetWidth=function(self,width)self.width=width end
        value.GetWidth=function(self)return self.width or 294 end
        value.SetPoint=function(self,point,...)
            self.point={point,...}
            self.points=self.points or {}
            self.points[point]=self.point
        end
        value.ClearAllPoints=function(self)self.point=nil self.points=nil end
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
            texture.SetGradient=function(self,direction,bottom,top)self.gradient={direction,bottom,top}end
            return texture
        end
        value.GetFontString=function(self)self.font=self.font or object() return self.font end
        return value
    end
    local oldCreateFrame=CreateFrame
    local oldProgressMixin=ColoredProgressBarMixin
    ColoredProgressBarMixin={ColorType={Blue=3,Green=2}}
    CreateFrame=function(kind,name,parent,template)
        local frame=object()
        frame.template=template frame.parent=parent
        if template=='QuestTitleButtonTemplate' or template=='LargeSideTabButtonTemplate' then frame.Icon=object()end
        if template=='ButtonFrameTemplate' then frame.Inset=object()end
        if template=='ListHeaderVisualTemplate' then frame.CollapseButton=object() frame.ButtonText=object() end
        if template=='ColoredProgressBarTemplate' then
            frame.SetFillPercent=function(self,fraction)self.fraction=fraction end
            frame.SetFillTextureByColorType=function(self,color)self.color=color end
        end
        if template=='WowStyle1ArrowDropdownTemplate' then
            frame.SetupMenu=function(self,menu)self.menu=menu end
            frame:SetSize(25,25)
        end
        if template=='SearchBoxTemplate' then
            frame.SetAutoFocus=function()end
            frame.ClearFocus=function()end
            frame.SetText=function(self,text)
                self.text=text
                for _,hook in ipairs(self.hooks.OnTextChanged or {}) do hook(self) end
            end
        end
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
    check(ns.ZoneButton:IsShown() and ns.ZoneButton.point[2]==WorldMapFrame and ns.DungeonButton.point[2]==ns.ZoneButton,
        'dock installs zone then dungeon tabs with Spoken absent at startup')
    check(ns.ZoneButton.fillToInterior and ns.DungeonButton.fillToInterior,'both side tabs fill their masks like CharacterFrame tabs')
    SpokenPlaces,SpokenPlacesPanel,SpokenPlacesPanelToggle=places,story,storyTab
    places.IsPartOn=function()return false end
    ns.SyncDock()
    check(not ns.GetStorySurfaces() and ns.ZoneButton.point[2]==WorldMapFrame,
        'disabled Places module uses the standalone layout even with its frames loaded')
    places.IsPartOn=function()return true end
    places.Get=function(_,key)if key=='showMapPanel' then return false end end
    ns.SyncDock()
    check(not ns.GetStorySurfaces() and ns.ZoneButton.point[2]==WorldMapFrame,
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
    check(ns.DungeonButton.point[2]==ns.ZoneButton and ns.ZoneButton.point[2]==SpokenPlacesPanel
        and SpokenPlacesPanelToggle.point[2]==SpokenPlacesPanel,'windowed tabs stack in story, zone, dungeon order')
    local queueDock=ns.QueueDock
    local dockQueued=false
    ns.QueueDock=function()dockQueued=true end
    SpokenPlacesPanelToggle:SetPoint('TOPLEFT',WorldMapFrame,'TOPRIGHT',0,-30)
    check(dockQueued and ns.ZoneButton.point[2]==SpokenPlacesPanel and ns.DungeonButton.point[2]==ns.ZoneButton,
        'a delayed Spoken reanchor queues a correction without pulling the quest tabs back to the map')
    ns.QueueDock=queueDock
    ns.SyncDock()
    check(SpokenPlacesPanelToggle.point[2]==SpokenPlacesPanel,'the next dock layout restores the Spoken tab beside the panel')
    local oldGetMap=WorldMapFrame.GetMapID
    local browserMapID=947
    WorldMapFrame.GetMapID=function()return browserMapID end
    ns.OpenDungeons()
    check(ns.DungeonFrame and ns.DungeonFrame:IsShown(),'native dungeon companion opens')
    check(ns.DungeonFrame.dungeonID==nil and #ns.DungeonFrame.Rows==21,'world map lists all known instances before selection')
    local function dungeonCards()
        local ids,count={},0
        for _,row in ipairs(ns.DungeonFrame.Rows) do
            if row:IsShown() then ids[row.step.id]=true count=count+1 end
        end
        return ids,count
    end
    ns.DungeonFrame.Search:SetText('  rAGEfire  ')
    local dungeonMatches,dungeonMatchCount=dungeonCards()
    check(dungeonMatchCount==1 and dungeonMatches[2437],'dungeon browser matches names without case or surrounding spaces')
    ns.DungeonFrame.Search:SetText('')
    browserMapID=1414
    ns.UpdateDungeonFrame()
    local kalimdor=dungeonCards()
    check(kalimdor[718] and kalimdor[2437] and not kalimdor[209],'continent filters dungeon entrances')
    browserMapID=1413
    ns.UpdateDungeonFrame()
    local barrens,count=dungeonCards()
    check(count==3 and barrens[718] and barrens[491] and barrens[722],'zone shows only its dungeon entrances')
    browserMapID=1411
    ns.UpdateDungeonFrame()
    check(ns.DungeonFrame.Empty:IsShown(),'zone without a dungeon has an empty state')
    browserMapID=947
    ns.UpdateDungeonFrame()
    check(ns.DungeonFrame.point[2]==SpokenPlacesPanel and ns.DungeonFrame.point[3]=='TOPLEFT','dungeon panel replaces story in the same slot')
    check(ns.DungeonFrame:GetWidth()==320 and ns.DungeonFrame:GetHeight()==500 and not SpokenPlacesPanel:IsShown(),'replacement matches story dimensions and collapses story')
    check(ns.ZoneButton.point[2]==ns.DungeonFrame,'quest tabs anchor to the active replacement panel')
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
    check(ns.DungeonFrame.Navigation==nil,'dungeon list uses no breadcrumbs')
    check(ns.DungeonFrame.Hint==nil,'bottom hints are removed')
    local instanceRow
    for _,row in ipairs(ns.DungeonFrame.Rows)do if row.step.id==2437 then instanceRow=row end end
    check(instanceRow.Art.fill==instanceRow and instanceRow.Art.file==131862 and instanceRow.Progress.Label.text=='0/6','dungeon banner fills its card and shows completion over the artwork')
    check(instanceRow:GetFontString().point[1]=='TOPLEFT' and instanceRow.text:find('13-18',1,true)
        and instanceRow.Progress.point[1]=='BOTTOMRIGHT','name and level range sit above the artwork with progress below')
    check(instanceRow.TitleFade.gradient[2].a==0 and instanceRow.TitleFade:GetHeight()<instanceRow:GetHeight(),
        'card art stays clear below the title fade')
    for _,id in ipairs(ns.Data.dungeons[2437].quests) do completed[id]=true end
    ns.UpdateDungeonFrame()
    for _,row in ipairs(ns.DungeonFrame.Rows)do if row.step.id==2437 then instanceRow=row end end
    check(instanceRow.Progress.Label.text=='Completed' and instanceRow.Progress.Icon:IsShown(),'finished dungeon switches to a checkmarked badge')
    check(instanceRow.Progress.backdrop.edgeFile=='Interface\\Tooltips\\UI-Tooltip-Border',
        'badge uses the rounded Blizzard tooltip edge')
    completed={}
    check(instanceRow.CardBorder:IsShown(),'dungeon artwork has a button border')
    instanceRow:GetScript('OnClick')(instanceRow)
    check(ns.DungeonFrame.dungeonID==2437,'instance browser can select RFC')
    local dungeonFrame=ns.DungeonFrame
    check(dungeonFrame.DetailBanner.points.TOPLEFT[4]==2 and dungeonFrame.DetailBanner.points.TOPRIGHT[4]==-2,
        'detail artwork spans the panel inside its frame border')
    check(not ns.DungeonFrame.BackButton and not ns.DungeonFrame.MapButton and not ns.DungeonFrame.EntranceButton,
        'dungeon detail leaves navigation to the map')
    local headings={}
    for _,header in ipairs(ns.DungeonFrame.Headings) do
        if header:IsShown() then
            check(header.template=='ListHeaderVisualTemplate' and not header.CollapseButton:IsShown(),'section uses native quest-log visuals without a collapse control')
            headings[#headings+1]=header:GetText()
        end
    end
    check(table.concat(headings,'\n'):find('Prerequisite Chains',1,true),'chain section is actually rendered')
    local header
    for _,row in ipairs(ns.DungeonFrame.Rows)do if row.step.id==5728 and row.isHeader then header=row end end
    check(header and header.kind=='chain','only prerequisite chain has expansion control')
    local detail
    for _,row in ipairs(ns.DungeonFrame.Rows)do if row.step.id==5726 and not row.isHeader then detail=row end end
    check(detail and detail:IsShown(),'expansion reveals missing prerequisite pickup')
    local waypoint,map
    local oldSetMap=WorldMapFrame.SetMapID
    WorldMapFrame.SetMapID=function(_,id)map=id browserMapID=id end
    local oldWaypoint=C_Map.SetUserWaypoint
    C_Map.SetUserWaypoint=function(point)waypoint=point end
    detail:GetScript('OnClick')(detail)
    check(map==1454 and waypoint and waypoint.map==1454,'prerequisite click navigates map and sets native waypoint')
    check(not ns.DungeonFrame:IsShown(),'pickup navigation uncovers map and leaves Spoken untouched')
    local previousWaypoint=waypoint
    ns.HandleChecklistClick(detail,5724,'available',{inside},ns.CloseDungeons)
    check(waypoint==previousWaypoint,'inside pickup does not produce fake waypoint')
    local showDungeonMap=ns.ShowDungeonMap
    local getDisplayedDungeon=ns.GetDisplayedDungeonMapID
    local shownMap
    ns.ShowDungeonMap=function(id)if id==2437 then shownMap=id browserMapID=1454 end end
    ns.GetDisplayedDungeonMapID=function()return shownMap end
    ns.OpenDungeons()
    ns.DungeonFrame.Rows[1]:GetScript('OnClick')()
    check(shownMap==2437 and ns.DungeonFrame.dungeonID==2437,'selecting the RFC card opens the map and quests')
    shownMap=nil
    ns.UpdateDungeonFrame()
    local orgrimmar,localCount=dungeonCards()
    check(localCount==1 and orgrimmar[2437] and ns.DungeonFrame.dungeonID==nil,
        'zooming out to the underlying Orgrimmar map switches to the scoped list')
    ns.OpenEntranceDungeons({2437})
    ns.UpdateDungeonFrame()
    check(shownMap==2437 and ns.DungeonFrame.dungeonID==2437,'an open dungeon panel follows entrance navigation')
    ns.CloseDungeons()
    shownMap=nil
    ns.OpenEntranceDungeons({2437})
    check(shownMap==2437 and not ns.DungeonsOpen and not ns.DungeonFrame:IsShown(),
        'an entrance opens the dungeon map while leaving the quest panel closed')
    SpokenPlaces:SetMapPanelCollapsed(false)
    shownMap=nil
    ns.OpenEntranceDungeons({2437})
    check(shownMap==2437 and ns.DungeonsOpen and ns.DungeonFrame.dungeonID==2437
        and ns.DungeonFrame:IsShown() and not SpokenPlacesPanel:IsShown(),
        'an entrance replaces a visible Place Story panel with the selected dungeon quests')
    ns.ShowDungeonMap=showDungeonMap
    ns.GetDisplayedDungeonMapID=getDisplayedDungeon
    ns.OpenDungeons(2437)
    browserMapID=1414
    ns.UpdateDungeonFrame()
    check(ns.DungeonFrame.dungeonID==nil,'ordinary map navigation returns an open detail to the new list')
    accepted[5728]=true
    completed[5722]=true
    ns.OpenDungeons(2437)
    ns.Refresh()
    check(ns.DungeonFrame.CompletedCount.Label.text=='1/6 Completed' and ns.DungeonFrame.InLogCount.Label.text=='1 In Quest Log',
        'visible detail progress refreshes after quest-state changes')
    check(not ns.DungeonFrame.CompletedCount.Icon:IsShown(),'partial dungeon progress uses the neutral badge')
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
    local oldShowMap=ns.ShowDungeonMap
    ns.ShowDungeonMap=function(id)calls=id end
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
    WorldMapFrame.questsStartsEntrances=nil
    ns.Settings.showEntrances=true ns.DrawDungeonEntrances(WorldMapFrame,1454)
    check(portalCount==1,'entrance renders on Orgrimmar map outside general pickup coverage')
    ns.Settings.showEntrances=false ns.DrawDungeonEntrances(WorldMapFrame,1454)
    check(portalCount==1 and ns.lastEntranceCount==0,'entrance filter suppresses portals')
    ns.Settings.showEntrances=true WorldMapFrame.AcquirePin=oldDraw
    ns.ShowDungeonMap=oldShowMap
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
    check(ns.DungeonButton:IsShown() and ns.ZoneButton.point[2]==ns.DungeonFrame,
        'without Spoken both windowed tabs remain available beside the dungeon panel')
    WorldMapFrame.IsShown=function()return false end
    mapHooks.OnHide()
    WorldMapFrame.IsShown=function()return true end
    mapHooks.OnShow()
    check(not ns.DungeonsOpen and not ns.DungeonFrame:IsShown(),'map close clears the selected dungeon view before reopen')
    WorldMapFrame.IsShown=oldMapShown
    mapAlpha=1 mapHooks.OnUpdate()
    check(ns.DungeonButton:GetAlpha()==1,'closed-panel tab follows the map back to full opacity')
    check(ns.ZoneButton:IsShown() and ns.ZoneButton.point[2]==WorldMapFrame,'without Spoken zone quests takes the first right-side tab')
    local zoneMapID=1413
    WorldMapFrame.GetMapID=function()return zoneMapID end
    WorldMapFrame.SetMapID=function(_,id)zoneMapID=id end
    completed[865]=true
    ns.ZoneButton.customClick()
    local zoneFrame=ns.ZoneFrame
    check(zoneFrame:IsShown() and not ns.DungeonFrame:IsShown() and ns.ZoneButton.checked,
        'windowed Zone Quests opens in the same dock and selects its tab')
    check(zoneFrame.Navigation==nil and zoneFrame.Header:IsShown() and #zoneFrame.Rows>100,
        'windowed Barrens shows its checklist without breadcrumbs')
    check(zoneFrame.Header.points.TOPLEFT[4]==2 and zoneFrame.Header.points.TOPRIGHT[4]==-2
        and zoneFrame.Header.Art.file==1851084 and zoneFrame.Header.Title.text:find('10-25',1,true),
        'zone header spans the frame and shows Barrens artwork and the fallback level range')
    local oldMapLevels=C_Map.GetMapLevels
    C_Map.GetMapLevels=function(id)if id==1413 then return 11,24 end end
    ns.UpdateZoneFrame()
    check(zoneFrame.Header.Title.text:find('11-24',1,true),'zone header prefers the native map level range when available')
    C_Map.GetMapLevels=oldMapLevels
    local progress=zoneFrame.Progress
    local total=tonumber(progress.text:match('^1/(%d+) Completed$'))
    check(progress.template=='ColoredProgressBarTemplate' and total and total>100 and progress.fraction==1/total
        and progress.color==ColoredProgressBarMixin.ColorType.Blue and zoneFrame.InLogCount==nil,
        'native progress bar displays the count, and partial completion stays blue')
    check(#zoneFrame.ChainHeaders>0,'each zone chain has a heading')
    local zoneRows={}
    for _,row in ipairs(zoneFrame.Rows) do if row:IsShown() then zoneRows[row.quest.id]=row end end
    check(not zoneRows[865] and zoneRows[6981].Kind:IsShown(),'completed quests hide by default and inside pickups are marked as dungeon quests')
    local fullZoneProgress=progress.text
    zoneFrame.QuestSearch:SetText('glowing shard')
    local questMatchCount=0
    for _,row in ipairs(zoneFrame.Rows) do
        if row:IsShown() then
            check(row.quest.id==6981,'quest search retains the matching quest')
            questMatchCount=questMatchCount+1
        end
    end
    check(questMatchCount==1 and zoneFrame.Progress.text==fullZoneProgress,'quest search keeps the zone completion summary')
    zoneFrame.QuestSearch:SetText('')
    local chainRow
    for _,row in ipairs(zoneFrame.Rows) do
        if row:IsShown() and row.chain and #row.chain.steps>1 then chainRow=row break end
    end
    local originalAddLine=GameTooltip.AddLine
    local hovered, dimmed=false,false
    GameTooltip.AddLine=function(self,text,r,g,b,wrap)
        if text:sub(1,2)=='> ' and r==1 and g==.82 then hovered=true end
        if text:sub(1,3)=='   ' and r==.65 then dimmed=true end
        originalAddLine(self,text,r,g,b,wrap)
    end
    chainRow:GetScript('OnEnter')(chainRow)
    GameTooltip.AddLine=originalAddLine
    check(hovered and dimmed,'chain tooltip highlights exactly the hovered row and dims the other steps')
    check(zoneFrame.Filter.points.TOPRIGHT[3]=='BOTTOMRIGHT' and zoneFrame.QuestSearch.points.RIGHT[2]==zoneFrame.Filter
        and zoneFrame.Filter.template=='WowStyle1ArrowDropdownTemplate' and zoneFrame.Filter:GetWidth()==25,
        'native arrow filter sits beside quest search below the header')
    local filterChecked, toggleCompleted
    zoneFrame.Filter.menu(zoneFrame.Filter,{CreateCheckbox=function(_,label,checked,toggle)
        check(label=='Show Completed Quests','dropdown has a completed-quest filter')
        filterChecked,toggleCompleted=checked,toggle
    end})
    check(not filterChecked(),'completion filter starts unchecked')
    toggleCompleted()
    check(filterChecked() and zoneFrame.Filter.ResetButton:IsShown(),'active filter shows the reset button')
    zoneFrame.Filter.ResetButton:GetScript('OnClick')()
    check(not filterChecked() and not zoneFrame.Filter.ResetButton:IsShown(),'reset clears the filter and hides the reset button')
    toggleCompleted()
    local completedRow
    for _,row in ipairs(zoneFrame.Rows) do if row:IsShown() and row.quest.id==865 then completedRow=row end end
    check(completedRow and completedRow.quest.complete and completedRow:GetHeight()==21,
        'completed filter reveals a checked, compact row')
    check(#completedRow.locations>0,'ordinary zone quests get pickup coordinates from the map data')
    waypoint=nil
    completedRow:GetScript('OnClick')(completedRow)
    check(waypoint and waypoint.map==1413 and not zoneFrame:IsShown(),'completed zone quest navigates to its pickup like dungeon quests')
    local nativeDetails, selectedQuest=QuestMapFrame_OpenToQuestDetails,nil
    QuestMapFrame_OpenToQuestDetails=function(id)selectedQuest=id end
    accepted[865]=true
    ns.OpenZoneQuests()
    for _,row in ipairs(zoneFrame.Rows) do
        if row:IsShown() and row.quest.id==865 then row:GetScript('OnClick')(row) break end
    end
    check(selectedQuest==865 and zoneFrame:IsShown(),'a logged zone quest opens its native details instead of a pickup')
    accepted[865]=nil
    QuestMapFrame_OpenToQuestDetails=nativeDetails
    WorldMapFrame:SetMapID(1414)
    ns.Refresh()
    local durotar
    for _,card in ipairs(zoneFrame.Cards) do if card.mapID==1411 then durotar=card end end
    check(zoneFrame.Overview:IsShown() and #zoneFrame.Cards>20
        and not zoneFrame.Scroll:IsShown() and durotar and durotar.Title.text:find('1-10',1,true) and durotar.highlight,
        'zooming to Kalimdor lists compact zone cards with level ranges')
    zoneFrame.OverviewSearch:SetText('DuroTAR')
    durotar=zoneFrame.Cards[1]
    check(durotar.mapID==1411 and not zoneFrame.Cards[2]:IsShown(),'zone search filters the current continent')
    durotar:GetScript('OnClick')(durotar)
    check(zoneMapID==1411 and zoneFrame.Scroll:IsShown()
        and zoneFrame.Header.Art.file==1851076 and zoneFrame.OverviewSearch:GetText()=='',
        'zone card opens the Durotar checklist and clears the old map query')
    WorldMapFrame:SetMapID(947)
    ns.Refresh()
    local easternKingdoms=zoneFrame.Cards[2]
    check(zoneMapID==947 and zoneFrame.Overview:IsShown() and not zoneFrame.Header:IsShown()
        and easternKingdoms.Title.text=='Eastern Kingdoms' and not zoneFrame.Cards[3]:IsShown(),
        'World shows only the two continent cards')
    easternKingdoms:GetScript('OnClick')(easternKingdoms)
    local undercity
    for _,card in ipairs(zoneFrame.Cards) do
        if card:IsShown() and card.mapID==1458 then undercity=card end
    end
    check(zoneMapID==1415 and undercity and zoneFrame.Overview:IsShown() and not zoneFrame.Scroll:IsShown(),
        'continent card opens its own zone list')
    undercity:GetScript('OnClick')(undercity)
    check(zoneMapID==1458 and zoneFrame.Header.Art.file==131839 and zoneFrame.Scroll:IsShown(),
        'World picker navigates across continents to the city checklist and fallback artwork')
    WorldMapFrame:SetMapID(2482)
    ns.Refresh()
    check(zoneFrame.Header:IsShown() and not zoneFrame.Progress:IsShown() and not zoneFrame.Filter:IsShown()
        and zoneFrame.Empty.text=='No zone quests are recorded in the current source.',
        'mapped source gaps keep the zone header and explain the missing checklist')
    zoneMapID=1413
    ns.Refresh()
    check(zoneFrame.Scroll:IsShown() and zoneFrame.mapID==1413,
        'native map navigation refreshes the open Zone Quests checklist')
    ns.CloseZoneQuests()
    local oldCanvas,oldResize=WorldMapFrame.ScrollContainer,WorldMapFrame.OnFrameSizeChanged
    local oldTabResize,oldTabSelect,oldTabDeselect=PanelTemplates_TabResize,PanelTemplates_SelectTab,PanelTemplates_DeselectTab
    PanelTemplates_TabResize=function(tab,_,width)tab:SetWidth(width)end
    PanelTemplates_SelectTab=function(tab)tab.selected=true end
    PanelTemplates_DeselectTab=function(tab)tab.selected=false end
    local oldSpacer=WorldMapFrame.TitleCanvasSpacerFrame
    WorldMapFrame.TitleCanvasSpacerFrame=object()
    WorldMapFrame.TitleCanvasSpacerFrame:SetHeight(67)
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
    local column=canvas.point[2]
    check(column.parent==WorldMapFrame and not ns.DungeonButton:IsShown()
        and canvas.point[3]=='LEFT' and canvas.point[4]==0, 'fullscreen map ends at its side column without a tab gutter')
    check(column:GetFrameStrata()=='FULLSCREEN' and ns.DungeonFrame:GetFrameStrata()=='FULLSCREEN',
        'fullscreen column and dungeon panel sit below the native dropdown strata')
    check(column.Dungeons.template=='PanelTopTabButtonTemplate' and column.Dungeons.selected
        and column.Zones.template=='PanelTopTabButtonTemplate' and not column.Story:IsShown(),
        'standalone fullscreen offers native zone and dungeon tabs')
    check(ns.DungeonsOpen and ns.DungeonFrame:IsShown() and ns.DungeonFrame.points.TOPLEFT[2]==column,
        'fullscreen opens the dungeon panel inside the column when Spoken is absent')
    column.Dungeons:GetScript('OnClick')()
    check(ns.DungeonsOpen and ns.DungeonFrame:IsShown() and not ns.DungeonFrame.CloseButton:IsShown(),'fullscreen dungeon panel stays open')
    ns.CloseDungeons()
    SpokenPlacesPanel=object()
    SpokenPlacesPanelToggle=object()
    SpokenPlaces={Get=function(_,key)return key=='showMapPanel' end,SetMapPanelCollapsed=function()end,RefreshPanel=function()
        if not WorldMapFrame:IsMaximized() then SpokenPlacesPanel:Show() end
    end}
    ns.SyncDock()
    check(SpokenPlacesPanel:IsShown() and SpokenPlacesPanel.points.TOPLEFT[2]==column and WorldMapFrame:IsMaximized(),
        'Spoken refresh loads fullscreen lore and restores the native maximized flag')
    check(SpokenPlacesPanel:GetFrameStrata()=='FULLSCREEN' and column.Story.template=='PanelTopTabButtonTemplate'
        and column.Story.selected and not column.Dungeons.selected,'Spoken stays below menus and selects its native tab')
    check(column.Story.point[2]==column.Zones and column.Zones.point[2]==column.Dungeons,
        'fullscreen tabs place zone quests between story and dungeons')
    column.Zones:GetScript('OnClick')()
    check(ns.ZoneFrame:IsShown() and not SpokenPlacesPanel:IsShown() and column.Zones.selected
        and ns.ZoneFrame.points.TOPLEFT[2]==column and not ns.ZoneFrame.CloseButton:IsShown(),
        'fullscreen Zone Quests replaces story inside the same dock')
    WorldMapFrame:SetMapID(1414)
    ns.Refresh()
    check(zoneFrame.Overview:IsShown() and not zoneFrame.Header:IsShown() and column.Zones.selected,
        'fullscreen zoom also switches the open zone panel to continent cards')
    column.Dungeons:GetScript('OnClick')()
    check(ns.DungeonFrame:IsShown() and column.Dungeons.selected and not column.Story.selected
        and not SpokenPlacesPanel:IsShown() and not SpokenPlacesPanelToggle:IsShown(),
        'switching from Spoken swaps panels inside the same column')
    column.Story:GetScript('OnClick')()
    check(SpokenPlacesPanel:IsShown() and not ns.DungeonFrame:IsShown(),'the fullscreen story button switches back to lore')
    check(resizeCount==1,'fullscreen switches leave the native zoom bounds in place')
    WorldMapFrame.IsMaximized=function()return false end
    ns.SyncDock()
    check(canvas.point[4]==-3 and resizeCount==2,'windowed viewport and native zoom bounds are rebuilt together')
    WorldMapFrame.ScrollContainer,WorldMapFrame.OnFrameSizeChanged=oldCanvas,oldResize
    PanelTemplates_TabResize,PanelTemplates_SelectTab,PanelTemplates_DeselectTab=oldTabResize,oldTabSelect,oldTabDeselect
    WorldMapFrame.TitleCanvasSpacerFrame=oldSpacer
    WorldMapFrame.GetMapID=oldGetMap
    ColoredProgressBarMixin=oldProgressMixin
    WorldMapFrame.IsMaximized=oldMaximized
    UIParent=oldUIParent SpokenPlacesPanel=oldSpoken SpokenPlaces=oldSpokenAPI SpokenPlacesPanelToggle=oldStoryTab hooksecurefunc=oldHook
    CreateFrame=oldCreateFrame ns.GetPlayerState=oldState WorldMapFrame.SetMapID=oldSetMap C_Map.SetUserWaypoint=oldWaypoint
    WorldMapFrame.GetAlpha=oldMapAlpha
    WorldMapFrame.GetAttribute,SetUIPanelAttribute,UpdateUIPanelPositions=oldGetAttribute,oldSetPanel,oldUpdatePanels
end
