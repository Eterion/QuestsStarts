local addonName, ns = ...
local queued, initialized = false, false
local events = CreateFrame('Frame')

local function playerState()
    local _, _, raceId = UnitRace('player')
    local _, _, classId = UnitClass('player')
    local complete, active, items, bankItems = {}, {}, {}, {}
    local getCount=C_Item and C_Item.GetItemCount or GetItemCount
    local holidays, monthDay = ns.ReadHolidays()
    local skill,reputation=ns.ReadRequirementState()
    return {
        level=UnitLevel('player'),
        raceMask=ns.Data.raceMasks[raceId],
        classMask=classId and 2^(classId-1),
        showLowLevel=ns.Filters and ns.Filters.showLowLevel,
        trivialRange=C_QuestLog.GetTrivialRange and C_QuestLog.GetTrivialRange() or 5,
        holidays=holidays, monthDay=monthDay,
        skill=skill,reputation=reputation,
        showQuestGivers=ns.Settings.enabled,
        showItemStarts=ns.Settings.showItems,
        showTurnedInBooks=ns.Settings.showTurnedInBooks,
        hasItem=function(id,includeBank)
            local cache=includeBank and bankItems or items
            if cache[id]==nil then
                cache[id]=getCount and (getCount(id,includeBank==true) or 0)>0 or false
            end
            return cache[id]
        end,
        completed=function(id)
            if complete[id] == nil then complete[id] = C_QuestLog.IsQuestFlaggedCompleted(id) == true end
            return complete[id]
        end,
        active=function(id)
            if active[id] == nil then active[id] = C_QuestLog.IsOnQuest(id) == true end
            return active[id]
        end,
    }
end
ns.GetPlayerState=playerState

local function readFilters()
    local get = C_CVar and C_CVar.GetCVarBool or GetCVarBool
    return {
        showLevels=get('showQuestLevel'),
        difficultyColor=get('showQuestDifficultyColor'),
        showLowLevel=C_Minimap and C_Minimap.IsTrackingHiddenQuests and C_Minimap.IsTrackingHiddenQuests() or false,
    }
end

function ns.Refresh()
    if not ns.Provider then return end
    ns.Provider:RemoveAllData(true)
    ns.lastPinCount = 0
    ns.lastEntranceCount = 0
    ns.lastStats = nil
    ns.lastReason = nil
    ns.Filters = readFilters()
    ns.SyncDock()
    if ns.UpdateDungeonFrame then ns.UpdateDungeonFrame() end
    if not ns.Data then ns.lastReason='Pickup data did not load.' return end
    if UnitFactionGroup('player') ~= ns.Data.faction then ns.lastReason='This prototype covers Horde characters.' return end
    if not WorldMapFrame:IsShown() then ns.lastReason='Open a covered zone map, then run /qs again.' return end
    local mapID = WorldMapFrame:GetMapID()
    ns.DrawDungeonEntrances(WorldMapFrame,mapID)
    if not ns.Settings.enabled and not ns.Settings.showItems and not ns.Settings.showTurnedInBooks then
        ns.lastReason='All pickup filters are disabled.'
        return
    end
    -- questPOI controls native accepted-quest objectives, not quest offers. It must
    -- not override the independent Quest starts setting.
    if not ns.Data.maps[mapID] then ns.lastReason='No pickup data for map '..tostring(mapID)..'. '..ns.L.coverage return end
    if #ns.Data.maps[mapID]==0 then ns.lastReason='No NPC or object pickup locations are recorded for this map in the current Horde export.' return end
    -- Suppress only native offers actually drawn, not offers hidden by map filters.
    local native = {}
    for pin in WorldMapFrame:EnumeratePinsByTemplate('QuestOfferPinTemplate') do
        if pin.questID and pin:IsShown() then native[pin.questID] = true end
    end
    local state = playerState()
    ns.lastState = state
    local groups,stats = ns.BuildGroups(ns.Data, mapID, state, ns.Settings.includeUnknown, native)
    ns.lastStats = stats
    local canvas = WorldMapFrame:GetCanvas()
    local scale = WorldMapFrame:GetCanvasScale()
    local pinScale = WorldMapFrame:GetGlobalPinScale()
    for _, cluster in ipairs(ns.ClusterGroups(groups, canvas:GetWidth()*scale, canvas:GetHeight()*scale, 28*pinScale)) do
        WorldMapFrame:AcquirePin(ns.PinTemplate, cluster, mapID)
        ns.lastPinCount = ns.lastPinCount + 1
    end
end

local function refreshSafely()
    local ok,err = pcall(ns.Refresh)
    ns.lastError = not ok and tostring(err) or nil
    return ok,err
