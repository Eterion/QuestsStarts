local _,ns=...
local watched=setmetatable({},{__mode='k'})
local queued,syncing,hookedSpoken=false,false,nil
local baseExtraWidth,appliedExtraWidth
local movedPanels=false
local panelSlots={'left','center','doublewide','right'}
local fullscreenStory
local canvasAnchors
local tabGutter=64
local fullscreenStrata='FULLSCREEN_DIALOG'

local function layoutFullscreenCanvas(map,width)
    local canvas=map.ScrollContainer
    if not canvas then return end
    if width then
        if not canvasAnchors then
            canvasAnchors={}
            for index=1,canvas:GetNumPoints() do canvasAnchors[index]={canvas:GetPoint(index)} end
        end
        local inset=(width+tabGutter)*UIParent:GetEffectiveScale()/map:GetEffectiveScale()
        for index=1,canvas:GetNumPoints() do
            local point,relative,relativePoint,x=canvas:GetPoint(index)
            if point=='RIGHT' and relative==map and relativePoint=='RIGHT' and x==-inset then return end
        end
        canvas:SetPoint('RIGHT',map,'RIGHT',-inset,0)
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
local function updatePanelWidth(active,storyTab,tab)
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

    local places=SpokenPlaces
    if places~=hookedSpoken and type(places.SetMapPanelCollapsed)=='function' then
        hookedSpoken=places
        hooksecurefunc(places,'SetMapPanelCollapsed',function(_,collapsed)
            if SpokenPlaces~=places or not ns.GetStorySurfaces() then return end
            fullscreenStory=not collapsed
            if collapsed==false then ns.CloseDungeons() end
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
    local tab,frame=ns.DungeonButton,ns.DungeonFrame
    if tab and tab:GetAlpha()~=alpha then tab:SetAlpha(alpha) end
    if frame and frame:GetAlpha()~=alpha then frame:SetAlpha(alpha) end
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
        return not ((story and story:IsVisible() and story:IsMouseOver())
            or (dungeon and dungeon:IsVisible() and dungeon:IsMouseOver()))
    end)
end

