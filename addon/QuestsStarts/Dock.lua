local _,ns=...
local watched=setmetatable({},{__mode='k'})
local watchedStoryAnchors=setmetatable({},{__mode='k'})
local queued,syncing,hookedSpoken=false,false,nil
local baseExtraWidth,appliedExtraWidth
local movedPanels=false
local panelSlots={'left','center','doublewide','right'}
local fadingFrames={'DungeonButton','DungeonFrame','ZoneButton','ZoneFrame'}
local fullscreenStory
local canvasAnchors
local fullscreenColumn
-- Blizzard's dropdowns use FULLSCREEN_DIALOG even when opened from the map.
local fullscreenStrata='FULLSCREEN'
local fullscreenTabBand=27

local function layoutFullscreenCanvas(map,column)
    local canvas=map.ScrollContainer
    if not canvas then return end
    if column then
        if not canvasAnchors then
            canvasAnchors={}
            for index=1,canvas:GetNumPoints() do canvasAnchors[index]={canvas:GetPoint(index)} end
        end
        for index=1,canvas:GetNumPoints() do
            local point,relative,relativePoint,x=canvas:GetPoint(index)
            if point=='RIGHT' and relative==column and relativePoint=='LEFT' and x==0 then return end
        end
        canvas:SetPoint('RIGHT',column,'LEFT',0,0)
    elseif canvasAnchors then
        canvas:ClearAllPoints()
        for _,anchor in ipairs(canvasAnchors) do canvas:SetPoint(unpack(anchor)) end
        canvasAnchors=nil
    else
        return
    end
    -- The native resize handler can run before the dock changes the viewport.
    if map.OnFrameSizeChanged then map:OnFrameSizeChanged() end
end

local function layoutFullscreenColumn(map,panelWidth,hasStory)
    if not fullscreenColumn then
        local column=CreateFrame('Frame',nil,map)
        column:SetFrameStrata(fullscreenStrata)
        column:SetFrameLevel(map:GetFrameLevel()+20)
        -- Follow Blizzard's quest-log inset if the native quest log is visible.
        column:SetPoint('TOPRIGHT',map.TitleCanvasSpacerFrame,'BOTTOMRIGHT')
        column.Dungeons=CreateFrame('Button',nil,column,'PanelTopTabButtonTemplate')
        column.Dungeons:SetText(ns.L.dungeons)
        column.Dungeons:SetScript('OnClick',function()
            if not ns.DungeonsOpen then ns.OpenDungeons() end
        end)
        column.Zones=CreateFrame('Button',nil,column,'PanelTopTabButtonTemplate')
        column.Zones:SetText(ns.L.zoneQuests)
        column.Zones:SetScript('OnClick',function()
            if not ns.ZoneQuestsOpen then ns.OpenZoneQuests() end
        end)
        column.Story=CreateFrame('Button',nil,column,'PanelTopTabButtonTemplate')
        column.Story:SetText('Place Story')
        column.Story:SetScript('OnClick',function()
            if (ns.DungeonsOpen or ns.ZoneQuestsOpen) and ns.GetStorySurfaces() and SpokenPlaces.SetMapPanelCollapsed then
                SpokenPlaces:SetMapPanelCollapsed(false)
            end
        end)
        column.Zones:SetPoint('BOTTOMRIGHT',column.Dungeons,'BOTTOMLEFT',-8,0)
        column.Story:SetPoint('BOTTOMRIGHT',column.Zones,'BOTTOMLEFT',-8,0)
        column.Dungeons:SetPoint('BOTTOMRIGHT',column,'TOPRIGHT',-10,-fullscreenTabBand)
        fullscreenColumn=column
    end
    local column=fullscreenColumn
    local width=panelWidth*UIParent:GetEffectiveScale()/map:GetEffectiveScale()
    column:SetSize(width,math.max(1,map:GetHeight()-map.TitleCanvasSpacerFrame:GetHeight()-2))
    local tabs=hasStory and 3 or 2
    local tabWidth=math.max(1,(width-15-8*(tabs-1))/tabs)
    column.minTabWidth=tabWidth
    column.maxTabWidth=tabWidth
    column.Story:SetShown(hasStory)
    column:Show()
    PanelTemplates_TabResize(column.Dungeons,0,tabWidth)
    PanelTemplates_TabResize(column.Zones,0,tabWidth)
    if hasStory then PanelTemplates_TabResize(column.Story,0,tabWidth) end
    return column