end

function ns.QueueRefresh()
    if not initialized or queued then return end
    queued = true
    C_Timer.After(0, function()
        queued = false
        local ok,err=refreshSafely()
        if not ok then geterrorhandler()(err) end
    end)
end

local function initialize()
    if initialized then return end
    if type(QuestsStartsDB) ~= 'table' then QuestsStartsDB = {} end
    ns.Settings = QuestsStartsDB
    if type(ns.Settings.enabled) ~= 'boolean' then ns.Settings.enabled = true end
    if type(ns.Settings.showItems) ~= 'boolean' then ns.Settings.showItems = ns.Settings.enabled end
    if type(ns.Settings.showTurnedInBooks) ~= 'boolean' then ns.Settings.showTurnedInBooks = false end
    if type(ns.Settings.includeUnknown) ~= 'boolean' then ns.Settings.includeUnknown = false end
    if type(ns.Settings.showEntrances) ~= 'boolean' then ns.Settings.showEntrances = true end
    initialized = true
    ns.Provider = CreateFromMixins(ns.ProviderMixin)
    WorldMapFrame:AddDataProvider(ns.Provider)
    ns.InstallFilter()
    ns.InstallMapInput()
    ns.InstallDungeonButton()
    if C_Calendar and C_Calendar.OpenCalendar then C_Calendar.OpenCalendar() end
    ns.QueueRefresh()
end

events:SetScript('OnEvent', function(_, event, ...)
    if event == 'ADDON_LOADED' then
        if ... == addonName then initialize() else ns.QueueDock() end
    elseif event=='GLOBAL_MOUSE_DOWN' or event=='GLOBAL_MOUSE_UP' then
        ns.HandleEntranceMouse(event,...)
    else ns.QueueRefresh() end
end)
events:RegisterEvent('ADDON_LOADED')
events:RegisterEvent('GLOBAL_MOUSE_DOWN')
events:RegisterEvent('GLOBAL_MOUSE_UP')
for _, event in ipairs({'PLAYER_ENTERING_WORLD','QUEST_LOG_UPDATE','QUEST_ACCEPTED','QUEST_REMOVED','QUEST_TURNED_IN','PLAYER_LEVEL_UP','QUESTLINE_UPDATE','CVAR_UPDATE','MINIMAP_UPDATE_TRACKING','CALENDAR_UPDATE_EVENT_LIST','SKILL_LINES_CHANGED','UPDATE_FACTION','SPELLS_CHANGED','BAG_UPDATE_DELAYED','BANKFRAME_OPENED','BANKFRAME_CLOSED','PLAYERBANKSLOTS_CHANGED','PLAYER_REGEN_ENABLED'}) do
    events:RegisterEvent(event)
end

SLASH_QUESTSSTARTS1 = '/qs'
SlashCmdList.QUESTSSTARTS = function(message)
    message = (message or ''):lower():match('^%s*(.-)%s*$')
    if message == 'on' or message == 'off' then
        ns.Settings.enabled = message == 'on'
        ns.QueueRefresh()
    elseif message=='dungeon' or message=='dungeons' then
        ns.OpenDungeons()
    else
        refreshSafely()
        print('QuestsStarts 0.13.24: '..ns.L.coverage)
        print('Dungeon entrances on this map: '..(ns.lastEntranceCount or 0))
        print('Entrance button activations: '..(ns.entranceClickCount or 0))
        if ns.lastEntranceFocus then print('Entrance input focus: '..ns.lastEntranceFocus) end
        print('Map click handler: '..(ns.lastMapInput or 'no canvas clicks received'))
        print('Quest Starts: '..(ns.Settings.enabled and 'on' or 'off')..'; Item Quest Starts: '..(ns.Settings.showItems and 'on' or 'off')..'; visible pins: '..(ns.lastPinCount or 0)..'.')
        if ns.lastError then print('Refresh error: '..ns.lastError) return end
        if ns.lastReason then print(ns.lastReason) return end
        local stats,state=ns.lastStats,ns.lastState
        if stats and state then
            print('Map '..WorldMapFrame:GetMapID()..'; player level '..state.level..'; low-level quests '..(state.showLowLevel and 'shown' or 'hidden')..'; trivial range '..state.trivialRange..'.')
            print(stats.total..' pickup quests in data; '..stats.eligible..' pass filters.')
            local reasons={}
            for reason,count in pairs(stats.hidden) do reasons[#reasons+1]=reason..': '..count end
            table.sort(reasons)
            if #reasons>0 then print('Hidden: '..table.concat(reasons,'; ')) end
        end
    end
end
