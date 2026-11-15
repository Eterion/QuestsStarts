local _, ns = ...
-- Blizzard loading-screen FileDataIDs from wowdev/wow-listfile.
local dungeonArt={
    [2437]=131862,[718]=131882,[209]=131869,[719]=131823,[491]=131865,
    [721]=131841,[796]=131852,[722]=131864,[1337]=131876,[1176]=131885,
    [2100]=131850,[1477]=131872,[1584]=131824,[1583]=131825,[2557]=131835,
    [2057]=131868,[2017]=131871,
    [16611]=7963782,[16919]=7963781,[16732]=7963777,[16544]=7963775,
}
local cardHeight=72
local detailHeight=88
local clearShadow=CreateColor(0,0,0,0)
local titleShadow=CreateColor(0,0,0,.94)
local checkIcon='Interface\\RaidFrame\\ReadyCheck-Ready'
local questLogIcon='Interface\\GossipFrame\\ActiveQuestIcon'
local shortStatus={completed='Done',['in log']='In log',available='Ready',blocked='Locked',unverified='Check'}
local statuses={
    available='Available', completed='Completed', ['in log']='In your quest log',
    blocked='Not yet available', unverified='Requirements need verification',
}
local reasons={
    profession='Requires a profession', ['profession skill']='Requires higher profession skill',
    ['minimum reputation']='Requires more reputation', ['maximum reputation']='At or above reputation limit',
    ['pickup source unverified']='Pickup source needs verification',
    ['minimum level']='Requires level %d', ['maximum level']='Above maximum level',
    ['recommended level']='Recommended for a higher level', prerequisite='Requires earlier quests',
    ['inactive holiday']='Holiday is not active', ['quest chain state']='Another step is already active or completed',
    ['exclusive quest']='An alternative quest is active or completed', ['parent quest']='Requires an active earlier quest',
    ['enabling quest']='Requires an earlier quest', ['disabling quest']='Blocked by an active quest',
    ['missing quest data']='Quest information is missing', ['cyclic prerequisite']='Quest chain needs verification',
}

function ns.DungeonStatusText(step)
    local reason=reasons[step.reason]
    if step.reason=='minimum level' then
        return string.format(reason,ns.Data.quests[step.id] and ns.Data.quests[step.id].requiredLevel or 0)
    end
    return reason or statuses[step.status] or ns.L.unknown
end

local function isMapPickup(location)
    return location.mapID and location.x and location.y
end

local function canNavigateStatus(status)
    return status=='available' or status=='unverified' or status=='completed'
end

function ns.HasChecklistPickup(status,locations)
    if not canNavigateStatus(status) then return false end
    for _,location in ipairs(locations) do
        if isMapPickup(location) then return true end
    end
    return false
end

local function navigatePickup(location,closePanel)
    if not WorldMapFrame:IsShown() then ToggleWorldMap() end
    WorldMapFrame:SetMapID(location.mapID)
    ns.SetPickupWaypoint(location.mapID,location)
    closePanel()
end

