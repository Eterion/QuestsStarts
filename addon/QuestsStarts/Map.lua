local _, ns = ...
local template = 'QuestsStartsPickupPinTemplate'
ns.PinTemplate = template

local function setOfferIcon(texture,kind)
    local dailyAtlas=kind=='Daily' and C_Texture and C_Texture.GetAtlasInfo
        and C_Texture.GetAtlasInfo('QuestDaily')
    texture:SetAtlas(dailyAtlas and 'QuestDaily' or 'QuestNormal')
    if kind=='Repeatable' then
        texture:SetDesaturated(true)
        texture:SetVertexColor(.85,.63,1)
    elseif kind=='Daily' and not dailyAtlas then
        texture:SetDesaturated(true)
        texture:SetVertexColor(.38,.72,1)
    end
end
local function setBookIcon(texture)
    if C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo('LevelUp-Icon-Book') then
        texture:SetAtlas('LevelUp-Icon-Book')
    else
        texture:SetTexture('Interface\\GossipFrame\\GossipGossipIcon')
        texture:SetTexCoord(0,1,0,1)
    end
end

local function setItemIcon(texture)
    if C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo('VignetteLoot') then
        texture:SetAtlas('VignetteLoot')
    else texture:SetTexture('Interface\\Minimap\\Tracking\\Banker') end
end

QuestsStartsPickupPinMixin = CreateFromMixins(MapCanvasPinMixin)
function QuestsStartsPickupPinMixin:OnLoad()
    self:SetScalingLimits(1, 1, 1.2)
    self:UseFrameLevelType('PIN_FRAME_LEVEL_QUEST_OFFER')
end
function QuestsStartsPickupPinMixin:OnAcquired(cluster, mapID)
    ns.ConfigurePinInput(self)
    self.cluster, self.mapID = cluster, mapID
    self:SetPosition(cluster.starter.x, cluster.starter.y)
    local allUncertain,hasItem,hasGiver,hasBook = true,false,false,false
    local allCollected=true
    local allTurnedIn=true
    local offers={}
    for _, group in ipairs(cluster.groups) do
        for _, quest in ipairs(group.quests) do
            if not quest.bookLocation then allCollected=false end
            if not quest.turnedIn then allTurnedIn=false end
            if quest.collection then hasBook=true
            elseif group.starter.kind=='Item' then hasItem=true
            else
                hasGiver=true
                offers[ns.GetQuestOfferKind(ns.Data.quests[quest.id])]=true
            end
            if not quest.uncertain then allUncertain = false end
        end
    end
    local function setCollectible(texture)
        if hasItem then setItemIcon(texture)
        else setBookIcon(texture) end
    end
    self.Texture:SetDesaturated(false)
    self.Texture:SetVertexColor(1,1,1)
    if hasGiver then
        setOfferIcon(self.Texture,offers.Normal and 'Normal' or offers.Daily and 'Daily' or 'Repeatable')
    elseif hasItem or hasBook then setCollectible(self.Texture)
    else self.Texture:SetAtlas('QuestNormal') end
    if self.ItemBadge then
        self.ItemBadge:Hide()
        if (hasItem or hasBook) and hasGiver then
            setCollectible(self.ItemBadge)
            self.ItemBadge:SetAlpha(allUncertain and .5 or 1)
            self.ItemBadge:Show()
        end
    end
    self.Texture:SetAlpha(allUncertain and 0.5 or 1)
    if self.Collected then
        if allTurnedIn then
            self.Collected:SetTexture('Interface\\RaidFrame\\ReadyCheck-Ready')
        elseif allCollected then
            self.Collected:SetTexture('Interface\\RaidFrame\\ReadyCheck-Waiting')
        end
        self.Collected:SetShown(hasBook and (allCollected or allTurnedIn))
    end
    self.Count:SetText(#cluster.groups > 1 and tostring(#cluster.groups) or '')
end
function QuestsStartsPickupPinMixin:OnReleased()
    self:OnMouseLeave()
    if self.ItemBadge then self.ItemBadge:Hide() end
    if self.Collected then self.Collected:Hide() end
    self.cluster, self.mapID = nil, nil
    MapCanvasPinMixin.OnReleased(self)
end
function ns.QuestText(entry)
    local q = ns.Data.quests[entry.id] or {}
    local title = C_QuestLog.GetTitleForQuestID(entry.id) or q.name or ('Quest '..entry.id)
    local level = q.questLevel or 0
    local filters=ns.Filters or {}
    local text = filters.showLevels and level > 0 and ('['..level..'] '..title) or title
    if entry.uncertain then text = text..' |cff999999(?)|r' end
    local color = filters.difficultyColor and GetQuestDifficultyColor(level) or {r=1,g=1,b=1}
    return text, color
end
local function pickupQuestText(entry)
    local title,color=ns.QuestText(entry)
    local kind=ns.GetQuestOfferKind(ns.Data.quests[entry.id])
    if kind~='Normal' then title=title..' ('..kind..')' end
    return title,color
end
function ns.StarterText(starter)
    local name=starter.name or UNKNOWN
    if starter.kind~='Item' then return name end
    local source=starter.droppedBy and ('drops from '..starter.droppedBy)
        or starter.foundIn and ('found in '..starter.foundIn) or 'item starts a quest'
    if starter.containedIn then source=source..', in '..starter.containedIn end
    return name..' ('..source..')'
end
function QuestsStartsPickupPinMixin:OnMouseEnter()
    if not self.cluster then return end
    if not ns.PickupTooltip then
        ns.PickupTooltip=CreateFrame('GameTooltip','QuestsStartsPickupTooltip',UIParent,'GameTooltipTemplate')
    end
    local tooltip=ns.PickupTooltip
    tooltip:SetOwner(self, 'ANCHOR_RIGHT')
    tooltip:ClearLines()
    local multiple = #self.cluster.groups > 1
    local uncertain = false
    local spacers={}
    for _, group in ipairs(self.cluster.groups) do
        local name=ns.StarterText(group.starter)
        tooltip:AddLine(' ')
        spacers[tooltip:NumLines()]=true
        tooltip:AddLine(name,0.1,1,0.1)
        for _, entry in ipairs(group.quests) do
            local text,color = pickupQuestText(entry)
            tooltip:AddLine('  '..text, color.r, color.g, color.b, true)
            if entry.turnedIn then
                tooltip:AddLine('  Turned in to the librarian.',.3,1,.3,true)
            elseif entry.bookLocation=='bags' then
                tooltip:AddLine('  In your bags. Bring it to the librarian.',.3,1,.3,true)
            elseif entry.bookLocation=='bank' then
                tooltip:AddLine('  In your bank. Withdraw it before visiting the librarian.',.3,1,.3,true)
            elseif entry.collection then
                tooltip:AddLine('  Collect the book and bring it to the librarian for the turn-in.',.8,.8,.8,true)
            end
            uncertain = uncertain or entry.uncertain
        end
    end
    if uncertain then
        tooltip:AddLine(' ')
        tooltip:AddLine(ns.L.unknown, 0.65, 0.65, 0.65, true)
    end
    tooltip:AddLine(' ')
    local hint = multiple and ns.L.choosePickup or ns.L.waypoint
    tooltip:AddLine(ns.CanWaypoint(self.mapID) and hint or ns.L.unavailableWaypoint, 0.65, 0.65, 0.65, true)
    -- Native tooltip rows are reused. A spacer can become a quest on the next
    -- hover, so reset every row after all lines exist, not just the headings.
    -- Keep these overrides off the shared GameTooltip and its font objects.
    local font,size,flags=GameTooltipText:GetFont()
    for index=1,tooltip:NumLines() do
        tooltip:GetLeftLine(index):SetFont(font,spacers[index] and size/2 or size,flags)
    end
    tooltip:Show()
end
function QuestsStartsPickupPinMixin:OnMouseLeave()
    if ns.PickupTooltip and ns.PickupTooltip:IsOwned(self) then ns.PickupTooltip:Hide() end
end
function ns.SetPickupWaypoint(mapID, starter)
    if not ns.CanWaypoint(mapID) then return end
    C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(mapID, starter.x, starter.y))
    if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then C_SuperTrack.SetSuperTrackedUserWaypoint(true) end
