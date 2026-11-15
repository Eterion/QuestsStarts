local _, ns = ...
local rowHeight = 21
local bannerHeight = 88
-- War-board FileDataIDs and fallback ranges for mapped zones. The client takes precedence.
local continents = {
    { id = 1414, name = 'Kalimdor', art = 131848, zones = {
        [1411] = { art=1851076, low=1, high=10 }, -- Durotar
        [1412] = { art=1851083, low=1, high=10 }, -- Mulgore
        [1413] = { art=1851084, low=10, high=25 }, -- The Barrens
        [1438] = { art=1851088, low=1, high=11 }, -- Teldrassil
        [1439] = { art=1851074, low=11, high=19 }, -- Darkshore
        [1440] = { art=1851070, low=19, high=30 }, -- Ashenvale
        [1441] = { art=1851110, low=24, high=35 }, -- Thousand Needles
        [1442] = { art=1851107, low=15, high=25 }, -- Stonetalon Mountains
        [1443] = { art=1851097, low=30, high=39 }, -- Desolace
        [1444] = { art=1851102, low=41, high=60 }, -- Feralas
        [1445] = { art=1851099, low=36, high=43 }, -- Dustwallow Marsh
        [1446] = { art=1851109, low=40, high=50 }, -- Tanaris
        [1447] = { art=1851071, low=42, high=55 }, -- Azshara
        [1448] = { art=1851101, low=47, high=54 }, -- Felwood
        [1449] = { art=1851111, low=48, high=55 }, -- Un'Goro Crater
        [1450] = {}, -- Moonglade
        [1451] = { art=1851106, low=55, high=59 }, -- Silithus
        [1452] = { art=1851114, low=55, high=60 }, -- Winterspring
        [1454] = {}, -- Orgrimmar
        [1456] = {}, -- Thunder Bluff
        [1457] = {}, -- Darnassus
        [2482] = { art=1851126 }, -- Mount Hyjal
        [2521] = { low=1, high=12 }, -- Zephras Isle
        [2652] = {}, -- Shen'dralas
    } },
    { id = 1415, name = 'Eastern Kingdoms', art = 131839, zones = {
        [1416] = { low=27, high=39 }, -- Alterac Mountains
        [1417] = { art=1851092, low=30, high=40 }, -- Arathi Highlands
        [1418] = { art=1851093, low=36, high=45 }, -- Badlands
        [1419] = { art=1851094, low=46, high=55 }, -- Blasted Lands
        [1420] = { art=1851089, low=1, high=12 }, -- Tirisfal Glades
        [1421] = { art=1851086, low=10, high=20 }, -- Silverpine Forest
        [1422] = { art=1851112, low=46, high=57 }, -- Western Plaguelands
        [1423] = { art=1851100, low=54, high=59 }, -- Eastern Plaguelands
        [1424] = { art=1851080, low=20, high=31 }, -- Hillsbrad Foothills
        [1425] = { art=1851103, low=41, high=49 }, -- The Hinterlands
        [1426] = { art=1851075, low=1, high=12 }, -- Dun Morogh
        [1427] = { art=1851105, low=43, high=48 }, -- Searing Gorge
        [1428] = { art=1851095, low=50, high=59 }, -- Burning Steppes
        [1429] = { art=1851068, low=1, high=10 }, -- Elwynn Forest
        [1430] = { low=50, high=60 }, -- Deadwind Pass
        [1431] = { art=1851098, low=19, high=30 }, -- Duskwood
        [1432] = { art=1851081, low=10, high=18 }, -- Loch Modan
        [1433] = { art=1851085, low=15, high=25 }, -- Redridge Mountains
        [1434] = { art=1851104, low=30, high=44 }, -- Stranglethorn Vale
        [1435] = { art=1851108, low=36, high=43 }, -- Swamp of Sorrows
        [1436] = { art=1851091, low=9, high=18 }, -- Westfall
        [1437] = { art=1851113, low=20, high=30 }, -- Wetlands
        [1453] = {}, -- Stormwind City
        [1455] = {}, -- Ironforge
        [1458] = {}, -- Undercity
        [2548] = { low=36, high=44 }, -- Riverglades
    } },
}
local continentByZone = {}
local continentByID = {}
for _, continent in ipairs(continents) do
    continentByID[continent.id] = continent
    for id in pairs(continent.zones) do continentByZone[id] = continent end
