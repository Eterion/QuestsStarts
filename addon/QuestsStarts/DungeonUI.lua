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

function ns.NavigateDungeonPickup(id,location)
    if not location.mapID or not location.x or not location.y then return false end
    if not WorldMapFrame:IsShown() then ToggleWorldMap() end
    WorldMapFrame:SetMapID(location.mapID)
    ns.SetPickupWaypoint(location.mapID,location)
    ns.CloseDungeons()
    return true
end

local function choosePickup(owner,id)
    local locations=ns.Data.pickups[id] or {}
    local navigable={}
    for _,location in ipairs(locations) do if location.mapID then navigable[#navigable+1]=location end end
    if #navigable==1 then ns.NavigateDungeonPickup(id,navigable[1]) return end
    if #navigable==0 then return end
    MenuUtil.CreateContextMenu(owner,function(_,root)
        root:CreateTitle(ns.L.pickupMenu)
        for _,location in ipairs(navigable) do
            local target=location
            root:CreateButton(ns.PickupLabel(target,ns.Data),function()ns.NavigateDungeonPickup(id,target)end)
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

local function canNavigateStep(step)
    return step.status=='available' or step.status=='unverified' or step.status=='completed'
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
    local navigable=false
    for _,location in ipairs(locations) do if location.mapID then navigable=true end end
    if navigable and canNavigateStep(step) then
        GameTooltip:AddLine(' ')
        GameTooltip:AddLine('Click to show the pickup on the map.',.65,.65,.65,true)
    end
    GameTooltip:Show()
end

local function makeRow(frame,index)
    local row=CreateFrame('Button','QuestsStartsDungeonRow'..index,frame.Content,'QuestTitleButtonTemplate')
    row:SetWidth(294)
    row:SetNormalFontObject('GameFontNormal')
    local title=row:GetFontString()
    title:ClearAllPoints() title:SetPoint('TOPLEFT',row,'TOPLEFT',23,-4)
    title:SetWidth(266) title:SetJustifyH('LEFT') title:SetWordWrap(true)
    title:SetMaxLines(2)
    row.Icon:ClearAllPoints() row.Icon:SetPoint('TOPLEFT',row,'TOPLEFT',3,-4)
    row.Art=row:CreateTexture(nil,'BACKGROUND')
    row.Art:SetAllPoints(row)
    row.Shade=row:CreateTexture(nil,'BORDER')
    row.Shade:SetAllPoints(row)
    row.Shade:SetColorTexture(0,0,0,.42)
    row.Caption=row:CreateTexture(nil,'ARTWORK')
    row.Caption:SetPoint('BOTTOMLEFT',row,'BOTTOMLEFT')
    row.Caption:SetPoint('BOTTOMRIGHT',row,'BOTTOMRIGHT')
    row.Caption:SetHeight(36)
    row.Caption:SetColorTexture(.04,.03,.02,.84)
    row.Complete=row:CreateTexture(nil,'OVERLAY')
    row.Complete:SetTexture('Interface\\RaidFrame\\ReadyCheck-Ready')
    row.Complete:SetSize(16,16)
    row.Complete:SetPoint('BOTTOMRIGHT',row,'BOTTOMRIGHT',-8,4)
    row.Complete:Hide()
    row.Status=row:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall')
    row.Progress=row:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall')
    row.Progress:SetWidth(55)
    row.Progress:SetJustifyH('RIGHT')
    row.Status:SetPoint('TOPLEFT',row,'TOPLEFT',23,-23)
    row.Status:SetWidth(266) row.Status:SetJustifyH('LEFT') row.Status:SetWordWrap(false)
    row:SetScript('OnLeave',function(self)if GameTooltip:IsOwned(self) then GameTooltip:Hide() end end)
    return row
end

local sectionNames={['in log']='In Your Quest Log',available='Pick Up Before Entering',inside='Pick Up Inside the Instance',
    chains='Prerequisite Chains',blocked='Not Yet Available',completed='Completed'}

function ns.PositionDungeonFrame()
    local frame=ns.DungeonFrame
    if not frame then return end
    ns.SyncDock()
    local width=frame:GetWidth()
    frame.Content:SetWidth(math.max(1,width-46))
    frame.Summary:SetWidth(math.max(1,width-40))
    frame.Navigation:SetWidth(math.max(1,width-14))
    return true
end

function ns.UpdateDungeonNavigation(frame)
    if frame.navDungeonID==frame.dungeonID then return end
    NavBar_Reset(frame.Navigation)
    if frame.dungeonID then
        local dungeon=ns.Data.dungeons[frame.dungeonID]
        NavBar_AddButton(frame.Navigation,{name=dungeon.name,id=frame.dungeonID,
            OnClick=function()ns.OpenDungeons(frame.dungeonID)end,
            listFunc=function()
                local result={}
                for _,entry in ipairs(ns.ListDungeons(ns.Data,ns.GetPlayerState())) do
                    result[#result+1]={text=entry.name,id=entry.id,func=function(_,id)ns.OpenDungeons(id)end}
                end
                return result
            end})
    end
    frame.navDungeonID=frame.dungeonID
end

function ns.UpdateDungeonFrame()
    local frame=ns.DungeonFrame
    if not frame or not frame:IsShown() then return end
    local data=ns.Data
    if not ns.PositionDungeonFrame() then return end
    local dungeon=frame.dungeonID and data.dungeons[frame.dungeonID]
    local player=ns.GetPlayerState()
    ns.UpdateDungeonNavigation(frame)
    local visible,headingCount,y=0,0,0
    local function heading(text,count)
        if y>0 then y=y+6 end
        headingCount=headingCount+1
        local bar=frame.Headings[headingCount]
        if not bar then
            bar=CreateFrame('Frame',nil,frame.Content)
            local background=bar:CreateTexture(nil,'BACKGROUND')
            background:SetAllPoints(bar)
            background:SetColorTexture(.25,.18,.10,.9)
            bar.Label=bar:CreateFontString(nil,'OVERLAY','GameFontNormal')
            bar.Label:SetPoint('LEFT',bar,'LEFT',8,0)
            frame.Headings[headingCount]=bar
        end
        bar:ClearAllPoints()
        bar:SetPoint('TOPLEFT',frame.Content,'TOPLEFT',0,-y)
        bar:SetSize(frame.Content:GetWidth(),25)
        bar.Label:SetText(text..' ('..count..')')
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
        row.Shade:SetShown(card)
        row.Caption:SetShown(card)
        local complete=card and step.total>0 and step.completed==step.total
        row.Complete:SetShown(complete)
        row.Progress:SetShown(card)
        row.Icon:SetShown(not card and not row.isHeader)
        local title=row:GetFontString()
        title:ClearAllPoints()
        title:SetMaxLines(1)
        title:SetWordWrap(false)
        row.Status:ClearAllPoints()
        row.Status:SetWordWrap(false)
        if card then
            local loaded=row.Art:SetTexture(dungeonArt[step.id])
            if not loaded then row.Art:SetColorTexture(.23,.17,.10,1) end
            local ratio=(16/9)*cardHeight/math.max(1,width)
            local cropX,cropY=math.min(1,1/ratio),math.min(1,ratio)
            row.Art:SetTexCoord((1-cropX)/2,(1+cropX)/2,(1-cropY)/2,(1+cropY)/2)
            title:SetPoint('BOTTOMLEFT',row,'BOTTOMLEFT',12,21)
            title:SetWidth(math.max(1,width-24))
            title:SetTextColor(1,.89,.65)
            row:SetText(step.name)
            row.Status:SetPoint('BOTTOMLEFT',row,'BOTTOMLEFT',12,5)
            row.Status:SetWidth(math.max(1,width-90))
            row.Status:SetJustifyH('LEFT')
            local level=step.levelLow and string.format('Levels %d–%d',step.levelLow,step.levelHigh) or ''
            row.Status:SetText(level)
            row.Progress:ClearAllPoints()
            row.Progress:SetPoint('BOTTOMRIGHT',row,'BOTTOMRIGHT',complete and -27 or -10,5)
            row.Progress:SetText(string.format('%d/%d',step.completed,step.total))
            row:SetScript('OnClick',function()ns.OpenDungeons(step.id)end)
            row:SetScript('OnEnter',function(self)
                GameTooltip:SetOwner(self,'ANCHOR_RIGHT')
                GameTooltip:SetText(step.name)
                GameTooltip:AddLine(row.Status:GetText(),1,1,1)
                GameTooltip:AddLine(row.Progress:GetText()..' completed',1,1,1)
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
            if step.status=='completed' then row.Icon:SetTexture('Interface\\RaidFrame\\ReadyCheck-Ready')
            elseif step.status=='in log' then row.Icon:SetTexture('Interface\\GossipFrame\\ActiveQuestIcon')
            else row.Icon:SetAtlas('QuestNormal') end
            row.Icon:SetAlpha(step.status=='blocked' and .4 or 1)
            row:SetScript('OnClick',nil)
            if not row.isHeader then
                row:SetScript('OnClick',function(self)
                    if canNavigateStep(step) then choosePickup(self,step.id)
                    elseif step.status=='in log' and QuestMapFrame_OpenToQuestDetails then QuestMapFrame_OpenToQuestDetails(step.id) end
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
    frame.EntranceButton:SetShown(not not hasEntrance)
    frame.EntranceButton:SetScript('OnClick',hasEntrance and function(owner)showEntranceMap(owner,dungeon)end or nil)
    frame.Scroll:SetPoint('TOPLEFT',frame,'TOPLEFT',16,dungeon and (hasEntrance and -175 or -147) or -66)
    frame.Scroll:SetPoint('BOTTOMRIGHT',frame,'BOTTOMRIGHT',-28,12)
    frame.DetailArt:SetShown(dungeon~=nil)
    frame.DetailShade:SetShown(dungeon~=nil)
    if not dungeon then
        frame.DungeonName:Hide()
        frame.Summary:Hide()
        for _,entry in ipairs(ns.ListDungeons(data,player)) do acquire(entry,'instance') end
    else
        frame.DungeonName:Show()
        frame.Summary:Show()
        local plan=ns.BuildDungeonPlan(data,frame.dungeonID,player)
        local sections=ns.OrganizeDungeonPlan(data,plan)
        local low,high=ns.DungeonLevelRange(frame.dungeonID,data)
        if not frame.DetailArt:SetTexture(dungeonArt[frame.dungeonID]) then
            frame.DetailArt:SetColorTexture(.23,.17,.10,1)
        end
        local crop=math.min(1,(16/9)*73/frame.Content:GetWidth())
        frame.DetailArt:SetTexCoord(0,1,(1-crop)/2,(1+crop)/2)
        frame.DungeonName:SetText(dungeon.name)
        local levels=low and string.format('Levels %d–%d   ',low,high) or ''
        frame.Summary:SetText(levels..string.format('%d/%d completed   %d in log',plan.completed,plan.total,plan.accepted))
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
        frame.Navigation=CreateFrame('Frame','QuestsStartsDungeonNav',frame,'NavBarTemplate')
        frame.Navigation:SetPoint('TOPLEFT',frame,'TOPLEFT',7,-30)
        NavBar_Initialize(frame.Navigation,'NavButtonTemplate',{name=WORLD or 'World',OnClick=function()ns.OpenDungeons()end},frame.Navigation.home,frame.Navigation.overflow)
        frame.navDungeonID=false
        frame.DetailArt=frame:CreateTexture(nil,'ARTWORK')
        frame.DetailArt:SetPoint('TOPLEFT',frame,'TOPLEFT',16,-66)
        frame.DetailArt:SetPoint('TOPRIGHT',frame,'TOPRIGHT',-28,-66)
        frame.DetailArt:SetHeight(73)
        frame.DetailShade=frame:CreateTexture(nil,'ARTWORK',nil,1)
        frame.DetailShade:SetAllPoints(frame.DetailArt)
        frame.DetailShade:SetColorTexture(.03,.02,.01,.68)
        frame.DungeonName=frame:CreateFontString(nil,'OVERLAY','GameFontNormalLarge')
        frame.DungeonName:SetPoint('BOTTOMLEFT',frame.DetailArt,'BOTTOMLEFT',9,27)
        frame.DungeonName:SetPoint('RIGHT',frame.DetailArt,'RIGHT',-9,0)
        frame.DungeonName:SetJustifyH('LEFT')
        frame.DungeonName:SetWordWrap(true)
        frame.DungeonName:SetMaxLines(2)
        frame.Summary=frame:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall')
        frame.Summary:SetPoint('BOTTOMLEFT',frame.DetailArt,'BOTTOMLEFT',9,7)
        frame.Summary:SetWidth(300) frame.Summary:SetJustifyH('LEFT')
        frame.Summary:SetHeight(16) frame.Summary:SetJustifyV('TOP')
        frame.EntranceButton=CreateFrame('Button',nil,frame,'UIPanelButtonTemplate')
        frame.EntranceButton:SetSize(158,22)
        frame.EntranceButton:SetPoint('TOPLEFT',frame.DetailArt,'BOTTOMLEFT',0,-6)
        frame.EntranceButton:SetText('Show Entrance on Map')
        frame.Scroll=CreateFrame('ScrollFrame','QuestsStartsDungeonScroll',frame,'QuestsStartsScrollFrameTemplate')
        frame.Scroll:SetPoint('TOPLEFT',frame,'TOPLEFT',16,-128)
        frame.Scroll:SetPoint('BOTTOMRIGHT',frame,'BOTTOMRIGHT',-28,12)
        frame.Content=CreateFrame('Frame',nil,frame.Scroll)
        frame.Content:SetSize(294,1) frame.Scroll:SetScrollChild(frame.Content)
        frame:SetScript('OnShow',ns.UpdateDungeonFrame)
        ns.DungeonFrame=frame
    end
    ns.DungeonFrame.dungeonID=dungeonID and ns.Data.dungeons[dungeonID] and dungeonID or nil
    ns.DungeonsOpen=true
    local story=ns.GetStorySurfaces()
    if story and SpokenPlaces and SpokenPlaces.SetMapPanelCollapsed then SpokenPlaces:SetMapPanelCollapsed(true) end
    ns.DungeonFrame.Scroll:SetVerticalScroll(0)
    ns.DungeonFrame:Show()
    ns.UpdateDungeonFrame()
end