end
function QuestsStartsPickupPinMixin:OnMouseUpAction(button, menuOwner)
    if button ~= 'LeftButton' or not self.cluster or not ns.CanWaypoint(self.mapID) then return end
    if #self.cluster.groups == 1 then ns.SetPickupWaypoint(self.mapID,self.cluster.starter) return end
    local mapID = self.mapID
    local groups = self.cluster.groups
    if ns.PickupTooltip then ns.PickupTooltip:Hide() end
    MenuUtil.CreateContextMenu(menuOwner or self, function(_, root)
        root:CreateTitle(ns.L.starts)
        for _, group in ipairs(groups) do
            local starter = group.starter
            local submenu=root:CreateButton(ns.StarterText(starter))
            for _, entry in ipairs(group.quests) do
                local text,color = pickupQuestText(entry)
                local colored = string.format('|cff%02x%02x%02x%s|r',math.floor(color.r*255),math.floor(color.g*255),math.floor(color.b*255),text)
                submenu:CreateButton(colored, function() ns.SetPickupWaypoint(mapID,starter) end)
            end
        end
    end)
end
function ns.CanWaypoint(mapID)
    return C_Map.CanSetUserWaypointOnMap and C_Map.CanSetUserWaypointOnMap(mapID)
        and C_Map.SetUserWaypoint and UiMapPoint and UiMapPoint.CreateFromCoordinates
end

ns.ProviderMixin = CreateFromMixins(MapCanvasDataProviderMixin)
function ns.ProviderMixin:RemoveAllData(keepEntrances)
    self:GetMap():RemoveAllPinsByTemplate(template)
    if not keepEntrances then
        self:GetMap():RemoveAllPinsByTemplate(ns.EntrancePinTemplate)
        self:GetMap().questsStartsEntrances=nil
    end
end
function ns.ProviderMixin:RefreshAllData()
    ns.QueueRefresh()
end
function ns.ProviderMixin:OnShow()
    ns.QueueRefresh()
end
function ns.ProviderMixin:OnHide()
    self:RemoveAllData()
end
function ns.ProviderMixin:OnCanvasScaleChanged() ns.QueueRefresh() end
function ns.ProviderMixin:OnCanvasSizeChanged() ns.QueueRefresh() end

function ns.InstallFilter()
    if not Menu or not Menu.ModifyMenu then return end
    Menu.ModifyMenu('MENU_WORLD_MAP_TRACKING', function(_, root)
        root:CreateDivider()
        root:CreateTitle('QuestsStarts')
        local function checkbox(label, key)
            root:CreateCheckbox(label, function() return ns.Settings[key] end, function()
                ns.Settings[key] = not ns.Settings[key]
                ns.QueueRefresh()
            end)
        end
        checkbox(ns.L.questGivers, 'enabled')
        checkbox(ns.L.repeatableQuests, 'showRepeatable')
        checkbox(ns.L.itemStarts, 'showItems')
        checkbox(ns.L.entrances, 'showEntrances')
        root:CreateDivider()
        checkbox(ns.L.turnedInBooks, 'showTurnedInBooks')
        checkbox(ns.L.uncertain, 'includeUnknown')
    end)
end