end

local function zoneName(id)
    local info = C_Map.GetMapInfo and C_Map.GetMapInfo(id)
    return info and info.name or ns.Data.mapNames[id] or (continentByID[id] and continentByID[id].name) or WORLD or 'World'
end

local function worldMapID()
    local info = C_Map.GetMapInfo and C_Map.GetMapInfo(continents[1].id)
    return info and info.parentMapID and info.parentMapID > 0 and info.parentMapID or 947
end

function ns.IsChecklistWorldMap(mapID)
    return mapID == 947 or mapID == worldMapID()
end

function ns.GetChecklistContinent(mapID)
    local continent = continentByID[mapID] or continentByZone[mapID]
    return continent and continent.id
end

local function selectMap(mapID)
    WorldMapFrame:SetMapID(mapID)
    ns.UpdateZoneFrame()
end

local function zoneLevels(mapID, banner)
    local low, high
    if C_Map.GetMapLevels then low, high = C_Map.GetMapLevels(mapID) end
    if low and high and low > 0 and high > low then return low, high end
    if banner then return banner.low, banner.high end
end

local function setZoneArtwork(texture, banner, fallback, width, height)
    local art = banner and banner.art
    if not ns.SetChecklistBannerArt(texture, art or fallback, width, height) and art and art ~= fallback then
        ns.SetChecklistBannerArt(texture, fallback, width, height)
    end
end