function ns.HandleChecklistClick(owner,id,status,locations,closePanel)
    if status=='in log' then
        if QuestMapFrame_OpenToQuestDetails then QuestMapFrame_OpenToQuestDetails(id) end
        return
    end
    if not canNavigateStatus(status) then return end
    local navigable={}
    for _,location in ipairs(locations) do
        if isMapPickup(location) then
            navigable[#navigable+1]=location
        end
    end
    if #navigable==1 then navigatePickup(navigable[1],closePanel) return end
    if #navigable==0 then return end
    MenuUtil.CreateContextMenu(owner,function(_,root)
        root:CreateTitle(ns.L.pickupMenu)
        for _,location in ipairs(navigable) do
            local target=location
            root:CreateButton(ns.PickupLabel(target,ns.Data),function()navigatePickup(target,closePanel)end)
        end
    end)
end

local function showEntranceMap(owner,dungeon)
    local maps,seen={},{}
    for _,entrance in ipairs(dungeon.entrances or {}) do
        local mapID=entrance.mapID
        if mapID and not seen[mapID] then
            maps[#maps+1]=mapID
            seen[mapID]=true
        end
    end
    local function navigate(mapID)
        ns.DungeonFrame.mapID=mapID
        WorldMapFrame:SetMapID(mapID)
    end
    if #maps==1 then navigate(maps[1]) end
    if #maps<2 then return end
    MenuUtil.CreateContextMenu(owner,function(_,root)
        for _,mapID in ipairs(maps) do
            local target=mapID
            local info=C_Map.GetMapInfo(mapID)
            root:CreateButton(info and info.name or ns.Data.mapNames[mapID] or tostring(mapID),
                function()navigate(target)end)
        end
    end)
end

local function stepTooltip(owner,step)
    GameTooltip:SetOwner(owner,'ANCHOR_RIGHT')
    local text=ns.QuestText({id=step.id,uncertain=step.status=='unverified'})
    GameTooltip:SetText(text,1,.82,0)
    GameTooltip:AddLine(ns.DungeonStatusText(step),1,1,1,true)
    local locations=ns.Data.pickups[step.id] or {}
    for _,location in ipairs(locations) do GameTooltip:AddLine(ns.PickupLabel(location,ns.Data),.8,.8,.8,true) end
    for _,location in ipairs(locations) do
        if location.fromQuest then GameTooltip:AddLine('Use the item to start this quest.',1,1,1,true) break end
    end
    if #locations==0 then GameTooltip:AddLine('Pickup location is not known.',.65,.65,.65,true) end
    if step.branch=='one of' then GameTooltip:AddLine('Complete one of these alternatives.',1,.82,0,true) end
    if step.branch=='all' then GameTooltip:AddLine('All required quests must be completed.',1,.82,0,true) end
    if ns.HasChecklistPickup(step.status,locations) then
        GameTooltip:AddLine(' ')
        GameTooltip:AddLine('Click to show the pickup on the map.',.65,.65,.65,true)
    end
    GameTooltip:Show()
end

function ns.ChecklistBannerTitle(name,low,high)
    if not low or not high then return name end
    return string.format('%s  |cffe7dcc2%d-%d|r',name,low,high)
end

function ns.SetChecklistBannerArt(art,fileID,width,height)
    local loaded=art:SetTexture(fileID)
    if not loaded then
        art:SetColorTexture(.23,.17,.10,1)
    end
    local ratio=(16/9)*height/math.max(1,width)
    local x,y=math.min(1,1/ratio),math.min(1,ratio)
    art:SetTexCoord((1-x)/2,(1+x)/2,(1-y)/2,(1+y)/2)
    return loaded
end

local function createTitleFade(parent,height)
    local fade=parent:CreateTexture(nil,'BORDER')
    fade:SetPoint('TOPLEFT',parent,'TOPLEFT')
    fade:SetPoint('TOPRIGHT',parent,'TOPRIGHT')
    fade:SetHeight(height)
    fade:SetColorTexture(1,1,1,1)
    fade:SetGradient('VERTICAL',clearShadow,titleShadow)
    return fade
end

function ns.CreateChecklistBanner(parent,height)
    local banner=CreateFrame('Frame',nil,parent)
    banner:SetPoint('TOPLEFT',parent,'TOPLEFT',2,-28)
    banner:SetPoint('TOPRIGHT',parent,'TOPRIGHT',-2,-28)
    banner:SetHeight(height)
    banner.Art=banner:CreateTexture(nil,'BACKGROUND')
    banner.Art:SetAllPoints(banner)
    createTitleFade(banner,54)
    banner.Title=banner:CreateFontString(nil,'OVERLAY','GameFontNormalLarge')
    banner.Title:SetPoint('TOPLEFT',banner,'TOPLEFT',14,-10)
    banner.Title:SetPoint('RIGHT',banner,'RIGHT',-14,0)
    banner.Title:SetJustifyH('LEFT')
    banner.Title:SetWordWrap(true)
    banner.Title:SetMaxLines(2)
    banner.Title:SetShadowColor(0,0,0,1)
    banner.Title:SetShadowOffset(1.5,-1.5)
    return banner
end

function ns.CreateQuestBadge(parent,texture)
    local badge=CreateFrame('Frame',nil,parent,'BackdropTemplate')
    badge:SetHeight(20)
    badge:SetBackdrop({
        bgFile='Interface\\Buttons\\WHITE8X8',
        edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',
        edgeSize=8,
        insets={left=2,right=2,top=2,bottom=2},
    })
    badge.Icon=badge:CreateTexture(nil,'ARTWORK')
    badge.Icon:SetTexture(texture)
    badge.Icon:SetSize(14,14)
    badge.Icon:SetPoint('LEFT',badge,'LEFT',5,0)
    badge.Label=badge:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall')
    badge.Label:SetShadowColor(0,0,0,1)
    badge.Label:SetShadowOffset(1,-1)
    return badge
end

local function setBadge(badge,text,showIcon,r,g,b)
    badge.Label:SetText(text)
    badge.Label:SetTextColor(r,g,b)
    badge.Label:SetPoint('LEFT',badge,'LEFT',showIcon and 22 or 7,0)
    badge.Icon:SetShown(showIcon)
    badge:SetWidth(badge.Label:GetStringWidth()+(showIcon and 29 or 14))
    badge:SetBackdropColor(r*.17,g*.17,b*.17,.95)
    badge:SetBackdropBorderColor(r*.65,g*.65,b*.65,.9)
end

function ns.UpdateQuestCountBadges(completedBadge,logBadge,completed,total,accepted)
    local text=string.format('%d/%d Completed',completed,total)
    if total>0 and completed==total then
        setBadge(completedBadge,text,true,.63,1,.50)
    else
        setBadge(completedBadge,text,false,1,.90,.68)
    end
    setBadge(logBadge,string.format('%d In Quest Log',accepted),true,1,.90,.68)
end

local function makeRow(frame,index)
    local row=CreateFrame('Button','QuestsStartsDungeonRow'..index,frame.Content,'QuestTitleButtonTemplate')
    row:SetWidth(294)
    row:SetNormalFontObject('GameFontNormal')
    local title=row:GetFontString()
    title:ClearAllPoints() title:SetPoint('TOPLEFT',row,'TOPLEFT',23,-4)
    title:SetWidth(266) title:SetJustifyH('LEFT') title:SetWordWrap(true)
    title:SetMaxLines(2)
    title:SetShadowColor(0,0,0,1)
    title:SetShadowOffset(1.5,-1.5)
    row.Icon:ClearAllPoints() row.Icon:SetPoint('TOPLEFT',row,'TOPLEFT',3,-4)
    row.Art=row:CreateTexture(nil,'BACKGROUND')
    row.Art:SetAllPoints(row)
    row.TitleFade=createTitleFade(row,48)
    row.CardBorder=CreateFrame('Frame',nil,row,'BackdropTemplate')
    row.CardBorder:SetAllPoints()
    row.CardBorder:SetBackdrop({edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',edgeSize=12})
    row.CardBorder:SetBackdropBorderColor(.76,.62,.40)
    row.Progress=ns.CreateQuestBadge(row,checkIcon)
    row.Progress:SetPoint('BOTTOMRIGHT',row,'BOTTOMRIGHT',-8,6)
    row.Status=row:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall')
    row.Status:SetPoint('TOPLEFT',row,'TOPLEFT',23,-23)
    row.Status:SetWidth(266) row.Status:SetJustifyH('LEFT') row.Status:SetWordWrap(false)
    row:SetScript('OnLeave',function(self)
        self.CardBorder:SetBackdropBorderColor(.76,.62,.40)
        if GameTooltip:IsOwned(self) then GameTooltip:Hide() end
    end)
    return row
end

local sectionNames={['in log']='In Your Quest Log',available='Pick Up Before Entering',inside='Pick Up Inside the Instance',
    chains='Prerequisite Chains',blocked='Not Yet Available',completed='Completed'}

function ns.CreateChecklistSearch(parent,onChange)
    local search=CreateFrame('EditBox',nil,parent,'SearchBoxTemplate')
    search:SetAutoFocus(false)
    search:SetHeight(22)
    search:HookScript('OnTextChanged',function(self)
        if not self.resetting then onChange() end
    end)
    search:HookScript('OnHide',function(self)self:ClearFocus()end)
    return search
end

function ns.ResetChecklistSearch(search)
    search:ClearFocus()
    search.resetting=true
    search:SetText('')
    search.resetting=false
end

function ns.ChecklistSearchQuery(search)
    return (search:GetText() or ''):match('^%s*(.-)%s*$'):lower()
end

function ns.ChecklistSearchMatches(name,query)
    return query=='' or name:lower():find(query,1,true)~=nil
end

function ns.PositionDungeonFrame()
    local frame=ns.DungeonFrame
    if not frame then return end
    ns.SyncDock()
    local width=frame:GetWidth()
    frame.Content:SetWidth(math.max(1,width-46))
    return true
end

function ns.UpdateDungeonFrame()
    local frame=ns.DungeonFrame
    if not frame or not frame:IsShown() then return end
    local data=ns.Data
    if not ns.PositionDungeonFrame() then return end
    local mapID=WorldMapFrame:GetMapID()
    if frame.mapID~=mapID then
        frame.mapID,frame.dungeonID=mapID,nil
        ns.ResetChecklistSearch(frame.Search)
        frame.Scroll:SetVerticalScroll(0)
    end
    local dungeon=frame.dungeonID and data.dungeons[frame.dungeonID]
    local player=ns.GetPlayerState()
    local visible,headingCount,y=0,0,0
    local function heading(text,count)
        if y>0 then y=y+6 end
        headingCount=headingCount+1
        local bar=frame.Headings[headingCount]
        if not bar then
            bar=CreateFrame('Button',nil,frame.Content,'ListHeaderVisualTemplate')
            bar:EnableMouse(false)
            bar.CollapseButton:Hide()
            bar.ButtonText:ClearAllPoints()
            bar.ButtonText:SetPoint('LEFT',bar,'LEFT',9,0)
            bar.ButtonText:SetPoint('RIGHT',bar,'RIGHT',-9,0)
            frame.Headings[headingCount]=bar
        end
        bar:ClearAllPoints()
        bar:SetPoint('TOPLEFT',frame.Content,'TOPLEFT',0,-y)
        bar:SetSize(frame.Content:GetWidth(),25)
        bar:SetText(text..' ('..count..')')
        bar:Show()
        y=y+29
    end
    local function acquire(step,kind)
        visible=visible+1
        local row=frame.Rows[visible]
        if not row then row=makeRow(frame,visible) frame.Rows[visible]=row end
        row:ClearAllPoints() row:SetPoint('TOPLEFT',frame.Content,'TOPLEFT',0,-y)
        local width=frame.Content:GetWidth()
        local card=kind=='instance'
        row:SetWidth(width)
        row:SetHeight(card and cardHeight or 23)
        row.step=step row.kind=kind row.isHeader=kind=='chain'
        row.Art:SetShown(card)
        row.TitleFade:SetShown(card)
        row.CardBorder:SetShown(card)
        row.CardBorder:SetBackdropBorderColor(.76,.62,.40)
        row.Progress:SetShown(card)
        row.Status:SetShown(not card)
        row.Icon:SetShown(not card and not row.isHeader)
        local title=row:GetFontString()
        title:ClearAllPoints()
        title:SetMaxLines(1)
        title:SetWordWrap(false)
        row.Status:ClearAllPoints()
        row.Status:SetWordWrap(false)
        if card then
            ns.SetChecklistBannerArt(row.Art,dungeonArt[step.id],width,cardHeight)
            title:SetPoint('TOPLEFT',row,'TOPLEFT',12,-9)
            title:SetWidth(math.max(1,width-24))
            title:SetMaxLines(2)
            title:SetWordWrap(true)
            title:SetTextColor(1,.89,.65)
            row:SetText(ns.ChecklistBannerTitle(step.name,step.levelLow,step.levelHigh))
            local progress=string.format('%d/%d',step.completed,step.total)
            if step.total>0 and step.completed==step.total then
                setBadge(row.Progress,'Completed',true,.63,1,.50)
            else
                setBadge(row.Progress,progress,false,1,.90,.68)
            end
            row:SetScript('OnClick',function()ns.OpenDungeons(step.id)end)
            row:SetScript('OnEnter',function(self)
                self.CardBorder:SetBackdropBorderColor(1,.82,.45)
                GameTooltip:SetOwner(self,'ANCHOR_RIGHT')
                GameTooltip:SetText(ns.ChecklistBannerTitle(step.name,step.levelLow,step.levelHigh))
                GameTooltip:AddLine(progress..' completed',1,1,1)
                GameTooltip:Show()
            end)
        else
            local label,color=ns.QuestText({id=step.id,uncertain=step.status=='unverified'})
            local indent=kind=='step' and 11 or 0
            local gutter=row.isHeader and 2 or 23+indent
            if kind=='step' then
                label=step.number..'. '..label
                if step.branch=='one of' then label=label..' (or)' end
            end
            title:SetPoint('LEFT',row,'LEFT',gutter,0)
            title:SetWidth(math.max(1,width-gutter-(row.isHeader and 5 or 61)))
            title:SetTextColor(color.r,color.g,color.b)
            row:SetText(label)
            row.Status:SetPoint('RIGHT',row,'RIGHT',-3,0)
            row.Status:SetWidth(55)
            row.Status:SetJustifyH('RIGHT')
            row.Status:SetText(row.isHeader and '' or (step.isNext and 'Next' or shortStatus[step.status] or ''))
            row.Icon:ClearAllPoints()
            row.Icon:SetPoint('LEFT',row,'LEFT',3+indent,0)
            row.Icon:SetSize(15,15)
            row.Icon:SetTexCoord(0,1,0,1)
            if step.status=='completed' then row.Icon:SetTexture(checkIcon)
            elseif step.status=='in log' then row.Icon:SetTexture(questLogIcon)
            else row.Icon:SetAtlas('QuestNormal') end
            row.Icon:SetAlpha(step.status=='blocked' and .4 or 1)
            row:SetScript('OnClick',nil)
            if not row.isHeader then
                row:SetScript('OnClick',function(self)
                    ns.HandleChecklistClick(self,step.id,step.status,ns.Data.pickups[step.id] or {},ns.CloseDungeons)
                end)
            end
            if row.isHeader then
                row:SetScript('OnEnter',function(self)stepTooltip(self,step.steps[1])end)
            else
                row:SetScript('OnEnter',function(self)stepTooltip(self,step)end)
            end
        end
        row:Show()
        y=y+row:GetHeight()+(kind=='instance' and 4 or 0)
    end
    frame.Scroll:ClearAllPoints()
    local hasEntrance=dungeon and dungeon.entrances and #dungeon.entrances>0
    frame.Search:SetShown(not dungeon)
    frame.BackButton:SetShown(dungeon~=nil)
    frame.EntranceButton:SetShown(not not hasEntrance)
    frame.EntranceButton:SetScript('OnClick',hasEntrance and function(owner)showEntranceMap(owner,dungeon)end or nil)
    if dungeon then
        frame.Scroll:SetPoint('TOPLEFT',frame.BackButton,'BOTTOMLEFT',0,-8)
    else
        frame.Scroll:SetPoint('TOPLEFT',frame.Search,'BOTTOMLEFT',-8,-6)
    end
    frame.Scroll:SetPoint('BOTTOMRIGHT',frame,'BOTTOMRIGHT',-28,12)
    frame.DetailBanner:SetShown(dungeon~=nil)
    frame.Empty:Hide()
    if not dungeon then
        local entries=ns.ListDungeons(data,player,mapID)
        local query=ns.ChecklistSearchQuery(frame.Search)
        for _,entry in ipairs(entries) do
            if ns.ChecklistSearchMatches(entry.name,query) then acquire(entry,'instance') end
        end
        frame.Empty:SetText(#entries==0 and 'No dungeons with quest data on this map.' or 'No matching dungeons.')
        frame.Empty:SetShown(visible==0)
    else
        local plan=ns.BuildDungeonPlan(data,frame.dungeonID,player)
        local sections=ns.OrganizeDungeonPlan(data,plan)
        local low,high=ns.DungeonLevelRange(frame.dungeonID,data)
        ns.SetChecklistBannerArt(frame.DetailBanner.Art,dungeonArt[frame.dungeonID],frame:GetWidth()-4,detailHeight)
        frame.DetailBanner.Title:SetText(ns.ChecklistBannerTitle(dungeon.name,low,high))
        ns.UpdateQuestCountBadges(frame.CompletedCount,frame.InLogCount,plan.completed,plan.total,plan.accepted)
        for _,key in ipairs({'in log','available','inside','chains','blocked','completed'}) do
            local entries=sections[key]
            if #entries>0 then
                heading(sectionNames[key],#entries)
                for _,entry in ipairs(entries) do
                    acquire(entry,entry.hasChain and 'chain' or 'quest')
                    if entry.hasChain then
                        local nextStepFound=false
                        for index,step in ipairs(entry.steps) do
                            step.number=index
                            step.isNext=not nextStepFound and not step.branch
                                and (step.status=='in log' or step.status=='available')
                            nextStepFound=nextStepFound or step.isNext
                            acquire(step,'step')
                        end
                        y=y+8
                    end
                end
                y=y+8
            end
        end
    end
    for index=visible+1,#frame.Rows do frame.Rows[index]:Hide() end
    for index=headingCount+1,#frame.Headings do frame.Headings[index]:Hide() end
    frame.Content:SetHeight(math.max(y,1))
end

function ns.OpenDungeons(dungeonID)
    if not ns.Data or not ns.Data.dungeons then return end
    if not WorldMapFrame:IsShown() then ToggleWorldMap() end
    if not ns.DungeonFrame then
        local frame=CreateFrame('Frame','QuestsStartsDungeonFrame',UIParent,'DefaultPanelFlatTemplate')
        frame:Hide()
        frame:SetClampedToScreen(true) frame:SetFrameStrata('HIGH')
        frame:SetTitle(ns.L.dungeons)
        frame.Rows={} frame.Headings={}
        frame.CloseButton=CreateFrame('Button',nil,frame,'UIPanelCloseButtonDefaultAnchors')
        frame.CloseButton:SetScript('OnClick',ns.CloseDungeons)
        frame.Search=ns.CreateChecklistSearch(frame,function()
            frame.Scroll:SetVerticalScroll(0)
            ns.UpdateDungeonFrame()
        end)
        frame.Search:SetPoint('TOPLEFT',frame,'TOPLEFT',24,-33)
        frame.Search:SetPoint('TOPRIGHT',frame,'TOPRIGHT',-34,-33)
        local banner=ns.CreateChecklistBanner(frame,detailHeight)
        frame.DetailBanner=banner
        frame.CompletedCount=ns.CreateQuestBadge(banner,checkIcon)
        frame.CompletedCount:SetPoint('BOTTOMLEFT',banner,'BOTTOMLEFT',14,7)
        frame.InLogCount=ns.CreateQuestBadge(banner,questLogIcon)
        frame.InLogCount:SetPoint('LEFT',frame.CompletedCount,'RIGHT',6,0)
        frame.BackButton=CreateFrame('Button',nil,frame,'UIPanelButtonTemplate')
        frame.BackButton:SetSize(60,22)
        frame.BackButton:SetPoint('TOPLEFT',banner,'BOTTOMLEFT',14,-6)
        frame.BackButton:SetText(BACK or 'Back')
        frame.BackButton:SetScript('OnClick',function()ns.OpenDungeons()end)
        frame.EntranceButton=CreateFrame('Button',nil,frame,'UIPanelButtonTemplate')
        frame.EntranceButton:SetSize(158,22)
        frame.EntranceButton:SetPoint('LEFT',frame.BackButton,'RIGHT',6,0)
        frame.EntranceButton:SetText('Show Entrance on Map')
        frame.Empty=frame:CreateFontString(nil,'OVERLAY','GameFontHighlight')
        frame.Empty:SetPoint('TOPLEFT',frame.Search,'BOTTOMLEFT',-7,-8)
        frame.Empty:SetPoint('RIGHT',frame,'RIGHT',-17,0)
        frame.Empty:SetJustifyH('LEFT')
        frame.Scroll=CreateFrame('ScrollFrame','QuestsStartsDungeonScroll',frame,'QuestsStartsScrollFrameTemplate')
        frame.Scroll:SetPoint('TOPLEFT',frame,'TOPLEFT',16,-128)
        frame.Scroll:SetPoint('BOTTOMRIGHT',frame,'BOTTOMRIGHT',-28,12)
        frame.Content=CreateFrame('Frame',nil,frame.Scroll)
        frame.Content:SetSize(294,1) frame.Scroll:SetScrollChild(frame.Content)
        frame:SetScript('OnShow',ns.UpdateDungeonFrame)
        ns.DungeonFrame=frame
    end
    if ns.CloseZoneQuests then ns.CloseZoneQuests() end
    local mapID=WorldMapFrame:GetMapID()
    if ns.DungeonFrame.mapID~=mapID then ns.ResetChecklistSearch(ns.DungeonFrame.Search) end
    ns.DungeonFrame.mapID=mapID
    ns.DungeonFrame.dungeonID=dungeonID and ns.Data.dungeons[dungeonID] and dungeonID or nil
    if ns.DungeonFrame.dungeonID then ns.DungeonFrame.Search:ClearFocus() end
    ns.DungeonsOpen=true
    local story=ns.GetStorySurfaces()
    if story and SpokenPlaces and SpokenPlaces.SetMapPanelCollapsed then SpokenPlaces:SetMapPanelCollapsed(true) end
    ns.DungeonFrame.Scroll:SetVerticalScroll(0)
    ns.DungeonFrame:Show()
    ns.UpdateDungeonFrame()
end