end

local function fillMaximizedMap(map)
    if not map:IsMaximized() then return end
    local width,height=map:GetParent():GetSize()
    if map:GetWidth()~=width or map:GetHeight()~=height then
        map:SetSize(width,height)
        SetUIPanelAttribute(map,'bottomClampOverride',0)
        UpdateUIPanelPositions(map)
        map:OnFrameSizeChanged()
    end
end

local function refreshFullscreenStory()
    local map=WorldMapFrame
    -- Spoken's synchronous refresh rejects maximized maps before loading lore.
    local isMaximized=map.IsMaximized
    map.IsMaximized=function()return false end
    local ok,err=pcall(SpokenPlaces.RefreshPanel,SpokenPlaces)
    map.IsMaximized=isMaximized
    if not ok then geterrorhandler()(err) end
end

local function placeManagedPanels(active,right)
    if not active then
        if movedPanels then
            movedPanels=false
            UpdateUIPanelPositions(WorldMapFrame)
        end
        return
    end
    if not GetUIPanel then return end
    local panelScale=active:GetEffectiveScale()
    local panelLeft,panelTop,panelBottom=active:GetLeft(),active:GetTop(),active:GetBottom()
    if not (panelLeft and panelTop and panelBottom) then return end
    panelLeft,panelTop,panelBottom=panelLeft*panelScale,panelTop*panelScale,panelBottom*panelScale
    local uiScale=UIParent:GetEffectiveScale()
    local screenRight=(UIParent:GetRight() or UIParent:GetWidth())*uiScale
    local target=right+8*uiScale
    local windows,seen={},{}
    for _,slot in ipairs(panelSlots) do
        local window=GetUIPanel(slot)
        if window and window~=WorldMapFrame and not seen[window] and window:IsShown() and window:GetLeft() then
            seen[window]=true
            windows[#windows+1]=window
        end
    end
    table.sort(windows,function(a,b)
        return a:GetLeft()*a:GetEffectiveScale()<b:GetLeft()*b:GetEffectiveScale()
    end)
    for _,window in ipairs(windows) do
        local scale=window:GetEffectiveScale()
        local left,top,bottom=window:GetLeft(),window:GetTop(),window:GetBottom()
        local width=window:GetWidth()*scale
        if left and top and bottom and top*scale>panelBottom and bottom*scale<panelTop and left*scale+width>panelLeft then
            if left*scale<target-1 then
                if target+width<=screenRight then
                    window:ClearAllPoints()
                    window:SetPoint('TOPLEFT',UIParent,'BOTTOMLEFT',
                        target/scale-(UIParent:GetLeft() or 0)*uiScale/scale,
                        top-(UIParent:GetBottom() or 0)*uiScale/scale)
                    movedPanels=true
                    target=target+width+8*uiScale
                elseif HideUIPanel then
                    HideUIPanel(window)
                    -- Blizzard may reflow the remaining windows after a close.
                    ns.QueueDock()
                    return
                end
            else
                target=math.max(target,left*scale+width+8*uiScale)
            end
        end
    end
end
local function updatePanelWidth(active,storyTab,zoneTab,tab)
    if not (SetUIPanelAttribute and UpdateUIPanelPositions) then return end
    if InCombatLockdown and InCombatLockdown() then return end
    local map=WorldMapFrame
    -- Forever keeps GetUIPanelAttribute local to Blizzard's panel manager.
    local current=map:GetAttribute('UIPanelLayout-extraWidth')
    if current~=appliedExtraWidth then baseExtraWidth=current end
    local extra=0
    if map:IsShown() and not (map.IsMaximized and map:IsMaximized()) and map:GetRight() then
        local scale=map:GetEffectiveScale()
        local mapRight=map:GetRight()*scale
        local function include(frame)
            if frame and frame:IsShown() and frame:GetRight() then
                local right=frame:GetRight()*frame:GetEffectiveScale()
                extra=math.max(extra,(right-mapRight)/scale)
            end
        end
        include(active)
        include(storyTab)
        include(zoneTab)
        include(tab)
    end
    local width=baseExtraWidth
    if extra>0 then
        local nativeWidth=width
        if not nativeWidth then
            local widthFunc=map:GetAttribute('UIPanelLayout-extraWidthFunc')
            if widthFunc then nativeWidth=widthFunc(map) end
        end
        width=(nativeWidth or 0)+math.ceil(extra)
    end
    appliedExtraWidth=width
    if current~=width then
        SetUIPanelAttribute(map,'extraWidth',width)
        UpdateUIPanelPositions(map)
        movedPanels=false
    end
    if active and extra>0 and map:GetRight() then
        placeManagedPanels(active,(map:GetRight()+extra)*map:GetEffectiveScale())
    else
        placeManagedPanels()
    end
end

function ns.QueueDock()
    if queued then return end
    queued=true
    C_Timer.After(0,function()queued=false ns.SyncDock()end)
end

function ns.CloseDungeons()
    ns.DungeonsOpen=false
    if ns.DungeonFrame then ns.DungeonFrame:Hide() end
    ns.QueueDock()
end

function ns.CloseZoneQuests()
    ns.ZoneQuestsOpen=false
    if ns.ZoneFrame then ns.ZoneFrame:Hide() end
    ns.QueueDock()
end

local function watch(frame)
    if not frame or watched[frame] then return end
    watched[frame]=true
    frame:HookScript('OnShow',ns.QueueDock)
    frame:HookScript('OnHide',ns.QueueDock)
    frame:HookScript('OnSizeChanged',ns.QueueDock)
end

function ns.SetupDockHooks()
    watch(QuestMapFrame)
    local story,tab=ns.GetStorySurfaces()
    if not story then return end
    watch(story)
    watch(tab)
    if not watchedStoryAnchors[tab] then
        watchedStoryAnchors[tab]=true
        hooksecurefunc(tab,'SetPoint',function()
            if not syncing and WorldMapFrame:IsShown() then ns.QueueDock() end
        end)
    end

    local places=SpokenPlaces
    ns.SetupSpokenEntranceInput(places)
    if places~=hookedSpoken and type(places.SetMapPanelCollapsed)=='function' then
        hookedSpoken=places
        hooksecurefunc(places,'SetMapPanelCollapsed',function(_,collapsed)
            if SpokenPlaces~=places or not ns.GetStorySurfaces() then return end
            fullscreenStory=not collapsed
            if collapsed==false then
                ns.CloseDungeons()
                ns.CloseZoneQuests()
            end
            ns.SyncDock()
        end)
        if type(places.RefreshPanel)=='function' then
            hooksecurefunc(places,'RefreshPanel',function()
                if SpokenPlaces==places and ns.GetStorySurfaces() then ns.QueueDock() end
            end)
        end
    end
end

function ns.GetStorySurfaces()
    local places=SpokenPlaces
    if not (places and SpokenPlacesPanel and SpokenPlacesPanelToggle) then return end
    if places.IsPartOn and not places:IsPartOn() then return end
    if places.Get and places:Get('showMapPanel')==false then return end
    return SpokenPlacesPanel,SpokenPlacesPanelToggle
end

function ns.SyncDockAlpha()
    -- These companions are parented to UIParent, so map movement fading must
    -- be mirrored explicitly. Read it while the map is visible rather than
    -- hooking the native fader's SetAlpha calls.
    local alpha=WorldMapFrame:GetAlpha()
    for _,key in ipairs(fadingFrames) do
        local frame=ns[key]
        if frame and frame:GetAlpha()~=alpha then frame:SetAlpha(alpha) end
    end
end

local function extendMapFadeHover()
    local fader=PlayerMovementFrameFader
    if not (fader and fader.AddDeferredFrame and GetCVarBool) then return end
    local map=WorldMapFrame
    fader.AddDeferredFrame(map,.5,1,.5,function()
        if not GetCVarBool('mapFade') or map:IsMouseOver() then return false end
        if map.IsMaximized and map:IsMaximized() then return true end
        local story=ns.GetStorySurfaces()
        local dungeon=ns.DungeonFrame
        local zone=ns.ZoneFrame
        return not ((story and story:IsVisible() and story:IsMouseOver())
            or (dungeon and dungeon:IsVisible() and dungeon:IsMouseOver())
            or (zone and zone:IsVisible() and zone:IsMouseOver()))
    end)
end

function ns.SyncDock()
    if syncing or not ns.DungeonButton then return end
    syncing=true
    ns.SetupDockHooks()
    local frame=ns.ZoneQuestsOpen and ns.ZoneFrame or ns.DungeonFrame
    local tab,zoneTab=ns.DungeonButton,ns.ZoneButton
    local addonPanelOpen=ns.DungeonsOpen or ns.ZoneQuestsOpen
    local story,storyTab=ns.GetStorySurfaces()
    if not WorldMapFrame:IsShown() then
        fullscreenStory=nil
        if fullscreenColumn then fullscreenColumn:Hide() end
        layoutFullscreenCanvas(WorldMapFrame)
        if ns.DungeonFrame then ns.DungeonFrame:Hide() end
        if ns.ZoneFrame then ns.ZoneFrame:Hide() end
        tab:Hide()
        zoneTab:Hide()
        updatePanelWidth()
        syncing=false
        return
    end
    local scale=WorldMapFrame:GetEffectiveScale()/UIParent:GetEffectiveScale()
    local maximized=WorldMapFrame.IsMaximized and WorldMapFrame:IsMaximized()
    local column
    if maximized then
        local storyWidth=story and SpokenPlaces and SpokenPlaces.Get and SpokenPlaces:Get('panelWidth')
        local preferred=type(storyWidth)=='number' and storyWidth*scale or 340
        local panelWidth=math.min(preferred,UIParent:GetWidth()*.4)
        column=layoutFullscreenColumn(WorldMapFrame,panelWidth,story~=nil)
        layoutFullscreenCanvas(WorldMapFrame,column)
    else
        if fullscreenColumn then fullscreenColumn:Hide() end
        layoutFullscreenCanvas(WorldMapFrame)
    end
    if maximized and story and SpokenPlaces and SpokenPlaces.RefreshPanel then
        if fullscreenStory==nil and SpokenPlaces.Get then
            fullscreenStory=not SpokenPlaces:Get('mapPanelCollapsed')
        end
        if fullscreenStory and not addonPanelOpen and not story:IsShown() then
            refreshFullscreenStory()
        end
        story:ClearAllPoints()
        local titleOffset=fullscreenTabBand*WorldMapFrame:GetEffectiveScale()/story:GetEffectiveScale()
        story:SetPoint('TOPLEFT',column,'TOPLEFT',0,-titleOffset)
        story:SetPoint('BOTTOMRIGHT',column,'BOTTOMRIGHT')
        story:SetFrameStrata(fullscreenStrata)
        story:SetFrameLevel(WorldMapFrame:GetFrameLevel()+15)
        if storyTab then
            storyTab:SetFrameStrata(WorldMapFrame:GetFrameStrata())
            storyTab:SetFrameLevel(WorldMapFrame:GetFrameLevel()+20)
        end
    end
    if story and story.close then story.close:SetShown(not maximized) end
    if maximized and not addonPanelOpen and not (story and story:IsShown()) then
        if not frame then
            syncing=false
            ns.OpenDungeons()
            return
        end
        ns.DungeonsOpen=true
        addonPanelOpen=true
    end
    ns.SyncDockAlpha()
    tab:SetScale(maximized and 1 or scale)
    tab:SetFrameStrata(WorldMapFrame:GetFrameStrata())
    tab:SetFrameLevel(WorldMapFrame:GetFrameLevel()+20)
    zoneTab:SetScale(maximized and 1 or scale)
    zoneTab:SetFrameStrata(WorldMapFrame:GetFrameStrata())
    zoneTab:SetFrameLevel(WorldMapFrame:GetFrameLevel()+20)
    local previousWidth=frame and frame:GetWidth()
    if frame then
        frame.CloseButton:SetShown(not maximized)
        local panelScale=story and story:GetEffectiveScale()/UIParent:GetEffectiveScale() or scale
        if maximized then panelScale=1 end
        frame:SetScale(panelScale)
        frame:SetFrameStrata(maximized and fullscreenStrata or (story and story:GetFrameStrata() or WorldMapFrame:GetFrameStrata()))
        frame:SetFrameLevel(maximized and WorldMapFrame:GetFrameLevel()+16
            or (story and story:GetFrameLevel() or WorldMapFrame:GetFrameLevel()+15))
        frame:ClearAllPoints()
        if maximized then
            frame:SetPoint('TOPLEFT',column,'TOPLEFT',0,-fullscreenTabBand*scale)
            frame:SetPoint('BOTTOMRIGHT',column,'BOTTOMRIGHT')
        elseif story then
            frame:SetPoint('TOPLEFT',story,'TOPLEFT',0,0)
            frame:SetSize(story:GetWidth(),story:GetHeight())
        else
            local edge=WorldMapFrame.BorderFrame or WorldMapFrame
            frame:SetPoint('TOPLEFT',edge,'TOPRIGHT',2,0)
            frame:SetSize(340,WorldMapFrame:GetHeight())
        end
    end
    if addonPanelOpen and frame then
        if story and story:IsShown() then story:Hide() end
        frame:Show()
    end
    local active=addonPanelOpen and frame or (story and story:IsShown() and story)
    if maximized then
        tab:Hide()
        zoneTab:Hide()
        if storyTab then storyTab:Hide() end
        local selected=ns.DungeonsOpen and column.Dungeons or ns.ZoneQuestsOpen and column.Zones or column.Story
        for _,button in ipairs({column.Story,column.Zones,column.Dungeons}) do
            if button==selected then PanelTemplates_SelectTab(button)
            else PanelTemplates_DeselectTab(button) end
        end
    else
        local edge=WorldMapFrame.BorderFrame or WorldMapFrame
        zoneTab:ClearAllPoints()
        if storyTab then
            local strata,level=storyTab:GetFrameStrata(),storyTab:GetFrameLevel()
            tab:SetFrameStrata(strata)
            tab:SetFrameLevel(level)
            zoneTab:SetFrameStrata(strata)
            zoneTab:SetFrameLevel(level)
            local point,relative,relativePoint,x,y=storyTab:GetPoint(1)
            if point and relative~=story and relative~=ns.DungeonFrame and relative~=ns.ZoneFrame and relative~=UIParent then
                ns.StoryTabBase={point,relative,relativePoint,x,y}
            end
            storyTab:ClearAllPoints()
            if active then storyTab:SetPoint('TOPLEFT',active,'TOPRIGHT',0,-30)
            elseif ns.StoryTabBase then storyTab:SetPoint(unpack(ns.StoryTabBase))
            else storyTab:SetPoint('TOPLEFT',edge,'TOPRIGHT',0,-30) end
            storyTab:Show()
            if storyTab.SetChecked then storyTab:SetChecked(not addonPanelOpen and story and story:IsShown() or false) end
            if active then
                -- Spoken can move its tab on a later frame without resizing or hiding it.
                local storyHeight=storyTab:GetHeight()*storyTab:GetEffectiveScale()/zoneTab:GetEffectiveScale()
                zoneTab:SetPoint('TOPLEFT',active,'TOPRIGHT',0,-33-storyHeight)
            else
                zoneTab:SetPoint('TOPLEFT',storyTab,'BOTTOMLEFT',0,-3)
            end
        else
            zoneTab:SetPoint('TOPLEFT',active or edge,'TOPRIGHT',0,-30)
        end
        tab:ClearAllPoints()
        tab:SetPoint('TOPLEFT',zoneTab,'BOTTOMLEFT',0,-3)
        zoneTab:Show()
        tab:Show()
    end
    if tab.SetChecked then tab:SetChecked(ns.DungeonsOpen==true) end
    zoneTab:SetChecked(ns.ZoneQuestsOpen==true)
    updatePanelWidth(active,storyTab,zoneTab,tab)
    syncing=false
    if frame and frame:IsShown() and math.abs(frame:GetWidth()-previousWidth)>.5 then
        if ns.ZoneQuestsOpen then ns.UpdateZoneFrame() else ns.UpdateDungeonFrame() end
    end
end

local function createSideTab(name,label,artwork,onClick)
    local tab=CreateFrame('Frame',name,UIParent,'LargeSideTabButtonTemplate')
    tab.tooltipText=label
    tab.Icon:SetTexture(artwork)
    tab:SetFillToInterior(true)
    tab:SetChecked(false) tab:EnableMouse(true)
    tab:SetCustomOnMouseUpHandler(function(_,button)
        if button and button~='LeftButton' then return end
        onClick()
    end)
    return tab
end

function ns.InstallDungeonButton()
    ns.DungeonButton=createSideTab('QuestsStartsDungeonsButton',ns.L.dungeons,
        'Interface\\Icons\\Achievement_Dungeon_ClassicDungeonmaster',function()
        if not ns.DungeonsOpen then ns.OpenDungeons() end
    end)
    ns.ZoneButton=createSideTab('QuestsStartsZoneButton',ns.L.zoneQuests,
        'Interface\\Icons\\Achievement_Quests_Completed_01',function()
        if not ns.ZoneQuestsOpen then ns.OpenZoneQuests() end
    end)
    WorldMapFrame:HookScript('OnShow',function()
        extendMapFadeHover()
        ns.SyncDock()
        if ns.DungeonsOpen then ns.UpdateDungeonFrame() end
    end)
    WorldMapFrame:HookScript('OnHide',function()
        ns.DungeonsOpen=false
        ns.ZoneQuestsOpen=false
        local story=ns.GetStorySurfaces()
        if story and SpokenPlaces and SpokenPlaces.SetMapPanelCollapsed then
            SpokenPlaces:SetMapPanelCollapsed(true)
        end
        ns.SyncDock()
    end)
    WorldMapFrame:HookScript('OnSizeChanged',ns.QueueDock)
    WorldMapFrame:HookScript('OnUpdate',ns.SyncDockAlpha)
    if WorldMapFrame.UpdateMaximizedSize then
        hooksecurefunc(WorldMapFrame,'UpdateMaximizedSize',fillMaximizedMap)
        if WorldMapFrame:IsShown() and WorldMapFrame:IsMaximized() then fillMaximizedMap(WorldMapFrame) end
    end
    if WorldMapFrame.Minimize then
        hooksecurefunc(WorldMapFrame,'Minimize',function()
            local story=ns.GetStorySurfaces()
            if story and SpokenPlaces then
                if SpokenPlaces.ApplyPanelOptions then SpokenPlaces:ApplyPanelOptions()
                elseif SpokenPlaces.RefreshPanel then SpokenPlaces:RefreshPanel() end
            end
            ns.QueueDock()
        end)
    end
    if UpdateUIPanelPositions then
        hooksecurefunc('UpdateUIPanelPositions',function()
            if not syncing and WorldMapFrame:IsShown() then ns.QueueDock() end
        end)
    end
    if EventRegistry and EventRegistry.RegisterCallback then
        EventRegistry:RegisterCallback('UIParentPanelManager.ShowUIPanel',ns.QueueDock,ns)
        EventRegistry:RegisterCallback('UIParentPanelManager.HideUIPanel',ns.QueueDock,ns)
    end
    if WorldMapFrame:IsShown() then extendMapFadeHover() end
    ns.SyncDock()
end