local function updateOverview(frame, continent, width)
    local content = frame.Overview.Content
    content:SetWidth(width)
    local query = ns.ChecklistSearchQuery(frame.OverviewSearch)
    local entries = {}
    if continent then
        for id, banner in pairs(continent.zones) do
            if ns.Data.mapNames[id] then
                local name = zoneName(id)
                if ns.ChecklistSearchMatches(name,query) then
                    local low, high = zoneLevels(id, banner)
                    entries[#entries+1] = { id=id, name=name, banner=banner, low=low, high=high }
                end
            end
        end
        table.sort(entries, function(a,b) return a.name < b.name end)
    else
        for _, entry in ipairs(continents) do
            local name = zoneName(entry.id)
            if ns.ChecklistSearchMatches(name,query) then
                entries[#entries+1] = { id=entry.id, name=name, banner=entry }
            end
        end
    end
    local height, spacing = 40, 4
    for i, entry in ipairs(entries) do
        local card = frame.Cards[i]
        if not card then
            card = CreateFrame('Button', nil, content, 'BackdropTemplate')
            card:SetBackdrop({ edgeFile='Interface\\Tooltips\\UI-Tooltip-Border', edgeSize=10 })
            card.Art = card:CreateTexture(nil, 'BACKGROUND', nil, -1)
            card.Art:SetAllPoints(card)
            local shade = card:CreateTexture(nil, 'BACKGROUND', nil, 1)
            shade:SetAllPoints(card)
            shade:SetColorTexture(1, 1, 1, 1)
            shade:SetGradient('HORIZONTAL', CreateColor(0,0,0,.88), CreateColor(0,0,0,.35))
            card.Title = card:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
            card.Title:SetPoint('LEFT', card, 'LEFT', 11, 0)
            card.Title:SetPoint('RIGHT', card, 'RIGHT', -11, 0)
            card.Title:SetJustifyH('LEFT')
            card.Title:SetWordWrap(false)
            card:SetHighlightTexture('Interface\\Buttons\\UI-Listbox-Highlight2', 'ADD')
            card:GetHighlightTexture():SetAlpha(.45)
            card:SetScript('OnClick', function(self) selectMap(self.mapID) end)
            card:SetScript('OnEnter', function(self) self:SetBackdropBorderColor(1,.82,.45) end)
            card:SetScript('OnLeave', function(self) self:SetBackdropBorderColor(.76,.62,.40) end)
            frame.Cards[i] = card
        end
        card.mapID = entry.id
        card:SetSize(width, height)
        card:SetPoint('TOPLEFT', content, 'TOPLEFT', 0, -(i-1)*(height+spacing))
        card:SetBackdropBorderColor(.76,.62,.40)
        card.Title:SetText(ns.ChecklistBannerTitle(entry.name, entry.low, entry.high))
        setZoneArtwork(card.Art, entry.banner, continent and continent.art, width, height)
        card:Show()
    end
    for i = #entries+1, #frame.Cards do frame.Cards[i]:Hide() end
    content:SetHeight(math.max(1, #entries*(height+spacing)-spacing))
    return #entries
end

local function rowEnter(self)
    local quest = self.quest
    GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
    local title = ns.QuestText(quest)
    GameTooltip:SetText(title)
    if quest.complete then GameTooltip:AddLine('Completed', .4, 1, .4) end
    if quest.active then GameTooltip:AddLine('In Your Quest Log', 1, .82, 0) end
    if quest.dungeon then GameTooltip:AddLine(quest.dungeon, 1, .82, 0, true) end
    for _, location in ipairs(self.locations) do
        GameTooltip:AddLine(ns.PickupLabel(location, ns.Data), .8, .8, .8, true)
    end
    if self.chain then
        GameTooltip:AddLine(' ')
        GameTooltip:AddLine('Quest Chain', 1, .82, 0)
        for _, step in ipairs(ns.ZoneChainTooltipSteps(self.chain, ns.Data.quests, ns.ZoneFrame.player)) do
            local label = ns.QuestText(step)
            local status = step.complete and 'Done' or step.active and 'In Log' or 'Pending'
            if step.id == quest.id then
                GameTooltip:AddLine('> '..label..' ('..status..')', 1, .82, 0, true)
            else
                GameTooltip:AddLine('   '..label..' ('..status..')', .65, .65, .65, true)
            end
        end
    end
    if ns.HasChecklistPickup(self.status, self.locations) then
        GameTooltip:AddLine(' ')
        GameTooltip:AddLine('Click to show the pickup on the map.', .65, .65, .65, true)
    end
    GameTooltip:Show()
end

local function rowClick(self)
    ns.HandleChecklistClick(self, self.quest.id, self.status, self.locations, ns.CloseZoneQuests)
end

local function createRow(content)
    local row = CreateFrame('Button', nil, content, 'QuestTitleButtonTemplate')
    row:SetHeight(rowHeight)
    row:SetNormalFontObject('GameFontNormal')
    row:SetScript('OnEnter', rowEnter)
    row:SetScript('OnLeave', function(self)
        if GameTooltip:IsOwned(self) then GameTooltip:Hide() end
    end)
    row:SetScript('OnClick', rowClick)
    row.Icon:ClearAllPoints()
    row.Icon:SetPoint('LEFT', row, 'LEFT', 3, 0)
    row.Icon:SetSize(14, 14)
    row.Kind = row:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
    row.Kind:SetPoint('RIGHT', row, 'RIGHT', -5, 0)
    row.Kind:SetText('Dungeon')
    local title = row:GetFontString()
    title:ClearAllPoints()
    title:SetJustifyH('LEFT')
    title:SetWordWrap(false)
    title:SetMaxLines(1)
    return row
end

function ns.UpdateZoneFrame()
    local frame = ns.ZoneFrame
    if not frame or not frame:IsShown() or not ns.Data then return end
    local mapID = WorldMapFrame:GetMapID()
    if frame.mapID ~= mapID then
        frame.mapID = mapID
        ns.ResetChecklistSearch(frame.OverviewSearch)
        ns.ResetChecklistSearch(frame.QuestSearch)
        frame.Scroll:SetVerticalScroll(0)
        frame.Overview:SetVerticalScroll(0)
    end
    local isWorld = ns.IsChecklistWorldMap(mapID)
    local continent = continentByID[mapID] or continentByZone[mapID]
    local width = math.max(1, frame:GetWidth()-44)
    frame.Content:SetWidth(width)
    local isHorde = UnitFactionGroup('player') == ns.Data.faction
    local showChecklist = ns.Data.mapNames[mapID] and isHorde
    local showOverview = isHorde and (isWorld or continentByID[mapID] ~= nil)
    frame.Header:SetShown(not not showChecklist)
    frame.Overview:SetShown(showOverview)
    frame.OverviewSearch:SetShown(showOverview)
    frame.Scroll:SetShown(not not showChecklist)
    if showOverview then
        frame.Empty:SetPoint('TOPLEFT', frame.OverviewSearch, 'BOTTOMLEFT', -7, -8)
        local count = updateOverview(frame, continentByID[mapID], width)
        frame.Empty:SetText(count == 0 and 'No matching maps.' or '')
        return
    end
    if not showChecklist then
        frame.Empty:SetPoint('TOPLEFT', frame, 'TOPLEFT', 17, -36)
        if not isHorde then frame.Empty:SetText('Zone quest data is available for Horde characters.')
        else frame.Empty:SetText('No zone checklist is available for this map.') end
        return
    end
    frame.Empty:SetText('')
    local banner = continent and continent.zones[mapID]
    local low, high = zoneLevels(mapID,banner)
    frame.Header.Title:SetText(ns.ChecklistBannerTitle(zoneName(mapID), low, high))
    local bannerWidth = frame:GetWidth()-4
    setZoneArtwork(frame.Header.Art, banner, continent and continent.art or 131848, bannerWidth, bannerHeight)
    if frame.indexMapID ~= mapID then
        frame.ids, frame.dungeons, frame.pickups = ns.IndexZoneQuests(ns.Data, mapID)
        frame.indexMapID = mapID
    end
    local showCompleted = ns.Settings.showCompletedZoneQuests == true
    local player = ns.GetPlayerState()
    player.showLowLevel = true
    frame.player = player
    local plan = ns.BuildZoneChecklist(ns.Data.quests, frame.ids, frame.dungeons, player, showCompleted)
    local query = ns.ChecklistSearchQuery(frame.QuestSearch)
    local function matchesQuest(quest)
        return query=='' or ns.ChecklistSearchMatches(ns.QuestText(quest),query)
    end
    frame.Progress:SetShown(plan.total > 0)
    frame.Filter:SetShown(plan.total > 0)
    frame.Filter.ResetButton:SetShown(plan.total > 0 and showCompleted)
    local colors = ColoredProgressBarMixin.ColorType
    local complete = plan.total > 0 and plan.completed == plan.total
    frame.Progress:SetFillTextureByColorType(complete and colors.Green or colors.Blue)
    frame.Progress:SetFillPercent(plan.completed / math.max(1, plan.total))
    frame.Progress:SetText(string.format('%d/%d Completed', plan.completed, plan.total))
    local y, rowIndex, headerIndex, chainIndex = 0, 0, 0, 0
    local function header(text)
        headerIndex = headerIndex+1
        local bar = frame.Headers[headerIndex]
        if not bar then
            bar = CreateFrame('Button', nil, frame.Content, 'ListHeaderVisualTemplate')
            bar:EnableMouse(false)
            bar.CollapseButton:Hide()
            bar.ButtonText:ClearAllPoints()
            bar.ButtonText:SetPoint('LEFT', bar, 'LEFT', 9, 0)
            bar.ButtonText:SetPoint('RIGHT', bar, 'RIGHT', -9, 0)
            frame.Headers[headerIndex] = bar
        end
        bar:SetPoint('TOPLEFT', frame.Content, 'TOPLEFT', 0, -y)
        bar:SetSize(width, 23)
        bar:SetText(text)
        bar:Show()
        y = y+26
    end
    local function chainHeader(chain)
        chainIndex = chainIndex+1
        local label = frame.ChainHeaders[chainIndex]
        if not label then
            label = frame.Content:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
            label:SetJustifyH('LEFT')
            label:SetWordWrap(false)
            label:SetMaxLines(1)
            frame.ChainHeaders[chainIndex] = label
        end
        label:SetPoint('TOPLEFT', frame.Content, 'TOPLEFT', 6, -y)
        label:SetWidth(math.max(1, width-12))
        label:SetHeight(20)
        local title = ns.QuestText(chain.steps[1])
        label:SetText(string.format('%s  |cffbfbfbf%d/%d|r', title, chain.completed, #chain.steps))
        label:Show()
        y = y+20
    end
    local function addRow(quest, chain)
        rowIndex = rowIndex+1
        local row = frame.Rows[rowIndex]
        if not row then
            row = createRow(frame.Content)
            frame.Rows[rowIndex] = row
        end
        row.quest = quest
        row.chain = chain
        row.locations = frame.pickups[quest.id] or {}
        if quest.active then row.status = 'in log'
        elseif quest.complete then row.status = 'completed'
        else
            local available = ns.IsAvailable(quest.id, ns.Data.quests, player)
            row.status = available and 'available' or available == nil and 'unverified' or 'blocked'
        end
        row:SetPoint('TOPLEFT', frame.Content, 'TOPLEFT', 0, -y)
        row:SetWidth(width)
        row.Kind:SetShown(quest.dungeon ~= nil)
        row.Icon:SetShown(quest.complete or quest.active)
        if quest.complete then row.Icon:SetTexture('Interface\\RaidFrame\\ReadyCheck-Ready')
        elseif quest.active then row.Icon:SetTexture('Interface\\GossipFrame\\ActiveQuestIcon') end
        local title = row:GetFontString()
        local label, color = ns.QuestText(quest)
        local indent = chain and 33 or 20
        row.Icon:SetPoint('LEFT', row, 'LEFT', chain and 16 or 3, 0)
        if chain then label = quest.stepNumber..'. '..label end
        title:SetPoint('LEFT', row, 'LEFT', indent, 0)
        title:SetWidth(math.max(1, width-indent-(quest.dungeon and 56 or 7)))
        if quest.complete then title:SetTextColor(.68, .68, .68)
        else title:SetTextColor(color.r, color.g, color.b) end
        row:SetText(label)
        row:Show()
        y = y+rowHeight
    end
    for _, chain in ipairs(plan.chains) do
        local started = false
        for _, quest in ipairs(chain.visible) do
            if matchesQuest(quest) then
                if not started then
                    if chainIndex==0 then header('Quest Chains') end
                    chainHeader(chain)
                    started = true
                end
                addRow(quest, chain)
            end
        end
        if started then y = y+8 end
    end
    local standaloneHeader = false
    for _, quest in ipairs(plan.quests) do
        if matchesQuest(quest) then
            if not standaloneHeader then
                header(chainIndex > 0 and 'Other Quests' or 'Quests')
                standaloneHeader = true
            end
            addRow(quest)
        end
    end
    if rowIndex == 0 then
        frame.Empty:SetPoint('TOPLEFT', frame.Scroll, 'TOPLEFT', 1, -3)
        if not next(frame.ids) then frame.Empty:SetText('No zone quests are recorded in the current source.')
        elseif plan.total == 0 then frame.Empty:SetText('No quests are recorded for this character here.')
        elseif query~='' then frame.Empty:SetText('No matching quests.')
        else frame.Empty:SetText('No quests to show.') end
    end
    for i = rowIndex+1, #frame.Rows do frame.Rows[i]:Hide() end
    for i = headerIndex+1, #frame.Headers do frame.Headers[i]:Hide() end
    for i = chainIndex+1, #frame.ChainHeaders do frame.ChainHeaders[i]:Hide() end
    frame.Content:SetHeight(math.max(1, y))
end

function ns.OpenZoneQuests()
    if not ns.Data then return end
    if not ns.ZoneFrame then
        local frame = CreateFrame('Frame', 'QuestsStartsZoneFrame', UIParent, 'DefaultPanelFlatTemplate')
        frame:Hide()
        frame:SetClampedToScreen(true)
        frame:SetTitle(ns.L.zoneQuests)
        frame.Rows, frame.Headers, frame.ChainHeaders, frame.Cards = {}, {}, {}, {}
        frame.CloseButton = CreateFrame('Button', nil, frame, 'UIPanelCloseButtonDefaultAnchors')
        frame.CloseButton:SetScript('OnClick', ns.CloseZoneQuests)
        local header = ns.CreateChecklistBanner(frame,bannerHeight)
        frame.Header = header
        frame.Progress = CreateFrame('Frame', nil, header, 'ColoredProgressBarTemplate')
        frame.Progress:SetPoint('BOTTOMLEFT', header, 'BOTTOMLEFT', 10, 3)
        frame.Progress:SetPoint('BOTTOMRIGHT', header, 'BOTTOMRIGHT', -10, 3)
        frame.Filter = CreateFrame('DropdownButton', nil, header, 'WowStyle1ArrowDropdownTemplate')
        frame.Filter:SetPoint('TOPRIGHT', header, 'BOTTOMRIGHT', -20, -11)
        frame.Filter:HookScript('OnEnter', function(self)
            GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
            GameTooltip:SetText(FILTER or 'Filter')
            GameTooltip:Show()
        end)
        frame.Filter:HookScript('OnLeave', function(self)
            if GameTooltip:IsOwned(self) then GameTooltip:Hide() end
        end)
        frame.QuestSearch = ns.CreateChecklistSearch(header,function()
            frame.Scroll:SetVerticalScroll(0)
            ns.UpdateZoneFrame()
        end)
        frame.QuestSearch:SetPoint('TOPLEFT', header, 'BOTTOMLEFT', 22, -12)
        frame.QuestSearch:SetPoint('RIGHT', frame.Filter, 'LEFT', -5, 0)
        local function setShowCompleted(show)
            ns.Settings.showCompletedZoneQuests = show
            frame.Scroll:SetVerticalScroll(0)
            ns.UpdateZoneFrame()
        end
        local reset = CreateFrame('Button', nil, frame.Filter, 'UIResetButtonTemplate')
        frame.Filter.ResetButton = reset
        reset:SetSize(15, 15)
        reset:SetPoint('CENTER', frame.Filter, 'TOPRIGHT', -2, 0)
        reset:SetScript('OnClick', function() setShowCompleted(false) end)
        frame.Filter:SetupMenu(function(_, menu)
            menu:CreateCheckbox('Show Completed Quests', function()
                return ns.Settings.showCompletedZoneQuests == true
            end, function()
                setShowCompleted(not ns.Settings.showCompletedZoneQuests)
            end)
        end)
        frame.Empty = frame:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
        frame.Empty:SetPoint('RIGHT', frame, 'RIGHT', -17, 0)
        frame.Empty:SetJustifyH('LEFT')
        frame.OverviewSearch = ns.CreateChecklistSearch(frame,function()
            frame.Overview:SetVerticalScroll(0)
            ns.UpdateZoneFrame()
        end)
        frame.OverviewSearch:SetPoint('TOPLEFT', frame, 'TOPLEFT', 24, -33)
        frame.OverviewSearch:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', -34, -33)
        frame.Overview = CreateFrame('ScrollFrame', 'QuestsStartsZoneOverview', frame, 'QuestsStartsScrollFrameTemplate')
        frame.Overview:SetPoint('TOPLEFT', frame.OverviewSearch, 'BOTTOMLEFT', -8, -6)
        frame.Overview:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', -28, 12)
        frame.Overview.Content = CreateFrame('Frame', nil, frame.Overview)
        frame.Overview.Content:SetSize(294, 1)
        frame.Overview:SetScrollChild(frame.Overview.Content)
        frame.Scroll = CreateFrame('ScrollFrame', 'QuestsStartsZoneScroll', frame, 'QuestsStartsScrollFrameTemplate')
        frame.Scroll:SetPoint('TOPLEFT', frame.QuestSearch, 'BOTTOMLEFT', -8, -6)
        frame.Scroll:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', -28, 12)
        frame.Content = CreateFrame('Frame', nil, frame.Scroll)
        frame.Content:SetSize(294, 1)
        frame.Scroll:SetScrollChild(frame.Content)
        ns.ZoneFrame = frame
    end
    ns.CloseDungeons()
    ns.ZoneQuestsOpen = true
    ns.ZoneFrame.Scroll:SetVerticalScroll(0)
    ns.ZoneFrame.Overview:SetVerticalScroll(0)
    local story = ns.GetStorySurfaces()
    if story and SpokenPlaces.SetMapPanelCollapsed then SpokenPlaces:SetMapPanelCollapsed(true) end
    ns.SyncDock()
    ns.UpdateZoneFrame()
end