function ns.SyncDock()
    if syncing or not ns.DungeonButton then return end
    syncing=true
    ns.SetupDockHooks()
    local frame,tab=ns.DungeonFrame,ns.DungeonButton
    local story,storyTab=ns.GetStorySurfaces()
    if not WorldMapFrame:IsShown() then
        fullscreenStory=nil
        layoutFullscreenCanvas(WorldMapFrame)
        if frame then frame:Hide() end
        tab:Hide()
        updatePanelWidth()
        syncing=false
        return
    end
    local scale=WorldMapFrame:GetEffectiveScale()/UIParent:GetEffectiveScale()
    local maximized=WorldMapFrame.IsMaximized and WorldMapFrame:IsMaximized()
    local panelWidth
    if maximized then
        local storyWidth=story and SpokenPlaces and SpokenPlaces.Get and SpokenPlaces:Get('panelWidth')
        local preferred=type(storyWidth)=='number' and storyWidth*scale or 340
        panelWidth=math.min(preferred,UIParent:GetWidth()*.4)
        layoutFullscreenCanvas(WorldMapFrame,panelWidth)
    else
        layoutFullscreenCanvas(WorldMapFrame)
    end
    if maximized and story and SpokenPlaces and SpokenPlaces.RefreshPanel then
        if fullscreenStory==nil and SpokenPlaces.Get then
            fullscreenStory=not SpokenPlaces:Get('mapPanelCollapsed')
        end
        if fullscreenStory and not ns.DungeonsOpen and not story:IsShown() then
            refreshFullscreenStory()
        end
        story:ClearAllPoints()
        local storyScale=story:GetEffectiveScale()/UIParent:GetEffectiveScale()
        story:SetPoint('TOPLEFT',UIParent,'TOPRIGHT',(-tabGutter-panelWidth)/storyScale,-67/storyScale)
        story:SetPoint('BOTTOMRIGHT',UIParent,'BOTTOMRIGHT',-tabGutter/storyScale,2/storyScale)
        story:SetFrameStrata(fullscreenStrata)
        story:SetFrameLevel(WorldMapFrame:GetFrameLevel()+15)
        if storyTab then
            storyTab:SetFrameStrata(WorldMapFrame:GetFrameStrata())
            storyTab:SetFrameLevel(WorldMapFrame:GetFrameLevel()+20)
        end
    end
    if story and story.close then story.close:SetShown(not maximized) end
    if maximized and not ns.DungeonsOpen and not (story and story:IsShown()) then
        if not frame then
            syncing=false
            ns.OpenDungeons()
            return
        end
        ns.DungeonsOpen=true
    end
    ns.SyncDockAlpha()
    tab:SetScale(maximized and 1 or scale)
    tab:SetFrameStrata(WorldMapFrame:GetFrameStrata())
    tab:SetFrameLevel(WorldMapFrame:GetFrameLevel()+20)
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
            frame:SetPoint('TOPRIGHT',UIParent,'TOPRIGHT',-tabGutter,-67)
            frame:SetSize(panelWidth,math.max(1,UIParent:GetHeight()-69))
        elseif story then
            frame:SetPoint('TOPLEFT',story,'TOPLEFT',0,0)
            frame:SetSize(story:GetWidth(),story:GetHeight())
        else
            local edge=WorldMapFrame.BorderFrame or WorldMapFrame
            frame:SetPoint('TOPLEFT',edge,'TOPRIGHT',2,0)
            frame:SetSize(340,WorldMapFrame:GetHeight())
        end
    end
    if ns.DungeonsOpen and frame then
        if story and story:IsShown() then story:Hide() end
        frame:Show()
    end
    local active=ns.DungeonsOpen and frame or (story and story:IsShown() and story)
    if storyTab then
        tab:SetFrameStrata(storyTab:GetFrameStrata())
        tab:SetFrameLevel(storyTab:GetFrameLevel())
        local point,relative,relativePoint,x,y=storyTab:GetPoint(1)
        if not maximized and point and relative~=story and relative~=frame and relative~=UIParent then
            ns.StoryTabBase={point,relative,relativePoint,x,y}
        end
        storyTab:ClearAllPoints()
        if maximized and active then
            local tabScale=storyTab:GetEffectiveScale()/UIParent:GetEffectiveScale()
            storyTab:SetPoint('TOPLEFT',active,'TOPRIGHT',0,-30/tabScale)
        elseif active then storyTab:SetPoint('TOPLEFT',active,'TOPRIGHT',0,-30)
        elseif ns.StoryTabBase then storyTab:SetPoint(unpack(ns.StoryTabBase))
        else storyTab:SetPoint('TOPLEFT',WorldMapFrame.BorderFrame or WorldMapFrame,'TOPRIGHT',0,-30) end
        storyTab:Show()
        if storyTab.SetChecked then storyTab:SetChecked(not ns.DungeonsOpen and story and story:IsShown() or false) end
        tab:ClearAllPoints()
        if maximized then
            tab:SetFrameStrata(fullscreenStrata)
            storyTab:SetFrameStrata(fullscreenStrata)
            tab:SetPoint('TOPLEFT',storyTab,'BOTTOMLEFT',0,-4)
        else
            tab:SetPoint('TOPLEFT',storyTab,'BOTTOMLEFT',0,-3)
        end
        tab:Show()
    else
        tab:ClearAllPoints()
        if maximized then
            tab:SetFrameStrata(fullscreenStrata)
            tab:SetPoint('TOPLEFT',frame,'TOPRIGHT',0,-30)
        else
            tab:SetPoint('TOPLEFT',WorldMapFrame.BorderFrame or WorldMapFrame,'TOPRIGHT',0,-30)
        end
        tab:SetShown(maximized or not ns.DungeonsOpen)
    end
    if tab.SetChecked then tab:SetChecked(ns.DungeonsOpen==true) end
    updatePanelWidth(active,storyTab,tab)
    syncing=false
end

function ns.InstallDungeonButton()
    local tab=CreateFrame('Frame','QuestsStartsDungeonsButton',UIParent,'LargeSideTabButtonTemplate')
    tab.fillToInterior=true tab.tooltipText=ns.L.dungeons
    tab.Icon:SetTexture('Interface\\Icons\\INV_Misc_Book_09')
    tab:SetChecked(false) tab:EnableMouse(true)
    tab:SetCustomOnMouseUpHandler(function(_,button)
        if button and button~='LeftButton' then return end
        if not ns.DungeonsOpen then
            ns.OpenDungeons()
        end
    end)
    ns.DungeonButton=tab
    WorldMapFrame:HookScript('OnShow',function()
        extendMapFadeHover()
        ns.SyncDock()
        if ns.DungeonsOpen then ns.UpdateDungeonFrame() end
    end)
    WorldMapFrame:HookScript('OnHide',function()
        ns.DungeonsOpen=false
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
